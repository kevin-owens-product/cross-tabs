module XB2.Share.Platform2.NameForCopy exposing (getWithLimit)

import Maybe.Extra as Maybe
import Regex exposing (Regex)


copyNumberRegex : Regex
copyNumberRegex =
    let
        regexString =
            -- Match anything so far as a first match group
            "(.*)"
                -- Now expect at least one space
                ++ "\\s"
                -- expect bracket here (
                ++ "\\("
                -- start of extra matching group
                ++ "("
                -- expect any digit here
                ++ "\\d+"
                -- and matching group is closed here
                ++ ")"
                -- now expect closing bracket )
                ++ "\\)"
                -- spaces are allowed in the end
                ++ "\\s{0,}"
                -- string should be ending by now
                ++ "$"
    in
    Regex.fromString regexString
        |> Maybe.withDefault Regex.never


parseNameWithCounter : String -> Maybe { originalName : String, copyNumber : Int }
parseNameWithCounter string =
    case
        Regex.find copyNumberRegex string
            |> List.head
            |> Maybe.map .submatches
            |> Maybe.withDefault []
    of
        (Just originalName) :: (Just copyNumber) :: [] ->
            String.toInt copyNumber
                |> Maybe.map (\number -> { originalName = originalName, copyNumber = number })

        _ ->
            Nothing


getNameWithSuffix : Int -> List String -> String -> ( String, String )
getNameWithSuffix maxLength allCurrentNames currentName =
    let
        analysedName =
            parseNameWithCounter currentName

        originalName =
            Maybe.unwrap currentName .originalName analysedName

        initialCopyNumber =
            Maybe.unwrap 1 (.copyNumber >> (+) 1) analysedName

        minimalSuffixLength =
            4

        checkShortenedVersion name =
            if String.length currentName + minimalSuffixLength > maxLength then
                let
                    regex =
                        Regex.fromString ("^(" ++ name ++ ")")
                            |> Maybe.withDefault Regex.never
                in
                Regex.find regex originalName
                    |> List.head
                    |> Maybe.isJust

            else
                False

        copyNumberString =
            allCurrentNames
                |> List.foldr
                    (\name numberSoFar ->
                        case parseNameWithCounter name of
                            Just result ->
                                if (result.originalName == originalName || checkShortenedVersion result.originalName) && result.copyNumber >= numberSoFar then
                                    result.copyNumber + 1

                                else
                                    numberSoFar

                            Nothing ->
                                numberSoFar
                    )
                    initialCopyNumber
                |> String.fromInt
    in
    ( originalName, " (" ++ copyNumberString ++ ")" )


getWithLimit : List String -> Int -> String -> String
getWithLimit allCurrentNames maxLength originalName =
    let
        ( name, suffix ) =
            getNameWithSuffix maxLength allCurrentNames originalName

        nameLength =
            String.length (name ++ suffix)
    in
    if nameLength > maxLength then
        String.slice 0 (maxLength - nameLength - 3) name ++ "..." ++ suffix

    else
        name ++ suffix
