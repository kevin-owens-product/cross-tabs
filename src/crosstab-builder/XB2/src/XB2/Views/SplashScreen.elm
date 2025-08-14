module XB2.Views.SplashScreen exposing (Params, Triggers, view)

import Html
import Html.Attributes as Attrs
import Html.Events as Events
import Json.Decode as Decode


type alias Params =
    { appName : String
    , email : String
    }


type alias Triggers msg =
    { talkToAnExpert : msg
    , upgrade : msg
    }


paramsToAttributes : Triggers msg -> Params -> List (Html.Attribute msg)
paramsToAttributes triggers params =
    [ Attrs.attribute "app-name" params.appName
    , Attrs.attribute "email" params.email
    , Events.on "CrosstabBuilder-talkToAnExpertEvent" (Decode.succeed triggers.talkToAnExpert)
    , Events.on "CrosstabBuilder-upgradeEvent" (Decode.succeed triggers.upgrade)
    ]


view : Triggers msg -> Params -> Html.Html msg
view triggers params =
    Html.node "x-et-splash-screen"
        (paramsToAttributes triggers params)
        []
