module XB2.Share.ErrorHandling exposing (signOutOn401)

import Process
import Task
import XB2.Share.Config exposing (Flags)
import XB2.Share.Config.Main
import XB2.Share.Data.Core.Error as CoreError
import XB2.Share.Error
import XB2.Share.Error.Analytics exposing (Event(..))
import XB2.Share.Gwi.Http exposing (Error)


signOutUrl : Flags -> String -> String
signOutUrl flags redirectTo =
    let
        url =
            XB2.Share.Config.Main.get flags.env |> .uri |> .signOut
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
                XB2.Share.Gwi.Http.BadStatus metadata _ ->
                    if metadata.statusCode == 401 then
                        signOutRedirect ()

                    else
                        defaultAction model

                XB2.Share.Gwi.Http.GenericError _ _ CoreError.InvalidToken ->
                    signOutRedirect ()

                XB2.Share.Gwi.Http.GenericError _ _ CoreError.InconsistentToken ->
                    signOutRedirect ()

                _ ->
                    defaultAction model

        event =
            case err of
                XB2.Share.Gwi.Http.BadStatus metadata body ->
                    case metadata.statusCode of
                        401 ->
                            SessionExpired

                        403 ->
                            Forbidden

                        _ ->
                            case XB2.Share.Error.getExceptionType body of
                                Just XB2.Share.Error.InvalidNamespacesCombination ->
                                    XB2.Share.Error.Analytics.InvalidNamespacesCombination

                                _ ->
                                    UnexpectedError metadata.statusCode metadata.url

                XB2.Share.Gwi.Http.GenericError _ _ CoreError.InvalidToken ->
                    SessionExpired

                XB2.Share.Gwi.Http.GenericError _ _ CoreError.InconsistentToken ->
                    InconsistentToken

                XB2.Share.Gwi.Http.BadBody metadata _ ->
                    UnexpectedError metadata.statusCode metadata.url

                _ ->
                    UnexpectedError 0 "unknown url"
    in
    ( newModel
    , Cmd.batch
        [ XB2.Share.Error.Analytics.trackEvent event
        , cmd
        ]
    )
