module Search exposing
    ( filter
    , filterDictAny
    )

import Data.Id exposing (IdDict)
import Dict.Any


sanitizedMatch : String -> String -> Bool
sanitizedMatch needle =
    String.contains (String.toLower needle) << String.toLower


match_ : (a -> String) -> String -> a -> Bool
match_ getter needle =
    sanitizedMatch needle << getter


matchAny_ : (a -> List String) -> String -> a -> Bool
matchAny_ getter needle =
    List.any (sanitizedMatch needle) << getter


checkEmpty : String -> (a -> a) -> (a -> a)
checkEmpty needle fc =
    if String.isEmpty needle then
        identity

    else
        fc


filter : (a -> String) -> String -> List a -> List a
filter getter needle =
    checkEmpty needle <| List.filter (match_ getter needle)


filterDictAny : (a -> List String) -> String -> IdDict tag a -> IdDict tag a
filterDictAny getter needle =
    checkEmpty needle <| Dict.Any.filter <| Basics.always <| matchAny_ getter needle
