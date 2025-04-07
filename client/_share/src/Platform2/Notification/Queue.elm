module Platform2.Notification.Queue exposing
    ( Msg(..)
    , NotificationData
    , NotificationId(..)
    , NotificationQueue
    , clearById
    , clearNonpersistent
    , empty
    , enqueue
    , enqueueWithId
    , update
    , view
    )

import Html exposing (Html)
import Html.Extra as Html
import Html.Keyed
import Platform2.Notification as Notification exposing (Notification)
import Process
import Queue exposing (Queue)
import Task
import WeakCss



-- TYPES


type NotificationId
    = Generic Int
    | UserDefined String


type QueueType
    = Infinite


type NotificationQueue msg
    = NotificationQueue
        { notifications : Queue (NotificationData msg)
        , queueType : QueueType
        , nextId : Int
        }


type alias NotificationData msg =
    { id : NotificationId
    , notification : Notification msg
    }


type Msg msg
    = StartHiding NotificationId
    | RemoveHiding
    | InnerMsg msg



-- MAIN API


empty_ : QueueType -> NotificationQueue msg
empty_ queueType =
    NotificationQueue
        { notifications = Queue.empty
        , queueType = queueType
        , nextId = 0
        }


empty : NotificationQueue msg
empty =
    empty_ Infinite


isEmpty : NotificationQueue msg -> Bool
isEmpty (NotificationQueue { notifications }) =
    Queue.isEmpty notifications


clearById : String -> NotificationQueue msg -> NotificationQueue msg
clearById id =
    filter ((/=) (UserDefined id) << .id)


incrementId : NotificationQueue msg -> NotificationQueue msg
incrementId (NotificationQueue queue) =
    NotificationQueue { queue | nextId = queue.nextId + 1 }


enqueueWithId : String -> Notification msg -> NotificationQueue msg -> ( NotificationQueue msg, Cmd (Msg msg) )
enqueueWithId id =
    enqueueWithId_ <| UserDefined id


enqueueWithId_ : NotificationId -> Notification msg -> NotificationQueue msg -> ( NotificationQueue msg, Cmd (Msg msg) )
enqueueWithId_ id notification queue =
    let
        notificationWithId =
            { id = id
            , notification = notification
            }

        cmd =
            if notification.shouldPersist then
                Cmd.none

            else
                performAfterDelay visibleTimeout <| StartHiding notificationWithId.id

        updateNotification =
            Queue.map
                (\notification_ ->
                    if notification_.id == id then
                        notificationWithId

                    else
                        notification_
                )

        dequeueIfOverLimit ((NotificationQueue data) as queue_) =
            case data.queueType of
                Infinite ->
                    queue_

        upsertQueue =
            toList queue
                |> List.map .id
                |> (\notifications ->
                        if List.member id notifications then
                            incrementId queue
                                |> mapQueue updateNotification

                        else
                            incrementId queue
                                |> mapQueue (Queue.enqueue notificationWithId)
                   )
                |> dequeueIfOverLimit
    in
    ( upsertQueue
    , cmd
    )


enqueue : Notification msg -> NotificationQueue msg -> ( NotificationQueue msg, Cmd (Msg msg) )
enqueue notification queue =
    let
        id =
            getNextId queue
    in
    enqueueWithId_ (Generic id) notification queue


{-| The third element of the 3-tuple is a Msg returned by the Html inside a notification.
-}
update : Msg msg -> NotificationQueue msg -> ( NotificationQueue msg, Cmd (Msg msg), Maybe msg )
update msg queue =
    case msg of
        StartHiding id ->
            ( map
                (\data ->
                    if data.id == id then
                        { data | notification = Notification.setHiding data.notification }

                    else
                        data
                )
                queue
            , performAfterDelay Notification.hidingTimeout RemoveHiding
            , Nothing
            )

        RemoveHiding ->
            let
                newQueue =
                    filter (.notification >> Notification.isHiding >> not) queue
            in
            ( newQueue
            , Cmd.none
            , Nothing
            )

        InnerMsg msg_ ->
            ( queue
            , Cmd.none
            , Just msg_
            )


mapQueue : (Queue (NotificationData msg) -> Queue (NotificationData msg)) -> NotificationQueue msg -> NotificationQueue msg
mapQueue fn (NotificationQueue ({ notifications } as queue)) =
    NotificationQueue { queue | notifications = fn notifications }


map : (NotificationData msg -> NotificationData msg) -> NotificationQueue msg -> NotificationQueue msg
map fn (NotificationQueue ({ notifications } as queue)) =
    NotificationQueue { queue | notifications = Queue.map fn notifications }


filter : (NotificationData msg -> Bool) -> NotificationQueue msg -> NotificationQueue msg
filter fn (NotificationQueue ({ notifications } as queue)) =
    NotificationQueue { queue | notifications = Queue.filter fn notifications }


toList : NotificationQueue msg -> List (NotificationData msg)
toList (NotificationQueue { notifications }) =
    Queue.toList notifications


clearNonpersistent : NotificationQueue msg -> NotificationQueue msg
clearNonpersistent =
    filter (.notification >> Notification.isPersistent)



-- VIEW


idToString : NotificationId -> String
idToString id =
    case id of
        Generic int ->
            "generic:" ++ String.fromInt int

        UserDefined string ->
            "userDefined:" ++ string


view : WeakCss.ClassName -> NotificationQueue msg -> Html (Msg msg)
view namespace queue =
    Html.viewIf (not <| isEmpty queue) <|
        Html.div
            [ WeakCss.toClass namespace ]
            [ Html.Keyed.node "div"
                []
                (List.map
                    (\{ id, notification } ->
                        ( idToString id
                        , Notification.view { wrapMsg = InnerMsg } namespace notification
                        )
                    )
                    (queue
                        |> toList
                        |> List.reverse
                    )
                )
            ]



-- HELPERS


getNextId : NotificationQueue msg -> Int
getNextId (NotificationQueue { nextId }) =
    nextId


visibleTimeout : Float
visibleTimeout =
    5000


performAfterDelay : Float -> a -> Cmd a
performAfterDelay delay msg =
    Task.perform (\_ -> msg) (Process.sleep delay)
