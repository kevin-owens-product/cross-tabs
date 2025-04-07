module Data.Platform2 exposing
    ( Audience
    , AudienceData
    , AudienceFlag(..)
    , AudienceFolder
    , AudienceFolderFlag(..)
    , AudienceFolderId
    , AudienceFolderIdTag
    , AudienceId
    , AudienceIdTag
    , ChartFolder
    , ChartFolderId
    , ChartFolderIdTag
    , ChartId
    , ChartIdTag
    , DashboardFiltersAudiencesMetadata
    , DashboardStoredFilters
    , Dataset
    , DatasetCategory
    , DatasetCode
    , DatasetCodeTag
    , QueryParamsAudience
    , Segment
    , SegmentId
    , SegmentIdTag
    , SimpleFilters
    , Splitter
    , SplitterCode
    , SplitterCodeTag
    , TVChannel
    , TVChannelCode
    , TVChannelCodeTag
    , TargetTimezone(..)
    , TargetTimezoneLabels
    , Timezone
    , TimezoneCode
    , TimezoneCodeTag
    , audienceDecoder
    , coreDatasetCode
    , dashboardFiltersDecoder
    , datasetCodesForNamespaceCodes
    , deepestDatasetNamespaceCode
    , deepestNamespaceCode
    , defaultAudienceName
    , defaultMinimumImpressions
    , encodeAudienceFolder
    , encodeDatasetForWebcomponent
    , encodeMinimumImpressions
    , encodeTargetTimezone
    , getAudienceFolders
    , getAudiences
    , getDatasets
    , getTVChannels
    , getTargetTimezoneCode
    , getTimezones
    , targetTimezoneLabel
    , targetTimezoneToString
    , toAnalyticsAudience
    )

import AssocSet
import BiDict.Assoc as BiDict exposing (BiDict)
import Config exposing (Flags)
import Config.Main
import Data.Audience.Expression as Expression exposing (AudienceExpression)
import Data.Auth as Auth
import Data.Id as Id exposing (Id(..), IdDict, IdSet)
import Data.Labels
    exposing
        ( CategoryId
        , Datapoint
        , LocationCode
        , NamespaceAndQuestionCode
        , NamespaceCode
        , NamespaceCodeTag
        , NamespaceLineage
        , QuestionAndDatapointCode
        , WaveCode
        )
import Dict
import Dict.Any exposing (AnyDict)
import Gwi.Http exposing (HttpCmd)
import Gwi.Json.Decode as Decode
import Gwi.List as List
import Gwi.String as String
import Http
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode
import List.NonEmpty as NonemptyList
import Palette
import RemoteData exposing (RemoteData(..), WebData)
import Set.Any exposing (AnySet)
import Store.Utils as Store
import Time exposing (Posix)
import Url.Builder


host : Flags -> String
host =
    .env >> Config.Main.get >> .uri >> .api



-- AUDIENCE FOLDERS


type AudienceFolderIdTag
    = AudienceFolderIdTag


type alias AudienceFolderId =
    Id AudienceFolderIdTag


type AudienceFolderFlag
    = CuratedFolder
    | AuthoredFolder


audienceFolderFlagToString : AudienceFolderFlag -> String
audienceFolderFlagToString flag =
    case flag of
        CuratedFolder ->
            "curated"

        AuthoredFolder ->
            "authored"


audienceFolderFlagFromString : String -> Maybe AudienceFolderFlag
audienceFolderFlagFromString string =
    case string of
        "curated" ->
            Just CuratedFolder

        "authored" ->
            Just AuthoredFolder

        _ ->
            Nothing


audienceFolderFlagDecoder : Decoder AudienceFolderFlag
audienceFolderFlagDecoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case audienceFolderFlagFromString string of
                    Just flag ->
                        Decode.succeed flag

                    Nothing ->
                        Decode.fail <| "Unknown P2 Audience Folder flag: " ++ string
            )


type alias AudienceFolder =
    { id : AudienceFolderId
    , name : String
    , position : Int
    , flags : AnySet String AudienceFolderFlag
    , createdAt : Posix
    , updatedAt : Posix
    }


audienceFolderDecoder : Decoder AudienceFolder
audienceFolderDecoder =
    Decode.succeed AudienceFolder
        |> Decode.andMap (Decode.field "id" Id.decode)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "position" Decode.int)
        |> Decode.andMap
            (Decode.field "flags"
                (Decode.list audienceFolderFlagDecoder
                    |> Decode.map (Set.Any.fromList audienceFolderFlagToString)
                )
            )
        |> Decode.andMap (Decode.field "created_at" Decode.unixIso8601Decoder)
        |> Decode.andMap (Decode.field "updated_at" Decode.unixIso8601Decoder)


encodeAudienceFolderFlag : AudienceFolderFlag -> Encode.Value
encodeAudienceFolderFlag flag =
    Encode.string <| audienceFolderFlagToString flag


encodeAudienceFolder : AudienceFolder -> Encode.Value
encodeAudienceFolder folder =
    Encode.object
        [ ( "id", Id.encode folder.id )
        , ( "name", Encode.string folder.name )
        , ( "position", Encode.int folder.position )
        , ( "flags", Encode.list encodeAudienceFolderFlag <| Set.Any.toList folder.flags )
        , ( "created_at", Encode.string <| Iso8601.fromTime folder.createdAt )
        , ( "updated_at", Encode.string <| Iso8601.fromTime folder.updatedAt )
        ]


getAudienceFolders : Flags -> HttpCmd Never (List AudienceFolder)
getAudienceFolders flags =
    Http.request
        { method = "GET"
        , headers = [ Auth.header flags.token ]
        , url = host flags ++ "/v2/audiences/saved/folders"
        , body = Http.emptyBody
        , expect = Gwi.Http.expectJson identity (Decode.field "data" (Decode.list audienceFolderDecoder))
        , timeout = Nothing
        , tracker = Nothing
        }



-- AUDIENCES


type AudienceIdTag
    = AudienceIdTag


type alias AudienceId =
    Id AudienceIdTag


type AudienceFlag
    = CuratedAudience
    | AuthoredAudience
    | IsP2Audience


audienceFlagToString : AudienceFlag -> String
audienceFlagToString flag =
    case flag of
        CuratedAudience ->
            "curated"

        AuthoredAudience ->
            "authored"

        IsP2Audience ->
            "isP2"


audienceFlagFromString : String -> Maybe AudienceFlag
audienceFlagFromString string =
    case string of
        "curated" ->
            Just CuratedAudience

        "authored" ->
            Just AuthoredAudience

        "isP2" ->
            Just IsP2Audience

        _ ->
            Nothing


audienceFlagDecoder : Decoder AudienceFlag
audienceFlagDecoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case audienceFlagFromString string of
                    Just flag ->
                        Decode.succeed flag

                    Nothing ->
                        Decode.fail <| "Unknown P2 Audience flag: " ++ string
            )


type alias Audience =
    { id : AudienceId
    , v1Id : AudienceId
    , name : String
    , expression : AudienceExpression
    , folderId : Maybe AudienceFolderId
    , userId : Int
    , position : Int
    , flags : AnySet String AudienceFlag
    , createdAt : Posix
    , updatedAt : Posix
    }


audienceDecoder : Decoder Audience
audienceDecoder =
    Decode.succeed Audience
        |> Decode.andMap (Decode.field "id" Id.decode)
        |> Decode.andMap (Decode.field "v1_id" Id.decodeFromInt)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "expression" Expression.decoder)
        |> Decode.andMap (Decode.field "folder_id" (Decode.nullable Id.decode))
        |> Decode.andMap (Decode.field "user_id" Decode.int)
        |> Decode.andMap (Decode.field "position" Decode.int)
        |> Decode.andMap
            (Decode.field "flags"
                (Decode.list audienceFlagDecoder
                    |> Decode.map (Set.Any.fromList audienceFlagToString)
                )
            )
        |> Decode.andMap (Decode.field "created_at" Decode.unixIso8601Decoder)
        |> Decode.andMap (Decode.field "updated_at" Decode.unixIso8601Decoder)


getAudiences : Flags -> HttpCmd Never (List Audience)
getAudiences flags =
    Http.request
        { method = "GET"
        , headers = [ Auth.header flags.token ]
        , url = host flags ++ "/v2/audiences/saved"
        , body = Http.emptyBody
        , expect = Gwi.Http.expectJson identity (Decode.field "data" (Decode.list audienceDecoder))
        , timeout = Nothing
        , tracker = Nothing
        }


defaultAudienceName : String
defaultAudienceName =
    "All Internet Users"


encodeAudienceStatesForAnalytics : AnySet String AudienceFlag -> Encode.Value
encodeAudienceStatesForAnalytics flags =
    Encode.string <|
        if Set.Any.member AuthoredAudience flags then
            "user"

        else if Set.Any.member CuratedAudience flags then
            "curated"

        else
            -- This case should never happen, as audience that's neither authored nor shared nor curated shouldn't be sent to FE by the BE API.
            -- (BTW, Shared not supported in v2)
            ""


toAnalyticsAudience : Audience -> { id : String, name : String, state : Encode.Value }
toAnalyticsAudience audience =
    { id = Id.unwrap audience.id
    , name = audience.name
    , state = encodeAudienceStatesForAnalytics audience.flags
    }



-- WIDGETS
-- DASHBOARDS
-- Sharing types


type alias DashboardFiltersAudiencesMetadata =
    AnyDict String AudienceId { color : Palette.Color }


type alias AudienceData =
    { id : AudienceId
    , expression : AudienceExpression
    , name : String
    }


type alias DashboardStoredFilters =
    { baseAudience : Maybe AudienceId
    , audiences : Maybe (List AudienceId)
    , audiencesData : Maybe (IdDict AudienceIdTag AudienceData)
    , audiencesMetadata : DashboardFiltersAudiencesMetadata
    , waves : Maybe (List WaveCode)
    , locations : Maybe (List LocationCode)
    }


dashboardFiltersAudiencesMetadataDecoder : Decoder DashboardFiltersAudiencesMetadata
dashboardFiltersAudiencesMetadataDecoder =
    Decode.dict (Decode.field "color" Palette.colorDecoder)
        |> Decode.map
            (Dict.toList
                >> List.map (Tuple.mapBoth Id.fromString (\c -> { color = c }))
                >> Dict.Any.fromList Id.unwrap
            )


dashboardFiltersDecoder : Decoder DashboardStoredFilters
dashboardFiltersDecoder =
    let
        nullableIdList =
            Decode.nullable (Decode.list Id.decode)

        audienceDataDecoder : Decoder AudienceData
        audienceDataDecoder =
            Decode.succeed AudienceData
                |> Decode.andMap (Decode.field "id" Id.decode)
                |> Decode.andMap (Decode.field "expression" Expression.decoder)
                |> Decode.andMap (Decode.field "name" Decode.string)
    in
    Decode.succeed DashboardStoredFilters
        |> Decode.andMap (Decode.field "base_audience" (Decode.nullable Id.decode))
        |> Decode.andMap (Decode.field "audiences" nullableIdList)
        |> Decode.andMap
            (Decode.optionalNullableField "audiences_data"
                (Decode.list audienceDataDecoder
                    |> Decode.map (List.map (\a -> ( a.id, a )) >> Id.dictFromList)
                )
            )
        |> Decode.andMap (Decode.field "audiences_metadata" dashboardFiltersAudiencesMetadataDecoder)
        |> Decode.andMap (Decode.field "waves" nullableIdList)
        |> Decode.andMap (Decode.field "locations" nullableIdList)



-- SPLITTERS


type SegmentIdTag
    = SegmentIdTag


{-| SegmentId == QuestionAndDatapointCode, but for clarity we keep it separate.
There are casting functions available below.
-}
type alias SegmentId =
    Id SegmentIdTag


type alias Segment =
    { id : SegmentId
    , name : String
    , accessible : Bool
    }


type SplitterCodeTag
    = SplitterCodeTag


type alias SplitterCode =
    Id SplitterCodeTag


type alias Splitter =
    { code : SplitterCode
    , name : String
    , segments : List Segment
    , accessible : Bool
    , position : Int
    }



-- ATTRIBUTES
-- Insight Categories
-- Datasets


type alias DatasetCode =
    Id DatasetCodeTag


type DatasetCodeTag
    = DatasetCodeTag


type alias DatasetCategory =
    { id : CategoryId
    , name : String
    , order : Float
    }


type alias Dataset =
    { code : DatasetCode
    , name : String
    , description : String
    , baseNamespaceCode : NamespaceCode
    , categories : List DatasetCategory
    , depth : Int
    , order : Float
    }


coreDatasetCode : DatasetCode
coreDatasetCode =
    Id.fromString "ds-core"


datasetsDecoder : Decoder (List Dataset)
datasetsDecoder =
    Decode.list datasetWithoutOrderDecoder
        |> Decode.map
            (\almostDatasets ->
                almostDatasets
                    |> List.indexedMap (\order toDataset -> toDataset <| toFloat order)
            )


datasetWithoutOrderDecoder : Decoder (Float -> Dataset)
datasetWithoutOrderDecoder =
    Decode.succeed Dataset
        |> Decode.andMap (Decode.field "code" Id.decode)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "description" Decode.string)
        |> Decode.andMap (Decode.field "base_namespace_code" Id.decode)
        |> Decode.andMap
            (Decode.field "categories"
                (Decode.list
                    (Decode.succeed DatasetCategory
                        |> Decode.andMap (Decode.field "id" Id.decode)
                        |> Decode.andMap (Decode.field "name" Decode.string)
                        |> Decode.andMap (Decode.field "order" Decode.float)
                    )
                )
                |> Decode.maybe
                |> Decode.map (Maybe.withDefault [])
            )
        |> Decode.andMap
            (Decode.field "depth" Decode.int
                |> Decode.maybe
                |> Decode.map (Maybe.withDefault 0)
            )


{-| NOTE: This will later be updated to be 1:1 with the decoder, but for that
the webcomponents themselves need to be updated.
-}
encodeDatasetForWebcomponent : Dataset -> Encode.Value
encodeDatasetForWebcomponent dataset =
    Encode.object
        [ ( "code", Id.encode dataset.code )
        , ( "name", Encode.string dataset.name )
        , ( "description", Encode.string dataset.description )
        , ( "base_namespace_code", Id.encode dataset.baseNamespaceCode )
        , ( "categories"
          , Encode.list
                (\category ->
                    Encode.object
                        [ ( "id", Id.encode category.id )
                        , ( "name", Encode.string category.name )
                        , ( "order", Encode.float category.order )
                        ]
                )
                dataset.categories
          )
        , ( "depth", Encode.int dataset.depth )
        , ( "order", Encode.float dataset.order )
        ]


getDatasets : Flags -> HttpCmd Never (List Dataset)
getDatasets flags =
    Http.request
        { method = "GET"
        , headers =
            [ Auth.header flags.token ]
        , url = host flags ++ "/platform/datasets"
        , body = Http.emptyBody
        , expect = Gwi.Http.expectJson identity datasetsDecoder
        , timeout = Nothing
        , tracker = Nothing
        }



-- Datasets folders
-- CHART FOLDERS


type alias ChartFolderId =
    Id ChartFolderIdTag


type ChartFolderIdTag
    = ChartFolderIdTag


type alias ChartFolder =
    { id : ChartFolderId
    , name : String
    , userId : Int
    , createdAt : Posix
    , updatedAt : Posix
    }



-- CHARTS


type ChartIdTag
    = ChartIdTag


type alias ChartId =
    Id ChartIdTag


findDeepestDataset : List DatasetCode -> WebData (IdDict DatasetCodeTag Dataset) -> Maybe Dataset
findDeepestDataset usedDatasets allDatasets =
    Store.getByIds allDatasets usedDatasets
        |> List.reverseSortBy .depth
        |> List.head


deepestDatasetNamespaceCode : List DatasetCode -> WebData (IdDict DatasetCodeTag Dataset) -> Maybe NamespaceCode
deepestDatasetNamespaceCode usedDatasets allDatasets =
    findDeepestDataset usedDatasets allDatasets
        |> Maybe.map .baseNamespaceCode


{-| Normally this would be just a matter of finding a dataset that has the
namespace code as `baseNamespaceCode` (hence the BiDict), but we're not
guaranteed that a namespace _will_ be used by some dataset as a base namespace.

If we don't find a dataset here, we need to move to the nearest ancestor and try
again. For that we need the namespace lineage to be fetched.

-}
datasetsForNamespace : BiDict DatasetCode NamespaceCode -> IdDict NamespaceCodeTag (WebData NamespaceLineage) -> NamespaceCode -> WebData (IdSet DatasetCodeTag)
datasetsForNamespace datasetsToNamespaces lineages namespaceCode =
    let
        simple : NamespaceCode -> IdSet DatasetCodeTag
        simple nsCode =
            datasetsToNamespaces
                |> BiDict.getReverse nsCode
                |> AssocSet.toList
                |> Id.setFromList

        recursive : List NamespaceCode -> NamespaceCode -> WebData (IdSet DatasetCodeTag)
        recursive ancestors_ nsCode =
            let
                simple_ =
                    simple nsCode
            in
            if Set.Any.isEmpty simple_ then
                case ancestors_ of
                    closestAncestor :: restOfAncestors ->
                        recursive restOfAncestors closestAncestor

                    [] ->
                        Success Id.emptySet

            else
                Success simple_

        ancestors : WebData (List NamespaceCode)
        ancestors =
            Dict.Any.get namespaceCode lineages
                |> Maybe.withDefault NotAsked
                |> RemoteData.map .ancestors
    in
    ancestors
        |> RemoteData.map ((::) namespaceCode)
        |> RemoteData.andThen (\ancestors_ -> recursive ancestors_ namespaceCode)



-- Timezones


timezonesQuestionCode : NamespaceAndQuestionCode
timezonesQuestionCode =
    Id.fromString "gwi-ext.q418999"


type TimezoneCodeTag
    = TimezoneCodeTag


{-| TimezoneCode == QuestionAndDatapointCode, but for clarity we keep it separate.
There are casting functions available below.
-}
type alias TimezoneCode =
    Id TimezoneCodeTag


{-| Not all datapoint codes are timezone codes - USE SPARINGLY AND CAREFULLY!
-}
unsafeDatapointCodeToTimezoneCode : QuestionAndDatapointCode -> TimezoneCode
unsafeDatapointCodeToTimezoneCode (Id id) =
    Id id


type alias Timezone =
    { code : TimezoneCode
    , name : String
    , position : Int
    }


timezoneFromDatapoint : Int -> Datapoint -> Timezone
timezoneFromDatapoint position datapoint =
    { code = unsafeDatapointCodeToTimezoneCode datapoint.code
    , name = datapoint.name
    , position = position
    }


getTimezones : Flags -> HttpCmd Never (List Timezone)
getTimezones flags =
    Data.Labels.getQuestionV2 timezonesQuestionCode flags
        |> Cmd.map
            (Result.map
                (.datapoints
                    >> NonemptyList.toList
                    >> List.sortBy .order
                    >> List.indexedMap timezoneFromDatapoint
                )
            )



-- TVChannels


type TVChannelCodeTag
    = TVChannelCodeTag


type alias TVChannelCode =
    Id TVChannelCodeTag


type alias TVChannel =
    { code : TVChannelCode
    , name : String
    , metadata : Maybe String
    }


tvChannelDecoder : Decoder TVChannel
tvChannelDecoder =
    Decode.succeed Tuple.pair
        |> Decode.andMap (Decode.field "code" Id.decode)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.map
            (\( code, label ) ->
                let
                    { name, metadata } =
                        parseTVChannelLabel label
                in
                { code = code
                , name = name
                , metadata = metadata
                }
            )


getTVChannels : Flags -> HttpCmd Never (List TVChannel)
getTVChannels flags =
    Http.request
        { method = "GET"
        , headers = [ Auth.header flags.token ]
        , url =
            Url.Builder.crossOrigin (host flags)
                [ "v1", "tvrf", "query", "datapoints" ]
                []
        , body = Http.emptyBody
        , expect =
            Gwi.Http.expectJson identity <|
                Decode.field "datapoints" (Decode.list tvChannelDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


parseTVChannelLabel : String -> { name : String, metadata : Maybe String }
parseTVChannelLabel label =
    {- We could do this in a better way (also checking for ")" or whatever) but
       it worked in TV1 for so long... :shrug:
    -}
    let
        startOfMeta =
            String.indices "(" label
                |> List.head
                |> Maybe.withDefault -1

        endOfMeta =
            String.length label

        channelName =
            String.slice 0 startOfMeta label

        channelMeta =
            String.slice startOfMeta endOfMeta label
    in
    { name = String.trim channelName
    , metadata =
        if String.isEmpty channelMeta then
            Nothing

        else
            Just channelMeta
    }



-- NUMBER OF MINIMUM IMPRESSIONS


defaultMinimumImpressions : Int
defaultMinimumImpressions =
    1



-- TARGET TIMEZONE


type TargetTimezone
    = Local
    | Standardized TimezoneCode


getTargetTimezoneCode : TargetTimezone -> Maybe TimezoneCode
getTargetTimezoneCode targetTimezone =
    case targetTimezone of
        Local ->
            Nothing

        Standardized code ->
            Just code


targetTimezoneToString : TargetTimezone -> String
targetTimezoneToString targetTimezone =
    case targetTimezone of
        Local ->
            ""

        Standardized code ->
            Id.unwrap code


encodeTargetTimezone : TargetTimezone -> Encode.Value
encodeTargetTimezone =
    Encode.string << targetTimezoneToString


encodeMinimumImpressions : Int -> Encode.Value
encodeMinimumImpressions =
    List.singleton
        >> Encode.list Encode.int


type alias TargetTimezoneLabels =
    { local : String
    , standardized : String -> String
    }


targetTimezoneLabel : TargetTimezoneLabels -> WebData (IdDict TimezoneCodeTag Timezone) -> TargetTimezone -> String
targetTimezoneLabel labels timezones targetTimezone =
    case targetTimezone of
        Local ->
            labels.local

        Standardized timezoneCode ->
            let
                timezoneName : RemoteData String String
                timezoneName =
                    timezones
                        |> RemoteData.mapError String.fromHttpError
                        |> RemoteData.andThen
                            (Dict.Any.get timezoneCode
                                >> Maybe.map .name
                                >> RemoteData.fromMaybe "timezone name not found for the code"
                            )
            in
            case timezoneName of
                -- in non-success cases at least give them the ID? :shrug:
                NotAsked ->
                    Id.unwrap timezoneCode ++ " - error getting timezone name"

                Loading ->
                    Id.unwrap timezoneCode ++ " - loading timezone name"

                Failure err ->
                    Id.unwrap timezoneCode ++ " - error getting timezone name: " ++ err

                Success name ->
                    labels.standardized name


datasetCodesForNamespaceCodes : BiDict DatasetCode NamespaceCode -> IdDict NamespaceCodeTag (WebData NamespaceLineage) -> List NamespaceCode -> WebData (List DatasetCode)
datasetCodesForNamespaceCodes datasetsToNamespaces lineages namespaceCodes =
    Data.Labels.compatibleTopLevelNamespaces lineages namespaceCodes
        |> RemoteData.map
            (\compatibleNamespacesSet ->
                compatibleNamespacesSet
                    |> Set.Any.toList
                    |> List.map (datasetsForNamespace datasetsToNamespaces lineages)
                    {- We might later find out we need to load all the
                       NotAsked resulting from ↑ (ensure they are all
                       Successes) instead of filtering them out ↓ ... but
                       for now this seems to work.
                    -}
                    |> List.remoteDataValues
                    |> List.foldl Set.Any.union Id.emptySet
                    |> Set.Any.toList
            )


deepestNamespaceCode :
    WebData (IdDict DatasetCodeTag Dataset)
    -> WebData (BiDict DatasetCode NamespaceCode)
    -> IdDict NamespaceCodeTag (WebData NamespaceLineage)
    -> NamespaceCode
    -> Maybe NamespaceCode
deepestNamespaceCode datasets datasetsToNamespaces lineages namespaceCode =
    let
        namespaceDatasets : WebData (List DatasetCode)
        namespaceDatasets =
            datasetsToNamespaces
                |> RemoteData.andThen
                    (\datasetsToNamespaces_ ->
                        datasetsForNamespace
                            datasetsToNamespaces_
                            lineages
                            namespaceCode
                    )
                |> RemoteData.map Set.Any.toList
    in
    namespaceDatasets
        |> RemoteData.toMaybe
        |> Maybe.andThen
            (\usedDatasets ->
                deepestDatasetNamespaceCode
                    usedDatasets
                    datasets
            )



-- Global search shared state for Dashboards


type alias QueryParamsAudience =
    { id : AudienceId, name : String, expression : AudienceExpression, flags : Maybe (AnySet String AudienceFlag) }


{-| An interface so that we don't have to import D2 stuff from within \_share
-}
type alias SimpleFilters =
    { baseAudience : Maybe QueryParamsAudience
    , audiences : List QueryParamsAudience
    , locations : List LocationCode
    , waves : List WaveCode
    }
