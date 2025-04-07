module Data.Metric exposing
    ( Metric(..)
    , allMetrics
    , decoder
    , encode
    , encodeMetrics
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type Metric
    = AudiencePercentage
    | DataPointPercentage
    | Universe
    | Index
    | Responses


allMetrics : List Metric
allMetrics =
    List.sortBy toComparable
        {- just ensuring the order is compatible with toComparable function -}
        [ AudiencePercentage
        , DataPointPercentage
        , Universe
        , Index
        , Responses
        ]


{-| Get comparable index for sorting purposes, so you can e.g. sort list of metrics like

    List.sortBy Metric.toComparable [Universe, AudiencePercentage, DataPointPercentage]
    --> [AudiencePercentage, DataPointPercentage, Universe]

-}
toComparable : Metric -> Int
toComparable metric =
    case metric of
        AudiencePercentage ->
            0

        DataPointPercentage ->
            1

        Universe ->
            2

        Index ->
            3

        Responses ->
            4


toString : Metric -> String
toString metric =
    case metric of
        AudiencePercentage ->
            "percentage"

        DataPointPercentage ->
            "horizontal_percentage"

        Universe ->
            "weighted_universe_count"

        Index ->
            "index"

        Responses ->
            "responses_count"


decoder : Decoder Metric
decoder =
    let
        decode metric =
            case metric of
                "percentage" ->
                    Decode.succeed AudiencePercentage

                "horizontal_percentage" ->
                    Decode.succeed DataPointPercentage

                "weighted_universe_count" ->
                    Decode.succeed Universe

                "index" ->
                    Decode.succeed Index

                "responses_count" ->
                    Decode.succeed Responses

                -- Legacy hack based on PRO: temporary hack due api inconsistency
                -- TODO do we still need this?
                "count" ->
                    Decode.succeed Responses

                _ ->
                    Decode.fail <| "Invalid Metric type: " ++ metric
    in
    Decode.andThen decode Decode.string


encode : Metric -> Value
encode metric =
    Encode.string (toString metric)


encodeMetrics : List Metric -> Value
encodeMetrics list =
    Encode.list encode list
