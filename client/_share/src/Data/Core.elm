module Data.Core exposing
    ( Audience
    , AudienceFolder
    , AudienceFolderId
    , AudienceFolderIdTag
    , AudienceId
    , AudienceIdTag
    , AudienceType(..)
    , Bookmark
    , BookmarkId
    , BookmarkIdTag
    , SavedQuery
    , SavedQueryId
    , SavedQueryIdTag
    , Segment
    , Splitter
    , TVChannel
    , TVChannelCode
    , TVChannelCodeTag
    , Timezone
    , TimezoneCode
    , TimezoneCodeTag
    , audienceDecoder
    , audienceTypeToString
    , defaultAudienceName
    , isAudienceStateInAudienceType
    , savedQueryDecoder
    )

import D3Charts.ChartBuilder
import Data.Audience.Expression
    exposing
        ( AudienceExpression
        )
import Data.Core.DatapointsSort as DatapointsSort exposing (DatapointsSort(..))
import Data.Id as Id exposing (Id)
import Data.Labels
    exposing
        ( LocationCode
        , NamespaceAndQuestionCode
        , QuestionAndDatapointCode
        , SuffixCode
        , WaveCode
        )
import Data.Metric as Metric exposing (Metric)
import Data.SavedQuery.Segmentation
    exposing
        ( SegmentId
        , Segmentation
        , SplitterCode
        )
import Gwi.Json.Decode as Decode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Time exposing (Posix)



-- Config
-- Helpers
-- Adapter
-- Bookmarks


type BookmarkIdTag
    = BookmarkIdTag


type alias BookmarkId =
    Id BookmarkIdTag


type alias Bookmark =
    { id : BookmarkId
    , name : String
    , questionCode : NamespaceAndQuestionCode
    , position : Float
    , suffixCodes : Maybe (NonEmpty SuffixCode)
    }



-- Saved Queries


type SavedQueryIdTag
    = SavedQueryIdTag


type alias SavedQueryId =
    Id SavedQueryIdTag


type alias SavedQuery =
    { id : SavedQueryId
    , name : String
    , position : Float
    , questionCode : NamespaceAndQuestionCode
    , activeDatapointCodes : List QuestionAndDatapointCode
    , suffixCodes : Maybe (NonEmpty SuffixCode)
    , audienceIds : List AudienceId
    , segmentation : Segmentation
    , filters :
        { locationCodes : List LocationCode
        , waveCodes : List WaveCode
        , baseAudience : Maybe AudienceId
        }
    , chartType : D3Charts.ChartBuilder.ChartType
    , metrics : List Metric
    , orderType : DatapointsSort
    }


savedQueryDecoder : Decoder SavedQuery
savedQueryDecoder =
    let
        filtersDecoder =
            Decode.succeed
                (\locationCodes waveCodes audiences ->
                    { waveCodes = waveCodes
                    , locationCodes = locationCodes
                    , baseAudience = audiences |> Maybe.andThen List.head
                    }
                )
                |> Decode.andMap (Decode.withDefault [] (Decode.field "locations" (Decode.list Id.decode)))
                |> Decode.andMap (Decode.withDefault [] (Decode.field "waves" (Decode.list Id.decode)))
                |> Decode.andMap (Decode.withDefault Nothing (Decode.optionalField "audiences" (Decode.list Id.decode)))

        emptyFilters =
            { waveCodes = []
            , locationCodes = []
            , baseAudience = Nothing
            }
    in
    Decode.succeed SavedQuery
        |> Decode.andMap (Decode.field "id" Id.decodeFromInt)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "position" Decode.float)
        |> Decode.andMap (Decode.at [ "query", "question" ] Id.decode)
        |> Decode.andMap (Decode.withDefault [] (Decode.at [ "query", "activeOptions" ] (Decode.list Id.decode)))
        |> Decode.andMap
            (Decode.field "query"
                (Decode.optionalField "suffixes" (Decode.list Id.decodeFromStringOrInt)
                    -- TODO after DB migration change this to Id.decode!
                    |> Decode.map (Maybe.andThen NonemptyList.fromList)
                )
            )
        |> Decode.andMap (Decode.withDefault [] (Decode.at [ "query", "audiences" ] (Decode.list Id.decode)))
        |> Decode.andMap Data.SavedQuery.Segmentation.decoder
        |> Decode.andMap (Decode.withDefault emptyFilters (Decode.at [ "query", "filter" ] filtersDecoder))
        |> Decode.andMap (Decode.withDefault D3Charts.ChartBuilder.AdvancedVerticalBarChart (Decode.at [ "query", "chartType" ] D3Charts.ChartBuilder.chartTypeDecoder))
        |> Decode.andMap (Decode.withDefault [] (Decode.at [ "query", "metrics" ] (Decode.list Metric.decoder)))
        |> Decode.andMap (Decode.withDefault Ascending (Decode.at [ "query", "orderType" ] DatapointsSort.decoder))



-- Widgets
-- Dashboards
-- Audience folders


type AudienceFolderIdTag
    = AudienceFolderIdTag


type alias AudienceFolderId =
    Id AudienceFolderIdTag


type alias AudienceFolder =
    { id : AudienceFolderId
    , name : String
    , curated : Bool
    }



-- Audience Type


type AudienceType
    = User
    | Shared
    | Default


audienceTypeToString : AudienceType -> String
audienceTypeToString audienceType_ =
    case audienceType_ of
        User ->
            "My Audiences"

        Shared ->
            "Shared Audiences"

        Default ->
            "Default Audiences"



-- Audiences


isAudienceStateInAudienceType : AudienceType -> Audience -> Bool
isAudienceStateInAudienceType audienceType_ { authored, shared, curated } =
    case audienceType_ of
        User ->
            authored

        Shared ->
            shared

        Default ->
            curated


type AudienceIdTag
    = AudienceIdTag


type alias AudienceId =
    Id AudienceIdTag


type alias Audience =
    { id : AudienceId
    , name : String
    , created : Posix
    , updated : Posix
    , expression : AudienceExpression
    , folderId : Maybe AudienceFolderId
    , authored : Bool
    , shared : Bool
    , curated : Bool
    , userId : Int
    }


audienceDecoder : Decoder Audience
audienceDecoder =
    Decode.succeed Audience
        |> Decode.andMap (Decode.field "id" Id.decodeFromInt)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "created_at" Decode.unixTimestampSeconds)
        |> Decode.andMap (Decode.field "updated_at" Decode.unixTimestampSeconds)
        |> Decode.andMap (Decode.field "expression" Data.Audience.Expression.decoder)
        |> Decode.andMap (Decode.field "folder" (Decode.maybe Id.decodeFromInt))
        |> Decode.andMap (Decode.field "type" Decode.string |> Decode.map ((==) "user"))
        |> Decode.andMap (Decode.field "shared" Decode.bool)
        |> Decode.andMap
            (Decode.field "curated"
                (Decode.oneOf
                    [ Decode.bool
                    , Decode.succeed False
                    ]
                )
            )
        |> Decode.andMap (Decode.field "user_id" Decode.int)


defaultAudienceName : String
defaultAudienceName =
    "All Internet Users"



-- Splitters


type alias Segment =
    { id : SegmentId
    , name : String
    , accessible : Bool
    }


type alias Splitter =
    { code : SplitterCode
    , name : String
    , segments : List Segment
    , accessible : Bool
    , position : Int
    }



-- TVChannels


type TVChannelCodeTag
    = TVChannelCodeTag


type alias TVChannelCode =
    Id TVChannelCodeTag


type alias TVChannel =
    { code : TVChannelCode
    , name : String
    }



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
