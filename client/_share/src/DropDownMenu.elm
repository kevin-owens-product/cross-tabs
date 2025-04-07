module DropDownMenu exposing
    ( ArrowPosition(..)
    , Config
    , Model(..)
    , view
    )

{-| This module handles the opening and closing logic of various drop-down menus
across the platform.

It _DOESN'T_ handle the styling. It only provides you with classes for various
ArrowPositions, which you can then use to customize your dropdowns, if you choose
to. Eg. `BottomLeft` will result in "left" class being added to the dropdown menu.

-}

import Html exposing (Html)
import Html.Extra as Html
import WeakCss exposing (ClassName)



-- Config


type ArrowPosition
    = TopLeft
    | Nowhere


type alias Config msg =
    { id : String
    , className : ClassName
    , arrow : ArrowPosition
    , content : List (Html msg)
    }


type Model msg
    = Open (Config msg)


applyOpenClosed : (Config msg -> a) -> a -> Model msg -> a
applyOpenClosed fcOpen _ m =
    case m of
        Open config ->
            fcOpen config



-- view


open_ : Config msg -> Html msg -> Config msg -> Html msg
open_ { id, className, arrow } listContent c =
    Html.viewIf (c.id == id) <|
        Html.div
            [ WeakCss.withActiveStates [ arrowPositionState arrow ] className ]
            [ listContent ]


arrowPositionState : ArrowPosition -> String
arrowPositionState arrow =
    case arrow of
        TopLeft ->
            "top-left"

        Nowhere ->
            "no-arrow"


view : Config msg -> Model msg -> Html msg
view ({ content, className } as config) =
    let
        listContent =
            Html.ul [ WeakCss.nest "list" className ] content
    in
    customView listContent config


customView : Html msg -> Config msg -> Model msg -> Html msg
customView listContent config =
    applyOpenClosed (open_ config listContent) Html.nothing
