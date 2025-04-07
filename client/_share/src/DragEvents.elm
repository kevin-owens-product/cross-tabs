port module DragEvents exposing
    ( dragstart
    , onDragEnd
    , onDragEnter
    , onDragLeave
    , onDragOver
    , onDragStart
    , onDrop
    )

{-| Events for Html5 drag and drop. This module is not used in P2.
-}

import Html exposing (Attribute)
import Html.Events as Events
import Json.Decode as Decode



-- Because of Firefox we need do some aditional magic with event.dataTransfer.setData


port dragstart : Decode.Value -> Cmd msg


onDragStart : (Decode.Value -> msg) -> Attribute msg
onDragStart message =
    let
        decoder =
            Decode.map message Decode.value
    in
    Events.stopPropagationOn
        "dragstart"
        (Decode.map (\msg -> ( msg, True )) decoder)


onDragEnd : msg -> Attribute msg
onDragEnd message =
    onDragHandler "dragend" message


onDragEnter : msg -> Attribute msg
onDragEnter message =
    onPreventHandler "dragenter" message


onDragOver : msg -> Attribute msg
onDragOver message =
    onPreventHandler "dragover" message


onDragLeave : msg -> Attribute msg
onDragLeave message =
    onPreventHandler "dragleave" message


onDrop : msg -> Attribute msg
onDrop message =
    onPreventHandler "drop" message


onDragHandler : String -> msg -> Attribute msg
onDragHandler eventName message =
    Events.on
        eventName
        (Decode.succeed message)


onPreventHandler : String -> msg -> Attribute msg
onPreventHandler eventName message =
    Events.preventDefaultOn
        eventName
        (Decode.succeed ( message, True ))
