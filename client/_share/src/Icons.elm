module Icons exposing
    ( Attribute
    , IconData
    , height
    , icon
    , width
    )

import Html exposing (Html)
import Maybe.Extra as Maybe
import Svg
import Svg.Attributes as SvgAttrs


{-| Crispicons. Specially crafted icons to keep crisp edges when rendered in the browser. Inspired by:

  - <https://solvit.io/5d11ad4>
  - <https://octicons.github.com/>

-}
type alias IconData =
    { vWidth : Int
    , vHeight : Int
    , vMinX : Int
    , vMinY : Int
    , svg : Html Never
    }


type Attribute
    = Width Int
    | Height Int


width : Int -> Attribute
width =
    Width


height : Int -> Attribute
height =
    Height


icon : List Attribute -> IconData -> Html msg
icon attrs data =
    let
        foldedAttrs =
            List.foldl
                (\attr acc ->
                    case attr of
                        Width w ->
                            { acc | width = Just w }

                        Height h ->
                            { acc | height = Just h }
                )
                { height = Nothing, width = Nothing }
                attrs

        proportionalWidth h =
            Basics.round ((toFloat data.vWidth / toFloat data.vHeight) * toFloat h)

        proportionalHeight w =
            Basics.round ((toFloat data.vHeight / toFloat data.vWidth) * toFloat w)

        iconWidth =
            Maybe.map proportionalWidth foldedAttrs.height
                |> Maybe.or foldedAttrs.width
                |> Maybe.withDefault data.vWidth

        iconHeight =
            Maybe.map proportionalHeight foldedAttrs.width
                |> Maybe.or foldedAttrs.height
                |> Maybe.withDefault data.vHeight
    in
    Svg.svg
        [ SvgAttrs.version "1.1"
        , SvgAttrs.width <| String.fromInt iconWidth
        , SvgAttrs.height <| String.fromInt iconHeight
        , SvgAttrs.viewBox <| String.join " " <| List.map String.fromInt [ data.vMinX, data.vMinY, data.vWidth, data.vHeight ]
        , SvgAttrs.fillRule "evenodd"
        , SvgAttrs.fill "currentColor"
        ]
        [ data.svg
        ]
        |> Html.map never
