module Time.Format exposing
    ( format_D_MMM_YYYY
    , tvDateAndTimeFormat
    )

import DateFormat


format_D_MMM_YYYY : List DateFormat.Token
format_D_MMM_YYYY =
    [ DateFormat.dayOfMonthNumber
    , DateFormat.text " "
    , DateFormat.monthNameAbbreviated
    , DateFormat.text " "
    , DateFormat.yearNumber
    ]


tvDateAndTimeFormat : List DateFormat.Token
tvDateAndTimeFormat =
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
