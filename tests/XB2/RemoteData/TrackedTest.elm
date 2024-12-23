module XB2.RemoteData.TrackedTest exposing (remoteDataTrackedTest)

import Expect
import Test exposing (Test, describe, test)
import XB2.RemoteData.Tracked as RD exposing (RemoteData(..))


remoteDataTrackedTest : Test
remoteDataTrackedTest =
    describe "RemoteData.Tracked"
        [ describe "withDefault"
            [ test "Success" <| \() -> RD.withDefault 0 (Success 1) |> Expect.equal 1
            , test "Failure" <| \() -> RD.withDefault 0 (Failure ()) |> Expect.equal 0
            , test "NotAsked" <| \() -> RD.withDefault 0 NotAsked |> Expect.equal 0
            , test "Loading Nothing" <| \() -> RD.withDefault 0 (Loading Nothing) |> Expect.equal 0
            , test "Loading (Just x)" <| \() -> RD.withDefault 0 (Loading (Just "trackerId")) |> Expect.equal 0
            ]
        ]
