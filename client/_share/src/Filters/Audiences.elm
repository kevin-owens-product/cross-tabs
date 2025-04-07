module Filters.Audiences exposing
    ( Config
    , Model
    , Msg(..)
    , State
    , init
    , update
    , view
    )

import Basics.Extra exposing (flip)
import Browser.Dom
import Cmd.Extra as Cmd
import Config exposing (Flags)
import CoolTip
import Data.Audience.Expression as Expression exposing (AudienceExpression)
import Data.Core as Core
    exposing
        ( Audience
        , AudienceFolder
        , AudienceFolderId
        , AudienceFolderIdTag
        , AudienceId
        , AudienceIdTag
        , AudienceType(..)
        )
import Data.Id exposing (IdDict)
import Data.Labels
    exposing
        ( NamespaceAndQuestionCode
        , NamespaceAndQuestionCodeTag
        , Question
        )
import Data.Permissions exposing (DataPermissions(..))
import Data.Upsell as Upsell
import Data.User exposing (Plan)
import Dict.Any
import DragEvents
import DragTypes exposing (Dragging, DropPlace(..))
import Filters.ActiveAudiences as ActiveAudiences exposing (ActiveAudiences)
import Filters.Features as Features exposing (Features)
import Gwi.Html.Events
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import Html.Extra as Html
import Html.Keyed
import Icons
import Icons.FontAwesome as FaIcons
import Icons.Gwi as GwiIcons
import Json.Decode as Decode
import Maybe.Extra as Maybe
import Permissions exposing (Can, Permission(..))
import Quantify exposing (Quantifier(..))
import RemoteData exposing (RemoteData(..), WebData)
import Scroll
import Search
import Spinner
import Store.Core
import Task
import WeakCss exposing (ClassName)



-- Config


type alias Config msg =
    { toggleAudience : Bool -> AudienceId -> msg
    , createAudience : Maybe AudienceFolderId -> Maybe String -> msg
    , activateIds : List AudienceId -> msg
    , deactivateIds : List AudienceId -> msg
    , baseAudience : Maybe AudienceId -> msg
    , deleteAudiences : List Audience -> msg
    , updateAudience : Audience -> msg
    , updateAudienceFolder : AudienceFolder -> msg
    , groupAudiences : AudienceFolder -> List AudienceId -> msg
    , msg : Msg -> msg
    , navigateToAB : Maybe AudienceId -> msg
    , trackAndNavigateToAB : Maybe Audience -> msg
    , upsellAction : Upsell.Resource -> msg
    , audienceWithUnknownDataClicked : DataPermissions -> Audience -> msg
    , changeDragging : Maybe Dragging -> msg
    }



-- Model


type State
    = Delete (List Audience)
    | Browser


type alias AudienceWithPermission =
    ( DataPermissions, Audience )


type alias ViewData =
    { audiences : Maybe (List Audience)
    , audienceFolders : Maybe (List AudienceFolder)
    , questions : IdDict NamespaceAndQuestionCodeTag Question
    }


setDraggingAudience : Audience -> Maybe Dragging
setDraggingAudience audience =
    Just <| DragTypes.Dragging audience InvalidDropPlace


setDropPlace : Maybe Dragging -> DropPlace -> Maybe Dragging
setDropPlace maybeDragging dropPlace =
    Maybe.map (\(DragTypes.Dragging audience _) -> DragTypes.Dragging audience dropPlace) maybeDragging


getDraggedAudience : Maybe Dragging -> Maybe Audience
getDraggedAudience =
    Maybe.map (\(DragTypes.Dragging audience _) -> audience)


getDropPlace : Maybe Dragging -> DropPlace
getDropPlace =
    Maybe.unwrap InvalidDropPlace (\(DragTypes.Dragging _ dropPlace) -> dropPlace)


type alias Model =
    { selectedAudiencesType : AudienceType
    , audienceFolderId : Maybe AudienceFolderId
    , dragging : Maybe Dragging
    , editingFolder : Maybe ( AudienceFolderId, String )
    , state : State
    , searchTerm : Maybe String
    }


init : Model
init =
    { selectedAudiencesType = User
    , audienceFolderId = Nothing
    , dragging = Nothing
    , editingFolder = Nothing
    , state = Browser
    , searchTerm = Nothing
    }


audienceElementId : AudienceId -> String
audienceElementId id =
    "filter-audiences-item-" ++ Data.Id.unwrap id


scrollAreaElementId : String
scrollAreaElementId =
    "filter-audiences-scroll-area"



-- Update


type Msg
    = NoOp
    | SetAudienceState AudienceType
    | ShowFolder (Maybe AudienceFolderId)
    | ViewAudiences
    | CreateAudience
    | EditAudience Audience
    | RemoveBaseAudience
    | EditFolder AudienceFolder
    | ChangeFolderName String
    | SaveFolderName AudienceFolder String
    | CancelEditFolderName
    | ChangeState State
    | ToggleAudienceForDelete Audience
    | DeleteAudiences
    | SearchTermChanged String
    | DragStarted Audience Decode.Value
    | SetSelectedDropPlace DropPlace
    | DragCancelled
    | DragStopped
    | UngroupAudience
    | GroupAudiences AudienceId
    | AddToGroup AudienceFolderId


isDeleting : { a | state : State } -> Bool
isDeleting model =
    case model.state of
        Delete _ ->
            True

        Browser ->
            False


isDeletingEmpty : State -> Bool
isDeletingEmpty state =
    case state of
        Delete list ->
            List.isEmpty list

        Browser ->
            True


showFolder : Maybe AudienceFolderId -> Model -> Model
showFolder folder model =
    { model | audienceFolderId = folder }


setSelectedAudienceType : AudienceType -> Model -> Model
setSelectedAudienceType audiencesType model =
    { model | selectedAudiencesType = audiencesType }


update : Config msg -> Flags -> Store.Core.Store -> Msg -> Model -> ( Model, Cmd msg )
update config { user } store msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SetAudienceState audiencesType ->
            ( setSelectedAudienceType audiencesType { model | audienceFolderId = Nothing }
            , Cmd.none
            )

        ShowFolder folder ->
            ( showFolder folder model
            , Cmd.none
            )

        ViewAudiences ->
            ( model
            , Cmd.perform <| config.navigateToAB Nothing
            )

        CreateAudience ->
            ( { model | searchTerm = Nothing }
            , Cmd.perform <| config.createAudience model.audienceFolderId model.searchTerm
            )

        EditAudience audience ->
            ( model
            , Cmd.perform <| config.trackAndNavigateToAB <| Just audience
            )

        RemoveBaseAudience ->
            ( model
            , Cmd.perform (config.baseAudience Nothing)
            )

        EditFolder folder ->
            toggleEditingFolder config model (Just ( folder.id, folder.name ))

        ChangeFolderName value ->
            ( { model | editingFolder = Maybe.map (Tuple.mapSecond (always value)) model.editingFolder }
            , Cmd.none
            )

        SaveFolderName folder newName ->
            ( { model | editingFolder = Nothing }
            , if folder.name /= newName then
                Cmd.perform (config.updateAudienceFolder { folder | name = newName })

              else
                Cmd.none
            )

        CancelEditFolderName ->
            ( { model | editingFolder = Nothing }
            , Cmd.none
            )

        ChangeState state ->
            ( { model | state = state }
            , Cmd.none
            )

        ToggleAudienceForDelete audience ->
            ( toggleDeleteAudience audience model
            , Cmd.none
            )

        DeleteAudiences ->
            ( { model | state = Browser }
            , case model.state of
                Delete audiences ->
                    Cmd.perform <| config.deleteAudiences audiences

                _ ->
                    Cmd.none
            )

        SearchTermChanged term ->
            let
                searchTerm =
                    if String.isEmpty term then
                        Nothing

                    else
                        Just term
            in
            ( { model | searchTerm = searchTerm }
            , Cmd.none
            )

        DragStarted audience event ->
            ( { model | dragging = setDraggingAudience audience }
            , Cmd.batch
                [ DragEvents.dragstart event
                , Cmd.perform (config.changeDragging (setDraggingAudience audience))
                ]
            )

        SetSelectedDropPlace dropPlace ->
            ( { model
                | dragging = setDropPlace model.dragging dropPlace
              }
            , Cmd.none
            )

        DragStopped ->
            ( { model | dragging = Nothing }
            , Cmd.batch
                [ Cmd.maybe <|
                    case ( model.dragging, store.questions ) of
                        ( Just (DragTypes.Dragging audience _), Success questions ) ->
                            case Data.Permissions.p1Audience user.planHandle questions audience of
                                Accessible ->
                                    Just <|
                                        config.baseAudience <|
                                            Maybe.map .id <|
                                                getDraggedAudience model.dragging

                                UpsellNeeded _ ->
                                    Just <|
                                        config.upsellAction <|
                                            Upsell.AudienceResource audience.id

                                Unknown _ ->
                                    Nothing

                        _ ->
                            Nothing
                , Cmd.perform (config.changeDragging Nothing)
                ]
            )

        DragCancelled ->
            ( { model | dragging = Nothing }
            , Cmd.perform (config.changeDragging Nothing)
            )

        UngroupAudience ->
            ( { model | dragging = Nothing }
            , Cmd.batch
                [ getDraggedAudience model.dragging
                    |> Cmd.fromMaybe (\audience -> config.updateAudience { audience | folderId = Nothing })
                , Cmd.perform (config.changeDragging Nothing)
                ]
            )

        GroupAudiences id ->
            ( model
            , getDraggedAudience model.dragging
                |> Cmd.fromMaybe
                    (\audience ->
                        let
                            newFolder =
                                { id = Data.Id.fromString "new"
                                , name = "New Folder"
                                , curated = False
                                }
                        in
                        config.groupAudiences newFolder [ audience.id, id ]
                    )
            )

        AddToGroup folderId ->
            ( { model | dragging = Nothing }
            , Cmd.batch
                [ getDraggedAudience model.dragging
                    |> Cmd.fromMaybe (\audience -> config.updateAudience { audience | folderId = Just folderId })
                , Cmd.perform (config.changeDragging Nothing)
                ]
            )


toggleDeleteAudience : Audience -> Model -> Model
toggleDeleteAudience audience model =
    let
        audiencesToDelete =
            case model.state of
                Delete audiences ->
                    -- optimization to avoid 2 iterations over the list
                    case List.partition ((==) audience) audiences of
                        ( [], otherAudiences ) ->
                            audience :: otherAudiences

                        ( _ :: _, otherAudiences ) ->
                            otherAudiences

                _ ->
                    [ audience ]
    in
    { model
        | state =
            if List.isEmpty audiencesToDelete then
                Browser

            else
                Delete audiencesToDelete
    }


toggleEditingFolder : Config msg -> Model -> Maybe ( AudienceFolderId, String ) -> ( Model, Cmd msg )
toggleEditingFolder config model folder =
    ( { model | editingFolder = folder }
    , case folder of
        Just ( fId, _ ) ->
            Task.attempt (always <| config.msg NoOp) <| Browser.Dom.focus <| folderEditAttrId fId

        Nothing ->
            Cmd.none
    )



-- View


moduleClass : ClassName
moduleClass =
    WeakCss.namespace "filter-audiences"


foldersClass : ClassName
foldersClass =
    WeakCss.add "folders" moduleClass


{-| TODO: This function is quite inefficient. We want to do partitioning instead
-}
foldersByType : Can -> Maybe AudienceFolderId -> AudienceType -> List AudienceFolder -> List AudienceFolder
foldersByType can activeFolder folderType folders =
    let
        selectedFolder =
            case activeFolder of
                Just folderId ->
                    (==) folderId << .id

                Nothing ->
                    always True
    in
    case folderType of
        User ->
            List.filter (\f -> (not f.curated || can CreateCuratedAudiences) && selectedFolder f) folders

        Shared ->
            []

        Default ->
            List.filter (\f -> f.curated && selectedFolder f) folders


headerView : { excludeUserAudience : Bool, showLoader : Bool, canCreateAudiences : Bool } -> Model -> Html Msg
headerView { excludeUserAudience, showLoader, canCreateAudiences } model =
    let
        headerClass =
            WeakCss.add "header" moduleClass

        showDropPlace =
            (model.selectedAudiencesType == User)
                && (model.searchTerm == Nothing)
                && isNested model
                && isDragging model

        content =
            if showDropPlace then
                let
                    isDraggingOver =
                        getDropPlace model.dragging == UngroupAudienceDropPLace

                    dropStates =
                        [ ( "drag-over", isDraggingOver ) ]
                in
                [ Html.div
                    [ WeakCss.add "ungroup-drop-place" headerClass
                        |> WeakCss.withStates dropStates
                    , DragEvents.onDragEnter <| SetSelectedDropPlace UngroupAudienceDropPLace
                    , DragEvents.onDragOver NoOp
                    , DragEvents.onDrop UngroupAudience
                    , DragEvents.onDragLeave <| SetSelectedDropPlace InvalidDropPlace
                    ]
                    [ Html.text "Drag to remove from folder" ]
                ]

            else
                let
                    controlButtons =
                        if model.selectedAudiencesType == User && not excludeUserAudience then
                            if isDeleting model then
                                let
                                    headerDeletingClass =
                                        WeakCss.add "deleting" headerClass
                                in
                                [ Html.button
                                    [ WeakCss.nest "confirm" headerDeletingClass
                                    , Events.onClick <|
                                        if isDeletingEmpty model.state then
                                            NoOp

                                        else
                                            DeleteAudiences
                                    , Attrs.attribute "aria-label" "confirm"
                                    ]
                                    [ Html.div [ WeakCss.nestMany [ "confirm", "icon" ] headerDeletingClass ]
                                        [ Icons.icon [ Icons.height 10 ] GwiIcons.checkSmall ]
                                    ]
                                , Html.button
                                    [ WeakCss.nest "cancel" headerDeletingClass
                                    , Events.onClick <| ChangeState Browser
                                    , Attrs.attribute "aria-label" "cancel"
                                    ]
                                    [ Html.div [ WeakCss.nestMany [ "cancel", "icon" ] headerDeletingClass ]
                                        [ Icons.icon [ Icons.height 9 ] GwiIcons.crossSmall ]
                                    ]
                                ]

                            else if canCreateAudiences then
                                let
                                    addButtonAttrs =
                                        [ Attrs.attributeIf (not showLoader) (Events.onClick CreateAudience)
                                        , WeakCss.nest "add-audience" headerClass
                                        , Attrs.title "Add Audience"
                                        ]
                                in
                                [ Html.button addButtonAttrs [ Icons.icon [ Icons.height 20, Icons.width 20 ] GwiIcons.plus ]
                                , Html.button
                                    [ WeakCss.nest "remove-audience" headerClass
                                    , Events.onClick <| ChangeState <| Delete []
                                    , Attrs.title "Delete Audience"
                                    ]
                                    [ Icons.icon [ Icons.height 20, Icons.width 20 ] GwiIcons.trash ]
                                ]

                            else
                                []

                        else
                            []

                    searchInputValue =
                        Maybe.withDefault "" model.searchTerm
                in
                Html.input
                    [ WeakCss.nest "search" headerClass
                    , Attrs.placeholder "Search Audience"
                    , Events.onInput SearchTermChanged
                    , Attrs.value searchInputValue
                    ]
                    []
                    :: controlButtons
    in
    Html.div
        [ WeakCss.withStates
            [ ( "drop-place", showDropPlace ) ]
            headerClass
        ]
        content


folderEditAttrId : AudienceFolderId -> String
folderEditAttrId folderId =
    "audiences__folder-edit-" ++ Data.Id.unwrap folderId


{-| TODO: refactor this - both code and logic
-}
folderView :
    Config msg
    -> Bool
    -> ActiveAudiences
    -> List AudienceWithPermission
    -> Model
    -> AudienceFolder
    -> Html msg
folderView ({ msg } as config) showToggleAll active audiences model folder =
    let
        folderClass =
            WeakCss.add "folder" foldersClass

        audienceIds =
            List.filterMap
                (\( _, a ) ->
                    if Just folder.id == a.folderId then
                        Just a.id

                    else
                        Nothing
                )
                audiences

        toggleState =
            ActiveAudiences.getQuantifier audienceIds active

        toggleCls =
            case toggleState of
                Some ->
                    [ ( "some", True ) ]

                All ->
                    [ ( "all", True ) ]

                None ->
                    []

        isEditing maybeEdited folderId =
            maybeEdited
                |> Maybe.map ((==) folderId << Tuple.first)
                |> Maybe.withDefault False

        toggleAction =
            if toggleState == All then
                config.deactivateIds audienceIds

            else
                config.activateIds audienceIds

        { folderToShow, cls, toggleBtn, folderButtons } =
            case model.audienceFolderId of
                Just _ ->
                    { folderToShow = Nothing
                    , cls = [ "opened" ]
                    , toggleBtn = Html.nothing
                    , folderButtons =
                        [ Html.viewIf showToggleAll <|
                            Html.a [ WeakCss.nest "toggle-all" folderClass, Events.onClick toggleAction ]
                                [ Html.text
                                    ((if toggleState == All then
                                        "Disable"

                                      else
                                        "Enable"
                                     )
                                        ++ " All Audiences"
                                    )
                                , Html.span
                                    [ folderClass
                                        |> WeakCss.add "toggle-all"
                                        |> WeakCss.add "icon"
                                        |> WeakCss.withStates toggleCls
                                    ]
                                    []
                                ]
                        , Html.viewIf (model.selectedAudiencesType /= Default) <|
                            Html.a
                                [ WeakCss.nest "edit-icon" folderClass
                                , Events.onClick <| msg <| EditFolder folder
                                , Attrs.attribute "aria-label" "edit audience folder"
                                ]
                                [ Icons.icon [ Icons.width 23, Icons.height 18 ] FaIcons.pencil ]
                        ]
                    }

                Nothing ->
                    { folderToShow = Just folder.id
                    , cls = []
                    , toggleBtn =
                        Html.span
                            [ folderClass |> WeakCss.add "toggle-icon" |> WeakCss.withStates toggleCls
                            , Events.onClick toggleAction
                            ]
                            []
                    , folderButtons = []
                    }

        audiencesCount =
            List.length audienceIds

        ( folderName, events ) =
            if isEditing model.editingFolder folder.id then
                let
                    currentName =
                        Maybe.unwrap folder.name Tuple.second model.editingFolder
                in
                ( Html.input
                    [ Attrs.type_ "text"
                    , WeakCss.nest "edit-name" folderClass
                    , Attrs.id <| folderEditAttrId folder.id
                    , Attrs.value currentName
                    , Events.onInput (msg << ChangeFolderName)
                    , Events.onEnter (msg <| SaveFolderName folder currentName)
                    , Events.onBlur (msg CancelEditFolderName)
                    , Gwi.Html.Events.onEsc (msg CancelEditFolderName)
                    ]
                    []
                , []
                )

            else
                ( Html.text folder.name, [ Events.onClick <| msg <| ShowFolder folderToShow ] )

        isDraggingOver =
            case getDropPlace model.dragging of
                AddToFolderDropPlace folderId ->
                    folder.id == folderId

                _ ->
                    False

        dropStates =
            [ ( "drag-over", isDraggingOver ) ]

        dropEvents =
            if
                (model.selectedAudiencesType == User)
                    && (model.searchTerm == Nothing)
                    && not (isNested model)
                    && isDragging model
            then
                [ DragEvents.onDragEnter <| msg <| SetSelectedDropPlace <| AddToFolderDropPlace folder.id
                , DragEvents.onDragOver <| msg NoOp
                , DragEvents.onDrop <| msg <| AddToGroup folder.id
                , DragEvents.onDragLeave <| msg <| SetSelectedDropPlace InvalidDropPlace
                ]

            else
                []
    in
    Html.viewIf (audiencesCount > 0) <|
        Html.li [ WeakCss.withStates dropStates folderClass ] <|
            toggleBtn
                :: Html.a
                    ((folderClass
                        |> WeakCss.add "link"
                        |> WeakCss.withActiveStates cls
                     )
                        :: events
                        ++ dropEvents
                    )
                    [ folderName
                    , Html.span [ WeakCss.nest "subtitle" folderClass ] [ Html.text <| String.fromInt audiencesCount ++ " Audiences" ]
                    ]
                :: folderButtons


foldersView : Config msg -> Bool -> ActiveAudiences -> Can -> Maybe (List AudienceFolder) -> List AudienceWithPermission -> Model -> Html msg
foldersView config showToggleAll active can audienceFolders audiences model =
    let
        folders =
            Maybe.map (foldersByType can model.audienceFolderId model.selectedAudiencesType) audienceFolders
                |> Maybe.withDefault []
    in
    Html.viewIf (not <| List.isEmpty folders) <|
        Html.ul [ WeakCss.toClass foldersClass ] <|
            List.map (folderView config showToggleAll active audiences model) folders


isNested : { a | audienceFolderId : Maybe AudienceFolderId } -> Bool
isNested model =
    Maybe.isJust model.audienceFolderId


isDragging : { a | dragging : Maybe b } -> Bool
isDragging model =
    Maybe.isJust model.dragging


audienceView : Config msg -> ViewData -> ActiveAudiences -> Model -> AudienceWithPermission -> Html msg
audienceView config viewData active model audienceWithPermission =
    audienceActualView viewData config active model audienceWithPermission


audiencesClass : ClassName
audiencesClass =
    WeakCss.add "audiences" moduleClass


audienceClass : ClassName
audienceClass =
    WeakCss.add "audience" audiencesClass


audienceActualView : ViewData -> Config msg -> ActiveAudiences -> Model -> AudienceWithPermission -> Html msg
audienceActualView viewData config active model ( permission, audience ) =
    let
        canEdit =
            model.selectedAudiencesType /= Default

        isActive =
            ActiveAudiences.isActive audience.id active

        isDragged =
            getDraggedAudience model.dragging
                |> Maybe.unwrap False ((==) audience.id << .id)

        isDragOver =
            case model.dragging of
                Just (DragTypes.Dragging _ (GroupAudiencesDropPlace id)) ->
                    id == audience.id

                _ ->
                    False

        expressionIsEmpty =
            Expression.isEmpty audience.expression

        states =
            [ ( "deleting", isDeleting model )
            , ( "active", isActive )
            , ( "upsell", Data.Permissions.isUpsellNeeded permission )
            , ( "dragged", isDragged )
            , ( "drag-over", isDragOver )
            , ( "empty-expression", expressionIsEmpty )
            ]
                ++ (case model.state of
                        Delete audiencesToDelete ->
                            [ ( "chosen-for-delete", List.member audience audiencesToDelete ) ]

                        _ ->
                            []
                   )

        attributes =
            [ WeakCss.add "audience" audiencesClass
                |> WeakCss.withStates states
            , Attrs.title audience.name
            , Attrs.id <| audienceElementId audience.id
            ]
                ++ (case model.state of
                        Delete _ ->
                            [ Events.onClick <| (config.msg << ToggleAudienceForDelete) audience
                            ]

                        _ ->
                            let
                                userState =
                                    model.selectedAudiencesType == User

                                isValidDropPlace =
                                    getDraggedAudience model.dragging
                                        |> Maybe.unwrap False ((/=) audience.id << .id)

                                addDraggingAttributes =
                                    userState && not (isNested model) && isValidDropPlace

                                draggingAttrs =
                                    if addDraggingAttributes then
                                        [ DragEvents.onDragEnter <| config.msg <| SetSelectedDropPlace <| GroupAudiencesDropPlace audience.id
                                        , DragEvents.onDragOver <| config.msg NoOp
                                        , DragEvents.onDrop <| (config.msg << GroupAudiences) audience.id
                                        , DragEvents.onDragLeave <| config.msg <| SetSelectedDropPlace InvalidDropPlace
                                        ]

                                    else
                                        []
                            in
                            [ Events.onClick <|
                                case permission of
                                    Accessible ->
                                        config.toggleAudience expressionIsEmpty audience.id

                                    UpsellNeeded _ ->
                                        config.upsellAction <|
                                            Upsell.AudienceResource audience.id

                                    Unknown _ ->
                                        config.audienceWithUnknownDataClicked permission audience
                            , Attrs.draggable "true"
                            , DragEvents.onDragEnd <| config.msg DragCancelled
                            , DragEvents.onDragStart <| config.msg << DragStarted audience
                            ]
                                ++ draggingAttrs
                   )

        selectionColor =
            ActiveAudiences.getColor audience.id active

        selectedIcon color =
            Html.div
                [ WeakCss.nest "selected-icon" audienceClass
                , Attrs.style "background" color
                ]
                []

        warnings =
            collectQuestionWarnings viewData.questions audience.expression

        warningsView tooltipContent =
            Html.div
                [ WeakCss.nest "warnings" audienceClass
                , Attrs.attribute "aria-label" "warning"
                ]
                [ CoolTip.view
                    { offset = Just -10
                    , type_ = CoolTip.Normal
                    , position = CoolTip.TopRight
                    , wrapperAttributes = []
                    , targetAttributes = []
                    , targetHtml =
                        [ Icons.icon
                            [ Icons.height 19
                            , Icons.width 19
                            ]
                            FaIcons.exclamationCircle
                        ]
                    , tooltipAttributes = []
                    , tooltipHtml = tooltipContent
                    }
                ]
    in
    Html.li
        attributes
        [ Html.div [ WeakCss.nest "status" audienceClass ]
            [ Maybe.map selectedIcon selectionColor
                |> Maybe.withDefault (selectedIcon "transparent")
            , case permission of
                Accessible ->
                    Html.nothing

                UpsellNeeded _ ->
                    Html.nothing

                Unknown _ ->
                    audienceUnknownErrorView permission
            , Html.viewIf (selectionColor == Nothing) <|
                if List.isEmpty warnings then
                    Html.viewIfLazy expressionIsEmpty
                        (\_ ->
                            warningsView
                                (Html.div []
                                    [ Html.div
                                        [ WeakCss.nest "error-tooltip-title" audienceClass ]
                                        [ Html.text "Audience is empty" ]
                                    , Html.div
                                        [ WeakCss.nest "error-tooltip-text" audienceClass ]
                                        [ Html.text "Please edit the audience and add attributes to enable use with data." ]
                                    ]
                                )
                        )

                else
                    warningsView <| Html.text <| String.join "\n\n" <| List.map (\( id, text ) -> "__" ++ Data.Id.unwrap id ++ "__: " ++ text) warnings
            ]
        , Html.div
            [ WeakCss.nest "name" audienceClass ]
            [ Html.text audience.name ]
        , Html.viewIf (permission == Accessible && canEdit) <|
            Html.div
                [ WeakCss.nest "edit" audienceClass
                , Attrs.attribute "aria-label" "edit audience"
                , Events.onClickPreventDefaultAndStopPropagation <| config.msg <| EditAudience audience
                ]
                [ Icons.icon [ Icons.width 23, Icons.height 18 ] FaIcons.pencil ]
        ]


audienceUnknownErrorView : DataPermissions -> Html msg
audienceUnknownErrorView permission =
    Data.Permissions.audiencePermissionsErrorCopy permission
        |> Html.viewMaybe
            (\{ title, message } ->
                Html.div
                    [ WeakCss.nest "errors" audienceClass
                    , Attrs.attribute "aria-label" "error"
                    ]
                    [ CoolTip.view
                        { offset = Just -10
                        , type_ = CoolTip.Normal
                        , position = CoolTip.TopRight
                        , wrapperAttributes = []
                        , targetAttributes = []
                        , targetHtml =
                            [ Icons.icon
                                [ Icons.height 19
                                , Icons.width 19
                                ]
                                FaIcons.exclamationCircle
                            ]
                        , tooltipAttributes = []
                        , tooltipHtml =
                            Html.div []
                                [ Html.div
                                    [ WeakCss.nest "error-tooltip-title" audienceClass ]
                                    [ Html.text title ]
                                , Html.div
                                    [ WeakCss.nest "error-tooltip-text" audienceClass ]
                                    [ Html.text message ]
                                ]
                        }
                    ]
            )


collectQuestionWarnings : IdDict NamespaceAndQuestionCodeTag Question -> AudienceExpression -> List ( NamespaceAndQuestionCode, String )
collectQuestionWarnings questions expression =
    let
        f { questionCode } acc =
            Dict.Any.get questionCode questions
                |> Maybe.andThen .warning
                |> Maybe.map (\text -> ( questionCode, text ) :: acc)
                |> Maybe.withDefault acc
    in
    Expression.foldr f [] expression


audiencesView : Config msg -> Features -> Plan -> Can -> ActiveAudiences -> ViewData -> Model -> List (Html msg)
audiencesView config features userPlan can active viewData model =
    let
        isCurrentTypeUser =
            model.selectedAudiencesType == User

        excludeUserAudience =
            Features.is Features.ExcludeUserAudience features

        byTypeAndFolder : AudienceWithPermission -> Bool
        byTypeAndFolder ( _, audience ) =
            let
                isInCurrentFolder =
                    audience.folderId == model.audienceFolderId

                isCurrentType =
                    Core.isAudienceStateInAudienceType
                        model.selectedAudiencesType
                        audience
            in
            (model.selectedAudiencesType == Shared && audience.shared)
                || (isInCurrentFolder && isCurrentType)

        addPermissions : Audience -> AudienceWithPermission
        addPermissions audience =
            let
                permission =
                    Data.Permissions.p1Audience
                        userPlan
                        viewData.questions
                        audience
            in
            ( permission, audience )
    in
    if isCurrentTypeUser && excludeUserAudience && model.searchTerm == Nothing then
        [ userAudienceNoAccessView config ]

    else
        let
            showToggleAll =
                Features.is Features.ToggleAllAudiences features

            audiencesWithPermission =
                viewData.audiences
                    |> Maybe.withDefault []
                    |> List.map addPermissions
                    |> List.sortBy (Tuple.second >> .name >> String.toLower)

            audiences : List AudienceWithPermission
            audiences =
                if model.searchTerm /= Nothing then
                    if excludeUserAudience then
                        getSharedSearchResults audiencesWithPermission model

                    else
                        getSearchResults audiencesWithPermission model

                else
                    List.filter byTypeAndFolder audiencesWithPermission
        in
        [ Html.viewIf (model.searchTerm == Nothing) <|
            foldersView config showToggleAll active can viewData.audienceFolders audiencesWithPermission model
        , audiencesListView config viewData active audiences model
        ]


userAudienceNoAccessView : Config msg -> Html msg
userAudienceNoAccessView { msg } =
    let
        noAccessClass =
            WeakCss.add "no-access" moduleClass

        headerClass =
            noAccessClass
                |> WeakCss.nest "header"

        messageClass =
            noAccessClass
                |> WeakCss.nest "message"

        linkClass =
            noAccessClass
                |> WeakCss.nest "button"
    in
    Html.div [ WeakCss.toClass noAccessClass ]
        [ Html.div [ headerClass ]
            [ Html.text "Please choose from your Shared or Default audiences."
            ]
        , Html.div [ messageClass ]
            [ Html.text "Go to Audience Builder to share any custom audiences you have built so that they can be used in this analysis."
            ]
        , Html.button
            [ linkClass
            , Events.onClick <| msg ViewAudiences
            ]
            [ Html.text "Manage Audiences" ]
        ]


audiencesListView : Config msg -> ViewData -> ActiveAudiences -> List AudienceWithPermission -> Model -> Html msg
audiencesListView config viewData active audiences model =
    let
        emptyFolders =
            Maybe.unwrap True List.isEmpty viewData.audienceFolders

        showEmptyState =
            List.isEmpty audiences
                && (model.searchTerm == Nothing)
                && emptyFolders
    in
    if showEmptyState then
        let
            emptyClass =
                WeakCss.addMany [ "audiences", "empty" ] moduleClass
        in
        Html.div [ WeakCss.toClass emptyClass ]
            [ case model.selectedAudiencesType of
                User ->
                    let
                        paragraph =
                            Html.p [ WeakCss.nest "paragraph" emptyClass ] << List.singleton << Html.text
                    in
                    paragraph "Create your first audience by clicking the + at the top, or choose from one of our ready-built audiences by browsing the Default tab below."

                Shared ->
                    Html.nothing

                Default ->
                    Html.nothing
            ]

    else
        Html.ul [ WeakCss.nest "audiences" moduleClass ] <|
            List.map (audienceView config viewData active model) audiences


getSearchResults : List AudienceWithPermission -> Model -> List AudienceWithPermission
getSearchResults audiences model =
    Maybe.map (flip (Search.filter (.name << Tuple.second)) audiences) model.searchTerm
        |> Maybe.withDefault []


getSharedSearchResults : List AudienceWithPermission -> Model -> List AudienceWithPermission
getSharedSearchResults audiences model =
    getSearchResults audiences model
        |> List.filter (\( _, f ) -> f.shared || f.curated)


bottomNavView : Model -> Html Msg
bottomNavView model =
    let
        bottomNavClass =
            WeakCss.add "bottom-nav" moduleClass

        activeClass t =
            [ ( "active", model.selectedAudiencesType == t ) ]

        btn : Icons.IconData -> String -> AudienceType -> Html Msg
        btn icon n t =
            Html.button
                [ bottomNavClass
                    |> WeakCss.add "btn"
                    |> WeakCss.withStates (activeClass t)
                , Events.onClick <| SetAudienceState t
                , Attrs.type_ "button"
                ]
                [ Icons.icon [ Icons.width 20 ] icon
                , Html.br [] []
                , Html.text n
                ]
    in
    Html.div [ WeakCss.toClass bottomNavClass ]
        [ btn GwiIcons.audienceSmall "My Audiences" User
        , btn GwiIcons.share "Shared" Shared
        , btn GwiIcons.defaultList "Default" Default
        ]


baseAudienceView : Maybe (IdDict AudienceIdTag Audience) -> Maybe AudienceId -> Model -> Html Msg
baseAudienceView audiences baseId model =
    let
        baseAudienceClass =
            WeakCss.add "base-audience" moduleClass

        defaultBaseClass =
            WeakCss.add "default-base" baseAudienceClass

        isDraggingOver =
            getDropPlace model.dragging == BaseAudienceDropPlace

        noBaseAudience =
            [ Html.div [ WeakCss.toClass defaultBaseClass ]
                [ Html.div []
                    [ Html.text "Base Audience: "
                    , Html.span
                        [ WeakCss.nest "name" defaultBaseClass ]
                        [ Html.text Core.defaultAudienceName ]
                    ]
                , Html.text "Drag an audience here to use it as a base audience"
                ]
            ]

        baseAudience =
            Maybe.map2 Tuple.pair baseId audiences
                |> Maybe.andThen (\( id, a ) -> Dict.Any.get id a)
                |> Maybe.map
                    (\audience ->
                        let
                            selectBaseClass =
                                WeakCss.add "selected-base" baseAudienceClass

                            attrs =
                                [ WeakCss.toClass selectBaseClass, Attrs.title audience.name ]
                        in
                        [ Html.div attrs
                            [ Html.text audience.name
                            , Html.span
                                [ WeakCss.add "remove" selectBaseClass
                                    |> WeakCss.withStates [ ( "inactive", isDraggingOver ) ]
                                , Events.onClick RemoveBaseAudience
                                ]
                                [ Html.text "x" ]
                            ]
                        ]
                    )
                |> Maybe.withDefault noBaseAudience

        classStates =
            [ ( "drag-over", isDraggingOver ) ]

        attributes =
            (WeakCss.add "drop-place" baseAudienceClass
                |> WeakCss.withStates classStates
            )
                :: (case model.dragging of
                        Just _ ->
                            [ DragEvents.onDragEnter <| SetSelectedDropPlace BaseAudienceDropPlace
                            , DragEvents.onDrop DragStopped
                            , DragEvents.onDragOver NoOp
                            , DragEvents.onDragLeave <| SetSelectedDropPlace InvalidDropPlace
                            ]

                        Nothing ->
                            []
                   )
    in
    Html.div [ WeakCss.toClass baseAudienceClass ]
        [ Html.div attributes baseAudience ]


view :
    Config msg
    -> Features
    -> Plan
    -> Can
    -> WebData (IdDict NamespaceAndQuestionCodeTag Question)
    -> WebData (IdDict AudienceIdTag Audience)
    -> WebData (IdDict AudienceFolderIdTag AudienceFolder)
    -> ActiveAudiences
    -> Model
    -> Html msg
view config features userPlan can questions audiences folders active model =
    let
        isNotLoaded =
            not << RemoteData.isSuccess

        settings =
            { showLoader =
                isNotLoaded audiences || isNotLoaded folders || isNotLoaded questions
            , excludeUserAudience =
                Features.is Features.ExcludeUserAudience features
            , canCreateAudiences = can CreateAudiences
            }

        ( footer, cls ) =
            case ( isDeleting model, Features.is Features.BaseAudience features ) of
                ( True, _ ) ->
                    ( [], [ "deleting" ] )

                ( _, False ) ->
                    ( [ Html.map config.msg <| bottomNavView model ], [] )

                ( False, True ) ->
                    ( [ Html.map config.msg <| baseAudienceView (RemoteData.toMaybe audiences) (ActiveAudiences.getBase active) model
                      , Html.map config.msg <| bottomNavView model
                      ]
                    , []
                    )
    in
    Html.div [ WeakCss.toClass moduleClass ] <|
        [ Html.map config.msg <| headerView settings model
        , Html.Keyed.node "div"
            [ moduleClass |> WeakCss.nest "items-area" ]
            [ if settings.showLoader then
                ( "Spinner"
                , Html.div [ moduleClass |> WeakCss.nest "scroll-area" ]
                    [ Spinner.view
                    ]
                )

              else
                let
                    viewData =
                        { audiences = RemoteData.toMaybe <| RemoteData.map Dict.Any.values audiences
                        , audienceFolders = RemoteData.toMaybe <| RemoteData.map Dict.Any.values folders
                        , questions = RemoteData.withDefault Data.Id.emptyDict questions
                        }
                in
                ( Core.audienceTypeToString model.selectedAudiencesType
                , Scroll.darkWithScrollId scrollAreaElementId
                    [ moduleClass
                        |> WeakCss.add "scroll-area"
                        |> WeakCss.withActiveStates cls
                    ]
                  <|
                    audiencesView config features userPlan can active viewData model
                )
            ]
        ]
            ++ footer
