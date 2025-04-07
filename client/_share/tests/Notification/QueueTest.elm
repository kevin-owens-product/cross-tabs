module Notification.QueueTest exposing
    ( neverDuplicatesIdsTest
    , notificationsWithId
    , removeHidingRemovesNotificationsUnderThatTimestampTest
    )

import ArchitectureTest exposing (TestedApp, TestedModel(..), TestedUpdate(..))
import Dict
import Dict.Extra as Dict
import Expect
import Fuzz exposing (Fuzzer)
import Html
import Html.Extra as Html
import Notification exposing (Notification, NotificationType(..))
import Notification.Queue exposing (NotificationId(..), NotificationQueue)
import Test exposing (Test, describe, test)



-- UNIT TESTS


notificationsWithId : Test
notificationsWithId =
    describe "Notifications with ID"
        [ test "enqueue notification with same id two times, the count should be one" <|
            \() ->
                let
                    mockNotification =
                        Notification.create Success Html.nothing
                in
                Notification.Queue.empty
                    |> Notification.Queue.enqueueWithId "id" mockNotification
                    |> Tuple.first
                    |> Notification.Queue.enqueueWithId "id" mockNotification
                    |> Tuple.first
                    |> Notification.Queue.toList
                    |> List.length
                    |> Expect.equal 1
        , test "enque two notifications with the same id, the content should be the last notification enqueue" <|
            \() ->
                let
                    firstNotification =
                        Notification.create Success Html.nothing

                    secondNotification =
                        Notification.create Success <| Html.text "second"
                in
                Notification.Queue.empty
                    |> Notification.Queue.enqueueWithId "id" firstNotification
                    |> Tuple.first
                    |> Notification.Queue.enqueueWithId "id" secondNotification
                    |> Tuple.first
                    |> Notification.Queue.toList
                    |> List.head
                    |> Maybe.map (.notification >> .content)
                    |> Maybe.withDefault Html.nothing
                    |> Expect.equal (Html.text "second")
        ]



-- FUZZ TESTS
{- TODO: think of adding fuzz tests for
   - persistent notifications (withPersistence)
   - for custom ids notifictions
   - for capped queue (with max. one item in it)
-}


neverDuplicatesIdsTest : Test
neverDuplicatesIdsTest =
    ArchitectureTest.invariantTest
        "The queue never contains duplicate IDs"
        app
    <|
        \_ _ finalModel ->
            finalModel
                |> Notification.Queue.toList
                |> List.map (.id >> Notification.Queue.idToString)
                |> Dict.frequencies
                |> Dict.values
                |> List.all (\count -> count == 1)
                |> Expect.equal True


removeHidingRemovesNotificationsUnderThatTimestampTest : Test
removeHidingRemovesNotificationsUnderThatTimestampTest =
    ArchitectureTest.msgTest
        "RemoveHiding removes all hiding notifications"
        app
        (Fuzz.constant RemoveHiding)
    <|
        \_ msg_ finalModel ->
            case msg_ of
                RemoveHiding ->
                    finalModel
                        |> Notification.Queue.toList
                        |> List.all (.notification >> Notification.isHiding >> not)
                        |> Expect.equal True

                _ ->
                    Expect.fail "Test generated unexpected Msg"



-- HELPERS


app : TestedApp (NotificationQueue msg) (Msg msg)
app =
    { model = ConstantModel Notification.Queue.empty
    , update = UpdateWithoutCmds update
    , msgFuzzer = msg
    , modelToString = modelToString
    , msgToString = msgToString
    }


type Msg msg
    = -- ignoring Notification.Queue.InnerMsg here - it's only for `view`
      Enqueue (Notification msg)
    | DismissId NotificationId
    | StartHiding NotificationId
    | RemoveHiding


update : Msg msg -> NotificationQueue msg -> NotificationQueue msg
update msg_ model =
    case msg_ of
        Enqueue notification_ ->
            model
                |> Notification.Queue.enqueue notification_
                |> Tuple.first

        DismissId id ->
            model
                |> Notification.Queue.update (Notification.Queue.DismissId id)
                |> (\( queue, _, _ ) -> queue)

        StartHiding id ->
            model
                |> Notification.Queue.update (Notification.Queue.StartHiding id)
                |> (\( queue, _, _ ) -> queue)

        RemoveHiding ->
            model
                |> Notification.Queue.update Notification.Queue.RemoveHiding
                |> (\( queue, _, _ ) -> queue)


modelToString : NotificationQueue msg -> String
modelToString model =
    Debug.toString model


msgToString : Msg msg -> String
msgToString msg_ =
    Debug.toString msg_


msg : Fuzzer (Msg msg)
msg =
    Fuzz.oneOf
        [ notification |> Fuzz.map Enqueue
        , Fuzz.intRange 0 10 |> Fuzz.map (Generic >> DismissId)
        , Fuzz.intRange 0 10 |> Fuzz.map (Generic >> StartHiding)
        , Fuzz.constant RemoveHiding
        ]


notification : Fuzzer (Notification msg)
notification =
    Fuzz.oneOf
        [ Fuzz.constant (Notification.create Success Html.nothing)
        , Fuzz.constant (Notification.create Warning Html.nothing)
        , Fuzz.constant (Notification.create Error Html.nothing)
        ]
