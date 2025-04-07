module Store.Platform2 exposing
    ( AudienceRelatedMsg(..)
    , Config
    , Configure
    , Msg(..)
    , Store
    , StoreAction(..)
    , configure
    , getLocationsForNamespaces
    , getWavesForNamespaces
    , init
    , storeActionMany
    , update
    )

import BiDict.Assoc as BiDict exposing (BiDict)
import Config exposing (Flags)
import Data.Id exposing (IdDict)
import Data.Labels as Labels
    exposing
        ( Category
        , CategoryIdTag
        , Location
        , LocationCodeTag
        , NamespaceAndQuestionCodeTag
        , NamespaceCode
        , NamespaceCodeTag
        , NamespaceLineage
        , QuestionV2
        , Region
        , Wave
        , WaveCodeTag
        )
import Data.Platform2
    exposing
        ( Audience
        , AudienceFolder
        , AudienceFolderIdTag
        , AudienceId
        , AudienceIdTag
        , ChartFolder
        , ChartFolderIdTag
        , Dataset
        , DatasetCode
        , DatasetCodeTag
        , Splitter
        , SplitterCodeTag
        , TVChannel
        , TVChannelCodeTag
        , Timezone
        , TimezoneCodeTag
        )
import Dict exposing (Dict)
import Dict.Any
import Gwi.Http exposing (Error, HttpCmd)
import Http
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..), WebData)
import Store.Utils as Store


type alias Config msg =
    { msg : Msg -> msg
    , err : (Store -> Store) -> Error Never -> msg
    , errWithoutModal : (Store -> Store) -> Error Never -> msg
    , simpleErr : Error Never -> msg
    , notFoundError : (Store -> Store) -> msg
    }


type alias Configure msg =
    { msg : Msg -> msg
    , err : (Store -> Store) -> Error Never -> msg
    , errWithoutModal : (Store -> Store) -> Error Never -> msg
    , notFoundError : (Store -> Store) -> msg
    }


configure : Configure msg -> Config msg
configure c =
    { msg = c.msg
    , err = c.err
    , errWithoutModal = c.errWithoutModal
    , simpleErr = c.err identity
    , notFoundError = c.notFoundError
    }


type AudienceRelatedMsg
    = AudienceFoldersFetched (List AudienceFolder)
    | AudiencesFetched (List Audience)


type Msg
    = AudienceRelatedMsg AudienceRelatedMsg
    | LocationsByNamespaceFetched NamespaceCode (List Location)
    | WavesByNamespaceFetched NamespaceCode (List Wave)
    | DatasetsFetched (List Dataset)
    | LineageFetched NamespaceCode NamespaceLineage
    | TimezonesFetched (List Timezone)
    | TVChannelsFetched (List TVChannel)


type StoreAction
    = FetchAudienceFolders
    | FetchAudiences
    | FetchLocationsByNamespace NamespaceCode
    | FetchWavesByNamespace NamespaceCode
    | FetchDatasets
    | FetchLineage NamespaceCode
    | FetchTimezones
    | FetchTVChannels


type alias Store =
    { audienceFolders : WebData (IdDict AudienceFolderIdTag AudienceFolder)
    , audiences : WebData (IdDict AudienceIdTag Audience)
    , audiencesV1ToV2 : WebData (IdDict AudienceIdTag AudienceId)
    , splitters : IdDict NamespaceCodeTag (WebData (IdDict SplitterCodeTag Splitter))
    , questions : IdDict NamespaceAndQuestionCodeTag (WebData QuestionV2)
    , categories : WebData (IdDict CategoryIdTag Category)
    , locations : WebData (IdDict LocationCodeTag Location)
    , locationsByNamespace : IdDict NamespaceCodeTag (WebData (IdDict LocationCodeTag Location))
    , allRegions : WebData (Dict Int Region)
    , regionsByNamespace : IdDict NamespaceCodeTag (WebData (Dict Int Region))
    , waves : WebData (IdDict WaveCodeTag Wave)
    , wavesByNamespace : IdDict NamespaceCodeTag (WebData (IdDict WaveCodeTag Wave))
    , datasets : WebData (IdDict DatasetCodeTag Dataset)
    , datasetsToNamespaces : WebData (BiDict DatasetCode NamespaceCode)
    , chartFolders : WebData (IdDict ChartFolderIdTag ChartFolder)
    , lineages : IdDict NamespaceCodeTag (WebData NamespaceLineage)
    , timezones : WebData (IdDict TimezoneCodeTag Timezone)
    , timezonesOrdered : WebData (List Timezone)
    , tvChannels : WebData (IdDict TVChannelCodeTag TVChannel)
    }


init : Store
init =
    { audienceFolders = NotAsked
    , audiences = NotAsked
    , audiencesV1ToV2 = NotAsked
    , splitters = Data.Id.emptyDict
    , questions = Data.Id.emptyDict
    , categories = NotAsked
    , locations = NotAsked
    , locationsByNamespace = Data.Id.emptyDict
    , allRegions = NotAsked
    , regionsByNamespace = Data.Id.emptyDict
    , waves = NotAsked
    , wavesByNamespace = Data.Id.emptyDict
    , datasets = NotAsked
    , datasetsToNamespaces = NotAsked
    , chartFolders = NotAsked
    , lineages = Data.Id.emptyDict
    , timezones = NotAsked
    , timezonesOrdered = NotAsked
    , tvChannels = NotAsked
    }



-- Network


type alias FetchConfig a b msg =
    { getState : Store -> WebData a
    , setNonSuccess : WebData a -> Store -> Store
    , onSuccess : b -> Msg
    , onError : Maybe (Bool -> (Store -> Store) -> Error Never -> msg)
    , request : Flags -> HttpCmd Never b
    , showErrorModal : Bool
    }


getByNamespacesWithErrors : (NamespaceCode -> Store -> WebData (IdDict a b)) -> NonEmpty NamespaceCode -> Store -> WebData (IdDict a b)
getByNamespacesWithErrors getter maybeNamespaceCodes store =
    maybeNamespaceCodes
        |> NonemptyList.foldr
            (\namespaceCode soFar ->
                case ( soFar, getter namespaceCode store ) of
                    ( NotAsked, Success itemsForNamespace ) ->
                        Success itemsForNamespace

                    ( Loading, _ ) ->
                        soFar

                    ( _, Loading ) ->
                        Loading

                    ( Success items1, Success items2 ) ->
                        Success <| Dict.Any.union items1 items2

                    ( _, Failure err ) ->
                        Failure err

                    _ ->
                        soFar
            )
            NotAsked


getByNamespacesIgnoreErrors : (NamespaceCode -> Store -> WebData (IdDict a b)) -> NonEmpty NamespaceCode -> Store -> WebData (IdDict a b)
getByNamespacesIgnoreErrors getter maybeNamespaceCodes store =
    maybeNamespaceCodes
        |> NonemptyList.foldr
            (\namespaceCode soFar ->
                case ( soFar, getter namespaceCode store ) of
                    ( NotAsked, Success itemsForNamespace ) ->
                        Success itemsForNamespace

                    ( Loading, _ ) ->
                        soFar

                    ( _, Loading ) ->
                        Loading

                    ( Success items1, Success items2 ) ->
                        Success <| Dict.Any.union items1 items2

                    _ ->
                        soFar
            )
            NotAsked


getWavesForNamespaces : NonEmpty NamespaceCode -> Store -> WebData (IdDict WaveCodeTag Wave)
getWavesForNamespaces maybeNamespaceCodes store =
    case getByNamespacesIgnoreErrors getWaves maybeNamespaceCodes store of
        NotAsked ->
            getByNamespacesWithErrors getWaves maybeNamespaceCodes store

        withoutErrors ->
            withoutErrors


getLocationsForNamespaces : NonEmpty NamespaceCode -> Store -> WebData (IdDict LocationCodeTag Location)
getLocationsForNamespaces maybeNamespaceCodes store =
    case getByNamespacesIgnoreErrors getLocations maybeNamespaceCodes store of
        NotAsked ->
            getByNamespacesWithErrors getLocations maybeNamespaceCodes store

        withoutErrors ->
            withoutErrors


getLocations : NamespaceCode -> Store -> WebData (IdDict LocationCodeTag Location)
getLocations namespaceCode =
    .locationsByNamespace
        >> Dict.Any.get namespaceCode
        >> Maybe.withDefault NotAsked


getWaves : NamespaceCode -> Store -> WebData (IdDict WaveCodeTag Wave)
getWaves namespaceCode =
    .wavesByNamespace
        >> Dict.Any.get namespaceCode
        >> Maybe.withDefault NotAsked


fetch_ : FetchConfig a b msg -> Config msg -> Flags -> Store -> ( Store, Cmd msg )
fetch_ r { msg, err, errWithoutModal } flags store =
    let
        errMsg =
            if r.showErrorModal then
                err

            else
                errWithoutModal
    in
    Store.peek
        never
        r.getState
        (msg << r.onSuccess)
        (Maybe.unwrap errMsg (\onError -> \s -> onError r.showErrorModal s) r.onError)
        r.request
        (\store_ result ->
            Maybe.unwrap
                (r.setNonSuccess Loading store_)
                (\e -> r.setNonSuccess (Failure e) store_)
                result
        )
        flags
        store


fetch : StoreAction -> Config msg -> Flags -> Store -> ( Store, Cmd msg )
fetch action =
    let
        fetchWithoutCustomError r =
            fetch_
                { getState = r.getState
                , setNonSuccess = r.setNonSuccess
                , onSuccess = r.onSuccess
                , onError = Nothing
                , request = r.request
                , showErrorModal = r.showErrorModal
                }
    in
    case action of
        FetchAudienceFolders ->
            fetchWithoutCustomError
                { getState = .audienceFolders
                , setNonSuccess = \val store_ -> { store_ | audienceFolders = val }
                , onSuccess = AudienceRelatedMsg << AudienceFoldersFetched
                , request = Data.Platform2.getAudienceFolders
                , showErrorModal = True
                }

        FetchAudiences ->
            fetchWithoutCustomError
                { getState = .audiences
                , setNonSuccess = \val store_ -> { store_ | audiences = val }
                , onSuccess = AudienceRelatedMsg << AudiencesFetched
                , request = Data.Platform2.getAudiences
                , showErrorModal = True
                }

        FetchLocationsByNamespace namespaceCode ->
            fetchWithoutCustomError
                { getState = getLocations namespaceCode
                , setNonSuccess =
                    \val store_ ->
                        let
                            valueToInsert =
                                case val of
                                    Failure (Http.BadStatus 403) ->
                                        Success Data.Id.emptyDict

                                    _ ->
                                        val
                        in
                        { store_
                            | locationsByNamespace =
                                store_.locationsByNamespace
                                    |> Dict.Any.insert namespaceCode valueToInsert
                        }
                , onSuccess = LocationsByNamespaceFetched namespaceCode
                , request = Labels.getLocationsForNamespace namespaceCode
                , showErrorModal = False
                }

        FetchWavesByNamespace namespaceCode ->
            fetchWithoutCustomError
                { getState = getWaves namespaceCode
                , setNonSuccess =
                    \val store_ ->
                        let
                            valueToInsert =
                                case val of
                                    Failure (Http.BadStatus 403) ->
                                        Success Data.Id.emptyDict

                                    _ ->
                                        val
                        in
                        { store_
                            | wavesByNamespace =
                                store_.wavesByNamespace
                                    |> Dict.Any.insert namespaceCode valueToInsert
                        }
                , onSuccess = WavesByNamespaceFetched namespaceCode
                , request = Labels.getWavesForNamespaceV2 namespaceCode
                , showErrorModal = False
                }

        FetchDatasets ->
            fetchWithoutCustomError
                { getState = .datasets
                , setNonSuccess = \val store_ -> { store_ | datasets = val }
                , onSuccess = DatasetsFetched
                , request = Data.Platform2.getDatasets
                , showErrorModal = True
                }

        FetchLineage namespaceCode ->
            fetchWithoutCustomError
                { getState =
                    .lineages
                        >> Dict.Any.get namespaceCode
                        >> Maybe.withDefault NotAsked
                , setNonSuccess =
                    \val store_ ->
                        { store_
                            | lineages =
                                store_.lineages
                                    |> Dict.Any.insert namespaceCode val
                        }
                , onSuccess = LineageFetched namespaceCode
                , request = Labels.getLineage namespaceCode
                , showErrorModal = False
                }

        FetchTimezones ->
            fetchWithoutCustomError
                { getState = .timezonesOrdered
                , setNonSuccess =
                    \list store_ ->
                        { store_
                            | timezonesOrdered = list
                            , timezones = RemoteData.andThen (Store.taggedCollectionLoadedWith .code) list
                        }
                , onSuccess = TimezonesFetched
                , request = Data.Platform2.getTimezones
                , showErrorModal = True
                }

        FetchTVChannels ->
            fetchWithoutCustomError
                { getState = .tvChannels
                , setNonSuccess = \val store_ -> { store_ | tvChannels = val }
                , onSuccess = TVChannelsFetched
                , request = Data.Platform2.getTVChannels
                , showErrorModal = True
                }


storeActionMany : List StoreAction -> Config msg -> Flags -> Store -> ( Store, Cmd msg )
storeActionMany actions config flags store =
    List.foldl
        (\action ( store_, cmds ) ->
            let
                ( newStore, newCmd ) =
                    fetch action config flags store_
            in
            ( newStore, newCmd :: cmds )
        )
        ( store, [] )
        actions
        |> Tuple.mapSecond Cmd.batch


setLocationsForNamespace : NamespaceCode -> List Location -> Store -> Store
setLocationsForNamespace namespaceCode locations store =
    { store
        | locationsByNamespace =
            store.locationsByNamespace
                |> Dict.Any.insert namespaceCode
                    (Store.taggedCollectionLoadedWith .code locations)
        , regionsByNamespace =
            store.regionsByNamespace
                |> Dict.Any.insert namespaceCode
                    (Success <| Labels.groupToRegion locations)
    }


setWavesForNamespace : NamespaceCode -> List Wave -> Store -> Store
setWavesForNamespace namespaceCode waves store =
    { store
        | wavesByNamespace =
            store.wavesByNamespace
                |> Dict.Any.insert namespaceCode
                    (Store.taggedCollectionLoadedWith .code waves)
    }


update : Config msg -> Msg -> Store -> ( Store, Cmd msg )
update _ msg store =
    case msg of
        AudienceRelatedMsg (AudienceFoldersFetched folders) ->
            ( { store | audienceFolders = Store.taggedCollectionLoaded folders }
            , Cmd.none
            )

        AudienceRelatedMsg (AudiencesFetched audiences) ->
            ( { store
                | audiences = Store.taggedCollectionLoaded audiences
                , audiencesV1ToV2 =
                    audiences
                        |> List.map (\a -> ( a.v1Id, a.id ))
                        |> Data.Id.dictFromList
                        |> Success
              }
            , Cmd.none
            )

        LocationsByNamespaceFetched namespaceCode locations ->
            ( setLocationsForNamespace namespaceCode locations store
            , Cmd.none
            )

        WavesByNamespaceFetched namespaceCode waves ->
            ( setWavesForNamespace namespaceCode waves store
            , Cmd.none
            )

        DatasetsFetched datasets ->
            ( { store
                | datasets = Store.taggedCollectionLoadedWith .code datasets
                , datasetsToNamespaces =
                    datasets
                        |> List.map (\ds -> ( ds.code, ds.baseNamespaceCode ))
                        |> BiDict.fromList
                        |> Success
              }
            , Cmd.none
            )

        LineageFetched namespaceCode lineage ->
            ( { store
                | lineages =
                    store.lineages
                        |> Dict.Any.insert namespaceCode (Success lineage)
              }
            , Cmd.none
            )

        TimezonesFetched list ->
            ( { store
                | timezonesOrdered = Success list
                , timezones = Store.taggedCollectionLoadedWith .code list
              }
            , Cmd.none
            )

        TVChannelsFetched channels ->
            ( { store | tvChannels = Store.taggedCollectionLoadedWith .code channels }
            , Cmd.none
            )
