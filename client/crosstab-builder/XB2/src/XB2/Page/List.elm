module XB2.Page.List exposing
    ( Config
    , Configure
    , CustomFrontendError(..)
    , DropOnItem
    , ExportAction
    , ExportingProject
    , Model
    , Msg(..)
    , Tab
    , configure
    , customFrontendErrorToOtherError
    , folderDeleted
    , getLoadedCrosstab
    , init
    , onP2StoreChange
    , selectionPanelView
    , storeActionFinished
    , subscriptions
    , update
    , updateTime
    , view
    )

import Browser.Dom as Dom
import Browser.Events
import Cmd.Extra as Cmd
import DateFormat
import Dict.Any
import Glue
import Glue.Lazy exposing (LazyGlue)
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import Html.Extra as Html
import Json.Decode as Decode
import List.NonEmpty as NonemptyList
import List.NonEmpty.Zipper as ListZipper
import Markdown
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..), WebData)
import Set.Any
import Task
import Time exposing (Posix, Zone)
import WeakCss exposing (ClassName)
import XB2.Analytics as Analytics
import XB2.CrosstabCellLoader as CrosstabCellLoader
import XB2.Data as XBData
    exposing
        ( XBFolder
        , XBFolderId
        , XBFolderIdTag
        , XBProject
        , XBProjectFullyLoaded
        , XBProjectId
        , XBProjectIdTag
        , XBUserSettings
        , projectIcon
        )
import XB2.Data.AudienceCrosstab as ACrosstab exposing (AudienceCrosstab)
import XB2.Data.AudienceCrosstab.Export as XBExport exposing (ExportData)
import XB2.Data.AudienceCrosstab.Sort as Sort
import XB2.Data.Calc.AudienceIntersect as AudienceIntersect exposing (XBQueryError)
import XB2.Detail.Common exposing (Unsaved(..))
import XB2.List.Selection as Selection exposing (Selection)
import XB2.List.Sort as Sort exposing (ProjectOwner(..), SortBy(..), projectOwnerToString)
import XB2.MoreOptions
import XB2.Router
import XB2.Share.Analytics.Place as Place
import XB2.Share.Config exposing (Flags)
import XB2.Share.CoolTip
import XB2.Share.CoolTip.Platform2 as P2CoolTip
import XB2.Share.Data.Id exposing (IdDict)
import XB2.Share.DragAndDrop.Move
import XB2.Share.Export exposing (ExportError)
import XB2.Share.Gwi.Html.Events as Events
import XB2.Share.Gwi.Http exposing (Error, OtherError(..))
import XB2.Share.Gwi.Json.Decode as Decode
import XB2.Share.Gwi.List as List
import XB2.Share.Gwi.String as String
import XB2.Share.Icons exposing (IconData)
import XB2.Share.Icons.Platform2 as P2Icons
import XB2.Share.Permissions
import XB2.Share.Platform2.Dropdown.DropdownMenu as DropdownMenu
import XB2.Share.Platform2.NameForCopy as NameForCopy
import XB2.Share.Platform2.Notification as Notification exposing (Notification)
import XB2.Share.Platform2.SearchInput as SearchInput
import XB2.Share.Platform2.SortingHeader as SortingHeader exposing (Direction(..))
import XB2.Share.Platform2.Spinner as Spinner
import XB2.Share.Search
import XB2.Share.Store.Platform2
import XB2.Share.Store.Utils as Store
import XB2.Share.Time.Format
import XB2.Sharing.Icon as SharingIcon
import XB2.Store as XBStore
import XB2.Utils.NewName as NewName
import XB2.Views.Modal as Modal exposing (Modal)
import XB2.Views.Modal.LoaderWithProgress as LoaderWithProgressModal
import XB2.Views.Modal.LoaderWithoutProgress as LoaderWithoutProgressModal
import XB2.Views.SelectionPanel as SelectionPanel



-- Config


type alias ExportAction =
    { startTime : Posix, time : Posix } -> Msg


type alias Config msg =
    { msg : Msg -> msg
    , openProject : XBProjectId -> msg
    , createXBProject : msg
    , openModal : Modal -> msg
    , openSharingModal : XBProject -> msg
    , closeModal : msg
    , openNewWindow : String -> msg
    , moveToFolder : Maybe XBFolder -> XBProject -> msg
    , openError : CustomFrontendError -> msg
    , setXB2ListFTUESeen : msg
    , cellLoaderConfig : CrosstabCellLoader.Config msg ExportAction
    , createNotification : IconData -> Html Msg -> msg
    , createPersistentNotification : String -> Notification Msg -> msg
    , exportAjaxError : Error ExportError -> msg
    , closeNotification : String -> msg
    }


type alias Configure msg =
    { msg : Msg -> msg
    , openProject : XBProjectId -> msg
    , createXBProject : msg
    , openModal : Modal -> msg
    , openSharingModal : XBProject -> msg
    , closeModal : msg
    , openNewWindow : String -> msg
    , moveToFolder : Maybe XBFolder -> XBProject -> msg
    , openError : CustomFrontendError -> msg
    , setXB2ListFTUESeen : msg
    , fetchManyP2 : List XB2.Share.Store.Platform2.StoreAction -> msg
    , queryAjaxError : Error XBQueryError -> msg
    , createNotification : IconData -> Html Msg -> msg
    , createPersistentNotification : String -> Notification Msg -> msg
    , exportAjaxError : Error ExportError -> msg
    , closeNotification : String -> msg
    }


configure : Configure msg -> Config msg
configure rec =
    { msg = rec.msg
    , openProject = rec.openProject
    , createXBProject = rec.createXBProject
    , openModal = rec.openModal
    , openSharingModal = rec.openSharingModal
    , closeModal = rec.closeModal
    , openNewWindow = rec.openNewWindow
    , moveToFolder = rec.moveToFolder
    , openError = rec.openError
    , setXB2ListFTUESeen = rec.setXB2ListFTUESeen
    , exportAjaxError = rec.exportAjaxError
    , createNotification = rec.createNotification
    , createPersistentNotification = rec.createPersistentNotification
    , closeNotification = rec.closeNotification
    , cellLoaderConfig =
        { msg = rec.msg << CellLoaderMsg
        , fetchManyP2 = rec.fetchManyP2
        , queryAjaxError = rec.queryAjaxError
        , analyticsPlace = Place.CrosstabBuilderList
        , getAfterQueueMsg = \getMsg times -> getMsg times |> rec.msg
        }
    }


type CustomFrontendError
    = CannotMoveProjectSharedWithMe


customFrontendErrorToOtherError : CustomFrontendError -> OtherError
customFrontendErrorToOtherError customFrontendError =
    case customFrontendError of
        CannotMoveProjectSharedWithMe ->
            XBListCannotMoveProjectSharedWithMe


type DropOnItem
    = DropOnProject XBProject
    | DropOnFolder XBFolder


dndSystem : XB2.Share.DragAndDrop.Move.System Msg DropOnItem XBProject
dndSystem =
    XB2.Share.DragAndDrop.Move.config
        -- `ghostStyle` controls the inline-css, and we want `height` and `width` to be there
        |> XB2.Share.DragAndDrop.Move.ghostStyle [ XB2.Share.DragAndDrop.Move.preserveHeight, XB2.Share.DragAndDrop.Move.preserveWidth ]
        |> XB2.Share.DragAndDrop.Move.debounceMs 100
        |> XB2.Share.DragAndDrop.Move.create DragAndDropMsg


type Tab
    = AllProjects
    | MyProjects
    | SharedProjects


tabToString : Tab -> String
tabToString tab =
    case tab of
        AllProjects ->
            "All"

        MyProjects ->
            "My Crosstabs"

        SharedProjects ->
            "Shared"


crosstabCellLoader : LazyGlue Model (CrosstabCellLoader.Model ExportAction) msg msg
crosstabCellLoader =
    Glue.poly
        { get = .exportingProject >> Maybe.map .cellLoaderModel
        , set =
            \sub model ->
                case ( model.exportingProject, sub ) of
                    ( Just currentSubmodel, Just newCellLoaderModel ) ->
                        { model
                            | exportingProject =
                                Just
                                    { currentSubmodel | cellLoaderModel = newCellLoaderModel }
                        }

                    _ ->
                        model
        }



-- Model


type alias ExportingProject =
    { project : XBProjectFullyLoaded
    , cellLoaderModel : CrosstabCellLoader.Model ExportAction
    , waitingForQuestions : Maybe { startTime : Posix, time : Posix }
    }


type alias Model =
    { currentTime : Maybe Posix
    , activeDropdown : DropdownMenu.DropdownMenu Msg
    , sortingDropdownOpened : Bool
    , sortBy : SortBy
    , currentFolderId : Maybe XBFolderId
    , dndModel : XB2.Share.DragAndDrop.Move.Model DropOnItem XBProject
    , selection : Selection
    , searchBarModel : SearchInput.Model
    , exportingProject : Maybe ExportingProject
    , tab : Tab

    {- There's a weird behaviour with checkbox with the keyboard. Since they're inside an
       interactive element you have to explicitly tell that the label takes the onClick
       event but not the checkbox... But you need the event in the input/checkbox for the
       keyboard to be accesible so this field keeps track if any project list checkbox is
       focused and it swaps between events to avoid conflicts.
    -}
    , focusedProjectCheckbox : Maybe XBProjectId
    }


init : Config msg -> XBUserSettings -> ( Model, Cmd msg )
init config settings =
    { currentTime = Nothing
    , activeDropdown = DropdownMenu.init
    , sortingDropdownOpened = False
    , sortBy = LastModifiedDesc
    , currentFolderId = Nothing
    , dndModel = dndSystem.model
    , selection = Selection.empty
    , searchBarModel = SearchInput.initialModel
    , exportingProject = Nothing
    , tab = AllProjects
    , focusedProjectCheckbox = Nothing
    }
        |> Cmd.with (Task.perform (config.msg << CurrentTime) Time.now)
        |> (if settings.xb2ListFTUESeen then
                identity

            else
                Cmd.addTrigger config.setXB2ListFTUESeen
           )


getLoadedCrosstab : XBProjectFullyLoaded -> Model -> Maybe AudienceCrosstab
getLoadedCrosstab desiredProject model =
    Maybe.andThen
        (\{ project, cellLoaderModel } ->
            if project == desiredProject && CrosstabCellLoader.isFullyLoaded cellLoaderModel then
                Just cellLoaderModel.audienceCrosstab

            else
                Nothing
        )
        model.exportingProject



-- Helpers


minuteInMillis : Float
minuteInMillis =
    60 * 1000


isInRoot : Maybe XBFolderId -> Bool
isInRoot currentFolderId =
    currentFolderId == Nothing



-- Update


type Msg
    = NoOp
    | OpenProject XBProjectId
    | ToggleDropdownMenu (DropdownMenu.DropdownMenu Msg)
    | CloseDropdown
    | OpenConfirmDeleteProjectModal XBProject
    | OpenConfirmDeleteProjectsModal (List XBProject)
    | OpenUnshareMeConfirmModal XBProject
    | OpenRenameProjectModal XBProject
    | OpenDuplicateProjectModal XBProject
    | OpenShareProjectModal XBProject
    | OpenCreateFolderModal (List XBProject)
    | OpenMoveToFolderModal (List XBProject)
    | OpenRenameFolderModal XBFolder
    | OpenDeleteFolderModal XBFolder
    | OpenUngroupFolderModal XBFolder
    | CurrentTime Posix
    | SearchInputMsg SearchInput.Msg
    | SortByClicked SortBy
    | SetCurrentFolderId (Maybe XBFolderId)
    | DragAndDropMsg (XB2.Share.DragAndDrop.Move.Msg DropOnItem XBProject)
    | ClearSelection
    | ToggleProjectSelection (List XBProject) XBProjectId Events.ShiftState
    | SelectAll (List XBProject)
    | OpenMoveProjectsOutOfFolderModal (List XBProject)
    | CellLoaderMsg CrosstabCellLoader.Msg
    | ExportProject XBProject
    | ExportFullyLoadedProject XBProjectFullyLoaded
    | FullLoadAndExport XBProjectFullyLoaded
    | TrackFullLoadAndExport XBProjectFullyLoaded { startTime : Posix, time : Posix }
    | CancelFullTableLoad
    | ConfirmCancelFullTableLoad
    | ExportSuccess XB2.Share.Export.ExportResponse
    | ExportFailure (Error ExportError)
    | CloseNotification
    | DownloadFile String
    | SelectTab Tab
    | SetFocusedProjectCheckbox (Maybe XBProjectId)


updateTime : Config msg -> Cmd msg
updateTime { msg } =
    Task.perform (msg << CurrentTime) Time.now


subscriptions : XBStore.Store -> Model -> Sub Msg
subscriptions { xbProjects } model =
    let
        closeDropdownSub =
            if DropdownMenu.isAnyVisible model.activeDropdown then
                Browser.Events.onClick <| Decode.succeed CloseDropdown

            else
                Sub.none

        closeDropdownOnEsc : Sub Msg
        closeDropdownOnEsc =
            Browser.Events.onKeyUp (Decode.escDecoder CloseDropdown)

        currentTimeSub =
            case xbProjects of
                Success dict ->
                    if Dict.Any.isEmpty dict then
                        Sub.none

                    else
                        Time.every minuteInMillis CurrentTime

                _ ->
                    Sub.none

        selectProjectWithKeyboardSub =
            case model.focusedProjectCheckbox of
                Just projectId ->
                    Browser.Events.onKeyDown
                        (Decode.field "key" Decode.string
                            |> Decode.andThen
                                (\key ->
                                    case key of
                                        -- Space looks like this
                                        " " ->
                                            Decode.succeed <|
                                                ToggleProjectSelection
                                                    {- Empty list here would cause issue??
                                                       It doesn't seem so right now.
                                                    -}
                                                    []
                                                    projectId
                                                    { shiftPressed = False }

                                        "Enter" ->
                                            Decode.succeed <|
                                                ToggleProjectSelection
                                                    {- Empty list here would cause issue??
                                                       It doesn't seem so right now.
                                                    -}
                                                    []
                                                    projectId
                                                    { shiftPressed = False }

                                        _ ->
                                            Decode.fail "We do not care about this key."
                                )
                        )

                Nothing ->
                    Sub.none
    in
    Sub.batch
        [ closeDropdownSub
        , currentTimeSub
        , dndSystem.subscriptions model.dndModel
        , selectProjectWithKeyboardSub
        , closeDropdownOnEsc
        ]


closeDropdown : Model -> Model
closeDropdown model =
    { model | activeDropdown = DropdownMenu.init, sortingDropdownOpened = False }


clearSelection : Model -> Model
clearSelection model =
    { model | selection = Selection.empty }


storeActionFinished : Model -> ( Model, Cmd msg )
storeActionFinished model =
    clearSelection model
        |> Cmd.pure


exportNotificationId : String
exportNotificationId =
    "export-project-list-notification"


fetchQuestionsForCrosstab : Config msg -> ACrosstab.AudienceCrosstab -> ( model, Cmd msg ) -> ( model, Cmd msg )
fetchQuestionsForCrosstab config crosstab ( model, cmds ) =
    let
        addFetchQuestions =
            crosstab
                |> ACrosstab.questionCodes
                |> List.map (XB2.Share.Store.Platform2.FetchQuestion { showErrorModal = False })
                |> config.cellLoaderConfig.fetchManyP2
                |> Cmd.addTrigger
    in
    ( model, cmds )
        |> addFetchQuestions


fetchDatasetsForCrosstab : Config msg -> ACrosstab.AudienceCrosstab -> ( model, Cmd msg ) -> ( model, Cmd msg )
fetchDatasetsForCrosstab config crosstab ( model, cmds ) =
    let
        addFetchDatasets =
            crosstab
                |> ACrosstab.namespaceCodes
                |> List.map XB2.Share.Store.Platform2.FetchLineage
                |> config.cellLoaderConfig.fetchManyP2
                |> Cmd.addTrigger
    in
    ( model, cmds )
        |> addFetchDatasets


trackFullLoadAndExport : Config msg -> XB2.Router.Route -> Flags -> XBProjectFullyLoaded -> XB2.Share.Store.Platform2.Store -> { startTime : Posix, time : Posix } -> Model -> ( Model, Cmd msg )
trackFullLoadAndExport config route flags xbProject p2Store times model =
    case model.exportingProject of
        Just ({ cellLoaderModel } as exportingProject) ->
            case
                ACrosstab.questionCodes cellLoaderModel.audienceCrosstab
                    |> Store.getByIdsIfAllLoaded p2Store.questions
            of
                Just questions ->
                    let
                        metadata =
                            xbProject.data.metadata

                        baseAudiences =
                            cellLoaderModel.audienceCrosstab
                                |> ACrosstab.getBaseAudiences
                                |> ListZipper.toNonEmpty

                        waves =
                            cellLoaderModel.audienceCrosstab
                                |> ACrosstab.getActiveWaves
                                |> Set.Any.toList
                                |> Store.getByIds p2Store.waves

                        locations =
                            cellLoaderModel.audienceCrosstab
                                |> ACrosstab.getActiveLocations
                                |> Set.Any.toList
                                |> Store.getByIds p2Store.locations

                        { rowCount, colCount } =
                            ACrosstab.getDimensionsWithTotals cellLoaderModel.audienceCrosstab

                        settings =
                            { orientation = metadata.metricsTransposition
                            , activeMetrics = metadata.activeMetrics
                            , email = flags.can XB2.Share.Permissions.ReceiveEmailExports
                            }

                        sortConfig =
                            Sort.convertSortToSortConfig metadata.sort

                        exportData : Maybe ExportData
                        exportData =
                            baseAudiences
                                |> NonemptyList.toList
                                |> List.map
                                    (\baseAudience ->
                                        XBExport.exportResult
                                            sortConfig
                                            cellLoaderModel.audienceCrosstab
                                            baseAudience
                                            Nothing
                                            questions
                                            |> Maybe.map
                                                (\results ->
                                                    { metadata =
                                                        { locations = locations
                                                        , waves = waves
                                                        , base = baseAudience
                                                        , name = Just xbProject.name
                                                        , date = times.time
                                                        , heatmap = Nothing
                                                        , averageTimeFormat = metadata.averageTimeFormat
                                                        }
                                                    , settings = settings
                                                    , results = results
                                                    }
                                                )
                                    )
                                |> Maybe.combine
                    in
                    case exportData of
                        Nothing ->
                            model
                                |> Cmd.withTrigger
                                    (config.createNotification P2Icons.info <|
                                        Html.span [] [ Html.text "Couldn't export the crosstab project." ]
                                    )

                        Just data ->
                            let
                                tableLoadedEvent =
                                    { bases =
                                        baseAudiences
                                            |> NonemptyList.map Analytics.prepareBaseForTracking
                                            |> NonemptyList.toList
                                    , crosstab = ACrosstab.getCrosstab cellLoaderModel.audienceCrosstab
                                    , locations = locations
                                    , waves = waves
                                    , extraParams =
                                        { loadTime =
                                            (Time.posixToMillis times.time - Time.posixToMillis times.startTime)
                                                // 1000
                                        , afterLoadAction = "export"
                                        }
                                    }
                                        |> Analytics.TableFullyLoaded
                                        |> Analytics.trackEvent flags route Place.CrosstabBuilderList

                                analyticsExportCmd =
                                    { audiences =
                                        ACrosstab.getRows cellLoaderModel.audienceCrosstab
                                            ++ ACrosstab.getColumns cellLoaderModel.audienceCrosstab
                                            |> List.map .item
                                    , locations = locations
                                    , waves = waves
                                    , metricsTransposition = metadata.metricsTransposition
                                    , xbBases =
                                        baseAudiences
                                            |> NonemptyList.map Analytics.prepareBaseForTracking
                                            |> NonemptyList.toList
                                    , rowCount = rowCount
                                    , colCount = colCount
                                    , heatmapMetric = Nothing
                                    , store = p2Store
                                    , maybeProject = Just xbProject
                                    , isSaved = Saved xbProject.id
                                    }
                                        |> Analytics.Export
                                        |> Analytics.trackEvent flags route Place.CrosstabBuilderList
                            in
                            ( model
                            , XBExport.exportMultipleBases flags
                                (Just <|
                                    XB2.Share.Data.Id.unwrap xbProject.id
                                )
                                data
                                ExportSuccess
                                ExportFailure
                                |> Cmd.map config.msg
                            )
                                |> Cmd.add tableLoadedEvent
                                |> Cmd.add analyticsExportCmd

                Nothing ->
                    Cmd.pure { model | exportingProject = Just { exportingProject | waitingForQuestions = Just times } }

        Nothing ->
            Cmd.pure model


onP2StoreChange : Config msg -> XB2.Router.Route -> Flags -> XB2.Share.Store.Platform2.Store -> XB2.Share.Store.Platform2.Msg -> Model -> ( Model, Cmd msg )
onP2StoreChange config route flags newP2Store p2StoreMsg model =
    case p2StoreMsg of
        XB2.Share.Store.Platform2.QuestionFetched _ _ ->
            case model.exportingProject of
                Just { project, waitingForQuestions } ->
                    model
                        |> Maybe.unwrap Cmd.pure (trackFullLoadAndExport config route flags project newP2Store) waitingForQuestions
                        |> Glue.Lazy.updateWith crosstabCellLoader
                            (CrosstabCellLoader.dequeueAndInterpretCommand config.cellLoaderConfig
                                flags
                                newP2Store
                            )

                Nothing ->
                    Cmd.pure model

        XB2.Share.Store.Platform2.QuestionFetchError _ _ _ _ ->
            Cmd.pure model

        XB2.Share.Store.Platform2.LocationsFetched _ ->
            Cmd.pure model

        XB2.Share.Store.Platform2.LocationsByNamespaceFetched _ _ ->
            Cmd.pure model

        XB2.Share.Store.Platform2.WavesFetched _ ->
            Cmd.pure model

        XB2.Share.Store.Platform2.WavesByNamespaceFetched _ _ ->
            Cmd.pure model

        XB2.Share.Store.Platform2.AudienceRelatedMsg _ ->
            Cmd.pure model

        XB2.Share.Store.Platform2.DatasetFoldersFetched _ ->
            Cmd.pure model

        XB2.Share.Store.Platform2.DatasetsFetched _ ->
            Cmd.pure model

        XB2.Share.Store.Platform2.LineageFetched _ _ ->
            Cmd.pure model


update : Config msg -> XB2.Router.Route -> Flags -> Zone -> XBStore.Store -> XB2.Share.Store.Platform2.Store -> Msg -> Model -> ( Model, Cmd msg )
update config route flags zone xbStore p2Store msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SetFocusedProjectCheckbox mProjectId ->
            let
                elementToFocus : String
                elementToFocus =
                    "modal-list-select-all"
            in
            { model | focusedProjectCheckbox = mProjectId }
                |> Cmd.pure
                |> Cmd.add
                    (Task.attempt
                        (always <| config.msg NoOp)
                        (Dom.focus elementToFocus)
                    )

        OpenProject id ->
            model
                |> closeDropdown
                |> Cmd.withTrigger (config.openProject id)

        ToggleDropdownMenu dropdownMenu ->
            let
                focusElement : String
                focusElement =
                    "button-item-dropmenu"
            in
            { model
                | activeDropdown = DropdownMenu.toggle dropdownMenu model.activeDropdown
            }
                |> Cmd.with
                    (Task.attempt
                        (always <| config.msg NoOp)
                        (Dom.focus focusElement)
                    )

        CloseDropdown ->
            let
                dropDownMenuId : Maybe String
                dropDownMenuId =
                    DropdownMenu.getDropdownId model.activeDropdown

                elementToFocus : String
                elementToFocus =
                    case dropDownMenuId of
                        Just idvalidate ->
                            "icon-ellipsis-id-" ++ idvalidate

                        Nothing ->
                            ""
            in
            model
                |> closeDropdown
                |> Cmd.with
                    (Task.attempt
                        (always <| config.msg NoOp)
                        (Dom.focus elementToFocus)
                    )

        OpenConfirmDeleteProjectModal project ->
            model
                |> closeDropdown
                |> Cmd.withTrigger
                    (config.openModal <|
                        Modal.initConfirmDeleteProject project
                    )

        OpenConfirmDeleteProjectsModal projects ->
            model
                |> Cmd.withTrigger
                    (config.openModal <|
                        Modal.initConfirmDeleteProjects projects
                    )

        OpenUnshareMeConfirmModal project ->
            model
                |> closeDropdown
                |> Cmd.withTrigger
                    (config.openModal <|
                        Modal.initConfirmUnshareMe project
                    )

        OpenRenameProjectModal project ->
            model
                |> closeDropdown
                |> Cmd.withTrigger (config.openModal <| Modal.initRenameProject project)

        OpenDuplicateProjectModal project ->
            let
                msg_ =
                    config.openModal <|
                        Modal.initDuplicateProject
                            (NameForCopy.getWithLimit (XBStore.getAllProjectNames xbStore) NewName.maxLength project.name)
                            project
            in
            model
                |> closeDropdown
                |> Cmd.withTrigger msg_

        OpenShareProjectModal project ->
            model
                |> closeDropdown
                |> Cmd.withTrigger (config.openSharingModal project)

        OpenCreateFolderModal projects ->
            let
                cmd =
                    Cmd.fromMaybe
                        (\time ->
                            config.openModal <|
                                Modal.initCreateFolder
                                    (NewName.timeBasedFolderName (XBStore.folderNameExists xbStore) zone time)
                                    projects
                        )
                        model.currentTime
            in
            model
                |> closeDropdown
                |> Cmd.with cmd

        OpenMoveToFolderModal projects ->
            model
                |> closeDropdown
                |> Cmd.withTrigger (config.openModal <| Modal.initMoveToFolder projects)

        OpenRenameFolderModal folder ->
            model
                |> closeDropdown
                |> Cmd.withTrigger (config.openModal <| Modal.initRenameFolder folder)

        OpenDeleteFolderModal folder ->
            let
                projectsInsideFolder =
                    xbStore.xbProjects
                        |> RemoteData.toMaybe
                        |> Maybe.unwrap 0
                            (Dict.Any.filter (\_ { folderId } -> Just folder.id == folderId)
                                >> Dict.Any.size
                            )
            in
            model
                |> closeDropdown
                |> Cmd.withTrigger (config.openModal <| Modal.initConfirmDeleteFolder projectsInsideFolder folder)

        OpenUngroupFolderModal folder ->
            model
                |> closeDropdown
                |> Cmd.withTrigger (config.openModal <| Modal.initConfirmUngroupFolder folder)

        CurrentTime time ->
            ( { model | currentTime = Just time }
            , Cmd.none
            )

        SearchInputMsg subMsg ->
            SearchInput.update subMsg model.searchBarModel
                |> (\( subm_, subcmd ) ->
                        ( { model | searchBarModel = subm_ }
                        , Cmd.map (config.msg << SearchInputMsg) subcmd
                        )
                   )

        SortByClicked sortBy ->
            let
                sortEvent : Cmd msg
                sortEvent =
                    { sorting = Sort.sortByToString sortBy }
                        |> Analytics.ListSorted
                        |> Analytics.trackEvent flags route Place.CrosstabBuilderList
            in
            closeDropdown
                { model
                    | sortBy =
                        if model.sortBy == LastModifiedDesc && sortBy == LastModifiedDesc then
                            LastModifiedAsc

                        else
                            sortBy
                }
                |> Cmd.with sortEvent

        SetCurrentFolderId maybeFolderId ->
            { model | currentFolderId = maybeFolderId }
                |> clearSelection
                |> Cmd.pure

        DragAndDropMsg dndMsg ->
            let
                ( return, newDndModel, dndCmd ) =
                    dndSystem.update dndMsg model.dndModel
            in
            case return of
                Just { dropListId, dragItem } ->
                    let
                        isDropItemSharedWithMe =
                            case dropListId of
                                DropOnProject project ->
                                    XBData.isSharedWithMe project.shared

                                DropOnFolder _ ->
                                    False
                    in
                    (if XBData.isSharedWithMe dragItem.shared || isDropItemSharedWithMe then
                        { model | dndModel = newDndModel }
                            |> Cmd.with (Cmd.map config.msg dndCmd)
                            |> Cmd.addTrigger (config.openError CannotMoveProjectSharedWithMe)

                     else
                        case dropListId of
                            DropOnProject project ->
                                ( { model | dndModel = newDndModel }
                                , Cmd.batch
                                    [ dndCmd
                                    , Task.perform (\_ -> OpenCreateFolderModal [ dragItem, project ]) (Task.succeed ())
                                    ]
                                    |> Cmd.map config.msg
                                )

                            DropOnFolder folder ->
                                { model | dndModel = newDndModel }
                                    |> Cmd.with (Cmd.map config.msg dndCmd)
                                    |> Cmd.addTrigger (config.moveToFolder (Just folder) dragItem)
                    )
                        |> Cmd.add (Analytics.trackEvent flags route Place.CrosstabBuilderList Analytics.ManagementPageDragAndDropUsed)

                Nothing ->
                    ( { model | dndModel = newDndModel }
                        |> closeDropdown
                    , Cmd.map config.msg dndCmd
                    )

        ClearSelection ->
            Cmd.pure { model | selection = Selection.empty }

        ToggleProjectSelection allListedProjects id { shiftPressed } ->
            let
                projectIdsToSelect : List XBProjectId
                projectIdsToSelect =
                    if shiftPressed && (not <| Selection.isSelected id model.selection) then
                        List.selectRange
                            { isSelected = \p -> Selection.isSelected p.id model.selection
                            , itemToSelect = .id >> (==) id
                            }
                            allListedProjects
                            |> List.map .id

                    else
                        [ id ]
            in
            Cmd.pure
                { model
                    | selection =
                        projectIdsToSelect
                            |> List.foldr
                                (\projectIdToSelect ->
                                    Selection.toggle projectIdToSelect
                                )
                                model.selection
                }

        SelectAll projects ->
            Cmd.pure { model | selection = Selection.selectAll (List.map .id projects) model.selection }

        OpenMoveProjectsOutOfFolderModal projects ->
            model
                |> closeDropdown
                |> Cmd.withTrigger (config.openModal <| Modal.initMoveOutOfFolder projects)

        CellLoaderMsg cellLoaderMsg ->
            Cmd.pure model
                |> Glue.Lazy.updateWith crosstabCellLoader (CrosstabCellLoader.update config.cellLoaderConfig route flags p2Store cellLoaderMsg)

        ExportProject xbProject ->
            ( model
            , XBStore.fetchTaskXBProjectFullyLoaded xbProject flags
                |> Task.map ExportFullyLoadedProject
                |> Task.attempt (Result.withDefault NoOp >> config.msg)
            )

        ExportFullyLoadedProject xbProject ->
            let
                showModalForExportIfNotEmpty currentTime =
                    ACrosstab.initFromProject
                        currentTime
                        (ACrosstab.crosstabSizeLimit flags.can)
                        0
                        xbProject
                        |> Result.map
                            (\( crosstab, crosstabCommands ) ->
                                if ACrosstab.isEmpty crosstab then
                                    model
                                        |> Cmd.withTrigger
                                            (config.createNotification P2Icons.info <|
                                                Html.span [] [ Html.text "Couldn't export the empty crosstab project." ]
                                            )

                                else
                                    let
                                        newCellLoaderModel =
                                            CrosstabCellLoader.init crosstab
                                    in
                                    { model
                                        | exportingProject =
                                            Just
                                                { project = xbProject
                                                , cellLoaderModel = newCellLoaderModel
                                                , waitingForQuestions = Nothing
                                                }
                                    }
                                        |> Cmd.withTrigger
                                            (config.openModal <|
                                                Modal.ConfirmFullLoadForExportFromList
                                                    (CrosstabCellLoader.notLoadedCellCount newCellLoaderModel)
                                                    xbProject
                                            )
                                        |> Glue.Lazy.updateWith crosstabCellLoader
                                            (CrosstabCellLoader.interpretCommands config.cellLoaderConfig flags p2Store AudienceIntersect.Export crosstabCommands)
                            )
                        |> Result.withDefault (Cmd.pure model)
            in
            case ( model.exportingProject, model.currentTime ) of
                ( Just { project, cellLoaderModel }, Just time ) ->
                    if project.id == xbProject.id && CrosstabCellLoader.isFullyLoaded cellLoaderModel then
                        model
                            |> Cmd.withTrigger (FullLoadAndExport xbProject |> config.msg)

                    else
                        showModalForExportIfNotEmpty time

                ( _, Just time ) ->
                    showModalForExportIfNotEmpty time

                _ ->
                    -- This can happen only if there is a bug in the code and currentTime is not initialised
                    model
                        |> Cmd.withTrigger
                            (config.createNotification P2Icons.info <|
                                Html.span [] [ Html.text "Missing time information for export." ]
                            )

        FullLoadAndExport project ->
            Cmd.pure model
                |> Glue.Lazy.updateWith crosstabCellLoader
                    (\cellLoaderModel ->
                        CrosstabCellLoader.reloadNotAskedCellsIfFullLoadRequestedWithOriginAndMsg
                            config.cellLoaderConfig
                            (TrackFullLoadAndExport project)
                            AudienceIntersect.Export
                            cellLoaderModel
                            |> fetchQuestionsForCrosstab config cellLoaderModel.audienceCrosstab
                            |> fetchDatasetsForCrosstab config cellLoaderModel.audienceCrosstab
                    )
                |> Cmd.addTrigger config.closeModal

        CancelFullTableLoad ->
            model
                |> Cmd.withTrigger (config.openModal Modal.ConfirmCancelExportFromList)

        ConfirmCancelFullTableLoad ->
            model
                |> Cmd.withTrigger config.closeModal
                |> Glue.Lazy.updateWith crosstabCellLoader
                    (CrosstabCellLoader.cancelAllLoadingRequests config.cellLoaderConfig flags p2Store)

        TrackFullLoadAndExport xbProject times ->
            -- Here change to progress modal
            trackFullLoadAndExport config route flags xbProject p2Store times model

        ExportSuccess response ->
            -- Here is where the export succeeds
            ( model
            , case response of
                XB2.Share.Export.Mail { message } ->
                    Cmd.perform <|
                        config.createNotification P2Icons.export <|
                            Html.text message

                XB2.Share.Export.DirectDownload { downloadUrl } ->
                    Cmd.perform
                        (config.createPersistentNotification exportNotificationId <|
                            Notification.exportView
                                { downloadMsg = DownloadFile downloadUrl
                                , closeMsg = CloseNotification
                                }
                        )
            )

        CloseNotification ->
            model
                |> Cmd.withTrigger (config.closeNotification exportNotificationId)

        DownloadFile downloadUrl ->
            ( model, XB2.Share.Export.urlDownload downloadUrl )
                |> Cmd.addTrigger (config.closeNotification exportNotificationId)

        ExportFailure httpError ->
            -- Here is where it fails
            ( model
            , Cmd.perform <| config.exportAjaxError httpError
            )

        SelectTab tab ->
            { model | tab = tab, currentFolderId = Nothing }
                |> Cmd.with
                    ({ tab = tabToString tab }
                        |> Analytics.TabsClicked
                        |> Analytics.trackEvent flags route Place.CrosstabBuilderList
                    )


folderDeleted : XBFolderId -> Model -> Model
folderDeleted folderId model =
    if model.currentFolderId == Just folderId then
        { model | currentFolderId = Nothing }

    else
        model



-- View


moduleClass : ClassName
moduleClass =
    WeakCss.namespace "xb2-list"


headerClass : ClassName
headerClass =
    WeakCss.add "header" moduleClass


errorView : String -> Html msg
errorView error =
    Html.div
        [ WeakCss.nest "error" moduleClass ]
        [ Html.div
            [ WeakCss.nestMany [ "error", "title" ] moduleClass ]
            [ Html.text "Error fetching saved Crosstabs"
            ]
        , Html.div
            [ WeakCss.nestMany [ "error", "message" ] moduleClass ]
            [ Markdown.toHtml [] error ]
        ]


emptyView : Config msg -> Flags -> Model -> Html msg
emptyView config flags model =
    let
        cls =
            WeakCss.add "empty-list" moduleClass

        viewAllAndMyProjects =
            [ Html.div
                [ WeakCss.nest "top-icon" cls ]
                [ XB2.Share.Icons.icon [] P2Icons.crosstabFTUE ]
            , Html.div
                [ WeakCss.nest "title" cls ]
                [ Html.text "Let’s create a crosstab"
                ]
            , Html.div
                [ WeakCss.nest "message" cls ]
                [ Html.text "Crosstabs are a tool to help you analyse and understand different data sets. Once you start building crosstabs you'll\u{00A0}see them here." ]
            , Html.a
                [ WeakCss.nest "create-btn" cls
                , Events.onClickPreventDefaultAndStopPropagation config.createXBProject
                , Attrs.href <|
                    XB2.Router.toUrlString
                        (XB2.Router.getPrefix flags)
                        (XB2.Router.Project Nothing)
                        []
                ]
                [ Html.text "Create a crosstab"
                , XB2.Share.Icons.icon [] P2Icons.plusSign
                ]
            ]
    in
    Html.div
        [ WeakCss.toClass cls ]
    <|
        case model.tab of
            AllProjects ->
                viewAllAndMyProjects

            MyProjects ->
                viewAllAndMyProjects

            SharedProjects ->
                [ Html.div
                    [ WeakCss.nest "top-icon" cls ]
                    [ XB2.Share.Icons.icon [] P2Icons.crosstabFTUE ]
                , Html.div
                    [ WeakCss.nest "message" cls ]
                    [ Html.text "Crosstabs shared with you will"
                    , Html.br [] []
                    , Html.text "appear on this page."
                    ]
                ]


getCorrectFormattedTimes : Zone -> Posix -> Posix -> { absoluteTime : String, correctTime : String }
getCorrectFormattedTimes zone now timeToFormat =
    let
        timeIsInFuture =
            Time.posixToMillis timeToFormat > Time.posixToMillis now

        correctTime =
            if timeIsInFuture then
                now

            else
                timeToFormat

        absoluteTime : String
        absoluteTime =
            DateFormat.format XB2.Share.Time.Format.format_D_MMM_YYYY_hh_mm zone correctTime
    in
    { absoluteTime = absoluteTime, correctTime = XB2.Share.Time.Format.xbRelativeTime now correctTime }


createdAtView : Zone -> { a | now : Posix, created : Posix } -> Html msg
createdAtView zone { created } =
    let
        formattedDate : String
        formattedDate =
            DateFormat.format XB2.Share.Time.Format.fullscreenPublishedFormat zone created
    in
    Html.div [ Attrs.title formattedDate ]
        [ Html.text formattedDate ]


updatedAtView : Zone -> { a | now : Posix, updated : Posix } -> Html msg
updatedAtView zone { now, updated } =
    let
        { absoluteTime, correctTime } =
            getCorrectFormattedTimes zone now updated
    in
    Html.div
        [ Attrs.title absoluteTime ]
        [ Html.text correctTime ]


listItemTimesView : Zone -> Maybe { a | now : Posix, updated : Posix, created : Posix } -> List (Html msg)
listItemTimesView zone =
    Maybe.unwrap []
        (\times ->
            [ Html.div
                [ WeakCss.nestMany [ "item", "time-label" ] moduleClass
                , Attrs.attribute "data-test-id" "date-created"
                ]
                [ createdAtView zone times
                ]
            , Html.div
                [ WeakCss.nestMany [ "item", "time-label" ] moduleClass
                , Attrs.attribute "data-test-id" "last-modified"
                ]
                [ updatedAtView zone times
                ]
            ]
        )


searchHighlightView : String -> String -> List (Html Msg)
searchHighlightView searchTerm name =
    if String.isEmpty searchTerm then
        [ Html.text name ]

    else
        XB2.Share.Search.highlight
            { match = Html.em [ WeakCss.nest "match" moduleClass ] << List.singleton << Html.text
            , rest = Html.text
            }
            searchTerm
            name


moreOptionsConfig : XB2.MoreOptions.Config Msg
moreOptionsConfig =
    { renameFolder = OpenRenameFolderModal
    , deleteFolder = OpenDeleteFolderModal
    , ungroupFolder = OpenUngroupFolderModal
    , confirmDeleteProject = OpenConfirmDeleteProjectModal
    , duplicateProject = OpenDuplicateProjectModal
    , renameProject = OpenRenameProjectModal
    , openProject = OpenProject
    , shareProject = OpenShareProjectModal
    , createFolder = OpenCreateFolderModal
    , moveToFolder = OpenMoveToFolderModal << List.singleton
    , unshareMe = OpenUnshareMeConfirmModal
    , moveOutOfFolder = OpenMoveProjectsOutOfFolderModal << List.singleton
    , export = ExportProject
    }


listFolderView : Config msg -> Zone -> Maybe { updatedAt : Posix, createdAt : Posix } -> Model -> Int -> XBFolder -> Html msg
listFolderView config zone maybeFolderTimes model index folder =
    let
        htmlId =
            "xb_folder_" ++ XB2.Share.Data.Id.unwrap folder.id

        maybeWithTimesRecord =
            Maybe.map2 (\now { updatedAt, createdAt } -> { now = now, updated = updatedAt, created = createdAt })
                model.currentTime
                maybeFolderTimes

        dropdownId =
            "xb-list-item-dd-menu-folder-" ++ XB2.Share.Data.Id.unwrap folder.id

        moreOptionsParameters =
            { isDropdownOpen = DropdownMenu.isVisible dropdownId model.activeDropdown
            , dropdownId = dropdownId
            , expandOnRight = False
            , withDropdownMenu = DropdownMenu.with ToggleDropdownMenu
            }

        dndEvents : List (Html.Attribute Msg)
        dndEvents =
            if (dndSystem.info model.dndModel.list /= Nothing) && isInRoot model.currentFolderId then
                dndSystem.dropEvents (DropOnFolder folder) index htmlId

            else
                []

        moreOptionsClass =
            WeakCss.namespace "xb2-list" |> WeakCss.addMany [ "item", "more-options-dropdown" ]
    in
    Html.map config.msg <|
        Html.div
            [ WeakCss.add "item" moduleClass |> WeakCss.withActiveStates [ "folder" ]
            , Attrs.id htmlId
            ]
            [ Html.button
                ((WeakCss.addMany [ "item", "link" ] moduleClass
                    |> WeakCss.withStates
                        [ ( "drag-over"
                          , isDragOver { overFolder = True } index model
                          )
                        , ( "folder", True )
                        ]
                 )
                    :: (Events.onClick <| SetCurrentFolderId (Just folder.id))
                    :: Attrs.tabindex 0
                    :: dndEvents
                )
                ([ Html.div [ WeakCss.nestMany [ "item", "group" ] moduleClass ]
                    [ Html.span [ WeakCss.nestMany [ "item", "folder-icons" ] moduleClass ]
                        [ XB2.Share.Icons.icon [] P2Icons.folderFilled
                        , XB2.Share.Icons.icon [] P2Icons.crosstab
                        ]
                    , Html.div
                        [ WeakCss.nestMany [ "item", "name" ] moduleClass
                        , Attrs.title folder.name
                        ]
                        (searchHighlightView model.searchBarModel.searchTerm folder.name)
                    ]
                 , Html.div [] []
                 ]
                    ++ listItemTimesView zone maybeWithTimesRecord
                )
            , XB2.MoreOptions.onFolderListView moreOptionsConfig moreOptionsParameters moreOptionsClass (Just folder)
            ]


listFoldersView : Config msg -> Zone -> List ( Maybe CreateUpdateTimes, XBFolder ) -> Model -> Html msg
listFoldersView config zone filteredFolders model =
    Html.viewIf ((not <| List.isEmpty filteredFolders) && isInRoot model.currentFolderId) <|
        Html.div [ WeakCss.nest "folders" moduleClass ] <|
            List.indexedMap
                (\index ( folderTimes, folder ) ->
                    listFolderView config zone folderTimes model index folder
                )
                filteredFolders


projectIconView : XB2.Share.CoolTip.Position -> Maybe XBProject -> XBProject -> Html msg
projectIconView coolTipPosition copiedFrom project =
    let
        iconWithTooltip html icon_ =
            P2CoolTip.view
                { offset = Nothing
                , type_ = XB2.Share.CoolTip.Normal
                , position = coolTipPosition
                , wrapperAttributes = [ WeakCss.nestMany [ "item", "icon", "tooltip" ] moduleClass ]
                , targetAttributes = []
                , targetHtml = [ XB2.Share.Icons.icon [] icon_ ]
                , tooltipAttributes = []
                , tooltipHtml = html
                }
    in
    case copiedFrom of
        Just { name } ->
            iconWithTooltip
                (Html.text <| "This is a copy of \"" ++ name ++ "\"")
                P2Icons.crosstab

        Nothing ->
            let
                icon =
                    projectIcon project.shared
            in
            SharingIcon.view moduleClass { icon = icon, notSharedIcon = XB2.Share.Icons.icon [] icon, coolTipPosition = coolTipPosition } project


projectCheckboxView : Config msg -> ClassName -> XBProject -> Bool -> List XBProject -> Html msg
projectCheckboxView config className project isProjectSelected filteredProjects =
    Html.label
        [ className |> WeakCss.nestMany [ "item", "select" ]
        , Events.onClickStopPropagationWithShiftCheck
            (config.msg << ToggleProjectSelection filteredProjects project.id)
        ]
        [ Html.input
            [ WeakCss.nestMany [ "item", "select", "input" ] className
            , Attrs.type_ "checkbox"
            , Attrs.checked isProjectSelected
            , Events.onClickStopPropagation <| config.msg NoOp
            , Attrs.attribute "aria-label" "Select project"
            , Attrs.tabindex 0
            , Events.onFocus (config.msg <| SetFocusedProjectCheckbox (Just project.id))
            , Events.onBlur (config.msg <| SetFocusedProjectCheckbox Nothing)
            ]
            []
        , Html.div
            [ className
                |> WeakCss.addMany [ "item", "select", "indicator" ]
                |> WeakCss.withStates [ ( "selected", isProjectSelected ) ]
            ]
            [ Html.i
                [ className |> WeakCss.nestMany [ "item", "select", "indicator", "icon" ] ]
                [ XB2.Share.Icons.icon [] <|
                    if isProjectSelected then
                        P2Icons.checkboxFilled

                    else
                        P2Icons.checkboxUnfilled
                ]
            ]
        ]


isDragOver : { overFolder : Bool } -> Int -> Model -> Bool
isDragOver { overFolder } index model =
    let
        dragedOver dropListId =
            case dropListId of
                DropOnFolder _ ->
                    overFolder

                DropOnProject _ ->
                    not overFolder
    in
    case dndSystem.info model.dndModel.list of
        Just { dropIndex, dropListId } ->
            index == dropIndex && dragedOver dropListId

        Nothing ->
            False


listProjectView : Config msg -> Flags -> Zone -> XB2.Share.Data.Id.IdDict XBProjectIdTag XBProject -> Bool -> List XBProject -> Model -> Int -> XBProject -> Html msg
listProjectView config flags zone projects areFoldersPresent filteredProjects model index ({ id, name, updatedAt, createdAt, shared } as project) =
    let
        isRootFolder =
            isInRoot model.currentFolderId

        dropdownId =
            "xb-list-item-dd-menu-" ++ XB2.Share.Data.Id.unwrap project.id

        moreOptionsParameters =
            { isDropdownOpen = DropdownMenu.isVisible dropdownId model.activeDropdown
            , dropdownId = dropdownId
            , inRootFolder = isRootFolder
            , areFoldersPresent = areFoldersPresent
            , expandOnRight = False
            , withDropdownMenu = DropdownMenu.with ToggleDropdownMenu
            }

        htmlId =
            "xb_project_" ++ XB2.Share.Data.Id.unwrap project.id

        dndEvents : List (Html.Attribute Msg)
        dndEvents =
            case dndSystem.info model.dndModel.list of
                Just { dragIndex } ->
                    if dragIndex /= index then
                        dndSystem.dropEvents (DropOnProject project) index htmlId

                    else
                        []

                Nothing ->
                    let
                        isAnySelected =
                            Selection.isAnySelected model.selection
                    in
                    if isRootFolder && not isAnySelected then
                        dndSystem.dragEvents (DropOnProject project) project index htmlId

                    else
                        []

        isBeingDragged : Bool
        isBeingDragged =
            case dndSystem.info model.dndModel.list of
                Just { dragIndex } ->
                    index == dragIndex

                Nothing ->
                    False

        isProjectSelected =
            Selection.isSelected project.id model.selection

        states : List ( String, Bool )
        states =
            [ ( "project", True )
            , ( "selected", isProjectSelected )
            ]

        maybeWithTimesRecord =
            Maybe.map (\now -> { now = now, updated = updatedAt, created = createdAt }) model.currentTime

        copiedFrom =
            project.copiedFrom
                |> Maybe.andThen (\projectId -> Dict.Any.get projectId projects)

        moreOptionsClass =
            WeakCss.namespace "xb2-list" |> WeakCss.addMany [ "item", "more-options-dropdown" ]
    in
    Html.div
        [ WeakCss.add "item" moduleClass |> WeakCss.withStates states
        , Attrs.id htmlId
        ]
        [ Html.a
            ([ WeakCss.addMany [ "item", "link" ] moduleClass
                |> WeakCss.withStates
                    [ ( "placeholder", isBeingDragged )
                    , ( "drag-over", isDragOver { overFolder = False } index model && not isBeingDragged )
                    ]
             , Attrs.attributeIf (dndSystem.info model.dndModel.list == Nothing) <| Events.onClickPreventDefaultAndStopPropagation <| config.openProject id
             , Attrs.href <|
                XB2.Router.toUrlString
                    (XB2.Router.getPrefix flags)
                    (XB2.Router.Project <| Just id)
                    []
             ]
                ++ List.map (Attrs.map config.msg) dndEvents
            )
            (if isBeingDragged then
                []

             else
                [ Html.div [ WeakCss.nestMany [ "item", "group" ] moduleClass ]
                    [ projectCheckboxView config
                        moduleClass
                        project
                        isProjectSelected
                        filteredProjects
                    , Html.span
                        [ WeakCss.nestMany [ "item", "icon" ] moduleClass ]
                        [ projectIconView XB2.Share.CoolTip.TopRight copiedFrom project ]
                    , Html.map config.msg <|
                        Html.div
                            [ WeakCss.nestMany [ "item", "name" ] moduleClass
                            , Attrs.title name
                            ]
                            (searchHighlightView model.searchBarModel.searchTerm name)
                    ]
                , Html.div
                    [ WeakCss.nestMany [ "item", "owner" ] moduleClass
                    , shared
                        |> XBData.projectOwner
                        |> projectOwnerToString
                        |> Attrs.title
                    ]
                    [ shared
                        |> XBData.projectOwner
                        |> projectOwnerToString
                        |> Html.text
                    ]
                ]
                    ++ listItemTimesView zone maybeWithTimesRecord
            )
        , Html.viewIf (not isBeingDragged) <|
            Html.map config.msg <|
                XB2.MoreOptions.onProjectListView moreOptionsConfig flags moreOptionsParameters moreOptionsClass (Just project)
        ]


listProjectsView : Config msg -> Flags -> Zone -> XB2.Share.Data.Id.IdDict XBProjectIdTag XBProject -> Bool -> Model -> List XBProject -> Html msg
listProjectsView config flags zone projects areFoldersPresent model filteredProjects =
    Html.viewIf (not <| List.isEmpty filteredProjects) <|
        Html.div
            [ WeakCss.add "projects" moduleClass
                |> WeakCss.withStates [ ( "any-selected", Selection.isAnySelected model.selection ) ]
            ]
        <|
            List.indexedMap (listProjectView config flags zone projects areFoldersPresent filteredProjects model) filteredProjects


listGhostView : XB2.Share.Data.Id.IdDict XBProjectIdTag XBProject -> Model -> Html Msg
listGhostView projects model =
    case dndSystem.info model.dndModel.list of
        Just { dragItem } ->
            let
                iconView icon =
                    Html.div [ WeakCss.nestMany [ "item", "icon" ] moduleClass ]
                        [ XB2.Share.Icons.icon [] icon ]
            in
            Html.div
                ((moduleClass |> WeakCss.nest "ghost")
                    :: dndSystem.ghostStyles model.dndModel
                )
                [ Html.div [ WeakCss.add "item" moduleClass |> WeakCss.withActiveStates [ "project" ] ]
                    [ Html.a [ WeakCss.addMany [ "item", "link" ] moduleClass |> WeakCss.withActiveStates [ "ghost" ] ]
                        [ case Maybe.andThen (\projectId -> Dict.Any.get projectId projects) dragItem.copiedFrom of
                            Nothing ->
                                iconView <| projectIcon dragItem.shared

                            Just _ ->
                                iconView P2Icons.crosstab
                        , Html.div
                            [ WeakCss.nestMany [ "item", "name" ] moduleClass
                            , Attrs.title dragItem.name
                            ]
                            (searchHighlightView model.searchBarModel.searchTerm dragItem.name)
                        ]
                    ]
                ]

        Nothing ->
            Html.nothing


sortByView :
    { label : String
    , asc : SortBy
    , desc : SortBy
    , currentSorting : SortBy
    , active : Bool
    }
    -> Html Msg
sortByView { label, asc, desc, currentSorting, active } =
    let
        setDirection : Direction -> SortBy
        setDirection direction =
            case direction of
                Asc ->
                    desc

                Desc ->
                    asc

                Off ->
                    LastModifiedDesc

        currentDirection : Direction
        currentDirection =
            if currentSorting == asc then
                Desc

            else if currentSorting == desc then
                Asc

            else
                Off

        baseClassName : ClassName
        baseClassName =
            WeakCss.addMany [ "list", "header", "sort" ] moduleClass
    in
    SortingHeader.view
        { baseClass = baseClassName
        , stateClasses = List.addIf active "active" []
        , label = label
        , setDirection = setDirection >> SortByClicked
        , direction = currentDirection
        }


createBtnView : Config msg -> Flags -> Html msg
createBtnView config flags =
    Html.div
        [ WeakCss.nestMany [ "create-btn", "wrapper" ] moduleClass ]
        [ Html.a
            [ Events.onClickPreventDefaultAndStopPropagation config.createXBProject
            , WeakCss.nest "create-btn" moduleClass
            , Attrs.href <|
                XB2.Router.toUrlString
                    (XB2.Router.getPrefix flags)
                    (XB2.Router.Project Nothing)
                    []
            ]
            [ Html.text "Create a crosstab"
            , XB2.Share.Icons.icon [] P2Icons.plusSign
            ]
        ]


type alias CreateUpdateTimes =
    { updatedAt : Posix, createdAt : Posix }


type alias ProjectsFoldersViewData =
    { projects : List XBProject
    , folders : List ( Maybe CreateUpdateTimes, XBFolder )
    , notShownWhenSearchCount : Int
    , emptySearchResult : Bool
    , isEmpty : Bool
    }


filterOutLinkSharedProjects : IdDict XBProjectIdTag XBProject -> IdDict XBProjectIdTag XBProject
filterOutLinkSharedProjects =
    Dict.Any.filter (\_ project -> project.shared /= XBData.SharedByLink)


getProjectsFoldersViewData : XB2.Share.Data.Id.IdDict XBProjectIdTag XBProject -> XB2.Share.Data.Id.IdDict XBFolderIdTag XBFolder -> Model -> ProjectsFoldersViewData
getProjectsFoldersViewData dictProjects_ dictFolders model =
    let
        dictProjects : XB2.Share.Data.Id.IdDict XBProjectIdTag XBProject
        dictProjects =
            filterOutLinkSharedProjects dictProjects_

        filterByTab : List XBProject -> List XBProject
        filterByTab =
            case model.tab of
                AllProjects ->
                    identity

                MyProjects ->
                    List.filter (.shared >> XBData.isMine)

                SharedProjects ->
                    List.filter (.shared >> XBData.isMine >> not)

        projects : List XBProject
        projects =
            Dict.Any.values dictProjects
                |> filterByTab

        projectsCount : Int
        projectsCount =
            List.length projects

        filterProjectsByCurrentFolder =
            List.filter (\{ folderId } -> folderId == model.currentFolderId)

        isSearching =
            not <| String.isEmpty model.searchBarModel.searchTerm

        filterFoldersBySearch : List XBFolder -> List XBFolder
        filterFoldersBySearch folders_ =
            if isSearching then
                let
                    folderIds : List XBFolderId
                    folderIds =
                        List.filterMap .folderId (XB2.Share.Search.filter .name model.searchBarModel.searchTerm projects)

                    ( filterSearchFoldersIn, filterSearchFoldersOut ) =
                        List.partition (\f -> List.member f.id folderIds) folders_
                in
                filterSearchFoldersIn ++ XB2.Share.Search.filter .name model.searchBarModel.searchTerm filterSearchFoldersOut

            else
                folders_

        filterProjectsBySearch : List XBProject -> List XBProject
        filterProjectsBySearch projects_ =
            if isSearching then
                let
                    searchedProjects =
                        XB2.Share.Search.filter .name model.searchBarModel.searchTerm projects_
                in
                case model.currentFolderId of
                    Nothing ->
                        searchedProjects

                    Just folderId ->
                        case Dict.Any.get folderId dictFolders of
                            Nothing ->
                                searchedProjects

                            Just folder ->
                                if
                                    XB2.Share.Search.matches .name model.searchBarModel.searchTerm folder
                                        && (searchedProjects
                                                |> List.filter (\p -> p.folderId == Just folderId)
                                                |> List.isEmpty
                                           )
                                then
                                    projects_

                                else
                                    searchedProjects

            else
                projects_

        sortProjects : List XBProject -> List XBProject
        sortProjects =
            List.map
                (\project ->
                    { item = project
                    , getUpdatedAt = .updatedAt
                    , getCreatedAt = .createdAt
                    , getName = .name
                    , owner = XBData.projectOwner project.shared
                    , parent = Maybe.andThen (\projectId -> Dict.Any.get projectId dictProjects) project.copiedFrom
                    }
                )
                >> Sort.sort model.sortBy

        sortedFilteredProjects_ : List XBProject
        sortedFilteredProjects_ =
            projects
                |> filterProjectsByCurrentFolder
                |> filterProjectsBySearch
                |> sortProjects

        folderTimeFrom get folderIdToCheck =
            projects
                |> List.filter (\{ folderId } -> Just folderIdToCheck == folderId)
                |> List.map get
                |> List.reverseSortBy Time.posixToMillis
                |> List.head

        folderTimes : XBFolder -> Maybe CreateUpdateTimes
        folderTimes folder =
            Maybe.map2 (\updatedAt createdAt -> { createdAt = createdAt, updatedAt = updatedAt })
                (folderTimeFrom .updatedAt folder.id)
                (folderTimeFrom .createdAt folder.id)

        sortedFilteredProjectsCount =
            List.length sortedFilteredProjects

        ( sortedFilteredFolders, sortedFilteredProjects ) =
            if isInRoot model.currentFolderId then
                let
                    folders : List XBFolder
                    folders =
                        Dict.Any.values dictFolders

                    sortedFilteredFolders_ : List XBFolder
                    sortedFilteredFolders_ =
                        folders
                            |> filterFoldersBySearch
                in
                List.append
                    (List.map DropOnFolder sortedFilteredFolders_)
                    (List.map DropOnProject sortedFilteredProjects_)
                    |> List.map
                        (\item ->
                            case item of
                                DropOnFolder f ->
                                    ( [ f ], [] )

                                DropOnProject p ->
                                    ( [], [ p ] )
                        )
                    |> List.unzip
                    |> (\( fs, ps ) -> ( List.fastConcat fs, List.fastConcat ps ))
                    |> Tuple.mapFirst
                        (List.filterMap
                            (\f ->
                                let
                                    fTimes =
                                        folderTimes f
                                in
                                if model.tab /= AllProjects && Maybe.isNothing fTimes then
                                    Nothing

                                else
                                    Just
                                        { item = ( fTimes, f )
                                        , getUpdatedAt = Tuple.first >> Maybe.unwrap (Time.millisToPosix 0) .updatedAt
                                        , getCreatedAt = Tuple.first >> Maybe.unwrap (Time.millisToPosix 0) .createdAt
                                        , getName = Tuple.second >> .name
                                        , owner = Me
                                        , parent = Nothing
                                        }
                            )
                            >> (if model.sortBy == OwnedByAsc || model.sortBy == OwnedByDesc then
                                    List.map .item

                                else
                                    Sort.sort model.sortBy
                               )
                        )

            else
                ( []
                , sortedFilteredProjects_
                )

        isEmpty : Bool
        isEmpty =
            List.isEmpty projects
                && ((Dict.Any.isEmpty dictFolders || List.isEmpty sortedFilteredFolders) && not isSearching)
    in
    { projects = sortedFilteredProjects_
    , folders = sortedFilteredFolders
    , notShownWhenSearchCount = projectsCount - sortedFilteredProjectsCount
    , emptySearchResult = isSearching && List.isEmpty sortedFilteredProjects && List.isEmpty sortedFilteredFolders
    , isEmpty = isEmpty
    }


viewTitle : Maybe XBFolderId -> XB2.Share.Data.Id.IdDict XBFolderIdTag XBFolder -> String
viewTitle currentFolderId dictFolders =
    currentFolderId
        |> Maybe.andThen (\folderId -> Dict.Any.get folderId dictFolders)
        |> Maybe.unwrap "Crosstabs" .name


resetSearchBtnView : Html Msg
resetSearchBtnView =
    Html.a
        [ WeakCss.nest "reset-search-link" moduleClass
        , Events.onClick <| SearchInputMsg SearchInput.resetSearchField
        ]
        [ Html.text "Reset Search" ]


searchFooterView : ProjectsFoldersViewData -> Model -> Html Msg
searchFooterView viewData model =
    Html.viewIf (not <| String.isEmpty model.searchBarModel.searchTerm) <|
        Html.footer [ WeakCss.nest "search-footer" moduleClass ]
            [ Html.text <| String.fromInt viewData.notShownWhenSearchCount
            , Html.text " Crosstabs not shown based on your search. "
            , resetSearchBtnView
            ]


emptySearchView : String -> Html Msg
emptySearchView searchTerm =
    Html.div [ WeakCss.nest "empty-results" moduleClass ]
        [ Html.div [] [ XB2.Share.Icons.icon [] P2Icons.crosstabFTUE ]
        , Html.p [ WeakCss.nestMany [ "empty-results", "small-text" ] moduleClass ] [ Html.text "Oh no! There are no search results" ]
        , Html.p [ WeakCss.nestMany [ "empty-results", "main-text" ] moduleClass ]
            [ Html.text "We couldn't find any search results for ‘"
            , Html.span [ WeakCss.nestMany [ "empty-results", "main-text", "highlight" ] moduleClass ] [ Html.text searchTerm ]
            , Html.text "’, please try again"
            ]
        ]


folderBreadcrumbsView : XB2.Share.Data.Id.IdDict XBFolderIdTag XBFolder -> XBFolderId -> Html Msg
folderBreadcrumbsView dictFolders folderId =
    Html.div [ WeakCss.nest "folder-breadcrumbs" moduleClass ]
        [ Html.button
            [ WeakCss.nestMany [ "folder-breadcrumbs", "link" ] moduleClass
            , Events.onClick <| SetCurrentFolderId Nothing
            , Attrs.tabindex 0
            ]
            [ Html.text "All Crosstabs" ]
        , XB2.Share.Icons.icon [] P2Icons.chevronRight
        , Html.span [ WeakCss.nestMany [ "folder-breadcrumbs", "current-folder" ] moduleClass ]
            [ Dict.Any.get folderId dictFolders
                |> Maybe.unwrap "Folder" .name
                |> Html.text
            ]
        ]


ftueView : Config msg -> Flags -> Html msg
ftueView config flags =
    let
        cls =
            WeakCss.add "ftue" moduleClass
    in
    Html.div
        [ WeakCss.toClass cls ]
        [ Html.div
            [ WeakCss.nest "top-icon" cls ]
            [ XB2.Share.Icons.icon [] P2Icons.crosstabFTUE ]
        , Html.div
            [ WeakCss.nest "title" cls ]
            [ Html.text "Your saved crosstabs" ]
        , Html.div
            [ WeakCss.nest "message" cls ]
            [ Html.text "All of your past crosstabs now live in one place. Create a new crosstab from scratch or continue working in your saved crosstabs." ]
        , Html.a
            [ WeakCss.nest "create-btn" cls
            , Events.onClickPreventDefaultAndStopPropagation config.createXBProject
            , Attrs.href <|
                XB2.Router.toUrlString
                    (XB2.Router.getPrefix flags)
                    (XB2.Router.Project Nothing)
                    []
            ]
            [ Html.text "Create a crosstab"
            , XB2.Share.Icons.icon [] P2Icons.plusSign
            ]
        ]


fullScrennLoaderView : Config msg -> Model -> Html msg
fullScrennLoaderView { msg } model =
    Html.viewMaybe
        (\{ cellLoaderModel } ->
            case cellLoaderModel.openedCellLoaderModal of
                CrosstabCellLoader.NoCellLoaderModal ->
                    Html.nothing

                CrosstabCellLoader.LoadWithoutProgress ->
                    LoaderWithoutProgressModal.view
                        { cancelMsg = msg CancelFullTableLoad }
                        { className = WeakCss.add "full-table-loading" moduleClass
                        , loadingLabel = "Loading your cells. This may take some time…"
                        }

                CrosstabCellLoader.LoadWithProgress { currentProgress, totalProgress } ->
                    let
                        progressValue : Float
                        progressValue =
                            min 100 (100 / totalProgress * currentProgress)
                    in
                    LoaderWithProgressModal.view
                        { cancelMsg = msg CancelFullTableLoad }
                        { className = WeakCss.add "full-table-loading" moduleClass
                        , loadingLabel = "Cells loaded! Downloading your export…"
                        , progressValue = progressValue
                        }
        )
        model.exportingProject


viewHeaderTabs : Config msg -> Model -> Html msg
viewHeaderTabs config model =
    let
        tabView : Tab -> XB2.Share.Icons.IconData -> Html msg
        tabView tab icon =
            Html.li
                [ WeakCss.addMany [ "tabs", "items", "item" ] moduleClass
                    |> WeakCss.withStates [ ( "active", model.tab == tab ) ]
                ]
                [ Html.button
                    [ WeakCss.nestMany [ "tabs", "items", "item", "link" ] moduleClass
                    , Events.onClick <| config.msg <| SelectTab tab
                    , Attrs.tabindex 0
                    ]
                    [ XB2.Share.Icons.icon [] icon
                    , Html.text <| tabToString tab
                    ]
                ]
    in
    Html.div [ WeakCss.nest "tabs" moduleClass ]
        [ Html.ul [ WeakCss.nestMany [ "tabs", "items" ] moduleClass ]
            [ tabView AllProjects P2Icons.list
            , tabView MyProjects P2Icons.crosstab
            , tabView SharedProjects P2Icons.shared
            ]
        , Html.div
            [ WeakCss.addMany [ "tabs", "underline" ] moduleClass
                |> WeakCss.withActiveStates
                    [ case model.tab of
                        AllProjects ->
                            "position-all"

                        MyProjects ->
                            "position-my"

                        SharedProjects ->
                            "position-shared"
                    ]
            ]
            []
        ]


listView :
    Config msg
    -> Flags
    -> Zone
    -> XB2.Share.Data.Id.IdDict XBProjectIdTag XBProject
    -> XB2.Share.Data.Id.IdDict XBFolderIdTag XBFolder
    -> XBUserSettings
    -> Model
    -> List (Html msg)
listView config flags zone dictProjects dictFolders settings model =
    let
        viewData =
            getProjectsFoldersViewData dictProjects dictFolders model

        shouldShowFTUE : Bool
        shouldShowFTUE =
            not viewData.isEmpty && not settings.xb2ListFTUESeen

        searchInput : Html msg
        searchInput =
            SearchInput.view
                { baseClass = WeakCss.add "navigation" moduleClass
                , placeholder =
                    if isInRoot model.currentFolderId then
                        "Search crosstabs"

                    else
                        "Search your folder"
                , searchInputId = searchCrosstabInputId
                , msg = config.msg << SearchInputMsg
                }
                model.searchBarModel
    in
    [ Html.div [ WeakCss.toClass headerClass ]
        [ Html.div [ WeakCss.nest "inner" headerClass ]
            [ searchInput
            , Html.h1 [ WeakCss.nestMany [ "inner", "title" ] headerClass ] [ Html.text <| viewTitle model.currentFolderId dictFolders ]
            , createBtnView config flags
            ]
        ]
    , Html.div [ WeakCss.nest "sub-title" moduleClass ] [ viewHeaderTabs config model ]
    , Html.map config.msg <| Html.viewMaybe (folderBreadcrumbsView dictFolders) model.currentFolderId
    , Html.viewIfLazy viewData.isEmpty (\() -> emptyView config flags model)
    , Html.viewIfLazy shouldShowFTUE (\() -> ftueView config flags)
    , Html.viewIf (not viewData.isEmpty) <|
        Html.div [ WeakCss.nest "list" moduleClass ] <|
            if viewData.emptySearchResult then
                [ Html.map config.msg <| emptySearchView model.searchBarModel.searchTerm ]

            else
                [ Html.map config.msg <|
                    Html.div [ WeakCss.nestMany [ "list", "header" ] moduleClass ]
                        [ Html.div [ WeakCss.nestMany [ "list", "header", "name-sort" ] moduleClass ]
                            [ sortByView
                                { label = "Name"
                                , asc = NameAsc
                                , desc = NameDesc
                                , currentSorting = model.sortBy
                                , active = model.sortBy == NameAsc || model.sortBy == NameDesc
                                }
                            ]
                        , Html.div [ WeakCss.nestMany [ "list", "header", "owned-sort" ] moduleClass ]
                            [ sortByView
                                { label = "Owned by"
                                , asc = OwnedByAsc
                                , desc = OwnedByDesc
                                , currentSorting = model.sortBy
                                , active = model.sortBy == OwnedByAsc || model.sortBy == OwnedByDesc
                                }
                            ]
                        , Html.div [ WeakCss.nestMany [ "list", "header", "created-sort" ] moduleClass ]
                            [ sortByView
                                { label = "Date created"
                                , asc = CreatedAsc
                                , desc = CreatedDesc
                                , currentSorting = model.sortBy
                                , active = model.sortBy == CreatedAsc || model.sortBy == CreatedDesc
                                }
                            ]
                        , Html.div [ WeakCss.nestMany [ "list", "header", "last-modified-sort" ] moduleClass ]
                            [ sortByView
                                { label = "Last modified"
                                , asc = LastModifiedAsc
                                , desc = LastModifiedDesc
                                , currentSorting = model.sortBy
                                , active = model.sortBy == LastModifiedAsc || model.sortBy == LastModifiedDesc
                                }
                            ]
                        ]
                , listFoldersView config zone viewData.folders model
                , listProjectsView config flags zone dictProjects (not <| Dict.Any.isEmpty dictFolders) model viewData.projects
                , Html.map config.msg <| listGhostView dictProjects model
                , Html.map config.msg <| searchFooterView viewData model
                ]
    , model.activeDropdown
        |> DropdownMenu.view
        |> Html.map config.msg
    , fullScrennLoaderView config model
    ]


searchCrosstabInputId : String
searchCrosstabInputId =
    "search-crosstab-input"


selectionPanelView : Config msg -> Flags -> XBStore.Store -> Model -> Html msg
selectionPanelView config flags { xbProjects, xbFolders } model =
    let
        selectedCount =
            Selection.selectedCount model.selection

        opened =
            Selection.isAnySelected model.selection

        buttonWithDisableMessageView disabledMsg_ disabled btnClass title maybeIcon onClick showDisabledMsg =
            let
                buttonView_ =
                    Html.button
                        [ btnClass |> WeakCss.withStates [ ( "disabled", disabled ) ]
                        , Attrs.disabled disabled
                        , Events.onClick onClick
                        ]
                        [ Html.viewMaybe
                            (\icon -> Html.i [ WeakCss.nest "icon" btnClass ] [ XB2.Share.Icons.icon [] icon ])
                            maybeIcon
                        , Html.text title
                        ]
            in
            P2CoolTip.viewIf (showDisabledMsg && disabled)
                { targetHtml = buttonView_
                , type_ = XB2.Share.CoolTip.RelativeAncestor ("." ++ WeakCss.toString SelectionPanel.panelClass)
                , position = XB2.Share.CoolTip.Top
                , wrapperAttributes = [ WeakCss.nest "tooltip" btnClass ]
                , tooltipText = disabledMsg_
                }

        buttonView =
            buttonWithDisableMessageView "You are not the owner of one or more of the selected projects.\nPlease save your project as new before moving them into a folder."

        deleteButtonView =
            buttonWithDisableMessageView "One or more project are shared with your whole organisation and cannot be removed "
    in
    Html.viewIfLazy opened
        (\_ ->
            RemoteData.map2 Tuple.pair xbProjects xbFolders
                |> RemoteData.map
                    (\( projects, folders ) ->
                        let
                            viewData =
                                getProjectsFoldersViewData projects folders model

                            selectedProjects =
                                List.filter (\{ id } -> Selection.isSelected id model.selection) viewData.projects

                            allSelected =
                                List.length viewData.projects == List.length selectedProjects

                            sharedWithMeCount =
                                List.length <| List.filter (XBData.isSharedWithMe << .shared) selectedProjects

                            someNotMineCrosstabSelected =
                                not <| List.all (XBData.isMine << .shared) selectedProjects

                            someSharedWithMyOrg =
                                List.any (XBData.isSharedWithMyOrg flags << .shared) selectedProjects

                            deleteCopy =
                                if sharedWithMeCount == List.length selectedProjects then
                                    "Remove"

                                else if sharedWithMeCount > 0 then
                                    "Delete & Remove"

                                else
                                    "Delete"

                            hasFolders =
                                not <| Dict.Any.isEmpty folders

                            showMoveOutFolder =
                                not (isInRoot model.currentFolderId)
                        in
                        SelectionPanel.view
                            { selectedCount = selectedCount
                            , opened = opened
                            , clearSelection = config.msg ClearSelection
                            , uselessCheckboxClicked = config.msg NoOp
                            , buttonsGroup1 =
                                \btnClass ->
                                    [ if allSelected then
                                        Html.button
                                            [ WeakCss.toClass btnClass
                                            , Events.onClick <| config.msg ClearSelection
                                            ]
                                            [ Html.text "Deselect all" ]

                                      else
                                        Html.button
                                            [ WeakCss.toClass btnClass
                                            , Events.onClick <| config.msg <| SelectAll viewData.projects
                                            , Attrs.id "modal-list-select-all"
                                            ]
                                            [ Html.text "Select all" ]
                                    ]
                            , buttonsGroup2 =
                                \btnClass ->
                                    [ buttonView
                                        someNotMineCrosstabSelected
                                        (WeakCss.add "action" btnClass)
                                        "Create folder"
                                        (Just P2Icons.group)
                                        (config.msg <| OpenCreateFolderModal selectedProjects)
                                        someNotMineCrosstabSelected
                                    , Html.viewIf showMoveOutFolder <|
                                        buttonView
                                            someNotMineCrosstabSelected
                                            (WeakCss.add "action" btnClass)
                                            "Ungroup"
                                            (Just P2Icons.ungroup)
                                            (config.msg <| OpenMoveProjectsOutOfFolderModal selectedProjects)
                                            someNotMineCrosstabSelected
                                    , Html.viewIf hasFolders <|
                                        buttonView
                                            someNotMineCrosstabSelected
                                            (WeakCss.add "action" btnClass)
                                            "Move to folder"
                                            (Just P2Icons.moveToFolder)
                                            (config.msg <| OpenMoveToFolderModal selectedProjects)
                                            someNotMineCrosstabSelected
                                    , deleteButtonView
                                        someSharedWithMyOrg
                                        (WeakCss.add "delete" btnClass)
                                        deleteCopy
                                        (Just P2Icons.trash)
                                        (config.msg <| OpenConfirmDeleteProjectsModal selectedProjects)
                                        someSharedWithMyOrg
                                    ]
                            }
                    )
                |> RemoteData.withDefault Html.nothing
        )


view : Config msg -> Flags -> Zone -> XBStore.Store -> Model -> Html msg
view config flags zone { xbProjects, xbFolders, userSettings } model =
    let
        data : WebData ( IdDict XBProjectIdTag XBProject, IdDict XBFolderIdTag XBFolder, XBUserSettings )
        data =
            RemoteData.map3 (\projects folders settings -> ( projects, folders, settings ))
                xbProjects
                xbFolders
                userSettings
    in
    Html.main_
        [ WeakCss.withStates [ ( "selection-opened", Selection.isAnySelected model.selection ) ] moduleClass ]
        (case data of
            NotAsked ->
                [ errorView "Data are not loaded." ]

            Loading ->
                [ Spinner.view ]

            Failure f ->
                [ errorView (String.fromHttpError f) ]

            Success ( projects, folders, settings ) ->
                listView config flags zone projects folders settings model
        )
