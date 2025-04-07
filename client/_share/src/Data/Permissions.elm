module Data.Permissions exposing
    ( DataPermissions(..)
    , ProblematicData
    , audiencePermissionsErrorCopy
    , bookmark
    , emptyProblematicData
    , filterUnknowns
    , isUpsellNeeded
    , p1Audience
    , questionV1
    , savedQuery
    , unwrapUnknown
    )

import Data.Audience.Expression exposing (LeafData)
import Data.Core
    exposing
        ( Bookmark
        , SavedQuery
        , Splitter
        )
import Data.Id exposing (IdDict)
import Data.Labels
    exposing
        ( Datapoint
        , Location
        , LocationCode
        , LocationCodeTag
        , NamespaceAndQuestionCode
        , NamespaceAndQuestionCodeTag
        , Question
        , QuestionAndDatapointCode
        , SuffixCode
        , Wave
        , WaveCode
        , WaveCodeTag
        )
import Data.Platform2
import Data.SavedQuery.Segmentation exposing (SplitterCode, SplitterCodeTag)
import Data.User exposing (Plan(..))
import Dict.Any
import Gwi.List as List
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Maybe.Extra as Maybe
import Plural
import Set.Any


{-| A codification of possible data states.

Accessible and UpsellNeeded states are mostly obvious: you can either use the
data or you have to buy it if you're freemium user. Enterprise users don't get
any Upsell-able data in their API responses. This mainly concerns "1st class
data" that gets this information (`accessible: Bool`) from the API, ie.
categories, questions, locations, multiplier, waves.

"2nd class data" that doesn't get `accessible: Bool` from the API, ie.
bookmarks, queries, audiences and dashboard widgets, has to derive this from the
1st class data it depends on, though, and can get into the Unknown state if the
1st class data goes missing / unavailable for some reason.

Example:

    1- User creates a bookmark using a (possibly private) question XYZ.
    2- GWI removes the question XYZ.
    -or-
    3- User moves to another organization that doesn't have access to that
       question.

What should happen to that bookmark?

The current answer is to show it with a warning indicator and perhaps disallow
some actions on it. (For what we did previously, look at Git history of this
file and/or the ticket PLAT-486. In short, we didn't render it; and before
even _that_ ticket we had a buggy behaviour where we sometimes showed it with an
upsell cube.)

Instead of spreading booleans across the codebase inconsistently, we decide on
the particular DataPermissions value, and then, in the rest of the codebase, we
`case` on it and have three easy-to-understand states.

-}
type alias ProblematicData =
    { questions : Maybe (NonEmpty NamespaceAndQuestionCode)
    , datapoints : Maybe (NonEmpty QuestionAndDatapointCode)
    , suffixes : Maybe (NonEmpty SuffixCode)
    , p1Audiences : Maybe (NonEmpty Data.Core.AudienceId)
    , p2Audiences : Maybe (NonEmpty Data.Platform2.AudienceId)
    , waves : Maybe (NonEmpty WaveCode)
    , locations : Maybe (NonEmpty LocationCode)
    , splitters : Maybe (NonEmpty SplitterCode)
    }


emptyProblematicData : ProblematicData
emptyProblematicData =
    { questions = Nothing
    , datapoints = Nothing
    , suffixes = Nothing
    , p1Audiences = Nothing
    , p2Audiences = Nothing
    , waves = Nothing
    , locations = Nothing
    , splitters = Nothing
    }


type DataPermissions
    = Accessible
    | UpsellNeeded ProblematicData
    | Unknown ProblematicData


problematicQuestion : NamespaceAndQuestionCode -> ProblematicData
problematicQuestion code =
    { emptyProblematicData | questions = Just <| NonemptyList.singleton code }


problematicDatapoint : QuestionAndDatapointCode -> ProblematicData
problematicDatapoint code =
    { emptyProblematicData | datapoints = Just <| NonemptyList.singleton code }


problematicDatapoints : NonEmpty QuestionAndDatapointCode -> ProblematicData
problematicDatapoints list =
    { emptyProblematicData | datapoints = Just list }


problematicP1Audience : Data.Core.AudienceId -> ProblematicData
problematicP1Audience id =
    { emptyProblematicData | p1Audiences = Just <| NonemptyList.singleton id }


problematicWave : WaveCode -> ProblematicData
problematicWave code =
    { emptyProblematicData | waves = Just <| NonemptyList.singleton code }


problematicLocation : LocationCode -> ProblematicData
problematicLocation code =
    { emptyProblematicData | locations = Just <| NonemptyList.singleton code }


problematicSplitter : SplitterCode -> ProblematicData
problematicSplitter code =
    { emptyProblematicData | splitters = Just <| NonemptyList.singleton code }


{-| We need to check if at least one datapoint is accessible
because this is not checked on API side
-}
questionV1 :
    { q
        | accessible : Bool
        , datapoints : NonEmpty Datapoint
        , code : NamespaceAndQuestionCode
    }
    -> DataPermissions
questionV1 { accessible, datapoints, code } =
    let
        inaccessibleQuestion : ProblematicData
        inaccessibleQuestion =
            problematicQuestion code

        atLeastOneAccessibleDatapoint : DataPermissions
        atLeastOneAccessibleDatapoint =
            NonemptyList.any .accessible datapoints
                |> fromAccessible inaccessibleQuestion
    in
    fromAccessible inaccessibleQuestion accessible
        |> combine atLeastOneAccessibleDatapoint


{-| Bookmark only depends on a question.
-}
bookmark : IdDict NamespaceAndQuestionCodeTag Question -> Bookmark -> DataPermissions
bookmark questions { questionCode } =
    let
        atLeastOneAccessibleDatapoint datapoints =
            NonemptyList.foldl
                (\datapoint acc ->
                    if acc == Accessible || datapoint.accessible then
                        Accessible

                    else
                        fromAccessible
                            (problematicDatapoint datapoint.code)
                            datapoint.accessible
                )
                (Unknown <| problematicDatapoints (NonemptyList.map .code datapoints))
                datapoints
    in
    Dict.Any.get questionCode questions
        |> Maybe.map
            (\{ accessible, datapoints, code } ->
                fromAccessible (problematicQuestion code) accessible
                    |> combine (atLeastOneAccessibleDatapoint datapoints)
            )
        |> Maybe.withDefault (Unknown <| problematicQuestion questionCode)


questionDatapoints : List QuestionAndDatapointCode -> { q | datapoints : NonEmpty Datapoint } -> DataPermissions
questionDatapoints datapointCodes question_ =
    List.foldl
        (\code acc ->
            let
                datapointPermission =
                    question_.datapoints
                        |> NonemptyList.find (\datapoint -> datapoint.code == code)
                        {- Here we're sidestepping the `fromAccessible Nothing`
                           case because it only ever returns Unknown. We need
                           `UnknownDatapoints` though.
                        -}
                        |> Maybe.map (.accessible >> fromAccessible (problematicDatapoint code))
                        |> Maybe.withDefault (Unknown <| problematicDatapoint code)
            in
            combine acc datapointPermission
        )
        Accessible
        datapointCodes


{-| Saved Query depends on:

  - question : Question
  - audiences : List Audience
  - segmentation splitters : List Splitter
  - filters:
      - locations : List Location
      - waves : List Wave
      - audiences : List Audience

We have to find permissions for all of these and `combine` them into one.

-}
savedQuery :
    Plan
    -> IdDict NamespaceAndQuestionCodeTag Question
    -> IdDict Data.Core.AudienceIdTag Data.Core.Audience
    -> IdDict SplitterCodeTag Splitter
    -> IdDict LocationCodeTag Location
    -> IdDict WaveCodeTag Wave
    -> SavedQuery
    -> DataPermissions
savedQuery plan questions audiences splitters locations waves { questionCode, audienceIds, segmentation, filters, activeDatapointCodes } =
    let
        question_ : DataPermissions
        question_ =
            Dict.Any.get questionCode questions
                |> Maybe.map (.accessible >> fromAccessible (problematicQuestion questionCode))
                |> Maybe.withDefault (Unknown <| problematicQuestion questionCode)

        datapoints : DataPermissions
        datapoints =
            Dict.Any.get questionCode questions
                |> Maybe.map (questionDatapoints activeDatapointCodes)
                |> Maybe.withDefault (Unknown <| problematicQuestion questionCode)

        splitter : DataPermissions
        splitter =
            segmentation
                |> Data.SavedQuery.Segmentation.getSplitterCode
                |> Maybe.map
                    (\splitterCode ->
                        Dict.Any.get splitterCode splitters
                            |> Maybe.map
                                (.accessible
                                    >> fromAccessible
                                        (problematicSplitter splitterCode)
                                )
                            |> Maybe.withDefault (Unknown <| problematicSplitter splitterCode)
                    )
                |> Maybe.withDefault Accessible

        filterBaseAudience : DataPermissions
        filterBaseAudience =
            filters.baseAudience
                |> Maybe.map
                    (\audienceId ->
                        Dict.Any.get audienceId audiences
                            |> Maybe.map (p1Audience plan questions)
                            |> Maybe.withDefault (Unknown <| problematicP1Audience audienceId)
                    )
                |> Maybe.withDefault Accessible

        audiences_ : List DataPermissions
        audiences_ =
            audienceIds
                |> List.map
                    (\audienceId ->
                        Dict.Any.get audienceId audiences
                            |> Maybe.map (p1Audience plan questions)
                            |> Maybe.withDefault (Unknown <| problematicP1Audience audienceId)
                    )

        filterLocations : List DataPermissions
        filterLocations =
            filters.locationCodes
                |> List.map
                    (\locationCode ->
                        Dict.Any.get locationCode locations
                            |> Maybe.map (.accessible >> fromAccessible (problematicLocation locationCode))
                            |> Maybe.withDefault (Unknown <| problematicLocation locationCode)
                    )

        filterWaves : List DataPermissions
        filterWaves =
            filters.waveCodes
                |> List.map
                    (\waveCode ->
                        Dict.Any.get waveCode waves
                            |> Maybe.map (.accessible >> fromAccessible (problematicWave waveCode))
                            |> Maybe.withDefault (Unknown <| problematicWave waveCode)
                    )

        allPermissions : List DataPermissions
        allPermissions =
            question_
                :: datapoints
                :: splitter
                :: filterBaseAudience
                :: List.fastConcat
                    [ audiences_
                    , filterLocations
                    , filterWaves
                    ]
    in
    List.foldl combine default allPermissions


{-| Audience depends on the accessibility of the used questions, and on the
enterprise Plan. (If that question is not available in their plan, then
this Audience is off limits -- Unknown.)

We walk (fold) over the expression tree and combine the permissions together.
This doesn't do early return but is easy to read and shouldn't hog performance
that much (audience trees are usually quite shallow).

-}
p1Audience : Plan -> IdDict NamespaceAndQuestionCodeTag Question -> Data.Core.Audience -> DataPermissions
p1Audience plan questions { expression } =
    Data.Audience.Expression.foldr
        (\leaf permissionsSoFar -> combine permissionsSoFar (p1AudienceLeaf plan questions leaf))
        default
        expression


p1AudienceLeaf : Plan -> IdDict NamespaceAndQuestionCodeTag Question -> LeafData -> DataPermissions
p1AudienceLeaf plan questions { questionCode, datapointCodes } =
    let
        canBeUsedInAudienceBuilder : Bool
        canBeUsedInAudienceBuilder =
            plan /= Student

        questionAccessible : Question -> DataPermissions
        questionAccessible question_ =
            if canBeUsedInAudienceBuilder then
                {- Returning `Just False` here would mean UpsellNeeded
                   (the dreaded cube!). Enterprise users don't get questions
                   with `accessible: False` from the API. So, enterprise users
                   will always get `Just True` here (no cube), and freemium
                   users can get both `Just True` and `Just False`.
                -}
                fromAccessible (problematicQuestion question_.code) question_.accessible

            else
                {- Enterprise users might get to this branch, ie. we limit their
                   set of available questions. If they somehow created an
                   audience that filters on the question they don't have access
                   to, that's an Unknown state for the whole Audience.
                -}
                Unknown <| problematicQuestion question_.code
    in
    Dict.Any.get questionCode questions
        |> Maybe.map
            (\question_ ->
                questionAccessible question_
                    |> combine (questionDatapoints datapointCodes question_)
            )
        |> Maybe.withDefault (Unknown <| problematicQuestion questionCode)


fromAccessible : ProblematicData -> Bool -> DataPermissions
fromAccessible problematicDataIfInaccessible accessible =
    if accessible then
        Accessible

    else
        UpsellNeeded problematicDataIfInaccessible


mergeUnique : NonEmpty (Data.Id.Id tag) -> NonEmpty (Data.Id.Id tag) -> NonEmpty (Data.Id.Id tag)
mergeUnique nl1 nl2 =
    let
        inBoth =
            Set.Any.union
                (Data.Id.setFromList (NonemptyList.toList nl1))
                (Data.Id.setFromList (NonemptyList.toList nl2))
    in
    inBoth
        |> Set.Any.toList
        |> NonemptyList.fromList
        |> {- `Nothing` shouldn't happen -} Maybe.withDefault nl1


combineMaybeNonemptylists : Maybe (NonEmpty (Data.Id.Id tag)) -> Maybe (NonEmpty (Data.Id.Id tag)) -> Maybe (NonEmpty (Data.Id.Id tag))
combineMaybeNonemptylists mList1 mList2 =
    case ( mList1, mList2 ) of
        ( Just list1, Just list2 ) ->
            Just <| mergeUnique list1 list2

        ( Just _, Nothing ) ->
            mList1

        ( Nothing, Just _ ) ->
            mList2

        ( Nothing, Nothing ) ->
            Nothing


mergeProblematicData : ProblematicData -> ProblematicData -> ProblematicData
mergeProblematicData data1 data2 =
    { data1
        | questions = combineMaybeNonemptylists data1.questions data2.questions
        , datapoints = combineMaybeNonemptylists data1.datapoints data2.datapoints
        , p1Audiences = combineMaybeNonemptylists data1.p1Audiences data2.p1Audiences
        , p2Audiences = combineMaybeNonemptylists data1.p2Audiences data2.p2Audiences
        , waves = combineMaybeNonemptylists data1.waves data2.waves
        , locations = combineMaybeNonemptylists data1.locations data2.locations
        , splitters = combineMaybeNonemptylists data1.splitters data2.splitters
    }


{-| "Rock-Paper-Scissors" ;)

Unknown variants win over UpsellNeeded and Accessible, and UpsellNeeded wins
over Accessible.

More concretely: If any of SavedQuery's dependencies is Unknown or one of its
variants, the SavedQuery becomes that variant of Unknown too. If none are
Unknown\* but some are UpsellNeeded, it becomes UpsellNeeded too. Only if all
dependencies are Accessible, does the SavedQuery become Accessible.

In this sense, Accessible is the DataPermissions' monoid's zero.
Forall x, `combine x Accessible` == x.

-}
combine : DataPermissions -> DataPermissions -> DataPermissions
combine p1 p2 =
    case ( p1, p2 ) of
        ( Unknown data1, Unknown data2 ) ->
            Unknown <| mergeProblematicData data1 data2

        ( Unknown _, _ ) ->
            p1

        ( _, Unknown _ ) ->
            p2

        ( UpsellNeeded data1, UpsellNeeded data2 ) ->
            UpsellNeeded <| mergeProblematicData data1 data2

        ( UpsellNeeded _, _ ) ->
            p1

        ( _, UpsellNeeded _ ) ->
            p2

        ( Accessible, Accessible ) ->
            Accessible


{-| Basically a `mzero` for a monoid that this datatype is.
Seriously, what have you guys done to me. ~janiczek

(See doc for `combine`.)

-}
default : DataPermissions
default =
    Accessible


getProblematicTypes : ProblematicData -> List ( String, List String )
getProblematicTypes data =
    let
        convert :
            String
            -> NonEmpty (Data.Id.Id tag)
            -> List ( String, List String )
            -> List ( String, List String )
        convert name =
            NonemptyList.toList
                >> List.map Data.Id.unwrap
                >> Tuple.pair name
                >> (::)
    in
    []
        |> Maybe.unwrap identity (convert "Question") data.questions
        |> Maybe.unwrap identity (convert "Data Point") data.datapoints
        |> Maybe.unwrap identity (convert "Audience") data.p1Audiences
        |> Maybe.unwrap identity (convert "Audience") data.p2Audiences
        |> Maybe.unwrap identity (convert "Wave") data.waves
        |> Maybe.unwrap identity (convert "Location") data.locations
        |> Maybe.unwrap identity (convert "Splitter") data.splitters


getUnknownTypesCopy : String -> ProblematicData -> { title : String, message : String }
getUnknownTypesCopy itemName problematicData =
    let
        ( unknownTypeNames, body ) =
            getProblematicTypes problematicData
                |> List.map
                    (\( name, list ) ->
                        let
                            pluralisedName =
                                name ++ Plural.fromInt (List.length list) " Code"
                        in
                        ( pluralisedName
                        , pluralisedName ++ ": " ++ String.join ", " list
                        )
                    )
                |> List.unzip
                |> Tuple.mapBoth (String.join "/") (String.join "\n")
    in
    { title = unknownTypeNames ++ " Missing"
    , message =
        "The "
            ++ itemName
            ++ " contains invalid data: "
            ++ body
            ++ ". Please rebuild your "
            ++ itemName
            ++ " using the same "
            ++ unknownTypeNames
            ++ " or get in touch with us."
    }


audiencePermissionsErrorCopy : DataPermissions -> Maybe { title : String, message : String }
audiencePermissionsErrorCopy permission =
    case permission of
        Accessible ->
            Nothing

        UpsellNeeded _ ->
            Nothing

        Unknown data ->
            Just <| getUnknownTypesCopy "audience" data


filterUnknowns : (ProblematicData -> Maybe (NonEmpty a)) -> DataPermissions -> List a -> List a
filterUnknowns getter permissions =
    case permissions of
        Unknown u ->
            case getter u of
                Just unknownList ->
                    List.filter (\code -> not <| NonemptyList.member code unknownList)

                Nothing ->
                    identity

        _ ->
            identity


unwrapUnknown : a -> (ProblematicData -> a) -> DataPermissions -> a
unwrapUnknown default_ map permissions =
    case permissions of
        Unknown u ->
            map u

        _ ->
            default_


isUpsellNeeded : DataPermissions -> Bool
isUpsellNeeded permissions =
    case permissions of
        UpsellNeeded _ ->
            True

        _ ->
            False
