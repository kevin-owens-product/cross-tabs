module Data.Users exposing
    ( NewPasswordError(..)
    , OldPasswordError(..)
    , UserPasswordErrors
    , decodeUserPasswordError
    )

import Json.Decode as Decode
import Json.Decode.Extra as Decode



-- Config
-- Helpers
-- Adapter
-- Countries
-- Job Titles
-- User details
-- Change password


type alias UserPasswordErrors =
    { oldPasswordErrors : Maybe (List OldPasswordError)
    , newPasswordErrors : Maybe (List NewPasswordError)
    }


type OldPasswordError
    = OldPasswordIsMissing
    | DoesNotMatch
    | ParsingError String


type NewPasswordError
    = MissingUpperCase
    | MissingLowerCase
    | MissingDigit
    | MissingSpecialCharacter
    | TooShort
    | NewPasswordIsMissing
    | NewParsingError String


decodeUserPasswordError : String -> Result Decode.Error UserPasswordErrors
decodeUserPasswordError =
    let
        decodeOldPasswordErrors message =
            case message of
                "does not match" ->
                    DoesNotMatch

                "invalid" ->
                    DoesNotMatch

                "is missing" ->
                    OldPasswordIsMissing

                _ ->
                    ParsingError <| "Unknown: " ++ message

        decodeNewPasswordErrors message =
            case message of
                "missing_uppercase" ->
                    MissingUpperCase

                "missing_lowercase" ->
                    MissingLowerCase

                "missing_digit" ->
                    MissingDigit

                "missing_special_char" ->
                    MissingSpecialCharacter

                "too_short" ->
                    TooShort

                "is missing" ->
                    NewPasswordIsMissing

                _ ->
                    NewParsingError <| "Unknown: " ++ message
    in
    Decode.decodeString <|
        Decode.field "errors"
            (Decode.succeed UserPasswordErrors
                |> Decode.andMap (Decode.optionalField "password" (Decode.list <| Decode.map decodeOldPasswordErrors Decode.string))
                |> Decode.andMap (Decode.optionalField "new_password" (Decode.list <| Decode.map decodeNewPasswordErrors Decode.string))
            )



-- Industry
