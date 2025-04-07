module Platform2.Notification exposing
    ( Button
    , Config
    , DisappearState(..)
    , Notification
    , StatelessNotification
    , exportView
    , fromStatelessNotification
    , hidingTimeout
    , isHiding
    , isPersistent
    , map
    , setHiding
    , view
    )

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Events.Extra as Events
import Html.Extra as Html
import Icons exposing (IconData)
import Icons.Platform2 as P2Icons
import WeakCss exposing (ClassName)


type DisappearState
    = -- Invisible state doesn't need to be here, we remove the item from the queue
      Visible
    | Hiding


type alias Button msg =
    { label : String
    , onClick : msg
    }


type alias Notification msg =
    { content : Html msg
    , state : DisappearState
    , button : Maybe (Button msg)
    , shouldPersist : Bool
    , icon : IconData
    , closeMsg : Maybe msg
    }


type alias StatelessNotification =
    { icon : IconData
    , content : Html Never
    }


type alias Config msg queueMsg =
    { wrapMsg : msg -> queueMsg
    }



-- CONSTRUCTORS


create : Maybe (Button msg) -> Html msg -> IconData -> Notification msg
create button content iconData =
    { content = content
    , state = Visible
    , button = button
    , shouldPersist = False
    , icon = iconData
    , closeMsg = Nothing
    }


fromStatelessNotification : StatelessNotification -> Notification msg
fromStatelessNotification { icon, content } =
    create
        Nothing
        (Html.map never content)
        icon



-- UPDATE


setHiding : Notification msg -> Notification msg
setHiding notification =
    { notification | state = Hiding }



-- PREDICATES


isHiding : Notification msg -> Bool
isHiding { state } =
    state == Hiding


isPersistent : Notification msg -> Bool
isPersistent { shouldPersist } =
    shouldPersist



-- VIEW


view : Config msg queueMsg -> ClassName -> Notification msg -> Html queueMsg
view config namespace { content, state, button, icon, closeMsg } =
    let
        concatenatedNamespaces =
            notificationNamespace namespace
    in
    Html.map config.wrapMsg <|
        Html.div [ WeakCss.nest "wrapper" namespace ]
            [ Html.div
                [ concatenatedNamespaces
                    |> WeakCss.withStates
                        [ ( "hiding", state == Hiding )
                        ]
                , Attrs.style "transition" ("opacity " ++ String.fromFloat hidingTimeout ++ "ms")
                ]
                [ Html.div
                    [ WeakCss.nest "icon" concatenatedNamespaces ]
                    [ Icons.icon [] icon ]
                , Html.div [ WeakCss.nest "content" concatenatedNamespaces ] [ content ]
                , Html.viewMaybe
                    (\button_ ->
                        Html.button
                            [ WeakCss.nest "action-button" concatenatedNamespaces
                            , Events.onClickPreventDefault button_.onClick
                            ]
                            [ Html.text button_.label ]
                    )
                    button
                , Html.viewMaybe
                    (\closeMsg_ ->
                        Html.a
                            [ Events.onClickPreventDefault closeMsg_
                            , WeakCss.nest "close" concatenatedNamespaces
                            ]
                            [ Icons.icon [ Icons.height 52 ] P2Icons.cross ]
                    )
                    closeMsg
                ]
            ]


exportView : { downloadMsg : msg, closeMsg : msg } -> Notification msg
exportView { downloadMsg, closeMsg } =
    { content = Html.text "Your export is ready."
    , state = Visible
    , button = Just { label = "Download", onClick = downloadMsg }
    , shouldPersist = True
    , icon = P2Icons.export
    , closeMsg = Just closeMsg
    }


map : (a -> b) -> Notification a -> Notification b
map f n =
    { content = Html.map f n.content
    , state = n.state
    , button = Maybe.map (buttonMap f) n.button
    , shouldPersist = n.shouldPersist
    , icon = n.icon
    , closeMsg = Maybe.map f n.closeMsg
    }


buttonMap : (a -> b) -> Button a -> Button b
buttonMap f a =
    { label = a.label
    , onClick = f a.onClick
    }



-- HELPERS


notificationNamespace : ClassName -> ClassName
notificationNamespace =
    WeakCss.add "notification"


hidingTimeout : Float
hidingTimeout =
    1000
