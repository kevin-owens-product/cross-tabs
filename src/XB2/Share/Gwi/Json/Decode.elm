module XB2.Share.Gwi.Json.Decode exposing
    ( emptyObject
    , emptyStringAsNullWith
    , escDecoder
    , intToString
    , stringOrInt
    , unixIso8601Decoder
    )

import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Maybe.Extra as Maybe
import Parser
import Time exposing (Posix)


intToString : Decoder String
intToString =
    Decode.map String.fromInt Decode.int


stringToInt : Decoder Int
stringToInt =
    Decode.andThen (Decode.fromMaybe "Couldn't parse int" << String.toInt) Decode.string


stringOrInt : Decoder Int
stringOrInt =
    Decode.oneOf
        [ Decode.int
        , stringToInt
        ]


unixIso8601Decoder : Decoder Posix
unixIso8601Decoder =
    Decode.string
        |> Decode.andThen
            (Iso8601.toTime
                >> Result.mapError Parser.deadEndsToString
                >> Decode.fromResult
            )


emptyStringAsNull : Decoder (Maybe String)
emptyStringAsNull =
    Decode.string
        |> Decode.nullable
        |> Decode.map (Maybe.filter (not << String.isEmpty))


emptyStringAsNullWith : (String -> a) -> Decoder (Maybe a)
emptyStringAsNullWith convert =
    emptyStringAsNull
        |> Decode.map (Maybe.map convert)


emptyObject : Decoder ()
emptyObject =
    Decode.keyValuePairs (Decode.succeed ())
        |> Decode.andThen
            (\fields ->
                if List.isEmpty fields then
                    Decode.succeed ()

                else
                    Decode.fail "object was not empty"
            )


escDecoder : msg -> Decoder msg
escDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                case key of
                    "Escape" ->
                        Decode.succeed msg

                    _ ->
                        Decode.fail "Not the key we're interested in"
            )
