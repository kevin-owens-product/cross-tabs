module Data.Audience.Expression exposing
    ( AudienceExpression(..)
    , AudienceInclusion(..)
    , LeafData
    , LogicOperator(..)
    , decoder
    , encodeV2
    , foldr
    , isEmpty
    , sizeExpression
    )

import Data.Id
import Data.Labels
    exposing
        ( NamespaceAndQuestionCode
        , QuestionAndDatapointCode
        , SuffixCode
        )
import Gwi.Json.Decode exposing (stringOrInt)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode exposing (Value)
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Maybe.Extra as Maybe


type LogicOperator
    = And
    | Or


type AudienceInclusion
    = Include
    | Exclude


type alias LeafData =
    { inclusion : AudienceInclusion
    , minCount : Int
    , questionCode : NamespaceAndQuestionCode
    , datapointCodes : List QuestionAndDatapointCode
    , suffixCodes : List SuffixCode
    }


type AudienceExpression
    = AllRespondents
    | Node LogicOperator (NonEmpty AudienceExpression)
    | Leaf LeafData


{-| This acts like an identity element in monoidal composition of audience expressions.
Anyway only in cases where equality isn't considered for built-in `(==)` operator
(which can't be overloaded in Elm) but when the equality is defined in terms
of which data are returned from API when audience is applied on any arbitrary question.

  - question code `q999` means "Audience Size" (hardcoded constrain of a system)
  - option code `q999_99` means "All Internet users"

So in another words size of rest of expressions for all respondents.
This is guaranteed to yield same data when as any expression `e` when intersected witch such.

    e == intersection e sizeExpression

-}
sizeExpression : AudienceExpression
sizeExpression =
    AllRespondents


isEmpty : AudienceExpression -> Bool
isEmpty expression =
    expression == AllRespondents


foldr : (LeafData -> b -> b) -> b -> AudienceExpression -> b
foldr f acc expression =
    case expression of
        AllRespondents ->
            acc

        Leaf leaf ->
            f leaf acc

        Node _ subnodes ->
            NonemptyList.foldr (\exp listAcc -> foldr f listAcc exp) acc subnodes


{-| There are some field renamings in process; eg. core /audiences is V1 and uses
"options" for datapoints and core-next (eg. the export services) are V2 and use
"datapoints" instead.

We are forced to send _just_ the field name each service understands. This type
helps with that.

-}
type TargetAPI
    = V2


encodeV2 : AudienceExpression -> Value
encodeV2 =
    encode V2


encode : TargetAPI -> AudienceExpression -> Value
encode targetApi expr =
    case expr of
        AllRespondents ->
            Encode.null

        Leaf data ->
            let
                datapointsField : String
                datapointsField =
                    case targetApi of
                        V2 ->
                            "datapoints"
            in
            [ Just ( "question", Data.Id.encode data.questionCode )
            , Just ( datapointsField, Encode.list Data.Id.encode data.datapointCodes )
            , Just ( "min_count", Encode.int data.minCount )
            , Just ( "not", Encode.bool (data.inclusion == Exclude) )
            , if List.isEmpty data.suffixCodes then
                Nothing

              else
                Just ( "suffixes", Encode.list Data.Id.encode data.suffixCodes )
            ]
                |> Maybe.values
                |> Encode.object

        Node logic nested ->
            let
                key =
                    case logic of
                        And ->
                            "and"

                        Or ->
                            "or"
            in
            Encode.object [ ( key, NonemptyList.encodeList (encode targetApi) nested ) ]


allRespondentsDecoder : Decoder AudienceExpression
allRespondentsDecoder =
    let
        fromPairs xs =
            case xs of
                [] ->
                    Decode.succeed AllRespondents

                [ ( _, () ) ] ->
                    Decode.succeed AllRespondents

                _ ->
                    Decode.fail "expected {}"
    in
    Decode.oneOf
        [ Decode.null AllRespondents
        , {- TODO: legacy representation of all internet users
             Should be possible to remove:
          -}
          Decode.keyValuePairs (Decode.succeed ())
            |> Decode.andThen fromPairs
        ]


decoder_ : { nestedCall : Bool } -> Decoder AudienceExpression
decoder_ { nestedCall } =
    Decode.oneOf
        [ Decode.lazy (\() -> nodeDecoder)
        , leafDecoder
        , if nestedCall then
            Decode.fail "Invalid nested structure"

          else
            allRespondentsDecoder
        ]


firstLevelDecoder : Decoder AudienceExpression
firstLevelDecoder =
    decoder_ { nestedCall = False }


nestedCallDecoder : Decoder AudienceExpression
nestedCallDecoder =
    decoder_ { nestedCall = True }


decoder : Decoder AudienceExpression
decoder =
    firstLevelDecoder


leafDecoder : Decoder AudienceExpression
leafDecoder =
    Decode.succeed LeafData
        |> Decode.andMap
            (Decode.field "not" Decode.bool
                |> Decode.maybe
                |> Decode.map (Maybe.withDefault False)
                |> Decode.map
                    (\bool ->
                        if bool then
                            Exclude

                        else
                            Include
                    )
            )
        |> Decode.andMap
            (Decode.field "min_count" stringOrInt
                |> Decode.maybe
                |> Decode.map (Maybe.withDefault 1)
            )
        |> Decode.andMap (Decode.field "question" Data.Id.decode)
        |> Decode.andMap
            {- TODO Unlike in encoder, we can just try the correct option here and
               then the old one if it fails. But we should remove this as soon as
               BE services use "datapoints" exclusively.
            -}
            (Decode.oneOf
                [ Decode.field "datapoints" (Decode.list Data.Id.decode)
                , Decode.field "options" (Decode.list Data.Id.decode)
                ]
            )
        |> Decode.andMap
            (Decode.field "suffixes" (Decode.list Data.Id.decodeFromStringOrInt)
                -- TODO after DB migration change to `Data.Id.decode`!
                |> Decode.maybe
                |> Decode.map (Maybe.withDefault [])
            )
        |> Decode.map Leaf


nodeDecoder : Decoder AudienceExpression
nodeDecoder =
    let
        logicNodeDecoder : String -> LogicOperator -> Decoder AudienceExpression
        logicNodeDecoder field constructor =
            Decode.field field
                (Decode.list
                    (Decode.lazy
                        (\() ->
                            Decode.maybe nestedCallDecoder
                        )
                    )
                )
                |> Decode.andThen (List.filterMap identity >> NonemptyList.fromList >> Decode.fromMaybe "Unexpected empty list")
                |> Decode.map (Node constructor)
    in
    Decode.oneOf
        [ logicNodeDecoder "and" And
        , logicNodeDecoder "or" Or
        ]
