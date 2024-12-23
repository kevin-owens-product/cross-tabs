module XB2.Share.Gwi.Html.Attributes exposing (cssVars, withDisabledGrammarly)

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


withDisabledGrammarly : List (Attribute msg) -> List (Attribute msg)
withDisabledGrammarly =
    (++)
        [ -- Legacy attribute for disabling Grammarly
          Attrs.attribute "data-gramm_editor" "false"

        -- Latest attribute for disabling Grammarly
        , Attrs.attribute "data-enable-grammarly" "false"
        ]
