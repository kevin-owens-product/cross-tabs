module Error.Analytics exposing (Event(..), trackEvent)

import Analytics
import Json.Encode as Encode exposing (Value)


type Event
    = UnexpectedError Int String
    | Forbidden
    | InvalidNamespacesCombination
    | SessionExpired
    | InconsistentToken


trackEvent : Event -> Cmd msg
trackEvent =
    Analytics.track << encodeEvent


encodeEvent : Event -> ( String, Value )
encodeEvent event =
    case event of
        UnexpectedError code url ->
            ( "Unexpected Error"
            , Encode.object
                [ ( "code", Encode.int code )
                , ( "url", Encode.string url )
                ]
            )

        InvalidNamespacesCombination ->
            ( "Query Error"
            , Encode.object
                [ ( "error", Encode.string "It is not possible to query two independent data sets. Please ensure that data and audiences selected are all from the same data set, or contact customer support for more information." )
                , ( "exception", Encode.string "InvalidQuery" )
                ]
            )

        Forbidden ->
            ( "Forbidden", Encode.null )

        SessionExpired ->
            ( "Session Expired", Encode.null )

        InconsistentToken ->
            ( "Got Inconsistent Token", Encode.null )
