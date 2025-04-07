module Data.Id exposing
    ( Id(..), unwrap, fromString
    , IdDict, emptyDict, dictFromList
    , IdSet, emptySet, setFromList, keysToSet
    , decode, decodeFromInt, decodeFromStringOrInt
    , encode, encodeSet
    )

{-|

@docs Id, unwrap, fromString

@docs IdDict, emptyDict, dictFromList

@docs IdSet, emptySet, setFromList, keysToSet

@docs decode, decodeFromInt, decodeFromStringOrInt

@docs encode, encodeSet

-}

import Dict.Any exposing (AnyDict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Set.Any exposing (AnySet)


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


setFromList : List (Id tag) -> IdSet tag
setFromList =
    Set.Any.fromList unwrap


keysToSet : IdDict tag entity -> IdSet tag
keysToSet dict =
    dict
        |> Dict.Any.keys
        |> setFromList


encodeSet : IdSet tag -> Encode.Value
encodeSet set =
    Set.Any.encode encode set
