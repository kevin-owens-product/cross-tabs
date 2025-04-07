module Data.Core.DatapointsSort exposing
    ( DatapointsSort(..)
    , decoder
    , encodeForQuery
    )

{-| Unfortunately CB/Dashboard queries use different string format from Dashboard
widgets. So we have different string representations here too.
Note everything defaults to Default.
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type DatapointsSort
    = Descending
    | Ascending
    | Alphabetical
    | {- This was named Alphabetical but it was a misnomer:

             sortBy Alphabetical [Male, Female]
             --> [Male, Female]

         Yup. So let's call it Default instead.
         Of course, some Core endpoints still need "alphabetical"-like strings,
         so that's what we encode to.
      -}
      Default


toStringForQuery : DatapointsSort -> String
toStringForQuery sort =
    case sort of
        Ascending ->
            "asc"

        Descending ->
            "desc"

        Default ->
            "sort-alphabetical"

        Alphabetical ->
            "alphabetical"


fromString : String -> DatapointsSort
fromString string =
    case string of
        "desc" ->
            Descending

        "asc" ->
            Ascending

        "alphabetical-real" ->
            Alphabetical

        _ ->
            Default


decoder : Decoder DatapointsSort
decoder =
    Decode.map fromString Decode.string


encodeForQuery : DatapointsSort -> Encode.Value
encodeForQuery sort =
    Encode.string <| toStringForQuery sort
