module XB2.Data.Zod.Nullish exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| A value that might be present or not (`undefined`). If it is present it may also be
a `null`. Useful in JS intercom.

`Maybe` was not enough to handle these cases, so we found it useful to have a type like
this.

-}
type Nullish a
    = Present a
    | Null
    | Undefined


decodeField : String -> Decoder a -> Decoder (Nullish a)
decodeField fieldName decoder =
    let
        finishDecoding : Decode.Value -> Decoder (Nullish a)
        finishDecoding json =
            case Decode.decodeValue (Decode.field fieldName Decode.value) json of
                Ok _ ->
                    Decode.field fieldName <|
                        Decode.oneOf
                            [ Decode.null Null
                            , decoder
                                |> Decode.map Present
                            ]

                Err _ ->
                    Decode.succeed Undefined
    in
    Decode.value
        |> Decode.andThen finishDecoding


map : (a -> b) -> Nullish a -> Nullish b
map f nullish =
    case nullish of
        Present value ->
            Present (f value)

        Null ->
            Null

        Undefined ->
            Undefined


toMaybe : Nullish a -> Maybe a
toMaybe nullish =
    case nullish of
        Present value ->
            Just value

        Null ->
            Nothing

        Undefined ->
            Nothing


fromMaybe : Maybe a -> Nullish a
fromMaybe maybe =
    case maybe of
        Just value ->
            Present value

        Nothing ->
            Null


addFieldsToKeyValuePairs :
    List ( String, Nullish Encode.Value )
    -> List ( String, Encode.Value )
    -> List ( String, Encode.Value )
addFieldsToKeyValuePairs nullishFields keyValuePairs =
    List.filterMap
        (\( fieldName, nullishValue ) ->
            case nullishValue of
                Present value ->
                    Just ( fieldName, value )

                Null ->
                    Just ( fieldName, Encode.null )

                Undefined ->
                    Nothing
        )
        nullishFields
        ++ keyValuePairs
