module XB2.Views.Modal.LoaderWithoutProgress exposing (view)

{-| A module handling everything related to the modal showing the spinner for loading
purposes. Used mainly in heatmap and export services.
-}

import Html
import Html.Events as Events
import WeakCss
import XB2.Share.Platform2.Spinner as Spinner


{-| The view of the modal. Pass a className and a text you want to show below the spinner
as you wish.

Looks like this:

    ┌───────────────────────────┐
    │             O             │
    │   Loading your cells...   │
    │                           │
    │           Cancel          │
    └───────────────────────────┘

-}
view :
    { cancelMsg : msg }
    ->
        { className : WeakCss.ClassName
        , loadingLabel : String
        }
    -> Html.Html msg
view triggers params =
    Html.div
        [ WeakCss.toClass params.className
        , Events.onClick triggers.cancelMsg
        ]
        [ Html.div
            [ WeakCss.nest "modal" params.className
            ]
            [ Html.div
                [ WeakCss.nestMany
                    [ "modal"
                    , "noprogress-spinner"
                    ]
                    params.className
                ]
                [ Spinner.view
                ]
            , Html.div
                [ WeakCss.nestMany
                    [ "modal"
                    , "title"
                    ]
                    params.className
                ]
                [ Html.text params.loadingLabel
                ]
            , Html.div
                [ WeakCss.nestMany
                    [ "modal"
                    , "cancel"
                    ]
                    params.className
                ]
                [ Html.a
                    [ WeakCss.nestMany
                        [ "modal"
                        , "cancel"
                        , "btn"
                        ]
                        params.className
                    , Events.onClick triggers.cancelMsg
                    ]
                    [ Html.text "Cancel"
                    ]
                ]
            ]
        ]
