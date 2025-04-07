module Platform2.Modal exposing (HeaderTab, headerWithTabsView)

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import Icons
import Icons.Platform2 as P2Icons
import WeakCss exposing (ClassName)


type alias HeaderTab msg =
    { title : String
    , active : Bool
    , icon : Icons.IconData
    , onClick : Maybe msg
    }


headerWithTabsView : msg -> ClassName -> List (HeaderTab msg) -> Html msg
headerWithTabsView closeModal class headerTabs =
    Html.header
        [ WeakCss.nestMany [ "header-with-tabs" ] class ]
        [ showTabs class headerTabs
        , Html.button
            [ Events.onClickPreventDefault closeModal
            , Attrs.type_ "button"
            , WeakCss.nestMany [ "header-with-tabs", "close" ] class
            , Attrs.attribute "aria-label" "Close modal"
            , Attrs.id "modal-close-header-modal"
            ]
            [ Icons.icon [ Icons.width 32 ] P2Icons.cross ]
        ]


showTabs : ClassName -> List (HeaderTab msg) -> Html msg
showTabs class headerTabs =
    Html.ul
        [ WeakCss.nestMany [ "header-with-tabs", "tabs" ] class ]
    <|
        List.map
            (\{ title, active, icon, onClick } ->
                Html.li
                    [ WeakCss.addMany [ "header-with-tabs", "tabs", "tab" ] class
                        |> WeakCss.withStates [ ( "active", active ), ( "clickable", onClick /= Nothing ) ]
                    , Attrs.attributeMaybe Events.onClick onClick
                    ]
                    [ Html.i [ WeakCss.nestMany [ "header-with-tabs", "tabs", "tab", "icon" ] class ]
                        [ Icons.icon [] icon
                        ]
                    , Html.text title
                    ]
            )
            headerTabs
