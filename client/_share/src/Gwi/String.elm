module Gwi.String exposing (fromHttpError)

import Http


fromHttpError : Http.Error -> String
fromHttpError err =
    -- TODO this should probably live in `Gwi.Http.errorToString`
    case err of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus code ->
            "Bad status code: " ++ String.fromInt code

        Http.BadBody decodeError ->
            "Bad payload (JSON decoding error): " ++ decodeError
