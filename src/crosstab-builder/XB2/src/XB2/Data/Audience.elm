module XB2.Data.Audience exposing
    ( Audience
    , Id
    , StringifiedId
    , decoder
    , defaultName
    , encodeId
    , idDecoder
    , idToString
    , toTypeString
    )

import Json.Decode as Decode
import Json.Decode.Extra as Decode
import Json.Encode as Encode
import Set.Any as AnySet
import Time
import UUID
import XB2.Data.Audience.Expression as Expression
import XB2.Data.Audience.Flag as Flag
import XB2.Data.Audience.Folder as Folder
import XB2.Data.Zod.Nullable as Nullable
import XB2.Share.Gwi.Json.Decode as Decode


type Id
    = AudienceId UUID.UUID


type alias StringifiedId =
    String


idToString : Id -> String
idToString (AudienceId id) =
    UUID.toString id


idDecoder : Decode.Decoder Id
idDecoder =
    Decode.map AudienceId UUID.jsonDecoder


encodeId : Id -> Encode.Value
encodeId (AudienceId id) =
    UUID.toValue id


{-| An `Audience` is a wrapper structure containing an `Expression`, which is a logical
combination of attributes that represent a group of users and its interests/features
(e.g. an `Audience` can have an `Expression` that scopes _'male users **AND** people
between 19-25 years old **OR** people between 26-31 years old'_).

This is an Elm-ish definition of [platform2-react-ui-components](https://github.com/GlobalWebIndex/platform2-react-ui-components/blob/master/src/logic/audiences/audienceBrowserLeft/types/server.ts#L51)
`CalculationAudience`.

-}
type alias Audience =
    { -- These fields here are often enough to identify an audience --
      id : Id
    , name : String
    , expression : Expression.Expression

    ------------------------------------------------------------------
    , shared : Bool
    , flags : AnySet.AnySet Flag.StringifiedFlag Flag.Flag

    -- Not using it
    -- , datasets : AnySet.AnySet Dataset.StringifiedCode Dataset.Code
    , -- 'folder_id'
      folderId : Nullable.Nullable Folder.Id
    , -- 'created_at'
      createdAt : Time.Posix
    , -- 'updated_at'
      updatedAt : Time.Posix

    -- Not using it
    -- , -- 'user_id'
    --   userId : Nullable.Nullable User.Id
    -- Not using it
    -- , -- 'times_used'
    --   timesUsed : Optional.Optional Int
    -- Not using it
    -- , permissions : Permissions
    }


flagsDecoder : Decode.Decoder (AnySet.AnySet Flag.StringifiedFlag Flag.Flag)
flagsDecoder =
    AnySet.decode Flag.toString Flag.decoder


{-| Checks if an `Audience` was shared by GWI to others.
-}
isCurated : Audience -> Bool
isCurated audience =
    AnySet.member Flag.CuratedAudience audience.flags


{-| Checks if an `Audience` is owned by the User.
-}
isAuthored : Audience -> Bool
isAuthored audience =
    AnySet.member Flag.AuthoredAudience audience.flags


toTypeString : Audience -> String
toTypeString audience =
    if isCurated audience then
        "Default Audiences"

    else if isAuthored audience then
        "My Audiences"

    else
        {- We'd normally use `audience.shared` JSON field here but there's no
           other possibility than:
        -}
        "Shared Audiences"


decoder : Decode.Decoder Audience
decoder =
    Decode.succeed Audience
        |> Decode.andMap (Decode.field "id" idDecoder)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "expression" Expression.decoder)
        |> Decode.andMap (Decode.field "shared" Decode.bool)
        |> Decode.andMap (Decode.field "flags" flagsDecoder)
        |> Decode.andMap (Nullable.decodeField "folder_id" Folder.idDecoder)
        |> Decode.andMap (Decode.field "created_at" Decode.unixIso8601Decoder)
        |> Decode.andMap (Decode.field "updated_at" Decode.unixIso8601Decoder)


defaultName : String
defaultName =
    "All Internet Users"
