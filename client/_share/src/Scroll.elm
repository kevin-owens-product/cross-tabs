module Scroll exposing (darkWithScrollId)

{-| Make sure to use position absolute css style in the list of attributes,
since without it, the scroll area is resizing in a loop indefinitely
-}

import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.Attributes.Extra as {- different names because of clash: `autocomplete` -} Attrs_


thumb : Html msg
thumb =
    Html.div [ Attrs.class "thumb" ] []


{-| This is required so that virtual-DOM is able to make appropriate mutations
in real DOM.
-}
element : Maybe String -> List (Attribute msg) -> List (Html msg) -> Html msg
element scrollId attrs inner =
    Html.node "x-gemini-scrollbar"
        (Attrs.class "gm-scrollbar-container"
            :: Attrs.attribute "autoshow" "true"
            :: attrs
        )
        [ Html.div [ Attrs.class "gm-scrollbar -vertical" ] [ thumb ]
        , Html.div [ Attrs.class "gm-scrollbar -horizontal" ] [ thumb ]
        , Html.div
            [ Attrs_.attributeMaybe Attrs.id scrollId
            , Attrs.class "gm-scroll-view"
            ]
            inner
        ]


darkWithScrollId : String -> List (Attribute msg) -> List (Html msg) -> Html msg
darkWithScrollId id =
    element (Just id) << (::) (Attrs.class "dark")
