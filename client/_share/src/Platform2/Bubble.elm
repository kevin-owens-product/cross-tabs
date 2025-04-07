module Platform2.Bubble exposing (view)

import Html exposing (Html)
import WeakCss exposing (ClassName)


view : ClassName -> String -> Html msg
view cls text =
    Html.div
        [ WeakCss.toClass cls ]
        [ Html.text text ]
