module XB2.Utils.NewName exposing
    ( duplicateName
    , maxLength
    , timeBasedCrosstabName
    , timeBasedFolderName
    )

import DateFormat
import Time exposing (Posix, Zone)
import XB2.Share.Time.Format


maxLength : Int
maxLength =
    64


timeBasedName : String -> Zone -> Posix -> String
timeBasedName name zone posix =
    name ++ " " ++ DateFormat.format XB2.Share.Time.Format.format_DD_MMM_YY_hh_mm zone posix


timeBasedFolderName : (String -> Bool) -> Zone -> Posix -> String
timeBasedFolderName nameExists zone posix =
    timeBasedName "Folder" zone posix
        |> ensureUniqueName nameExists


timeBasedCrosstabName : (String -> Bool) -> Zone -> Posix -> String
timeBasedCrosstabName nameExists zone posix =
    timeBasedName "New Crosstab" zone posix
        |> ensureUniqueName nameExists


fitIntoLimit : String -> String -> String
fitIntoLimit name suffix =
    let
        sumLength =
            String.length name + String.length suffix

        name_ =
            if sumLength > maxLength then
                String.slice 0 (maxLength - (sumLength + 3)) name
                    ++ "..."

            else
                name
    in
    name_ ++ suffix


{-|

    "This is a long name"
    --> "This i... (1)"

    "Name" -- when "Name (1)" already exists
    --> "Name (2)"

-}
duplicateName : (String -> Bool) -> String -> String
duplicateName nameExists name =
    ensureUniqueNameWithSuffix 1 nameExists name


ensureUniqueName : (String -> Bool) -> String -> String
ensureUniqueName nameExists name =
    if nameExists name then
        ensureUniqueNameWithSuffix 1 nameExists name

    else
        name


ensureUniqueNameWithSuffix : Int -> (String -> Bool) -> String -> String
ensureUniqueNameWithSuffix n nameExists name =
    let
        suffix =
            " (" ++ String.fromInt n ++ ")"

        newName =
            fitIntoLimit name suffix
    in
    if nameExists newName then
        ensureUniqueNameWithSuffix (n + 1) nameExists name

    else
        newName
