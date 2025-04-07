module XB2.Detail.Heatmap exposing
    ( Color(..)
    , HeatmapScale(..)
    , colorToHex
    , getColor
    , initScale
    )

import XB2.Data.AudienceCrosstab as AudienceCrosstab
    exposing
        ( AudienceCrosstab
        , CellDataResult
        , HeatmapBehaviour(..)
        )
import XB2.Data.AudienceItem as AudienceItem exposing (AudienceItem)
import XB2.Data.AudienceItemId as AudienceItemId exposing (AudienceItemId)
import XB2.Data.Metric exposing (Metric(..))
import XB2.Data.Range as Range exposing (Range)
import XB2.RemoteData.Tracked as Tracked


type Color
    = Red500
    | Red400
    | Red300
    | Red200
    | Red100
    | Magenta -- for debugging, out of range values. Signifies business logic errors, shouldn't happen normally.
    | Green100
    | Green200
    | Green300
    | Green400
    | Green500
    | NoColor


colorToHex : Color -> String
colorToHex color =
    case color of
        Red500 ->
            "#df535e"

        Red400 ->
            "#e6757e"

        Red300 ->
            "#ec989f"

        Red200 ->
            "#f2babf"

        Red100 ->
            "#f8dddf"

        Magenta ->
            "#ff00ff"

        Green100 ->
            "#def4f7"

        Green200 ->
            "#bceaf0"

        Green300 ->
            "#9be0e9"

        Green400 ->
            "#79d5e2"

        Green500 ->
            "#58cbda"

        NoColor ->
            ""


{-| Transforms a float in range <0..1> into a color. Defaults to Magenta elsewhere.
Goes (linearly) from dark red through light red, light green into dark green.
-}
toColor : Float -> Color
toColor num =
    if num < 0 || num > 1 then
        Magenta

    else if num < 0.1 then
        Red500

    else if num < 0.2 then
        Red400

    else if num < 0.3 then
        Red300

    else if num < 0.4 then
        Red200

    else if num < 0.5 then
        Red100

    else if num < 0.6 then
        Green100

    else if num < 0.7 then
        Green200

    else if num < 0.8 then
        Green300

    else if num < 0.9 then
        Green400

    else
        Green500


type HeatmapScale
    = HeatmapScale ({ row : AudienceItemId, col : AudienceItemId } -> CellDataResult -> Maybe Color)


initScale : AudienceCrosstab -> Metric -> HeatmapScale
initScale crosstab heatmapMetric =
    let
        range : Range
        range =
            AudienceCrosstab.getRange heatmapMetric crosstab

        valueToColor : Metric -> CellDataResult -> Color
        valueToColor metric cellDataResult =
            let
                value =
                    AudienceCrosstab.getFilteredMetricValue metric
                        (AudienceCrosstab.AvAData { data = cellDataResult, incompatibilities = Tracked.NotAsked })
            in
            case metric of
                RowPercentage ->
                    value
                        |> Maybe.withDefault -1
                        |> Range.interpolate range
                        |> toColor

                ColumnPercentage ->
                    value
                        |> Maybe.withDefault -1
                        |> Range.interpolate range
                        |> toColor

                Index ->
                    value
                        |> Maybe.map
                            (\index ->
                                let
                                    { min, max } =
                                        range

                                    redBandWidth =
                                        (99 - min) / 5
                                in
                                if index < (min + redBandWidth) then
                                    Red500

                                else if index < (min + redBandWidth * 2) then
                                    Red400

                                else if index < (min + redBandWidth * 3) then
                                    Red300

                                else if index < (min + redBandWidth * 4) then
                                    Red200

                                else if index <= 99 then
                                    Red100

                                else if index < 101 then
                                    NoColor

                                else
                                    let
                                        greenBandWidth =
                                            (max - 101) / 5
                                    in
                                    if index < (max - greenBandWidth * 4) then
                                        Green100

                                    else if index < (max - greenBandWidth * 3) then
                                        Green200

                                    else if index < (max - greenBandWidth * 2) then
                                        Green300

                                    else if index < (max - greenBandWidth) then
                                        Green400

                                    else
                                        Green500
                            )
                        |> Maybe.withDefault NoColor

                Sample ->
                    -- unused
                    value
                        |> Maybe.map
                            (\sample ->
                                sample
                                    |> Range.interpolate { min = 1, max = 1000 }
                                    |> toColor
                            )
                        |> Maybe.withDefault NoColor

                Size ->
                    -- unused
                    value
                        |> Maybe.map
                            (\size ->
                                size
                                    |> Range.interpolate { min = 10000, max = 1000000 }
                                    |> toColor
                            )
                        |> Maybe.withDefault NoColor
    in
    HeatmapScale
        (\ids result ->
            valueToColor heatmapMetric result
                |> disableForTotals heatmapMetric ids
        )


{-| In case of some metrics, either the total row or column or both are disabled
(no coloring inside them). This is determined by `AudienceCrosstab.heatmapBehaviour`.
-}
disableForTotals : Metric -> { row : AudienceItemId, col : AudienceItemId } -> Color -> Maybe Color
disableForTotals metric { row, col } color =
    let
        isTotalId id =
            id == AudienceItemId.total

        disableColor =
            Nothing

        keepColor =
            Just color

        behaviour : HeatmapBehaviour
        behaviour =
            AudienceCrosstab.heatmapBehaviour metric
    in
    case behaviour of
        AllCells ->
            keepColor

        AllExceptRowTotals ->
            if isTotalId col then
                disableColor

            else
                keepColor

        AllExceptColumnTotals ->
            if isTotalId row then
                disableColor

            else
                keepColor

        DataCellsOnly ->
            if isTotalId row || isTotalId col then
                disableColor

            else
                keepColor


getColor :
    HeatmapScale
    -> { x | row : AudienceItem, col : AudienceItem }
    -> CellDataResult
    -> Maybe String
getColor (HeatmapScale f) data intersect =
    f
        { row = AudienceItem.getId data.row
        , col = AudienceItem.getId data.col
        }
        intersect
        |> Maybe.map colorToHex
