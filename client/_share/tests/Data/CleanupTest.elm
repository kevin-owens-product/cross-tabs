module Data.CleanupTest exposing (savedQueryCleanupTest, temporaryQueryCleanupTest)

import D3Charts.ChartBuilder exposing (ChartType(..))
import Data.Cleanup as Cleanup
import Data.Core
    exposing
        ( AudienceId
        , SavedQuery
        )
import Data.Core.DatapointsSort exposing (DatapointsSort(..))
import Data.Id exposing (IdDict)
import Data.Labels
    exposing
        ( LocationCode
        , NamespaceAndQuestionCode
        , NamespaceAndQuestionCodeTag
        , Question
        , Suffix
        , WaveCode
        )
import Data.Metric as Metric
import Data.Permissions exposing (DataPermissions(..))
import Data.SavedQuery.Segmentation as Segmentation exposing (Segmentation(..), SplitBases(..))
import Data.TemporaryQuery exposing (TemporaryQuery)
import Expect
import Factory.Datapoint as Datapoint
import Factory.Question
import List.NonEmpty as NonemptyList
import Test exposing (..)


savedQueryCleanupTest : Test
savedQueryCleanupTest =
    describe "Saved query cleanup test"
        [ test "Without any unknown data the saved query is unchanged" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Accessible

                    savedQuery =
                        savedQueryMock
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Expect.equal (Just savedQuery)
        , test "With question without datapoint present in saved query should filter it out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Accessible

                    savedQuery =
                        { savedQueryMock
                            | activeDatapointCodes =
                                [ id "q2_1", id "s2_1" ]
                        }
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Maybe.map .activeDatapointCodes
                    |> Expect.equal (Just [ id "s2_1" ])
        , test "With no good datapoints it should be Nothing" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Accessible

                    savedQuery =
                        { savedQueryMock
                            | activeDatapointCodes =
                                [ id "nonexistent_1", id "nonexistent_2" ]
                        }
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Expect.equal Nothing
        , test "If there are no inaccessible locations everything should stay as it has been" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Accessible

                    savedQuery =
                        savedQueryMock
                            |> withLocationCodes [ id "s2_1", id "s2_20", id "s2_21" ]
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Maybe.map (.filters >> .locationCodes)
                    |> Expect.equal (Just [ id "s2_1", id "s2_20", id "s2_21" ])
        , test "Inaccessible locations should be filtered out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | locations = Just ( id "s2_20", [] ) }

                    savedQuery =
                        savedQueryMock
                            |> withLocationCodes [ id "s2_1", id "s2_20", id "s2_21" ]
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Maybe.map (.filters >> .locationCodes)
                    |> Expect.equal (Just [ id "s2_1", id "s2_21" ])
        , test "If there are no inaccessible waves everything should stay as it has been" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Accessible

                    savedQuery =
                        savedQueryMock
                            |> withWaveCodes [ id "q3_2019", id "q4_2019", id "q1_2020" ]
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Maybe.map (.filters >> .waveCodes)
                    |> Expect.equal (Just [ id "q3_2019", id "q4_2019", id "q1_2020" ])
        , test "If there are inaccessible waves filter them out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | waves = Just ( id "q4_2019", [] ) }

                    savedQuery =
                        savedQueryMock
                            |> withWaveCodes [ id "q3_2019", id "q4_2019", id "q1_2020" ]
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Maybe.map (.filters >> .waveCodes)
                    |> Expect.equal (Just [ id "q3_2019", id "q1_2020" ])
        , test "If there are inaccessible base audience set the base audience to Nothing " <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | p1Audiences = Just ( id "1234", [] ) }

                    savedQuery =
                        savedQueryMock
                            |> withBaseAudience (id "1234")
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Maybe.map (.filters >> .baseAudience)
                    |> Expect.equal (Just Nothing)
        , test "If there are inaccessible audiences, clear them out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | p1Audiences = Just ( id "1234", [] ) }

                    savedQuery =
                        savedQueryMock
                            |> withAudiences [ id "1", id "2", id "1234" ]
                in
                Cleanup.cleanupSavedQuery questions permissions savedQuery
                    |> Maybe.map .audienceIds
                    |> Expect.equal (Just [ id "1", id "2" ])
        ]


temporaryQueryCleanupTest : Test
temporaryQueryCleanupTest =
    describe "Temporary query cleanup test"
        [ test "Without unknown data the temporary query is unchanged" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Accessible
                in
                goodTemporaryQuery
                    |> Cleanup.cleanupTemporaryQuery questions permissions questionCode
                    |> Expect.equal (Just goodTemporaryQuery)
        , test "Datapoints not present in the question to be filtered out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Accessible
                in
                { goodTemporaryQuery | activeDatapointCodes = [ id "s2_1", id "s2_2", id "s2_3" ] }
                    |> Cleanup.cleanupTemporaryQuery questions permissions questionCode
                    |> Expect.equal (Just goodTemporaryQuery)
        , test "Suffixes not present in the question to be filtered out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Accessible
                in
                { goodTemporaryQuery | suffixCodes = Just ( id "1", [ id "2" ] ) }
                    |> Cleanup.cleanupTemporaryQuery questions permissions questionCode
                    |> Expect.equal (Just goodTemporaryQuery)
        , test "Inaccessible locations should be filtered out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | locations = Just ( id "s2_20", [] ) }
                in
                { goodTemporaryQuery | filters = { emptyFilters | locationCodes = [ id "s2_20" ] } }
                    |> Cleanup.cleanupTemporaryQuery questions permissions questionCode
                    |> Expect.equal (Just goodTemporaryQuery)
        , test "Inaccessible waves should be filtered out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | waves = Just ( id "q3_2019", [] ) }
                in
                { goodTemporaryQuery | filters = { emptyFilters | waveCodes = [ id "q3_2019" ] } }
                    |> Cleanup.cleanupTemporaryQuery questions permissions questionCode
                    |> Expect.equal (Just goodTemporaryQuery)
        , test "Inaccessible base audience should be filtered out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | p1Audiences = Just ( id "1234", [] ) }
                in
                { goodTemporaryQuery | filters = { emptyFilters | baseAudience = Just (id "1234") } }
                    |> Cleanup.cleanupTemporaryQuery questions permissions questionCode
                    |> Expect.equal (Just goodTemporaryQuery)
        , test "Inaccessible audience should be filtered out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | p1Audiences = Just ( id "bad_audience", [] ) }
                in
                { goodTemporaryQuery | audienceIds = [ id "bad_audience" ] }
                    |> Cleanup.cleanupTemporaryQuery questions permissions questionCode
                    |> Expect.equal (Just goodTemporaryQuery)
        , test "Inaccessible splitter should be filtered out" <|
            \() ->
                let
                    questions =
                        [ questionWithInaccessibleDatapoints ]
                            |> toQuestions

                    permissions =
                        Unknown { emptyProblematicData | splitters = Just ( id "bad_splitter", [] ) }
                in
                { goodTemporaryQuery
                    | segmentation =
                        Segmentation
                            (SplitBases True)
                            (Just ( id "bad_splitter", [ id "segment" ] ))
                }
                    |> Cleanup.cleanupTemporaryQuery questions permissions questionCode
                    |> Expect.equal (Just goodTemporaryQuery)
        ]


goodTemporaryQuery : TemporaryQuery
goodTemporaryQuery =
    { activeDatapointCodes = [ id "s2_1", id "s2_2" ]
    , suffixCodes = Just ( id "1", [] )
    , audienceIds = []
    , segmentation = Segmentation.empty
    , filters = emptyFilters
    , chartType = D3Charts.ChartBuilder.DataTable
    , metrics = [ Metric.Index ]
    , orderType = Descending
    , areSegmentsSwitched = True
    , ordinate = Metric.Index
    }


emptyFilters =
    { locationCodes = []
    , waveCodes = []
    , baseAudience = Nothing
    }



-- DATA


id =
    Data.Id.fromString


emptyProblematicData =
    Data.Permissions.emptyProblematicData


questionMock =
    Factory.Question.mock


savedQueryMock : SavedQuery
savedQueryMock =
    { id = Data.Id.fromString ""
    , name = ""
    , position = 0
    , questionCode = questionCode
    , activeDatapointCodes = [ id "s2_1", id "s2_2" ]
    , suffixCodes = Nothing
    , audienceIds = [ Data.Id.fromString "" ]
    , segmentation =
        Segmentation.empty
            |> Segmentation.withSplitterAndSegments (Data.Id.fromString "") []
    , filters =
        { locationCodes = [ Data.Id.fromString "" ]
        , waveCodes = [ Data.Id.fromString "" ]
        , baseAudience = Just <| Data.Id.fromString ""
        }
    , chartType = AdvancedVerticalBarChart
    , metrics = []
    , orderType = Default
    }


withWaveCodes : List WaveCode -> SavedQuery -> SavedQuery
withWaveCodes waveCode q =
    let
        updateWaves f =
            { f | waveCodes = waveCode }
    in
    { q | filters = updateWaves q.filters }


withLocationCodes : List LocationCode -> SavedQuery -> SavedQuery
withLocationCodes locations q =
    let
        updateLocations f =
            { f | locationCodes = locations }
    in
    { q | filters = updateLocations q.filters }


withBaseAudience : AudienceId -> SavedQuery -> SavedQuery
withBaseAudience audience q =
    let
        updateBaseAudience f =
            { f | baseAudience = Just audience }
    in
    { q | filters = updateBaseAudience q.filters }


withAudiences : List AudienceId -> SavedQuery -> SavedQuery
withAudiences audiences q =
    { q | audienceIds = audiences }


questionCode : NamespaceAndQuestionCode
questionCode =
    id "s2"


questionWithInaccessibleDatapoints : Question
questionWithInaccessibleDatapoints =
    { questionMock
        | code = questionCode
        , datapoints =
            NonemptyList.fromCons
                (Datapoint.mock |> Datapoint.withCode (id "s2_1") |> Datapoint.withName "Some accessible" |> Datapoint.accessible)
                [ Datapoint.mock |> Datapoint.withCode (id "s2_2") |> Datapoint.withName "Some inacessible" |> Datapoint.inaccessible
                ]
        , suffixes = Just ( { suffixMock | code = id "1" }, [] )
        , accessible = True
    }


suffixMock : Suffix
suffixMock =
    { code = id ""
    , name = ""
    , midpoint = Nothing
    }


toQuestions : List Question -> IdDict NamespaceAndQuestionCodeTag Question
toQuestions list =
    list
        |> List.map (\q -> ( q.code, q ))
        |> Data.Id.dictFromList
