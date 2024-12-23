module XB2.Share.Gwi.Html.Events exposing
    ( Dimensions
    , Element(..)
    , Position
    , ShiftState
    , TargetWithBodyDimensions
    , onBackspace
    , onClickStopPropagationWithShiftCheck
    , onClickWithBodyDimensions
    , onEsc
    )

import Html exposing (Attribute)
import Html.Events as Events
import Json.Decode as Decode
import Json.Decode.Extra as Decode
import Keyboard
import Keyboard.Events exposing (Event(..))
import Maybe.Extra as Maybe


onEsc : msg -> Attribute msg
onEsc msg =
    onKey Keyboard.Escape msg


onBackspace : msg -> Attribute msg
onBackspace msg =
    onKey Keyboard.Backspace msg


onKey : Keyboard.Key -> msg -> Attribute msg
onKey key msg =
    Keyboard.Events.on Keydown
        [ ( key, msg ) ]


type Element
    = Element
        { parent : Maybe Element
        , nodeName : String
        , clientHeight : Int
        , clientWidth : Int
        }


type OffsetElement
    = OffsetElement
        { parent : Maybe OffsetElement
        , nodeName : String
        , offsetLeft : Float
        , offsetTop : Float
        , scrollTop : Float
        , scrollLeft : Float
        }


type alias Position =
    { x : Float
    , y : Float
    }


type alias Dimensions =
    { width : Float
    , height : Float
    }


parentDecoder : Decode.Decoder Element
parentDecoder =
    Decode.succeed
        (\clientWidth clientHeight nodeName parent ->
            Element
                { parent = parent
                , nodeName = nodeName
                , clientHeight = clientHeight
                , clientWidth = clientWidth
                }
        )
        |> Decode.andMap (Decode.field "clientWidth" Decode.int)
        |> Decode.andMap (Decode.field "clientHeight" Decode.int)
        |> Decode.andMap (Decode.field "nodeName" Decode.string)
        |> Decode.andMap
            (Decode.field "parentElement"
                (Decode.oneOf
                    [ Decode.map Just <| Decode.lazy (\() -> parentDecoder)
                    , Decode.succeed Nothing
                    ]
                )
            )


offsetParentDecoder : Decode.Decoder OffsetElement
offsetParentDecoder =
    let
        pDecoder =
            Decode.oneOf
                [ Decode.map Just <| Decode.lazy (\() -> offsetParentDecoder)
                , Decode.succeed Nothing
                ]
    in
    Decode.succeed
        (\offsetLeft offsetTop scrollTop scrollLeft nodeName parent ->
            OffsetElement
                { parent = parent
                , nodeName = nodeName
                , offsetLeft = Maybe.withDefault 0 offsetLeft
                , offsetTop = Maybe.withDefault 0 offsetTop
                , scrollTop = Maybe.withDefault 0 scrollTop
                , scrollLeft = Maybe.withDefault 0 scrollLeft
                }
        )
        |> Decode.andMap (Decode.optionalField "offsetLeft" Decode.float)
        |> Decode.andMap (Decode.optionalField "offsetTop" Decode.float)
        |> Decode.andMap (Decode.optionalField "scrollTop" Decode.float)
        |> Decode.andMap (Decode.optionalField "scrollLeft" Decode.float)
        |> Decode.andMap (Decode.field "nodeName" Decode.string)
        |> Decode.andMap
            (Decode.oneOf
                [ Decode.field "offsetParent" pDecoder
                , Decode.field "parentNode" pDecoder
                ]
            )


type alias TargetWithBodyDimensions =
    { position : Position, bodyDimensions : Dimensions, target : Element }


onClickWithBodyDimensions : (TargetWithBodyDimensions -> msg) -> Html.Attribute msg
onClickWithBodyDimensions toMsg =
    let
        decoder =
            Decode.map2
                (\target offsetElement ->
                    { target = target
                    , offsetElement = offsetElement
                    }
                )
                (Decode.field "target" parentDecoder)
                (Decode.field "target" offsetParentDecoder)
                |> Decode.map
                    (\result ->
                        let
                            getBodyDimensions_ dimensionsSoFar (Element element) =
                                if String.toUpper element.nodeName == "BODY" then
                                    Just ( toFloat element.clientWidth, toFloat element.clientHeight )

                                else if dimensionsSoFar == Nothing then
                                    Maybe.unwrap dimensionsSoFar (getBodyDimensions_ dimensionsSoFar) element.parent

                                else
                                    dimensionsSoFar

                            getElementOffsetOnPage offsetSoFar (OffsetElement element) =
                                let
                                    accOffset =
                                        Tuple.mapBoth ((+) (element.offsetTop - element.scrollTop)) ((+) (element.offsetLeft - element.scrollLeft)) offsetSoFar
                                in
                                Maybe.unwrap accOffset (getElementOffsetOnPage accOffset) element.parent

                            ( bodyWidth, bodyHeight ) =
                                getBodyDimensions_ Nothing result.target
                                    |> Maybe.withDefault ( 0, 0 )

                            ( y, x ) =
                                getElementOffsetOnPage ( 0, 0 ) result.offsetElement
                        in
                        { position = Position x y
                        , bodyDimensions = Dimensions bodyWidth bodyHeight
                        , target = result.target
                        }
                    )
    in
    Events.stopPropagationOn "click" (Decode.map (\position -> ( toMsg position, True )) decoder)


type alias ShiftState =
    { shiftPressed : Bool }



{- onClickWithShiftCheck : (ShiftState -> msg) -> Html.Attribute msg
   onClickWithShiftCheck action =
       Events.on "click"
           (Decode.field "shiftKey" Decode.bool
               |> Decode.map (\shiftPressed -> action { shiftPressed = shiftPressed })
           )
-}


onClickStopPropagationWithShiftCheck : (ShiftState -> msg) -> Html.Attribute msg
onClickStopPropagationWithShiftCheck action =
    Events.stopPropagationOn "click"
        (Decode.field "shiftKey" Decode.bool
            |> Decode.map (\shiftPressed -> ( action { shiftPressed = shiftPressed }, True ))
        )



{-
   Hack provided by: ♥️ https://dev.to/margaretkrutikova/elm-dom-node-decoder-to-detect-click-outside-3ioh
-}
