module XB2.HeatmapTest exposing (initScaleTest)

import Expect
import List.NonEmpty.Zipper as Zipper
import Test exposing (..)
import XB2.AudienceCrosstabFuzzer as AudienceCrosstabFuzzer
import XB2.Data.AudienceCrosstab as AC
import XB2.Data.AudienceItem as AudienceItem
import XB2.Data.Metric as Metric
import XB2.Detail.Heatmap as Heatmap
import XB2.Share.Gwi.List as List


totalsHeader : AC.Key
totalsHeader =
    { item = AudienceItem.totalItem, isSelected = False }


magentaString : String
magentaString =
    Heatmap.colorToHex Heatmap.Magenta


getAllColors : AC.AudienceCrosstab -> Heatmap.HeatmapScale -> List String
getAllColors crosstab scale =
    let
        columnHeaders : List AC.Key
        columnHeaders =
            totalsHeader
                :: AC.getColumns crosstab

        rowHeaders : List AC.Key
        rowHeaders =
            totalsHeader
                :: AC.getRows crosstab
    in
    List.fastConcatMap
        (\row ->
            columnHeaders
                |> List.fastConcatMap
                    (\col ->
                        AC.getBaseAudiences crosstab
                            |> Zipper.toList
                            |> List.filterMap
                                (\base ->
                                    let
                                        cell : AC.Cell
                                        cell =
                                            AC.value { base = base, col = col, row = row } crosstab
                                    in
                                    case cell.data of
                                        AC.AvAData data ->
                                            Heatmap.getColor scale { col = col.item, row = row.item } data.data

                                        _ ->
                                            Nothing
                                )
                    )
        )
        rowHeaders


initScaleTest : Test
initScaleTest =
    describe "Test heatmap scale, never get magenta"
        [ Test.fuzz (AudienceCrosstabFuzzer.audienceCrosstabFuzzer 2 18) "testing crosstab with random values" <|
            \audienceCrosstab ->
                if AC.isEmpty audienceCrosstab then
                    Expect.pass

                else
                    Expect.all
                        ([ Metric.ColumnPercentage, Metric.RowPercentage, Metric.Index ]
                            |> List.fastConcatMap
                                (\metric ->
                                    let
                                        allColors =
                                            Heatmap.initScale audienceCrosstab metric
                                                |> getAllColors audienceCrosstab
                                    in
                                    [ \_ ->
                                        List.member magentaString allColors
                                            |> Expect.equal False
                                            |> Expect.onFail "There should be No magenta in list of colors"
                                    , \_ ->
                                        List.isEmpty allColors
                                            |> Expect.equal False
                                            |> Expect.onFail "List is not empty"
                                    ]
                                )
                        )
                        ()
        ]
