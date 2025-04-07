module Gwi.AssocSet exposing (toggle)

import AssocSet as Set exposing (Set)


toggle : item -> Set item -> Set item
toggle item set =
    if Set.member item set then
        Set.remove item set

    else
        Set.insert item set
