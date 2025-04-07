module ColorContrast exposing (HexColor, get)

import Hex
import Maybe.Extra as Maybe
import Regex exposing (Regex)


type alias HexColor =
    String


type alias RGB =
    { red : Int, green : Int, blue : Int }


hexToRgb : HexColor -> Maybe RGB
hexToRgb hex =
    let
        shorthandColorRegex : Regex
        shorthandColorRegex =
            Regex.fromStringWith { caseInsensitive = True, multiline = False } "^#?([a-f\\d])([a-f\\d])([a-f\\d])$"
                |> Maybe.withDefault Regex.never

        longHex : String
        longHex =
            Regex.replace shorthandColorRegex
                (\{ submatches } ->
                    "#"
                        ++ (submatches
                                |> List.map (Maybe.unwrap "" (\s -> s ++ s))
                                |> String.concat
                           )
                )
                hex

        parseColorRegex : Regex
        parseColorRegex =
            Regex.fromStringWith { caseInsensitive = True, multiline = False } "^#?([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2})$"
                |> Maybe.withDefault Regex.never

        intRGBValues =
            longHex
                |> String.toLower
                |> Regex.find parseColorRegex
                |> List.head
                |> Maybe.unwrap [] .submatches
                |> List.filterMap
                    (\match ->
                        Maybe.map Hex.fromString match
                            |> Maybe.andThen Result.toMaybe
                    )
    in
    case intRGBValues of
        r :: g :: b :: _ ->
            Just { red = r, green = g, blue = b }

        _ ->
            Nothing


luminance : RGB -> Float
luminance { red, green, blue } =
    let
        magicForColor : Int -> Float
        magicForColor c =
            let
                v =
                    toFloat c / 255
            in
            if v <= 0.03928 then
                v / 12.92

            else
                ((v + 0.055) / 1.055) ^ 2.4
    in
    magicForColor red * 0.2126 + magicForColor green * 0.7152 + magicForColor blue * 0.0722


getRatio : HexColor -> HexColor -> Maybe Float
getRatio color1 color2 =
    Maybe.map2
        (\rgb1 rgb2 ->
            let
                color1Luminance =
                    luminance rgb1

                color2Luminance =
                    luminance rgb2
            in
            if color1Luminance > color2Luminance then
                (color2Luminance + 0.05) / (color1Luminance + 0.05)

            else
                (color1Luminance + 0.05) / (color2Luminance + 0.05)
        )
        (hexToRgb color1)
        (hexToRgb color2)


{-|

    Calculate two hex colors contrast ratio and if it's enough according to WCAG standards

    https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio

    Based on this article
    https://dev.to/alvaromontoro/building-your-own-color-contrast-checker-4j7o

-}
get : HexColor -> HexColor -> Maybe { aaLevelSmall : Bool, aaLevelLarge : Bool, aaaLevelSmall : Bool, aaaLevelLarge : Bool }
get color1 color2 =
    getRatio color1 color2
        |> Maybe.map
            (\ratio ->
                { aaLevelSmall = ratio < 1 / 4.5
                , aaLevelLarge = ratio < 1 / 3
                , aaaLevelSmall = ratio < 1 / 7
                , aaaLevelLarge = ratio < 1 / 4.5
                }
            )
