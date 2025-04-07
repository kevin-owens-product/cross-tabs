module Analytics.Global exposing
    ( Event(..)
    , trackEvent
    )

import Analytics
import Analytics.Place as Place exposing (Place)
import Json.Encode as Encode exposing (Value)


type Event
    = AudienceUsed Place { id : String, name : String, state : Encode.Value }


trackEvent : Event -> Cmd msg
trackEvent event =
    Analytics.track <| encodeEvent event


encodeEvent : Event -> ( String, Value )
encodeEvent event =
    case event of
        AudienceUsed place { id, name, state } ->
            ( "Audience Used"
            , Encode.object
                [ ( "audience_ID", Encode.string id )
                , ( "name", Encode.string name )
                , ( "place", Place.encode place )
                , ( "type", state )
                ]
            )
