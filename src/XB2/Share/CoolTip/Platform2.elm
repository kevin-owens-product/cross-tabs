module XB2.Share.CoolTip.Platform2 exposing (ConditionalCooltipConfig, view, viewIf)

import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import XB2.Share.CoolTip exposing (Config, Position, Type)


type alias ConditionalCooltipConfig msg =
    { targetHtml : Html msg
    , type_ : Type
    , position : Position
    , wrapperAttributes : List (Attribute msg)
    , tooltipText : String
    }


p2Class : Attribute msg
p2Class =
    Attrs.class "p2"


view : Config msg -> Html msg
view config =
    XB2.Share.CoolTip.view
        { config
            | targetAttributes = p2Class :: config.targetAttributes
            , tooltipAttributes = p2Class :: config.tooltipAttributes
        }


viewIf : Bool -> ConditionalCooltipConfig msg -> Html msg
viewIf cond { targetHtml, tooltipText, type_, position, wrapperAttributes } =
    if cond then
        view
            { offset = Nothing
            , type_ = type_
            , position = position
            , wrapperAttributes = wrapperAttributes
            , targetAttributes = []
            , targetHtml = [ targetHtml ]
            , tooltipAttributes = []
            , tooltipHtml = Html.text tooltipText
            }

    else
        targetHtml
