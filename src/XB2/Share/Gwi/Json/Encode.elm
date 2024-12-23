module XB2.Share.Gwi.Json.Encode exposing (encodeStringAsInt)

import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as Encode


encodeStringAsInt : String -> Value
encodeStringAsInt value =
    Encode.maybe
        Encode.int
        (String.toInt value)
