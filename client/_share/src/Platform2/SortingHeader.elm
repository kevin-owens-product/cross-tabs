module Platform2.SortingHeader exposing
    ( Config
    , Direction(..)
    , view
    )

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Events.Extra as Events
import Icons
import Icons.Platform2 as P2Icons
import WeakCss exposing (ClassName)


type Direction
    = Asc
    | Desc
    | Off


type alias Config msg =
    { baseClass : ClassName
    , stateClasses : List String
    , label : String
    , setDirection : Direction -> msg
    , direction : Direction
    }


cycleDirection : Direction -> Direction
cycleDirection direction =
    case direction of
        Asc ->
            Desc

        Desc ->
            Off

        Off ->
            Asc


view : Config msg -> Html msg
view { baseClass, stateClasses, label, setDirection, direction } =
    let
        arrowsClass =
            WeakCss.add "arrows" baseClass
    in
    Html.div
        [ baseClass
            |> WeakCss.withActiveStates stateClasses
        ]
        [ Html.button
            [ WeakCss.nest "label" baseClass
            , Events.onClickStopPropagation (setDirection (cycleDirection direction))
            , Attrs.tabindex 0
            ]
            [ Html.text label ]
        , Html.div
            [ WeakCss.toClass arrowsClass ]
            [ Html.div
                [ Events.onClickStopPropagation (setDirection Asc)
                , WeakCss.add "up" arrowsClass
                    |> WeakCss.withStates [ ( "active", direction == Asc ) ]
                ]
                [ Icons.icon
                    []
                    P2Icons.chevronUp
                ]
            , Html.div
                [ Events.onClickStopPropagation (setDirection Desc)
                , WeakCss.add "down" arrowsClass
                    |> WeakCss.withStates [ ( "active", direction == Desc ) ]
                ]
                [ Icons.icon
                    []
                    P2Icons.chevronDown
                ]
            ]
        ]
