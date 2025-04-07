module Gwi.Json.Decode exposing
    ( intToString
    , stringOrInt
    , unixIso8601Decoder
    , unixTimestampSeconds
    )

import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
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


unixTimestampSeconds : Decoder Posix
unixTimestampSeconds =
    Decode.int |> Decode.map (Time.millisToPosix << (*) 1000)


unixIso8601Decoder : Decoder Posix
unixIso8601Decoder =
    Decode.string
        |> Decode.andThen
            (Iso8601.toTime
                >> Result.mapError Parser.deadEndsToString
                >> Decode.fromResult
            )
