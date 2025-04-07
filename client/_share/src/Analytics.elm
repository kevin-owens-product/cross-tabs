port module Analytics exposing (track)

import Json.Encode exposing (Value)


port track : ( String, Value ) -> Cmd msg
