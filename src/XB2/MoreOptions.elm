module XB2.MoreOptions exposing
    ( Config
    , onFolderListView
    , onProjectListView
    )

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Extra as Html
import Maybe.Extra as Maybe
import WeakCss exposing (ClassName)
import XB2.Data as XBData exposing (XBFolder, XBProject, XBProjectId)
import XB2.Share.Config exposing (Flags)
import XB2.Share.Gwi.List as List
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons
import XB2.Share.Platform2.Dropdown.DropdownMenu as DropdownMenu
import XB2.Share.Platform2.Dropdown.Item as DropdownItem


type alias Config msg =
    { confirmDeleteProject : XBProject -> msg
    , duplicateProject : XBProject -> msg
    , renameProject : XBProject -> msg
    , shareProject : XBProject -> msg
    , unshareMe : XBProject -> msg
    , createFolder : List XBProject -> msg
    , moveToFolder : XBProject -> msg
    , renameFolder : XBFolder -> msg
    , openProject : XBProjectId -> msg
    , deleteFolder : XBFolder -> msg
    , ungroupFolder : XBFolder -> msg
    , moveOutOfFolder : XBProject -> msg
    , export : XBProject -> msg
    }


onProjectListView :
    { a
        | confirmDeleteProject : XBProject -> msg
        , duplicateProject : XBProject -> msg
        , renameProject : XBProject -> msg
        , openProject : XBProjectId -> msg
        , shareProject : XBProject -> msg
        , unshareMe : XBProject -> msg
        , createFolder : List XBProject -> msg
        , moveToFolder : XBProject -> msg
        , moveOutOfFolder : XBProject -> msg
        , export : XBProject -> msg
    }
    -> Flags
    ->
        { isDropdownOpen : Bool
        , inRootFolder : Bool
        , areFoldersPresent : Bool
        , dropdownId : String
        , expandOnRight : Bool
        , withDropdownMenu : DropdownMenu.DropdownMenuOptions msg -> Html msg
        }
    -> ClassName
    -> Maybe XBProject
    -> Html msg
onProjectListView config flags { isDropdownOpen, dropdownId, inRootFolder, areFoldersPresent, withDropdownMenu, expandOnRight } moduleClass maybeProject =
    Html.viewMaybe
        (\xbProject ->
            let
                isMine =
                    XBData.isMine xbProject.shared

                isSharedWithMe =
                    XBData.isSharedWithMe xbProject.shared

                isSharedWithMyOrg =
                    XBData.isSharedWithMyOrg flags xbProject.shared

                showSharingBtn =
                    not isSharedWithMe

                dropdownMenuClass =
                    WeakCss.add "menu" moduleClass

                orientation =
                    if expandOnRight then
                        DropdownMenu.RightTop

                    else
                        DropdownMenu.LeftTop

                separator =
                    Html.div [ WeakCss.nest "separator" moduleClass ] []

                topButtons =
                    [ Just <|
                        DropdownItem.view
                            [ DropdownItem.class dropdownMenuClass
                            , DropdownItem.onClick (config.duplicateProject xbProject)
                            , DropdownItem.label "Duplicate"
                            , DropdownItem.id (dropdownId ++ "duplicate")
                            , DropdownItem.leftIcon P2Icons.duplicate
                            ]
                    , if showSharingBtn then
                        Just <|
                            DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.shareProject xbProject)
                                , DropdownItem.label "Share crosstab"
                                , DropdownItem.id (dropdownId ++ "share")
                                , DropdownItem.leftIcon P2Icons.share
                                ]

                      else
                        Nothing
                    , Just <|
                        DropdownItem.view
                            [ DropdownItem.class dropdownMenuClass
                            , DropdownItem.onClick (config.openProject xbProject.id)
                            , DropdownItem.label "Edit"
                            , DropdownItem.id (dropdownId ++ "edit")
                            , DropdownItem.leftIcon P2Icons.edit
                            ]
                    , if isMine then
                        Just <|
                            DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.renameProject xbProject)
                                , DropdownItem.label "Rename"
                                , DropdownItem.id (dropdownId ++ "rename")
                                , DropdownItem.leftIcon P2Icons.rename
                                ]

                      else
                        Nothing
                    ]
                        |> Maybe.values

                middleButtons =
                    [ if inRootFolder && isMine then
                        Just <|
                            DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.createFolder [ xbProject ])
                                , DropdownItem.label "Create folder"
                                , DropdownItem.id (dropdownId ++ "createFolder")
                                , DropdownItem.leftIcon P2Icons.group
                                ]

                      else
                        Nothing
                    , Just <|
                        DropdownItem.view
                            [ DropdownItem.class dropdownMenuClass
                            , DropdownItem.onClick (config.export xbProject)
                            , DropdownItem.label "Export"
                            , DropdownItem.id (dropdownId ++ "export")
                            , DropdownItem.leftIcon P2Icons.export
                            ]
                    , if not inRootFolder && isMine then
                        Just <|
                            DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.moveOutOfFolder xbProject)
                                , DropdownItem.label "Ungroup"
                                , DropdownItem.id (dropdownId ++ "remove-from-folder")
                                , DropdownItem.leftIcon P2Icons.ungroup
                                ]

                      else
                        Nothing
                    , if areFoldersPresent && isMine then
                        Just <|
                            DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.moveToFolder xbProject)
                                , DropdownItem.label "Move to folder"
                                , DropdownItem.id (dropdownId ++ "move-to-folder")
                                , DropdownItem.leftIcon P2Icons.moveToFolder
                                ]

                      else
                        Nothing
                    ]
                        |> Maybe.values

                bottomButtons =
                    [ if isMine then
                        Just <|
                            DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.confirmDeleteProject xbProject)
                                , DropdownItem.label "Delete"
                                , DropdownItem.id (dropdownId ++ "delete")
                                , DropdownItem.leftIcon P2Icons.trash
                                ]

                      else
                        Nothing
                    , if isSharedWithMe && not isSharedWithMyOrg then
                        Just <|
                            DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.unshareMe xbProject)
                                , DropdownItem.label "Remove"
                                , DropdownItem.id (dropdownId ++ "remove")
                                , DropdownItem.leftIcon P2Icons.cross
                                ]

                      else
                        Nothing
                    ]
                        |> Maybe.values

                allButtons =
                    [ topButtons
                    , middleButtons
                    , bottomButtons
                    ]
                        |> List.filter (not << List.isEmpty)

                bottomOffset =
                    allButtons
                        |> List.map List.length
                        |> List.sum
                        |> (*) 40
            in
            withDropdownMenu
                { id = dropdownId
                , orientation = orientation
                , screenBottomEdgeMinOffset = toFloat bottomOffset
                , screenSideEdgeMinOffset = 200
                , controlElementAttrs =
                    [ moduleClass
                        |> WeakCss.addMany [ "trigger-ellipsis" ]
                        |> WeakCss.withStates [ ( "open", isDropdownOpen ) ]
                    , Attrs.attribute "aria-label" "ellipsis-dropdown"
                    , Attrs.id ("icon-ellipsis-id-" ++ dropdownId)
                    ]
                , controlElementContent =
                    [ Html.div
                        [ moduleClass |> WeakCss.nestMany [ "trigger-ellipsis", "icon" ] ]
                        [ XB2.Share.Icons.icon [] P2Icons.ellipsisVertical ]
                    , Html.div
                        [ moduleClass |> WeakCss.nestMany [ "trigger-ellipsis", "icon-circle" ] ]
                        [ XB2.Share.Icons.icon [] P2Icons.ellipsisVerticalCircle ]
                    ]
                , content =
                    Html.div
                        [ moduleClass |> WeakCss.withActiveStates [ "dynamic" ] ]
                        [ Html.div
                            [ WeakCss.toClass dropdownMenuClass ]
                            (allButtons
                                |> List.intersperse (List.singleton separator)
                                |> List.fastConcat
                            )
                        ]
                }
        )
        maybeProject


onFolderListView :
    { a
        | renameFolder : XBFolder -> msg
        , deleteFolder : XBFolder -> msg
        , ungroupFolder : XBFolder -> msg
    }
    ->
        { isDropdownOpen : Bool
        , dropdownId : String
        , expandOnRight : Bool
        , withDropdownMenu : DropdownMenu.DropdownMenuOptions msg -> Html msg
        }
    -> ClassName
    -> Maybe XBFolder
    -> Html msg
onFolderListView config { isDropdownOpen, dropdownId, withDropdownMenu, expandOnRight } moduleClass maybeFolder =
    Html.viewMaybe
        (\xbFolder ->
            let
                dropdownMenuClass =
                    WeakCss.add "menu" moduleClass

                orientation =
                    if expandOnRight then
                        DropdownMenu.RightTop

                    else
                        DropdownMenu.LeftTop
            in
            withDropdownMenu
                { id = dropdownId
                , orientation = orientation
                , screenBottomEdgeMinOffset = 140
                , screenSideEdgeMinOffset = 200
                , controlElementAttrs =
                    [ moduleClass
                        |> WeakCss.addMany [ "trigger-ellipsis" ]
                        |> WeakCss.withStates [ ( "open", isDropdownOpen ) ]
                    , Attrs.attribute "aria-label" "ellipsis-dropdown"
                    , Attrs.id ("icon-ellipsis-id-" ++ dropdownId)
                    ]
                , controlElementContent =
                    [ Html.div
                        [ moduleClass |> WeakCss.nestMany [ "trigger-ellipsis", "icon" ] ]
                        [ XB2.Share.Icons.icon [] P2Icons.ellipsisVertical ]
                    , Html.div
                        [ moduleClass |> WeakCss.nestMany [ "trigger-ellipsis", "icon-circle" ] ]
                        [ XB2.Share.Icons.icon [] P2Icons.ellipsisVerticalCircle ]
                    ]
                , content =
                    Html.div
                        [ moduleClass |> WeakCss.withActiveStates [ "dynamic" ] ]
                        [ Html.div
                            [ WeakCss.toClass dropdownMenuClass ]
                            [ DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.renameFolder xbFolder)
                                , DropdownItem.label "Rename folder"
                                , DropdownItem.id (dropdownId ++ "rename-folder")
                                , DropdownItem.leftIcon P2Icons.rename
                                ]
                            , DropdownItem.separator dropdownMenuClass
                            , DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.ungroupFolder xbFolder)
                                , DropdownItem.label "Ungroup"
                                , DropdownItem.id (dropdownId ++ "ungroup")
                                , DropdownItem.leftIcon P2Icons.ungroup
                                ]
                            , DropdownItem.separator dropdownMenuClass
                            , DropdownItem.view
                                [ DropdownItem.class dropdownMenuClass
                                , DropdownItem.onClick (config.deleteFolder xbFolder)
                                , DropdownItem.label "Delete folder"
                                , DropdownItem.id (dropdownId ++ "delete-folder")
                                , DropdownItem.leftIcon P2Icons.trash
                                ]
                            ]
                        ]
                }
        )
        maybeFolder
