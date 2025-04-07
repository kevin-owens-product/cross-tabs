module XB2.Data.Zod.Nullable exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| A value that might be present or `null`. Useful in JS intercom.

It's similar to `Maybe`.

-}
type Nullable a
    = Present a
    | Null


decodeField : String -> Decoder a -> Decoder (Nullable a)
decodeField fieldName decoder =
    Decode.field fieldName <|
        Decode.oneOf
            [ Decode.null Null
            , decoder
                |> Decode.map Present
            ]


map : (a -> b) -> Nullable a -> Nullable b
map f nullable =
    case nullable of
        Present value ->
            Present (f value)

        Null ->
            Null


toMaybe : Nullable a -> Maybe a
toMaybe nullable =
    case nullable of
        Present value ->
            Just value

        Null ->
            Nothing


fromMaybe : Maybe a -> Nullable a
fromMaybe maybe =
    case maybe of
        Just value ->
            Present value

        Nothing ->
            Null


addFieldsToKeyValuePairs :
    List ( String, Nullable Encode.Value )
    -> List ( String, Encode.Value )
    -> List ( String, Encode.Value )
addFieldsToKeyValuePairs nullableFields keyValuePairs =
    List.filterMap
        (\( fieldName, nullableValue ) ->
            case nullableValue of
                Present value ->
                    Just ( fieldName, value )

                Null ->
                    Nothing
        )
        nullableFields
        ++ keyValuePairs
