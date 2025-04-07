module XB2.Utils.Set.Any exposing (areDifferent)

import Set.Any as AnySet


{-| Check if two `AnySet`s are different in some of its key/value pairs.
-}
areDifferent :
    (t -> comparable)
    -> AnySet.AnySet comparable t
    -> AnySet.AnySet comparable t
    -> Bool
areDifferent toComparable set1 set2 =
    not (AnySet.equal (AnySet.diff set1 set2) (AnySet.empty toComparable))
