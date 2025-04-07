module XB2.Share.Platform2.Grouping exposing
    ( Grouping(..)
    , interleavingPrefix
    , toString
    )


type Grouping
    = Split
    | And
    | Or


toString : Grouping -> String
toString grouping =
    case grouping of
        Split ->
            "Split"

        And ->
            "And"

        Or ->
            "Or"


interleavingPrefix : Grouping -> String
interleavingPrefix grouping =
    case grouping of
        Split ->
            ""

        And ->
            "AND "

        Or ->
            "OR "
