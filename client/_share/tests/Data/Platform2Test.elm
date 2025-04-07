module Data.Platform2Test exposing (dashboardFiltersDecoderTest, datasetCodesForNamespaceCodesTest)

import BiDict.Assoc as BiDict
import Data.Audience.Expression as Expression
import Data.Id exposing (Id(..), IdDict)
import Data.Labels exposing (NamespaceCode, NamespaceCodeTag, NamespaceLineage)
import Data.Platform2
    exposing
        ( DatasetCode
        )
import Dict.Any
import Expect
import Json.Decode as Decode
import Palette exposing (Color(..))
import RemoteData exposing (RemoteData(..), WebData)
import Test exposing (Test)


id : String -> Id tag
id =
    Data.Id.fromString


getNamespaceLineageMock ancestors descendants =
    Success { ancestors = ancestors |> List.map id, descendants = descendants |> List.map id }


mockLineages : IdDict NamespaceCodeTag (WebData NamespaceLineage)
mockLineages =
    Data.Id.emptyDict
        |> Dict.Any.insert (id "core")
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
        |> Dict.Any.insert (id "gwi-ext") (getNamespaceLineageMock [ "core" ] [ "gwiq-591dre9", "gwiq-c0068", "gwiq-gjp3509" ])


datasetsToNamespaces : BiDict.BiDict DatasetCode NamespaceCode
datasetsToNamespaces =
    BiDict.fromList
        [ ( Id "ds-ffe-gup", Id "gwi-ext" )
        , ( Id "ds-ato-byb", Id "gwi-ext" )
        , ( Id "ds-sov-wre", Id "gwi-ext" )
        , ( Id "ds-zuz-kzu", Id "core" )
        , ( Id "ds-cgy-vec", Id "gwi-ext" )
        , ( Id "ds-tka-lup", Id "gwi-ext" )
        , ( Id "ds-wek-uca", Id "gwi-wek-uca" )
        , ( Id "ds-kog-rfu", Id "gwi-kog-rfu" )
        , ( Id "ds-hispanic", Id "gwi-hispanic" )
        , ( Id "ds-core", Id "core" )
        ]


datasetCodesForNamespaceCodesTest : Test
datasetCodesForNamespaceCodesTest =
    Test.describe "Data.Platform2.datasetCodesForNamespaceCodes"
        [ Test.test "Get all with matching baseNamespaceCode" <|
            \() ->
                Data.Platform2.datasetCodesForNamespaceCodes datasetsToNamespaces mockLineages [ id "core" ]
                    |> Expect.equal
                        ([ id "ds-core", id "ds-zuz-kzu" ]
                            |> Success
                        )
        ]


dashboardFiltersDecoderTest : Test
dashboardFiltersDecoderTest =
    let
        case1 =
            """
            {
            "base_audience": "e6d19257-5a94-4359-a5f6-23add471f611",
            "audiences": null,
            "waves": ["q1_2019", "q2_2019", "q3_2019", "q3_2020", "q4_2019"],
            "locations": null,
            "audiences_metadata": {
                "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d": {
                    "color": "Color1"
                },
                "521e347d-8080-4fde-9c2d-ac20e8ee23fe": {
                    "color": "Color4"
                },
                "ce148705-f4fd-4b1c-adfc-6319694607e6": {
                    "color": "Color3"
                },
                "f3a3777c-df65-4864-b9de-be6ed6ae38be": {
                    "color": "Color2"
                }
            }
        }
            """

        case2 =
            """
            {
            "base_audience": "e6d19257-5a94-4359-a5f6-23add471f611",
            "audiences": ["4f68ce1a-3a7b-4b37-be3e-896405cb0a6d", "f3a3777c-df65-4864-b9de-be6ed6ae38be", "ce148705-f4fd-4b1c-adfc-6319694607e6", "521e347d-8080-4fde-9c2d-ac20e8ee23fe"],
            "waves": ["q1_2019", "q2_2019", "q3_2019", "q3_2020", "q4_2019"],
            "locations": null,
            "audiences_metadata": {
                "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d": {
                    "color": "Color1"
                },
                "521e347d-8080-4fde-9c2d-ac20e8ee23fe": {
                    "color": "Color4"
                },
                "ce148705-f4fd-4b1c-adfc-6319694607e6": {
                    "color": "Color3"
                },
                "f3a3777c-df65-4864-b9de-be6ed6ae38be": {
                    "color": "Color2"
                }
            }
        }
            """

        case3 =
            """
            {
            "base_audience": "e6d19257-5a94-4359-a5f6-23add471f611",
            "audiences": ["4f68ce1a-3a7b-4b37-be3e-896405cb0a6d", "f3a3777c-df65-4864-b9de-be6ed6ae38be", "ce148705-f4fd-4b1c-adfc-6319694607e6", "521e347d-8080-4fde-9c2d-ac20e8ee23fe"],
            "audiences_data": [
                {"id": "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d", "name": "Whatever name", "expression": {"and":[{"question":"q6","datapoints":["q6_1"],"min_count":1,"not":false}]}}
            ],
            "waves": ["q1_2019", "q2_2019", "q3_2019", "q3_2020", "q4_2019"],
            "locations": null,
            "audiences_metadata": {
                "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d": {
                    "color": "Color1"
                },
                "521e347d-8080-4fde-9c2d-ac20e8ee23fe": {
                    "color": "Color4"
                },
                "ce148705-f4fd-4b1c-adfc-6319694607e6": {
                    "color": "Color3"
                },
                "f3a3777c-df65-4864-b9de-be6ed6ae38be": {
                    "color": "Color2"
                }
            }
        }
            """
    in
    Test.describe "Data.Platform2.dashboardFiltersDecoder"
        [ Test.test "Decode correctly audiences if there are none" <|
            \() ->
                Decode.decodeString Data.Platform2.dashboardFiltersDecoder case1
                    |> Expect.equal
                        (Ok
                            { baseAudience = Just (Data.Id.fromString "e6d19257-5a94-4359-a5f6-23add471f611")
                            , audiences = Nothing
                            , audiencesData = Nothing
                            , audiencesMetadata =
                                [ ( Data.Id.fromString "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d", { color = Color1 } )
                                , ( Data.Id.fromString "521e347d-8080-4fde-9c2d-ac20e8ee23fe", { color = Color4 } )
                                , ( Data.Id.fromString "ce148705-f4fd-4b1c-adfc-6319694607e6", { color = Color3 } )
                                , ( Data.Id.fromString "f3a3777c-df65-4864-b9de-be6ed6ae38be", { color = Color2 } )
                                ]
                                    |> Data.Id.dictFromList
                            , waves =
                                [ "q1_2019", "q2_2019", "q3_2019", "q3_2020", "q4_2019" ]
                                    |> List.map Data.Id.fromString
                                    |> Just
                            , locations = Nothing
                            }
                        )
        , Test.test "Decode correctly audiences if there are some and no data" <|
            \() ->
                Decode.decodeString Data.Platform2.dashboardFiltersDecoder case2
                    |> Expect.equal
                        (Ok
                            { baseAudience = Just (Data.Id.fromString "e6d19257-5a94-4359-a5f6-23add471f611")
                            , audiences =
                                [ "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d", "f3a3777c-df65-4864-b9de-be6ed6ae38be", "ce148705-f4fd-4b1c-adfc-6319694607e6", "521e347d-8080-4fde-9c2d-ac20e8ee23fe" ]
                                    |> List.map Data.Id.fromString
                                    |> Just
                            , audiencesData = Nothing
                            , audiencesMetadata =
                                [ ( Data.Id.fromString "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d", { color = Color1 } )
                                , ( Data.Id.fromString "521e347d-8080-4fde-9c2d-ac20e8ee23fe", { color = Color4 } )
                                , ( Data.Id.fromString "ce148705-f4fd-4b1c-adfc-6319694607e6", { color = Color3 } )
                                , ( Data.Id.fromString "f3a3777c-df65-4864-b9de-be6ed6ae38be", { color = Color2 } )
                                ]
                                    |> Data.Id.dictFromList
                            , waves =
                                [ "q1_2019", "q2_2019", "q3_2019", "q3_2020", "q4_2019" ]
                                    |> List.map Data.Id.fromString
                                    |> Just
                            , locations = Nothing
                            }
                        )
        , Test.test "Decode correctly audiences if there are also data" <|
            \() ->
                Decode.decodeString Data.Platform2.dashboardFiltersDecoder case3
                    |> Expect.equal
                        (Ok
                            { baseAudience = Just (Data.Id.fromString "e6d19257-5a94-4359-a5f6-23add471f611")
                            , audiences =
                                [ "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d", "f3a3777c-df65-4864-b9de-be6ed6ae38be", "ce148705-f4fd-4b1c-adfc-6319694607e6", "521e347d-8080-4fde-9c2d-ac20e8ee23fe" ]
                                    |> List.map Data.Id.fromString
                                    |> Just
                            , audiencesData =
                                [ ( Data.Id.fromString "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d"
                                  , { id = Data.Id.fromString "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d"
                                    , name = "Whatever name"
                                    , expression =
                                        Expression.Node Expression.And
                                            ( Expression.Leaf
                                                { datapointCodes = [ Data.Id.fromString "q6_1" ]
                                                , inclusion = Expression.Include
                                                , minCount = 1
                                                , questionCode = Data.Id.fromString "q6"
                                                , suffixCodes = []
                                                }
                                            , []
                                            )
                                    }
                                  )
                                ]
                                    |> Data.Id.dictFromList
                                    |> Just
                            , audiencesMetadata =
                                [ ( Data.Id.fromString "4f68ce1a-3a7b-4b37-be3e-896405cb0a6d", { color = Color1 } )
                                , ( Data.Id.fromString "521e347d-8080-4fde-9c2d-ac20e8ee23fe", { color = Color4 } )
                                , ( Data.Id.fromString "ce148705-f4fd-4b1c-adfc-6319694607e6", { color = Color3 } )
                                , ( Data.Id.fromString "f3a3777c-df65-4864-b9de-be6ed6ae38be", { color = Color2 } )
                                ]
                                    |> Data.Id.dictFromList
                            , waves =
                                [ "q1_2019", "q2_2019", "q3_2019", "q3_2020", "q4_2019" ]
                                    |> List.map Data.Id.fromString
                                    |> Just
                            , locations = Nothing
                            }
                        )
        ]
