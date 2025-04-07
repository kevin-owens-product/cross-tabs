module XB2.Share.Dialog.ErrorDisplay exposing (ErrorDisplay)

import Html exposing (Html)


type alias ErrorDisplay msg =
    { title : String
    , body : Html msg
    , details : List String
    , errorId : Maybe String
    }
