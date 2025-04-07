module Palette exposing
    ( Color(..)
    , FiltersColor(..)
    , colorDecoder
    , filtersColorToHex
    , p2AudienceColorFromIndex
    )

import Array exposing (Array)
import Json.Decode as Decode


cycledColor : Array a -> Int -> Result String a
cycledColor palette index =
    if Array.isEmpty palette then
        Err "Palette is empty"

    else
        let
            index_ =
                modBy (Array.length palette) index
        in
        case Array.get index_ palette of
            Just color_ ->
                Ok color_

            Nothing ->
                -- This shouldn't happen but our type system is not clever enough for that
                Err "Supposedly untriggerable error in Palette.color"


type FiltersColor
    = DefaultColor Color


type Color
    = BaseAloneColor
    | BaseWithAudiencesColor
    | Color1
    | Color2
    | Color3
    | Color4
    | Color5
    | Color6
    | Color7


type alias P2Palette =
    Array FiltersColor


colorToHex : Color -> String
colorToHex color =
    case color of
        BaseAloneColor ->
            -- grey 6
            "#526482"

        BaseWithAudiencesColor ->
            "#7989a6"

        Color1 ->
            -- violet 3
            "#5461c8"

        Color2 ->
            -- teal 4
            "#008291"

        Color3 ->
            -- pink 3
            "#de1b76"

        Color4 ->
            -- blue 4
            "#007cb6"

        Color5 ->
            -- purple 3
            "#963cbd"

        Color6 ->
            -- orange 4
            "#da3441"

        Color7 ->
            -- green 4
            "#008851"


colorDecoder : Decode.Decoder Color
colorDecoder =
    let
        decoder str =
            case str of
                "BaseAloneColor" ->
                    Decode.succeed BaseAloneColor

                "BaseWithAudiencesColor" ->
                    Decode.succeed BaseWithAudiencesColor

                "Color1" ->
                    Decode.succeed Color1

                "Color2" ->
                    Decode.succeed Color2

                "Color3" ->
                    Decode.succeed Color3

                "Color4" ->
                    Decode.succeed Color4

                "Color5" ->
                    Decode.succeed Color5

                "Color6" ->
                    Decode.succeed Color6

                "Color7" ->
                    Decode.succeed Color7

                unknown ->
                    Decode.fail <| "colorDecoder: Unknown color " ++ unknown
    in
    Decode.andThen decoder Decode.string


filtersColorToHex : FiltersColor -> String
filtersColorToHex filtersColor =
    case filtersColor of
        DefaultColor color ->
            colorToHex color


p2Audiences : P2Palette
p2Audiences =
    -- The order is important here!
    -- For reference: https://www.figma.com/file/IQV9SyNVCQXYOrQow4GQsM/Design-Debt?node-id=7%3A755
    Array.fromList
        [ DefaultColor Color1
        , DefaultColor Color2
        , DefaultColor Color3
        , DefaultColor Color4
        , DefaultColor Color5
        , DefaultColor Color6
        , DefaultColor Color7
        ]


p2AudienceColorFromIndex : Int -> FiltersColor
p2AudienceColorFromIndex index =
    cycledColor p2Audiences index
        |> Result.withDefault (DefaultColor BaseAloneColor)
