module XB2.Share.Modal.CheckboxItemView exposing (view)

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Events as Events
import Html.Extra as Html
import WeakCss exposing (ClassName)
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons


view : { config | getInfo : item -> Maybe String, getName : item -> String, toggleItem : item -> msg } -> ClassName -> Bool -> item -> Html msg
view config className isSelected item =
    let
        icon =
            if isSelected then
                P2Icons.checkboxFilled

            else
                P2Icons.checkboxUnfilled
    in
    Html.div [ WeakCss.nest "item" className ]
        [ Html.label [ WeakCss.nestMany [ "item", "label" ] className ]
            [ Html.div [ WeakCss.nestMany [ "item", "label", "name-icon" ] className ]
                [ Html.input
                    [ WeakCss.nestMany [ "item", "label", "input" ] className
                    , Attrs.checked isSelected
                    , Attrs.type_ "checkbox"
                    , Events.onClick <| config.toggleItem item
                    ]
                    []
                , Html.span
                    [ WeakCss.nestMany [ "item", "label", "checkbox" ] className
                    ]
                    [ XB2.Share.Icons.icon [] icon
                    ]
                , Html.div
                    [ WeakCss.addMany [ "item", "name" ] className
                        |> WeakCss.withStates [ ( "selected", isSelected ) ]
                    ]
                    [ Html.text <| config.getName item ]
                ]
            , config.getInfo item
                |> Html.viewMaybe (Html.div [ WeakCss.nestMany [ "item", "info" ] className ] << List.singleton << Html.text)
            ]
        ]
