module XB2.Data.CaptionTest exposing
    ( captionGroupingPrefixTests
    , captionMergeTests
    , captionSetSubtitleTests
    , combinedShortNameTests
    , fuzzCaptionFromGroupOfCaptionsTests
    , propertyBasedTestTrimName
    , trimNameTestFuzz
    )

import Expect
import Fuzz exposing (Fuzzer)
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Test exposing (..)
import XB2.Data.Caption as Caption exposing (Caption)
import XB2.Share.Platform2.Grouping exposing (Grouping(..))


captionGroupingPrefixTests : Test
captionGroupingPrefixTests =
    describe "caption groupingPrefix tests"
        [ test "Split returns an empty string" <|
            \_ -> Expect.equal (Caption.groupingPrefix Split) ""
        , test "And returns 'all '" <|
            \_ -> Expect.equal (Caption.groupingPrefix And) "all "
        , test "Or returns 'any of '" <|
            \_ -> Expect.equal (Caption.groupingPrefix Or) "any of "
        ]


captionSetSubtitleTests : Test
captionSetSubtitleTests =
    describe "Caption setSubtitleTests tests"
        [ test "setSubtitle sets subtitle to Nothing when passed Nothing" <|
            \_ ->
                let
                    caption =
                        Caption.create { name = "Test", fullName = "Full Test", subtitle = Just "Initial Subtitle" }

                    updatedCaption =
                        Caption.setSubtitle Nothing caption
                in
                Expect.equal (Caption.getSubtitle updatedCaption) Nothing
        , test "setSubtitle sets subtitle to Just string when passed Just string" <|
            \_ ->
                let
                    caption =
                        Caption.create { name = "Test", fullName = "Full Test", subtitle = Nothing }

                    updatedCaption =
                        Caption.setSubtitle (Just "New Subtitle") caption
                in
                Expect.equal (Caption.getSubtitle updatedCaption) (Just "New Subtitle")
        ]


captionMergeTests : Test
captionMergeTests =
    describe "Caption merge tests"
        [ test "merge sets subtitle to Nothing" <|
            \_ ->
                let
                    caption1 =
                        Caption.create { name = "First", fullName = "First Full", subtitle = Just "Some Subtitle" }

                    caption2 =
                        Caption.create { name = "Second", fullName = "Second Full", subtitle = Just "Other Subtitle" }

                    mergedCaption =
                        Caption.merge "and" caption1 caption2
                in
                Expect.equal (Caption.getSubtitle mergedCaption) Nothing
        ]


fuzzCaptionNames : Fuzzer String
fuzzCaptionNames =
    Fuzz.intRange 0 150
        |> Fuzz.map (\n -> String.repeat n "A")


propertyBasedTestTrimName : Test
propertyBasedTestTrimName =
    fuzz fuzzCaptionNames "Caption trimNameByUserDefinedLimit trims names longer than max length" <|
        \randomName ->
            let
                caption : Caption
                caption =
                    Caption.create { name = randomName, fullName = "Full Test", subtitle = Nothing }

                trimmedCaption : Caption
                trimmedCaption =
                    Caption.trimNameByUserDefinedLimit caption

                maxAllowedLength : number
                maxAllowedLength =
                    100

                trimmedName : String
                trimmedName =
                    Caption.getName trimmedCaption
            in
            if String.length randomName > maxAllowedLength then
                Expect.equal trimmedName (String.left maxAllowedLength randomName)

            else
                Expect.equal trimmedName randomName


trimNameTestFuzz : Test
trimNameTestFuzz =
    Test.describe "Caption Property-Based Tests for trimNameByUserDefinedLimit"
        [ propertyBasedTestTrimName
        ]


fuzzCaptionFromGroupOfCaptionsTests : Test
fuzzCaptionFromGroupOfCaptionsTests =
    fuzz fuzzCaptionNames "Caption fromGroupOfCaptions with Grouping.Or" <|
        \randomName ->
            let
                caption1 : Caption
                caption1 =
                    Caption.create { name = randomName, fullName = randomName, subtitle = Nothing }

                caption2 : Caption
                caption2 =
                    Caption.create { name = randomName, fullName = randomName, subtitle = Nothing }

                grouping : Grouping
                grouping =
                    Or

                captions : NonEmpty Caption
                captions =
                    NonemptyList.fromList [ caption1, caption2 ]
                        |> Maybe.withDefault (NonemptyList.singleton caption1)

                result : Caption
                result =
                    Caption.fromGroupOfCaptions grouping captions
            in
            Expect.equal (Caption.getFullName result) (randomName ++ " OR " ++ randomName)


combinedShortNameTests : Test
combinedShortNameTests =
    describe "Caption combinedShortName tests"
        [ test "Empty list returns N/A" <|
            \_ ->
                let
                    result =
                        Caption.combinedShortName And []
                in
                Expect.equal result "N/A"
        , test "Single name returns the name" <|
            \_ ->
                let
                    result =
                        Caption.combinedShortName And [ "First" ]
                in
                Expect.equal result "First"
        , test "Two names combine with 'AND'" <|
            \_ ->
                let
                    result =
                        Caption.combinedShortName And [ "First", "Second" ]
                in
                Expect.equal result "First AND Second"
        , test "More than two names combine with 'AND' and show count of remaining" <|
            \_ ->
                let
                    result =
                        Caption.combinedShortName And [ "First", "Second", "Third", "Fourth" ]
                in
                Expect.equal result "First AND all 3 data points / audiences including Second"
        ]
