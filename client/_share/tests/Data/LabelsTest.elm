module Data.LabelsTest exposing (compatibleTopLevelNamespacesTest, isWave2017OrNewerTest)

import Data.Id as Id exposing (IdDict)
import Data.Labels as Labels exposing (NamespaceCodeTag, NamespaceLineage)
import Dict.Any
import Expect
import Factory.Wave
import RemoteData exposing (RemoteData(..), WebData)
import Set.Any
import Test exposing (..)
import Time exposing (Month(..))


isWave2017OrNewerTest : Test
isWave2017OrNewerTest =
    describe "Data.Labels.isWave2017OrNewer"
        [ test "yes" <|
            \() ->
                Labels.isWave2017OrNewer (Factory.Wave.mock |> Factory.Wave.withStartDate ( 2019, Jan, 1 ))
                    |> Expect.equal True
                    |> Expect.onFail "Should be true"
        , test "no" <|
            \() ->
                Labels.isWave2017OrNewer (Factory.Wave.mock |> Factory.Wave.withStartDate ( 2015, Jan, 1 ))
                    |> Expect.equal False
                    |> Expect.onFail "Should be false"
        , test "yes boundary" <|
            \() ->
                Labels.isWave2017OrNewer (Factory.Wave.mock |> Factory.Wave.withStartDate ( 2017, Jan, 1 ))
                    |> Expect.equal True
                    |> Expect.onFail "Should be true"
        , test "no boundary" <|
            \() ->
                Labels.isWave2017OrNewer (Factory.Wave.mock |> Factory.Wave.withStartDate ( 2016, Jan, 1 ))
                    |> Expect.equal False
                    |> Expect.onFail "Should be false"
        ]


getNamespaceLineageMock ancestors descendants =
    Success { ancestors = ancestors |> List.map Id.fromString, descendants = descendants |> List.map Id.fromString }


mockLineages : IdDict NamespaceCodeTag (WebData NamespaceLineage)
mockLineages =
    Id.emptyDict
        |> Dict.Any.insert (Id.fromString "core")
            (getNamespaceLineageMock []
                [ "gwi-ext"
                , "gwi-mad-cba"
                , "gwi-tvu-rir"
                , "gwi-tyj-yga"
                , "gwi-vry-myl"
                , "gwi-xgi-xig"
                , "gwiq-591dre9"
                , "gwiq-c0068"
                , "gwiq-gjp3509"
                , "gwiq-rv25mov"
                ]
            )
        |> Dict.Any.insert (Id.fromString "gwi-ext") (getNamespaceLineageMock [ "core" ] [ "gwiq-591dre9", "gwiq-c0068", "gwiq-gjp3509" ])


compatibleTopLevelNamespacesTest : Test
compatibleTopLevelNamespacesTest =
    describe "Data.Labels.compatibleTopLevelNamespaces"
        [ test "namespace is topLevel" <|
            \() ->
                Labels.compatibleTopLevelNamespaces mockLineages [ Id.fromString "core" ]
                    |> Expect.equal
                        (Set.Any.fromList Id.unwrap [ Id.fromString "core" ]
                            |> Success
                        )
        ]
