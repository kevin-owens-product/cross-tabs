module PluralTest exposing (pluralTest)

import Expect
import Plural
import Test exposing (..)


pluralTest : Test
pluralTest =
    describe "Plural"
        [ describe "Plural.fromInt"
            [ test "1 Query" <|
                \() ->
                    Plural.fromInt 1 "Query" |> Expect.equal "Query"
            , test "2 Queries" <|
                \() ->
                    Plural.fromInt 2 "Query" |> Expect.equal "Queries"
            ]
        , describe "Plural.fromFloat"
            [ test "this 1.0" <|
                \() ->
                    Plural.fromFloat 1.0 "this" |> Expect.equal "this"
            , test "these 1.5" <|
                \() ->
                    Plural.fromFloat 1.5 "this" |> Expect.equal "these"
            ]
        ]
