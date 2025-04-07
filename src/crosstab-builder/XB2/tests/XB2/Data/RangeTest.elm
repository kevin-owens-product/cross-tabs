module XB2.Data.RangeTest exposing
    ( Msg(..)
    , combineIsCommutative
    , extendOnlyChangesRangeIfNumberOutsideRange
    , interpolateIn01Range
    , minLTEMax
    )

import ArchitectureTest exposing (TestedApp, TestedModel(..), TestedUpdate(..))
import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (..)
import XB2.Data.Range as Range exposing (Range)



-- FUZZERS


rangeFuzzer : Fuzzer Range
rangeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Range.init
        , Fuzz.map Range.fromList (Fuzz.list Fuzz.niceFloat)
        , Fuzz.map Range.fromNumber Fuzz.niceFloat
        ]



-- ARCHITECTURE TEST DEFINITIONS


app : TestedApp Range Msg
app =
    { model = FuzzedModel rangeFuzzer
    , update = UpdateWithoutCmds update
    , msgFuzzer = msgFuzzer
    , modelToString = rangeToString
    , msgToString = msgToString
    }


type Msg
    = Combine Range
    | ExtendWith Float


msgFuzzer : Fuzzer Msg
msgFuzzer =
    Fuzz.oneOf
        [ combineMsgFuzzer
        , extendWithMsgFuzzer
        ]


combineMsgFuzzer : Fuzzer Msg
combineMsgFuzzer =
    Fuzz.map Combine rangeFuzzer


extendWithMsgFuzzer : Fuzzer Msg
extendWithMsgFuzzer =
    Fuzz.map ExtendWith Fuzz.niceFloat


update : Msg -> Range -> Range
update msg range =
    case msg of
        Combine range2 ->
            Range.combine range2 range

        ExtendWith float ->
            Range.extendWith float range


msgToString : Msg -> String
msgToString msg =
    case msg of
        Combine range ->
            "Combine " ++ rangeToString range

        ExtendWith float ->
            "ExtendWith " ++ String.fromFloat float


rangeToString : Range -> String
rangeToString range =
    "<"
        ++ String.fromFloat range.min
        ++ ","
        ++ String.fromFloat range.max
        ++ ">"



-- TESTS


minLTEMax : Test
minLTEMax =
    ArchitectureTest.invariantTest
        "Range's min <= max if "
        app
    <|
        \_ _ finalRange ->
            if finalRange /= Range.init then
                finalRange.min
                    |> Expect.atMost finalRange.max

            else
                Expect.pass


extendOnlyChangesRangeIfNumberOutsideRange : Test
extendOnlyChangesRangeIfNumberOutsideRange =
    ArchitectureTest.msgTest
        "Extend only changes range if the number is outside the range"
        app
        extendWithMsgFuzzer
    <|
        \inputRange msg outputRange ->
            case msg of
                ExtendWith float ->
                    if Range.contains float inputRange then
                        outputRange
                            |> Expect.equal inputRange

                    else
                        outputRange
                            |> Expect.notEqual inputRange

                _ ->
                    Expect.pass


combineIsCommutative : Test
combineIsCommutative =
    fuzz2 rangeFuzzer rangeFuzzer "combine a b == combine b a" <|
        \r1 r2 ->
            Range.combine r1 r2
                |> Expect.equal (Range.combine r2 r1)


interpolateIn01Range : Test
interpolateIn01Range =
    fuzz2 Fuzz.niceFloat rangeFuzzer "interpolate returns 0..1 if number in range" <|
        \float range ->
            if Range.contains float range then
                let
                    interpolateResult =
                        Range.interpolate range float
                in
                interpolateResult
                    |> Expect.all
                        [ Expect.atLeast 0
                        , Expect.atMost 1
                        ]

            else
                Expect.pass
