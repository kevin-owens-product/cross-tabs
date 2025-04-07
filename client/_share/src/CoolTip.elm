module CoolTip exposing
    ( Config
    , Position(..)
    , Type(..)
    , view
    )

import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as Attrs


type alias Config msg =
    { offset : Maybe Int
    , type_ : Type
    , position : Position
    , wrapperAttributes : List (Attribute msg)
    , targetAttributes : List (Attribute msg)
    , targetHtml : List (Html msg)
    , tooltipAttributes : List (Attribute msg)
    , tooltipHtml : Html msg
    }


{-| Check the comment in the x-cooltip/component.ts file for description of these.

TL;DR:
\* default to using Normal when you can
\* try to troubleshoot with RelativeAncestor if `position: relative` elements are giving you hell
\* use Global only if you absolutely must.

-}
type Type
    = Normal
    | NormalShownWhenEllipsis String


type Position
    = Top
    | TopRight
    | Right
    | Bottom
    | BottomRight


positionToClass : Position -> String
positionToClass position =
    case position of
        Top ->
            "top"

        TopRight ->
            "topright"

        Right ->
            "right"

        BottomRight ->
            "bottomright"

        Bottom ->
            "bottom"


view : Config msg -> Html msg
view { offset, type_, position, tooltipHtml, wrapperAttributes, tooltipAttributes, targetAttributes, targetHtml } =
    Html.node "x-cooltip"
        ((offset
            |> Attrs.attributeMaybe
                (\offset_ -> Attrs.attribute "offset" (String.fromInt offset_))
         )
            :: (case type_ of
                    Normal ->
                        Attrs.empty

                    NormalShownWhenEllipsis selector ->
                        Attrs.attribute "show-when-ellipsis" selector
               )
            :: wrapperAttributes
        )
        [ Html.node "x-cooltip-target"
            targetAttributes
            targetHtml
        , Html.node "x-cooltip-tooltip"
            ((Attrs.class <| positionToClass position) :: tooltipAttributes)
            [ tooltipHtml ]
        ]
