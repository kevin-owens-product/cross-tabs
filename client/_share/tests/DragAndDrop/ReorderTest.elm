module DragAndDrop.ReorderTest exposing (suite)

import DragAndDrop.Fuzzer
import DragAndDrop.Reorder exposing (moveItem)
import Expect
import Test


suite : Test.Test
suite =
    Test.describe "suite"
        [ Test.test "moveItem" <|
            \() ->
                [ moveItem 0 0 []
                , moveItem 0 0 [ 4 ]
                , moveItem 0 0 [ 4, 8 ]
                , moveItem 1 1 [ 4, 8 ]
                , moveItem 0 1 [ 4, 8 ]
                , moveItem 1 0 [ 4, 8 ]
                ]
                    |> Expect.equalLists
                        [ []
                        , [ 4 ]
                        , [ 4, 8 ]
                        , [ 4, 8 ]
                        , [ 8, 4 ]
                        , [ 8, 4 ]
                        ]
        , Test.fuzz DragAndDrop.Fuzzer.ddl "operation == ~operation" <|
            \{ dragIndex, dropIndex, list } ->
                let
                    n : Int
                    n =
                        List.length list - 1
                in
                Expect.equal
                    (moveItem dragIndex dropIndex list)
                    ((List.reverse >> moveItem (n - dragIndex) (n - dropIndex) >> List.reverse) list)
        ]
