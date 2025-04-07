module XB2.Data.SelectionMap exposing
    ( SelectionMap
    , SelectionSettings
    , create
    , selectionSettings
    , selectionSettingsForColumn
    , selectionSettingsForRow
    )

{-|

    SelectionMap is solving problem of quickly and effectively finding
    whether the cell in 2D plane is selected and if it has as well any selected neighbours.

    It has been introduced to solve the problem of correctly show borders on selected rows and columns that can be next to each other and therefor the selection border has to be "merged".

    For more information, consult the ticket [ATC-463](https://globalwebindex.atlassian.net/browse/ATC-463)

-}

import List.Extra as List
import Set exposing (Set)


type SelectionMap
    = SelectionMap { rows : Set Int, columns : Set Int }


type alias SelectionSettings =
    { above : Bool
    , below : Bool
    , right : Bool
    , left : Bool
    , selectedRow : Bool
    , selectedColumn : Bool
    }


selectedIndexes : List Bool -> List Int
selectedIndexes =
    List.findIndices identity


create : List Bool -> List Bool -> SelectionMap
create rows columns =
    SelectionMap
        { rows = Set.fromList (selectedIndexes rows)
        , columns = Set.fromList (selectedIndexes columns)
        }


selectionSettings : Int -> Int -> SelectionMap -> SelectionSettings
selectionSettings rowIndex columnIndex (SelectionMap { rows, columns }) =
    { left = Set.member (columnIndex - 1) columns
    , right = Set.member (columnIndex + 1) columns
    , below = Set.member (rowIndex + 1) rows
    , above = Set.member (rowIndex - 1) rows
    , selectedRow = Set.member rowIndex rows
    , selectedColumn = Set.member columnIndex columns
    }


selectionSettingsForRow : Int -> SelectionMap -> SelectionSettings
selectionSettingsForRow rowIndex (SelectionMap { rows }) =
    { left = False
    , right = False
    , below = Set.member (rowIndex + 1) rows
    , above = Set.member (rowIndex - 1) rows
    , selectedRow = Set.member rowIndex rows
    , selectedColumn = False
    }


selectionSettingsForColumn : Int -> SelectionMap -> SelectionSettings
selectionSettingsForColumn colIndex (SelectionMap { columns }) =
    { below = False
    , above = False
    , right = Set.member (colIndex + 1) columns
    , left = Set.member (colIndex - 1) columns
    , selectedRow = False
    , selectedColumn = Set.member colIndex columns
    }
