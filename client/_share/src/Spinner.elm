module Spinner exposing (view)

-- libs

import Html exposing (Html)
import WeakCss exposing (ClassName)


moduleClass : ClassName
moduleClass =
    WeakCss.namespace "spinner"


view : Html msg
view =
    Html.div [ WeakCss.toClass moduleClass ]
        [ Html.div [ WeakCss.nest "bounce-1" moduleClass ] []
        , Html.div [ WeakCss.nest "bounce-2" moduleClass ] []
        , Html.div [ WeakCss.nest "bounce-3" moduleClass ] []
        ]
