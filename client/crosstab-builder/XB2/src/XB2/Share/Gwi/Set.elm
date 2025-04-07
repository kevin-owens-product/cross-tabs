module XB2.Share.Gwi.Set exposing (toggle)

import Set exposing (Set)


toggle : comparable -> Set comparable -> Set comparable
toggle x xs =
    if Set.member x xs then
        Set.remove x xs

    else
        Set.insert x xs
