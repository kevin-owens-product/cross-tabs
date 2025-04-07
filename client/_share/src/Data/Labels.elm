module Data.Labels exposing
    ( Category
    , CategoryId
    , CategoryIdTag
    , Datapoint
    , Location
    , LocationCode
    , LocationCodeTag
    , NamespaceAndQuestionCode
    , NamespaceAndQuestionCodeTag
    , NamespaceCode
    , NamespaceCodeTag
    , NamespaceLineage
    , Question
    , QuestionAndDatapointCode
    , QuestionAndDatapointCodeTag
    , QuestionAveragesUnit(..)
    , QuestionV2
    , Region
    , RegionCode(..)
    , ShortQuestionCode
    , ShortQuestionCodeTag
    , Suffix
    , SuffixCode
    , SuffixCodeTag
    , Wave
    , WaveCode
    , WaveCodeTag
    , WaveKind(..)
    , WaveQuarter(..)
    , WaveYear
    , comparableRegionCode
    , compatibleTopLevelNamespaces
    , coreNamespaceCode
    , getLineage
    , getLocationsForNamespace
    , getQuestionV2
    , getWavesForNamespaceV2
    , groupToRegion
    , isWave2017OrNewer
    , locationsByRegions
    , mergeLineage
    , regionName
    , sortWavesMostRecentFirst
    , wavesByYears
    )

import Config exposing (Flags)
import Config.Main
import Data.Auth as Auth
import Data.Id exposing (Id, IdDict, IdSet)
import Dict exposing (Dict)
import Dict.Any exposing (AnyDict)
import Gwi.Http exposing (HttpCmd)
import Gwi.List as List
import Http
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode
import List.Extra as List
import List.NonEmpty as NonemptyList exposing (NonEmpty)
import RemoteData exposing (RemoteData(..), WebData)
import Set.Any
import Time exposing (Month(..), Posix)
import Time.Extra as Time
import Url.Builder



-- HELPERS


host : Flags -> String
host =
    .env >> Config.Main.get >> .uri >> .api



-- QUESTIONS


type alias NamespaceAndQuestionCode =
    Id NamespaceAndQuestionCodeTag


type NamespaceAndQuestionCodeTag
    = NamespaceAndQuestionCodeTag


type alias ShortQuestionCode =
    Id ShortQuestionCodeTag


type ShortQuestionCodeTag
    = ShortQuestionCodeTag


type QuestionAveragesUnit
    = AgreementScore
    | TimeInHours
    | OtherUnit String


averagesUnitDecoder : Decoder QuestionAveragesUnit
averagesUnitDecoder =
    let
        decoder s =
            case s of
                "agreement score" ->
                    AgreementScore

                "hours" ->
                    TimeInHours

                _ ->
                    OtherUnit s
    in
    Decode.map decoder Decode.string


type alias Question =
    { code : NamespaceAndQuestionCode
    , namespaceCode : NamespaceCode
    , name : String
    , fullName : String
    , categoryIds : List CategoryId
    , suffixes : Maybe (NonEmpty Suffix)
    , message : Maybe String

    {- TODO remove locationCodes after we start using
       /questions/:id/compatibilities
    -}
    , locationCodes : List LocationCode
    , accessible : Bool
    , notice : Maybe String
    , averagesUnit : Maybe QuestionAveragesUnit
    , warning : Maybe String
    , knowledgeBase : Maybe String

    {- Made last because we have two decoders that only differ in this field.
       So they can reuse one common base.
    -}
    , datapoints : NonEmpty Datapoint
    }


type alias QuestionV2 =
    { code : ShortQuestionCode
    , longCode : NamespaceAndQuestionCode
    , namespaceCode : NamespaceCode
    , name : String
    , fullName : String
    , categoryIds : List CategoryId
    , suffixes : Maybe (NonEmpty Suffix)
    , message : Maybe String
    , accessible : Bool
    , notice : Maybe String
    , averagesUnit : Maybe QuestionAveragesUnit
    , averageSupport : Bool
    , warning : Maybe String
    , knowledgeBase : Maybe String

    {- Made last because we have two decoders that only differ in this field.
       So they can reuse one common base.
    -}
    , datapoints : NonEmpty Datapoint
    }


getQuestionV2 : NamespaceAndQuestionCode -> Flags -> HttpCmd Never QuestionV2
getQuestionV2 namespaceAndQuestionCode flags =
    Http.request
        { method = "GET"
        , headers =
            [ Auth.header flags.token ]
        , url =
            Url.Builder.crossOrigin (host flags)
                [ "v2", "questions", Data.Id.unwrap namespaceAndQuestionCode ]
                [ Url.Builder.string "include" "categories,datapoints" ]
        , body = Http.emptyBody
        , expect = Gwi.Http.expectJson identity <| questionV2Decoder namespaceAndQuestionCode
        , timeout = Nothing
        , tracker = Nothing
        }


questionV2Decoder : NamespaceAndQuestionCode -> Decoder QuestionV2
questionV2Decoder wantedQuestionCode =
    let
        ( _, wantedShortQuestionCode ) =
            splitQuestionCode wantedQuestionCode

        unwrappedShortQuestionCode : String
        unwrappedShortQuestionCode =
            Data.Id.unwrap wantedShortQuestionCode

        {- In this V2 API the datapoints' codes
           aren't returned as "q3_1" but as "1". The problem is that the rest
           of the world expects them to be like "q3_1" (saved audiences,
           dashboards, ...).

           So we add the question code back into the datapoint code. We
           currently don't have any use for the "short" normalized code. If we
           do, we can make two separate fields in Datapoint or something.
        -}
        fixDatapointCode : String -> QuestionAndDatapointCode
        fixDatapointCode =
            {- Written in this slightly-pointfree way to not do this `if`
               inside every datapoint but just once in this `let`.
            -}
            if unwrappedShortQuestionCode == "waves" then
                \datapointCode -> Data.Id.fromString datapointCode

            else
                \datapointCode ->
                    Data.Id.fromString
                        (unwrappedShortQuestionCode ++ "_" ++ datapointCode)

        v2DatapointDecoder : Decoder Datapoint
        v2DatapointDecoder =
            Decode.succeed Datapoint
                |> Decode.andMap (Decode.field "code" (Decode.map fixDatapointCode Decode.string))
                |> Decode.andMap (Decode.field "name" Decode.string)
                |> Decode.andMap
                    -- TODO perhaps this will get fixed later in ATC-3037
                    (Decode.field "accessible" Decode.bool
                        |> Decode.withDefault False
                    )
                |> Decode.andMap (Decode.maybe (Decode.field "midpoint" Decode.float))
                |> Decode.andMap (Decode.field "order" Decode.float)

        v2CategoryIdDecoder : Decoder CategoryId
        v2CategoryIdDecoder =
            {- Category here actually contains all the data we get from /api/categories
               but we only care about the id.
            -}
            Decode.field "id" Data.Id.decode

        averagesSupportDecoder : Decoder Bool
        averagesSupportDecoder =
            Decode.list Decode.string
                |> Decode.map (List.member "support_averages")
    in
    Decode.succeed
        (\code namespaceCode name fullName categoryIds suffixes message accessible notice averagesUnit averageSupport warning knowledgeBase datapoints ->
            { code = code
            , longCode = wantedQuestionCode
            , namespaceCode = namespaceCode
            , name = name
            , fullName = fullName
            , categoryIds = categoryIds
            , suffixes = suffixes
            , message = message
            , accessible = accessible
            , notice = notice
            , averagesUnit = averagesUnit
            , averageSupport = averageSupport
            , warning = warning
            , knowledgeBase = knowledgeBase
            , datapoints = datapoints
            }
        )
        |> Decode.andMap (Decode.at [ "question", "code" ] Data.Id.decode)
        |> Decode.andMap (Decode.at [ "question", "namespace_code" ] Data.Id.decode)
        |> Decode.andMap (Decode.at [ "question", "name" ] Decode.string)
        |> Decode.andMap (Decode.at [ "question", "description" ] Decode.string)
        |> Decode.andMap (Decode.at [ "question", "categories" ] (Decode.list v2CategoryIdDecoder))
        |> Decode.andMap (Decode.maybe (Decode.at [ "question", "suffixes" ] (NonemptyList.decodeList suffixDecoder)))
        |> Decode.andMap (Decode.maybe (Decode.at [ "question", "message" ] Decode.string))
        |> Decode.andMap
            -- TODO perhaps this will get fixed later in ATC-3037
            (Decode.at [ "question", "accessible" ] Decode.bool
                |> Decode.withDefault False
            )
        |> Decode.andMap (Decode.maybe (Decode.at [ "question", "notice" ] Decode.string))
        |> Decode.andMap (Decode.maybe (Decode.at [ "question", "unit" ] averagesUnitDecoder))
        |> Decode.andMap (Decode.maybe (Decode.at [ "question", "flags" ] averagesSupportDecoder) |> Decode.map (Maybe.withDefault False))
        |> Decode.andMap (Decode.maybe (Decode.at [ "question", "warning" ] Decode.string))
        |> Decode.andMap (Decode.maybe (Decode.at [ "question", "knowledge_base" ] Decode.string))
        |> Decode.andMap (Decode.at [ "question", "datapoints" ] (NonemptyList.decodeList v2DatapointDecoder))



-- CATEGORIES


type CategoryIdTag
    = CategoryIdTag


type alias CategoryId =
    Id CategoryIdTag


type alias Category =
    { id : CategoryId
    , name : String
    , description : Maybe String
    , parentId : Maybe CategoryId
    , order : Float
    , accessible : Bool
    , questionCodes : List NamespaceAndQuestionCode
    }



-- DATAPOINTS


type QuestionAndDatapointCodeTag
    = QuestionAndDatapointCodeTag


type alias QuestionAndDatapointCode =
    Id QuestionAndDatapointCodeTag


type alias Datapoint =
    { code : QuestionAndDatapointCode
    , name : String
    , accessible : Bool
    , midpoint : Maybe Float
    , order : Float
    }



-- LOCATIONS


type LocationCodeTag
    = LocationCodeTag


{-| LocationCode == DatapointCode, but for clarity we keep it separate.
There are casting functions available below.
-}
type alias LocationCode =
    Id LocationCodeTag


type alias Location =
    { code : LocationCode
    , name : String
    , region : RegionCode
    , accessible : Bool
    }


locationsByNamespaceUrl : Flags -> String
locationsByNamespaceUrl flags =
    Url.Builder.crossOrigin (host flags)
        [ "v2", "locations", "filter" ]
        []


wavesByNamespaceUrl : Flags -> String
wavesByNamespaceUrl flags =
    Url.Builder.crossOrigin (host flags)
        [ "v2", "waves", "filter" ]
        []


encodeRequestForLocationsForNamespace : NamespaceCode -> Encode.Value
encodeRequestForLocationsForNamespace namespaceCode =
    Encode.object
        [ ( "namespaces"
          , Encode.list
                (\code ->
                    Encode.object
                        [ ( "code", Data.Id.encode code ) ]
                )
                [ namespaceCode ]
          )
        , ( "include", Encode.object [ ( "regions", Encode.bool True ) ] )
        ]


encodeRequestForWavesForNamespace : NamespaceCode -> Encode.Value
encodeRequestForWavesForNamespace namespaceCode =
    Encode.object
        [ ( "namespaces"
          , Encode.list
                (\code ->
                    Encode.object
                        [ ( "code", Data.Id.encode code ) ]
                )
                [ namespaceCode ]
          )
        ]


getLocationsForNamespace : NamespaceCode -> Flags -> HttpCmd Never (List Location)
getLocationsForNamespace namespaceCode flags =
    Http.request
        { method = "POST"
        , headers =
            [ Auth.header flags.token ]
        , url = locationsByNamespaceUrl flags
        , body = Http.jsonBody <| encodeRequestForLocationsForNamespace namespaceCode
        , expect = Gwi.Http.expectJson identity (Decode.field "locations" (Decode.list locationV2Decoder))
        , timeout = Nothing
        , tracker = Nothing
        }



--to get All the locations with V2 we have to send the body with an empty namespaces
--to get All the waves with V2 we have to send the body with an empty namespaces


locationV2Decoder : Decoder Location
locationV2Decoder =
    Decode.succeed Location
        |> Decode.andMap (Decode.field "code" Data.Id.decode)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.at [ "region", "area" ] regionCodeDecoder)
        |> Decode.andMap (Decode.field "accessible" Decode.bool)



-- REGION CODES


type RegionCode
    = Euro
    | Mea
    | Americas
    | Apac


type alias Region =
    { name : String
    , locations : IdDict LocationCodeTag Location
    }


regionCodeDecoder : Decoder RegionCode
regionCodeDecoder =
    let
        typeBuilder code =
            case code of
                "euro" ->
                    Decode.succeed Euro

                "mea" ->
                    Decode.succeed Mea

                "americas" ->
                    Decode.succeed Americas

                "apac" ->
                    Decode.succeed Apac

                _ ->
                    Decode.fail <| "Invalid area code " ++ code
    in
    Decode.andThen typeBuilder Decode.string


regionName : RegionCode -> String
regionName code =
    case code of
        Euro ->
            "Europe"

        Americas ->
            "Americas"

        Mea ->
            "Middle East & Africa"

        Apac ->
            "Asia Pacific"


comparableRegionCode : RegionCode -> Int
comparableRegionCode code =
    case code of
        Euro ->
            1

        Americas ->
            2

        Mea ->
            3

        Apac ->
            4


allRegions : Dict Int Region
allRegions =
    [ Americas, Apac, Euro, Mea ]
        |> List.map
            (\code ->
                ( comparableRegionCode code
                , { name = regionName code
                  , locations = Data.Id.emptyDict
                  }
                )
            )
        |> Dict.fromList


addLocation : Location -> Dict Int Region -> Dict Int Region
addLocation location_ regions =
    let
        insertLocation region =
            { region
                | locations = Dict.Any.insert location_.code location_ region.locations
            }

        updater maybeRegion =
            case maybeRegion of
                Just region ->
                    Just <| insertLocation region

                Nothing ->
                    Dict.get (comparableRegionCode location_.region) allRegions
                        |> Maybe.map insertLocation
    in
    Dict.update (comparableRegionCode location_.region) updater regions


groupToRegion : List Location -> Dict Int Region
groupToRegion locations =
    List.foldr addLocation Dict.empty locations



-- SUFFIXES


type SuffixCodeTag
    = SuffixCodeTag


type alias SuffixCode =
    Id SuffixCodeTag


type alias Suffix =
    { code : SuffixCode
    , name : String
    , midpoint : Maybe Float
    }


suffixDecoder : Decoder Suffix
suffixDecoder =
    Decode.succeed Suffix
        |> Decode.andMap
            (Decode.oneOf
                -- TODO keeping this "id" just in case but it's probably not needed.
                -- After other id->code changes look at this again.
                [ Decode.field "code" Data.Id.decode
                , Decode.field "id" Data.Id.decodeFromInt
                ]
            )
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.optionalNullableField "midpoint" Decode.float)



-- WAVES


type WaveCodeTag
    = WaveCodeTag


type alias WaveCode =
    Id WaveCodeTag


type WaveKind
    = Quarter WaveQuarter
    | SlidingQuarter


type alias WaveYear =
    Int


type WaveQuarter
    = Q1
    | Q2
    | Q3
    | Q4


dateToQuarter : Posix -> Maybe WaveQuarter
dateToQuarter date =
    case Time.toMonth Time.utc date of
        Jan ->
            Just Q1

        Apr ->
            Just Q2

        Jul ->
            Just Q3

        Oct ->
            Just Q4

        _ ->
            Nothing


type alias Wave =
    { code : WaveCode
    , name : String -- eg. "Q1 2020"
    , accessible : Bool
    , kind : WaveKind
    , startDate : Posix
    , endDate : Posix
    }


waveYear : Wave -> WaveYear
waveYear { startDate } =
    Time.toYear Time.utc startDate


waveKindDecoder : Decoder WaveKind
waveKindDecoder =
    let
        quarterDecoder =
            Decode.field "date_start" dateDecoder
                |> Decode.andThen
                    (\date ->
                        Decode.fromMaybe
                            ("Unsuccessful quarter decoding from date " ++ Iso8601.fromTime date)
                            (dateToQuarter date)
                    )

        kindDecoder kind =
            case kind of
                "quarter" ->
                    Decode.map Quarter quarterDecoder

                "sliding_quarter" ->
                    Decode.succeed SlidingQuarter

                unknown ->
                    Decode.fail <| "Unsupported wave kind: " ++ unknown
    in
    Decode.field "kind" Decode.string
        |> Decode.andThen kindDecoder


dateDecoder : Decoder Posix
dateDecoder =
    Decode.andThen
        (\str ->
            -- Do this because new endpoint returns full ISO-8601 format (with T and Z)
            str
                |> String.split "T"
                |> List.take 1
                |> String.concat
                |> Time.fromIso8601Date Time.utc
                |> Decode.fromMaybe ("Invalid date: " ++ str)
        )
        Decode.string


waveDecoder : Decoder Wave
waveDecoder =
    Decode.succeed Wave
        |> Decode.andMap (Decode.field "code" Data.Id.decode)
        |> Decode.andMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "accessible" Decode.bool)
        |> Decode.andMap waveKindDecoder
        |> Decode.andMap (Decode.field "date_start" dateDecoder)
        |> Decode.andMap (Decode.field "date_end" dateDecoder)


isWave2017OrNewer : Wave -> Bool
isWave2017OrNewer wave =
    waveYear wave >= 2017


getWavesForNamespaceV2 : NamespaceCode -> Flags -> HttpCmd Never (List Wave)
getWavesForNamespaceV2 namespaceCode flags =
    Http.request
        { method = "POST"
        , headers =
            [ Auth.header flags.token ]
        , url = wavesByNamespaceUrl flags
        , body = Http.jsonBody <| encodeRequestForWavesForNamespace namespaceCode
        , expect = Gwi.Http.expectJson identity (Decode.field "waves" (Decode.list waveDecoder))
        , timeout = Nothing
        , tracker = Nothing
        }



-- Namespaces


type NamespaceCodeTag
    = NamespaceCodeTag


type alias NamespaceCode =
    Id NamespaceCodeTag


{-|

  - "q20" -> ("core", "q20")
  - "gwi-ext.q418999" -> ("gwi-ext", "q418999")

-}
splitQuestionCode : NamespaceAndQuestionCode -> ( NamespaceCode, ShortQuestionCode )
splitQuestionCode namespaceAndQuestionCode =
    let
        unwrapped =
            Data.Id.unwrap namespaceAndQuestionCode
    in
    case String.split "." unwrapped of
        [ namespaceCode, shortQuestionCode ] ->
            ( Data.Id.fromString namespaceCode, Data.Id.fromString shortQuestionCode )

        _ ->
            ( Data.Id.fromString "core", Data.Id.fromString unwrapped )


getWavesSortedLeastRecentFirst : IdDict WaveCodeTag Wave -> List Wave
getWavesSortedLeastRecentFirst dict =
    dict
        |> Dict.Any.values
        |> List.sortBy (.startDate >> Time.posixToMillis)


sortWavesMostRecentFirst : List Wave -> List Wave
sortWavesMostRecentFirst list =
    list
        |> List.reverseSortBy (.startDate >> Time.posixToMillis)



-- LINEAGES


type alias NamespaceLineage =
    { ancestors : List NamespaceCode
    , descendants : List NamespaceCode
    }


mergeLineage : NamespaceCode -> NamespaceLineage -> List NamespaceCode
mergeLineage currentNamespace { ancestors, descendants } =
    currentNamespace
        :: ancestors
        ++ descendants


lineageDecoder : Decoder NamespaceLineage
lineageDecoder =
    let
        idsAsObjectKeysDecoder : Decoder (List (Id tag))
        idsAsObjectKeysDecoder =
            Decode.keyValuePairs (Decode.succeed ())
                |> Decode.map (List.map (Tuple.first >> Data.Id.fromString))
    in
    Decode.succeed NamespaceLineage
        |> Decode.andMap (Decode.field "ancestors" idsAsObjectKeysDecoder)
        |> Decode.andMap (Decode.field "descendants" idsAsObjectKeysDecoder)


getLineage : NamespaceCode -> Flags -> HttpCmd Never NamespaceLineage
getLineage namespaceCode flags =
    Http.request
        { method = "GET"
        , headers =
            [ Auth.header flags.token ]
        , url =
            Url.Builder.crossOrigin (host flags)
                [ "v1", "surveys", "lineage", "by_namespace", Data.Id.unwrap namespaceCode ]
                []
        , body = Http.emptyBody
        , expect = Gwi.Http.expectJson identity lineageDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


coreNamespaceCode : NamespaceCode
coreNamespaceCode =
    Data.Id.fromString "core"


compatibleTopLevelNamespaces : IdDict NamespaceCodeTag (WebData NamespaceLineage) -> List NamespaceCode -> WebData (IdSet NamespaceCodeTag)
compatibleTopLevelNamespaces lineages namespaceCodes =
    let
        mergeAncestorsOnlyLineage : NamespaceCode -> NamespaceLineage -> List NamespaceCode
        mergeAncestorsOnlyLineage currentNamespace { ancestors } =
            currentNamespace :: ancestors

        compatibleAncestorsNamespaces : NamespaceCode -> WebData (IdSet NamespaceCodeTag)
        compatibleAncestorsNamespaces namespaceCode =
            Dict.Any.get namespaceCode lineages
                |> Maybe.withDefault NotAsked
                |> RemoteData.map (mergeAncestorsOnlyLineage namespaceCode >> Data.Id.setFromList)
    in
    namespaceCodes
        |> List.map compatibleAncestorsNamespaces
        |> List.combineRemoteData
        |> RemoteData.map
            (\compatibles ->
                let
                    all : IdSet NamespaceCodeTag
                    all =
                        List.foldl Set.Any.union Data.Id.emptySet compatibles
                in
                List.foldl Set.Any.intersect all compatibles
            )


wavesByYears : IdDict WaveCodeTag Wave -> Dict WaveYear (List Wave)
wavesByYears waves =
    waves
        |> Dict.Any.filter (always .accessible)
        |> getWavesSortedLeastRecentFirst
        |> List.gatherWith (\a b -> waveYear a == waveYear b)
        |> List.map
            (\( first, restList ) ->
                let
                    wavesInsideYear =
                        (first :: restList)
                            |> List.reverseSortBy
                                (\wave ->
                                    ( Time.posixToMillis wave.startDate
                                    , Time.posixToMillis wave.endDate
                                    )
                                )
                in
                ( waveYear first, wavesInsideYear )
            )
        |> Dict.fromList


locationsByRegions : IdDict LocationCodeTag Location -> AnyDict Int RegionCode (List Location)
locationsByRegions locations =
    let
        groupLocationsByRegion : List Location -> AnyDict Int RegionCode (List Location)
        groupLocationsByRegion locations_ =
            [ Euro, Americas, Mea, Apac ]
                |> List.map
                    (\code ->
                        ( code
                        , List.filter ((==) code << .region) locations_
                            |> List.sortBy .name
                        )
                    )
                |> List.filter (Tuple.second >> List.isEmpty >> not)
                |> Dict.Any.fromList comparableRegionCode
    in
    locations
        |> Dict.Any.filter (always .accessible)
        |> Dict.Any.values
        |> groupLocationsByRegion
