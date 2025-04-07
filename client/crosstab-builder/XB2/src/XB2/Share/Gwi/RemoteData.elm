module XB2.Share.Gwi.RemoteData exposing (traverse)

import RemoteData exposing (RemoteData(..))


traverse : (a -> RemoteData x b) -> List a -> RemoteData x (List b)
traverse fn list =
    sequence (List.map fn list)


sequence : List (RemoteData x a) -> RemoteData x (List a)
sequence list =
    List.foldr
        (RemoteData.map2 (::))
        (Success [])
        list
