module XB2.Share.Platform2.Drawers exposing
    ( Drawer(..)
    , LocationsConfig
    , LocationsDrawer
    , LocationsDrawerNavigation
    , Model
    , Msg(..)
    , WavesConfig
    , close
    , init
    , openLocations
    , openWaves
    , update
    , view
    )

import Cmd.Extra as Cmd
import Dict
import Dict.Any exposing (AnyDict)
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import Html.Extra as Html
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..), WebData)
import Set exposing (Set)
import Set.Any exposing (AnySet)
import WeakCss exposing (ClassName)
import XB2.Share.Data.Id exposing (IdDict, IdSet)
import XB2.Share.Data.Labels
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
import XB2.Share.Gwi.List as List
import XB2.Share.Gwi.Set as Set
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons
import XB2.Share.Platform2.Spinner as Spinner
import XB2.Share.Plural
import XB2.Share.Store.Platform2


type alias DefaultConfig msg a =
    { a | msg : Msg -> msg }


type alias WavesConfig msg =
    DefaultConfig msg { applyWavesSelection : IdSet WaveCodeTag -> msg }


type alias LocationsConfig msg =
    DefaultConfig msg { applyLocationsSelection : IdSet LocationCodeTag -> Bool -> msg }


type Drawer msg
    = Closed
    | Waves (WavesConfig msg) WavesDrawer
    | Locations (LocationsConfig msg) LocationsDrawer


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
    , getLocations : XB2.Share.Store.Platform2.Store -> WebData (IdDict LocationCodeTag Location)
    , footerWarning : Maybe String
    }


type alias WavesDrawer =
    { selectedWaves : IdSet WaveCodeTag
    , initialSelectedWaves : IdSet WaveCodeTag
    , openedYears : Set Int
    , getWaves : XB2.Share.Store.Platform2.Store -> WebData (IdDict WaveCodeTag Wave)
    , footerWarning : Maybe String
    }


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



{----- UPDATES ----}


update : XB2.Share.Store.Platform2.Store -> Msg -> Model msg -> ( Model msg, Cmd msg )
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
                        { locationDrawer | selectedLocations = Set.Any.diff locationDrawer.selectedLocations (XB2.Share.Data.Id.setFromList locationCodesList) }

                    else
                        { locationDrawer | selectedLocations = Set.Any.union locationDrawer.selectedLocations (XB2.Share.Data.Id.setFromList locationCodesList) }
            in
            mapLocationsDrawer updatedDrawer model
                |> Cmd.pure

        SelectWaves waveCodesList ->
            let
                updatedDrawer drawer =
                    if List.all (\code -> Set.Any.member code drawer.selectedWaves) waveCodesList then
                        { drawer | selectedWaves = Set.Any.diff drawer.selectedWaves (XB2.Share.Data.Id.setFromList waveCodesList) }

                    else
                        { drawer | selectedWaves = Set.Any.union drawer.selectedWaves (XB2.Share.Data.Id.setFromList waveCodesList) }
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


wavesDrawerContent : WavesConfig msg -> ClassName -> XB2.Share.Store.Platform2.Store -> WavesDrawer -> List (Html msg)
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
                    XB2.Share.Data.Labels.wavesByYears waves

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
                        |> XB2.Share.Data.Id.setFromList
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
                                [ XB2.Share.Icons.icon [] <|
                                    wavesIcon waves_
                                ]
                            , Html.span
                                [ WeakCss.nestMany [ "item", "checkbox" ] contentClass
                                , Events.onClick <| config.msg <| SelectWaves <| List.map .code waves_
                                ]
                                [ XB2.Share.Icons.icon [] <|
                                    wavesIcon waves_
                                ]
                            , Html.button
                                [ WeakCss.nestMany [ "item", "inner" ] contentClass
                                , Events.onClick <| config.msg <| ToggleWaveSublist waveYear
                                ]
                                [ Html.span
                                    [ WeakCss.nestMany [ "item", "inner", "right-icon" ] contentClass ]
                                    [ XB2.Share.Icons.icon [] P2Icons.folderFilled ]
                                , Html.span
                                    [ WeakCss.nestMany [ "item", "inner", "content" ] contentClass
                                    ]
                                    [ Html.text <| String.fromInt waveYear ]
                                , Html.span
                                    [ WeakCss.nestMany [ "item", "inner", "right-icon" ] contentClass ]
                                    [ XB2.Share.Icons.icon []
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
                            [ XB2.Share.Icons.icon [] drawerItemIcon ]
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
                                    [ Html.span [] [ XB2.Share.Icons.icon [] P2Icons.warningTriangleIcon ]
                                    , Html.span [] [ Html.text copy ]
                                    ]
                            )
                            footerWarning
                        , Html.button
                            [ WeakCss.nestMany [ "footer", "apply-button" ] contentClass
                            , Events.onClick applyMsg
                            , Attrs.disabled <| Set.Any.isEmpty selectedWaves
                            ]
                            [ Html.text <| "Apply " ++ String.fromInt selectedCount ++ XB2.Share.Plural.fromInt selectedCount " wave"
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
                    [ XB2.Share.Icons.icon [] P2Icons.cross
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
                |> XB2.Share.Data.Id.setFromList
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
                        [ XB2.Share.Icons.icon [] <|
                            locationsIcon locations
                        ]
                    , Html.button
                        [ WeakCss.nestMany [ "item", "inner" ] contentClass
                        , Events.onClick <| config.msg <| ToggleLocationsSublist regionCode
                        ]
                        [ Html.span
                            [ WeakCss.nestMany [ "item", "inner", "right-icon" ] contentClass ]
                            [ XB2.Share.Icons.icon [] P2Icons.folderFilled ]
                        , Html.span
                            [ WeakCss.nestMany [ "item", "inner", "content" ] contentClass
                            ]
                            [ Html.text <| XB2.Share.Data.Labels.regionName regionCode
                            ]
                        , Html.span
                            [ WeakCss.nestMany [ "item", "inner", "right-icon" ] contentClass ]
                            [ XB2.Share.Icons.icon []
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
        |> List.sortBy (\( regionCode, _ ) -> XB2.Share.Data.Labels.regionName regionCode)
        |> List.map regionItem


locationsDrawerRegionItems : LocationsConfig msg -> ClassName -> IdSet LocationCodeTag -> List Location -> List (Html msg)
locationsDrawerRegionItems config moduleClass selectedLocations regionItems =
    let
        contentClass =
            drawerContentClass moduleClass

        isItemSelected location =
            Set.Any.member location.code selectedLocations

        locationIcon : Location -> XB2.Share.Icons.IconData
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
                    [ XB2.Share.Icons.icon [] (locationIcon location) ]
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

        locationIcon : Location -> XB2.Share.Icons.IconData
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
                [ XB2.Share.Icons.icon [] (locationIcon location)
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


locationsDrawerContent : LocationsConfig msg -> ClassName -> XB2.Share.Store.Platform2.Store -> LocationsDrawer -> List (Html msg)
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
                    XB2.Share.Data.Labels.locationsByRegions locations

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
                            [ XB2.Share.Icons.icon [] P2Icons.cross
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
                                    [ XB2.Share.Icons.icon [] P2Icons.search
                                    ]
                                , Html.viewIf (searchValue /= "") <|
                                    Html.button
                                        [ WeakCss.nestMany [ "header", "search-row", "search", "clear-btn" ] contentClass
                                        , Events.onClick <| config.msg LocationsDrawerClearInput
                                        ]
                                        [ XB2.Share.Icons.icon [] P2Icons.cross
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
                                    [ Html.span [] [ XB2.Share.Icons.icon [] P2Icons.warningTriangleIcon ]
                                    , Html.span [] [ Html.text copy ]
                                    ]
                            )
                            footerWarning
                        , Html.button
                            [ WeakCss.nestMany [ "footer", "apply-button" ] contentClass
                            , Events.onClickPreventDefaultAndStopPropagation applyMsg
                            , Attrs.disabled <| Set.Any.isEmpty selectedLocations
                            ]
                            [ Html.text <| "Apply " ++ String.fromInt selectedCount ++ XB2.Share.Plural.fromInt selectedCount " location"
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


openWaves :
    WavesConfig msg
    ->
        { selectedWaves : IdSet WaveCodeTag
        , getWaves : XB2.Share.Store.Platform2.Store -> WebData (IdDict WaveCodeTag Wave)
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


openLocations :
    LocationsConfig msg
    ->
        { selectedLocations : IdSet LocationCodeTag
        , segmenting : Maybe Bool
        , getLocations : XB2.Share.Store.Platform2.Store -> WebData (IdDict LocationCodeTag Location)
        , footerWarning : Maybe String
        }
    -> Drawer msg
openLocations config { selectedLocations, segmenting, getLocations, footerWarning } =
    Locations config
        { navigation = LocationsRoot
        , selectedLocations = selectedLocations
        , initialSelectedLocations = selectedLocations
        , openedRegions = Set.Any.empty XB2.Share.Data.Labels.comparableRegionCode
        , segmenting = segmenting
        , initialSegmenting = segmenting
        , getLocations = getLocations
        , footerWarning = footerWarning
        }


view : ClassName -> XB2.Share.Store.Platform2.Store -> Drawer msg -> Html msg
view moduleClass store drawer =
    let
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
