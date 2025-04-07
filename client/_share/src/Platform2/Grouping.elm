module Platform2.Grouping exposing
    ( Grouping(..)
    , groupingPanelItemLabel
    , toString
    )


type Grouping
    = Split


groupingPanelItemLabel : Grouping -> Maybe String
groupingPanelItemLabel grouping =
    case grouping of
        Split ->
            Nothing


toString : Grouping -> String
toString grouping =
    case grouping of
        Split ->
            "Split"
