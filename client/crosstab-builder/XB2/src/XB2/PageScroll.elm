module XB2.PageScroll exposing
    ( down
    , left
    , right
    , up
    )

import XB2.Data.AudienceCrosstab exposing (VisibleCells)


up : VisibleCells -> VisibleCells
up visibleCells =
    let
        visibleRows =
            max 1 (visibleCells.bottomRightRow - visibleCells.topLeftRow)

        ( newBottom, newTop ) =
            if visibleCells.topLeftRow - visibleRows <= 0 then
                ( visibleCells.bottomRightRow, 0 )

            else
                ( visibleCells.topLeftRow, visibleCells.topLeftRow - visibleRows )
    in
    { visibleCells
        | bottomRightRow = newBottom
        , topLeftRow = newTop
    }


down : VisibleCells -> Int -> VisibleCells
down visibleCells rowsCount =
    let
        visibleRows =
            visibleCells.bottomRightRow - visibleCells.topLeftRow

        newBottomRight =
            min (visibleCells.bottomRightRow + visibleRows) rowsCount

        newTopLeft =
            newBottomRight - visibleRows
    in
    { visibleCells
        | bottomRightRow = newBottomRight
        , topLeftRow = newTopLeft
    }


left : VisibleCells -> VisibleCells
left visibleCells =
    let
        visibleCols =
            max 1 (visibleCells.bottomRightCol - visibleCells.topLeftCol)

        ( newBottom, newTop ) =
            if visibleCells.topLeftCol - visibleCols <= 0 then
                ( visibleCells.bottomRightCol, 0 )

            else
                ( visibleCells.topLeftCol, visibleCells.topLeftCol - visibleCols )
    in
    { visibleCells
        | bottomRightCol = newBottom
        , topLeftCol = newTop
    }


right : VisibleCells -> Int -> VisibleCells
right visibleCells columnsCount =
    let
        visibleCols =
            visibleCells.bottomRightCol - visibleCells.topLeftCol

        newBottomRight =
            min (visibleCells.bottomRightCol + visibleCols) columnsCount

        newTopLeft =
            newBottomRight - visibleCols
    in
    { visibleCells
        | bottomRightCol = newBottomRight
        , topLeftCol = newTopLeft
    }
