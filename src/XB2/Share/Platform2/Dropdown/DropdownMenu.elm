module XB2.Share.Platform2.Dropdown.DropdownMenu exposing
    ( DropdownMenu
    , DropdownMenuOptions
    , Orientation(..)
    , Position
    , getDropdownId
    , init
    , isAnyVisible
    , isVisible
    , toggle
    , view
    , with
    , withPrecisePosition
    )

import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.Events exposing (stopPropagationOn)
import Html.Extra as Html
import Json.Decode as Decode
import WeakCss exposing (ClassName)
import XB2.Share.Gwi.Html.Events as Events



{-

   Module usage
   1. Somewhere hold module state (DropdownMenu msg)
       - Use XB2.DropdownMenu.init as default state
   2. Somewhere in view always call this XB2.DropdownMenu.view dropDownHeldSomewhere
   3. Call XB2.DropdownMenu.with for every element which is controlling the menu (open/close)
       - First argument is msg for your update where you simply set new (DropdownMenu msg) to your model
   4. Style it, because this module does not contain any styles for dropdown menu container

   You actually read these comments? Nice! Check if they are still valid.
-}
{- Note: BottomRight is not the same as RightBottom
   - RightBottom shows the menu NEXT to the trigger to the right side, ALIGNED to the bottom
   - BottomRight shows the menu UNDER the trigger ALIGNED to the right
-}


type Orientation
    = BottomRight
    | BottomLeft
    | RightTop
    | RightCenter
    | RightBottom
    | LeftTop
    | LeftBottom
    | ToLeft


type alias MenuData msg =
    { orientation : Orientation
    , position : Position
    , content : Html msg
    , id : String
    }


type DropdownMenu msg
    = Closed
    | Opened (MenuData msg)


type alias Position =
    { x : Float
    , y : Float
    }


init : DropdownMenu msg
init =
    Closed


type alias DropdownMenuOptions msg =
    { id : String
    , orientation : Orientation
    , screenBottomEdgeMinOffset : Float
    , screenSideEdgeMinOffset : Float
    , content : Html msg
    , controlElementAttrs : List (Attribute msg)
    , controlElementContent : List (Html msg)
    }


with : (DropdownMenu msg -> msg) -> DropdownMenuOptions msg -> Html msg
with toMsg { id, orientation, content, screenBottomEdgeMinOffset, screenSideEdgeMinOffset, controlElementAttrs, controlElementContent } =
    let
        openMsg { position, bodyDimensions } =
            let
                bodyWidth =
                    bodyDimensions.width

                bodyHeight =
                    bodyDimensions.height

                {- TODO: This logic can get quickly out of hands, we should maybe separate the X axis (Left, Right)
                   and Y axis (Top, Bottom) and do the orientation change on bounding areas
                       e.g. (Right, Top) in right bottom corner should be (Left, Bottom)

                -}
                orientation_ =
                    if position.y + screenBottomEdgeMinOffset > bodyHeight && (orientation == RightTop || orientation == RightCenter) then
                        if position.x + screenSideEdgeMinOffset > bodyWidth then
                            LeftBottom

                        else
                            RightBottom

                    else if position.y + screenBottomEdgeMinOffset > bodyHeight && (orientation == LeftTop) then
                        LeftBottom

                    else if position.x < screenSideEdgeMinOffset && orientation == BottomRight then
                        BottomLeft

                    else if position.x + screenSideEdgeMinOffset > bodyWidth && orientation == BottomLeft then
                        BottomRight

                    else if position.x + screenSideEdgeMinOffset > bodyWidth && orientation == RightTop then
                        LeftTop

                    else
                        orientation
            in
            toMsg <|
                Opened
                    { id = id
                    , orientation = orientation_
                    , position = position
                    , content = content
                    }

        attributes =
            Events.onClickWithBodyDimensions openMsg
                :: controlElementAttrs
    in
    Html.button attributes controlElementContent


withPrecisePosition : (DropdownMenu msg -> msg) -> DropdownMenuOptions msg -> Html msg
withPrecisePosition unconstructedMsg dropdownMenuOptions =
    let
        msg position =
            unconstructedMsg <|
                Opened
                    { id = dropdownMenuOptions.id
                    , orientation = dropdownMenuOptions.orientation
                    , position = position
                    , content = dropdownMenuOptions.content
                    }

        decoder =
            Decode.map2
                (\x y ->
                    ( msg (Position x y), True )
                )
                (Decode.at [ "target", "__getBoundingClientRect", "left" ] Decode.float)
                (Decode.at [ "target", "__getBoundingClientRect", "top" ] Decode.float)

        onClickWithPos =
            stopPropagationOn "click" decoder
    in
    Html.button (onClickWithPos :: dropdownMenuOptions.controlElementAttrs) dropdownMenuOptions.controlElementContent


orientationToActiveState : Orientation -> String
orientationToActiveState orientation =
    case orientation of
        BottomRight ->
            "bottom-right"

        BottomLeft ->
            "bottom-left"

        RightTop ->
            "right-top"

        RightCenter ->
            "right-center"

        RightBottom ->
            "right-bottom"

        LeftTop ->
            "left-top"

        LeftBottom ->
            "left-bottom"

        ToLeft ->
            "left"


moduleClass : ClassName
moduleClass =
    WeakCss.namespace "p2-et"
        |> WeakCss.add "dynamic-dropdown-menu"


show : MenuData msg -> Html msg
show { orientation, position, content } =
    Html.div
        [ WeakCss.withActiveStates [ orientationToActiveState orientation ] moduleClass
        , Attrs.style "top" (String.fromFloat position.y ++ "px")
        , Attrs.style "left" (String.fromFloat position.x ++ "px")
        , Attrs.style "position" "fixed"
        ]
        [ Html.div [ WeakCss.nest "inner" moduleClass ] [ content ]
        ]


view : DropdownMenu msg -> Html msg
view ddm =
    case ddm of
        Opened data ->
            show data

        Closed ->
            Html.nothing


isAnyVisible : DropdownMenu msg -> Bool
isAnyVisible ddm =
    case ddm of
        Closed ->
            False

        Opened _ ->
            True


isVisible : String -> DropdownMenu msg -> Bool
isVisible idForCheck ddm =
    case ddm of
        Closed ->
            False

        Opened { id } ->
            idForCheck == id


toggle : DropdownMenu msg -> DropdownMenu msg -> DropdownMenu msg
toggle new current =
    case ( new, current ) of
        ( Opened newData, Opened currentData ) ->
            if newData.id == currentData.id then
                Closed

            else
                new

        _ ->
            new


getDropdownId : DropdownMenu msg -> Maybe String
getDropdownId dropdownMenu =
    case dropdownMenu of
        Closed ->
            Nothing

        Opened menuData ->
            Just menuData.id
