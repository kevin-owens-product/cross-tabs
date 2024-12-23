module XB2.CrosstabTest exposing
    ( testAddingColumnsAtIndex
    , testAddingMultipleColumns
    , testAddingMultipleRows
    , testAddingRowsAtIndex
    , testMoveItemInRows
    , testMoveItemsFromRowToColumn
    , testRowColCounting
    )

import Expect
import Test exposing (..)
import XB2.Data.Crosstab as Crosstab exposing (Crosstab)



-- TODO: write some tests for bases as well


type alias TestCrosstab =
    Crosstab ( Int, String ) () Int


emptyCrosstab : TestCrosstab
emptyCrosstab =
    Crosstab.empty Tuple.second (always "()")


addThreeRows : TestCrosstab -> TestCrosstab
addThreeRows =
    addRows 3


addRows : Int -> TestCrosstab -> TestCrosstab
addRows size crosstab =
    if size == 0 then
        crosstab

    else
        let
            initialCrosstab =
                Crosstab.addRow 1 ( 1, "row 1" ) [ () ] crosstab
        in
        if size == 1 then
            initialCrosstab

        else
            List.range 2 size
                |> List.map (\n -> { value = n, key = ( n, "row " ++ String.fromInt n ) })
                |> (\list -> Crosstab.addRows list [ () ] initialCrosstab)


addColumns : Int -> TestCrosstab -> TestCrosstab
addColumns size crosstab =
    let
        initialCrosstab =
            Crosstab.addColumn 1 ( 1, "column 1" ) [ () ] crosstab
    in
    if size == 1 then
        initialCrosstab

    else
        List.range 2 size
            |> List.map (\n -> { value = n, key = ( n, "column " ++ String.fromInt n ) })
            |> (\list -> Crosstab.addColumns list [ () ] initialCrosstab)


addTwoColumns : TestCrosstab -> TestCrosstab
addTwoColumns =
    addColumns 2


testAddingMultipleColumns : Test
testAddingMultipleColumns =
    describe "Add multiple columns at once"
        [ test "Add empty array of columns should return original crosstab" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addColumns [] []
                    |> Crosstab.getColumns
                    |> Expect.equal
                        []
        , test "Add one column to empty crosstab should create crosstab with that column" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addColumns
                        [ { value = 1
                          , key = ( 1, "column 1" )
                          }
                        ]
                        []
                    |> Crosstab.getColumns
                    |> Expect.equal
                        [ ( 1, "column 1" ) ]
        , test "Add two columns to empty crosstab should create crosstab with two columns" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addColumns
                        [ { value = 1
                          , key = ( 1, "column 1" )
                          }
                        , { value = 2
                          , key = ( 2, "column 2" )
                          }
                        ]
                        []
                    |> Crosstab.getColumns
                    |> Expect.equal
                        [ ( 1, "column 1" )
                        , ( 2, "column 2" )
                        ]
        , test "Add two columns to already filled crosstab should create crosstab with added two columns" <|
            \() ->
                let
                    crosstab =
                        emptyCrosstab
                            |> Crosstab.addColumns
                                [ { value = 1
                                  , key = ( 1, "column 1" )
                                  }
                                , { value = 2
                                  , key = ( 2, "column 2" )
                                  }
                                ]
                                []
                in
                crosstab
                    |> Crosstab.addColumns
                        [ { value = 1
                          , key = ( 3, "column 3" )
                          }
                        , { value = 2
                          , key = ( 4, "column 4" )
                          }
                        ]
                        []
                    |> Crosstab.getColumns
                    |> Expect.equal
                        [ ( 1, "column 1" )
                        , ( 2, "column 2" )
                        , ( 3, "column 3" )
                        , ( 4, "column 4" )
                        ]
        ]


testAddingMultipleRows : Test
testAddingMultipleRows =
    describe "Add multiple rows at once"
        [ test "Add empty array of rows should return original crosstab" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addRows [] []
                    |> Crosstab.getRows
                    |> Expect.equal
                        []
        , test "Add one row to empty crosstab should create crosstab with that row" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addRows
                        [ { value = 1
                          , key = ( 1, "row 1" )
                          }
                        ]
                        []
                    |> Crosstab.getRows
                    |> Expect.equal
                        [ ( 1, "row 1" ) ]
        , test "Add two rows to empty crosstab should create crosstab with two rows" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addRows
                        [ { value = 1
                          , key = ( 1, "row 1" )
                          }
                        , { value = 2
                          , key = ( 2, "row 2" )
                          }
                        ]
                        []
                    |> Crosstab.getRows
                    |> Expect.equal
                        [ ( 1, "row 1" )
                        , ( 2, "row 2" )
                        ]
        , test "Add two rows to already filled crosstab should create crosstab with added two rows" <|
            \() ->
                let
                    crosstab =
                        emptyCrosstab
                            |> Crosstab.addRows
                                [ { value = 1
                                  , key = ( 1, "row 1" )
                                  }
                                , { value = 2
                                  , key = ( 2, "row 2" )
                                  }
                                ]
                                []
                in
                crosstab
                    |> Crosstab.addRows
                        [ { value = 1
                          , key = ( 3, "row 3" )
                          }
                        , { value = 2
                          , key = ( 4, "row 4" )
                          }
                        ]
                        []
                    |> Crosstab.getRows
                    |> Expect.equal
                        [ ( 1, "row 1" )
                        , ( 2, "row 2" )
                        , ( 3, "row 3" )
                        , ( 4, "row 4" )
                        ]
        ]


testAddingRowsAtIndex : Test
testAddingRowsAtIndex =
    describe "Add rows at index"
        [ test "Add row at index 0 should be first item" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.addRowAtIndex 6 0 ( 6, "" ) [ () ]
                    |> Crosstab.getRows
                    |> Expect.equal
                        [ ( 6, "" )
                        , ( 1, "row 1" )
                        , ( 2, "row 2" )
                        , ( 3, "row 3" )
                        , ( 4, "row 4" )
                        , ( 5, "row 5" )
                        ]
        , test "Add row at index, 1 should be first item" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.addRowAtIndex 6 1 ( 6, "" ) [ () ]
                    |> Crosstab.getRows
                    |> Expect.equal
                        [ ( 1, "row 1" )
                        , ( 6, "" )
                        , ( 2, "row 2" )
                        , ( 3, "row 3" )
                        , ( 4, "row 4" )
                        , ( 5, "row 5" )
                        ]
        , test "Add row at index out of array should add to the end" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.addRowAtIndex 6 10 ( 6, "" ) [ () ]
                    |> Crosstab.getRows
                    |> Expect.equal
                        [ ( 1, "row 1" )
                        , ( 2, "row 2" )
                        , ( 3, "row 3" )
                        , ( 4, "row 4" )
                        , ( 5, "row 5" )
                        , ( 6, "" )
                        ]
        , test "Add row at negative index should add to the beginning" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.addRowAtIndex 6 -1 ( 6, "six" ) [ () ]
                    |> Crosstab.getRows
                    |> Expect.equal
                        [ ( 6, "six" )
                        , ( 1, "row 1" )
                        , ( 2, "row 2" )
                        , ( 3, "row 3" )
                        , ( 4, "row 4" )
                        , ( 5, "row 5" )
                        ]
        , test "It should be possible to add rows that already exist" <|
            \() ->
                emptyCrosstab
                    |> addRows 1
                    |> Crosstab.addRowAtIndex 6 0 ( 1, "row 1" ) [ () ]
                    |> Crosstab.getRows
                    |> Expect.equal
                        [ ( 1, "row 1" )
                        , ( 1, "row 1" )
                        ]
        ]


testAddingColumnsAtIndex : Test
testAddingColumnsAtIndex =
    describe "Add column at index"
        [ test "It should be possible to add rows that are already present" <|
            \() ->
                emptyCrosstab
                    |> addColumns 1
                    |> Crosstab.addColumnAtIndex 1 0 ( 1, "column 1" ) [ () ]
                    |> Crosstab.getColumns
                    |> Expect.equal
                        [ ( 1, "column 1" )
                        , ( 1, "column 1" )
                        ]
        , test "Add row at index 1 should be first item" <|
            \() ->
                emptyCrosstab
                    |> addColumns 3
                    |> Crosstab.addColumnAtIndex 4 1 ( 4, "four" ) [ () ]
                    |> Crosstab.getColumns
                    |> Expect.equal
                        [ ( 1, "column 1" )
                        , ( 4, "four" )
                        , ( 2, "column 2" )
                        , ( 3, "column 3" )
                        ]
        ]


testMoveItemInRows : Test
testMoveItemInRows =
    describe "Move item in row"
        [ test "Move existing item to the beginning" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.moveItemsToRowIndex Tuple.first 0 { rows = [ ( 5, "row 5" ) ], columns = [] } []
                    |> Crosstab.getRows
                    |> Expect.equal [ ( 5, "row 5" ), ( 1, "row 1" ), ( 2, "row 2" ), ( 3, "row 3" ), ( 4, "row 4" ) ]
        , test "Move existing item after the beginning" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.moveItemsToRowIndex Tuple.first 1 { rows = [ ( 5, "row 5" ) ], columns = [] } []
                    |> Crosstab.getRows
                    |> Expect.equal [ ( 1, "row 1" ), ( 5, "row 5" ), ( 2, "row 2" ), ( 3, "row 3" ), ( 4, "row 4" ) ]
        , test "Move existing item after itself doesn't change the structure" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.moveItemsToRowIndex Tuple.first 4 { rows = [ ( 5, "row 5" ) ], columns = [] } []
                    |> Crosstab.getRows
                    |> Expect.equal [ ( 1, "row 1" ), ( 2, "row 2" ), ( 3, "row 3" ), ( 4, "row 4" ), ( 5, "row 5" ) ]
        , test "Move existing item out of range should move item to the end" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.moveItemsToRowIndex Tuple.first 5 { rows = [ ( 2, "row 2" ) ], columns = [] } []
                    |> Crosstab.getRows
                    |> Expect.equal [ ( 1, "row 1" ), ( 3, "row 3" ), ( 4, "row 4" ), ( 5, "row 5" ), ( 2, "row 2" ) ]
        , test "Move existing below index 0 should move item to the beginning" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.moveItemsToRowIndex Tuple.first -2 { rows = [ ( 2, "row 2" ) ], columns = [] } []
                    |> Crosstab.getRows
                    |> Expect.equal [ ( 2, "row 2" ), ( 1, "row 1" ), ( 3, "row 3" ), ( 4, "row 4" ), ( 5, "row 5" ) ]
        , test "Move non-existing item should do nothing" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> Crosstab.moveItemsToRowIndex Tuple.first 3 { rows = [ ( 12, "row 12" ) ], columns = [] } []
                    |> Crosstab.moveItemsToRowIndex Tuple.first 2 { rows = [ ( 5, "row 12" ) ], columns = [] } []
                    |> Crosstab.getRows
                    |> Expect.equal [ ( 1, "row 1" ), ( 2, "row 2" ), ( 3, "row 3" ), ( 4, "row 4" ), ( 5, "row 5" ) ]
        ]


testMoveItemsFromRowToColumn : Test
testMoveItemsFromRowToColumn =
    describe "Move item from row to column"
        [ test "Should remove item from row and insert it to column at specified position" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> addColumns 3
                    |> Crosstab.moveItemsToColumnIndex (always 5) 2 { rows = [ ( 5, "row 5" ) ], columns = [] } [ () ]
                    |> (\crosstab ->
                            { rows = Crosstab.getRows crosstab
                            , columns = Crosstab.getColumns crosstab
                            , rowCount = Crosstab.rowCount crosstab
                            , colCount = Crosstab.colCount crosstab
                            }
                       )
                    |> Expect.equal
                        { rows = [ ( 1, "row 1" ), ( 2, "row 2" ), ( 3, "row 3" ), ( 4, "row 4" ) ]
                        , columns = [ ( 1, "column 1" ), ( 2, "column 2" ), ( 5, "row 5" ), ( 3, "column 3" ) ]
                        , rowCount = 4
                        , colCount = 4
                        }
        , test "Check there are no redundant values left after row is moved to columne" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> addColumns 3
                    |> Crosstab.moveItemsToColumnIndex (always 5) 2 { rows = [ ( 5, "row 5" ) ], columns = [] } [ () ]
                    |> Crosstab.foldr (\_ _ -> (+) 1) 0
                    |> Expect.equal 16
        , test "Move nonexisting item from row to column should not change Crosstab" <|
            \() ->
                emptyCrosstab
                    |> addRows 5
                    |> addColumns 3
                    |> Crosstab.moveItemsToColumnIndex (always 1000) 2 { rows = [ ( 1000, "row 1000" ) ], columns = [] } [ () ]
                    |> (\crosstab ->
                            { rows = Crosstab.getRows crosstab
                            , columns = Crosstab.getColumns crosstab
                            , rowCount = Crosstab.rowCount crosstab
                            , colCount = Crosstab.colCount crosstab
                            }
                       )
                    |> Expect.equal
                        { rows = [ ( 1, "row 1" ), ( 2, "row 2" ), ( 3, "row 3" ), ( 4, "row 4" ), ( 5, "row 5" ) ]
                        , columns = [ ( 1, "column 1" ), ( 2, "column 2" ), ( 3, "column 3" ) ]
                        , rowCount = 5
                        , colCount = 3
                        }
        ]


testRowColCounting : Test
testRowColCounting =
    describe "Counting of rows and columns"
        [ test "Empty Crosstab has 0 rows" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.rowCount
                    |> Expect.equal 0
        , test "Empty Crosstab has 0 cols" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.colCount
                    |> Expect.equal 0
        , test "After adding three rows stats should be 2 rows" <|
            \() ->
                emptyCrosstab
                    |> addThreeRows
                    |> Crosstab.rowCount
                    |> Expect.equal 3
        , test "After adding three rows and deleting one of them stats should be two rows" <|
            \() ->
                emptyCrosstab
                    |> addThreeRows
                    |> Crosstab.removeRow ( 1, "row 1" )
                    |> Crosstab.rowCount
                    |> Expect.equal 2
        , test "After deleting one row from empty Crosstab stats should be zero" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.removeRow ( 1, "row 1" )
                    |> Crosstab.rowCount
                    |> Expect.equal 0
        , test "After adding two cols stats should be 2 cols" <|
            \() ->
                emptyCrosstab
                    |> addTwoColumns
                    |> Crosstab.colCount
                    |> Expect.equal 2
        , test "After adding two columns and deleting one of them stats should be one column" <|
            \() ->
                emptyCrosstab
                    |> addTwoColumns
                    |> Crosstab.removeColumn ( 1, "column 1" )
                    |> Crosstab.colCount
                    |> Expect.equal 1
        , test "Switch should switch stats as well" <|
            \() ->
                emptyCrosstab
                    |> addThreeRows
                    |> addTwoColumns
                    |> Crosstab.switchRowsAndColumns identity
                    |> (\c -> ( Crosstab.rowCount c, Crosstab.colCount c ))
                    |> Expect.equal ( 2, 3 )
        , test "Do not raise export when you add Rows and you are at the limit" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addColumn 1 ( 1, "" ) [ () ]
                    |> Crosstab.addRow 2 ( 2, "" ) [ () ]
                    |> Crosstab.addRow 3 ( 3, "" ) [ () ]
                    |> Crosstab.addRow 4 ( 4, "" ) [ () ]
                    |> Crosstab.rowCount
                    |> Expect.equal 3
        , test "Do not raise export when you add Columns and you are at the limit" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addRow 1 ( 1, "" ) [ () ]
                    |> Crosstab.addColumn 2 ( 2, "" ) [ () ]
                    |> Crosstab.addColumn 3 ( 3, "" ) [ () ]
                    |> Crosstab.addColumn 4 ( 4, "" ) [ () ]
                    |> Crosstab.colCount
                    |> Expect.equal 3
        , test "Adding same row the second time adds it twice" <|
            \() ->
                emptyCrosstab
                    |> Crosstab.addRow 1 ( 1, "" ) [ () ]
                    |> Crosstab.addRow 1 ( 1, "" ) [ () ]
                    |> Crosstab.rowCount
                    |> Expect.equal 2
        ]
