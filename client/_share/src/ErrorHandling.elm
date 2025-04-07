module ErrorHandling exposing (signOutOn401)

import Config exposing (Flags)
import Config.Main
import Data.Core.Error as CoreError
import Error
import Error.Analytics exposing (Event(..))
import Gwi.Http exposing (Error)
import Process
import Task


signOutUrl : Flags -> String -> String
signOutUrl flags redirectTo =
    let
        url =
            Config.Main.get flags.env |> .uri |> .signOut
    in
    url { redirectTo = redirectTo }


signOutOn401 : Flags -> Error err -> String -> (String -> msg) -> (model -> ( model, Cmd msg )) -> model -> ( model, Cmd msg )
signOutOn401 flags err redirectTo loadUrl defaultAction model =
    let
        signOutRedirect () =
            ( model
              -- Give some time to analytics event to be processed by browser before redirect
            , Process.sleep 350 |> Task.perform (always (loadUrl <| signOutUrl flags redirectTo))
            )

        ( newModel, cmd ) =
            case err of
                Gwi.Http.BadStatus metadata _ ->
                    if metadata.statusCode == 401 then
                        signOutRedirect ()

                    else
                        defaultAction model

                Gwi.Http.GenericError _ _ CoreError.InvalidToken ->
                    signOutRedirect ()

                Gwi.Http.GenericError _ _ CoreError.InconsistentToken ->
                    signOutRedirect ()

                _ ->
                    defaultAction model

        event =
            case err of
                Gwi.Http.BadStatus metadata body ->
                    case metadata.statusCode of
                        401 ->
                            SessionExpired

                        403 ->
                            Forbidden

                        _ ->
                            case Error.getExceptionType body of
                                Just Error.InvalidNamespacesCombination ->
                                    Error.Analytics.InvalidNamespacesCombination

                                _ ->
                                    UnexpectedError metadata.statusCode metadata.url

                Gwi.Http.GenericError _ _ CoreError.InvalidToken ->
                    SessionExpired

                Gwi.Http.GenericError _ _ CoreError.InconsistentToken ->
                    InconsistentToken

                Gwi.Http.BadBody metadata _ ->
                    UnexpectedError metadata.statusCode metadata.url

                _ ->
                    UnexpectedError 0 "unknown url"
    in
    ( newModel
    , Cmd.batch
        [ Error.Analytics.trackEvent event
        , cmd
        ]
    )
