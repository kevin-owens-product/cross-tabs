module XB2.Views.SelectionPanel exposing (Config, panelClass, view)

import Html exposing (Html)
import Html.Events as Events
import WeakCss exposing (ClassName)
import XB2.Detail.Common as Common
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons


panelClass : ClassName
panelClass =
    WeakCss.add "selection-panel" Common.moduleClass


type alias Config msg =
    { selectedCount : Int
    , opened : Bool
    , clearSelection : msg
    , uselessCheckboxClicked : msg
    , buttonsGroup1 : ClassName -> List (Html msg)
    , buttonsGroup2 : ClassName -> List (Html msg)
    }


view : Config msg -> Html msg
view config =
    let
        btnClass =
            WeakCss.add "control-btn" panelClass
    in
    Html.div
        [ WeakCss.withStates [ ( "opened", config.opened ) ] panelClass
        ]
        [ Html.span [ WeakCss.nest "counter" panelClass ]
            [ Html.span
                [ WeakCss.nestMany [ "counter", "checkbox" ] panelClass
                , Events.onClick config.uselessCheckboxClicked
                ]
                [ XB2.Share.Icons.icon [] P2Icons.checkboxFilled ]
            , Html.text (String.fromInt config.selectedCount)
            , Html.text " Selected"
            ]
        , Html.div [ WeakCss.nest "control-buttons" panelClass ]
            [ Html.div [ WeakCss.nestMany [ "control-buttons", "group1" ] panelClass ] <| config.buttonsGroup1 btnClass
            , Html.div [ WeakCss.nestMany [ "control-buttons", "group2" ] panelClass ] <| config.buttonsGroup2 btnClass
            , Html.button
                [ WeakCss.nest "close" btnClass
                , Events.onClick config.clearSelection
                ]
                [ XB2.Share.Icons.icon [] P2Icons.cross ]
            ]
        ]
