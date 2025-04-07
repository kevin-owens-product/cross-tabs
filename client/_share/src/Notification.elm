module Notification exposing
    ( DisappearState(..)
    , Notification
    , NotificationType(..)
    , create
    , hidingTimeout
    , isHiding
    , setHiding
    )

import Html exposing (Html)


type DisappearState
    = -- Invisible state doesn't need to be here, we remove the item from the queue
      Visible
    | Hiding


type NotificationType
    = Success
    | Warning
    | Error


type alias Notification msg =
    { content : Html msg
    , notificationType : NotificationType
    , state : DisappearState
    , shouldPersist : Bool
    }



-- CONSTRUCTORS


create : NotificationType -> Html msg -> Notification msg
create notificationType content =
    { content = content
    , state = Visible
    , notificationType = notificationType
    , shouldPersist = False
    }



-- UPDATE


setHiding : Notification msg -> Notification msg
setHiding notification =
    { notification | state = Hiding }



-- PREDICATES


isHiding : Notification msg -> Bool
isHiding { state } =
    state == Hiding



-- VIEW
-- HELPERS


hidingTimeout : Float
hidingTimeout =
    1000
