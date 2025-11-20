module XB2.Data.AverageTest exposing
    ( averageDecodeAvgWithSuffixes
    , averageDecodeAvgWithoutSuffixes
    , averageEncodeAvgWithSuffixes
    , averageEncodeAvgWithoutSuffixes
    , averageSwitchesFromFloatNumberToHHmm
    , averageSwitchesFromHHmmToFloatNumber
    , averageTestFuzzEncoderDecoder
    , averageTimeFormatDecoderTests
    , averageTimeToStringATC3750
    , averageTimeToStringTests
    , encodeAverageTimeFormatTests
    )

import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (..)
import XB2.Data.Average as Average exposing (AverageTimeFormat(..))
import XB2.Share.Data.Id as Id
import XB2.Share.Data.Labels exposing (NamespaceAndQuestionCode, QuestionAndDatapointCode)


averageTimeToStringATC3750 : Test
averageTimeToStringATC3750 =
    Test.test "ATC-3750 - Round minutes correctly" <|
        \() ->
            Average.averageTimeToString HHmm 1.01
                {- because 1.01 hours is 01:00:36 but we don't show seconds, so
                   we need to round minutes, not seconds.
                -}
                |> Expect.equal "01:01"


averageTimeToStringTests : Test
averageTimeToStringTests =
    Test.describe "Average averageTimeToString"
        [ Test.test "Converts FloatNumber to string" <|
            \() ->
                Average.averageTimeToString FloatNumber 1.25
                    |> Expect.equal "1.25"
        , Test.test "Converts FloatNumber to string with no decimals" <|
            \() ->
                Average.averageTimeToString FloatNumber 2
                    |> Expect.equal "2"
        , Test.test "Converts 1.5 hours to HHmm" <|
            \() ->
                Average.averageTimeToString HHmm 1.5
                    |> Expect.equal "01:30"
        , Test.test "Rounds minutes correctly for 1.01 hours" <|
            \() ->
                Average.averageTimeToString HHmm 1.01
                    |> Expect.equal "01:01"
        , Test.test "Handles zero hours" <|
            \() ->
                Average.averageTimeToString HHmm 0
                    |> Expect.equal "00:00"
        ]


averageSwitchesFromFloatNumberToHHmm : Test
averageSwitchesFromFloatNumberToHHmm =
    Test.test "Average SwitchTimeFormat switches FloatNumber to HHmm" <|
        \() ->
            Average.switchTimeFormat FloatNumber
                |> Expect.equal HHmm


averageSwitchesFromHHmmToFloatNumber : Test
averageSwitchesFromHHmmToFloatNumber =
    Test.test "Average SwitchTimeFormat switches HHmm to FloatNumber" <|
        \() ->
            Average.switchTimeFormat HHmm
                |> Expect.equal FloatNumber


mockNamespaceAndQuestionCodeString : String
mockNamespaceAndQuestionCodeString =
    "q20"


mockNamespaceAndQuestionCode : NamespaceAndQuestionCode
mockNamespaceAndQuestionCode =
    Id.Id mockNamespaceAndQuestionCodeString


mockQuestionAndDatapointCodeString : String
mockQuestionAndDatapointCodeString =
    "q2216_9"


mockQuestionAndDatapointCode : QuestionAndDatapointCode
mockQuestionAndDatapointCode =
    Id.Id mockQuestionAndDatapointCodeString


averageEncodeAvgWithoutSuffixes : Test
averageEncodeAvgWithoutSuffixes =
    Test.test "Average Encode AvgWithoutSuffixes encodes correctly" <|
        \() ->
            let
                input : Average.Average
                input =
                    Average.AvgWithoutSuffixes mockNamespaceAndQuestionCode

                expectedOutput : Encode.Value
                expectedOutput =
                    Encode.object
                        [ ( "question", Id.encode mockNamespaceAndQuestionCode ) ]
            in
            Average.encode input
                |> Expect.equal expectedOutput


averageEncodeAvgWithSuffixes : Test
averageEncodeAvgWithSuffixes =
    Test.test "Average Encode AvgWithSuffixes encodes correctly" <|
        \() ->
            let
                input : Average.Average
                input =
                    Average.AvgWithSuffixes mockNamespaceAndQuestionCode mockQuestionAndDatapointCode

                expectedOutput : Encode.Value
                expectedOutput =
                    Encode.object
                        [ ( "question", Id.encode mockNamespaceAndQuestionCode )
                        , ( "datapoint", Id.encode mockQuestionAndDatapointCode )
                        ]
            in
            Average.encode input
                |> Expect.equal expectedOutput


averageDecodeAvgWithoutSuffixes : Test
averageDecodeAvgWithoutSuffixes =
    Test.test "Average Decoder decodes AvgWithoutSuffixes correctly" <|
        \() ->
            let
                json =
                    "{ \"question\": \"" ++ mockNamespaceAndQuestionCodeString ++ "\" }"

                expected =
                    Average.AvgWithoutSuffixes (Id.Id mockNamespaceAndQuestionCodeString)
            in
            Decode.decodeString (Average.decoder { isDbu = False }) json
                |> Expect.equal (Ok expected)


averageDecodeAvgWithSuffixes : Test
averageDecodeAvgWithSuffixes =
    Test.test "Average Decoder decodes AvgWithSuffixes correctly" <|
        \() ->
            let
                json =
                    "{ \"question\": \"" ++ mockNamespaceAndQuestionCodeString ++ "\", \"datapoint\": \"" ++ mockQuestionAndDatapointCodeString ++ "\" }"

                expected =
                    Average.AvgWithSuffixes (Id.Id mockNamespaceAndQuestionCodeString) (Id.Id mockQuestionAndDatapointCodeString)
            in
            Decode.decodeString (Average.decoder { isDbu = False }) json
                |> Expect.equal (Ok expected)


averageTimeFormatDecoderTests : Test
averageTimeFormatDecoderTests =
    Test.describe "Average AverageTimeFormat Decoder"
        [ Test.test "Average Decodes 'hhmm' correctly" <|
            \() ->
                Decode.decodeString Average.averageTimeFormatDecoder "\"hhmm\""
                    |> Expect.equal (Ok HHmm)
        , Test.test "Average ecodes 'float' correctly" <|
            \() ->
                Decode.decodeString Average.averageTimeFormatDecoder "\"float\""
                    |> Expect.equal (Ok FloatNumber)
        , Test.test "Average Defaults to HHmm for unknown values" <|
            \() ->
                Decode.decodeString Average.averageTimeFormatDecoder "\"unknown\""
                    |> Expect.equal (Ok HHmm)
        ]


encodeAverageTimeFormatTests : Test
encodeAverageTimeFormatTests =
    Test.describe "Average Encode AverageTimeFormat"
        [ Test.test "Average Encodes HHmm as 'hhmm'" <|
            \() ->
                let
                    input : AverageTimeFormat
                    input =
                        HHmm

                    expectedOutput : Encode.Value
                    expectedOutput =
                        Encode.string "hhmm"
                in
                Average.encodeAverageTimeFormat input
                    |> Expect.equal expectedOutput
        , Test.test "Average Encodes FloatNumber as 'float'" <|
            \() ->
                let
                    input : AverageTimeFormat
                    input =
                        FloatNumber

                    expectedOutput : Encode.Value
                    expectedOutput =
                        Encode.string "float"
                in
                Average.encodeAverageTimeFormat input
                    |> Expect.equal expectedOutput
        ]



--use of fuzz


fuzzNamespaceAndQuestionCode : Fuzzer NamespaceAndQuestionCode
fuzzNamespaceAndQuestionCode =
    Fuzz.string
        |> Fuzz.map Id.Id


fuzzQuestionAndDatapointCode : Fuzzer QuestionAndDatapointCode
fuzzQuestionAndDatapointCode =
    Fuzz.string
        |> Fuzz.map Id.Id


fuzzAverage : Fuzzer Average.Average
fuzzAverage =
    Fuzz.oneOf
        [ Fuzz.map Average.AvgWithoutSuffixes fuzzNamespaceAndQuestionCode
        , Fuzz.map2 Average.AvgWithSuffixes fuzzNamespaceAndQuestionCode fuzzQuestionAndDatapointCode
        ]


propertyBasedTestAverageEncoderDecoder : Test
propertyBasedTestAverageEncoderDecoder =
    fuzz fuzzAverage "Encoding and decoding Average is reversible" <|
        \average ->
            let
                encoded =
                    Average.encode average

                decoded =
                    Decode.decodeValue (Average.decoder { isDbu = False }) encoded
            in
            Expect.equal (Ok average) decoded


averageTestFuzzEncoderDecoder : Test
averageTestFuzzEncoderDecoder =
    Test.describe "Average Property-Based Tests for Average"
        [ propertyBasedTestAverageEncoderDecoder
        ]
