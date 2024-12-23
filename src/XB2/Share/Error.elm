module XB2.Share.Error exposing (Exception(..), getDisplay, getExceptionType)

import Dict
import Html
import Html.Attributes as Attrs
import Json.Decode as Decode exposing (Decoder)
import Maybe.Extra as Maybe
import XB2.Share.Data.Core.Error as CoreError
import XB2.Share.Dialog.ErrorDisplay exposing (ErrorDisplay)
import XB2.Share.Gwi.Http exposing (Error(..))


messageDecoder : Decoder String
messageDecoder =
    Decode.oneOf
        [ Decode.field "message" Decode.string
        , Decode.field "error" Decode.string
        ]


type Exception
    = InvalidNamespacesCombination
    | InvalidQuery
    | InvalidAudiences


exceptionDecoder : Decoder Exception
exceptionDecoder =
    let
        decoder exception =
            case String.toLower exception of
                "invalidprojectscombination" ->
                    Decode.succeed InvalidNamespacesCombination

                "invalidquery" ->
                    Decode.succeed InvalidQuery

                "invalidaudiences" ->
                    Decode.succeed InvalidAudiences

                _ ->
                    Decode.fail <| "Unknown exception type: " ++ exception
    in
    Decode.field "exception" <| Decode.andThen decoder Decode.string


getExceptionType : String -> Maybe Exception
getExceptionType requestBody =
    Decode.decodeString exceptionDecoder requestBody
        |> Result.toMaybe


getDisplay : (err -> ErrorDisplay msg) -> Error err -> ErrorDisplay msg
getDisplay customErrorDisplay error =
    case error of
        BadUrl _ ->
            { title = "Bad URL"
            , body = Html.text "Oops, service can't be reached."
            , details = []
            , errorId = Nothing
            }

        Timeout ->
            { title = "Timeout"
            , body = Html.text "A request to our servers took way too long. Please try again later. If the issue persists then please start a live chat with a member of our support team using the button below."
            , details = []
            , errorId = Nothing
            }

        NetworkError ->
            { title = "Network Error"
            , body = Html.text "Unfortunately we have detected a connection issue. Please try again later. If the issue persists then please start a live chat with a member of our support team using the button below."
            , details = []
            , errorId = Nothing
            }

        BadStatus metadata body ->
            let
                maybeUuid : Maybe String
                maybeUuid =
                    metadata.headers
                        |> Dict.get "x-gateway-uuid"

                badStatusMessage =
                    case getExceptionType body of
                        Just InvalidNamespacesCombination ->
                            Html.p []
                                [ Html.text "It is not possible to query two independent data sets. Please ensure that data and audiences selected are all from the same data set, or contact "
                                , Html.a [ Attrs.href "mailto:customersuccess@globalwebindex.com", Attrs.target "_blank" ] [ Html.text "customer support" ]
                                , Html.text " for more information."
                                ]

                        Just InvalidAudiences ->
                            Html.p []
                                [ Html.text "You do not have access to specified audience(s)."
                                , Html.br [] []
                                , Html.text "This may be due to a change in your permissions, or due to a change in the questions used to create this audience. Please try to recreate the audience in Audience Builder, or contact support for help."
                                ]

                        _ ->
                            body
                                |> Decode.decodeString messageDecoder
                                |> Result.withDefault "Unexpected error."
                                |> Html.text
            in
            { title = "Incompatible Data"
            , body = badStatusMessage
            , details = Maybe.unwrap [] (viewUuid >> List.singleton) maybeUuid
            , errorId = maybeUuid
            }

        BadBody _ decodeError ->
            { title = "Bad Body"
            , body = Html.text <| Decode.errorToString decodeError
            , details = []
            , errorId = Nothing
            }

        GenericError uuid _ genericError ->
            { title = CoreError.errorTitle genericError
            , body = Html.text <| CoreError.errorToString genericError
            , details = [ viewUuid uuid ]
            , errorId = Just uuid
            }

        CustomError uuid _ customError ->
            let
                { title, body, details } =
                    customErrorDisplay customError
            in
            { title = title
            , body = body
            , details = viewUuid uuid :: details
            , errorId = Just uuid
            }

        OtherError otherError ->
            { title = XB2.Share.Gwi.Http.otherErrorTitle otherError
            , body = Html.text <| XB2.Share.Gwi.Http.otherErrorToString otherError
            , details = []
            , errorId = Nothing
            }


viewUuid : String -> String
viewUuid uuid =
    "Error code: " ++ uuid
