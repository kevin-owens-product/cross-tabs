module Platform2.Drawers exposing
    ( Drawer(..)
    , LocationsConfig
    , LocationsDrawer
    , LocationsDrawerNavigation
    , MinimumImpressionsConfig
    , Model
    , Msg(..)
    , ReadonlyConfig
    , TVChannelsConfig
    , TimezonesConfig
    , WavesConfig
    , WavesDrawer
    , close
    , init
    , openLocations
    , openLocationsReadonly
    , openMinimumImpressions
    , openMinimumImpressionsReadonly
    , openTVChannels
    , openTVChannelsReadonly
    , openTimezones
    , openTimezonesReadonly
    , openWaves
    , openWavesReadonly
    , update
    , view
    )

import Cmd.Extra as Cmd
import Data.Id exposing (Id, IdDict, IdSet)
import Data.Labels
    exposing
        ( Location
        , LocationCode
        , LocationCodeTag
        , RegionCode
        , Wave
        , WaveCode
        , WaveCodeTag
        , WaveYear
        )
import Data.Platform2
    exposing
        ( TVChannel
        , TVChannelCode
        , TVChannelCodeTag
        , TargetTimezone(..)
        )
import Dict
import Dict.Any exposing (AnyDict)
import Gwi.List as List
import Gwi.Set as Set
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import Html.Extra as Html
import Icons exposing (IconData)
import Icons.Platform2 as P2Icons
import Maybe.Extra as Maybe
import Platform2.Spinner as Spinner
import Plural
import RemoteData exposing (RemoteData(..), WebData)
import Set exposing (Set)
import Set.Any exposing (AnySet)
import Store.Platform2
import Store.Utils as Store
import Time
import WeakCss exposing (ClassName)


type alias DefaultConfig msg a =
    { a | msg : Msg -> msg }


type alias WavesConfig msg =
    DefaultConfig msg { applyWavesSelection : IdSet WaveCodeTag -> msg }


type alias LocationsConfig msg =
    DefaultConfig msg { applyLocationsSelection : IdSet LocationCodeTag -> Bool -> msg }


type alias TVChannelsConfig msg =
    DefaultConfig msg { applyTVChannelsSelection : IdSet TVChannelCodeTag -> msg }


type alias TimezonesConfig msg =
    DefaultConfig msg { applyTimezoneSelection : TargetTimezone -> msg }


type alias MinimumImpressionsConfig msg =
    DefaultConfig msg { applyMinimumImpressionsSelection : Int -> msg }


type alias ReadonlyConfig msg =
    DefaultConfig msg {}


type Drawer msg
    = Closed
    | Waves (WavesConfig msg) WavesDrawer
    | WavesReadonly (ReadonlyConfig msg) WavesReadonlyDrawer
    | Locations (LocationsConfig msg) LocationsDrawer
    | LocationsReadonly (ReadonlyConfig msg) LocationsReadonlyDrawer
    | TVChannels (TVChannelsConfig msg) TVChannelsDrawer
    | TVChannelsReadonly (ReadonlyConfig msg) TVChannelsReadonlyDrawer
    | Timezones (TimezonesConfig msg) TimezonesDrawer
    | TimezonesReadonly (ReadonlyConfig msg) TimezonesReadonlyDrawer
    | MinimumImpressions (MinimumImpressionsConfig msg) MinimumImpressionsDrawer
    | MinimumImpressionsReadonly (ReadonlyConfig msg) MinimumImpressionsReadonlyDrawer


type LocationsDrawerNavigation
    = LocationsRoot
    | Search String


type alias LocationsDrawer =
    { navigation : LocationsDrawerNavigation
    , selectedLocations : IdSet LocationCodeTag
    , initialSelectedLocations : IdSet LocationCodeTag
    , openedRegions : AnySet Int RegionCode
    , segmenting : Maybe Bool
    , initialSegmenting : Maybe Bool
    , getLocations : Store.Platform2.Store -> WebData (IdDict LocationCodeTag Location)
    , footerWarning : Maybe String
    }


type alias LocationsReadonlyDrawer =
    { selectedLocations : IdSet LocationCodeTag
    , getLocations : Store.Platform2.Store -> WebData (IdDict LocationCodeTag Location)
    }


type alias WavesDrawer =
    { selectedWaves : IdSet WaveCodeTag
    , initialSelectedWaves : IdSet WaveCodeTag
    , openedYears : Set Int
    , getWaves : Store.Platform2.Store -> WebData (IdDict WaveCodeTag Wave)
    , footerWarning : Maybe String
    }


type alias WavesReadonlyDrawer =
    { selectedWaves : IdSet WaveCodeTag
    , getWaves : Store.Platform2.Store -> WebData (IdDict WaveCodeTag Wave)
    }


type alias TVChannelsDrawer =
    { selectedChannels : IdSet TVChannelCodeTag
    , initialSelectedChannels : IdSet TVChannelCodeTag
    , searchTerm : String
    }


type alias TVChannelsReadonlyDrawer =
    { selectedChannels : IdSet TVChannelCodeTag }


type alias TimezonesDrawer =
    { selectedTimezone : TargetTimezone
    , isFolderOpen : Bool
    }


type alias TimezonesReadonlyDrawer =
    { selectedTimezone : TargetTimezone }


type alias MinimumImpressionsDrawer =
    { selectedMinimumImpressions : Int
    }


type alias MinimumImpressionsReadonlyDrawer =
    { selectedMinimumImpressions : Int }


mapWavesDrawer : (WavesDrawer -> WavesDrawer) -> Drawer msg -> Drawer msg
mapWavesDrawer fn drawer =
    case drawer of
        Waves config wavesDrawer ->
            Waves config <| fn wavesDrawer

        _ ->
            drawer


mapLocationsDrawer : (LocationsDrawer -> LocationsDrawer) -> Drawer msg -> Drawer msg
mapLocationsDrawer fn drawer =
    case drawer of
        Locations config locationsDrawer ->
            Locations config <| fn locationsDrawer

        _ ->
            drawer


mapTVChannelsDrawer : (TVChannelsDrawer -> TVChannelsDrawer) -> Drawer msg -> Drawer msg
mapTVChannelsDrawer fn drawer =
    case drawer of
        TVChannels config tvChannelsDrawer ->
            TVChannels config <| fn tvChannelsDrawer

        _ ->
            drawer


mapTimezonesDrawer : (TimezonesDrawer -> TimezonesDrawer) -> Drawer msg -> Drawer msg
mapTimezonesDrawer fn drawer =
    case drawer of
        Timezones config timezonesDrawer ->
            Timezones config <| fn timezonesDrawer

        _ ->
            drawer


mapMinimumImpressionsDrawer :
    (MinimumImpressionsDrawer -> MinimumImpressionsDrawer)
    -> Drawer msg
    -> Drawer msg
mapMinimumImpressionsDrawer fn drawer =
    case drawer of
        MinimumImpressions config minimumImpressionsDrawer ->
            MinimumImpressions config <| fn minimumImpressionsDrawer

        _ ->
            drawer


type alias Model msg =
    Drawer msg


init : Model msg
init =
    Closed


type Msg
    = CloseDrawer
    | ToggleWaveSublist WaveYear
    | ToggleLocationsSublist RegionCode
    | LocationsDrawerInputChanged String
    | LocationsDrawerClearInput
    | ToggleWaveInDrawer Wave
    | ToggleLocationInDrawer Location
    | SelectLocations (List LocationCode)
    | SelectWaves (List WaveCode)
    | ToggleSegmenting
    | TVChannelsDrawerInputChanged String
    | TVChannelsDrawerClearInput
    | ToggleTVChannel TVChannelCode
    | SelectTimezone TargetTimezone
    | SelectMinimumImpressions Int
    | ToggleTimezoneFolder



{----- UPDATES ----}


update : Store.Platform2.Store -> Msg -> Model msg -> ( Model msg, Cmd msg )
update _ msg model =
    case msg of
        CloseDrawer ->
            ( Closed, Cmd.none )

        ToggleWaveSublist year ->
            let
                updatedDrawer wavesDrawer =
                    { wavesDrawer | openedYears = Set.toggle year wavesDrawer.openedYears }
            in
            mapWavesDrawer updatedDrawer model
                |> Cmd.pure

        ToggleLocationsSublist region ->
            let
                updatedDrawer locationsDrawer =
                    { locationsDrawer | openedRegions = Set.Any.toggle region locationsDrawer.openedRegions }
            in
            mapLocationsDrawer updatedDrawer model
                |> Cmd.pure

        LocationsDrawerInputChanged searchTerm ->
            let
                updatedDrawer locationsDrawer =
                    if String.isEmpty searchTerm then
                        { locationsDrawer | navigation = LocationsRoot }

                    else
                        { locationsDrawer | navigation = Search searchTerm }
            in
            mapLocationsDrawer updatedDrawer model
                |> Cmd.pure

        TVChannelsDrawerInputChanged searchTerm ->
            let
                setSearchTerm channelsDrawer =
                    { channelsDrawer | searchTerm = searchTerm }
            in
            mapTVChannelsDrawer setSearchTerm model
                |> Cmd.pure

        TVChannelsDrawerClearInput ->
            let
                clearSearchTerm channelsDrawer =
                    { channelsDrawer | searchTerm = "" }
            in
            mapTVChannelsDrawer clearSearchTerm model
                |> Cmd.pure

        ToggleTVChannel tvChannelCode ->
            let
                toggleChannel channelsDrawer =
                    { channelsDrawer | selectedChannels = Set.Any.toggle tvChannelCode channelsDrawer.selectedChannels }
            in
            mapTVChannelsDrawer toggleChannel model
                |> Cmd.pure

        LocationsDrawerClearInput ->
            let
                updatedDrawer locationsDrawer =
                    { locationsDrawer | navigation = LocationsRoot }
            in
            mapLocationsDrawer updatedDrawer model
                |> Cmd.pure

        ToggleWaveInDrawer wave ->
            let
                updatedDrawer : WavesDrawer -> WavesDrawer
                updatedDrawer wavesDrawer =
                    { wavesDrawer | selectedWaves = Set.Any.toggle wave.code wavesDrawer.selectedWaves }
            in
            mapWavesDrawer updatedDrawer model
                |> Cmd.pure

        ToggleLocationInDrawer location ->
            let
                updatedDrawer locationDrawer =
                    { locationDrawer | selectedLocations = Set.Any.toggle location.code locationDrawer.selectedLocations }
            in
            mapLocationsDrawer updatedDrawer model
                |> Cmd.pure

        SelectLocations locationCodesList ->
            let
                updatedDrawer locationDrawer =
                    if List.all (\code -> Set.Any.member code locationDrawer.selectedLocations) locationCodesList then
                        { locationDrawer | selectedLocations = Set.Any.diff locationDrawer.selectedLocations (Data.Id.setFromList locationCodesList) }

                    else
                        { locationDrawer | selectedLocations = Set.Any.union locationDrawer.selectedLocations (Data.Id.setFromList locationCodesList) }
            in
            mapLocationsDrawer updatedDrawer model
                |> Cmd.pure

        SelectWaves waveCodesList ->
            let
                updatedDrawer drawer =
                    if List.all (\code -> Set.Any.member code drawer.selectedWaves) waveCodesList then
                        { drawer | selectedWaves = Set.Any.diff drawer.selectedWaves (Data.Id.setFromList waveCodesList) }

                    else
                        { drawer | selectedWaves = Set.Any.union drawer.selectedWaves (Data.Id.setFromList waveCodesList) }
            in
            mapWavesDrawer updatedDrawer model
                |> Cmd.pure

        ToggleSegmenting ->
            let
                toggleSegmenting locationDrawer =
                    case locationDrawer.segmenting of
                        Just v ->
                            { locationDrawer | segmenting = Just <| not v }

                        Nothing ->
                            locationDrawer
            in
            mapLocationsDrawer toggleSegmenting model
                |> Cmd.pure

        SelectTimezone targetTimezone ->
            mapTimezonesDrawer (\timezoneDrawer -> { timezoneDrawer | selectedTimezone = targetTimezone }) model
                |> Cmd.pure

        SelectMinimumImpressions minimumImpressions ->
            mapMinimumImpressionsDrawer
                (\minimumImpressionsDrawer ->
                    { minimumImpressionsDrawer
                        | selectedMinimumImpressions = minimumImpressions
                    }
                )
                model
                |> Cmd.pure

        ToggleTimezoneFolder ->
            mapTimezonesDrawer (\timezoneDrawer -> { timezoneDrawer | isFolderOpen = not timezoneDrawer.isFolderOpen }) model
                |> Cmd.pure



{----- VIEW -----}


drawerContentClass : ClassName -> ClassName
drawerContentClass =
    WeakCss.add "content"


closingMsgCheckSets :
    { selected : IdSet a
    , selectedOnOpen : IdSet a
    , applyMsg : msg
    }
    -> Maybe msg
closingMsgCheckSets { selected, selectedOnOpen, applyMsg } =
    if Set.Any.isEmpty selected then
        Nothing

    else if selected == selectedOnOpen then
        Nothing

    else
        Just applyMsg


closingMsgCheckSegmenting :
    { segmenting : Maybe Bool
    , segmentingOnOpen : Maybe Bool
    }
    -> msg
    -> Maybe msg
    -> Maybe msg
closingMsgCheckSegmenting { segmenting, segmentingOnOpen } applyMsgDefault applyMsgPrev =
    if applyMsgPrev /= Nothing then
        applyMsgPrev

    else if segmenting /= segmentingOnOpen then
        Just applyMsgDefault

    else
        Nothing


wavesDrawerContent : WavesConfig msg -> ClassName -> Store.Platform2.Store -> WavesDrawer -> List (Html msg)
wavesDrawerContent config moduleClass store ({ initialSelectedWaves, getWaves, footerWarning } as data) =
    remoteDataView "Waves" moduleClass (getWaves store) <|
        \waves ->
            let
                selectedWaves =
                    data.selectedWaves
                        |> Set.Any.filter
                            (\code ->
                                Maybe.isJust <| Dict.Any.get code waves
                            )

                wavesByYears =
                    Data.Labels.wavesByYears waves

                contentClass =
                    drawerContentClass moduleClass

                selectAllLabel : List WaveCode -> String
                selectAllLabel waveCodes =
                    if List.all (\code -> Set.Any.member code selectedWaves) waveCodes then
                        "Deselect all"

                    else
                        "Select all"

                wavesList =
                    Dict.toList wavesByYears
                        |> List.reverse

                wavesIcon waves_ =
                    if selectedWavesCount waves_ == 0 then
                        P2Icons.checkboxUnfilled

                    else if selectedWavesCount waves_ < List.length waves_ then
                        P2Icons.checkboxHalfFilled

                    else
                        P2Icons.checkboxFilled

                selectedWavesCount waves_ =
                    waves_
                        |> List.map .code
                        |> Data.Id.setFromList
                        |> Set.Any.intersect selectedWaves
                        |> Set.Any.size

                drawerRootItem ( waveYear, waves_ ) =
                    let
                        isOpen =
                            Set.member waveYear data.openedYears
                    in
                    Html.div [ WeakCss.nest "itemwrapper" contentClass ]
                        [ Html.div
                            [ WeakCss.add "item" contentClass
                                |> WeakCss.withStates [ ( "selected", selectedWavesCount waves_ > 0 ) ]
                            ]
                            [ Html.input
                                [ WeakCss.nestMany [ "item", "checkbox", "indicator" ] contentClass
                                , Events.onClick <| config.msg <| SelectWaves <| List.map .code waves_
                                , Attrs.attribute "aria-label" "Select Wave"
                                , Attrs.type_ "checkbox"
                                ]
                                [ Icons.icon [] <|
                                    wavesIcon waves_
                                ]
                            , Html.span
                                [ WeakCss.nestMany [ "item", "checkbox" ] contentClass
                                , Events.onClick <| config.msg <| SelectWaves <| List.map .code waves_
                                ]
                                [ Icons.icon [] <|
                                    wavesIcon waves_
                                ]
                            , Html.button
                                [ WeakCss.nestMany [ "item", "inner" ] contentClass
                                , Events.onClick <| config.msg <| ToggleWaveSublist waveYear
                                ]
                                [ Html.span
                                    [ WeakCss.nestMany [ "item", "inner", "right-icon" ] contentClass ]
                                    [ Icons.icon [] P2Icons.folderFilled ]
                                , Html.span
                                    [ WeakCss.nestMany [ "item", "inner", "content" ] contentClass
                                    ]
                                    [ Html.text <| String.fromInt waveYear ]
                                , Html.span
                                    [ WeakCss.nestMany [ "item", "inner", "right-icon" ] contentClass ]
                                    [ Icons.icon []
                                        (if isOpen then
                                            P2Icons.caretUp

                                         else
                                            P2Icons.caretDown
                                        )
                                    ]
                                ]
                            ]
                        , Html.div [ WeakCss.add "list-items" contentClass |> WeakCss.withStates [ ( "open", isOpen ) ] ]
                            [ Html.viewIf isOpen
                                (Html.div [] <| List.map drawerListItem waves_)
                            ]
                        ]

                drawerListItem : Wave -> Html msg
                drawerListItem wave =
                    let
                        isItemSelected =
                            Set.Any.member wave.code selectedWaves

                        drawerItemIcon =
                            if isItemSelected then
                                P2Icons.checkboxFilled

                            else
                                P2Icons.checkboxUnfilled
                    in
                    Html.div
                        [ WeakCss.addMany [ "list-item" ] contentClass
                            |> WeakCss.withStates [ ( "selected", isItemSelected ) ]
                        , Events.onClick <| config.msg <| ToggleWaveInDrawer wave
                        ]
                        [ Html.input
                            [ WeakCss.nestMany [ "list-item", "checkbox", "indicator" ] contentClass
                            , Attrs.attribute "aria-label" "Select Wave"
                            , Attrs.type_ "checkbox"
                            ]
                            []
                        , Html.span [ WeakCss.nestMany [ "list-item", "checkbox" ] contentClass ]
                            [ Icons.icon [] drawerItemIcon ]
                        , Html.span
                            [ WeakCss.nestMany [ "list-item", "inner" ] contentClass
                            ]
                            [ Html.text wave.name ]
                        ]

                applyMsg : msg
                applyMsg =
                    config.applyWavesSelection selectedWaves
                        |> (\msg ->
                                closingMsgCheckSets
                                    { selected = selectedWaves
                                    , selectedOnOpen = initialSelectedWaves
                                    , applyMsg = msg
                                    }
                           )
                        |> Maybe.withDefault (config.msg CloseDrawer)

                selectedCount : Int
                selectedCount =
                    Set.Any.size selectedWaves

                footer : Html msg
                footer =
                    Html.footer [ WeakCss.nestMany [ "footer" ] contentClass ]
                        [ Html.viewMaybe
                            (\copy ->
                                Html.div [ WeakCss.nestMany [ "footer", "warning" ] contentClass ]
                                    [ Html.span [] [ Icons.icon [] P2Icons.warningTriangleIcon ]
                                    , Html.span [] [ Html.text copy ]
                                    ]
                            )
                            footerWarning
                        , Html.button
                            [ WeakCss.nestMany [ "footer", "apply-button" ] contentClass
                            , Events.onClick applyMsg
                            , Attrs.disabled <| Set.Any.isEmpty selectedWaves
                            ]
                            [ Html.text <| "Apply " ++ String.fromInt selectedCount ++ Plural.fromInt selectedCount " wave"
                            ]
                        ]

                allWaveCodes =
                    wavesByYears
                        |> Dict.values
                        |> List.fastConcatMap (List.map .code)
            in
            [ Html.header [ WeakCss.nest "header" contentClass ]
                [ Html.button
                    [ WeakCss.nestMany [ "header", "close-button" ] contentClass
                    , Events.onClick <| config.msg CloseDrawer
                    , Attrs.id "modal-waves-close-button"
                    ]
                    [ Icons.icon [] P2Icons.cross
                    ]
                , Html.h2 [ WeakCss.nestMany [ "header", "title" ] contentClass ]
                    [ Html.text "Select waves to filter by..." ]
                , Html.button
                    [ WeakCss.nestMany [ "header", "select-all-button" ] contentClass
                    , Events.onClick <| config.msg <| SelectWaves allWaveCodes
                    ]
                    [ Dict.values wavesByYears
                        |> List.concat
                        |> List.map .code
                        |> selectAllLabel
                        |> Html.text
                    ]
                ]
            , Html.div
                [ WeakCss.nest "items" contentClass
                , Attrs.tabindex 0
                ]
              <|
                List.map drawerRootItem wavesList
            , footer
            ]


locationsDrawerRegions :
    LocationsConfig msg
    -> ClassName
    -> IdSet LocationCodeTag
    -> AnySet Int RegionCode
    -> AnyDict Int RegionCode (List Location)
    -> List (Html msg)
locationsDrawerRegions config moduleClass selectedLocations openedRegions locationsByRegions =
    let
        contentClass =
            drawerContentClass moduleClass

        selectedLocationsCount locations =
            locations
                |> List.map .code
                |> Data.Id.setFromList
                |> Set.Any.intersect selectedLocations
                |> Set.Any.size

        locationsIcon locations =
            if selectedLocationsCount locations == 0 then
                P2Icons.checkboxUnfilled

            else if selectedLocationsCount locations < List.length locations then
                P2Icons.checkboxHalfFilled

            else
                P2Icons.checkboxFilled

        regionItem : ( RegionCode, List Location ) -> Html msg
        regionItem ( regionCode, locations ) =
            let
                isOpen =
                    Set.Any.member regionCode openedRegions
            in
            Html.div [ WeakCss.nest "itemwrapper" contentClass ]
                [ Html.div
                    [ WeakCss.add "item" contentClass
                        |> WeakCss.withStates [ ( "selected", selectedLocationsCount locations > 0 ) ]
                    ]
                    [ Html.input
                        [ WeakCss.nestMany [ "item", "checkbox", "indicator" ] contentClass
                        , Events.onClick <| config.msg <| SelectLocations <| List.map .code locations
                        , Attrs.attribute "aria-label" "Select Region"
                        , Attrs.type_ "checkbox"
                        ]
                        []
                    , Html.span
                        [ WeakCss.nestMany [ "item", "checkbox" ] contentClass
                        , Events.onClick <| config.msg <| SelectLocations <| List.map .code locations
                        ]
                        [ Icons.icon [] <|
                            locationsIcon locations
                        ]
                    , Html.button
                        [ WeakCss.nestMany [ "item", "inner" ] contentClass
                        , Events.onClick <| config.msg <| ToggleLocationsSublist regionCode
                        ]
                        [ Html.span
                            [ WeakCss.nestMany [ "item", "inner", "right-icon" ] contentClass ]
                            [ Icons.icon [] P2Icons.folderFilled ]
                        , Html.span
                            [ WeakCss.nestMany [ "item", "inner", "content" ] contentClass
                            ]
                            [ Html.text <| Data.Labels.regionName regionCode
                            ]
                        , Html.span
                            [ WeakCss.nestMany [ "item", "inner", "right-icon" ] contentClass ]
                            [ Icons.icon []
                                (if isOpen then
                                    P2Icons.caretUp

                                 else
                                    P2Icons.caretDown
                                )
                            ]
                        ]
                    ]
                , Html.div [ WeakCss.add "list-items" contentClass |> WeakCss.withStates [ ( "open", isOpen ) ] ]
                    [ Html.viewIf isOpen <|
                        Html.div [] (locationsDrawerRegionItems config moduleClass selectedLocations locations)
                    ]
                ]
    in
    locationsByRegions
        |> Dict.Any.toList
        |> List.sortBy (\( regionCode, _ ) -> Data.Labels.regionName regionCode)
        |> List.map regionItem


locationsDrawerRegionItems : LocationsConfig msg -> ClassName -> IdSet LocationCodeTag -> List Location -> List (Html msg)
locationsDrawerRegionItems config moduleClass selectedLocations regionItems =
    let
        contentClass =
            drawerContentClass moduleClass

        isItemSelected location =
            Set.Any.member location.code selectedLocations

        locationIcon : Location -> Icons.IconData
        locationIcon location =
            if isItemSelected location then
                P2Icons.checkboxFilled

            else
                P2Icons.checkboxUnfilled

        item : Location -> Html msg
        item location =
            Html.div
                [ WeakCss.addMany [ "list-item" ] contentClass
                    |> WeakCss.withStates [ ( "selected", isItemSelected location ) ]
                , Events.onClick <| config.msg <| ToggleLocationInDrawer location
                ]
                [ Html.input
                    [ WeakCss.nestMany [ "list-item", "checkbox", "indicator" ] contentClass
                    , Attrs.attribute "aria-label" "Select Region"
                    , Attrs.type_ "checkbox"
                    ]
                    []
                , Html.span
                    [ WeakCss.nestMany [ "list-item", "checkbox" ] contentClass ]
                    [ Icons.icon [] (locationIcon location) ]
                , Html.span
                    [ WeakCss.nestMany [ "list-item", "inner" ] contentClass ]
                    [ Html.text location.name ]
                ]
    in
    List.map item regionItems


locationsDrawerSearchItems :
    LocationsConfig msg
    -> ClassName
    -> IdSet LocationCodeTag
    -> List Location
    -> List (Html msg)
locationsDrawerSearchItems config moduleClass selectedLocations filteredItems =
    let
        contentClass =
            drawerContentClass moduleClass

        isItemSelected location =
            Set.Any.member location.code selectedLocations

        locationIcon : Location -> Icons.IconData
        locationIcon location =
            if isItemSelected location then
                P2Icons.checkboxFilled

            else
                P2Icons.checkboxUnfilled

        item : Location -> Html msg
        item location =
            Html.div
                [ WeakCss.addMany [ "search-list-item" ] contentClass
                    |> WeakCss.withStates
                        [ ( "selected", isItemSelected location )
                        ]
                , Events.onClick <| config.msg <| ToggleLocationInDrawer location
                ]
                [ Icons.icon [] (locationIcon location)
                , Html.span
                    [ WeakCss.nestMany [ "search-list-item", "content" ] contentClass
                    ]
                    [ Html.text location.name ]
                ]
    in
    if List.isEmpty filteredItems then
        [ Html.div [ WeakCss.nest "no-results" contentClass ] [ Html.text "No results found" ] ]

    else
        List.map item filteredItems


segmentingToBool : Maybe Bool -> Bool
segmentingToBool s =
    case s of
        Just v ->
            v

        Nothing ->
            False


locationsDrawerContent : LocationsConfig msg -> ClassName -> Store.Platform2.Store -> LocationsDrawer -> List (Html msg)
locationsDrawerContent config moduleClass store ({ navigation, initialSelectedLocations, segmenting, initialSegmenting, getLocations, footerWarning } as data) =
    remoteDataView "locations" moduleClass (getLocations store) <|
        \locations ->
            let
                selectedLocations =
                    data.selectedLocations
                        |> Set.Any.filter
                            (\code ->
                                Maybe.isJust <| Dict.Any.get code locations
                            )

                locationsByRegions =
                    Data.Labels.locationsByRegions locations

                contentClass =
                    drawerContentClass moduleClass

                selectAllLabel : List LocationCode -> String
                selectAllLabel displayedCodes =
                    if List.all (\code -> Set.Any.member code selectedLocations) displayedCodes then
                        "Deselect all"

                    else
                        "Select all"

                applyMsg =
                    config.applyLocationsSelection selectedLocations (segmentingToBool segmenting)
                        |> (\msg ->
                                -- TODO this could be nicer
                                closingMsgCheckSets
                                    { selected = selectedLocations
                                    , selectedOnOpen = initialSelectedLocations
                                    , applyMsg = msg
                                    }
                                    |> closingMsgCheckSegmenting
                                        { segmenting = segmenting
                                        , segmentingOnOpen = initialSegmenting
                                        }
                                        msg
                           )
                        |> Maybe.withDefault (config.msg CloseDrawer)

                searchValue =
                    case navigation of
                        LocationsRoot ->
                            ""

                        Search searchTerm ->
                            searchTerm

                header allLocationCodes =
                    Html.header [ WeakCss.nest "header" contentClass ]
                        [ Html.button
                            [ WeakCss.nestMany [ "header", "close-button" ] contentClass
                            , Events.onClick <| config.msg CloseDrawer
                            , Attrs.id "modal-locations-close-modal"
                            ]
                            [ Icons.icon [] P2Icons.cross
                            ]
                        , Html.h2 [ WeakCss.nestMany [ "header", "title" ] contentClass ]
                            [ Html.text "Select locations to filter by..."
                            ]
                        , Html.div [ WeakCss.nestMany [ "header", "search-row" ] contentClass ]
                            [ Html.div [ WeakCss.nestMany [ "header", "search-row", "search" ] contentClass ]
                                [ Html.input
                                    [ WeakCss.nestMany [ "header", "search-row", "search", "input" ] contentClass
                                    , Attrs.placeholder "Filter locations"
                                    , Events.onInput <| config.msg << LocationsDrawerInputChanged
                                    , Attrs.value searchValue
                                    ]
                                    []
                                , Html.span [ WeakCss.nestMany [ "header", "search-row", "search", "left-icon" ] contentClass ]
                                    [ Icons.icon [] P2Icons.search
                                    ]
                                , Html.viewIf (searchValue /= "") <|
                                    Html.button
                                        [ WeakCss.nestMany [ "header", "search-row", "search", "clear-btn" ] contentClass
                                        , Events.onClick <| config.msg LocationsDrawerClearInput
                                        ]
                                        [ Icons.icon [] P2Icons.cross
                                        ]
                                ]
                            , Html.button
                                [ WeakCss.nestMany [ "header", "search-row", "select-all-button" ] contentClass
                                , Events.onClick <| config.msg <| SelectLocations allLocationCodes
                                ]
                                [ Html.text <| selectAllLabel allLocationCodes
                                ]
                            ]
                        ]

                selectedCount =
                    Set.Any.size selectedLocations

                footer : Html msg
                footer =
                    Html.footer [ WeakCss.nestMany [ "footer" ] contentClass ]
                        [ Html.viewMaybe
                            (\copy ->
                                Html.div [ WeakCss.nestMany [ "footer", "warning" ] contentClass ]
                                    [ Html.span [] [ Icons.icon [] P2Icons.warningTriangleIcon ]
                                    , Html.span [] [ Html.text copy ]
                                    ]
                            )
                            footerWarning
                        , Html.button
                            [ WeakCss.nestMany [ "footer", "apply-button" ] contentClass
                            , Events.onClickPreventDefaultAndStopPropagation applyMsg
                            , Attrs.disabled <| Set.Any.isEmpty selectedLocations
                            ]
                            [ Html.text <| "Apply " ++ String.fromInt selectedCount ++ Plural.fromInt selectedCount " location"
                            ]
                        ]

                segmenting_ =
                    case segmenting of
                        Just isSegmented ->
                            switchWithOnOffLabels contentClass
                                isSegmented
                                "Segment output by location"
                                (config.msg ToggleSegmenting)

                        Nothing ->
                            Html.nothing
            in
            case navigation of
                LocationsRoot ->
                    let
                        allLocationCodes =
                            Dict.Any.keys locations
                    in
                    [ header allLocationCodes
                    , Html.div [ WeakCss.nest "items" contentClass ] <|
                        locationsDrawerRegions
                            config
                            moduleClass
                            selectedLocations
                            data.openedRegions
                            locationsByRegions
                    , segmenting_
                    , footer
                    ]

                Search searchTerm ->
                    let
                        filteredItems : List Location
                        filteredItems =
                            Dict.Any.values locationsByRegions
                                |> List.fastConcat
                                |> List.filter (\location -> String.contains (String.toLower searchTerm) (String.toLower location.name))
                                |> List.sortBy .name
                    in
                    [ header <| List.map .code filteredItems
                    , Html.div [ WeakCss.nest "items" contentClass ] <|
                        locationsDrawerSearchItems config moduleClass selectedLocations filteredItems
                    , segmenting_
                    , footer
                    ]


remoteDataView : String -> ClassName -> RemoteData err a -> (a -> List (Html msg)) -> List (Html msg)
remoteDataView label moduleClass data successView =
    let
        errorView string =
            [ Html.div
                [ WeakCss.nest "error" (drawerContentClass moduleClass) ]
                [ Html.text string ]
            ]
    in
    case data of
        Success successData ->
            successView successData

        Failure _ ->
            errorView <| "Error loading " ++ label

        Loading ->
            [ Spinner.view ]

        NotAsked ->
            errorView <| "Bug: didn't start loading " ++ label


tvChannelsDrawerContent : TVChannelsConfig msg -> ClassName -> Store.Platform2.Store -> TVChannelsDrawer -> List (Html msg)
tvChannelsDrawerContent config moduleClass store ({ searchTerm } as data) =
    remoteDataView "TV channels" moduleClass store.tvChannels <|
        \allChannels ->
            let
                selectedChannels =
                    data.selectedChannels
                        |> Set.Any.filter
                            (\code ->
                                Maybe.isJust <| Dict.Any.get code allChannels
                            )

                contentClass =
                    drawerContentClass moduleClass

                headerView =
                    Html.header [ WeakCss.nest "header" contentClass ]
                        [ Html.button
                            [ WeakCss.nestMany [ "header", "close-button" ] contentClass
                            , Events.onClick <| config.msg CloseDrawer
                            ]
                            [ Icons.icon [] P2Icons.cross ]
                        , Html.h2
                            [ WeakCss.nestMany [ "header", "title" ] contentClass ]
                            [ Html.text "Select your channel(s) to filter by..." ]
                        , Html.div [ WeakCss.nestMany [ "header", "search-row" ] contentClass ]
                            [ Html.div [ WeakCss.nestMany [ "header", "search-row", "search" ] contentClass ]
                                [ Html.span [ WeakCss.nestMany [ "header", "search-row", "search", "left-icon" ] contentClass ]
                                    [ Icons.icon [] P2Icons.search
                                    ]
                                , Html.input
                                    [ WeakCss.nestMany [ "header", "search-row", "search", "input" ] contentClass
                                    , Attrs.placeholder "Search TV channels"
                                    , Events.onInput <| config.msg << TVChannelsDrawerInputChanged
                                    , Attrs.value searchTerm
                                    ]
                                    []
                                , Html.viewIf (searchTerm /= "") <|
                                    Html.button
                                        [ WeakCss.nestMany [ "header", "search-row", "search", "clear-btn" ] contentClass
                                        , Events.onClick <| config.msg TVChannelsDrawerClearInput
                                        ]
                                        [ Icons.icon [] P2Icons.cross
                                        ]
                                ]
                            ]
                        ]

                footerView : Html msg
                footerView =
                    let
                        codesCount =
                            Set.Any.size selectedChannels
                    in
                    Html.footer [ WeakCss.nest "footer" contentClass ]
                        [ Html.button
                            [ WeakCss.nestMany [ "footer", "apply-button" ] contentClass
                            , Events.onClick <| config.applyTVChannelsSelection selectedChannels
                            , Attrs.disabled <| codesCount == 0
                            ]
                            [ Html.text <| "Apply " ++ String.fromInt codesCount ++ Plural.fromInt codesCount " channel"
                            ]
                        ]

                rootView () =
                    Html.ul [ WeakCss.nest "items" contentClass ]
                        (allChannels
                            |> Dict.Any.values
                            |> List.sortBy .name
                            |> List.map itemView
                        )

                searchResultView () =
                    let
                        filteredItems =
                            allChannels
                                |> Dict.Any.values
                                |> List.filter
                                    (\tvChannel ->
                                        String.contains
                                            (String.toLower searchTerm)
                                            (String.toLower tvChannel.name)
                                    )
                                |> List.sortBy .name
                    in
                    if List.isEmpty filteredItems then
                        Html.div
                            [ WeakCss.nest "no-results" contentClass ]
                            [ Html.text "No results found" ]

                    else
                        Html.div [] (List.map itemView filteredItems)

                itemView : TVChannel -> Html msg
                itemView tvChannel =
                    let
                        isSelected =
                            Set.Any.member tvChannel.code selectedChannels
                    in
                    Html.li
                        [ WeakCss.addMany [ "list-item" ] contentClass
                            |> WeakCss.withStates
                                [ ( "selected", isSelected )
                                , ( "top-level", True )
                                , ( "checkbox-at-top", True )
                                ]
                        , Events.onClick <| config.msg <| ToggleTVChannel tvChannel.code
                        ]
                        [ Html.span
                            [ WeakCss.nestMany [ "list-item", "checkbox" ] contentClass ]
                            [ Icons.icon []
                                (if isSelected then
                                    P2Icons.checkboxFilled

                                 else
                                    P2Icons.checkboxUnfilled
                                )
                            ]
                        , Html.span
                            [ WeakCss.nestMany [ "list-item", "inner" ] contentClass ]
                            [ Html.span
                                [ WeakCss.nestMany [ "list-item", "inner", "name" ] contentClass ]
                                [ Html.text tvChannel.name ]
                            , tvChannel.metadata
                                |> Html.viewMaybe
                                    (\metadata_ ->
                                        Html.span
                                            [ WeakCss.nestMany [ "list-item", "inner", "description" ] contentClass ]
                                            [ Html.text metadata_ ]
                                    )
                            ]
                        ]
            in
            [ headerView
            , if String.isEmpty searchTerm then
                rootView ()

              else
                searchResultView ()
            , footerView
            ]


timezonesDrawerContent : TimezonesConfig msg -> ClassName -> Store.Platform2.Store -> TimezonesDrawer -> List (Html msg)
timezonesDrawerContent config moduleClass store { selectedTimezone, isFolderOpen } =
    let
        contentClass =
            drawerContentClass moduleClass

        headerView =
            Html.header [ WeakCss.nest "header" contentClass ]
                [ Html.button
                    [ WeakCss.nestMany [ "header", "close-button" ] contentClass
                    , Events.onClick <| config.msg CloseDrawer
                    ]
                    [ Icons.icon [] P2Icons.cross ]
                , Html.h2
                    [ WeakCss.nestMany [ "header", "title" ] contentClass ]
                    [ Html.text "Select a time zone to filter by..." ]
                ]

        footerView : Html msg
        footerView =
            Html.footer [ WeakCss.nest "footer" contentClass ]
                [ Html.button
                    [ WeakCss.nestMany [ "footer", "apply-button" ] contentClass
                    , Events.onClick <| config.applyTimezoneSelection selectedTimezone
                    ]
                    [ Html.text "Apply time zone"
                    ]
                ]

        rootView : Html msg
        rootView =
            Html.ul
                [ WeakCss.nest "items" contentClass ]
                [ itemView { topLevel = True } Local
                , folderView
                    (store.timezonesOrdered
                        -- let's not sort them as the order is important
                        |> RemoteData.withDefault []
                        |> List.map (.code >> Standardized)
                    )
                ]

        itemView : { topLevel : Bool } -> TargetTimezone -> Html msg
        itemView { topLevel } targetTimezone =
            let
                isSelected =
                    targetTimezone == selectedTimezone
            in
            Html.li
                [ WeakCss.addMany [ "list-item" ] contentClass
                    |> WeakCss.withStates
                        [ ( "selected", isSelected )
                        , ( "top-level", topLevel )
                        , ( "timezones", True )
                        ]
                , Events.onClick <| config.msg <| SelectTimezone targetTimezone
                ]
                [ Html.span
                    [ WeakCss.nestMany [ "list-item", "checkbox" ] contentClass ]
                    [ Icons.icon []
                        (if isSelected then
                            P2Icons.radioButtonFilled

                         else
                            P2Icons.radioButtonUnfilled
                        )
                    ]
                , Html.span
                    [ WeakCss.nestMany [ "list-item", "inner" ] contentClass ]
                    [ Html.span
                        [ WeakCss.nestMany [ "list-item", "inner", "name" ] contentClass ]
                        [ Html.text <|
                            Data.Platform2.targetTimezoneLabel
                                { local = "Use local time zone"
                                , standardized = identity
                                }
                                store.timezones
                                targetTimezone
                        ]
                    ]
                ]

        folderView : List TargetTimezone -> Html msg
        folderView timezoneList =
            Html.li [ WeakCss.nest "item-wrapper" contentClass ]
                [ Html.div [ WeakCss.nest "item-with-description" contentClass ]
                    [ Html.div [ WeakCss.nestMany [ "item-with-description", "name-and-icons" ] contentClass ]
                        [ Html.span
                            [ WeakCss.nestMany [ "item-with-description", "checkbox" ] contentClass
                            , Events.onClickStopPropagation <| config.msg ToggleTimezoneFolder
                            ]
                            [ Icons.icon []
                                (if isFolderOpen then
                                    let
                                        isFolderContentSelected =
                                            List.member selectedTimezone timezoneList
                                    in
                                    if isFolderContentSelected then
                                        P2Icons.radioButtonFilled

                                    else
                                        P2Icons.radioButtonUnfilled

                                 else
                                    P2Icons.folderFilled
                                )
                            ]
                        , Html.div
                            [ WeakCss.nestMany [ "item-with-description", "inner" ] contentClass
                            , Events.onClickStopPropagation <| config.msg ToggleTimezoneFolder
                            ]
                            [ Html.viewIf isFolderOpen <|
                                Html.span
                                    [ WeakCss.nestMany [ "item-with-description", "inner", "right-icon" ] contentClass ]
                                    [ Icons.icon [] P2Icons.folderFilled
                                    ]
                            , Html.span
                                [ WeakCss.nestMany [ "item-with-description", "inner", "content" ] contentClass ]
                                [ Html.text "Use standardized time zone" ]
                            , Html.span
                                [ WeakCss.nestMany [ "item-with-description", "inner", "right-icon" ] contentClass ]
                                [ Icons.icon []
                                    (if isFolderOpen then
                                        P2Icons.caretUp

                                     else
                                        P2Icons.caretDown
                                    )
                                ]
                            ]
                        ]
                    ]
                , Html.viewIfLazy isFolderOpen <|
                    \() ->
                        Html.div
                            [ WeakCss.nest "list-items" contentClass ]
                            (List.map (itemView { topLevel = False }) timezoneList)
                ]
    in
    [ headerView
    , rootView
    , footerView
    ]


minimumImpressionsDrawerContent :
    MinimumImpressionsConfig msg
    -> ClassName
    -> MinimumImpressionsDrawer
    -> List (Html msg)
minimumImpressionsDrawerContent config moduleClass { selectedMinimumImpressions } =
    let
        contentClass : ClassName
        contentClass =
            drawerContentClass moduleClass

        headerView : Html msg
        headerView =
            Html.header [ WeakCss.nest "header" contentClass ]
                [ Html.button
                    [ WeakCss.nestMany [ "header", "close-button" ] contentClass
                    , Events.onClick <| config.msg CloseDrawer
                    ]
                    [ Icons.icon [] P2Icons.cross ]
                , Html.h2
                    [ WeakCss.nestMany [ "header", "title" ] contentClass ]
                    [ Html.text "Select Minimum number of views" ]
                ]

        descriptionView : Html msg
        descriptionView =
            Html.div [ WeakCss.nest "description" contentClass ]
                [ Html.b
                    [ WeakCss.nestMany
                        [ "description"
                        , "title"
                        ]
                        contentClass
                    ]
                    [ Html.text "Reach & Frequency" ]
                , Html.text "Select the minimum number of views"
                , Html.br [] []
                , Html.text "for an individual to be considered"
                , Html.br [] []
                , Html.text "as reached."
                ]

        footerView : Html msg
        footerView =
            Html.footer [ WeakCss.nest "footer" contentClass ]
                [ Html.button
                    [ WeakCss.nestMany [ "footer", "apply-button" ] contentClass
                    , Events.onClick <|
                        config.applyMinimumImpressionsSelection
                            selectedMinimumImpressions
                    ]
                    [ Html.text "Apply frequency"
                    ]
                ]

        rootView : Html msg
        rootView =
            Html.ul
                [ WeakCss.nest "items" contentClass ]
                (List.indexedMap
                    (\order minimumImpressions ->
                        itemView { topLevel = True }
                            order
                            minimumImpressions
                    )
                    (List.range 1 10)
                )

        itemView : { topLevel : Bool } -> Int -> Int -> Html msg
        itemView { topLevel } order minimumImpressions =
            let
                isSelected : Bool
                isSelected =
                    minimumImpressions == selectedMinimumImpressions

                isFirstItem : Bool
                isFirstItem =
                    order == 0
            in
            Html.li
                [ WeakCss.addMany [ "list-item" ] contentClass
                    |> WeakCss.withStates
                        [ ( "selected", isSelected )
                        , ( "top-level", topLevel )
                        , ( "impression", True )
                        , ( "first-item", isFirstItem )
                        ]
                , Events.onClick <|
                    config.msg <|
                        SelectMinimumImpressions
                            minimumImpressions
                ]
                [ Html.span
                    [ WeakCss.nestMany [ "list-item", "checkbox" ] contentClass ]
                    [ Icons.icon []
                        (if isSelected then
                            P2Icons.radioButtonFilled

                         else
                            P2Icons.radioButtonUnfilled
                        )
                    ]
                , Html.span
                    [ WeakCss.nestMany [ "list-item", "inner" ] contentClass ]
                    [ Html.span
                        [ WeakCss.nestMany
                            [ "list-item", "inner", "name" ]
                            contentClass
                        ]
                        [ Html.text <|
                            String.fromInt
                                minimumImpressions
                        ]
                    ]
                ]
    in
    [ headerView
    , descriptionView
    , rootView
    , footerView
    ]


close : Drawer msg
close =
    Closed


switchWithOnOffLabels : ClassName -> Bool -> String -> msg -> Html msg
switchWithOnOffLabels className isSegmented text msg =
    Html.div
        [ WeakCss.nest "segmenting" className ]
        [ Html.div [ WeakCss.nestMany [ "segmenting", "label" ] className ]
            [ Html.text text ]
        , Html.label
            [ WeakCss.nestMany [ "segmenting", "switch" ] className ]
            [ Html.input
                [ WeakCss.nestMany [ "segmenting", "switch", "input" ] className
                , Attrs.type_ "checkbox"
                , Attrs.checked isSegmented
                , Events.onClick msg
                ]
                []
            , Html.span
                [ WeakCss.addMany [ "segmenting", "switch", "slider" ] className
                    |> WeakCss.withStates [ ( "active", isSegmented ) ]
                ]
                [ Html.span
                    [ WeakCss.nestMany [ "segmenting", "switch", "slider", "dot" ] className
                    ]
                    []
                ]
            ]
        ]


openTVChannels :
    TVChannelsConfig msg
    -> { selectedChannels : IdSet TVChannelCodeTag }
    -> Drawer msg
openTVChannels config { selectedChannels } =
    TVChannels config
        { selectedChannels = selectedChannels
        , initialSelectedChannels = selectedChannels
        , searchTerm = ""
        }


openTVChannelsReadonly : ReadonlyConfig msg -> TVChannelsReadonlyDrawer -> Drawer msg
openTVChannelsReadonly config data =
    TVChannelsReadonly config data


openTimezones :
    TimezonesConfig msg
    -> { selectedTimezone : TargetTimezone }
    -> Drawer msg
openTimezones config { selectedTimezone } =
    Timezones config
        { selectedTimezone = selectedTimezone
        , isFolderOpen = Data.Platform2.getTargetTimezoneCode selectedTimezone /= Nothing
        }


openMinimumImpressions :
    MinimumImpressionsConfig msg
    -> { selectedMinimumImpressions : Int }
    -> Drawer msg
openMinimumImpressions config { selectedMinimumImpressions } =
    MinimumImpressions config
        { selectedMinimumImpressions = selectedMinimumImpressions
        }


openTimezonesReadonly : ReadonlyConfig msg -> TimezonesReadonlyDrawer -> Drawer msg
openTimezonesReadonly config data =
    TimezonesReadonly config data


openMinimumImpressionsReadonly :
    ReadonlyConfig msg
    -> MinimumImpressionsReadonlyDrawer
    -> Drawer msg
openMinimumImpressionsReadonly config data =
    MinimumImpressionsReadonly config data


openWaves :
    WavesConfig msg
    ->
        { selectedWaves : IdSet WaveCodeTag
        , getWaves : Store.Platform2.Store -> WebData (IdDict WaveCodeTag Wave)
        , footerWarning : Maybe String
        }
    -> Drawer msg
openWaves config { selectedWaves, getWaves, footerWarning } =
    Waves config
        { selectedWaves = selectedWaves
        , initialSelectedWaves = selectedWaves
        , openedYears = Set.empty
        , getWaves = getWaves
        , footerWarning = footerWarning
        }


openWavesReadonly : ReadonlyConfig msg -> WavesReadonlyDrawer -> Drawer msg
openWavesReadonly config data =
    WavesReadonly config data


openLocations :
    LocationsConfig msg
    ->
        { selectedLocations : IdSet LocationCodeTag
        , segmenting : Maybe Bool
        , getLocations : Store.Platform2.Store -> WebData (IdDict LocationCodeTag Location)
        , footerWarning : Maybe String
        }
    -> Drawer msg
openLocations config { selectedLocations, segmenting, getLocations, footerWarning } =
    Locations config
        { navigation = LocationsRoot
        , selectedLocations = selectedLocations
        , initialSelectedLocations = selectedLocations
        , openedRegions = Set.Any.empty Data.Labels.comparableRegionCode
        , segmenting = segmenting
        , initialSegmenting = segmenting
        , getLocations = getLocations
        , footerWarning = footerWarning
        }


openLocationsReadonly : ReadonlyConfig msg -> LocationsReadonlyDrawer -> Drawer msg
openLocationsReadonly config data =
    LocationsReadonly config data


view : ClassName -> Store.Platform2.Store -> Drawer msg -> Html msg
view moduleClass store drawer =
    let
        readonlyDrawerContent_ =
            readonlyDrawerContent moduleClass

        getItemsData :
            WebData (IdDict tag { a | name : String })
            -> List (Id tag)
            -> WebData (List { name : String, order : String })
        getItemsData data ids =
            data
                |> RemoteData.map
                    (Store.getByIds data ids
                        |> List.map
                            (\item ->
                                { name = item.name
                                , order = item.name
                                }
                            )
                        |> always
                    )

        getItemsDataWaves :
            WebData (IdDict WaveCodeTag Wave)
            -> List WaveCode
            -> WebData (List { name : String, order : Int })
        getItemsDataWaves data ids =
            data
                |> RemoteData.map
                    (Store.getByIds data ids
                        |> List.map
                            (\wave ->
                                { name = wave.name
                                , order = negate <| Time.posixToMillis wave.startDate
                                }
                            )
                        |> always
                    )

        drawerOpen =
            drawer /= Closed

        content =
            case drawer of
                Closed ->
                    []

                Waves config wavesData ->
                    wavesDrawerContent config moduleClass store wavesData

                Locations config locationsData ->
                    locationsDrawerContent config moduleClass store locationsData

                TVChannels config tvChannelsData ->
                    tvChannelsDrawerContent config moduleClass store tvChannelsData

                Timezones config timezonesData ->
                    timezonesDrawerContent config moduleClass store timezonesData

                MinimumImpressions config minimumImpressionsData ->
                    minimumImpressionsDrawerContent config
                        moduleClass
                        minimumImpressionsData

                WavesReadonly config wavesData ->
                    let
                        itemLabel : String
                        itemLabel =
                            "wave"

                        items : List WaveCode
                        items =
                            Set.Any.toList wavesData.selectedWaves

                        numberOfSelectedItems : Int
                        numberOfSelectedItems =
                            List.length items
                    in
                    readonlyDrawerContent_
                        config
                        items
                        P2Icons.waves
                        itemLabel
                        (getItemsDataWaves (wavesData.getWaves store))
                        { title =
                            String.fromInt numberOfSelectedItems
                                ++ " selected "
                                ++ Plural.fromInt numberOfSelectedItems itemLabel
                        }

                LocationsReadonly config locationsData ->
                    let
                        itemLabel : String
                        itemLabel =
                            "location"

                        items : List LocationCode
                        items =
                            Set.Any.toList locationsData.selectedLocations

                        numberOfSelectedItems : Int
                        numberOfSelectedItems =
                            List.length items
                    in
                    readonlyDrawerContent_
                        config
                        items
                        P2Icons.locations
                        itemLabel
                        (getItemsData (locationsData.getLocations store))
                        { title =
                            String.fromInt numberOfSelectedItems
                                ++ " selected "
                                ++ Plural.fromInt numberOfSelectedItems itemLabel
                        }

                TVChannelsReadonly config channelsData ->
                    let
                        itemLabel : String
                        itemLabel =
                            "channel"

                        items : List TVChannelCode
                        items =
                            Set.Any.toList channelsData.selectedChannels

                        numberOfSelectedItems : Int
                        numberOfSelectedItems =
                            List.length items
                    in
                    readonlyDrawerContent_
                        config
                        items
                        P2Icons.tv
                        itemLabel
                        (getItemsData store.tvChannels)
                        { title =
                            String.fromInt numberOfSelectedItems
                                ++ " selected "
                                ++ Plural.fromInt numberOfSelectedItems itemLabel
                        }

                TimezonesReadonly config timezonesData ->
                    let
                        itemLabel : String
                        itemLabel =
                            "timezone"

                        items : List TargetTimezone
                        items =
                            [ timezonesData.selectedTimezone ]
                    in
                    readonlyDrawerContent_
                        config
                        items
                        P2Icons.time
                        itemLabel
                        (List.map
                            (\timezone ->
                                let
                                    name =
                                        Data.Platform2.targetTimezoneLabel
                                            { local = "Local time zone"
                                            , standardized = identity
                                            }
                                            store.timezones
                                            timezone
                                in
                                { name = name
                                , order = name
                                }
                            )
                            >> Success
                        )
                        { title =
                            "Selected timezone"
                        }

                MinimumImpressionsReadonly config minimumImpressionsData ->
                    let
                        itemLabel : String
                        itemLabel =
                            "impression"

                        items : List Int
                        items =
                            [ minimumImpressionsData.selectedMinimumImpressions ]
                    in
                    readonlyDrawerContent_
                        config
                        items
                        P2Icons.eyeCircleTick
                        itemLabel
                        (List.map
                            (\minimumImpressions ->
                                { name = String.fromInt minimumImpressions
                                , order = minimumImpressions
                                }
                            )
                            >> Success
                        )
                        { title =
                            "Selected minimum number of views"
                        }

        closingMsg =
            case drawer of
                Closed ->
                    Nothing

                Waves config wavesData ->
                    Just <|
                        if Set.Any.isEmpty wavesData.selectedWaves then
                            config.msg CloseDrawer

                        else if wavesData.selectedWaves == wavesData.initialSelectedWaves then
                            config.msg CloseDrawer

                        else
                            config.applyWavesSelection wavesData.selectedWaves

                Locations config locationsData ->
                    Just <|
                        if Set.Any.isEmpty locationsData.selectedLocations then
                            config.msg CloseDrawer

                        else if
                            (locationsData.selectedLocations == locationsData.initialSelectedLocations)
                                && (locationsData.segmenting == locationsData.initialSegmenting)
                        then
                            config.msg CloseDrawer

                        else
                            config.applyLocationsSelection locationsData.selectedLocations (segmentingToBool locationsData.segmenting)

                TVChannels config tvChannelsData ->
                    Just <|
                        if Set.Any.isEmpty tvChannelsData.selectedChannels then
                            config.msg CloseDrawer

                        else if tvChannelsData.selectedChannels == tvChannelsData.initialSelectedChannels then
                            config.msg CloseDrawer

                        else
                            config.applyTVChannelsSelection tvChannelsData.selectedChannels

                Timezones config timezonesData ->
                    Just <| config.applyTimezoneSelection timezonesData.selectedTimezone

                MinimumImpressions config minimumImpressionsData ->
                    Just <|
                        config.applyMinimumImpressionsSelection
                            minimumImpressionsData.selectedMinimumImpressions

                WavesReadonly config _ ->
                    Just <| config.msg CloseDrawer

                LocationsReadonly config _ ->
                    Just <| config.msg CloseDrawer

                TVChannelsReadonly config _ ->
                    Just <| config.msg CloseDrawer

                TimezonesReadonly config _ ->
                    Just <| config.msg CloseDrawer

                MinimumImpressionsReadonly config _ ->
                    Just <| config.msg CloseDrawer
    in
    Html.div [ moduleClass |> WeakCss.withStates [ ( "open", drawerOpen ) ] ]
        [ Html.div
            [ WeakCss.add "overlay" moduleClass
                |> WeakCss.withStates [ ( "open", drawerOpen ) ]
            , Attrs.attributeMaybe Events.onClick closingMsg
            ]
            []
        , Html.div
            [ drawerContentClass moduleClass
                |> WeakCss.withStates [ ( "open", drawerOpen ) ]
            ]
            content
        ]


readonlyDrawerContent :
    ClassName
    -> ReadonlyConfig msg
    -> List item
    -> IconData
    -> String
    -> (List item -> WebData (List { name : String, order : comparable }))
    -> { title : String }
    -> List (Html msg)
readonlyDrawerContent moduleClass config selectedItems icon itemLabel getItemsData texts =
    let
        pluralItemLabel =
            Plural.fromInt 2 itemLabel

        itemsData =
            getItemsData selectedItems
    in
    remoteDataView pluralItemLabel moduleClass itemsData <|
        \itemsData_ ->
            let
                contentClass =
                    drawerContentClass moduleClass

                headerView =
                    Html.header [ WeakCss.nest "header" contentClass ]
                        [ Html.button
                            [ WeakCss.nestMany [ "header", "close-button" ] contentClass
                            , Events.onClick <| config.msg CloseDrawer
                            ]
                            [ Icons.icon [] P2Icons.cross ]
                        , Html.h2
                            [ WeakCss.nestMany [ "header", "title" ] contentClass ]
                            [ Html.text texts.title
                            ]
                        ]

                itemsView =
                    Html.ul [ WeakCss.nest "items" contentClass ]
                        (itemsData_
                            |> List.sortBy .order
                            |> List.map (.name >> itemView)
                        )

                itemView : String -> Html msg
                itemView itemName =
                    Html.li
                        [ WeakCss.add "item" contentClass
                            |> WeakCss.withActiveStates [ "readonly" ]
                        ]
                        [ Html.span
                            [ WeakCss.nestMany [ "item", "icon" ] contentClass ]
                            [ Icons.icon [] icon ]
                        , Html.span
                            [ WeakCss.nestMany [ "item", "inner" ] contentClass ]
                            [ Html.span
                                [ WeakCss.nestMany [ "item", "inner", "name" ] contentClass ]
                                [ Html.text itemName ]
                            ]
                        ]
            in
            [ headerView
            , itemsView
            ]
