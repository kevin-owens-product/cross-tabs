port module XB2.Share.Gwi.Browser.Dom exposing
    ( DomElementId
    , ScrollOffset(..)
    , batchRegister
    , debouncedScrollEvent
    , scrollToIfNotVisible
    )

import Browser.Dom exposing (Element)
import Dict exposing (Dict)
import Task exposing (Task)


port onScrollEnd_ : (( String, Int, Int ) -> msg) -> Sub msg


port onScrollStart_ : (String -> msg) -> Sub msg


port debouncedScrollEvent : String -> Cmd msg


{-| For upcoming visibility calculation is better to have this coordinates for first element as 0,0
(with approprieate correction of scene and viewport),
but for some cases has parent element defined offset position (non zero x,y) and this is inherited to the child
-}
correctElementValuesByParent : Element -> Element -> Element
correctElementValuesByParent element parentElement =
    let
        innerElement =
            element.element

        innerViewport =
            element.viewport

        innerScene =
            element.scene
    in
    { element
        | element =
            { innerElement
                | x = innerElement.x - parentElement.element.x
                , y = innerElement.y - parentElement.element.y
            }
        , viewport =
            { innerViewport
                | width = element.viewport.width - parentElement.element.x
                , height = element.viewport.height - parentElement.element.y
            }
        , scene =
            { innerScene
                | width = element.scene.width - parentElement.element.x
                , height = element.scene.height - parentElement.element.y
            }
    }


isVisible : Element -> Element -> Browser.Dom.Viewport -> Bool
isVisible element_ parentElement vp =
    let
        element =
            correctElementValuesByParent element_ parentElement
    in
    (element.element.y >= parentElement.element.y)
        && (element.element.y + element.element.height <= vp.viewport.height + parentElement.element.y)
        && (element.element.x >= parentElement.element.x)
        && (element.element.x + element.element.width <= parentElement.element.x + vp.viewport.width)


type ScrollOffset
    = Centered


scrollToIfNotVisibleWithOffset : { scrollParentId : String, elementId : String, scrollOffest : ScrollOffset } -> Task Browser.Dom.Error ()
scrollToIfNotVisibleWithOffset { scrollParentId, elementId, scrollOffest } =
    Task.map3
        (\element viewport parentElement ->
            let
                ( yCorrection, xCorrection ) =
                    case scrollOffest of
                        Centered ->
                            ( element.viewport.height / 2 - element.viewport.height, element.viewport.width / 2 - element.viewport.width )
            in
            { visible = isVisible element parentElement viewport
            , scrollToY = viewport.viewport.y + element.element.y + yCorrection
            , scrollToX = viewport.viewport.x + element.element.x + xCorrection
            }
        )
        (Browser.Dom.getElement elementId)
        (Browser.Dom.getViewportOf scrollParentId)
        (Browser.Dom.getElement scrollParentId)
        |> Task.andThen
            (\{ visible, scrollToY, scrollToX } ->
                if visible then
                    Task.succeed ()

                else
                    Browser.Dom.setViewportOf scrollParentId scrollToX scrollToY
            )


scrollToIfNotVisible : { scrollParentId : String, elementId : String } -> Task Browser.Dom.Error ()
scrollToIfNotVisible { scrollParentId, elementId } =
    scrollToIfNotVisibleWithOffset { scrollParentId = scrollParentId, elementId = elementId, scrollOffest = Centered }


type alias DomElementId =
    String


{-| This will guarantee only one subscription per type even for multiple elements observed.
It means we do not have unnecessary `NoOp` msgs fired.
-}
batchRegister :
    { onScrollEnd : Dict DomElementId (( Int, Int ) -> msg)
    , onScrollStart : Dict DomElementId msg
    , noOp : msg
    }
    -> Sub msg
batchRegister config =
    Sub.batch
        [ onScrollEnd_
            (\( id, x, y ) ->
                case Dict.get id config.onScrollEnd of
                    Just msg ->
                        msg ( x, y )

                    Nothing ->
                        config.noOp
            )
        , onScrollStart_
            (\id ->
                case Dict.get id config.onScrollStart of
                    Just msg ->
                        msg

                    Nothing ->
                        config.noOp
            )
        ]
