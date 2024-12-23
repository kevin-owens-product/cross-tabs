module XB2.Share.Search exposing
    ( filter
    , highlight
    , matches
    )

import XB2.Share.Gwi.List as List


sanitizedMatch : String -> String -> Bool
sanitizedMatch needle =
    String.contains (String.toLower needle) << String.toLower


match_ : (a -> String) -> String -> a -> Bool
match_ getter needle =
    sanitizedMatch needle << getter


checkEmpty : String -> (a -> a) -> (a -> a)
checkEmpty needle fc =
    if String.isEmpty needle then
        identity

    else
        fc


filter : (a -> String) -> String -> List a -> List a
filter getter needle =
    checkEmpty needle <| List.filter (match_ getter needle)


matches : (a -> String) -> String -> a -> Bool
matches =
    match_


highlight : { match : String -> a, rest : String -> a } -> String -> String -> List a
highlight { match, rest } term source =
    let
        needle =
            String.toLower term

        termLength =
            String.length term

        tokens : List { length : Int, isMatch : Bool }
        tokens =
            String.toLower source
                |> String.split needle
                |> List.fastConcatMap
                    (\str ->
                        [ { length = String.length str, isMatch = False }
                        , { length = termLength, isMatch = True }
                        ]
                    )

        view : { length : Int, isMatch : Bool } -> ( List a, String ) -> ( List a, String )
        view { length, isMatch } ( acc, src ) =
            let
                fn =
                    if isMatch then
                        match

                    else
                        rest

                substring =
                    String.left length src

                restOfString =
                    String.dropLeft length src
            in
            ( fn substring :: acc
            , restOfString
            )
    in
    List.foldl view ( [], source ) tokens
        |> Tuple.first
        |> List.reverse
