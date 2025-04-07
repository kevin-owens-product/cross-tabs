module Data.Cleanup exposing (cleanupSavedQuery, cleanupTemporaryQuery)

import Data.Core exposing (AudienceId, SavedQuery)
import Data.Id as Id exposing (IdDict, IdSet)
import Data.Labels
    exposing
        ( LocationCode
        , NamespaceAndQuestionCode
        , NamespaceAndQuestionCodeTag
        , Question
        , QuestionAndDatapointCode
        , QuestionAndDatapointCodeTag
        , SuffixCode
        , SuffixCodeTag
        , WaveCode
        )
import Data.Permissions exposing (DataPermissions)
import Data.SavedQuery.Segmentation as Segmentation exposing (Segmentation)
import Data.TemporaryQuery exposing (TemporaryQuery)
import Dict.Any
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Maybe.Extra as Maybe
import Set.Any


cleanSuffixes : Question -> Maybe (NonEmpty SuffixCode) -> Maybe (NonEmpty SuffixCode)
cleanSuffixes question suffixCodes =
    let
        questionSuffixes : IdSet SuffixCodeTag
        questionSuffixes =
            question.suffixes
                |> Maybe.map NonemptyList.toList
                |> Maybe.withDefault []
                |> List.map .code
                |> Id.setFromList
    in
    suffixCodes
        |> Maybe.andThen (NonemptyList.filter (\suffix -> Set.Any.member suffix questionSuffixes))


cleanSegmentation : DataPermissions -> Segmentation -> Segmentation
cleanSegmentation permissions segmentation =
    Data.Permissions.unwrapUnknown segmentation
        (.splitters
            >> Maybe.map2
                (\splitterCode unknownSplitterCodes ->
                    if NonemptyList.member splitterCode unknownSplitterCodes then
                        Segmentation.empty

                    else
                        segmentation
                )
                (Segmentation.getSplitterCode segmentation)
            >> Maybe.withDefault segmentation
        )
        permissions


cleanDatapoints : Question -> List QuestionAndDatapointCode -> Maybe (List QuestionAndDatapointCode)
cleanDatapoints question datapointsList =
    -- OK datapoint codes imply the question code is also OK
    let
        questionDatapoints : IdSet QuestionAndDatapointCodeTag
        questionDatapoints =
            question.datapoints
                |> NonemptyList.toList
                |> List.map .code
                |> Id.setFromList
    in
    datapointsList
        |> List.filter (\dp -> Set.Any.member dp questionDatapoints)
        |> Just
        |> Maybe.filter (not << List.isEmpty)


cleanBaseAudience_ : DataPermissions -> Maybe AudienceId -> Maybe AudienceId
cleanBaseAudience_ permissions baseAudience =
    Data.Permissions.unwrapUnknown baseAudience
        (\unknownData ->
            Maybe.andThen2
                (\audiences_ baseAudience_ ->
                    if NonemptyList.member baseAudience_ audiences_ then
                        Nothing

                    else
                        baseAudience
                )
                unknownData.p1Audiences
                baseAudience
        )
        permissions


cleanQueryDatapoints : Question -> { q | activeDatapointCodes : List QuestionAndDatapointCode } -> Maybe { q | activeDatapointCodes : List QuestionAndDatapointCode }
cleanQueryDatapoints question query =
    cleanDatapoints question query.activeDatapointCodes
        |> Maybe.map (\filteredDatapointCodes -> { query | activeDatapointCodes = filteredDatapointCodes })


cleanQuerySuffixes : Question -> { q | suffixCodes : Maybe (NonEmpty SuffixCode) } -> { q | suffixCodes : Maybe (NonEmpty SuffixCode) }
cleanQuerySuffixes question query =
    cleanSuffixes question query.suffixCodes
        |> (\suffixes -> { query | suffixCodes = suffixes })


cleanQuerySegments : DataPermissions -> { q | segmentation : Segmentation } -> { q | segmentation : Segmentation }
cleanQuerySegments permissions query =
    cleanSegmentation permissions query.segmentation
        |> (\segmentation -> { query | segmentation = segmentation })


cleanQueryBaseAudience : DataPermissions -> { q | filters : { f | baseAudience : Maybe AudienceId } } -> { q | filters : { f | baseAudience : Maybe AudienceId } }
cleanQueryBaseAudience permissions query =
    cleanBaseAudience_ permissions query.filters.baseAudience
        |> (\baseAudience ->
                let
                    updateBaseAudience f =
                        { f | baseAudience = baseAudience }
                in
                { query | filters = updateBaseAudience query.filters }
           )


cleanQueryLocations : DataPermissions -> { q | filters : { f | locationCodes : List LocationCode } } -> { q | filters : { f | locationCodes : List LocationCode } }
cleanQueryLocations permissions query =
    Data.Permissions.filterUnknowns .locations permissions query.filters.locationCodes
        |> (\locations ->
                let
                    updateLocations f =
                        { f | locationCodes = locations }
                in
                { query | filters = updateLocations query.filters }
           )


cleanQueryWaves : DataPermissions -> { q | filters : { f | waveCodes : List WaveCode } } -> { q | filters : { f | waveCodes : List WaveCode } }
cleanQueryWaves permissions query =
    Data.Permissions.filterUnknowns .waves permissions query.filters.waveCodes
        |> (\waves ->
                let
                    updateWaves f =
                        { f | waveCodes = waves }
                in
                { query | filters = updateWaves query.filters }
           )


cleanQueryAudiences : DataPermissions -> { q | audienceIds : List AudienceId } -> { q | audienceIds : List AudienceId }
cleanQueryAudiences permissions query =
    { query
        | audienceIds =
            query.audienceIds
                |> Data.Permissions.filterUnknowns .p1Audiences permissions
    }


cleanupSavedQuery : IdDict NamespaceAndQuestionCodeTag Question -> DataPermissions -> SavedQuery -> Maybe SavedQuery
cleanupSavedQuery questions permissions savedQuery =
    Dict.Any.get savedQuery.questionCode questions
        |> Maybe.andThen
            (\question ->
                savedQuery
                    |> cleanQueryDatapoints question
                    |> Maybe.map
                        (cleanQuerySuffixes question
                            >> cleanQuerySegments permissions
                            >> cleanQueryLocations permissions
                            >> cleanQueryWaves permissions
                            >> cleanQueryBaseAudience permissions
                            >> cleanQueryAudiences permissions
                        )
            )


cleanupTemporaryQuery :
    IdDict NamespaceAndQuestionCodeTag Question
    -> DataPermissions
    -> NamespaceAndQuestionCode
    -> TemporaryQuery
    -> Maybe TemporaryQuery
cleanupTemporaryQuery questions permissions questionCode temporaryQuery =
    Dict.Any.get questionCode questions
        |> Maybe.andThen
            (\question ->
                temporaryQuery
                    |> cleanQueryDatapoints question
                    |> Maybe.map
                        (cleanQuerySuffixes question
                            >> cleanQuerySegments permissions
                            >> cleanQueryLocations permissions
                            >> cleanQueryWaves permissions
                            >> cleanQueryBaseAudience permissions
                            >> cleanQueryAudiences permissions
                        )
            )
