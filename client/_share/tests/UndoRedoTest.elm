module UndoRedoTest exposing (undoRedoTest)

import Basics.Extra exposing (flip)
import Expect
import Test exposing (Test, describe, test)
import UndoRedo


undoRedoTest : Test
undoRedoTest =
    describe "UndoRedo module test"
        [ test "init" <|
            \() ->
                UndoRedo.init 3 "current"
                    |> Expect.all
                        [ Expect.equal "current" << UndoRedo.current
                        , Expect.equal False << UndoRedo.hasPast
                        , Expect.equal False << UndoRedo.hasFuture
                        ]
        , test "update history once" <|
            \() ->
                UndoRedo.init 3 "current"
                    |> UndoRedo.commit () ((++) "edited ")
                    |> Expect.all
                        [ Expect.equal "edited current" << UndoRedo.current
                        , Expect.equal True << UndoRedo.hasPast
                        , Expect.equal False << UndoRedo.hasFuture
                        , Expect.equal 1 << UndoRedo.lengthPast
                        ]
        , test "update history - hit limit" <|
            \() ->
                UndoRedo.init 2 "current"
                    |> UndoRedo.commit () ((++) " | edited ")
                    |> UndoRedo.commit () ((++) " | edited again")
                    |> UndoRedo.commit () ((++) "edited last time")
                    |> Expect.all
                        [ Expect.equal "edited last time | edited again | edited current" << UndoRedo.current
                        , Expect.equal True << UndoRedo.hasPast
                        , Expect.equal False << UndoRedo.hasFuture
                        , Expect.equal 2 << UndoRedo.lengthPast
                        ]
        , test "update history - hit limit do undo" <|
            \() ->
                UndoRedo.init 2 "current"
                    |> UndoRedo.commit () ((++) " | edited ")
                    |> UndoRedo.commit () ((++) " | edited again")
                    |> UndoRedo.commit () ((++) "edited last time")
                    |> UndoRedo.undo
                    |> UndoRedo.undo
                    |> UndoRedo.undo
                    |> UndoRedo.undo
                    |> Expect.all
                        [ Expect.equal " | edited current" << UndoRedo.current
                        , Expect.equal False << UndoRedo.hasPast
                        , Expect.equal True << UndoRedo.hasFuture
                        , Expect.equal 0 << UndoRedo.lengthPast
                        , Expect.equal 2 << UndoRedo.lengthFuture
                        ]
        , test "update history - hit limit, do undo, do rendo" <|
            \() ->
                UndoRedo.init 2 "current"
                    |> UndoRedo.commit () ((++) " | edited ")
                    |> UndoRedo.commit () ((++) " | edited again")
                    |> UndoRedo.commit () ((++) "edited last time")
                    |> UndoRedo.undo
                    |> UndoRedo.undo
                    |> UndoRedo.undo
                    |> UndoRedo.redo
                    |> UndoRedo.redo
                    |> UndoRedo.redo
                    |> Expect.all
                        [ Expect.equal "edited last time | edited again | edited current" << UndoRedo.current
                        , Expect.equal True << UndoRedo.hasPast
                        , Expect.equal False << UndoRedo.hasFuture
                        , Expect.equal 2 << UndoRedo.lengthPast
                        , Expect.equal 0 << UndoRedo.lengthFuture
                        ]
        , test "update history, do undo, update current - future is cleaned" <|
            \() ->
                UndoRedo.init 2 "current"
                    |> UndoRedo.commit () ((++) " | edited ")
                    |> UndoRedo.commit () ((++) " | edited again")
                    |> UndoRedo.undo
                    |> UndoRedo.commit () ((++) "edited last time")
                    |> Expect.all
                        [ Expect.equal "edited last time | edited current" << UndoRedo.current
                        , Expect.equal True << UndoRedo.hasPast
                        , Expect.equal False << UndoRedo.hasFuture
                        , Expect.equal 2 << UndoRedo.lengthPast
                        , Expect.equal 0 << UndoRedo.lengthFuture
                        ]
        , describe "set history"
            [ test "overflow history" <|
                \() ->
                    UndoRedo.init 3 0
                        |> UndoRedo.new () 1
                        |> UndoRedo.new () 2
                        |> UndoRedo.new () 3
                        |> UndoRedo.new () 4
                        |> Expect.all
                            [ Expect.equal 4 << UndoRedo.current
                            , Expect.equal True << UndoRedo.hasPast
                            , Expect.equal False << UndoRedo.hasFuture
                            , Expect.equal 3 << UndoRedo.lengthPast
                            ]
            , test "overflow history, do undo once" <|
                \() ->
                    UndoRedo.init 3 0
                        |> UndoRedo.new () 1
                        |> UndoRedo.new () 2
                        |> UndoRedo.new () 3
                        |> UndoRedo.new () 4
                        |> UndoRedo.undo
                        |> Expect.all
                            [ Expect.equal 3 << UndoRedo.current
                            , Expect.equal True << UndoRedo.hasPast
                            , Expect.equal True << UndoRedo.hasFuture
                            , Expect.equal 2 << UndoRedo.lengthPast
                            , Expect.equal 1 << UndoRedo.lengthFuture
                            ]
            , test "overflow history, do undo more than history size" <|
                \() ->
                    UndoRedo.init 3 0
                        |> UndoRedo.new () 1
                        |> UndoRedo.new () 2
                        |> UndoRedo.new () 3
                        |> UndoRedo.new () 4
                        |> flip (List.foldl (<|)) (List.repeat 4 UndoRedo.undo)
                        |> Expect.all
                            [ Expect.equal 1 << UndoRedo.current
                            , Expect.equal False << UndoRedo.hasPast
                            , Expect.equal True << UndoRedo.hasFuture
                            , Expect.equal 0 << UndoRedo.lengthPast
                            , Expect.equal 3 << UndoRedo.lengthFuture
                            ]
            , test "overflow history, do undo and rendo over history limit" <|
                \() ->
                    UndoRedo.init 3 0
                        |> UndoRedo.new () 1
                        -- [0],1,[]
                        |> UndoRedo.new () 2
                        -- [0,1],2,[]
                        |> UndoRedo.new () 3
                        -- [0,1,2],3,[]
                        |> UndoRedo.new () 4
                        -- [1,2,3],4,[]
                        |> flip (List.foldl (<|)) (List.repeat 5 UndoRedo.undo)
                        |> flip (List.foldl (<|)) (List.repeat 5 UndoRedo.redo)
                        |> Expect.all
                            [ Expect.equal 4 << UndoRedo.current
                            , Expect.equal True << UndoRedo.hasPast
                            , Expect.equal False << UndoRedo.hasFuture
                            , Expect.equal 3 << UndoRedo.lengthPast
                            , Expect.equal 0 << UndoRedo.lengthFuture
                            ]
            ]
        ]
