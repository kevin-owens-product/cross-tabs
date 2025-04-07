module Analytics.Common exposing
    ( commaSeparated
    , list
    )

import Json.Encode as Encode exposing (Value)


list : (a -> String) -> List a -> Value
list toString =
    Encode.list (Encode.string << toString)


commaSeparated : (a -> String) -> List a -> Value
commaSeparated toString =
    List.map toString
        >> String.join ","
        >> Encode.string
