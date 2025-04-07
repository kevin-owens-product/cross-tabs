module Data.CoreTest exposing (audienceDecoderTest, savedQueryDecoderTest)

-- Core

import D3Charts.ChartBuilder
import Data.Audience.Expression
import Data.Core as Core exposing (Audience)
import Data.Core.DatapointsSort exposing (DatapointsSort(..))
import Data.Id
import Data.Metric exposing (Metric(..))
import Data.SavedQuery.Segmentation
import Expect
import Json.Decode as Decode
import List.NonEmpty as NonemptyList
import Test exposing (..)


type DecodeResult
    = DecodedNicely
    | DecodedSadly String


isOk : Result a b -> DecodeResult
isOk res =
    case res of
        Ok _ ->
            DecodedNicely

        Err e ->
            DecodedSadly <| Debug.toString e


savedQueryDecoderTest : Test
savedQueryDecoderTest =
    let
        decode =
            Decode.decodeString Core.savedQueryDecoder
    in
    describe "Data.Core.savedQueryDecoder"
        [ test "doesn't fail with missing filters - PLAT-514" <|
            \() ->
                decode
                    """
                    {
                        "id": 0,
                        "name": "foo",
                        "position": 0,
                        "query": {
                            "question": "bar",
                            "multiplier": 0,
                            "segments": []
                        }
                    }
                    """
                    |> isOk
                    |> Expect.equal DecodedNicely
        , test "Decode suffixes correctly - AT-27" <|
            \() ->
                decode
                    """
                    {
                        "id": 897,
                        "name": "Lifestyle Indicators - limited options",
                        "position": 4157440.0,
                        "query": {
                            "question": "q4155",
                            "audiences": [],
                            "options": ["q4155_3"],
                            "activeOptions": ["q4155_3"],
                            "filter": {},
                            "segments": [],
                            "suffixes": [1, 2],
                            "split_bases": false,
                            "chartType": "vertical_bar_chart",
                            "orderType": "sort-alphabetical",
                            "datapoints": ["percentage", "horizontal_percentage", "weighted_universe_count", "index", "count"],
                            "metrics": ["percentage", "horizontal_percentage", "weighted_universe_count", "index", "count"]
                        }
                    }
                    """
                    |> Expect.equal
                        (Ok
                            { id = Data.Id.fromString "897"
                            , name = "Lifestyle Indicators - limited options"
                            , position = 4157440.0
                            , questionCode = Data.Id.fromString "q4155"
                            , activeDatapointCodes = [ Data.Id.fromString "q4155_3" ]
                            , suffixCodes = Just <| NonemptyList.map Data.Id.fromString ( "1", [ "2" ] )
                            , audienceIds = []
                            , segmentation = Data.SavedQuery.Segmentation.empty
                            , filters =
                                { locationCodes = []
                                , waveCodes = []
                                , baseAudience = Nothing
                                }
                            , chartType = D3Charts.ChartBuilder.AdvancedVerticalBarChart
                            , metrics = [ AudiencePercentage, DataPointPercentage, Universe, Index, Responses ]
                            , orderType = Default
                            }
                        )
        , test "Decode correctly with all filters and split bases" <|
            \() ->
                decode
                    """
                    {
                        "id": 897,
                        "name": "Lifestyle Indicators - limited options",
                        "position": 4157440.0,
                        "query": {
                            "question": "q4155",
                            "audiences": ["3417"],
                            "options": ["q4155_3"],
                            "activeOptions": ["q4155_3"],
                            "filter": { "locations": ["s2_43", "s2_32"], "waves" : ["q1_2018"], "audiences" : ["666"]  },
                            "segments": ["i1_1"],
                            "suffixes": [1, 2],
                            "split_bases": true,
                            "multiplier" : "waves",
                            "chartType": "horizontal_bar_chart",
                            "orderType": "sort-whatever",
                            "datapoints": ["percentage", "horizontal_percentage", "count"],
                            "metrics": ["percentage", "horizontal_percentage", "count"]
                        }
                    }
                    """
                    |> Expect.equal
                        (Ok
                            { id = Data.Id.fromString "897"
                            , name = "Lifestyle Indicators - limited options"
                            , position = 4157440.0
                            , questionCode = Data.Id.fromString "q4155"
                            , activeDatapointCodes = [ Data.Id.fromString "q4155_3" ]
                            , suffixCodes = Just <| NonemptyList.map Data.Id.fromString ( "1", [ "2" ] )
                            , audienceIds = [ Data.Id.fromString "3417" ]
                            , segmentation =
                                Data.SavedQuery.Segmentation.empty
                                    |> Data.SavedQuery.Segmentation.withSplitBases True
                                    |> Data.SavedQuery.Segmentation.withSplitterAndSegments
                                        (Data.Id.fromString "waves")
                                        [ Data.Id.fromString "i1_1" ]
                            , filters =
                                { locationCodes = List.map Data.Id.fromString [ "s2_43", "s2_32" ]
                                , waveCodes = [ Data.Id.fromString "q1_2018" ]
                                , baseAudience = Just <| Data.Id.fromString "666"
                                }
                            , chartType = D3Charts.ChartBuilder.AdvancedHorizontalBarChart
                            , metrics = [ AudiencePercentage, DataPointPercentage, Responses ]
                            , orderType = Default
                            }
                        )
        ]


audienceDecoderTest : Test
audienceDecoderTest =
    let
        decode =
            Decode.decodeString Core.audienceDecoder

        testCase : String -> Maybe String -> Int -> Test
        testCase description jsonSubstring expectedResult =
            test description <|
                \() ->
                    decode (json jsonSubstring)
                        |> Result.mapError Decode.errorToString
                        |> findMinCount
                        |> Expect.equal (Ok expectedResult)

        findMinCount : Result String Audience -> Result String Int
        findMinCount result =
            result
                |> Result.andThen
                    (\{ expression } ->
                        expression
                            |> Data.Audience.Expression.foldr
                                (\{ minCount } searchResult ->
                                    if searchResult == Nothing then
                                        Just minCount

                                    else
                                        searchResult
                                )
                                Nothing
                            |> Result.fromMaybe "Couldn't find minCount"
                    )

        json : Maybe String -> String
        json minCount =
            """
            {
              "id": 13817,
              "name": "MinCount3",
              "expression": {
                "and": [
                  {
                    "options": [
                      "q127ag4_27",
                      "q127ag4_35",
                      "q127ag4_37",
                      "q127ag4_39",
                      "q127ag4_33",
                      "q127ag4_21",
                      "q127ag4_34",
                      "q127ag4_7"
                    ],
                    "question": "q127ag4" """
                ++ (case minCount of
                        Nothing ->
                            ""

                        Just string ->
                            """, "min_count": """ ++ string
                   )
                ++ """
                  }
                ]
              },
              "curated": null,
              "type": "user",
              "shared": false,
              "folder": null,
              "created_at": 1537905295,
              "updated_at": 1537905295,
              "user_id": 0
            }
            """
    in
    describe "Data.Core.audienceDecoder"
        [ testCase "min_count int works" (Just "3") 3
        , testCase "min_count string works" (Just "\"4\"") 4
        , testCase "min_count null defaults to 1" (Just "null") 1
        , testCase "min_count missing defaults to 1" Nothing 1
        ]
