port module XB2.Share.Analytics exposing (batch_, track)

import Json.Encode exposing (Value)


port track : ( String, Value ) -> Cmd msg


port batch : List ( String, Value ) -> Cmd msg


batch_ : (event -> ( String, Value )) -> List event -> Cmd msg
batch_ encodeEvent events =
    case events of
        [] ->
            Cmd.none

        [ event ] ->
            track <| encodeEvent event

        _ ->
            batch <| List.map encodeEvent events
