module XB2.Detail.NotificationTextTest exposing (allTests)

import AssocSet
import Expect
import Test exposing (..)
import XB2.Data.AudienceCrosstab exposing (Direction(..))
import XB2.Detail.NotificationText as NotificationText
import XB2.Share.Platform2.Grouping exposing (Grouping(..))
import XB2.Views.AttributeBrowser exposing (ItemType(..))


allTests : Test
allTests =
    describe "NotificationText tests"
        [ createdTests, affixedTests ]


createdTests : Test
createdTests =
    describe "Created notifications"
        [ test "split and one column - should be singular" <|
            \_ ->
                NotificationText.created Column { differentDataset = False } 1 Split (AssocSet.singleton AttributeItem)
                    |> Expect.equal "Created 1 column."
        , test "split and more row - should be singular" <|
            \_ ->
                NotificationText.created Row { differentDataset = False } 1 Split (AssocSet.singleton AttributeItem)
                    |> Expect.equal "Created 1 row."
        , test "split and one column - should contain dataset notice" <|
            \_ ->
                NotificationText.created Column { differentDataset = True } 1 Split (AssocSet.singleton AttributeItem)
                    |> Expect.equal "Created 1 column + New dataset(s) added"
        , test "split and more row - should contain dataset notice" <|
            \_ ->
                NotificationText.created Row { differentDataset = True } 1 Split (AssocSet.singleton AttributeItem)
                    |> Expect.equal "Created 1 row + New dataset(s) added"
        , test "split and more columns - should be plural" <|
            \_ ->
                NotificationText.created Column { differentDataset = False } 3 Split (AssocSet.singleton AttributeItem)
                    |> Expect.equal "Created 3 columns."
        , test "split and more rows - should be plural" <|
            \_ ->
                NotificationText.created Row { differentDataset = False } 2 Split (AssocSet.singleton AttributeItem)
                    |> Expect.equal "Created 2 rows."
        , test "AND and more items - should be 1 column with singular" <|
            \_ ->
                NotificationText.created Column { differentDataset = False } 2 And (AssocSet.singleton AttributeItem)
                    |> Expect.equal "Created 1 column with 2 data points."
        , test "OR and more items - should be 1 row with singular" <|
            \_ ->
                NotificationText.created Row { differentDataset = False } 2 And (AssocSet.singleton AudienceItem)
                    |> Expect.equal "Created 1 row with 2 audiences."
        , test "OR and more type of items - should be 1 row with both labels" <|
            \_ ->
                NotificationText.created Row { differentDataset = False } 2 And (AssocSet.fromList [ AudienceItem, AttributeItem ])
                    |> Expect.equal "Created 1 row with 2 data points / audiences."
        ]


affixedTests : Test
affixedTests =
    describe "Affixed notifications"
        [ test "with one row and one name" <|
            \_ ->
                NotificationText.affixed 1 0 [ "Male" ]
                    |> Expect.equal "Appended 1 row with 'Male' data point / audience."
        , test "with one column and two names" <|
            \_ ->
                NotificationText.affixed 0 1 [ "Male", "Female" ]
                    |> Expect.equal "Appended 1 column with 'Male' & 1 other data point / audience."
        , test "with one row and one column and two names" <|
            \_ ->
                NotificationText.affixed 1 1 [ "Male", "Female" ]
                    |> Expect.equal "Appended 1 row and 1 column with 'Male' & 1 other data point / audience."
        , test "with one row and one column and three names should be plural" <|
            \_ ->
                NotificationText.affixed 1 1 [ "Male", "Female", "Won't say" ]
                    |> Expect.equal "Appended 1 row and 1 column with 'Male' & 2 other data points / audiences."
        ]
