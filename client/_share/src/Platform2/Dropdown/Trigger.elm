module Platform2.Dropdown.Trigger exposing
    ( buttonView
    , Required
    , Attribute, class, label, disabled
    , RequiredWithBodyFence, color
    )

{-|

@docs buttonView
@docs Required
@docs Attribute, class, label, disabled

-}

import Gwi.Html.Events as Events
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs_
import Html.Extra as Html
import Icons exposing (IconData)
import WeakCss exposing (ClassName)



-- CONFIG


type alias Required msg =
    { onClick : msg
    , open : Bool
    , activeIconClass : Maybe String
    , openedIcon : IconData
    , closedIcon : IconData
    }


type alias RequiredWithBodyFence msg =
    { onClick : Events.TargetWithBodyDimensions -> msg
    , open : Bool
    , activeIconClass : Maybe String
    , openedIcon : IconData
    , closedIcon : IconData
    }


type Attribute msg
    = Attribute (Config msg -> Config msg)


type alias Config msg =
    { class : ClassName
    , label : Html msg
    , sublabel : Maybe String
    , leftIcon : Maybe IconData
    , disabled : Bool
    , color : Maybe String
    }


defaultConfig : Config msg
defaultConfig =
    { class = WeakCss.namespace "dropdown"
    , label = Html.nothing
    , sublabel = Nothing
    , leftIcon = Nothing
    , disabled = False
    , color = Nothing
    }


class : ClassName -> Attribute msg
class class_ =
    Attribute (\config -> { config | class = class_ })


label : Html msg -> Attribute msg
label label_ =
    Attribute (\config -> { config | label = label_ })


disabled : Bool -> Attribute msg
disabled disabled_ =
    Attribute (\config -> { config | disabled = disabled_ })


color : String -> Attribute msg
color c =
    Attribute (\config -> { config | color = Just c })



-- VIEW


renderButton : RequiredWithBodyFence msg -> Config msg -> Html msg
renderButton required config =
    Html.button
        [ config.class
            |> WeakCss.add "trigger-button"
            |> WeakCss.withStates [ ( "open", required.open ), ( "disabled", config.disabled ) ]
        , Attrs.disabled config.disabled
        , Events.onClickWithBodyDimensions required.onClick
        , Attrs_.attributeMaybe (Attrs.style "background-color") config.color
        ]
        [ Html.viewMaybe
            (\leftIcon_ ->
                Html.div
                    [ config.class |> WeakCss.nestMany [ "trigger-button", "left-icon" ] ]
                    [ Icons.icon [] leftIcon_ ]
            )
            config.leftIcon
        , Html.span
            [ WeakCss.nestMany [ "trigger-button", "label" ] config.class ]
            [ config.label ]
        , Html.viewMaybe
            (\sublabel_ ->
                Html.span
                    [ config.class |> WeakCss.nestMany [ "trigger-button", "sublabel" ] ]
                    [ Html.text sublabel_ ]
            )
            config.sublabel
        , Html.div
            [ config.class |> WeakCss.nestMany [ "trigger-button", "right-icon" ]
            , Attrs_.attributeIf required.open <|
                Attrs.class <|
                    Maybe.withDefault "" required.activeIconClass
            ]
            [ Icons.icon []
                (if required.open then
                    required.openedIcon

                 else
                    required.closedIcon
                )
            ]
        ]


buttonWithBodyFenceView : RequiredWithBodyFence msg -> List (Attribute msg) -> Html msg
buttonWithBodyFenceView required attributes =
    attributes
        |> List.foldl (\(Attribute attribute) config -> attribute config) defaultConfig
        |> renderButton required


buttonView : Required msg -> List (Attribute msg) -> Html msg
buttonView required =
    buttonWithBodyFenceView
        { onClick = \_ -> required.onClick
        , open = required.open
        , activeIconClass = required.activeIconClass
        , openedIcon = required.openedIcon
        , closedIcon = required.closedIcon
        }
