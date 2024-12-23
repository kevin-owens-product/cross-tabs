module XB2.Views.Header exposing (Config, Model, view)

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import Html.Extra as Html
import Maybe.Extra as Maybe
import RemoteData
import Time exposing (Posix, Zone)
import WeakCss exposing (ClassName)
import XB2.Data exposing (XBProject, projectIcon)
import XB2.Data.AudienceCrosstab exposing (AudienceCrosstab)
import XB2.Router
import XB2.Share.Config exposing (Flags)
import XB2.Share.CoolTip
import XB2.Share.CoolTip.Platform2 as P2Cooltip
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons
import XB2.Sharing.Icon as SharingIcon
import XB2.Store as XBStore
import XB2.Utils.NewName as NewName


moduleClass : ClassName
moduleClass =
    WeakCss.namespace "xb2-header"


type alias Config msg =
    { deleteCrosstab : XBProject -> msg
    , duplicateCrosstab : XBProject -> msg
    , navigateTo : XB2.Router.Route -> msg
    , renameCrosstab : XBProject -> msg
    , save : Maybe XBProject -> String -> msg
    , saveAsNew : String -> msg
    , startExport : Maybe XBProject -> msg
    , shareProject : XBProject -> msg
    , shareAndCopyLink : XBProject -> msg
    , closeSharedProjectWarning : msg
    , setSharedProjectWarningDismissal : Bool -> msg
    , noOp : msg
    , undo : msg
    , redo : msg
    , toggleHeaderCollapsed : msg
    }


type alias Model =
    { currentTime : Maybe Posix
    , canProcessExport : Bool
    , isDropdownOpen : Bool
    , isExporting : Bool
    , isUnsaved : Bool
    , zone : Zone
    , wasSharedProjectWarningDismissed : Bool
    , undoDisabled : Bool
    , redoDisabled : Bool
    , crosstabData : AudienceCrosstab
    , isHeaderCollapsed : Bool
    }


exportButton : Config msg -> Maybe XBProject -> Model -> { isCrosstabEmpty : Bool } -> Html msg
exportButton config maybeProject model { isCrosstabEmpty } =
    let
        class =
            WeakCss.nestMany [ "btn", "export" ] moduleClass

        attrs =
            if model.canProcessExport && not model.isExporting then
                [ class, Events.onClick <| config.startExport maybeProject ]

            else
                [ class, Attrs.disabled True ]

        button =
            Html.button
                attrs
                [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.export
                , Html.text
                    (if model.isExporting then
                        "Exporting..."

                     else
                        "Export"
                    )
                ]
    in
    P2Cooltip.viewIf (not model.canProcessExport)
        { targetHtml = button
        , type_ = XB2.Share.CoolTip.Normal
        , position = XB2.Share.CoolTip.BottomLeft
        , wrapperAttributes = [ WeakCss.nest "btn" moduleClass ]
        , tooltipText =
            if isCrosstabEmpty then
                "Add Attributes or Audiences to your Crosstab to export it."

            else
                "Please wait for data to load before exporting"
        }


isSharedWithMe : Maybe XBProject -> Bool
isSharedWithMe maybeProject =
    Maybe.unwrap False (XB2.Data.isSharedWithMe << .shared) maybeProject


view :
    Config msg
    -> Flags
    -> Maybe XBProject
    -> XBStore.Store
    -> { isCrosstabEmpty : Bool }
    -> Model
    -> Html msg
view config flags maybeProject xbStore isEmpty model =
    let
        name : String
        name =
            model.currentTime
                |> Maybe.map
                    (NewName.timeBasedCrosstabName
                        (XBStore.projectNameExists xbStore)
                        model.zone
                    )
                |> Maybe.or (Maybe.map .name maybeProject)
                |> Maybe.withDefault "New Crosstab"

        isSaveBtnEnabled : Bool
        isSaveBtnEnabled =
            model.isUnsaved || isSharedWithMe maybeProject

        isMine : Bool
        isMine =
            Maybe.unwrap False (.shared >> XB2.Data.isMine) maybeProject

        isSharedByLink : Bool
        isSharedByLink =
            Maybe.unwrap False (.shared >> (==) XB2.Data.SharedByLink) maybeProject

        saveBtnLabel : String
        saveBtnLabel =
            if isSharedWithMe maybeProject then
                "Save as copy"

            else
                "Save"

        isDismissCheckboxActive : Bool
        isDismissCheckboxActive =
            xbStore.userSettings
                |> RemoteData.map (not << .canShowSharedProjectWarning)
                -- if not fetched yet, err on the side of making the checkbox unchecked
                |> RemoteData.withDefault False

        projectAction : (XBProject -> msg) -> List (Html.Attribute msg)
        projectAction action =
            case maybeProject of
                Nothing ->
                    [ Attrs.disabled True
                    ]

                Just project ->
                    [ Events.onClick <| action project
                    ]

        renameBtn : XBProject -> Html msg
        renameBtn project =
            let
                canRename =
                    not <| XB2.Data.isSharedWithMe project.shared
            in
            Html.viewIf canRename <|
                Html.button
                    [ WeakCss.nestMany [ "name", "rename-btn" ] moduleClass
                    , Events.onClick <| config.renameCrosstab project
                    , Attrs.attribute "aria-label" "Rename Crosstab"
                    ]
                    [ XB2.Share.Icons.icon [] P2Icons.rename ]

        namePart : Html msg
        namePart =
            case maybeProject of
                Nothing ->
                    Html.text name

                Just project ->
                    Html.div
                        [ WeakCss.nestMany [ "name", "text" ] moduleClass
                        ]
                        [ Html.span
                            [ WeakCss.nestMany [ "name", "text", "content" ] moduleClass ]
                            [ Html.text name ]
                        , renameBtn project
                        ]

        collapsorButton : Html msg
        collapsorButton =
            P2Cooltip.view
                { offset = Nothing
                , type_ = XB2.Share.CoolTip.Normal
                , position = XB2.Share.CoolTip.BottomLeft
                , wrapperAttributes = []
                , targetAttributes = []
                , targetHtml =
                    [ Html.button
                        [ WeakCss.nestMany [ "btn", "collapsor" ] moduleClass
                        , Events.onClick config.toggleHeaderCollapsed
                        , Attrs.attribute "aria-label" "Toggle collapsed header"
                        ]
                        [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 16 ]
                            (if model.isHeaderCollapsed then
                                P2Icons.chevronDown

                             else
                                P2Icons.chevronUp
                            )
                        ]
                    ]
                , tooltipAttributes = []
                , tooltipHtml =
                    if model.isHeaderCollapsed then
                        Html.text "Expand header"

                    else
                        Html.text "Collapse header"
                }

        undoButton : Html msg
        undoButton =
            P2Cooltip.view
                { offset = Nothing
                , type_ = XB2.Share.CoolTip.Normal
                , position = XB2.Share.CoolTip.Bottom
                , wrapperAttributes = []
                , targetAttributes = []
                , targetHtml =
                    [ Html.button
                        [ WeakCss.addMany [ "btn", "undo" ] moduleClass
                            |> WeakCss.withStates [ ( "disabled", model.undoDisabled ) ]
                        , Events.onClick config.undo
                        , Attrs.disabled model.undoDisabled
                        , Attrs.attribute "aria-label" "Undo"
                        ]
                        [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.undo ]
                    ]
                , tooltipAttributes = []
                , tooltipHtml = Html.text "Undo (CTRL / ⌘ Z)"
                }

        redoButton : Html msg
        redoButton =
            P2Cooltip.view
                { offset = Nothing
                , type_ = XB2.Share.CoolTip.Normal
                , position = XB2.Share.CoolTip.BottomLeft
                , wrapperAttributes = []
                , targetAttributes = []
                , targetHtml =
                    [ Html.button
                        [ WeakCss.addMany [ "btn", "redo" ] moduleClass
                            |> WeakCss.withStates [ ( "disabled", model.redoDisabled ) ]
                        , Events.onClick config.redo
                        , Attrs.disabled model.redoDisabled
                        , Attrs.attribute "aria-label" "Redo"
                        ]
                        [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.redo ]
                    ]
                , tooltipAttributes = []
                , tooltipHtml = Html.text "Redo (CTRL Y / Shift ⌘ Z)"
                }

        shareLinkButton : Html msg
        shareLinkButton =
            P2Cooltip.view
                { offset = Nothing
                , type_ = XB2.Share.CoolTip.Normal
                , position = XB2.Share.CoolTip.Bottom
                , wrapperAttributes = []
                , targetAttributes = []
                , targetHtml =
                    [ Html.button
                        (projectAction config.shareAndCopyLink
                            ++ [ WeakCss.nestMany
                                    [ "share-buttons"
                                    , "btn"
                                    , "share-link"
                                    ]
                                    moduleClass
                               , Attrs.attribute "aria-label" "Share Crosstab"
                               ]
                        )
                        [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.link
                        ]
                    ]
                , tooltipAttributes = []
                , tooltipHtml = Html.text "Copy link"
                }
    in
    Html.viewIf (not model.isHeaderCollapsed) <|
        Html.header [ WeakCss.toClass moduleClass ]
            [ Html.div [ WeakCss.nest "left" moduleClass ]
                [ Html.a
                    [ WeakCss.nest "back-btn" moduleClass
                    , Events.onClickPreventDefaultAndStopPropagation <|
                        config.navigateTo XB2.Router.ProjectList
                    , Attrs.href <|
                        XB2.Router.toUrlString
                            (XB2.Router.getPrefix flags)
                            XB2.Router.ProjectList
                            []
                    , Attrs.attribute "aria-label" "Go back"
                    ]
                    [ XB2.Share.Icons.icon
                        [ XB2.Share.Icons.width 32
                        , XB2.Share.Icons.height 32
                        ]
                        P2Icons.arrowLeft
                    ]
                , maybeProject
                    |> Html.viewMaybe
                        (\project ->
                            SharingIcon.view
                                moduleClass
                                { icon = projectIcon project.shared
                                , notSharedIcon = Html.nothing
                                , coolTipPosition = XB2.Share.CoolTip.BottomRight
                                }
                                project
                        )
                , Html.div [ WeakCss.nest "title" moduleClass ]
                    [ Html.h1 [ WeakCss.nest "name" moduleClass ]
                        [ namePart
                        , Html.viewIf (maybeProject == Nothing && model.isUnsaved) <|
                            Html.p
                                [ WeakCss.nest "edited" moduleClass ]
                                [ Html.text "— Unsaved" ]
                        ]
                    ]
                ]
            , Html.aside
                [ WeakCss.nest "right" moduleClass ]
                [ Html.button
                    [ Events.onClick <| config.save maybeProject name
                    , WeakCss.nestMany [ "btn-primary", "save" ] moduleClass
                    , Attrs.disabled <| not isSaveBtnEnabled
                    ]
                    [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.changes
                    , Html.text saveBtnLabel
                    ]
                , Html.viewIf isMine <|
                    Html.button
                        [ Events.onClick <| config.saveAsNew name
                        , WeakCss.nestMany [ "btn", "save-as-new" ] moduleClass
                        ]
                        [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.saveAsNew
                        , Html.text "Save as new"
                        ]
                , Html.viewIf (isMine || isSharedByLink) <|
                    Html.div [ WeakCss.nest "share-buttons" moduleClass ]
                        [ Html.button
                            (projectAction config.shareProject
                                ++ [ WeakCss.nestMany
                                        [ "share-buttons"
                                        , "btn"
                                        , "share"
                                        ]
                                        moduleClass
                                   ]
                            )
                            [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.share
                            , Html.text "Share"
                            ]
                        , Html.div
                            [ WeakCss.nestMany [ "share-buttons", "separator" ]
                                moduleClass
                            ]
                            []
                        , shareLinkButton
                        ]
                , exportButton config maybeProject model isEmpty
                , undoButton
                , redoButton
                , Html.span [ WeakCss.nest "separator" moduleClass ] []
                , collapsorButton
                ]
            , Html.viewIfLazy
                (isSharedWithMe maybeProject
                    && not model.wasSharedProjectWarningDismissed
                )
              <|
                \() -> sharedProjectWarningView config isDismissCheckboxActive
            ]


sharedProjectWarningView : Config msg -> Bool -> Html msg
sharedProjectWarningView config isDismissCheckboxActive =
    let
        clickCheckboxMsg =
            if isDismissCheckboxActive then
                {- currently dismissing -> set dismiss as False
                   = stop dismissing
                   = start showing the warning
                -}
                config.setSharedProjectWarningDismissal False

            else
                {- currently not dismissing -> set dismiss as True
                   = start dismissing
                   = stop showing the warning
                -}
                config.setSharedProjectWarningDismissal True
    in
    Html.div
        [ WeakCss.nest "shared-project-warning" moduleClass ]
        [ Html.div
            [ WeakCss.nestMany [ "shared-project-warning", "heading" ] moduleClass ]
            [ Html.text "Viewing a shared project" ]
        , Html.div
            [ WeakCss.nestMany [ "shared-project-warning", "notice" ] moduleClass ]
            [ Html.text "Any changes you make will only be visible to you. Save your crosstab as a copy in order to apply your changes." ]
        , checkboxView
            config
            (WeakCss.add "shared-project-warning" moduleClass)
            "Don't show again"
            isDismissCheckboxActive
            clickCheckboxMsg
        , Html.button
            [ WeakCss.nestMany [ "shared-project-warning", "close-btn" ] moduleClass
            , Events.onClick config.closeSharedProjectWarning
            , Attrs.attribute "aria-label" "close"
            ]
            [ XB2.Share.Icons.icon [] P2Icons.crossSmall ]
        ]


{-| NOTE: this was copied over from TableView. Perhaps it could be made generic?
Also what about the existing `Checkbox` module?
-}
checkboxView : Config msg -> ClassName -> String -> Bool -> msg -> Html msg
checkboxView config cls label isActive msg =
    -- accessible custom-styled HTML5 checkboxes: <https://codepen.io/michmy/pen/jBQQpp>
    Html.label
        [ WeakCss.nest "checkbox" cls
        , Events.onClick msg
        ]
        [ Html.input
            [ Attrs.type_ "checkbox"
            , Attrs.checked isActive
            , WeakCss.nestMany [ "checkbox", "input" ] cls
            , Events.onClickStopPropagation config.noOp
            ]
            []
        , Html.div
            [ WeakCss.nestMany [ "checkbox", "indicator" ] cls
            ]
            [ Html.i [ WeakCss.nestMany [ "checkbox", "indicator", "icon" ] cls ]
                [ XB2.Share.Icons.icon [] <|
                    if isActive then
                        P2Icons.checkboxFilled

                    else
                        P2Icons.checkboxUnfilled
                ]
            ]
        , Html.div
            [ WeakCss.nestMany [ "checkbox", "label" ] cls
            ]
            [ Html.text label ]
        ]
