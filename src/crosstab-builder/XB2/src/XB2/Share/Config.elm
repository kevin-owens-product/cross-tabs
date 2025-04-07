module XB2.Share.Config exposing
    ( Flags
    , Referrer(..)
    , combinePrefixAndFeature
    , decode
    )

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Extra as Decode
import Maybe.Extra as Maybe
import XB2.Share.Config.Main exposing (Stage)
import XB2.Share.Data.User as User exposing (User)
import XB2.Share.Permissions exposing (Can)


{-| Values gotten from platform2-kernel.
-}
type alias Flags =
    { token : String -- TODO: Wrap this inside an opaque type
    , user : User
    , env : Stage
    , feature : Maybe String
    , pathPrefix : Maybe String
    , can : Can
    , helpMode : Bool
    , supportChatVisible : Bool
    , revision : Maybe String
    , referrer : Referrer
    , platform2Url : String
    }


{-| We can later expand this to P1 / Empty / ... if some functionality requires it
So far this is only needed for disabling the "sticky P2" banner if we just came to P1 from P2.
-}
type Referrer
    = Platform2Referrer
    | OtherReferrer


decoder : Decoder Flags
decoder =
    Decode.succeed Flags
        |> Decode.andMap (Decode.field "token" Decode.string)
        |> Decode.andMap (Decode.field "user" User.decoder)
        |> Decode.andMap (Decode.field "env" XB2.Share.Config.Main.envDecoder)
        |> Decode.andMap (Decode.field "feature" (Decode.maybe Decode.string))
        |> Decode.andMap (Decode.optionalNullableField "pathPrefix" Decode.string)
        |> Decode.andMap (Decode.map XB2.Share.Permissions.fromUser (Decode.field "user" User.decoder))
        |> Decode.andMap (Decode.field "helpMode" Decode.bool)
        |> Decode.andMap (Decode.succeed False)
        |> Decode.andMap (Decode.optionalNullableField "revision" Decode.string)
        |> Decode.andMap
            (Decode.field "platform2Url" Decode.string
                |> Decode.andThen (\p2Url -> Decode.field "referrer" (referrerDecoder p2Url))
            )
        |> Decode.andMap (Decode.field "platform2Url" Decode.string)


referrerDecoder : String -> Decoder Referrer
referrerDecoder p2Url =
    Decode.string
        |> Decode.map
            (\url ->
                if String.startsWith p2Url url then
                    Platform2Referrer

                else
                    OtherReferrer
            )


decode : Value -> Result Decode.Error Flags
decode value =
    Decode.decodeValue decoder value


combinePrefixAndFeature : Flags -> Maybe String
combinePrefixAndFeature { feature, pathPrefix } =
    case Maybe.values [ feature, pathPrefix ] of
        [] ->
            Nothing

        values ->
            Just <| String.join "/" values
