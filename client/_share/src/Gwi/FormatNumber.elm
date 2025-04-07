module Gwi.FormatNumber exposing
    ( formatNumber
    , formatTV
    , formatTVInt
    , formatToDecimals
    )

import FormatNumber
import FormatNumber.Locales
import Maybe.Extra as Maybe


type Multiplier
    = Thousands
    | Millions
    | Billions


defaultLocale : FormatNumber.Locales.Locale
defaultLocale =
    FormatNumber.Locales.base


multiplierToShortString : Multiplier -> String
multiplierToShortString m =
    case m of
        Thousands ->
            "k"

        Millions ->
            "M"

        Billions ->
            "B"


addSuffix : String -> Float -> String
addSuffix suffix num =
    String.fromFloat num ++ suffix


{-| Ported from <https://github.com/GlobalWebIndex/d3-charts/blob/6292e49bb7be71dd0993467d924687133573b58d/src/utils/text.ts#L185>

  - Has effect only for positive numbers

-}
formatNumber : Float -> String
formatNumber value =
    let
        suffix =
            Maybe.unwrap "" multiplierToShortString
    in
    numberWithMultiplier value
        |> (\( valueString, multiplier ) ->
                valueString ++ suffix multiplier
           )


numberWithMultiplier : Float -> ( String, Maybe Multiplier )
numberWithMultiplier value =
    let
        ( dividedValue, multiplier ) =
            if value < 1000 then
                ( value, Nothing )

            else if value < 10000 then
                ( toFloat (round (value / 100)) / 10, Just Thousands )

            else if value < 1000000 then
                ( toFloat (round (value / 1000)), Just Thousands )

            else if value < 1000000000 then
                ( toFloat (round (value / 100000)) / 10, Just Millions )

            else
                ( toFloat (round (value / 100000000)) / 10, Just Billions )
    in
    ( String.fromFloat dividedValue, multiplier )


{-| TV is supposed to format numbers like CB does:

<https://github.com/GlobalWebIndex/d3-charts/blob/6292e49bb7be71dd0993467d924687133573b58d/src/utils/text.ts#L178-L199>

This means: unit suffixes, but also one decimal point.
It's a bit different from the `formatNumber` in this module.

TV has a bit different acceptance criterias for this so we differ from the CB
algorithm too.

See tests for examples.

-}
formatTV : Float -> String
formatTV =
    formatToDecimals { decimals = 1, keepZeroValues = True }


formatToDecimals : { decimals : Int, keepZeroValues : Bool } -> Float -> String
formatToDecimals { decimals, keepZeroValues } value =
    let
        withSuffix s v =
            v ++ s

        removeDecimalsIfAllZeros : String -> String
        removeDecimalsIfAllZeros string =
            case String.split "." string of
                [ intPart, decimalPart ] ->
                    if String.all ((==) '0') decimalPart then
                        intPart

                    else
                        string

                _ ->
                    string

        sanitizeZeroDecimals =
            if keepZeroValues then
                identity

            else
                removeDecimalsIfAllZeros

        toStringWithSanitizedDecimals =
            toStringWithDecimals decimals
                >> sanitizeZeroDecimals
    in
    if value < 1000 then
        toStringWithSanitizedDecimals value

    else if value < 1000000 then
        (value / (10 ^ 3 |> toFloat))
            |> toStringWithSanitizedDecimals
            |> withSuffix "k"

    else if value < 1000000000 then
        (value / (10 ^ 6 |> toFloat))
            |> toStringWithSanitizedDecimals
            |> withSuffix "M"

    else
        (value / (10 ^ 9 |> toFloat))
            |> toStringWithSanitizedDecimals
            |> withSuffix "B"


toStringWithDecimals : Int -> Float -> String
toStringWithDecimals decimals =
    FormatNumber.format { defaultLocale | decimals = FormatNumber.Locales.Exact decimals }


{-| Basically the same thing as formatTV, but we don't show that decimal digit
if the number < 1000.
-}
formatTVInt : Int -> String
formatTVInt value =
    if value < 1000 then
        String.fromInt value

    else if value < 1000000 then
        toFloat (round (toFloat value / 100)) / 10 |> addSuffix "k"

    else if value < 1000000000 then
        toFloat (round (toFloat value / 100000)) / 10 |> addSuffix "M"

    else
        toFloat (round (toFloat value / 100000000)) / 10 |> addSuffix "B"
