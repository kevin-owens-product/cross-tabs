module XB2.Share.Export exposing
    ( ExportError(..)
    , ExportResponse(..)
    , exportErrorDecoder
    , exportErrorDisplay
    , stringDownload
    , urlDownload
    )

import File.Download
import Html
import Json.Decode as Decode exposing (Decoder)
import XB2.Share.Data.Core.Error as CoreError
import XB2.Share.Dialog.ErrorDisplay exposing (ErrorDisplay)


urlDownload : String -> Cmd msg
urlDownload url =
    File.Download.url url


stringDownload : { filename : String, mimeType : String, contents : String } -> Cmd msg
stringDownload { filename, mimeType, contents } =
    File.Download.string filename mimeType contents



-- Types


type ExportError
    = AuthTokenParseError
    | QueryingDataError
    | ProcessingError
    | CurrentUserQueryError
    | EmailSendError
    | ResultsMissing


type ExportResponse
    = Mail { message : String }
    | DirectDownload { downloadUrl : String }


exportErrorDecoder : Decoder ExportError
exportErrorDecoder =
    CoreError.typeDecoder
        |> Decode.andThen
            (\errorType ->
                case errorType of
                    "auth_token_parse_error" ->
                        Decode.succeed AuthTokenParseError

                    "quering_data_error" ->
                        Decode.succeed QueryingDataError

                    "processing_error" ->
                        Decode.succeed ProcessingError

                    "current_user_query_error" ->
                        Decode.succeed CurrentUserQueryError

                    "email_send_error" ->
                        Decode.succeed EmailSendError

                    "results_missing_error" ->
                        Decode.succeed ResultsMissing

                    _ ->
                        Decode.fail <| "Failed to determine ExportError from error_type: " ++ errorType
            )


exportErrorDisplay : ExportError -> ErrorDisplay msg
exportErrorDisplay err =
    case err of
        AuthTokenParseError ->
            { title = "Auth token parsing error"
            , body = Html.text "There was an error parsing your auth token"
            , details = []
            , errorId = Nothing
            }

        QueryingDataError ->
            { title = "Querying data error"
            , body = Html.text "There was an error querying the data"
            , details = []
            , errorId = Nothing
            }

        ProcessingError ->
            { title = "Processing error"
            , body = Html.text "There was a processing error"
            , details = []
            , errorId = Nothing
            }

        CurrentUserQueryError ->
            { title = "Current user query error"
            , body = Html.text "There was an error querying current_user"
            , details = []
            , errorId = Nothing
            }

        EmailSendError ->
            { title = "Email send error"
            , body = Html.text "There was an error sending email"
            , details = []
            , errorId = Nothing
            }

        ResultsMissing ->
            { title = "Results missing"
            , body = Html.text "The results for the query are missing"
            , details = []
            , errorId = Nothing
            }
