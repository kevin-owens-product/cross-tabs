module Data.PermissionsTest exposing
    ( audienceTest
    , bookmarkTest
    , questionTest
    , savedQueryTest
    )

import D3Charts.ChartBuilder exposing (ChartType(..))
import Data.Audience.Expression exposing (AudienceExpression, AudienceInclusion(..))
import Data.Core
    exposing
        ( Audience
        , AudienceIdTag
        , Bookmark
        , SavedQuery
        , Splitter
        )
import Data.Core.DatapointsSort exposing (DatapointsSort(..))
import Data.Id exposing (IdDict)
import Data.Labels
    exposing
        ( Location
        , LocationCodeTag
        , NamespaceAndQuestionCodeTag
        , Question
        , QuestionAndDatapointCode
        , Wave
        , WaveCodeTag
        )
import Data.Permissions exposing (DataPermissions(..))
import Data.SavedQuery.Segmentation as Segmentation
    exposing
        ( SplitterCodeTag
        )
import Data.User
import Dict.Any
import Expect
import Factory.Datapoint as Datapoint
import Factory.Question
import Factory.Wave as Wave
import List.NonEmpty as NonemptyList
import Test exposing (..)
import Time


emptyProblematicData =
    Data.Permissions.emptyProblematicData


questionTest : Test
questionTest =
    describe "Data.Permissions.question"
        [ test "Accessible if at least one datapoint is accessible" <|
            \() ->
                Data.Permissions.questionV1
                    questionWithInaccessibleDatapoints
                    |> Expect.equal Accessible
        , test "UpsellNeeded if accessible is false" <|
            \() ->
                Data.Permissions.questionV1
                    { questionWithInaccessibleDatapoints | accessible = False }
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | questions = Just ( questionWithAllDatapointsInaccessible.code, [] ) }
                        )
        , test "UpsellNeeded if accessible is true but all datapoints are inaccessible" <|
            \() ->
                Data.Permissions.questionV1
                    questionWithAllDatapointsInaccessible
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | questions = Just ( questionWithAllDatapointsInaccessible.code, [] ) }
                        )
        ]


bookmarkTest : Test
bookmarkTest =
    describe "Data.Permissions.bookmark"
        [ test "Unknown if the question can't be found" <|
            \() ->
                Data.Permissions.bookmark
                    Data.Id.emptyDict
                    bookmark
                    |> Expect.equal (Unknown { emptyProblematicData | questions = Just ( Data.Id.fromString "", [] ) })
        , test "UpsellNeeded if the question can be found but is not accessible" <|
            \() ->
                Data.Permissions.bookmark
                    inaccessibleQuestions
                    bookmark
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | questions = Just ( Data.Id.fromString "", [] ) }
                        )
        , test "Accessible if the question can be found and is accessible" <|
            \() ->
                Data.Permissions.bookmark
                    accessibleQuestions
                    bookmark
                    |> Expect.equal Accessible
        , test "UpsellNeeded if the question has all datapoints inaccessible" <|
            \() ->
                Data.Permissions.bookmark
                    (toQuestionDict ( "", questionWithAllDatapointsInaccessible ))
                    bookmark
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | datapoints = Just ( Data.Id.fromString "s2_2", [] ) }
                        )
        , test "Accessible if the question has some datapoints accessible" <|
            \() ->
                Data.Permissions.bookmark
                    questionsWithS2
                    { bookmark | questionCode = Data.Id.fromString "s2" }
                    |> Expect.equal Accessible
        ]


audienceTest : Test
audienceTest =
    -- TODO test for walking the tree (actual tree, not just a "singleton"!) and combining properly
    describe "Data.Permissions.p1Audience"
        [ test "Unknown if the used questions can't be found" <|
            \() ->
                Data.Permissions.p1Audience
                    Data.User.Free
                    Data.Id.emptyDict
                    audience
                    |> Expect.equal (Unknown { emptyProblematicData | questions = Just ( Data.Id.fromString "", [] ) })
        , test "UpsellNeeded if the used questions can be found but aren't accessible" <|
            \() ->
                Data.Permissions.p1Audience
                    Data.User.Free
                    inaccessibleQuestions
                    audience
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | questions = Just ( Data.Id.fromString "", [] ) }
                        )
        , test "Accessible if the used questions can be found and are accessible" <|
            \() ->
                Data.Permissions.p1Audience
                    Data.User.Free
                    accessibleQuestions
                    audience
                    |> Expect.equal Accessible
        , test "Some inaccessible datapoints within audience" <|
            \() ->
                Data.Permissions.p1Audience
                    Data.User.Free
                    questionsWithS2
                    (audienceWithS2 (List.map Data.Id.fromString [ "s2_1", "s2_2" ]))
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | datapoints = Just ( Data.Id.fromString "s2_2", [] ) }
                        )
        , test "Question with inaccessible datapoints but not within this audience" <|
            \() ->
                Data.Permissions.p1Audience
                    Data.User.Free
                    questionsWithS2
                    (audienceWithS2 [ Data.Id.fromString "s2_1" ])
                    |> Expect.equal Accessible
        , test "Audience with datapoint that is no longer present" <|
            \() ->
                Data.Permissions.p1Audience
                    Data.User.Professional
                    questionsWithS2
                    (audienceWithS2 (List.map Data.Id.fromString [ "s2_1", "foo-bar" ]))
                    |> Expect.equal
                        (Unknown { emptyProblematicData | datapoints = Just ( Data.Id.fromString "foo-bar", [] ) })
        ]


savedQueryTest : Test
savedQueryTest =
    describe "Data.Permissions.savedQuery"
        [ test "Unknown if the used question can't be found" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    Data.Id.emptyDict
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQuery
                    |> Expect.equal (Unknown { emptyProblematicData | questions = Just ( Data.Id.fromString "", [] ) })
        , test "Unknown if the used segmentation splitter can't be found" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    Data.Id.emptyDict
                    accessibleLocations
                    accessibleWaves
                    savedQuery
                    |> Expect.equal (Unknown { emptyProblematicData | splitters = Just ( Data.Id.fromString "", [] ) })
        , test "Unknown if the used audiences can't be found" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    Data.Id.emptyDict
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQuery
                    |> Expect.equal (Unknown { emptyProblematicData | p1Audiences = Just ( Data.Id.fromString "", [] ) })
        , test "Unknown if the used filters locations can't be found" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    Data.Id.emptyDict
                    accessibleWaves
                    savedQuery
                    |> Expect.equal (Unknown { emptyProblematicData | locations = Just ( Data.Id.fromString "", [] ) })
        , test "Unknown if the used filters waves can't be found" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    Data.Id.emptyDict
                    savedQuery
                    |> Expect.equal (Unknown { emptyProblematicData | waves = Just ( Data.Id.fromString "", [] ) })
        , test "Unknown if the used filters all can't be found" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    Data.Id.emptyDict
                    Data.Id.emptyDict
                    Data.Id.emptyDict
                    Data.Id.emptyDict
                    Data.Id.emptyDict
                    savedQuery
                    |> Expect.equal
                        (Unknown
                            { emptyProblematicData
                                | questions = Just ( Data.Id.fromString "", [] )
                                , p1Audiences = Just ( Data.Id.fromString "", [] )
                                , waves = Just ( Data.Id.fromString "", [] )
                                , locations = Just ( Data.Id.fromString "", [] )
                                , splitters = Just ( Data.Id.fromString "", [] )
                            }
                        )
        , test "UpsellNeeded if the used question can be found but aren't accessible" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    inaccessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQuery
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | questions = Just ( Data.Id.fromString "", [] ) }
                        )
        , test "UpsellNeeded if the used segmentation splitter can be found but aren't accessible" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    inaccessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQuery
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | splitters = Just ( Data.Id.fromString "", [] ) }
                        )
        , test "UpsellNeeded if the used filters' locations can be found but aren't accessible" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    inaccessibleLocations
                    accessibleWaves
                    savedQuery
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | locations = Just ( Data.Id.fromString "", [] ) }
                        )
        , test "UpsellNeeded if the used filters' waves can be found but aren't accessible" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    inaccessibleWaves
                    savedQuery
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | waves = Just ( Data.Id.fromString "", [] ) }
                        )
        , test "Accessible if everything the query depends on is accessible" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQuery
                    |> Expect.equal Accessible
        , test "Accessible if everything OK and there is no audience in the query" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQueryWithNoAudience
                    |> Expect.equal Accessible
        , test "Accessible if everything OK and there is no splitter in the query's segmentation" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQueryWithNoSplitter
                    |> Expect.equal Accessible
        , test "Accessible if everything OK and there is no location in the query's filters" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQueryWithNoLocation
                    |> Expect.equal Accessible
        , test "Accessible if everything OK and there is no wave in the query's filters" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQueryWithNoWave
                    |> Expect.equal Accessible
        , test "Accessible if everything OK and there is no base audience in the query's filters" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    accessibleQuestions
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    savedQueryWithNoBaseAudience
                    |> Expect.equal Accessible
        , test "Saved query with inaccessible datapoint" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    questionsWithS2
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    (savedQueryQueryS2WithDatapointCodes (List.map Data.Id.fromString [ "s2_1", "s2_2" ]))
                    |> Expect.equal
                        (UpsellNeeded
                            { emptyProblematicData | datapoints = Just ( Data.Id.fromString "s2_2", [] ) }
                        )
        , test "Saved query with partially inaccessible question but only with accessible datapointCodes" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    questionsWithS2
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    (savedQueryQueryS2WithDatapointCodes [ Data.Id.fromString "s2_1" ])
                    |> Expect.equal Accessible
        , test "Saved query with datapoint that is no longer present" <|
            \() ->
                Data.Permissions.savedQuery
                    Data.User.Free
                    questionsWithS2
                    audiences
                    accessibleSplitters
                    accessibleLocations
                    accessibleWaves
                    (savedQueryQueryS2WithDatapointCodes [ Data.Id.fromString "s2_1", Data.Id.fromString "foo-bar" ])
                    |> Expect.equal (Unknown { emptyProblematicData | datapoints = Just ( Data.Id.fromString "foo-bar", [] ) })
        ]



-- DATA


savedQuery : SavedQuery
savedQuery =
    { id = Data.Id.fromString ""
    , name = ""
    , position = 0
    , questionCode = Data.Id.fromString ""
    , activeDatapointCodes = []
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


savedQueryWithNoAudience : SavedQuery
savedQueryWithNoAudience =
    { savedQuery | audienceIds = [] }


savedQueryWithNoSplitter : SavedQuery
savedQueryWithNoSplitter =
    { savedQuery | segmentation = Segmentation.empty }


savedQueryWithNoLocation : SavedQuery
savedQueryWithNoLocation =
    let
        filters =
            savedQuery.filters
    in
    { savedQuery | filters = { filters | locationCodes = [] } }


savedQueryWithNoWave : SavedQuery
savedQueryWithNoWave =
    let
        filters =
            savedQuery.filters
    in
    { savedQuery | filters = { filters | waveCodes = [] } }


savedQueryWithNoBaseAudience : SavedQuery
savedQueryWithNoBaseAudience =
    let
        filters =
            savedQuery.filters
    in
    { savedQuery | filters = { filters | baseAudience = Nothing } }


savedQueryQueryS2WithDatapointCodes : List QuestionAndDatapointCode -> SavedQuery
savedQueryQueryS2WithDatapointCodes codes =
    let
        filters =
            savedQuery.filters
    in
    { savedQuery
        | activeDatapointCodes = codes
        , questionCode = Data.Id.fromString "s2"
        , audienceIds = []
        , filters = { filters | baseAudience = Nothing }
    }


audience : Audience
audience =
    { id = Data.Id.fromString ""
    , name = ""
    , created = Time.millisToPosix 0
    , updated = Time.millisToPosix 0
    , userId = 0
    , expression = audienceExpression
    , folderId = Nothing
    , authored = True
    , shared = False
    , curated = False
    }


audienceExpression : AudienceExpression
audienceExpression =
    Data.Audience.Expression.Node Data.Audience.Expression.Or <|
        NonemptyList.singleton
            (Data.Audience.Expression.Leaf
                { inclusion = Include
                , minCount = 1
                , questionCode = Data.Id.fromString ""
                , datapointCodes = []
                , suffixCodes = []
                }
            )


audienceExpressionWithS2 : List QuestionAndDatapointCode -> AudienceExpression
audienceExpressionWithS2 codes =
    Data.Audience.Expression.Node Data.Audience.Expression.And <|
        NonemptyList.singleton
            (Data.Audience.Expression.Leaf
                { inclusion = Include
                , minCount = 1
                , questionCode = Data.Id.fromString "s2"
                , datapointCodes = codes
                , suffixCodes = []
                }
            )


audienceWithS2 : List QuestionAndDatapointCode -> Audience
audienceWithS2 codes =
    { id = Data.Id.fromString ""
    , name = ""
    , created = Time.millisToPosix 0
    , updated = Time.millisToPosix 0
    , userId = 0
    , expression = audienceExpressionWithS2 codes
    , folderId = Nothing
    , authored = True
    , shared = False
    , curated = False
    }


bookmark : Bookmark
bookmark =
    { id = Data.Id.fromString ""
    , name = ""
    , questionCode = Data.Id.fromString ""
    , position = 0
    , suffixCodes = Nothing
    }


questionMock =
    Factory.Question.mock


inaccessibleQuestion : Question
inaccessibleQuestion =
    { questionMock | accessible = False }


questionWithInaccessibleDatapoints : Question
questionWithInaccessibleDatapoints =
    { questionMock
        | code = Data.Id.fromString "s2"
        , datapoints =
            NonemptyList.fromCons
                (Datapoint.mock |> Datapoint.withCode (Data.Id.fromString "s2_1") |> Datapoint.withName "Some accessible" |> Datapoint.accessible)
                [ Datapoint.mock |> Datapoint.withCode (Data.Id.fromString "s2_2") |> Datapoint.withName "Some inacessible" |> Datapoint.inaccessible
                ]
        , accessible = True
    }


questionWithAllDatapointsInaccessible : Question
questionWithAllDatapointsInaccessible =
    { questionMock
        | code = Data.Id.fromString "s2"
        , datapoints =
            NonemptyList.fromCons
                (Datapoint.mock |> Datapoint.withCode (Data.Id.fromString "s2_1") |> Datapoint.inaccessible)
                [ Datapoint.mock |> Datapoint.withCode (Data.Id.fromString "s2_2") |> Datapoint.inaccessible
                ]
        , accessible = True
    }


accessibleQuestion : Question
accessibleQuestion =
    makeAccessible inaccessibleQuestion


inaccessibleSplitter : Splitter
inaccessibleSplitter =
    { code = Data.Id.fromString ""
    , name = ""
    , segments = []
    , accessible = False
    , position = 0
    }


accessibleSplitter : Splitter
accessibleSplitter =
    makeAccessible inaccessibleSplitter


inaccessibleLocation : Location
inaccessibleLocation =
    { code = Data.Id.fromString ""
    , name = ""
    , region = Data.Labels.Euro
    , accessible = False
    }


accessibleLocation : Location
accessibleLocation =
    makeAccessible inaccessibleLocation


inaccessibleWave : Wave
inaccessibleWave =
    (\w -> { w | accessible = False }) Wave.mock


accessibleWave : Wave
accessibleWave =
    makeAccessible inaccessibleWave


toQuestionDict : ( String, Question ) -> IdDict NamespaceAndQuestionCodeTag Question
toQuestionDict =
    Data.Id.dictFromList << List.singleton << Tuple.mapFirst Data.Id.fromString


inaccessibleQuestions : IdDict NamespaceAndQuestionCodeTag Question
inaccessibleQuestions =
    toQuestionDict ( "", inaccessibleQuestion )


accessibleQuestions : IdDict NamespaceAndQuestionCodeTag Question
accessibleQuestions =
    toQuestionDict ( "", accessibleQuestion )


questionsWithS2 : IdDict NamespaceAndQuestionCodeTag Question
questionsWithS2 =
    toQuestionDict ( "s2", questionWithInaccessibleDatapoints )


audiences : IdDict AudienceIdTag Audience
audiences =
    Data.Id.dictFromList [ ( Data.Id.fromString "", audience ) ]


inaccessibleSplitters : IdDict SplitterCodeTag Splitter
inaccessibleSplitters =
    Data.Id.dictFromList [ ( Data.Id.fromString "", inaccessibleSplitter ) ]


accessibleSplitters : IdDict SplitterCodeTag Splitter
accessibleSplitters =
    Data.Id.dictFromList [ ( Data.Id.fromString "", accessibleSplitter ) ]


inaccessibleLocations : IdDict LocationCodeTag Location
inaccessibleLocations =
    Data.Id.dictFromList [ ( Data.Id.fromString "", inaccessibleLocation ) ]


accessibleLocations : IdDict LocationCodeTag Location
accessibleLocations =
    Data.Id.dictFromList [ ( Data.Id.fromString "", accessibleLocation ) ]


inaccessibleWaves : IdDict WaveCodeTag Wave
inaccessibleWaves =
    Data.Id.emptyDict
        |> Dict.Any.insert inaccessibleWave.code inaccessibleWave


accessibleWaves : IdDict WaveCodeTag Wave
accessibleWaves =
    Data.Id.emptyDict
        |> Dict.Any.insert accessibleWave.code accessibleWave


makeAccessible : { a | accessible : Bool } -> { a | accessible : Bool }
makeAccessible record =
    { record | accessible = True }
