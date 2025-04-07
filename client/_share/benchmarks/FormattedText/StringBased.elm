module FormattedText.StringBased exposing
    ( FormattedText
    , Part(..)
    , Protocol(..)
    , parse
    , toList
    )

{-| Implementation using left to right parser with very super limited backtracking
-}


type Protocol
    = Http
    | Https


type Part
    = Text String
    | Link Protocol String


type alias FormattedText =
    List Part


isWhitespace : Char -> Bool
isWhitespace c =
    c == ' ' || c == '\t' || c == '\n' || c == '\u{000D}'


parse : String -> FormattedText
parse str =
    parseHelp identity (Text "") str


parseHelp : (FormattedText -> FormattedText) -> Part -> String -> FormattedText
parseHelp f acc string =
    case String.uncons string of
        Nothing ->
            f [ acc ]

        Just ( char, rest ) ->
            case acc of
                Text s ->
                    let
                        endText i =
                            case String.dropRight i s of
                                "" ->
                                    identity

                                str ->
                                    (::) (Text str)
                    in
                    if String.right 7 s == "http://" then
                        parseHelp (f << endText 7) (Link Http <| String.fromChar char) rest

                    else if String.right 8 s == "https://" then
                        parseHelp (f << endText 8) (Link Https <| String.fromChar char) rest

                    else
                        parseHelp f (Text <| s ++ String.fromChar char) rest

                Link p url ->
                    if isWhitespace char then
                        parseHelp (f << (::) (Link p url)) (Text <| String.fromChar char) rest

                    else
                        parseHelp f (Link p <| url ++ String.fromChar char) rest


toList : (String -> a) -> (Protocol -> String -> a) -> FormattedText -> List a
toList textFn linkFn =
    List.map
        (\part_ ->
            case part_ of
                Text t ->
                    textFn t

                Link p url ->
                    linkFn p url
        )
