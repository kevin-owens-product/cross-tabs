module Gwi.ListTest exposing (listTest)

import Expect
import Gwi.List as List
import Test exposing (..)


listTest : Test
listTest =
    describe "Gwi.List"
        [ describe "selectRange"
            [ test "Nothing selected, select only one item" <|
                \() ->
                    List.selectRange { isSelected = always False, itemToSelect = (==) 2 } [ 1, 2, 3, 4 ]
                        |> Expect.equal [ 2 ]
            , test "First selected range" <|
                \() ->
                    List.selectRange { isSelected = \i -> i == 1, itemToSelect = (==) 3 } [ 1, 2, 3, 4 ]
                        |> Expect.equal [ 2, 3 ]
            , test "First and last selected, clicked in the middle, select range from first" <|
                \() ->
                    [ 1, 2, 3, 4, 5, 6, 7 ]
                        |> List.selectRange { isSelected = \i -> List.member i [ 1, 7 ], itemToSelect = (==) 5 }
                        |> Expect.equal [ 2, 3, 4, 5 ]
            , test "Selected after clicked, select range to already selected" <|
                \() ->
                    [ 1, 2, 3, 4, 5, 6, 7 ]
                        |> List.selectRange { isSelected = \i -> i == 6, itemToSelect = (==) 3 }
                        |> Expect.equal [ 3, 4, 5 ]
            , test "Invalid data" <|
                \() ->
                    [ 1, 2, 3, 4, 5, 6, 7 ]
                        |> List.selectRange { isSelected = \i -> i == 6, itemToSelect = always False }
                        |> Expect.equal []
            ]
        ]
