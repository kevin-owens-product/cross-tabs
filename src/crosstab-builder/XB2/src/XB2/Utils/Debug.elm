module XB2.Utils.Debug exposing
    ( json
    , jsonWithInternals
    , jsonWithInternalsCheckEncodeDecode
    )

import Json.Decode as Decode
import Json.Encode as Encode


json : String -> Decode.Decoder a -> Decode.Decoder a
json message decoder =
    Decode.value
        |> Decode.andThen (debugHelper message decoder)


debugHelper : String -> Decode.Decoder a -> Encode.Value -> Decode.Decoder a
debugHelper message decoder value =
    let
        _ =
            Debug.log message (Decode.decodeValue decoder value)
    in
    decoder


jsonWithInternals : String -> Decode.Decoder a -> Decode.Decoder a
jsonWithInternals message decoder =
    Decode.value
        |> Decode.andThen (debugHelperWithInternals message decoder)


debugHelperWithInternals : String -> Decode.Decoder a -> Encode.Value -> Decode.Decoder a
debugHelperWithInternals message decoder value =
    let
        _ =
            Debug.log message
                { internals = Encode.encode 0 value
                , result = Decode.decodeValue decoder value
                }
    in
    decoder


jsonWithInternalsCheckEncodeDecode :
    String
    -> (a -> Encode.Value)
    -> Decode.Decoder a
    -> Decode.Decoder a
jsonWithInternalsCheckEncodeDecode message encoder decoder =
    Decode.value
        |> Decode.andThen
            (debugHelperWithInternalsCheckEncodeDecode message decoder encoder)


debugHelperWithInternalsCheckEncodeDecode :
    String
    -> Decode.Decoder a
    -> (a -> Encode.Value)
    -> Encode.Value
    -> Decode.Decoder a
debugHelperWithInternalsCheckEncodeDecode message decoder encoder value =
    let
        _ =
            Debug.log message
                { internals = Encode.encode 0 value
                , result = Decode.decodeValue decoder value
                , valueAfterDecode =
                    case Decode.decodeValue decoder value of
                        Ok decodedValue ->
                            Encode.encode 0 (encoder decodedValue)

                        Err _ ->
                            "It failed"
                }
    in
    decoder
