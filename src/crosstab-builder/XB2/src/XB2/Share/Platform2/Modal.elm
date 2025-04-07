module XB2.Share.Platform2.Modal exposing (HeaderTab, headerWithTabsView, headerWithTabsViewWithoutX)

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events as Events
import Html.Events.Extra as Events
import WeakCss exposing (ClassName)
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons


type alias HeaderTab msg =
    { title : String
    , active : Bool
    , icon : XB2.Share.Icons.IconData
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
            [ XB2.Share.Icons.icon [ XB2.Share.Icons.width 32 ] P2Icons.cross ]
        ]


headerWithTabsViewWithoutX : ClassName -> List (HeaderTab msg) -> Html msg
headerWithTabsViewWithoutX class headerTabs =
    Html.header
        [ WeakCss.nestMany [ "header-with-tabs" ] class ]
        [ showTabs class headerTabs
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
                        [ XB2.Share.Icons.icon [] icon
                        ]
                    , Html.text title
                    ]
            )
            headerTabs
