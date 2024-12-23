module XB2.ColumnLabelTest exposing (fromIntTest)

import Expect
import Fuzz exposing (Fuzzer)
import Maybe.Extra as Maybe
import Random
import Test exposing (..)
import XB2.ColumnLabel as ColumnLabel
import XB2.Share.Gwi.List as List


negativeNumberFuzzer : Fuzzer Int
negativeNumberFuzzer =
    Fuzz.intRange Random.minInt -1


nonNegativeNumberFuzzer : Fuzzer Int
nonNegativeNumberFuzzer =
    Fuzz.intRange 0 Random.maxInt


fromIntTest : Test
fromIntTest =
    let
        runTest : ( Int, Maybe String ) -> Test
        runTest ( input, output ) =
            test (String.fromInt input ++ " -> " ++ Debug.toString output) <|
                \() ->
                    input
                        |> ColumnLabel.fromInt
                        |> Expect.equal output
    in
    describe "XB2.ColumnLabel.fromInt" <|
        List.fastConcat
            [ [ fuzz negativeNumberFuzzer "Negative numbers -> Nothing" <|
                    \negativeInt ->
                        negativeInt
                            |> ColumnLabel.fromInt
                            |> Expect.equal Nothing
              , fuzz nonNegativeNumberFuzzer "Positive numbers -> Just uppercase letters" <|
                    \nonNegativeInt ->
                        nonNegativeInt
                            |> ColumnLabel.fromInt
                            |> Expect.all
                                [ Maybe.isJust
                                    >> Expect.equal True
                                    >> Expect.onFail "Should have been Just"
                                , Maybe.unwrap False (\str -> str == String.toUpper str)
                                    >> Expect.equal True
                                    >> Expect.onFail "Should have been uppercase"
                                , Maybe.unwrap False (String.all Char.isAlpha)
                                    >> Expect.equal True
                                    >> Expect.onFail "Should have only contained alpha characters"
                                ]
              ]
            , List.map runTest
                [ ( 0, Just "A" )
                , ( 1, Just "B" )
                , ( 2, Just "C" )

                --
                , ( 25, Just "Z" )
                , ( 26, Just "AA" )
                , ( 27, Just "AB" )

                --
                , ( 51, Just "AZ" )
                , ( 52, Just "BA" )
                , ( 53, Just "BB" )
                , ( 77, Just "BZ" )

                --
                , ( 701, Just "ZZ" )
                , ( 702, Just "AAA" )
                , ( 703, Just "AAB" )
                ]
            ]
