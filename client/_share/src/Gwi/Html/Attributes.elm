module Gwi.Html.Attributes exposing (cssVars)

import Html exposing (Attribute)
import Html.Attributes as Attrs


{-| This function expects you to provide the `--` prefixes!

    cssVars [ ( "--total-row-height", "300px" ) ]

-}
cssVars : List ( String, String ) -> Attribute msg
cssVars vars =
    vars
        |> List.map (\( var, value ) -> var ++ ": " ++ value)
        |> String.join ";"
        |> Attrs.attribute "style"
