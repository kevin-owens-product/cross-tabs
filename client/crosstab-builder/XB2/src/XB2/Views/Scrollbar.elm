module XB2.Views.Scrollbar exposing (Config, view)

import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.Events as Events
import Json.Decode exposing (Decoder)
import WeakCss exposing (ClassName)
import XB2.Share.Icons
import XB2.Share.Icons.Platform2 as P2Icons


type alias Config msg =
    { scrollId : String
    , parentClass : ClassName
    , upMsg : msg
    , downMsg : msg
    , leftMsg : msg
    , rightMsg : msg
    , hover : msg
    , stopHovering : msg
    , active : Bool
    , activeScrollLeft : Bool
    , activeScrollTop : Bool
    , hovered : Bool
    , verticalTooltip : String
    , horizontalTooltip : String
    , verticalTooltipNext : String
    , verticalTooltipPrev : String
    , horizontalTooltipNext : String
    , horizontalTooltipPrev : String
    , scrollDecoder : Decoder msg
    }


view : Config msg -> List (Attribute msg) -> List (Html msg) -> List (Html msg) -> Html msg
view config attrs insideTableScroll inner =
    let
        div_ : String -> List (Html msg) -> Html msg
        div_ class children =
            Html.div [ Attrs.class class ] children

        hoverAttrs : List (Attribute msg)
        hoverAttrs =
            [ Events.onMouseEnter config.hover
            , Events.onMouseLeave config.stopHovering
            ]

        button : String -> String -> msg -> Html msg -> Html msg
        button state tooltipContent msg icon =
            Html.button
                [ Events.onClick msg
                , WeakCss.add "table-scroll-button" config.parentClass
                    |> WeakCss.withActiveStates [ state ]
                , Attrs.attribute "tooltip-content" tooltipContent
                , Attrs.attribute "aria-label" "Scroll crosstab"
                ]
                [ icon ]

        tooltip : String -> String -> Html msg
        tooltip state content =
            Html.div
                [ WeakCss.add "table-scroll-tooltip" config.parentClass
                    |> WeakCss.withActiveStates [ state ]
                ]
                [ Html.text content ]

        contentWrapperClass =
            "simplebar-content-wrapper"
    in
    Html.div
        ([ WeakCss.nest "table-scroll" config.parentClass
         , Attrs.classList
            [ ( "inactive", not config.active )
            , ( "hovered", config.hovered )
            , ( "is-scrolling-top", config.activeScrollTop )
            , ( "is-scrolling-left", config.activeScrollLeft )
            ]
         ]
            ++ attrs
        )
        (insideTableScroll
            ++ [ Html.node "x-simplebar"
                    [ Attrs.attribute "scrollable-selector" ("." ++ contentWrapperClass) ]
                    [ Html.div
                        (WeakCss.nest "table-scroll-additions" config.parentClass
                            :: hoverAttrs
                        )
                        [ button "up" config.verticalTooltipPrev config.upMsg <| XB2.Share.Icons.icon [ XB2.Share.Icons.width 7 ] P2Icons.chevronUp
                        , button "down" config.verticalTooltipNext config.downMsg <| XB2.Share.Icons.icon [ XB2.Share.Icons.width 7 ] P2Icons.chevronDown
                        , button "left" config.horizontalTooltipPrev config.leftMsg <| XB2.Share.Icons.icon [ XB2.Share.Icons.width 20 ] P2Icons.chevronLeft
                        , button "right" config.horizontalTooltipNext config.rightMsg <| XB2.Share.Icons.icon [ XB2.Share.Icons.width 20 ] P2Icons.chevronRight
                        ]

                    {- If .simplebar-wrapper already exists, simplebar doesn't create
                       the DOM nodes but instead finds ours and uses them <3
                    -}
                    , div_ "simplebar-wrapper"
                        [ div_ "simplebar-height-auto-observer-wrapper"
                            [ div_ "simplebar-height-auto-observer" [] ]
                        , div_ "simplebar-mask"
                            [ div_ "simplebar-offset"
                                [ Html.div
                                    [ Attrs.class contentWrapperClass
                                    , Attrs.id config.scrollId
                                    , Events.on "scroll" config.scrollDecoder
                                    ]
                                    [ Html.div
                                        (Attrs.class "simplebar-content"
                                            :: attrs
                                        )
                                        inner
                                    ]
                                ]
                            ]
                        , div_ "simplebar-placeholder" []
                        ]
                    , Html.div
                        (Attrs.class "simplebar-track simplebar-horizontal"
                            :: hoverAttrs
                        )
                        [ div_ "simplebar-scrollbar"
                            [ tooltip "horizontal" config.horizontalTooltip ]
                        ]
                    , Html.div
                        (Attrs.class "simplebar-track simplebar-vertical"
                            :: hoverAttrs
                        )
                        [ div_ "simplebar-scrollbar"
                            [ tooltip "vertical" config.verticalTooltip ]
                        ]
                    ]
               ]
        )
