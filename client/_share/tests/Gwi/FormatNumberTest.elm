module Gwi.FormatNumberTest exposing
    ( formatNumberTest
    , formatTVIntTest
    , formatTVTest
    , formatToDecimalsTest
    )

-- Libs

import Expect
import Gwi.FormatNumber as FormatNumber
import Test exposing (..)


formatNumberTest : Test
formatNumberTest =
    let
        dataSet =
            [ { number = 0, expect = "0" }
            , { number = 999, expect = "999" }
            , { number = 100000, expect = "100k" }
            , { number = 100000000, expect = "100M" }
            , { number = 2345, expect = "2.3k" }
            , { number = 999999, expect = "1000k" }
            ]
    in
    describe "Gwi.FormatNumber.formatNumber" <|
        List.map
            (\testCase ->
                test (String.fromFloat testCase.number ++ " formatted to be " ++ testCase.expect) <|
                    \() ->
                        FormatNumber.formatNumber testCase.number
                            |> Expect.equal testCase.expect
            )
            dataSet


formatTVTest : Test
formatTVTest =
    let
        dataSet =
            [ { number = 0.7189506874253725, expect = "0.7" }
            , { number = 1.45823885472525, expect = "1.5" }
            , { number = 5.876666666666667, expect = "5.9" }
            , { number = 8.569583669602052, expect = "8.6" }
            , { number = 191.36250640680856, expect = "191.4" }
            , { number = 270.0126904315268, expect = "270.0" }
            , { number = 3279514.97, expect = "3.3M" }
            , { number = 2589790026.565486, expect = "2.6B" }
            ]
    in
    describe "Gwi.FormatNumber.formatTV" <|
        List.map
            (\testCase ->
                test (String.fromFloat testCase.number ++ " formatted to be " ++ testCase.expect) <|
                    \() ->
                        FormatNumber.formatTV testCase.number
                            |> Expect.equal testCase.expect
            )
            dataSet


formatTVIntTest : Test
formatTVIntTest =
    let
        dataSet =
            [ { number = 161, expect = "161" }
            , { number = 15039, expect = "15k" }
            , { number = 57037, expect = "57k" }
            , { number = 147632, expect = "147.6k" }
            , { number = 558057, expect = "558.1k" }
            , { number = 666188, expect = "666.2k" }
            , { number = 38269245, expect = "38.3M" }
            ]
    in
    describe "Gwi.FormatNumber.formatTVInt" <|
        List.map
            (\testCase ->
                test (String.fromInt testCase.number ++ " formatted to be " ++ testCase.expect) <|
                    \() ->
                        FormatNumber.formatTVInt testCase.number
                            |> Expect.equal testCase.expect
            )
            dataSet


formatToDecimalsTest : Test
formatToDecimalsTest =
    let
        dataSet : List { number : Float, expect : String, config : { decimals : Int, keepZeroValues : Bool } }
        dataSet =
            [ { number = 161, expect = "161.00", config = { decimals = 2, keepZeroValues = True } }
            , { number = 161, expect = "161", config = { decimals = 2, keepZeroValues = False } }
            , { number = 147632, expect = "147.6k", config = { decimals = 1, keepZeroValues = False } }
            , { number = 147632, expect = "147.6320k", config = { decimals = 4, keepZeroValues = True } }
            , { number = 147000, expect = "147k", config = { decimals = 2, keepZeroValues = False } }
            , { number = 147000, expect = "147.000k", config = { decimals = 3, keepZeroValues = True } }
            ]
    in
    describe "Gwi.FormatNumber.formatToDecimals" <|
        List.indexedMap
            (\i testCase ->
                test ("#" ++ String.fromInt i ++ ": " ++ String.fromFloat testCase.number ++ " formatted to be " ++ testCase.expect) <|
                    \() ->
                        FormatNumber.formatToDecimals testCase.config testCase.number
                            |> Expect.equal testCase.expect
            )
            dataSet
