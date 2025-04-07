module Data.SimpleRESTTest exposing (simpleRoutesTest)

import Data.SimpleREST
import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (..)


simpleRoutesTest : Test
simpleRoutesTest =
    describe "Data.SimpleREST.simpleRoutes"
        [ fuzz3
            nonemptyStringWithoutSlashes
            nonemptyStringWithoutSlashes
            nonemptyStringWithoutSlashes
            "single doesn't contain double slash"
          <|
            \host name id ->
                Data.SimpleREST.simpleRoutes host name (Data.SimpleREST.Fetch id)
                    |> String.contains "//"
                    |> Expect.equal False
                    |> Expect.onFail "single shouldn't contain double slash"
        , fuzz2
            nonemptyStringWithoutSlashes
            nonemptyStringWithoutSlashes
            "collection doesn't contain double slash"
          <|
            \host name ->
                Data.SimpleREST.simpleRoutes host name Data.SimpleREST.Create
                    |> String.contains "//"
                    |> Expect.equal False
                    |> Expect.onFail "collection shouldn't contain double slash"
        ]


nonemptyStringWithoutSlashes : Fuzzer String
nonemptyStringWithoutSlashes =
    Fuzz.string
        |> Fuzz.map
            (\string ->
                let
                    withoutSlashes : String
                    withoutSlashes =
                        String.replace "/" "a" string
                in
                if String.isEmpty withoutSlashes then
                    "a"

                else
                    withoutSlashes
            )
