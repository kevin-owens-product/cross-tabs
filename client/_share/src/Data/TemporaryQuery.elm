module Data.TemporaryQuery exposing
    ( TemporaryQuery
    , Version(..)
    , decode
    , encode
    )

{- These are very similar to SavedQueries, but are never saved. Basically they're
   serializing/deserializing the current state of ChartBuilder view: all the
   query-related data but also all the view options.

   All that to be able to create and share links to CB.Router.Question routes
   with specific view options:

   https://app.globalwebindex.com/chart-builder/questions/q2?view=<BLOB>

   We can then decode those blobs and set the CB state with them, as we do with
   SavedQueries.

   ----

   This is meant mainly for platform links in report PDFs, but end-users can
   create them too.

-}

import Base64
import D3Charts.ChartBuilder
import Data.Core exposing (AudienceId)
import Data.Core.DatapointsSort as DatapointsSort exposing (DatapointsSort)
import Data.Id as Id
import Data.Labels
    exposing
        ( LocationCode
        , QuestionAndDatapointCode
        , SuffixCode
        , WaveCode
        )
import Data.Metric as Metric exposing (Metric)
import Data.SavedQuery.Segmentation
    exposing
        ( SegmentId
        , Segmentation(..)
        , SplitBases(..)
        , SplitterCode
        )
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Maybe.Extra as Maybe


type alias TemporaryQuery =
    { activeDatapointCodes : List QuestionAndDatapointCode
    , suffixCodes : Maybe (NonEmpty SuffixCode)
    , audienceIds : List AudienceId
    , segmentation : Segmentation
    , filters :
        { locationCodes : List LocationCode
        , waveCodes : List WaveCode
        , baseAudience : Maybe AudienceId
        }
    , chartType : D3Charts.ChartBuilder.ChartType
    , metrics : List Metric
    , orderType : DatapointsSort
    , areSegmentsSwitched : Bool
    , ordinate : Metric
    }


type Version
    = {- JSON + Base64 -} V1


encode : Version -> TemporaryQuery -> String
encode v query =
    case v of
        V1 ->
            encodeV1 query


{-| JSON >> Base64 approach, largely copied from Data.Core.encodeSavedQuery
-}
encodeV1 : TemporaryQuery -> String
encodeV1 query =
    let
        filter =
            Encode.object
                [ ( "waves", Encode.list Id.encode query.filters.waveCodes )
                , ( "locations", Encode.list Id.encode query.filters.locationCodes )
                , ( "audiences"
                  , Encode.list Id.encode <|
                        Maybe.unwrap [] List.singleton query.filters.baseAudience
                  )
                ]

        splitter_ =
            Data.SavedQuery.Segmentation.getSplitterCode query.segmentation
                |> Maybe.map (Tuple.pair "splitter" << Id.encode)

        segments =
            Data.SavedQuery.Segmentation.getSegmentIds query.segmentation
    in
    [ Just ( "datapoints", Encode.list Id.encode query.activeDatapointCodes )
    , Just ( "audiences", Encode.list Id.encode query.audienceIds )
    , Just ( "filter", filter )
    , Just ( "segments", Encode.list Id.encode segments )
    , Just ( "split_bases", Encode.bool <| Data.SavedQuery.Segmentation.getSplitBases query.segmentation )
    , Just ( "chart_type", D3Charts.ChartBuilder.encodeChartType query.chartType )
    , Just ( "order_type", DatapointsSort.encodeForQuery query.orderType )
    , Just ( "metrics", Metric.encodeMetrics query.metrics )
    , Just ( "are_segments_switched", Encode.bool query.areSegmentsSwitched )
    , Just ( "ordinate", Metric.encode query.ordinate )
    , Just
        ( "suffixes"
        , Encode.list Id.encode <|
            Maybe.unwrap
                []
                NonemptyList.toList
                query.suffixCodes
        )
    , splitter_
    ]
        |> Maybe.values
        |> Encode.object
        |> Encode.encode 0
        |> Base64.fromString
        |> Maybe.withDefault {- should never happen -} ""


{-| These decoders don't need to necessarily be JSON ones. It's probably the
easiest solution but other ones like custom binary format using `elm/bytes`
might be more efficient.

Here's a comparison of the APIs:

  - Json.Decode.decodeString : Json.Decode.Decoder a -> String -> Result Json.Decode.Error a
  - Bytes.Decode.decode : Bytes.Decode.Decoder a -> Bytes -> Maybe a

So we're going for a common denominator: `String -> Maybe a` (expecting that for
conversion between String and Bytes we'd use something like danfishgold/base64-bytes).

To try them in sequence from the newest to the oldest we can use

    decodeV3 blob
        |> Maybe.orElseLazy (\() -> decodeV2 blob)
        |> Maybe.orElseLazy (\() -> decodeV1 blob)

-}
decode : String -> Maybe ( Version, TemporaryQuery )
decode blob =
    decodeV1 blob


{-| Base64 >> JSON approach, largely copied from Data.Core.savedQueryDecoder
-}
decodeV1 : String -> Maybe ( Version, TemporaryQuery )
decodeV1 blob =
    blob
        |> Base64.toString
        |> Maybe.andThen
            (Decode.decodeString decoderV1
                >> Result.toMaybe
            )
        |> Maybe.map (Tuple.pair V1)


decoderV1 : Decoder TemporaryQuery
decoderV1 =
    let
        filtersDecoder =
            Decode.succeed
                (\locationCodes waveCodes audiences ->
                    { waveCodes = waveCodes
                    , locationCodes = locationCodes
                    , baseAudience = audiences |> Maybe.andThen List.head
                    }
                )
                |> Decode.andMap (Decode.field "locations" (Decode.list Id.decode))
                |> Decode.andMap (Decode.field "waves" (Decode.list Id.decode))
                |> Decode.andMap (Decode.optionalField "audiences" (Decode.list Id.decode))

        splitterDecoder : Decoder ( SplitterCode, List SegmentId )
        splitterDecoder =
            Decode.succeed Tuple.pair
                |> Decode.andMap (Decode.field "splitter" Id.decode)
                |> Decode.andMap (Decode.field "segments" (Decode.list Id.decode))

        segmentationDecoder : Decoder Segmentation
        segmentationDecoder =
            Decode.succeed Segmentation
                |> Decode.andMap (Decode.map SplitBases <| Decode.field "split_bases" Decode.bool)
                |> Decode.andMap (Decode.maybe splitterDecoder)
    in
    Decode.succeed TemporaryQuery
        |> Decode.andMap (Decode.field "datapoints" (Decode.list Id.decode))
        |> Decode.andMap
            (Decode.optionalField "suffixes" (Decode.list Id.decode)
                |> Decode.map (Maybe.andThen NonemptyList.fromList)
            )
        |> Decode.andMap (Decode.field "audiences" (Decode.list Id.decode))
        |> Decode.andMap segmentationDecoder
        |> Decode.andMap (Decode.field "filter" filtersDecoder)
        |> Decode.andMap (Decode.field "chart_type" D3Charts.ChartBuilder.chartTypeDecoder)
        |> Decode.andMap (Decode.field "metrics" (Decode.list Metric.decoder))
        |> Decode.andMap (Decode.field "order_type" DatapointsSort.decoder)
        |> Decode.andMap (Decode.field "are_segments_switched" Decode.bool)
        |> Decode.andMap (Decode.field "ordinate" Metric.decoder)
