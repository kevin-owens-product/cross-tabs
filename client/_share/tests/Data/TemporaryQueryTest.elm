module Data.TemporaryQueryTest exposing (test)

import D3Charts.ChartBuilder exposing (ChartType(..))
import Data.Core exposing (AudienceId)
import Data.Core.DatapointsSort exposing (DatapointsSort(..))
import Data.Id as Id exposing (Id)
import Data.Labels exposing (LocationCode, WaveCode)
import Data.Metric exposing (Metric)
import Data.SavedQuery.Segmentation as Segmentation exposing (Segmentation)
import Data.TemporaryQuery as TemporaryQuery exposing (TemporaryQuery)
import Expect
import Fuzz exposing (Fuzzer)
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Test exposing (Test, describe, fuzz)


test : Test
test =
    describe "Data.TemporaryQuery"
        [ fuzz temporaryQueryFuzzer "v1 roundtrip" <|
            \query ->
                query
                    |> TemporaryQuery.encode TemporaryQuery.V1
                    |> TemporaryQuery.decode
                    |> Expect.equal (Just ( TemporaryQuery.V1, query ))
        ]


temporaryQueryFuzzer : Fuzzer TemporaryQuery
temporaryQueryFuzzer =
    Fuzz.constant TemporaryQuery
        |> Fuzz.andMap (Fuzz.list idFuzzer)
        |> Fuzz.andMap (Fuzz.maybe (nonemptyListFuzzer idFuzzer))
        |> Fuzz.andMap (Fuzz.list idFuzzer)
        |> Fuzz.andMap segmentationFuzzer
        |> Fuzz.andMap filtersFuzzer
        |> Fuzz.andMap chartTypeFuzzer
        |> Fuzz.andMap (Fuzz.list metricFuzzer)
        |> Fuzz.andMap datapointsSortFuzzer
        |> Fuzz.andMap Fuzz.bool
        |> Fuzz.andMap metricFuzzer


idFuzzer : Fuzzer (Id tag)
idFuzzer =
    Fuzz.map Id.fromString Fuzz.string


nonemptyListFuzzer : Fuzzer a -> Fuzzer (NonEmpty a)
nonemptyListFuzzer innerFuzzer =
    Fuzz.map2 NonemptyList.fromCons
        innerFuzzer
        (Fuzz.list innerFuzzer)


oneOf_ : List a -> Fuzzer a
oneOf_ values =
    Fuzz.oneOf <| List.map Fuzz.constant values


metricFuzzer : Fuzzer Metric
metricFuzzer =
    oneOf_ Data.Metric.allMetrics


chartTypeFuzzer : Fuzzer ChartType
chartTypeFuzzer =
    oneOf_
        [ AdvancedHorizontalBarChart
        , AdvancedVerticalBarChart
        , DataTable
        ]


datapointsSortFuzzer : Fuzzer DatapointsSort
datapointsSortFuzzer =
    oneOf_
        [ Descending
        , Ascending
        , Default
        ]


filtersFuzzer :
    Fuzzer
        { locationCodes : List LocationCode
        , waveCodes : List WaveCode
        , baseAudience : Maybe AudienceId
        }
filtersFuzzer =
    Fuzz.map3
        (\locs waves base ->
            { locationCodes = locs
            , waveCodes = waves
            , baseAudience = base
            }
        )
        (Fuzz.list idFuzzer)
        (Fuzz.list idFuzzer)
        (Fuzz.maybe idFuzzer)


segmentationFuzzer : Fuzzer Segmentation
segmentationFuzzer =
    Fuzz.map2
        (\splitBases splitterAndSegments ->
            let
                withoutSplitters =
                    Segmentation.empty
                        |> Segmentation.withSplitBases splitBases
            in
            splitterAndSegments
                |> Maybe.map
                    (\( splitter, segments ) ->
                        withoutSplitters
                            |> Segmentation.withSplitterAndSegments splitter segments
                    )
                |> Maybe.withDefault withoutSplitters
        )
        Fuzz.bool
        (Fuzz.maybe (Fuzz.pair idFuzzer (Fuzz.list idFuzzer)))
