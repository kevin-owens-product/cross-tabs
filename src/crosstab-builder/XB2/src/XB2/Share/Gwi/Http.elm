module XB2.Share.Gwi.Http exposing
    ( Error(..)
    , HttpCmd
    , OtherError(..)
    , UUID
    , cmdMap
    , errorToErrorType
    , errorToString
    , expectErrorAwareJson
    , expectJson
    , expectJsonSeq
    , getCustomError
    , otherErrorTitle
    , otherErrorToString
    , resolveErrorAwareJson
    , toHttpError
    )

{-| Since elm/http 2.0.0 the Http.Error's `BadStatus` constructor no longer carries response body, only statusCode (int).

This makes the plain Http.Error useless for some error-handling use cases
(like decoding json from response body to determine the error cause).

This module works around that by providing Error which carries ALL the available info which can be retrieved from http 2.0.0's Http.Response

-}

import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder)
import Result.Extra as Result
import XB2.Share.Data.Core.Error as CoreError exposing (Error(..))


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
    = XBAvgVsAvgNotSupported
    | XBListCannotMoveProjectSharedWithMe
    | QuestionForAverageNotAvailable
    | XBQuestionDoesntSupportAverages
    | AveragesDataIssue String


type alias UUID =
    String


type alias HttpCmd err a =
    Cmd (Result (Error err) a)


type SuccessDecoder a
    = JsonDecoder (Decoder a)


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


{-| Similar to Http.expectJson, but providing more informative Error value to the callback
-}
expectJson : (Result (Error err) a -> msg) -> Decoder a -> Http.Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg
        (basicResolveResponse (JsonDecoder decoder))


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


jsonSeqResolveResponse : Decoder a -> Http.Response String -> Result (Error err) (List a)
jsonSeqResolveResponse decoder response =
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
            let
                bodyWithoutLeadingLineBreak : String
                bodyWithoutLeadingLineBreak =
                    if String.endsWith "\n" body then
                        String.dropRight 1 body

                    else
                        body

                listOfJsonStrings : List String
                listOfJsonStrings =
                    String.split "\n" bodyWithoutLeadingLineBreak
            in
            List.map (Decode.decodeString decoder) listOfJsonStrings
                |> Result.combine
                |> Result.mapError (\err -> BadBody metadata err)


{-| Similar to Http.expectString, but providing more informative Error value to the
callback. The decoder will be applied to the json elements list returned from the
json-seq.
-}
expectJsonSeq : Decoder a -> Http.Expect (Result (Error err) (List a))
expectJsonSeq decoder =
    Http.expectStringResponse identity
        (jsonSeqResolveResponse decoder)


{-| Looks at `error_type` field and returns Err.
-}
expectErrorAwareJson : Decoder err -> Decoder a -> Http.Expect (Result (Error err) a)
expectErrorAwareJson customErrorDecoder successBodyDecoder =
    Http.expectStringResponse identity
        (resolveResponse customErrorDecoder successBodyDecoder)


resolveErrorAwareJson : Decoder err -> Decoder a -> Http.Resolver (Error err) a
resolveErrorAwareJson customErrorDecoder successBodyDecoder =
    Http.stringResolver (resolveResponse customErrorDecoder successBodyDecoder)


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


getCustomError : Error customError -> Maybe customError
getCustomError error =
    case error of
        BadUrl _ ->
            Nothing

        Timeout ->
            Nothing

        NetworkError ->
            Nothing

        BadStatus _ _ ->
            Nothing

        BadBody _ _ ->
            Nothing

        GenericError _ _ _ ->
            Nothing

        CustomError _ _ customError ->
            Just customError

        OtherError _ ->
            Nothing


otherErrorToString : OtherError -> String
otherErrorToString otherError =
    case otherError of
        XBAvgVsAvgNotSupported ->
            "Two average values cannot be compared against each other"

        QuestionForAverageNotAvailable ->
            "Question for average was not available"

        XBListCannotMoveProjectSharedWithMe ->
            "Please duplicate your project before moving it into a folder."

        XBQuestionDoesntSupportAverages ->
            "This question does not support averages"

        AveragesDataIssue info ->
            "This question has incorrectly defined averages: " ++ info


errorToErrorType : (err -> String) -> Error err -> String
errorToErrorType customErrorToErrorType err =
    case err of
        BadUrl _ ->
            "bad_url"

        Timeout ->
            "timeout"

        NetworkError ->
            "network_error"

        BadStatus _ _ ->
            "bad_status"

        BadBody _ _ ->
            "bad_body"

        GenericError _ _ genericErr ->
            case genericErr of
                BadRequest ->
                    "bad_request"

                ValidationError ->
                    "validation_error"

                InternalServerError ->
                    "internal_server_error"

                Unauthorized ->
                    "unauthorized"

                InvalidToken ->
                    "invalid_token"

                InconsistentToken ->
                    "inconsistent_token"

                ForbiddenError _ ->
                    "forbidden"

                JsonEncodeError ->
                    "json_encode_error"

                JsonDecodeError ->
                    "json_decode_error"

                NotFound ->
                    "not_found"

                GatewayProxyError ->
                    "proxy_error"

                GatewayTimeout ->
                    "timeout"

                UnknownError unknownError ->
                    unknownError

        CustomError _ _ customErr ->
            customErrorToErrorType customErr

        OtherError otherErr ->
            case otherErr of
                XBAvgVsAvgNotSupported ->
                    "xb_avg_vs_avg_not_supported"

                QuestionForAverageNotAvailable ->
                    "question_for_avergae_not_available"

                XBListCannotMoveProjectSharedWithMe ->
                    "xb_list_cannot_move_project_shared_with_me"

                XBQuestionDoesntSupportAverages ->
                    "xb_question_doesnt_support_averages"

                AveragesDataIssue _ ->
                    "xb_averages_data_issue"


otherErrorTitle : OtherError -> String
otherErrorTitle otherErr =
    case otherErr of
        XBAvgVsAvgNotSupported ->
            "Error"

        QuestionForAverageNotAvailable ->
            "Error"

        XBListCannotMoveProjectSharedWithMe ->
            "Shared Project Permissions"

        XBQuestionDoesntSupportAverages ->
            "Averages not supported"

        AveragesDataIssue _ ->
            "Averages error"


cmdMap : (a -> b) -> HttpCmd err a -> HttpCmd err b
cmdMap f =
    Cmd.map (Result.map f)
