module XB2.Share.Data.Id exposing
    ( Id(..), unwrap, fromString
    , IdDict, emptyDict, dictFromList
    , IdSet, emptySet, singletonSet, setFromList
    , decode, decodeFromInt, decodeFromStringOrInt
    , encode, unsafeEncodeAsInt, encodeSet
    )

{-|

@docs Id, unwrap, fromString

@docs IdDict, emptyDict, dictFromList

@docs IdSet, emptySet, singletonSet, setFromList

@docs decode, decodeFromInt, decodeFromStringOrInt

@docs encode, unsafeEncodeAsInt, encodeSet

-}

import Dict.Any exposing (AnyDict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Set.Any exposing (AnySet)
import XB2.Share.Gwi.Json.Encode exposing (encodeStringAsInt)


type Id a
    = Id String


fromString : String -> Id a
fromString =
    Id


unwrap : Id a -> String
unwrap (Id string) =
    string


decode : Decoder (Id a)
decode =
    Decode.map Id Decode.string


decodeFromInt : Decoder (Id a)
decodeFromInt =
    Decode.map (Id << String.fromInt) Decode.int


decodeFromStringOrInt : Decoder (Id a)
decodeFromStringOrInt =
    Decode.oneOf
        [ decode
        , decodeFromInt
        ]


encode : Id a -> Value
encode (Id string) =
    Encode.string string


unsafeEncodeAsInt : Id a -> Value
unsafeEncodeAsInt =
    encodeStringAsInt << unwrap



-- AnyDict


type alias IdDict tag v =
    AnyDict String (Id tag) v


emptyDict : IdDict tag v
emptyDict =
    Dict.Any.empty unwrap


dictFromList : List ( Id tag, v ) -> IdDict tag v
dictFromList =
    Dict.Any.fromList unwrap



-- AnySet


type alias IdSet tag =
    AnySet String (Id tag)


emptySet : IdSet tag
emptySet =
    Set.Any.empty unwrap


singletonSet : Id tag -> IdSet tag
singletonSet item =
    Set.Any.singleton item unwrap


setFromList : List (Id tag) -> IdSet tag
setFromList =
    Set.Any.fromList unwrap


encodeSet : IdSet tag -> Encode.Value
encodeSet set =
    Set.Any.encode encode set
