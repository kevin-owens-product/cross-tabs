module Data.Core.Error exposing
    ( Error(..)
    , ForbiddenErrorMetadata
    , decoder
    , errorTitle
    , errorToString
    , typeDecoder
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import List.NonEmpty as NonemptyList exposing (NonEmpty)


type
    Error
    -- core-next errors https://github.com/GlobalWebIndex/golib/blob/master/handler/errors.go
    = BadRequest
    | ValidationError
    | InternalServerError
    | ForbiddenError ForbiddenErrorMetadata
    | Unauthorized
    | InvalidToken
    | InconsistentToken
    | JsonEncodeError
    | JsonDecodeError
    | NotFound
      -- gateway errors https://github.com/GlobalWebIndex/gateway/blob/master/pkg/proxy/errors.go
    | GatewayProxyError
    | GatewayTimeout
      -- Fallback
    | UnknownError String


type alias ForbiddenErrorMetadata =
    { questions : Maybe (NonEmpty String)
    , locations : Maybe (NonEmpty String)
    , waves : Maybe (NonEmpty String)
    }


typeDecoder : Decoder String
typeDecoder =
    Decode.field "error_type" Decode.string


forbiddenMetadataErrorDecoder : Decoder ForbiddenErrorMetadata
forbiddenMetadataErrorDecoder =
    Decode.at [ "meta", "forbidden_codes" ]
        (Decode.succeed ForbiddenErrorMetadata
            |> Decode.andMap
                (Decode.optionalField "questions" <|
                    NonemptyList.decodeList <|
                        Decode.field "code" Decode.string
                )
            |> Decode.andMap
                (Decode.optionalField "locations" (NonemptyList.decodeList Decode.string))
            |> Decode.andMap
                (Decode.optionalField "waves" (NonemptyList.decodeList Decode.string))
        )


decoder : Decoder Error
decoder =
    typeDecoder
        |> Decode.andThen
            (\errorType ->
                case errorType of
                    "bad_request" ->
                        Decode.succeed BadRequest

                    "validation_error" ->
                        Decode.succeed ValidationError

                    "internal_server_error" ->
                        Decode.succeed InternalServerError

                    "unauthorized" ->
                        Decode.succeed Unauthorized

                    "invalid_token" ->
                        Decode.succeed InvalidToken

                    "forbidden" ->
                        Decode.map ForbiddenError forbiddenMetadataErrorDecoder

                    "json_encode_error" ->
                        Decode.succeed JsonEncodeError

                    "json_decode_error" ->
                        Decode.succeed JsonDecodeError

                    "not_found" ->
                        Decode.succeed NotFound

                    "proxy_error" ->
                        Decode.succeed GatewayProxyError

                    "timeout" ->
                        Decode.succeed GatewayTimeout

                    "inconsistent_token" ->
                        Decode.succeed InconsistentToken

                    _ ->
                        Decode.succeed <| UnknownError errorType
            )


forbiddenErrorToString : ForbiddenErrorMetadata -> String
forbiddenErrorToString metadata =
    let
        stuff =
            [ ( metadata.questions, "questions" )
            , ( metadata.locations, "locations" )
            , ( metadata.waves, "waves" )
            ]
                |> List.filterMap
                    (\( list, label ) ->
                        Maybe.map
                            (\l ->
                                " for these " ++ label ++ ": " ++ String.join ", " (NonemptyList.toList l)
                            )
                            list
                    )
                |> String.join ", "
    in
    "User permissions are insufficient" ++ stuff ++ "."


errorTitle : Error -> String
errorTitle err =
    case err of
        ForbiddenError _ ->
            "Permissions insufficient to view data"

        _ ->
            errorToString err


errorToString : Error -> String
errorToString err =
    case err of
        BadRequest ->
            "Bad request"

        ValidationError ->
            "Validation error"

        InternalServerError ->
            "Internal server error"

        Unauthorized ->
            "Unauthorized"

        InvalidToken ->
            "Invalid Token"

        InconsistentToken ->
            "Inconsistent Token"

        ForbiddenError metadata ->
            forbiddenErrorToString metadata

        JsonEncodeError ->
            "JSON encode error"

        JsonDecodeError ->
            "JSON decode error"

        NotFound ->
            "Not found"

        GatewayProxyError ->
            "Proxy error"

        GatewayTimeout ->
            "Gateway timeout"

        UnknownError err_ ->
            "Unknown error: " ++ err_
