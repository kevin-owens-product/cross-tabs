module XB2.Utils.AssocSet exposing (decode, encode)

import AssocSet
import Json.Decode as Decode
import Json.Encode as Encode


encode : (a -> Encode.Value) -> AssocSet.Set a -> Encode.Value
encode encoder set =
    Encode.list encoder (AssocSet.toList set)


decode : Decode.Decoder a -> Decode.Decoder (AssocSet.Set a)
decode decoder =
    Decode.list decoder
        |> Decode.map AssocSet.fromList
