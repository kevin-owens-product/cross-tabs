module RemoteData.LoadedTest exposing (suite)

import Expect
import Http exposing (Error(..))
import RemoteData.Loaded as RD exposing (RemoteData(..), WebData)
import Test exposing (..)


suite : Test
suite =
    describe "RemoteData.Loaded"
        [ describe "Monad laws"
            [ test "Left identity" <|
                \() ->
                    SuccessL 1
                        |> RD.andThen addOne
                        |> Expect.equal (addOne 1)
            , describe "Right identity"
                [ test "SuccessL" <|
                    \() -> SuccessL 1 |> RD.andThen addOne |> Expect.equal (SuccessL 2)
                , test "LoadingL (Just a)" <|
                    \() -> LoadingL (Just 1) |> RD.andThen addOne |> Expect.equal (LoadingL (Just 2))
                , test "LoadingL Nothing" <|
                    \() -> LoadingL Nothing |> RD.andThen addOne |> Expect.equal (LoadingL Nothing)
                , test "NotAskedL" <|
                    \() -> NotAskedL |> RD.andThen addOne |> Expect.equal NotAskedL
                , test "FailureL e" <|
                    \() -> FailureL Timeout |> RD.andThen addOne |> Expect.equal (FailureL Timeout)
                ]
            ]
        , describe "isSuccess"
            [ test "SuccessL" <| \() -> RD.isSuccess (SuccessL ()) |> Expect.equal True
            , test "LoadingL Nothing" <| \() -> RD.isSuccess (LoadingL Nothing) |> Expect.equal False
            , test "LoadingL (Just _)" <| \() -> RD.isSuccess (LoadingL (Just ())) |> Expect.equal False
            , test "NotAskedL" <| \() -> RD.isSuccess NotAskedL |> Expect.equal False
            , test "FailureL ()" <| \() -> RD.isSuccess (FailureL ()) |> Expect.equal False
            ]
        ]


addOne : Int -> WebData Int
addOne x =
    SuccessL (x + 1)
