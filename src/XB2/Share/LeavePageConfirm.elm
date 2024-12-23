port module XB2.Share.LeavePageConfirm exposing (setConfirm)

import Json.Encode as Encode


port setConfirmMsgBeforeLeavePage : Maybe Encode.Value -> Cmd msg



{-
   --------------------------------
   !!! Please read before usage !!!
   --------------------------------
   This code and related JS behind port (ports/beforeunload-confirm.js)
   should be used only once for every specific route. It means only one place/module
   can pass state of confirmation via setConfirm, because of concurrency.
-}


leaveConfirmationMsg : String
leaveConfirmationMsg =
    "Leave page? Changes will be lost."


setConfirm : Bool -> Cmd msg
setConfirm shouldConfirmBeforeLeave =
    setConfirmMsgBeforeLeavePage <|
        if shouldConfirmBeforeLeave then
            Just <|
                Encode.object
                    [ ( "msg", Encode.string leaveConfirmationMsg ) ]

        else
            Nothing
