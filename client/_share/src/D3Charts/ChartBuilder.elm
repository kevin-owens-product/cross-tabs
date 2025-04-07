module D3Charts.ChartBuilder exposing (ChartType(..), chartTypeDecoder, encodeChartType)

{-|

@docs ChartType, chartTypeToString, chartTypeDecoder, encodeChartType
@docs ChartData, ChartGroup, Chart

---

This module holds Elm types for the <x-cb-horizontal-bar-chart> and
<x-cb-vertical-bar-chart> WebComponents, which use our GWI JS library `d3-charts`.

d3-charts splits its available charts into two sections: CB and Dashboards.
This is the CB part. For the other, see D3Charts.Dashboards.

The actual HTML views that render these WebComponents are in ChartBuilder.Charts,
which further uses types from this module.

---

MAPPING OF TYPES IN THIS MODULE TO HIGH-LEVEL ELEMENTS IN UI
Let's say you go for q6 (Education), segment by Age Groups and add two audiences.
Then you'd see:

    X = Audience 1
    # = Audience 2

    16 to 24                 25 to 34     ...
    _____________________    __________

               #
               #
       #       #               ...
     X #       #
     X #     X #
     X #     X #    ...

     ^       ^
     |       |
     |       Schooling until age 18
     |
     Schooling until age 16


    In this example:
    - the whole thing is `ChartData`
    - the "16 to 24" thing is a `ChartGroup`
    - the collection of bars for the different audiences (grouped under "Schooling until age 16") is a `Chart`
    - the individual bar (for one audience) is a `ChartPoint`

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type ChartType
    = AdvancedHorizontalBarChart
    | AdvancedVerticalBarChart
    | DataTable


chartTypeToString : ChartType -> String
chartTypeToString type_ =
    case type_ of
        AdvancedHorizontalBarChart ->
            "advanced_horizontal_bar_chart"

        AdvancedVerticalBarChart ->
            "advanced_vertical_bar_chart"

        DataTable ->
            "data_table"


encodeChartType : ChartType -> Encode.Value
encodeChartType type_ =
    Encode.string <| chartTypeToString type_


chartTypeDecoder : Decoder ChartType
chartTypeDecoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "data_table" ->
                        Decode.succeed DataTable

                    "vertical_bar_chart" ->
                        Decode.succeed AdvancedVerticalBarChart

                    "advanced_vertical_bar_chart" ->
                        Decode.succeed AdvancedVerticalBarChart

                    "horizontal_bar_chart" ->
                        Decode.succeed AdvancedHorizontalBarChart

                    "advanced_horizontal_bar_chart" ->
                        Decode.succeed AdvancedHorizontalBarChart

                    _ ->
                        Decode.fail <| "Invalid CB ChartType: " ++ string
            )
