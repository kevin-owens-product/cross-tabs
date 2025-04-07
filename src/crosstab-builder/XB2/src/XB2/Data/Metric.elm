module XB2.Data.Metric exposing
    ( Metric(..)
    , allMetrics
    , decoder
    , description
    , encode
    , label
    , toString
    )

{-| -}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


{-| There was also the Percentage metric but we never used it.
Corresponds to `AudienceIntersection.percentage`.
-}
type Metric
    = Size
    | Sample
    | Index
    | RowPercentage
    | ColumnPercentage


allMetrics : List Metric
allMetrics =
    [ Size
    , Sample
    , ColumnPercentage
    , RowPercentage
    , Index
    ]


toString : Metric -> String
toString metric =
    case metric of
        Size ->
            "size"

        Sample ->
            "sample"

        ColumnPercentage ->
            "column_percentage"

        RowPercentage ->
            "row_percentage"

        Index ->
            "index"


label : Metric -> String
label metric =
    case metric of
        Size ->
            "Universe"

        Sample ->
            "Responses"

        ColumnPercentage ->
            "% Column"

        RowPercentage ->
            "% Row"

        Index ->
            "Index"


description : Metric -> String
description metric =
    case metric of
        Size ->
            "An estimate of the real world population that match both the row and column."

        Sample ->
            "The number of actual people on the panel that match both the row and column."

        ColumnPercentage ->
            "The proportion of the column who also match the row."

        RowPercentage ->
            "The proportion of the row who also match the column."

        Index ->
            "The relative affinity of the row and column combination compared to the base."


fromString : String -> Maybe Metric
fromString metric =
    case metric of
        "size" ->
            Just Size

        "sample" ->
            Just Sample

        "column_percentage" ->
            Just ColumnPercentage

        "row_percentage" ->
            Just RowPercentage

        "index" ->
            Just Index

        _ ->
            Nothing


decoder : Decoder Metric
decoder =
    let
        decode metric =
            fromString metric
                |> Maybe.map Decode.succeed
                |> Maybe.withDefault (Decode.fail <| "Invalid XB Metric type: " ++ metric)
    in
    Decode.andThen decode Decode.string


encode : Metric -> Value
encode =
    Encode.string << toString
