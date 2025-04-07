module XB2.Views.SplashScreen exposing (Params, view)

import Html
import Html.Attributes as Attrs
import Json.Encode as Encode


type alias Params =
    { appName : String
    , splashTitle : String
    , splashSubtitle : String
    , planUpgrades : List String
    }


paramsToAttributes : Params -> List (Html.Attribute msg)
paramsToAttributes params =
    [ Attrs.attribute "app-name" params.appName
    , Attrs.attribute "splash-title" params.splashTitle
    , Attrs.attribute "splash-subtitle" params.splashSubtitle
    , Attrs.attribute "plan-upgrades" (Encode.encode 0 (Encode.list Encode.string params.planUpgrades))
    ]


view : Params -> Html.Html msg
view params =
    Html.node "x-et-splash-screen"
        (paramsToAttributes params)
        []
