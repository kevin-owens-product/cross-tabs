module XB2.Utils.Filename exposing (sanitize)

import Regex


sanitize : String -> String
sanitize name =
    name
        |> Regex.replace illegalCharsRegex (\_ -> "�")
        |> Regex.replace unicodeControlRegex (\_ -> "�")
        |> Regex.replace linuxReservedRegex (\_ -> "�")
        |> Regex.replace windowsReservedRegex (\_ -> "�")
        |> Regex.replace windowsTrailingRegex (\_ -> "�")


illegalCharsRegex : Regex.Regex
illegalCharsRegex =
    Regex.fromString "[\\/\\?<>\\\\:\\*\\|\"']"
        |> Maybe.withDefault Regex.never


unicodeControlRegex : Regex.Regex
unicodeControlRegex =
    Regex.fromString "[\u{0000}-\u{001F}\u{0080}-\u{009F}]"
        |> Maybe.withDefault Regex.never


linuxReservedRegex : Regex.Regex
linuxReservedRegex =
    Regex.fromString "^\\.+$"
        |> Maybe.withDefault Regex.never


windowsReservedRegex : Regex.Regex
windowsReservedRegex =
    Regex.fromString "^(con|prn|aux|nul|com[0-9]|lpt[0-9])(\\..*)?$"
        |> Maybe.withDefault Regex.never


windowsTrailingRegex : Regex.Regex
windowsTrailingRegex =
    Regex.fromString "[\\. ]+$"
        |> Maybe.withDefault Regex.never
