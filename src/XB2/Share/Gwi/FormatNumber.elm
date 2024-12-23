module XB2.Share.Gwi.FormatNumber exposing
    ( formatNumber
    , formatXBAverage
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


toStringWithDecimals : Int -> Float -> String
toStringWithDecimals decimals =
    FormatNumber.format { defaultLocale | decimals = FormatNumber.Locales.Exact decimals }


formatXBAverage : Float -> String
formatXBAverage value =
    toStringWithDecimals 2 value
