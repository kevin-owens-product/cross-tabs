module Store.Core exposing
    ( Store
    , init
    )

-- Modules

import Data.Core
    exposing
        ( Audience
        , AudienceFolder
        , AudienceFolderIdTag
        , AudienceIdTag
        , Bookmark
        , BookmarkIdTag
        , SavedQuery
        , SavedQueryIdTag
        , Splitter
        , TVChannel
        , TVChannelCodeTag
        , Timezone
        , TimezoneCodeTag
        )
import Data.Id exposing (IdDict)
import Data.Labels
    exposing
        ( Category
        , CategoryIdTag
        , Location
        , LocationCodeTag
        , NamespaceAndQuestionCodeTag
        , NamespaceCodeTag
        , Question
        , Region
        , Wave
        , WaveCodeTag
        )
import Data.SavedQuery.Segmentation exposing (SplitterCodeTag)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..), WebData)


type alias Store =
    { categories : WebData (IdDict CategoryIdTag Category)
    , questions : WebData (IdDict NamespaceAndQuestionCodeTag Question)
    , bookmarks : WebData (IdDict BookmarkIdTag Bookmark)
    , savedQueries : WebData (IdDict SavedQueryIdTag SavedQuery)
    , locations : WebData (IdDict LocationCodeTag Location)
    , locationsByNamespace : IdDict NamespaceCodeTag (WebData (IdDict LocationCodeTag Location))
    , allRegions : WebData (Dict Int Region)
    , regionsByNamespace : IdDict NamespaceCodeTag (WebData (Dict Int Region))
    , waves : WebData (IdDict WaveCodeTag Wave)
    , wavesByNamespace : IdDict NamespaceCodeTag (WebData (IdDict WaveCodeTag Wave))
    , splitters : IdDict NamespaceCodeTag (WebData (IdDict SplitterCodeTag Splitter))
    , tvChannels : WebData (IdDict TVChannelCodeTag TVChannel)
    , timezones : WebData (IdDict TimezoneCodeTag Timezone)
    , timezonesOrdered : WebData (List Timezone)
    , audiences : WebData (IdDict AudienceIdTag Audience)
    , audienceFolders : WebData (IdDict AudienceFolderIdTag AudienceFolder)
    }


init : Store
init =
    { categories = NotAsked
    , questions = NotAsked
    , bookmarks = NotAsked
    , savedQueries = NotAsked
    , locations = NotAsked
    , locationsByNamespace = Data.Id.emptyDict
    , allRegions = NotAsked
    , regionsByNamespace = Data.Id.emptyDict
    , waves = NotAsked
    , wavesByNamespace = Data.Id.emptyDict
    , splitters = Data.Id.emptyDict
    , audiences = NotAsked
    , audienceFolders = NotAsked
    , tvChannels = NotAsked
    , timezones = NotAsked
    , timezonesOrdered = NotAsked
    }



-- Network
-- Update
{- refresh* functions are a variant on the fetch* functions;
   they return the Cmds unconditionally even when the current store is not NotAsked
-}
