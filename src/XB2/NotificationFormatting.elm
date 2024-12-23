module XB2.NotificationFormatting exposing
    ( TextType(..)
    , formattedLine
    )

import Html exposing (Html)
import WeakCss exposing (ClassName)


type TextType
    = Plain
    | Bold


{-| All this becomes one line.
-}
formattedLine : ClassName -> List ( TextType, String ) -> Html msg
formattedLine namespace chunks =
    chunks
        |> List.map
            (\( textType, line ) ->
                Html.span
                    [ notificationTextNamespace namespace
                        |> WeakCss.withStates [ ( "bold", textType == Bold ) ]
                    ]
                    [ Html.text line ]
            )
        |> Html.div []


notificationTextNamespace : ClassName -> ClassName
notificationTextNamespace namespace =
    namespace
        |> WeakCss.add "notification-text"
