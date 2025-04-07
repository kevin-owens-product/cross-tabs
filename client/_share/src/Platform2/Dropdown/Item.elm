module Platform2.Dropdown.Item exposing
    ( view
    , Attribute, onClick, class, label, leftIcon
    )

{-|

@docs view
@docs Attribute, onClick, class, label, leftIcon

-}

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs
import Html.Events.Extra as Events
import Html.Extra as Html
import Html.Keyed
import Icons exposing (IconData)
import Icons.Platform2 as P2Icons
import WeakCss exposing (ClassName)



-- CONFIG


type Attribute msg
    = Attribute (Config msg -> Config msg)


type alias Config msg =
    { onClick : Maybe msg
    , class : ClassName
    , label : String
    , sublabel : Maybe String
    , uniqueElementId : String
    , leftIcon : Maybe IconData
    , rightIcon : Maybe IconData
    , selected : Bool
    , disabled : Bool
    , children : List (List (Attribute msg))
    , itemWrapp : Html msg -> Html msg
    , separatorAfterIt : Bool

    -- Working with XB2.DropdownMenu
    , dynamicVerticalOrientation : Bool
    }


defaultConfig : Config msg
defaultConfig =
    { onClick = Nothing
    , class = WeakCss.namespace "dropdown"
    , label = "Option"
    , sublabel = Nothing
    , uniqueElementId = "Option"
    , leftIcon = Nothing
    , rightIcon = Nothing
    , selected = False
    , disabled = False
    , children = []
    , itemWrapp = identity
    , separatorAfterIt = False
    , dynamicVerticalOrientation = False
    }


onClick : msg -> Attribute msg
onClick onClick_ =
    Attribute (\config -> { config | onClick = Just onClick_ })


class : ClassName -> Attribute msg
class class_ =
    Attribute (\config -> { config | class = class_ })


label : String -> Attribute msg
label label_ =
    Attribute (\config -> { config | label = label_ })


leftIcon : IconData -> Attribute msg
leftIcon leftIcon_ =
    Attribute (\config -> { config | leftIcon = Just leftIcon_ })



-- VIEW


leftIconView : Config msg -> Maybe IconData -> Html msg
leftIconView config maybeIcon =
    if config.selected then
        Html.div
            [ config.class |> WeakCss.nestMany [ "item", "left-icon" ] ]
            [ Icons.icon [] P2Icons.tick ]

    else
        case maybeIcon of
            Just icon ->
                Html.div
                    [ config.class |> WeakCss.nestMany [ "item", "left-icon" ] ]
                    [ Icons.icon [ Icons.width 32, Icons.height 32 ] icon ]

            Nothing ->
                Html.nothing


itemView : Config msg -> Html msg
itemView config =
    Html.Keyed.node "div"
        [ config.class
            |> WeakCss.nestMany [ "item", "wrapper" ]
        ]
        [ ( config.uniqueElementId
          , config.itemWrapp <|
                Html.button
                    [ config.class
                        |> WeakCss.add "item"
                        |> WeakCss.withStates
                            [ ( "selected", config.selected )
                            , ( "disabled", config.disabled )
                            ]
                    , Attrs.attributeMaybe Events.onClickStopPropagation config.onClick
                    , Attrs.tabindex 0
                    , Attrs.id "button-item-dropmenu"
                    ]
                    [ leftIconView config config.leftIcon
                    , Html.span
                        [ config.class |> WeakCss.nestMany [ "item", "label" ]

                        -- https://stackoverflow.com/questions/556153/inline-elements-shifting-when-made-bold-on-hover
                        , Attrs.attribute "label" config.label
                        ]
                        [ Html.text config.label ]
                    , Html.viewMaybe
                        (\sublabelText ->
                            Html.span
                                [ config.class |> WeakCss.nestMany [ "item", "sub-label" ] ]
                                [ Html.text sublabelText ]
                        )
                        config.sublabel
                    , Html.viewMaybe
                        (\rightIcon_ ->
                            Html.div
                                [ config.class |> WeakCss.nestMany [ "item", "right-icon" ] ]
                                [ Icons.icon [] rightIcon_ ]
                        )
                        config.rightIcon
                    ]
          )
        , ( config.uniqueElementId ++ "-separator"
          , Html.viewIf config.separatorAfterIt (separator config.class)
          )
        ]


render : Config msg -> Html msg
render config =
    if List.isEmpty config.children then
        itemView config

    else
        Html.div
            [ config.class
                |> WeakCss.add "item"
                |> WeakCss.withActiveStates [ "nested" ]
            ]
            [ itemView config
            , Html.viewIf config.separatorAfterIt (separator config.class)
            , Html.div
                -- This wrapper is needed only because of the little space between parent and child menus,
                -- and we want to keep the hover of the mouse while moving it on no man's land
                [ config.class
                    |> WeakCss.add "item"
                    |> WeakCss.withActiveStates [ "children-wrap" ]
                ]
                [ Html.div
                    [ config.class
                        |> WeakCss.add "item"
                        |> WeakCss.withStates
                            [ ( "children", True )
                            , ( "v-edge", config.dynamicVerticalOrientation )
                            ]
                    ]
                    (List.map view config.children)
                ]
            ]


view : List (Attribute msg) -> Html msg
view attributes =
    attributes
        |> List.foldl (\(Attribute attribute) config -> attribute config) defaultConfig
        |> render


separator : ClassName -> Html msg
separator class_ =
    Html.div [ class_ |> WeakCss.nest "separator" ] []
