module XB2.Data.AudienceItemId exposing
    ( AudienceItemId
    , ComparableId
    , decoder
    , decoderWithoutField
    , encode
    , generateFromString
    , generateId
    , toComparable
    , toString
    , total
    , totalString
    )

{-| -}

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode
import Random exposing (Seed)
import UUID exposing (UUID)


{-| IDs hold an unique integer, so that we can have multiple "same"
AudienceItems. This means rows, columns and even bases.

Not really about order, more about uniqueness and identity. UUIDs would probably
be nicer, but ... side-effect-y :) (unless we want to hold the random Seed and
do UUID generation without side effects!).

The string is for communication with servers.

-}
type AudienceItemId
    = AudienceItemId String


type alias ComparableId =
    String


create : UUID -> AudienceItemId
create =
    AudienceItemId << UUID.toString


generateId : Seed -> ( AudienceItemId, Seed )
generateId seed =
    Random.step UUID.generator seed
        |> Tuple.mapFirst create


generateFromString : String -> Seed -> ( AudienceItemId, Seed )
generateFromString id seed =
    UUID.fromString id
        |> Result.map (\uuid -> ( create uuid, seed ))
        |> Result.withDefault (generateId seed)


toComparable : AudienceItemId -> String
toComparable =
    toString


decoderWithoutField : Decoder AudienceItemId
decoderWithoutField =
    Decode.succeed AudienceItemId
        |> Decode.andMap Decode.string


decoder : Decoder AudienceItemId
decoder =
    Decode.succeed AudienceItemId
        |> Decode.andMap (Decode.field "id" Decode.string)


encode : AudienceItemId -> Encode.Value
encode (AudienceItemId id) =
    Encode.object
        [ ( "id", Encode.string id )
        ]


toString : AudienceItemId -> String
toString (AudienceItemId id) =
    id


total : AudienceItemId
total =
    generateId (Random.initialSeed 0)
        |> Tuple.first


totalString : String
totalString =
    toString total
