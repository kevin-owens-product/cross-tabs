module FormattedText exposing
    ( FormattedText
    , Part(..)
    , Protocol(..)
    , parse
    )

import List.Extra as List
import Regex exposing (Regex)


{-| Regex based parser for content containing links.
This is by far the fastest implementation we managed to come up with.
Given this is meant to run over whole collection during decoding and how simple
it is at this moment we choosed to use this fastest version.

see benchmars for other implementations and comparision

-}
urlRegex : Regex
urlRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromString "http(s)?://[^\\s]+"


type Protocol
    = Http
    | Https


type Part
    = Text String
    | Link Protocol String


type alias FormattedText =
    List Part


parse : String -> FormattedText
parse str =
    let
        textBetweenLinks =
            Regex.split urlRegex str
                |> List.map Text

        links =
            Regex.find urlRegex str
                |> List.map
                    (\{ match } ->
                        if String.startsWith "https://" match then
                            Link Https (String.dropLeft 8 match)

                        else
                            Link Http (String.dropLeft 7 match)
                    )

        emptyText part =
            case part of
                Text s ->
                    String.isEmpty s

                _ ->
                    False
    in
    List.interweave textBetweenLinks links
        |> List.filter (not << emptyText)
