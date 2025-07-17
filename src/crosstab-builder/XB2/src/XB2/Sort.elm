module XB2.Sort exposing
    ( Axis(..)
    , AxisSort(..)
    , Sort
    , SortDirection(..)
    , axisSortToDebugString
    , axisToString
    , decoder
    , empty
    , encode
    , forAxis
    , isAnyAxisSorting
    , isSorting
    , isSortingByAverage
    , isSortingByMetric
    , isSortingByName
    , needsDataReload
    , otherAxis
    , sortingAudience
    , sortingMetric
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode
import XB2.Data.AudienceItemId as AudienceItemId exposing (AudienceItemId)
import XB2.Data.Metric as Metric exposing (Metric)


type alias Sort =
    { rows : AxisSort
    , columns : AxisSort
    }


type AxisSort
    = ByOtherAxisMetric AudienceItemId Metric SortDirection
    | ByTotalsMetric Metric SortDirection
    | ByOtherAxisAverage AudienceItemId SortDirection
    | ByName SortDirection
    | NoSort


type SortDirection
    = Ascending
    | Descending


type Axis
    = Rows
    | Columns


axisToString : Axis -> String
axisToString axis =
    case axis of
        Rows ->
            "Rows"

        Columns ->
            "Columns"


empty : Sort
empty =
    { rows = NoSort
    , columns = NoSort
    }


decoder : Decoder Sort
decoder =
    Decode.succeed Sort
        |> Decode.andMap (Decode.field "rows" axisSortDecoder)
        |> Decode.andMap (Decode.field "columns" axisSortDecoder)


axisSortDecoder : Decoder AxisSort
axisSortDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\type_ ->
                case type_ of
                    "by_other_axis_metric" ->
                        Decode.succeed ByOtherAxisMetric
                            |> Decode.andMap (Decode.field "audience_item_id" AudienceItemId.decoder)
                            |> Decode.andMap (Decode.field "metric" Metric.decoder)
                            |> Decode.andMap (Decode.field "direction" directionDecoder)

                    "by_totals_metric" ->
                        Decode.succeed ByTotalsMetric
                            |> Decode.andMap (Decode.field "metric" Metric.decoder)
                            |> Decode.andMap (Decode.field "direction" directionDecoder)

                    "by_other_axis_average" ->
                        Decode.succeed ByOtherAxisAverage
                            |> Decode.andMap (Decode.field "audience_item_id" AudienceItemId.decoder)
                            |> Decode.andMap (Decode.field "direction" directionDecoder)

                    "by_name" ->
                        Decode.succeed ByName
                            |> Decode.andMap (Decode.field "direction" directionDecoder)

                    "no_sort" ->
                        Decode.succeed NoSort

                    _ ->
                        Decode.fail <|
                            "Unknown AxisSort: "
                                ++ type_
            )


directionDecoder : Decoder SortDirection
directionDecoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "ascending" ->
                        Decode.succeed Ascending

                    "descending" ->
                        Decode.succeed Descending

                    _ ->
                        Decode.fail <| "Unknown SortDirection: " ++ string
            )


encode : Sort -> Encode.Value
encode sort =
    Encode.object
        [ ( "rows", encodeAxis sort.rows )
        , ( "columns", encodeAxis sort.columns )
        ]


encodeAxis : AxisSort -> Encode.Value
encodeAxis sort =
    case sort of
        ByOtherAxisMetric id metric direction ->
            Encode.object
                [ ( "type", Encode.string "by_other_axis_metric" )
                , ( "audience_item_id", AudienceItemId.encode id )
                , ( "metric", Metric.encode metric )
                , ( "direction", encodeDirection direction )
                ]

        ByTotalsMetric metric direction ->
            Encode.object
                [ ( "type", Encode.string "by_totals_metric" )
                , ( "metric", Metric.encode metric )
                , ( "direction", encodeDirection direction )
                ]

        ByOtherAxisAverage id direction ->
            Encode.object
                [ ( "type", Encode.string "by_other_axis_average" )
                , ( "audience_item_id", AudienceItemId.encode id )
                , ( "direction", encodeDirection direction )
                ]

        ByName direction ->
            Encode.object
                [ ( "type", Encode.string "by_name" )
                , ( "direction", encodeDirection direction )
                ]

        NoSort ->
            Encode.object
                [ ( "type", Encode.string "no_sort" ) ]


encodeDirection : SortDirection -> Encode.Value
encodeDirection direction =
    case direction of
        Ascending ->
            Encode.string "ascending"

        Descending ->
            Encode.string "descending"


forAxis : Axis -> Sort -> AxisSort
forAxis axis sort =
    case axis of
        Rows ->
            sort.rows

        Columns ->
            sort.columns


isSorting : AxisSort -> Bool
isSorting axisSort =
    case axisSort of
        NoSort ->
            False

        ByName _ ->
            True

        ByOtherAxisMetric _ _ _ ->
            True

        ByTotalsMetric _ _ ->
            True

        ByOtherAxisAverage _ _ ->
            True


isAnyAxisSorting : Sort -> Bool
isAnyAxisSorting { columns, rows } =
    isSorting columns || isSorting rows


isSortingByName : AxisSort -> Bool
isSortingByName axisSort =
    case axisSort of
        ByName _ ->
            True

        NoSort ->
            False

        ByOtherAxisMetric _ _ _ ->
            False

        ByTotalsMetric _ _ ->
            False

        ByOtherAxisAverage _ _ ->
            False


isSortingByMetric : AxisSort -> Bool
isSortingByMetric axisSort =
    case axisSort of
        ByName _ ->
            False

        NoSort ->
            False

        ByOtherAxisMetric _ _ _ ->
            True

        ByTotalsMetric _ _ ->
            True

        ByOtherAxisAverage _ _ ->
            False


isSortingByAverage : AxisSort -> Bool
isSortingByAverage axisSort =
    case axisSort of
        ByName _ ->
            False

        NoSort ->
            False

        ByOtherAxisMetric _ _ _ ->
            False

        ByTotalsMetric _ _ ->
            False

        ByOtherAxisAverage _ _ ->
            True


sortingAudience : AxisSort -> Maybe AudienceItemId
sortingAudience axisSort =
    case axisSort of
        ByName _ ->
            Nothing

        NoSort ->
            Nothing

        ByTotalsMetric _ _ ->
            Just AudienceItemId.total

        ByOtherAxisMetric id _ _ ->
            Just id

        ByOtherAxisAverage id _ ->
            Just id


needsDataReload : AxisSort -> Bool
needsDataReload axisSort =
    case axisSort of
        ByName _ ->
            False

        NoSort ->
            False

        ByOtherAxisMetric _ _ _ ->
            True

        ByTotalsMetric _ _ ->
            True

        ByOtherAxisAverage _ _ ->
            True


sortingMetric : AxisSort -> Maybe Metric
sortingMetric axisSort =
    case axisSort of
        ByName _ ->
            Nothing

        NoSort ->
            Nothing

        ByTotalsMetric metric _ ->
            Just metric

        ByOtherAxisMetric _ metric _ ->
            Just metric

        ByOtherAxisAverage _ _ ->
            Nothing


axisSortToDebugString : AxisSort -> String
axisSortToDebugString sort =
    case sort of
        NoSort ->
            "-"

        ByName dir ->
            "By name (" ++ sortDirectionToDebugString dir ++ ")"

        ByOtherAxisAverage id dir ->
            "By other axis Average ("
                ++ sortDirectionToDebugString dir
                ++ ", "
                ++ AudienceItemId.toString id
                ++ ")"

        ByOtherAxisMetric id metric dir ->
            "By other axis Metric ("
                ++ sortDirectionToDebugString dir
                ++ ", "
                ++ Metric.toString metric
                ++ ", "
                ++ AudienceItemId.toString id
                ++ ")"

        ByTotalsMetric metric dir ->
            "By Totals Metric ("
                ++ sortDirectionToDebugString dir
                ++ ", "
                ++ Metric.toString metric
                ++ ")"


sortDirectionToDebugString : SortDirection -> String
sortDirectionToDebugString dir =
    case dir of
        Ascending ->
            "ASC"

        Descending ->
            "DESC"


otherAxis : Axis -> Axis
otherAxis axis =
    case axis of
        Rows ->
            Columns

        Columns ->
            Rows
