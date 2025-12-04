module XB2.AudienceCrosstabFuzzer exposing (audienceCrosstabFuzzer)

{-| TODO: Intersection generators were removed from here, add them again for bulk AvA
Request
-}

import Basics.Extra exposing (flip)
import Dict
import Fuzz
import List.Extra as List
import Random
import Set.Any
import Time
import XB2.Data exposing (AudienceDefinition(..))
import XB2.Data.Audience.Expression as Expression
import XB2.Data.AudienceCrosstab as AC
import XB2.Data.AudienceItem as AudienceItem
import XB2.Data.BaseAudience as BaseAudience
import XB2.Data.Calc.AudienceIntersect exposing (AudienceIntersection, Intersect, IntersectResult, Stretching)
import XB2.Data.Calc.Average exposing (AverageResult)
import XB2.RemoteData.Tracked as Tracked
import XB2.Share.Data.Id exposing (IdSet)
import XB2.Share.Data.Labels
    exposing
        ( LocationCodeTag
        , QuestionAveragesUnit(..)
        , WaveCodeTag
        )
import XB2.Share.Gwi.Http exposing (Error(..), OtherError(..))



-- TYPES


type alias Audiences =
    { row : AudienceIntersection
    , col : AudienceIntersection
    }



-- CONSTANTS


wavesSet : IdSet WaveCodeTag
wavesSet =
    XB2.Share.Data.Id.emptySet
        |> Set.Any.insert (XB2.Share.Data.Id.fromString "wave_1")


locationsSet : IdSet LocationCodeTag
locationsSet =
    XB2.Share.Data.Id.emptySet
        |> Set.Any.insert (XB2.Share.Data.Id.fromString "location_1")


emptyAudienceCrosstab : AC.AudienceCrosstab
emptyAudienceCrosstab =
    AC.init wavesSet locationsSet (Time.millisToPosix 0) 1000 1000
        |> AC.setCellsVisibility True allCellsVisible


allCellsVisible : AC.VisibleCells
allCellsVisible =
    { topLeftRow = 0
    , topLeftCol = 0
    , bottomRightRow = 1000
    , bottomRightCol = 1000
    , frozenCols = 0
    , frozenRows = 0
    }



-- GENERATORS


intersectGenerator : Fuzz.Fuzzer Intersect
intersectGenerator =
    Fuzz.map3 Intersect
        (Fuzz.intRange 0 9999999)
        (Fuzz.intRange 0 999999)
        (Fuzz.floatRange 0 200)


audienceIntersectionTotalGenerator : Fuzz.Fuzzer AudienceIntersection
audienceIntersectionTotalGenerator =
    Fuzz.map4 AudienceIntersection
        (Fuzz.constant "0")
        (Fuzz.floatRange 0 100)
        (Fuzz.intRange 0 999999)
        (Fuzz.intRange 0 9999999)


stretchingGenerator : Fuzz.Fuzzer Stretching
stretchingGenerator =
    Fuzz.map2 Stretching
        (Fuzz.floatRange 0 6667788)
        (Fuzz.floatRange 0 2)


fuzzUniform : a -> List a -> Fuzz.Fuzzer a
fuzzUniform a list =
    Fuzz.uniformInt (List.length list + 1)
        |> Fuzz.map
            (\index ->
                (a :: list)
                    |> List.getAt index
                    |> Maybe.withDefault a
            )


stretchingDictGenerator : Fuzz.Fuzzer (Maybe (Dict.Dict String Stretching))
stretchingDictGenerator =
    Fuzz.listOfLength 15
        (Fuzz.map2 Tuple.pair
            (fuzzUniform "q1_2019___s2_1" [ "q1_2019___s2_2", "q1_2019___s2_31", "q1_2019___s2_90" ])
            stretchingGenerator
        )
        |> Fuzz.andThen
            (\s ->
                fuzzUniform Nothing [ Just <| Dict.fromList s ]
            )


audiencesTotalGenerator : Fuzz.Fuzzer Audiences
audiencesTotalGenerator =
    Fuzz.map2 Audiences
        audienceIntersectionTotalGenerator
        audienceIntersectionTotalGenerator


initCellData data =
    AC.initCell data Tracked.NotAsked |> .data


intersectResultTotalGenerator : Fuzz.Fuzzer AC.CellData
intersectResultTotalGenerator =
    Fuzz.map (initCellData << Tracked.Success) <|
        Fuzz.map3 IntersectResult
            intersectGenerator
            audiencesTotalGenerator
            stretchingDictGenerator


averageResultGenerator : Fuzz.Fuzzer AC.CellData
averageResultGenerator =
    Fuzz.map
        (\value -> AC.AverageData <| Tracked.Success <| AverageResult value (OtherUnit "devices"))
        (Fuzz.floatRange 0 100)



-- FUZZERS


audienceCrosstabFuzzer : Int -> Int -> Fuzz.Fuzzer AC.AudienceCrosstab
audienceCrosstabFuzzer min max =
    let
        fromRowsColsCounts : ( Int, Int ) -> Fuzz.Fuzzer AC.AudienceCrosstab
        fromRowsColsCounts ( rowCount, colCount ) =
            List.foldl
                (\i rac ->
                    let
                        fn hMock =
                            rac
                                |> Fuzz.map (AC.addAudiencesOneByOne (AC.addRow <| initCellData Tracked.NotAsked) [ hMock ])
                                |> Fuzz.map (Result.map (\( ac, cs ) -> updateAudienceCrosstab ( Fuzz.constant ac, cs )))
                                |> Fuzz.andThen (Result.withDefault rac)
                    in
                    fn (mockHeader i)
                )
                (Fuzz.constant emptyAudienceCrosstab)
                (List.range 1 rowCount)
                |> flip
                    (List.foldl
                        (\j rac ->
                            let
                                fn hMock =
                                    rac
                                        |> Fuzz.map (AC.addAudiencesOneByOne (AC.addColumn <| initCellData Tracked.NotAsked) [ hMock ])
                                        |> Fuzz.map (Result.map (\( ac, cs ) -> updateAudienceCrosstab ( Fuzz.constant ac, cs )))
                                        |> Fuzz.andThen (Result.withDefault rac)
                            in
                            fn (mockHeader j)
                        )
                    )
                    (List.range (rowCount + 1) (rowCount + colCount))
    in
    Fuzz.map2 Tuple.pair
        (Fuzz.intRange min max)
        (Fuzz.intRange min max)
        |> Fuzz.andThen fromRowsColsCounts



-- HELPERS


mockHeaderN : String -> Random.Seed -> ( AC.Key, Random.Seed )
mockHeaderN title seed =
    AudienceItem.fromSavedProject
        { id = title
        , name = title
        , fullName = title
        , subtitle = ""
        , definition = Expression Expression.sizeExpression
        }
        seed
        |> Tuple.mapFirst
            (\item ->
                { item = item
                , isSelected = False
                }
            )


mockHeader : Int -> Random.Seed -> ( AC.Key, Random.Seed )
mockHeader n =
    mockHeaderN (String.fromInt n)


updateAudienceCrosstab : ( Fuzz.Fuzzer AC.AudienceCrosstab, List AC.Command ) -> Fuzz.Fuzzer AC.AudienceCrosstab
updateAudienceCrosstab ( newRandomAudienceCrosstab, reloadCellsCommands ) =
    List.foldr
        (\command rac ->
            case command of
                AC.CancelHttpRequest _ ->
                    rac

                AC.MakeHttpRequest _ _ _ _ params ->
                    case params of
                        AC.TotalVsTotalRequest ->
                            Fuzz.map2
                                (\total ac ->
                                    AC.insertTotalsCell
                                        AudienceItem.totalItem
                                        BaseAudience.default
                                        total
                                        ac
                                )
                                intersectResultTotalGenerator
                                rac

                        AC.AverageRowRequest { getData } ->
                            let
                                { row, col } =
                                    getData (OtherUnit "Mock")
                            in
                            Fuzz.map2
                                (\averageResult ac ->
                                    AC.insertCrosstabCell
                                        { row = row
                                        , col = col
                                        , base = BaseAudience.default
                                        }
                                        averageResult
                                        ac
                                )
                                averageResultGenerator
                                rac

                        AC.AverageColRequest { getData } ->
                            let
                                { row, col } =
                                    getData (OtherUnit "Mock")
                            in
                            Fuzz.map2
                                (\averageResult ac ->
                                    AC.insertCrosstabCell
                                        { row = row
                                        , col = col
                                        , base = BaseAudience.default
                                        }
                                        averageResult
                                        ac
                                )
                                averageResultGenerator
                                rac

                        AC.TotalRowAverageColRequest { getData } ->
                            let
                                { col } =
                                    getData (OtherUnit "Mock")
                            in
                            Fuzz.map2
                                (\averageResult ac ->
                                    AC.insertTotalsCell
                                        col
                                        BaseAudience.default
                                        averageResult
                                        ac
                                )
                                averageResultGenerator
                                rac

                        AC.TotalColAverageRowRequest { getData } ->
                            let
                                { row } =
                                    getData (OtherUnit "Mock")
                            in
                            Fuzz.map2
                                (\averageResult ac ->
                                    AC.insertTotalsCell
                                        row
                                        BaseAudience.default
                                        averageResult
                                        ac
                                )
                                averageResultGenerator
                                rac

                        AC.AverageVsAverageRequest { row, col } ->
                            Fuzz.map
                                (AC.insertCrosstabCell
                                    { row = row
                                    , col = col
                                    , base = BaseAudience.default
                                    }
                                    (AC.AverageData <| Tracked.Failure (OtherError XBAvgVsAvgNotSupported))
                                )
                                rac

                        AC.CrosstabBulkAvARequest _ ->
                            -- TODO: Implement test for this
                            rac

                        AC.IncompatibilityBulkRequest _ ->
                            -- TODO: Implement test for this
                            rac

                        AC.DbuRowRequest _ ->
                            -- TODO: Implement test for this
                            rac

                        AC.DbuColRequest _ ->
                            -- TODO: Implement test for this
                            rac

                        AC.TotalRowDbuColRequest _ ->
                            -- TODO: Implement test for this
                            rac

                        AC.TotalColDbuRowRequest _ ->
                            -- TODO: Implement test for this
                            rac

                        AC.AverageVsDbuRequest _ ->
                            -- TODO: Implement test for this
                            rac

                        AC.DbuVsDbuRequest _ ->
                            -- TODO: Implement test for this
                            rac

                        AC.DbuVsAverageRequest _ ->
                            -- TODO: Implement test for this
                            rac
        )
        newRandomAudienceCrosstab
        reloadCellsCommands
