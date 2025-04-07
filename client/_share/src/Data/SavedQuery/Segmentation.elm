module Data.SavedQuery.Segmentation exposing
    ( SegmentId
    , SegmentIdTag
    , Segmentation(..)
    , SplitBases(..)
    , SplitterCode
    , SplitterCodeTag
    , decoder
    , empty
    , getSegmentIds
    , getSplitBases
    , getSplitterCode
    , withSplitBases
    , withSplitterAndSegments
    )

import Data.Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Maybe.Extra as Maybe


type SplitterCodeTag
    = SplitterCodeTag


type SegmentIdTag
    = SegmentIdTag


type alias SplitterCode =
    Id SplitterCodeTag


{-| SegmentId == DatapointCode, but for clarity we keep it separate.
There are casting functions available below.
-}
type alias SegmentId =
    Id SegmentIdTag


type SplitBases
    = SplitBases Bool


type Segmentation
    = Segmentation SplitBases (Maybe ( SplitterCode, List SegmentId ))


empty : Segmentation
empty =
    Segmentation (SplitBases False) Nothing


withSplitBases : Bool -> Segmentation -> Segmentation
withSplitBases splitBases (Segmentation _ splitter) =
    Segmentation (SplitBases splitBases) splitter


withSplitterAndSegments : SplitterCode -> List SegmentId -> Segmentation -> Segmentation
withSplitterAndSegments splitter segments (Segmentation splitBases _) =
    Segmentation splitBases (Just ( splitter, segments ))


decoder : Decoder Segmentation
decoder =
    let
        splitterDecoder : Decoder ( SplitterCode, List SegmentId )
        splitterDecoder =
            Decode.succeed Tuple.pair
                |> Decode.andMap (Decode.at [ "query", "multiplier" ] Data.Id.decode)
                |> Decode.andMap (Decode.at [ "query", "segments" ] (Decode.list Data.Id.decode))
    in
    Decode.succeed Segmentation
        |> Decode.andMap (Decode.map SplitBases <| Decode.withDefault False <| Decode.at [ "query", "split_bases" ] Decode.bool)
        |> Decode.andMap (Decode.maybe splitterDecoder)


getSplitBases : Segmentation -> Bool
getSplitBases (Segmentation (SplitBases splitBases) _) =
    splitBases


getSplitterCode : Segmentation -> Maybe SplitterCode
getSplitterCode (Segmentation _ splitterSegments) =
    Maybe.map Tuple.first splitterSegments


getSegmentIds : Segmentation -> List SegmentId
getSegmentIds (Segmentation _ splitterSegments) =
    Maybe.unwrap [] Tuple.second splitterSegments
