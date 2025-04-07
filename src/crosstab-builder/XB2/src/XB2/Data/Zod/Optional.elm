module XB2.Data.Zod.Optional exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| A value that might be present or not (`undefined`). Useful in JS intercom.

It's similar to `Maybe`.

-}
type Optional a
    = Present a
    | Undefined


decodeField : String -> Decoder a -> Decoder (Optional a)
decodeField fieldName decoder =
    let
        finishDecoding : Decode.Value -> Decoder (Optional a)
        finishDecoding json =
            case Decode.decodeValue (Decode.field fieldName Decode.value) json of
                Ok _ ->
                    Decode.map Present (Decode.field fieldName decoder)

                Err _ ->
                    Decode.succeed Undefined
    in
    Decode.value
        |> Decode.andThen finishDecoding


map : (a -> b) -> Optional a -> Optional b
map f optional =
    case optional of
        Present value ->
            Present (f value)

        Undefined ->
            Undefined


toMaybe : Optional a -> Maybe a
toMaybe optional =
    case optional of
        Present value ->
            Just value

        Undefined ->
            Nothing


fromMaybe : Maybe a -> Optional a
fromMaybe maybe =
    case maybe of
        Just value ->
            Present value

        Nothing ->
            Undefined


addFieldsToKeyValuePairs :
    List ( String, Optional Encode.Value )
    -> List ( String, Encode.Value )
    -> List ( String, Encode.Value )
addFieldsToKeyValuePairs optionalFields keyValuePairs =
    List.filterMap
        (\( fieldName, optionalValue ) ->
            case optionalValue of
                Present value ->
                    Just ( fieldName, value )

                Undefined ->
                    Nothing
        )
        optionalFields
        ++ keyValuePairs
