port module Ports exposing (openChatWithErrorId, setNewAccessToken)

import Json.Encode as Encode


port openChatWithErrorId : Encode.Value -> Cmd msg


port setNewAccessToken : (String -> msg) -> Sub msg
