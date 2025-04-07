module ResizeObserver exposing
    ( Dimensions
    , view
    )

import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.Events as Events
import Json.Decode as Decode exposing (Decoder)


type alias Dimensions =
    { width : Float
    , height : Float
    }


{-| It's only important that this element or one of its descendants
(in `children`) is findable using the `targetSelector`.
-}
view :
    { targetSelector : String
    , toMsg : Dimensions -> msg
    }
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
view { targetSelector, toMsg } attrs children =
    Html.node "x-resize-observer"
        (Attrs.attribute "target-selector" targetSelector
            :: Events.on "targetresize" (Decode.map toMsg targetDimensionsDecoder)
            :: attrs
        )
        children


targetDimensionsDecoder : Decoder Dimensions
targetDimensionsDecoder =
    Decode.field "detail" <|
        Decode.map2 Dimensions
            (Decode.field "width" Decode.float)
            (Decode.field "height" Decode.float)
