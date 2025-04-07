module XB2.Views.Modal.LoaderWithProgress exposing (view)

import Html
import Html.Events as Events
import Svg
import Svg.Attributes as SvgAttrs
import WeakCss
import XB2.Share.Gwi.Html.Attributes as Attrs


view :
    { cancelMsg : msg }
    ->
        { className : WeakCss.ClassName
        , loadingLabel : String
        , progressValue : Float
        }
    -> Html.Html msg
view triggers params =
    Html.div
        [ WeakCss.toClass params.className
        , Events.onClick triggers.cancelMsg
        ]
        [ Html.div
            [ WeakCss.nest "modal" params.className ]
            [ Svg.svg
                [ WeakCss.addMany [ "modal", "progress-bar" ] params.className
                    |> WeakCss.toString
                    |> SvgAttrs.class
                , Attrs.cssVars
                    [ ( "--data-percentage-progress"
                      , params.progressValue
                            |> String.fromFloat
                      )
                    ]
                , SvgAttrs.viewBox "0 0 36 36"
                ]
                [ Svg.path
                    [ WeakCss.addMany [ "modal", "progress-bar", "circle" ] params.className
                        |> WeakCss.toString
                        |> SvgAttrs.class
                    , SvgAttrs.d "M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    ]
                    []
                , Svg.path
                    [ WeakCss.addMany [ "modal", "progress-bar", "arc" ] params.className
                        |> WeakCss.toString
                        |> SvgAttrs.class
                    , SvgAttrs.d "M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    ]
                    []
                ]
            , Html.div
                [ WeakCss.nestMany [ "modal", "progress-label" ] params.className ]
                [ Html.text <| (params.progressValue |> round |> String.fromInt) ++ "%" ]
            , Html.div
                [ WeakCss.nestMany [ "modal", "title" ] params.className ]
                [ Html.text params.loadingLabel ]
            , Html.div
                [ WeakCss.nestMany [ "modal", "cancel" ] params.className ]
                [ Html.a
                    [ WeakCss.nestMany [ "modal", "cancel", "btn" ] params.className
                    , Events.onClick triggers.cancelMsg
                    ]
                    [ Html.text "Cancel" ]
                ]
            ]
        ]
