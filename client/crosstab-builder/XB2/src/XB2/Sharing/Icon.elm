module XB2.Sharing.Icon exposing (view)

import Html exposing (Html)
import Html.Extra as Html
import List.NonEmpty as NonemptyList
import WeakCss exposing (ClassName)
import XB2.Data as XBData
    exposing
        ( Shared(..)
        , XBProject
        )
import XB2.Share.CoolTip
import XB2.Share.CoolTip.Platform2 as P2CoolTip
import XB2.Share.Icons


view : ClassName -> { icon : XB2.Share.Icons.IconData, notSharedIcon : Html msg, coolTipPosition : XB2.Share.CoolTip.Position } -> XBProject -> Html msg
view moduleClass { icon, notSharedIcon, coolTipPosition } project =
    let
        sharingIconWithTooltip html icon_ =
            P2CoolTip.view
                { offset = Nothing
                , type_ = XB2.Share.CoolTip.Normal
                , position = coolTipPosition
                , wrapperAttributes = [ WeakCss.nestMany [ "name", "sharing-icon", "wrapper" ] moduleClass ]
                , targetAttributes = [ WeakCss.nestMany [ "name", "sharing-icon" ] moduleClass ]
                , targetHtml = [ XB2.Share.Icons.icon [] icon_ ]
                , tooltipAttributes = []
                , tooltipHtml = html
                }
    in
    case project.shared of
        MyPrivateCrosstab ->
            notSharedIcon

        SharedBy owner _ ->
            sharingIconWithTooltip
                (Html.div [] <|
                    (case owner.email of
                        Just email ->
                            [ Html.strong [] [ Html.text "Shared by: " ]
                            , Html.text email
                            ]

                        Nothing ->
                            [ Html.strong [] [ Html.text "Shared by user #" ]
                            , Html.text owner.id
                            ]
                    )
                        ++ [ Html.br [] []
                           , Html.viewIf (not <| String.isEmpty project.sharingNote) <| Html.br [] []
                           , Html.text project.sharingNote
                           ]
                )
                icon

        MySharedCrosstab sharees ->
            let
                isSharedWithOrg =
                    NonemptyList.any XBData.isOrgSharee sharees

                userEmails =
                    sharees
                        |> NonemptyList.toList
                        |> List.filterMap XBData.userShareeEmail

                copy =
                    if isSharedWithOrg then
                        if List.isEmpty userEmails then
                            "Shared with everyone in your organisation and with:\n"
                                ++ String.join "\n" userEmails

                        else
                            "Shared with everyone in your organisation.\n"

                    else
                        "Shared with:\n" ++ String.join "\n" userEmails
            in
            sharingIconWithTooltip
                (Html.text copy)
                icon

        SharedByLink ->
            sharingIconWithTooltip
                (Html.div []
                    [ Html.strong [] [ Html.text "Shared by link" ]
                    ]
                )
                icon
