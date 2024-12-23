module XB2.Share.Data.Platform2 exposing
    ( Attribute
    , AttributeCodes
    , AttributeTaxonomyPath
    , Audience
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
    , CompatibilitiesMetadata
    , Dataset
    , DatasetCategory
    , DatasetCode
    , DatasetCodeTag
    , DatasetFolder(..)
    , DatasetFolderData
    , DatasetFolderId
    , DatasetFolderIdTag
    , FullUserEmail
    , Incompatibilities
    , Incompatibility
    , OrganisationId
    , OrganisationIdTag
    , Segment
    , SegmentId
    , SegmentIdTag
    , Splitter
    , SplitterCode
    , SplitterCodeTag
    , Taxonomy
    , Timezone
    , TimezoneCode
    , TimezoneCodeTag
    , UserEmailId
    , UserEmailIdTag
    , attributeDecoder
    , attributeToString
    , audienceDecoder
    , audienceTypeString
    , createAudienceWithExpression
    , datasetCodesForNamespaceCodes
    , datasetsForNamespace
    , datasetsFromExpression
    , deepestNamespaceCode
    , defaultAudienceName
    , encodeAttribute
    , encodeAudienceFolder
    , encodeDatasetForWebcomponent
    , fetchFullUserEmails
    , getAudienceFolders
    , getDatasetFolders
    , getDatasets
    , splitAttributeLabel
    )

import AssocSet
import BiDict.Assoc as BiDict exposing (BiDict)
import Dict.Any exposing (AnyDict)
import Http
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode
import Json.Encode.Extra as Encode
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..), WebData)
import Set.Any exposing (AnySet)
import Time exposing (Posix)
import Url.Builder
import XB2.Data.Namespace as Namespace
import XB2.Share.Config exposing (Flags)
import XB2.Share.Config.Main
import XB2.Share.Data.Audience.Expression as Expression exposing (AudienceExpression)
import XB2.Share.Data.Auth as Auth
import XB2.Share.Data.Id as Id exposing (Id, IdDict, IdSet)
import XB2.Share.Data.Labels
    exposing
        ( CategoryId
        , LocationCode
        , NamespaceLineage
        , ShortDatapointCode
        , ShortQuestionCode
        , SuffixCode
        , WaveCode
        )
import XB2.Share.Gwi.Http exposing (HttpCmd)
import XB2.Share.Gwi.Json.Decode as Decode
import XB2.Share.Gwi.List as List
import XB2.Share.Store.Utils as Store


host : Flags -> String
host =
    .env >> XB2.Share.Config.Main.get >> .uri >> .api



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
        , expect = XB2.Share.Gwi.Http.expectJson identity (Decode.field "data" (Decode.list audienceFolderDecoder))
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


isAudienceCurated : Audience -> Bool
isAudienceCurated audience =
    Set.Any.member CuratedAudience audience.flags


isAudienceAuthored : Audience -> Bool
isAudienceAuthored audience =
    Set.Any.member AuthoredAudience audience.flags


audienceTypeString : Audience -> String
audienceTypeString audience =
    if isAudienceCurated audience then
        "Default Audiences"

    else if isAudienceAuthored audience then
        "My Audiences"

    else
        {- We'd normally use `audience.shared` JSON field here but there's no
           other possibility than:
        -}
        "Shared Audiences"


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


createAudienceWithExpression : String -> AudienceExpression -> Flags -> HttpCmd Never Audience
createAudienceWithExpression audienceName expression flags =
    Http.request
        { method = "POST"
        , headers = [ Auth.header flags.token ]
        , url = Url.Builder.crossOrigin (host flags) [ "v2", "audiences", "saved" ] []
        , body =
            [ ( "name", Encode.string audienceName )
            , ( "flags", Encode.list (audienceFlagToString >> Encode.string) [ IsP2Audience ] )
            , ( "expression", Expression.encodeV2 expression )
            , ( "datasets", Encode.list identity [] ) -- autofill on BE
            ]
                |> Encode.object
                |> Http.jsonBody
        , expect = XB2.Share.Gwi.Http.expectJson identity audienceDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


defaultAudienceName : String
defaultAudienceName =
    "All Internet Users"



-- WIDGETS
-- DASHBOARDS
-- Sharing types
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


type alias AttributeTaxonomyPath =
    { taxonomyPath : List Taxonomy
    , dataset : Maybe Dataset
    }


type alias Taxonomy =
    { id : String
    , name : String
    , order : Float
    , height : Int
    }


type alias Attribute =
    { namespaceCode : Namespace.Code
    , codes : AttributeCodes
    , questionName : String
    , datapointName : String
    , suffixName : Maybe String
    , questionDescription : Maybe String
    , order : Float
    , compatibilitiesMetadata : Maybe CompatibilitiesMetadata
    , taxonomyPaths : Maybe (List AttributeTaxonomyPath)
    }


type alias CompatibilitiesMetadata =
    { hasIncompatibilities : Bool
    , hasCompatibilities : Bool
    }


type alias AttributeCodes =
    { datapointCode : ShortDatapointCode
    , questionCode : ShortQuestionCode
    , suffixCode : Maybe SuffixCode
    }


attributeToString : Attribute -> String
attributeToString { codes } =
    [ Id.unwrap codes.questionCode
    , Id.unwrap codes.datapointCode
    , Maybe.unwrap "" Id.unwrap codes.suffixCode
    ]
        |> String.join "--"


encodeAttributeTaxonomyPath : AttributeTaxonomyPath -> Encode.Value
encodeAttributeTaxonomyPath taxonomyPath =
    Encode.object
        [ ( "taxonomy_path", encodeTaxonomyList taxonomyPath.taxonomyPath )
        , ( "dataset", Encode.maybe encodeDatasetForWebcomponent taxonomyPath.dataset )
        ]


encodeTaxonomy : Taxonomy -> Encode.Value
encodeTaxonomy taxonomy =
    Encode.object
        [ ( "height", Encode.int taxonomy.height )
        , ( "id", Encode.string taxonomy.id )
        , ( "name", Encode.string taxonomy.name )
        , ( "order", Encode.float taxonomy.order )
        ]


encodeTaxonomyList : List Taxonomy -> Encode.Value
encodeTaxonomyList taxonomies =
    Encode.list encodeTaxonomy taxonomies


encodeCompatibilitiesMetadata : CompatibilitiesMetadata -> Encode.Value
encodeCompatibilitiesMetadata metadata =
    Encode.object
        [ ( "has_compatibilities", Encode.bool metadata.hasCompatibilities )
        , ( "has_incompatibilities", Encode.bool metadata.hasIncompatibilities )
        ]


encodeAttribute : { isStaged : Bool, isCalculated : Bool } -> Attribute -> Encode.Value
encodeAttribute { isStaged, isCalculated } attr =
    Encode.object
        [ ( "compatibleAttribute"
          , [ ( "question_label", Encode.string attr.questionName )
            , ( "datapoint_label", Encode.string attr.datapointName )
            , ( "suffix_label"
              , Maybe.unwrap (Encode.string "") Encode.string attr.suffixName
              )
            , ( "namespace_code", Namespace.encodeCode attr.namespaceCode )
            , ( "question_code", Id.encode attr.codes.questionCode )
            , ( "datapoint_code", Id.encode attr.codes.datapointCode )
            , ( "suffix_code"
              , Maybe.unwrap (Encode.string "") Id.encode attr.codes.suffixCode
              )
            , ( "question_description"
              , Maybe.unwrap Encode.null Encode.string attr.questionDescription
              )
            , ( "order", Encode.float attr.order )
            , ( "compatibilities_metadata"
              , Maybe.unwrap Encode.null
                    encodeCompatibilitiesMetadata
                    attr.compatibilitiesMetadata
              )
            , ( "taxonomy_paths"
              , Maybe.unwrap Encode.null
                    (Encode.list encodeAttributeTaxonomyPath)
                    attr.taxonomyPaths
              )
            ]
                |> Encode.object
          )
        , ( "isStaged", Encode.bool isStaged )
        , ( "isCalculated", Encode.bool isCalculated )
        ]


attributeLabelDelimiter : String
attributeLabelDelimiter =
    "»"


splitAttributeLabel :
    String
    ->
        Maybe
            { questionLabel : String
            , datapointLabel : Maybe String
            , suffixLabel : Maybe String
            }
splitAttributeLabel attributeLabel =
    {- This whole function is a giant fragile hack as we are trying to get
       names for question/datapoints/suffix from the P2 attribute label with
       splitting it by "»" from

       "Frequency of Drinks Consumption » Rum » At least once a month"

       These data should be given to us by the P2 BE endpoint instead but they
       are not. If there will be any problem with this piece of code it should
       be solved on the P2 side first.
    -}
    String.split attributeLabelDelimiter attributeLabel
        |> List.map String.trim
        |> (\labels ->
                case labels of
                    [ question, datapoint, suffix ] ->
                        Just
                            { questionLabel = question
                            , datapointLabel = Just datapoint
                            , suffixLabel = Just suffix
                            }

                    [ question, datapoint ] ->
                        Just
                            { questionLabel = question
                            , datapointLabel = Just datapoint
                            , suffixLabel = Nothing
                            }

                    [ question ] ->
                        Just
                            { questionLabel = question
                            , datapointLabel = Nothing
                            , suffixLabel = Nothing
                            }

                    _ ->
                        Nothing
           )


attributeTaxonomyPathDecoder : Decoder AttributeTaxonomyPath
attributeTaxonomyPathDecoder =
    Decode.succeed AttributeTaxonomyPath
        |> Decode.andMap
            (Decode.field "taxonomy_path"
                (Decode.list <|
                    Decode.lazy
                        (\_ ->
                            Decode.succeed Taxonomy
                                |> Decode.andMap (Decode.field "id" Decode.string)
                                |> Decode.andMap (Decode.field "name" Decode.string)
                                |> Decode.andMap (Decode.field "order" Decode.float)
                                |> Decode.andMap (Decode.field "height" Decode.int)
                        )
                )
                |> Decode.maybe
                |> Decode.map (Maybe.withDefault [])
            )
        |> Decode.andMap (Decode.maybe (Decode.field "dataset" datasetDecoder))


emptyStringAsNothing : (String -> a) -> String -> Maybe a
emptyStringAsNothing toExpectedType s =
    if String.isEmpty s then
        Nothing

    else
        Just <| toExpectedType s


attributeDecoder : Decoder Attribute
attributeDecoder =
    Decode.field "compatibleAttribute"
        (Decode.succeed Attribute
            |> Decode.andMap (Decode.field "namespace_code" Namespace.codeDecoder)
            |> Decode.andMap attributeCodesDecoder
            |> Decode.andMap (Decode.field "question_label" Decode.string)
            |> Decode.andMap (Decode.field "datapoint_label" Decode.string)
            |> Decode.andMap
                (Decode.optionalNullableField "suffix_label" Decode.string
                    |> Decode.map (Maybe.andThen (emptyStringAsNothing identity))
                )
            |> Decode.andMap (Decode.maybe (Decode.field "question_description" Decode.string))
            |> Decode.andMap (Decode.field "order" Decode.float)
            |> Decode.andMap (Decode.maybe (Decode.field "compatibilities_metadata" compatibilitiesMetadataDecoder))
            |> Decode.andMap (Decode.optionalField "taxonomy_paths" <| Decode.list attributeTaxonomyPathDecoder)
        )


compatibilitiesMetadataDecoder : Decoder CompatibilitiesMetadata
compatibilitiesMetadataDecoder =
    Decode.succeed CompatibilitiesMetadata
        |> Decode.andMap (Decode.field "has_incompatibilities" Decode.bool)
        |> Decode.andMap (Decode.field "has_compatibilities" Decode.bool)


attributeCodesDecoder : Decoder AttributeCodes
attributeCodesDecoder =
    Decode.succeed AttributeCodes
        |> Decode.andMap (Decode.field "datapoint_code" Id.decode)
        |> Decode.andMap (Decode.field "question_code" Id.decode)
        |> Decode.andMap
            (Decode.optionalField "suffix_code" Decode.string
                |> Decode.map (Maybe.andThen (emptyStringAsNothing Id.fromString))
            )



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
    , baseNamespaceCode : Namespace.Code
    , categories : List DatasetCategory
    , depth : Int
    , order : Float
    }


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
        |> Decode.andMap (Decode.field "base_namespace_code" Namespace.codeDecoder)
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


datasetDecoder : Decoder Dataset
datasetDecoder =
    Decode.succeed Dataset
        |> Decode.andMap (Decode.field "code" Id.decode)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "description" Decode.string)
        |> Decode.andMap (Decode.field "base_namespace_code" Namespace.codeDecoder)
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
        |> Decode.andMap
            (Decode.optionalNullableField "order" Decode.float
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
        , ( "base_namespace_code", Namespace.encodeCode dataset.baseNamespaceCode )
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
        , expect = XB2.Share.Gwi.Http.expectJson identity datasetsDecoder
        , timeout = Nothing
        , tracker = Nothing
        }



-- Datasets folders


type DatasetFolderIdTag
    = DatasetFolderIdTag


type alias DatasetFolderId =
    Id DatasetFolderIdTag


type alias DatasetFolderData =
    { id : DatasetFolderId
    , name : String
    , description : String
    , order : Float
    , datasetCodes : List DatasetCode
    , subfolders : List DatasetFolder
    }


type DatasetFolder
    = DatasetFolder DatasetFolderData


datasetFolderDecoder : Decoder DatasetFolder
datasetFolderDecoder =
    (Decode.succeed DatasetFolderData
        |> Decode.andMap (Decode.field "id" Id.decodeFromStringOrInt)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "description" Decode.string)
        |> Decode.andMap (Decode.field "order" Decode.float)
        |> Decode.andMap
            (Decode.optionalField "child_datasets" (Decode.list <| Decode.field "code" Id.decode)
                |> Decode.map (Maybe.withDefault [])
            )
        |> Decode.andMap
            (Decode.optionalField "child_folders" (Decode.list <| Decode.lazy (\_ -> datasetFolderDecoder))
                |> Decode.map (Maybe.withDefault [])
            )
    )
        |> Decode.map DatasetFolder


getDatasetFolders : Flags -> HttpCmd Never (List DatasetFolder)
getDatasetFolders flags =
    Http.request
        { method = "GET"
        , headers = [ Auth.header flags.token ]
        , url = host flags ++ "/platform/dataset-folders"
        , body = Http.emptyBody
        , expect = XB2.Share.Gwi.Http.expectJson identity (Decode.list datasetFolderDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }



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


type alias Incompatibility =
    { locationCode : LocationCode
    , waveCodes : AnySet String WaveCode
    }


type alias Incompatibilities =
    AnyDict String LocationCode Incompatibility


findDeepestDataset : List DatasetCode -> WebData (IdDict DatasetCodeTag Dataset) -> Maybe Dataset
findDeepestDataset usedDatasets allDatasets =
    Store.getByIds allDatasets usedDatasets
        |> List.reverseSortBy .depth
        |> List.head


deepestDatasetNamespaceCode : List DatasetCode -> WebData (IdDict DatasetCodeTag Dataset) -> Maybe Namespace.Code
deepestDatasetNamespaceCode usedDatasets allDatasets =
    findDeepestDataset usedDatasets allDatasets
        |> Maybe.map .baseNamespaceCode


{-| Normally this would be just a matter of finding a dataset that has the
namespace code as `baseNamespaceCode` (hence the BiDict), but we're not
guaranteed that a namespace _will_ be used by some dataset as a base namespace.

If we don't find a dataset here, we need to move to the nearest ancestor and try
again. For that we need the namespace lineage to be fetched.

-}
datasetsForNamespace : BiDict DatasetCode Namespace.Code -> Dict.Any.AnyDict Namespace.StringifiedCode Namespace.Code (WebData NamespaceLineage) -> Namespace.Code -> WebData (IdSet DatasetCodeTag)
datasetsForNamespace datasetsToNamespaces lineages namespaceCode =
    let
        simple : Namespace.Code -> IdSet DatasetCodeTag
        simple nsCode =
            datasetsToNamespaces
                |> BiDict.getReverse nsCode
                |> AssocSet.toList
                |> Id.setFromList

        recursive : List Namespace.Code -> Namespace.Code -> WebData (IdSet DatasetCodeTag)
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

        ancestors : WebData (List Namespace.Code)
        ancestors =
            Dict.Any.get namespaceCode lineages
                |> Maybe.withDefault NotAsked
                |> RemoteData.map .ancestors
    in
    ancestors
        |> RemoteData.map ((::) namespaceCode)
        |> RemoteData.andThen (\ancestors_ -> recursive ancestors_ namespaceCode)


type OrganisationIdTag
    = OrganisationIdTag


type alias OrganisationId =
    Id OrganisationIdTag


type UserEmailIdTag
    = UserEmailIdTag


type alias UserEmailId =
    Id UserEmailIdTag


type alias FullUserEmail =
    { id : UserEmailId
    , email : String
    , firstName : String
    , lastName : String
    }


fetchFullUserEmails : String -> Flags -> HttpCmd Never (List FullUserEmail)
fetchFullUserEmails term flags =
    Http.request
        { method = "POST"
        , headers = [ Auth.header flags.token ]
        , url = Url.Builder.crossOrigin (host flags) [ "v2", "users", "suggest" ] []
        , body = Http.jsonBody <| Encode.object [ ( "hint", Encode.string term ), ( "limit", Encode.int 3 ) ]
        , expect = XB2.Share.Gwi.Http.expectJson identity fullUserEmailsDecoder
        , tracker = Nothing
        , timeout = Nothing
        }


fullUserEmailsDecoder : Decoder (List FullUserEmail)
fullUserEmailsDecoder =
    Decode.optionalField "users"
        (Decode.list
            (Decode.succeed FullUserEmail
                |> Decode.andMap (Decode.field "id" Id.decodeFromInt)
                |> Decode.andMap (Decode.field "email" Decode.string)
                |> Decode.andMap (Decode.field "first_name" Decode.string)
                |> Decode.andMap (Decode.field "last_name" Decode.string)
            )
        )
        |> Decode.map (Maybe.withDefault [])



-- Timezones


type TimezoneCodeTag
    = TimezoneCodeTag


{-| TimezoneCode == QuestionAndDatapointCode, but for clarity we keep it separate.
There are casting functions available below.
-}
type alias TimezoneCode =
    Id TimezoneCodeTag


type alias Timezone =
    { code : TimezoneCode
    , name : String
    , position : Int
    }



-- TVChannels
-- NUMBER OF MINIMUM IMPRESSIONS
-- TARGET TIMEZONE


datasetCodesForNamespaceCodes : BiDict DatasetCode Namespace.Code -> Dict.Any.AnyDict Namespace.StringifiedCode Namespace.Code (WebData NamespaceLineage) -> List Namespace.Code -> WebData (List DatasetCode)
datasetCodesForNamespaceCodes datasetsToNamespaces lineages namespaceCodes =
    XB2.Share.Data.Labels.compatibleTopLevelNamespaces lineages namespaceCodes
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


datasetsFromExpression : BiDict DatasetCode Namespace.Code -> Dict.Any.AnyDict Namespace.StringifiedCode Namespace.Code (WebData NamespaceLineage) -> AudienceExpression -> WebData (List DatasetCode)
datasetsFromExpression datasetsToNamespaces lineages expression =
    expression
        |> Expression.namespaceCodes
        |> datasetCodesForNamespaceCodes datasetsToNamespaces lineages


deepestNamespaceCode :
    WebData (IdDict DatasetCodeTag Dataset)
    -> WebData (BiDict DatasetCode Namespace.Code)
    -> Dict.Any.AnyDict Namespace.StringifiedCode Namespace.Code (WebData NamespaceLineage)
    -> Namespace.Code
    -> Maybe Namespace.Code
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
