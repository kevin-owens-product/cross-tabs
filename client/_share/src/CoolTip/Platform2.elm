module CoolTip.Platform2 exposing (view)

import CoolTip exposing (Config)
import Html exposing (Attribute, Html)
import Html.Attributes as Attrs


p2Class : Attribute msg
p2Class =
    Attrs.class "p2"


view : Config msg -> Html msg
view config =
    CoolTip.view
        { config
            | targetAttributes = p2Class :: config.targetAttributes
            , tooltipAttributes = p2Class :: config.tooltipAttributes
        }
