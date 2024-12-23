module XB2.List.SelectionTest exposing (emptySelectionTest, isAnySelectedFuzzTest, propertyBasedTestIsSelected, selectAllFuzzTest, selectedCountFuzzTest, toggleFuzzTests)

import Expect
import Fuzz exposing (Fuzzer)
import List.NonEmpty as NonemptyList
import Test exposing (..)
import XB2.Data
    exposing
        ( XBProjectId
        )
import XB2.List.Selection as Selection
import XB2.Share.Data.Id as Id


fuzzValidString : Fuzzer String
fuzzValidString =
    Fuzz.string
        |> Fuzz.filter (\s -> String.trim s /= "")


fuzzXBProjectId : Fuzzer XBProjectId
fuzzXBProjectId =
    Fuzz.string
        |> Fuzz.filterMap
            (\idString ->
                if String.trim idString /= "" then
                    Just (Id.Id (String.trim idString))

                else
                    Nothing
            )


fuzzSelection : Fuzzer Selection.Selection
fuzzSelection =
    Fuzz.oneOf
        [ Fuzz.constant Selection.NotSelected
        , Fuzz.map Selection.SelectedProjects (Fuzz.list fuzzXBProjectId |> Fuzz.map NonemptyList.fromList |> Fuzz.filterMap identity)
        ]


toggleFuzzTests : Test
toggleFuzzTests =
    Test.describe "Selection toggle with fuzzers"
        [ fuzz2 fuzzXBProjectId Fuzz.bool "toggle adds or removes project IDs" <|
            \projectId shouldAdd ->
                let
                    initialSelection =
                        if shouldAdd then
                            Selection.NotSelected

                        else
                            Selection.SelectedProjects (NonemptyList.singleton projectId)

                    result =
                        Selection.toggle projectId initialSelection
                in
                if shouldAdd then
                    Expect.equal (Selection.SelectedProjects (NonemptyList.singleton projectId)) result

                else
                    Expect.equal Selection.NotSelected result
        ]


emptySelectionTest : Test
emptySelectionTest =
    Test.describe "empty Selection"
        [ Test.test "empty is NotSelected" <|
            \_ ->
                let
                    result =
                        Selection.empty
                in
                Expect.equal result Selection.NotSelected
        ]


propertyBasedTestIsSelected : Test
propertyBasedTestIsSelected =
    fuzz2 fuzzXBProjectId fuzzSelection "Selection isSelected check if a project is selected correctly" <|
        \projectId selection ->
            let
                result =
                    Selection.isSelected projectId selection
            in
            case selection of
                Selection.NotSelected ->
                    Expect.equal result False

                Selection.SelectedProjects projects ->
                    Expect.equal result (NonemptyList.any ((==) projectId) projects)


selectAllFuzzTest : Test
selectAllFuzzTest =
    fuzz fuzzValidString "Selection selectAll adds all provided projects correctly" <|
        \projectIdStr ->
            let
                projectId =
                    Id.Id projectIdStr

                allProjects =
                    [ projectId ]

                selection =
                    Selection.NotSelected

                result =
                    Selection.selectAll allProjects selection
            in
            case result of
                Selection.SelectedProjects selectedProjects ->
                    Expect.equal (NonemptyList.length selectedProjects) 1

                Selection.NotSelected ->
                    Expect.fail "Expected SelectedProjects, but got NotSelected"


isAnySelectedFuzzTest : Test
isAnySelectedFuzzTest =
    fuzz fuzzSelection "Selection isAnySelected returns correct value based on selection" <|
        \selection ->
            let
                result : Bool
                result =
                    Selection.isAnySelected selection
            in
            case selection of
                Selection.NotSelected ->
                    Expect.equal result False

                Selection.SelectedProjects _ ->
                    Expect.equal result True


selectedCountFuzzTest : Test
selectedCountFuzzTest =
    fuzz fuzzSelection "Selection selectedCount correctly counts selected projects" <|
        \selection ->
            let
                count : Int
                count =
                    Selection.selectedCount selection
            in
            case selection of
                Selection.NotSelected ->
                    Expect.equal count 0

                Selection.SelectedProjects projects ->
                    Expect.equal count (NonemptyList.length projects)
