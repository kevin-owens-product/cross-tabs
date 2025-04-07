module FormattedText.ParserBased exposing
    ( FormattedText
    , Part(..)
    , Protocol(..)
    , parse
    , toList
    )

{-| This is the second implementation of parser version.
revised version of original Marek's implementation
that is using lists and avoid CSP style.

it's negligibly slower compare to original Marek's parser.

-}

import Gwi.List as List
import List.Extra as List
import Parser as P exposing ((|.), (|=), Parser)


type Protocol
    = Http
    | Https


type Part
    = Text String
    | Link Protocol String


type alias FormattedText =
    List Part


protocol : Parser Protocol
protocol =
    P.oneOf
        [ P.map (always Http) (P.token "http://")
        , P.map (always Https) (P.token "https://")
        ]


restOfLink : Parser String
restOfLink =
    P.getChompedString (P.chompWhile (not << isWhitespace))


protocolToString : Protocol -> String
protocolToString protocol_ =
    case protocol_ of
        Http ->
            "http://"

        Https ->
            "https://"


link : Parser Part
link =
    P.succeed Tuple.pair
        |= protocol
        |= restOfLink
        |> P.map
            (\( protocol_, restOfLink_ ) ->
                if String.isEmpty restOfLink_ then
                    Text (protocolToString protocol_)

                else
                    Link protocol_ restOfLink_
            )


isWhitespace : Char -> Bool
isWhitespace c =
    c == ' ' || c == '\t' || c == '\n' || c == '\u{000D}'


text : Parser Part
text =
    P.oneOf
        [ P.getChompedString (P.chompUntilEndOr "http")
            |> P.andThen
                (\string ->
                    if String.isEmpty string then
                        P.problem "empty text"

                    else
                        P.succeed (Text string)
                )
        , P.map (always (Text "http")) (P.token "http")
        ]


part : Parser Part
part =
    P.oneOf
        [ link
        , text
        ]


isText : Part -> Bool
isText part_ =
    case part_ of
        Text _ ->
            True

        Link _ _ ->
            False


areSame : Part -> Part -> Bool
areSame a b =
    isText a == isText b


textString : Part -> Maybe String
textString part_ =
    case part_ of
        Text text_ ->
            Just text_

        Link _ _ ->
            Nothing


mergeTexts : List Part -> List Part
mergeTexts parts =
    parts
        |> List.groupWhile areSame
        |> List.fastConcatMap
            (\( first, rest ) ->
                let
                    all =
                        first :: rest
                in
                if isText first then
                    List.filterMap textString all
                        |> String.concat
                        |> Text
                        |> List.singleton

                else
                    all
            )


formattedText : Parser FormattedText
formattedText =
    manyWith (P.succeed ()) part
        |> P.map mergeTexts


{-| Taken from Punie/elm-parser-extras, made to work with arbitrary separator
-}
manyWith : Parser () -> Parser a -> Parser (List a)
manyWith spaces p =
    P.loop [] (manyHelp spaces p)


{-| Taken from Punie/elm-parser-extras, made to work with arbitrary separator
-}
manyHelp : Parser () -> Parser a -> List a -> Parser (P.Step (List a) (List a))
manyHelp spaces p vs =
    P.oneOf
        [ P.succeed (\v -> P.Loop (v :: vs))
            |= p
            |. spaces
        , P.succeed ()
            |> P.map (always (P.Done (List.reverse vs)))
        ]


parse : String -> FormattedText
parse s =
    P.run formattedText s
        |> Result.withDefault [ Text "" ]


toList : (String -> a) -> (Protocol -> String -> a) -> FormattedText -> List a
toList textFn linkFn =
    List.map
        (\part_ ->
            case part_ of
                Text text_ ->
                    textFn text_

                Link protocol_ restOfLink_ ->
                    linkFn protocol_ restOfLink_
        )
