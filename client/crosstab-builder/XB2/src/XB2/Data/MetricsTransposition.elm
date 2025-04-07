module XB2.Data.MetricsTransposition exposing
    ( MetricsTransposition(..)
    , decoder
    , encode
    , metricAnalyticsName
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type MetricsTransposition
    = MetricsInRows
    | MetricsInColumns


metricAnalyticsName : MetricsTransposition -> String
metricAnalyticsName metricsTransposition =
    case metricsTransposition of
        MetricsInRows ->
            "row_metrics"

        MetricsInColumns ->
            "column_metrics"


decoder : Decoder MetricsTransposition
decoder =
    let
        decode transposition =
            case transposition of
                "row_metrics" ->
                    Decode.succeed MetricsInRows

                "column_metrics" ->
                    Decode.succeed MetricsInColumns

                _ ->
                    Decode.fail <| "Invalid transposition type: " ++ transposition
    in
    Decode.andThen decode Decode.string


encode : MetricsTransposition -> Value
encode =
    Encode.string << metricAnalyticsName
