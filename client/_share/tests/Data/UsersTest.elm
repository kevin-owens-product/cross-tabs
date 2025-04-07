module Data.UsersTest exposing
    ( decodeBothErrorsTest
    , decodeNewPasswordErrorsTest
    , decodeNoErrorsTest
    , decodeNonsenseTest
    , decodeOldPasswordErrorsTest
    )

-- Core

import Data.Users as Users exposing (NewPasswordError(..), OldPasswordError(..))
import Expect
import Test exposing (..)


decodeOldPasswordErrorsTest : Test
decodeOldPasswordErrorsTest =
    let
        oldPasswordEmpty =
            """
            {"errors": {"password": ["is missing"]}}
            """

        oldPasswordDoesNotMatch =
            """
            {"errors": {"password": ["does not match"]}}
            """

        getPasswordErrorsFromResult =
            Result.toMaybe >> Maybe.andThen .oldPasswordErrors >> Maybe.withDefault []
    in
    describe "Data.Users.decodeUserPasswordError - old password"
        [ test "oldPassword is empty" <|
            \() ->
                Users.decodeUserPasswordError oldPasswordEmpty
                    |> getPasswordErrorsFromResult
                    |> Expect.equalLists [ OldPasswordIsMissing ]
        , test "oldPassword does not match" <|
            \() ->
                Users.decodeUserPasswordError oldPasswordDoesNotMatch
                    |> getPasswordErrorsFromResult
                    |> Expect.equalLists [ DoesNotMatch ]
        ]


decodeNewPasswordErrorsTest : Test
decodeNewPasswordErrorsTest =
    let
        newPasswordEmpty =
            """
            {"errors": {"new_password": ["is missing"]}}
            """

        newPasswordInvalid =
            """
            {"errors": {"new_password": [ "missing_uppercase", "missing_lowercase", "missing_digit", "missing_special_char", "too_short" ]}}
            """

        getPasswordErrorsFromResult =
            Result.toMaybe >> Maybe.andThen .newPasswordErrors >> Maybe.withDefault []
    in
    describe "Data.Users.decodeUserPasswordError - new password"
        [ test "newPassword is empty" <|
            \() ->
                Users.decodeUserPasswordError newPasswordEmpty
                    |> getPasswordErrorsFromResult
                    |> Expect.equalLists [ NewPasswordIsMissing ]
        , test "newPassword is not valid" <|
            \() ->
                Users.decodeUserPasswordError newPasswordInvalid
                    |> getPasswordErrorsFromResult
                    |> Expect.equalLists [ MissingUpperCase, MissingLowerCase, MissingDigit, MissingSpecialCharacter, TooShort ]
        ]


decodeNoErrorsTest : Test
decodeNoErrorsTest =
    let
        noErrors =
            """
            {"errors": {}}
            """
    in
    test "Data.Users.decodeUserPasswordError - no errors" <|
        \() ->
            Users.decodeUserPasswordError noErrors
                |> Expect.equal (Ok { oldPasswordErrors = Nothing, newPasswordErrors = Nothing })


decodeBothErrorsTest : Test
decodeBothErrorsTest =
    let
        bothPasswordEmpty =
            """
            {"errors": {"password": ["is missing"], "new_password": ["is missing"]}}
            """
    in
    test "Data.Users.decodeUserPasswordError - both errors" <|
        \() ->
            Users.decodeUserPasswordError bothPasswordEmpty
                |> Expect.equal (Ok { oldPasswordErrors = Just [ OldPasswordIsMissing ], newPasswordErrors = Just [ NewPasswordIsMissing ] })


decodeNonsenseTest : Test
decodeNonsenseTest =
    let
        bothPasswordEmpty =
            """
            {"errors": {"password": ["nonsense"], "new_password": ["nonsense"]}}
            """
    in
    test "Data.Users.decodeUserPasswordError - nonsense" <|
        \() ->
            Users.decodeUserPasswordError bothPasswordEmpty
                |> Expect.equal (Ok { oldPasswordErrors = Just [ ParsingError "Unknown: nonsense" ], newPasswordErrors = Just [ NewParsingError "Unknown: nonsense" ] })
