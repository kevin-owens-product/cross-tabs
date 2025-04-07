module XB2.Share.Time.Format exposing
    ( format_DD_MMM_YY_hh_mm
    , format_D_MMM_YYYY_hh_mm
    , format_YYYY_MM_DD_hh_mm
    , fullscreenPublishedFormat
    , xbRelativeTime
    )

import DateFormat
import DateFormat.Relative
import Time exposing (Posix)


format_DD_MMM_YY_hh_mm : List DateFormat.Token
format_DD_MMM_YY_hh_mm =
    [ DateFormat.dayOfMonthFixed
    , DateFormat.text " "
    , DateFormat.monthNameAbbreviated
    , DateFormat.text " "
    , DateFormat.yearNumberLastTwo
    , DateFormat.text " "
    , DateFormat.hourMilitaryFixed
    , DateFormat.text ":"
    , DateFormat.minuteFixed
    ]


fullscreenPublishedFormat : List DateFormat.Token
fullscreenPublishedFormat =
    [ DateFormat.dayOfMonthFixed
    , DateFormat.text " "
    , DateFormat.monthNameFull
    , DateFormat.text " "
    , DateFormat.yearNumber
    ]


xbRelativeTime : Posix -> Posix -> String
xbRelativeTime current saved =
    DateFormat.Relative.relativeTimeWithOptions
        xbRelativeTimeOptions
        current
        saved


xbRelativeTimeOptions : DateFormat.Relative.RelativeTimeOptions
xbRelativeTimeOptions =
    -- this fn was much nicer before elm-format :'D
    { someSecondsAgo =
        \secs ->
            if secs < 45 then
                "just now"

            else
                "1 minute ago"
    , someMinutesAgo =
        \mins ->
            if mins == 1 then
                "1 minute ago"

            else if mins < 45 then
                String.fromInt mins ++ " minutes ago"

            else
                "1 hour ago"
    , someHoursAgo =
        \hs ->
            if hs == 1 then
                "1 hour ago"

            else if hs < 22 then
                String.fromInt hs ++ " hours ago"

            else
                "1 day ago"
    , someDaysAgo =
        \ds ->
            if ds == 1 then
                "1 day ago"

            else if ds < 26 then
                String.fromInt ds ++ " days ago"

            else
                "1 month ago"
    , someMonthsAgo =
        \ms ->
            if ms == 1 then
                "1 month ago"

            else if ms < 11 then
                String.fromInt ms ++ " months ago"

            else
                "1 year ago"
    , someYearsAgo = \ys -> String.fromInt ys ++ " years ago"
    , rightNow = "just now"
    , inSomeSeconds =
        \secs ->
            if secs == 0 then
                "just now"

            else if secs == 1 then
                "in a second"

            else if secs < 45 then
                "in " ++ String.fromInt secs ++ " seconds"

            else
                "in a minute"
    , inSomeMinutes =
        \mins ->
            if mins == 1 then
                "in a minute"

            else if mins < 45 then
                "in " ++ String.fromInt mins ++ " minutes"

            else
                "in an hour"
    , inSomeHours =
        \hs ->
            if hs == 1 then
                "in an hour"

            else if hs < 22 then
                "in " ++ String.fromInt hs ++ " hours"

            else
                "in a day"
    , inSomeDays =
        \ds ->
            if ds == 1 then
                "in a day"

            else if ds < 26 then
                "in " ++ String.fromInt ds ++ " days"

            else
                "in a month"
    , inSomeMonths =
        \ms ->
            if ms == 1 then
                "in a month"

            else if ms < 11 then
                "in " ++ String.fromInt ms ++ " months"

            else
                "in a year"
    , inSomeYears =
        \ys ->
            if ys == 1 then
                "in a year"

            else
                "in " ++ String.fromInt ys ++ " years"
    }


format_YYYY_MM_DD_hh_mm : List DateFormat.Token
format_YYYY_MM_DD_hh_mm =
    [ DateFormat.yearNumber
    , DateFormat.text " "
    , DateFormat.monthFixed
    , DateFormat.text " "
    , DateFormat.dayOfMonthFixed
    , DateFormat.text " "
    , DateFormat.hourMilitaryFixed
    , DateFormat.text ":"
    , DateFormat.minuteFixed
    ]


format_D_MMM_YYYY_hh_mm : List DateFormat.Token
format_D_MMM_YYYY_hh_mm =
    [ DateFormat.dayOfMonthNumber
    , DateFormat.text " "
    , DateFormat.monthNameAbbreviated
    , DateFormat.text " "
    , DateFormat.yearNumber
    , DateFormat.text " "
    , DateFormat.hourMilitaryFixed
    , DateFormat.text ":"
    , DateFormat.minuteFixed
    ]
