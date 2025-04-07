module XB2.Views.Onboarding exposing (viewEditABExpBasedOnUserSettings)

{-| Module containing Onboarding views used throughout the application.
TODO: Improve view testing here.
-}

import Html
import Html.Events.Extra as Events
import Html.Extra as Html
import RemoteData
import WeakCss
import XB2.Data as XB2Data


{-| The helper function containing the view for Edit AB Expression modal.
-}
viewEditABExp : { closeMsg : msg } -> { className : WeakCss.ClassName } -> Html.Html msg
viewEditABExp triggers params =
    let
        containerClassName : WeakCss.ClassName
        containerClassName =
            WeakCss.add "onboarding" params.className
    in
    Html.div
        [ WeakCss.toClass containerClassName
        ]
        [ Html.span
            [ WeakCss.nest "new-badge" containerClassName
            ]
            [ Html.text "New"
            ]
        , Html.h3
            [ WeakCss.nest "title" containerClassName
            ]
            [ Html.text
                """
                You can now edit expressions all in one place 🙌
                """
            ]
        , Html.p
            [ WeakCss.nest "tip" containerClassName
            ]
            [ Html.text
                """
                Modify complex expressions in your crosstabs with ease, plus take 
                advantage of the new
                """
            , Html.strong
                []
                [ Html.text " ‘exclude attribute’"
                ]
            , Html.text " feature."
            ]
        , Html.p
            [ WeakCss.nest "tip-second" containerClassName
            ]
            [ Html.text
                """
                Give it a try and start optimizing your data analysis today!
                """
            ]
        , Html.button
            [ WeakCss.nest "got-it" containerClassName
            , Events.onClickStopPropagation triggers.closeMsg
            ]
            [ Html.text "Got it"
            ]
        ]


{-| A view containing the onboarding popup for the Edit AB Expression feature. Its
visibility depends on the user settings flag passed.
-}
viewEditABExpBasedOnUserSettings :
    { updateUserSettingsToMsg : XB2Data.XBUserSettings -> msg }
    ->
        { className : WeakCss.ClassName
        , remoteUserSettings : RemoteData.WebData XB2Data.XBUserSettings
        }
    -> Html.Html msg
viewEditABExpBasedOnUserSettings triggers params =
    case params.remoteUserSettings of
        RemoteData.Success settings ->
            Html.viewIf (not settings.editAttributeExpressionOnboardingSeen) <|
                viewEditABExp
                    { closeMsg =
                        triggers.updateUserSettingsToMsg
                            { settings
                                | editAttributeExpressionOnboardingSeen = True
                            }
                    }
                    { className = params.className }

        RemoteData.Failure _ ->
            Html.nothing

        RemoteData.NotAsked ->
            Html.nothing

        RemoteData.Loading ->
            Html.nothing
