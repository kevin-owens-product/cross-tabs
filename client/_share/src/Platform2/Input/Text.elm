module Platform2.Input.Text exposing
    ( view
    , Required
    , Attribute, class, value, limit, onEnter
    )

{-|

@docs view
@docs Required
@docs Attribute, class, value, limit, onEnter

-}

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra exposing (attributeMaybe)
import Html.Events as Events
import Html.Events.Extra as Events
import Html.Extra as Html
import Icons exposing (IconData)
import WeakCss exposing (ClassName)



-- CONFIG


type alias Required msg =
    { onInput : String -> msg
    , placeholder : String
    }


type Attribute msg
    = Attribute (Config msg -> Config msg)


type alias Config msg =
    { class : ClassName
    , value : String
    , id : String
    , limit : Maybe Int
    , placeholder : String
    , icon : Maybe IconData
    , onEnter : Maybe msg
    }


defaultConfig : Config msg
defaultConfig =
    { class = WeakCss.namespace "form-control"
    , value = ""
    , id = ""
    , placeholder = ""
    , limit = Nothing
    , icon = Nothing
    , onEnter = Nothing
    }


class : ClassName -> Attribute msg
class class_ =
    Attribute (\config -> { config | class = class_ })


value : String -> Attribute msg
value value_ =
    Attribute (\config -> { config | value = value_ })


limit : Int -> Attribute msg
limit limit_ =
    Attribute (\config -> { config | limit = Just limit_ })


onEnter : msg -> Attribute msg
onEnter onEnter_ =
    Attribute (\config -> { config | onEnter = Just onEnter_ })



-- VIEW


render : Required msg -> Config msg -> Html msg
render required config =
    Html.div
        [ config.class |> WeakCss.nest "control" ]
        [ Html.viewMaybe
            (\icon_ ->
                Html.div
                    [ config.class |> WeakCss.nest "icon" ]
                    [ Icons.icon [] icon_ ]
            )
            config.icon
        , Html.input
            [ config.class |> WeakCss.nest "input"
            , Events.onInput required.onInput
            , Attrs.placeholder required.placeholder
            , Attrs.value config.value
            , Attrs.id config.id
            , Attrs.autocomplete False
            , Attrs.autofocus True
            , attributeMaybe Events.onEnter config.onEnter
            ]
            []
        , Html.viewMaybe
            (\limit_ ->
                Html.span
                    [ WeakCss.add "char-limit" config.class
                        |> WeakCss.withStates
                            [ ( "reached", String.length config.value >= limit_ - 10 ) ]
                    ]
                    [ Html.text <|
                        String.concat
                            [ String.fromInt (String.length config.value)
                            , "/"
                            , String.fromInt limit_
                            ]
                    ]
            )
            config.limit
        ]


view : Required msg -> List (Attribute msg) -> Html msg
view required attributes =
    attributes
        |> List.foldl (\(Attribute attribute) config -> attribute config) defaultConfig
        |> render required
