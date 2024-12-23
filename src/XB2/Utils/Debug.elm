module XB2.Utils.Debug exposing (json)

import Json.Decode as Decode exposing (Decoder)


json : String -> Decoder a -> Decoder a
json message decoder =
    Decode.value
        |> Decode.andThen (debugHelper message decoder)


debugHelper : String -> Decoder a -> Decode.Value -> Decoder a
debugHelper message decoder value =
    let
        _ =
            Debug.log message (Decode.decodeValue decoder value)
    in
    decoder
