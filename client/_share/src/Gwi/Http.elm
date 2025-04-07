module Gwi.Http exposing
    ( Error(..)
    , HttpCmd
    , OtherError(..)
    , UUID
    , errorToString
    , expectErrorAwareJson
    , expectJson
    , expectWhatever
    , fromHttpError
    , otherErrorTitle
    , otherErrorToString
    , toHttpError
    )

{-| Since elm/http 2.0.0 the Http.Error's `BadStatus` constructor no longer carries response body, only statusCode (int).

This makes the plain Http.Error useless for some error-handling use cases
(like decoding json from response body to determine the error cause).

This module works around that by providing Error which carries ALL the available info which can be retrieved from http 2.0.0's Http.Response

-}

import Data.Core.Error as CoreError exposing (Error(..))
import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| This type holds the same data as `Http.Response` with 2 differences:

1.  It does not have GoodStatus\_ (that belongs to `Ok` part of `Result Error a`)
2.  It has extra BadBody constructor for json decoding errors

In comparison with `Http.Error` it carries `Http.Metadata` in `BadStatus` and `BadBody` constructors.

-}
type Error err
    = -- elm/http errors
      BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata String
    | BadBody Http.Metadata Decode.Error
      -- core-next and gateway errors
    | GenericError UUID String CoreError.Error
      -- Extension point for component specific errors (TV, Chart builder etc.)
    | CustomError UUID String err
      -- Miscellania
    | OtherError OtherError


type OtherError
    = TVNoChannelsInPlan


type alias UUID =
    String


type alias HttpCmd err a =
    Cmd (Result (Error err) a)


type SuccessDecoder a
    = JsonDecoder (Decoder a)
    | Whatever a


basicResolveResponse : SuccessDecoder a -> Http.Response String -> Result (Error err) a
basicResolveResponse successDecoder response =
    case response of
        Http.BadUrl_ e ->
            Err <| BadUrl e

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            Err <| BadStatus metadata body

        Http.GoodStatus_ metadata body ->
            case successDecoder of
                JsonDecoder decoder ->
                    Decode.decodeString decoder body
                        |> Result.mapError (BadBody metadata)

                Whatever a ->
                    Ok a


{-| Similar to Http.expectJson, but providing more informative Error value to the callback
-}
expectJson : (Result (Error err) a -> msg) -> Decoder a -> Http.Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg
        (basicResolveResponse (JsonDecoder decoder))


{-| Similar to Http.expectWhatever, but providing more informative Error value to the callback
-}
expectWhatever : (Result (Error err) () -> msg) -> Http.Expect msg
expectWhatever toMsg =
    Http.expectStringResponse toMsg
        (basicResolveResponse (Whatever ()))


resolveResponse : Decoder err -> Decoder a -> Http.Response String -> Result (Error err) a
resolveResponse customErrorDecoder successBodyDecoder response =
    case response of
        Http.BadUrl_ e ->
            Err <| BadUrl e

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            case Decode.decodeString (errorDecoder metadata.headers body customErrorDecoder) body of
                Ok err ->
                    Err err

                Err _ ->
                    Err <| BadStatus metadata body

        Http.GoodStatus_ metadata body ->
            let
                {- `DELETE qb_projects` endpoint was giving us troubles, as
                   - in case of error it returned {error_type: ...} and
                   - in case of success the response was empty.

                   `Decode.decodeString (Decode.succeed ()) ""`
                   fails, but we need it to return `Ok ()`.
                   So we work around it with this `sanitizedBody`.
                -}
                sanitizedBody =
                    if String.isEmpty body then
                        "null"

                    else
                        body
            in
            Decode.decodeString successBodyDecoder sanitizedBody
                |> Result.mapError (BadBody metadata)


{-| Looks at `error_type` field and returns Err.
-}
expectErrorAwareJson : Decoder err -> Decoder a -> Http.Expect (Result (Error err) a)
expectErrorAwareJson customErrorDecoder successBodyDecoder =
    Http.expectStringResponse identity
        (resolveResponse customErrorDecoder successBodyDecoder)


errorDecoder : Dict String String -> String -> Decoder err -> Decoder (Error err)
errorDecoder headers body customErrorDecoder =
    let
        uuid =
            headers
                |> Dict.get "x-gateway-uuid"
                |> Maybe.withDefault "missing"
    in
    Decode.oneOf
        [ Decode.map (CustomError uuid body) customErrorDecoder
        , Decode.map (GenericError uuid body) CoreError.decoder
        ]


{-| Note this is not at all 1:1
-}
fromHttpError : Http.Error -> Error Never
fromHttpError error =
    case error of
        Http.BadUrl url ->
            BadUrl url

        Http.Timeout ->
            Timeout

        Http.NetworkError ->
            NetworkError

        Http.BadStatus status ->
            BadStatus { emptyMetadata | statusCode = status } (String.fromInt status)

        Http.BadBody decodeError ->
            BadBody emptyMetadata
                (Decode.Failure
                    decodeError
                    (Encode.string "<VALUE LOST IN CONVERSION FROM Http.Error>")
                )


toHttpError : (err -> Http.Error) -> Error err -> Http.Error
toHttpError customErrorToHttpError error =
    case error of
        BadUrl url ->
            Http.BadUrl url

        Timeout ->
            Http.Timeout

        NetworkError ->
            Http.NetworkError

        BadStatus metadata _ ->
            Http.BadStatus metadata.statusCode

        BadBody _ decodeError ->
            Http.BadBody <| Decode.errorToString decodeError

        GenericError _ _ genericError ->
            genericErrorToHttpError genericError

        CustomError _ _ customError ->
            customErrorToHttpError customError

        OtherError otherError ->
            -- ¯\_(ツ)_/¯
            Http.BadBody <| otherErrorToString otherError


genericErrorToHttpError : CoreError.Error -> Http.Error
genericErrorToHttpError err =
    let
        badRequest =
            400

        forbidden =
            403

        internalServerError =
            500
    in
    Http.BadStatus <|
        case err of
            BadRequest ->
                badRequest

            ValidationError ->
                badRequest

            InternalServerError ->
                internalServerError

            Unauthorized ->
                401

            InvalidToken ->
                forbidden

            InconsistentToken ->
                forbidden

            JsonEncodeError ->
                internalServerError

            JsonDecodeError ->
                internalServerError

            NotFound ->
                404

            ForbiddenError _ ->
                forbidden

            GatewayProxyError ->
                internalServerError

            GatewayTimeout ->
                504

            UnknownError _ ->
                internalServerError


errorToString : (customError -> String) -> Error customError -> String
errorToString customErrorToString error =
    case error of
        BadUrl string ->
            "Bad URL: " ++ string

        Timeout ->
            "Your calculation request has timed out"

        NetworkError ->
            "Network error"

        BadStatus _ string ->
            "Bad status: " ++ string

        BadBody _ decodeError ->
            "Bad body: " ++ Decode.errorToString decodeError

        GenericError _ _ genericError ->
            CoreError.errorToString genericError

        CustomError _ _ customError ->
            customErrorToString customError

        OtherError otherError ->
            otherErrorToString otherError


otherErrorToString : OtherError -> String
otherErrorToString otherError =
    case otherError of
        TVNoChannelsInPlan ->
            "No channels in the plan"


otherErrorTitle : OtherError -> String
otherErrorTitle otherErr =
    case otherErr of
        TVNoChannelsInPlan ->
            "Error"


emptyMetadata : Http.Metadata
emptyMetadata =
    { url = ""
    , statusCode = 0
    , statusText = ""
    , headers = Dict.empty
    }
