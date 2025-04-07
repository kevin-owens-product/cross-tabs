module XB2.Data.Audience.Folder exposing
    ( Flag
    , Folder
    , Id
    , StringifiedFlag
    , StringifiedId
    , decoder
    , encode
    , idDecoder
    , idToString
    )

import Iso8601
import Json.Decode as Decode
import Json.Encode as Encode
import Set.Any as AnySet
import Time
import UUID
import XB2.Share.Gwi.Json.Decode as Decode


type Id
    = FolderId UUID.UUID


type alias StringifiedId =
    String


idToString : Id -> StringifiedId
idToString (FolderId id) =
    UUID.toString id


encodeId : Id -> Encode.Value
encodeId (FolderId id) =
    UUID.toValue id


idDecoder : Decode.Decoder Id
idDecoder =
    Decode.map FolderId UUID.jsonDecoder


type Flag
    = -- Means that the user owns the entity
      Authored
      -- Means that GWI shared the entity to others
    | Curated
      {- We use this constructor for forward compatibility with new flags. There's no
         `"unknown"` flag, this just wraps anything that does not fall into the previous
         two values. This way we can still convert them to `String` and encode in case
         backend does some tests.
      -}
    | UnknownFlag String


type alias StringifiedFlag =
    String


flagDecoder : Decode.Decoder Flag
flagDecoder =
    Decode.map flagFromString Decode.string


encodeFlag : Flag -> Encode.Value
encodeFlag =
    flagToString >> Encode.string


flagToString : Flag -> StringifiedFlag
flagToString flag =
    case flag of
        Authored ->
            "authored"

        Curated ->
            "curated"

        UnknownFlag str ->
            str


flagFromString : String -> Flag
flagFromString str =
    case str of
        "authored" ->
            Authored

        "curated" ->
            Curated

        anotherFlag ->
            UnknownFlag anotherFlag


type alias Folder =
    { id : Id
    , name : String
    , position : Float
    , flags : AnySet.AnySet StringifiedFlag Flag
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


decoder : Decode.Decoder Folder
decoder =
    Decode.map6 Folder
        (Decode.field "id" idDecoder)
        (Decode.field "name" Decode.string)
        (Decode.field "position" Decode.float)
        (Decode.field "flags" (AnySet.decode flagToString flagDecoder))
        (Decode.field "created_at" Decode.unixIso8601Decoder)
        (Decode.field "updated_at" Decode.unixIso8601Decoder)


encode : Folder -> Encode.Value
encode folder =
    Encode.object
        [ ( "id", encodeId folder.id )
        , ( "name", Encode.string folder.name )
        , ( "position", Encode.float folder.position )
        , ( "flags", AnySet.encode encodeFlag folder.flags )
        , ( "created_at", Encode.string (Iso8601.fromTime folder.createdAt) )
        , ( "updated_at", Encode.string (Iso8601.fromTime folder.updatedAt) )
        ]
