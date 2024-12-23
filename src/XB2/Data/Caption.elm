module XB2.Data.Caption exposing
    ( Caption
    , CaptionData
    , combinedShortName
    , create
    , fromAudience
    , fromDatapoint
    , fromGroupOfCaptions
    , getFullName
    , getName
    , getSubtitle
    , groupingPrefix
    , maxUserDefinedNameLength
    , merge
    , setName
    , setSubtitle
    , toString
    , trimNameByUserDefinedLimit
    )

import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Maybe.Extra as Maybe
import String.Extra as String
import XB2.Share.Platform2.Grouping as Grouping exposing (Grouping(..))


maxUserDefinedNameLength : Int
maxUserDefinedNameLength =
    100


nameLengthLimit : Int
nameLengthLimit =
    50


type alias CaptionData =
    { name : String
    , fullName : String
    , subtitle : Maybe String
    }


type Caption
    = Caption CaptionData


create : CaptionData -> Caption
create =
    Caption


fromDatapoint : { question : String, datapoint : Maybe String, suffix : Maybe String } -> Caption
fromDatapoint { question, datapoint, suffix } =
    let
        name =
            case datapoint of
                Just d ->
                    d ++ (Maybe.map (\suf -> ": " ++ suf) suffix |> Maybe.withDefault "")

                Nothing ->
                    ""
    in
    Caption
        { name = name
        , fullName = name
        , subtitle = Just question
        }


fromAudience : { audience : String, parent : Maybe String } -> Caption
fromAudience { audience, parent } =
    Caption
        { name = audience
        , fullName = audience
        , subtitle = parent
        }


groupingPrefix : Grouping -> String
groupingPrefix grouping =
    case grouping of
        Split ->
            ""

        And ->
            "all "

        Or ->
            "any of "


combinedShortName : Grouping -> List String -> String
combinedShortName grouping names =
    case names of
        [] ->
            "N/A"

        [ item ] ->
            item

        [ first, second ] ->
            first
                ++ " "
                ++ Grouping.interleavingPrefix grouping
                ++ second

        first :: second :: tail ->
            first
                ++ " "
                ++ Grouping.interleavingPrefix grouping
                ++ groupingPrefix grouping
                ++ (String.fromInt <| List.length tail + 1)
                ++ " data points / audiences including "
                ++ second


toString : Caption -> String
toString (Caption { fullName, subtitle }) =
    Maybe.unwrap fullName (\s -> fullName ++ " (" ++ s ++ ")") subtitle


getName : Caption -> String
getName (Caption { name }) =
    name


getFullName : Caption -> String
getFullName (Caption { fullName }) =
    fullName


getSubtitle : Caption -> Maybe String
getSubtitle (Caption { subtitle }) =
    subtitle


setName : String -> Caption -> Caption
setName newName (Caption c) =
    Caption { c | name = newName, fullName = newName }


setSubtitle : Maybe String -> Caption -> Caption
setSubtitle newSubtitle (Caption c) =
    Caption { c | subtitle = newSubtitle }


merge : String -> Caption -> Caption -> Caption
merge sep (Caption c1) (Caption c2) =
    Caption
        { name = c1.name ++ " " ++ sep ++ " " ++ c2.name
        , fullName = "(" ++ c1.fullName ++ " " ++ sep ++ " " ++ c2.fullName ++ ")"
        , subtitle = Nothing
        }


fromGroupOfCaptions : Grouping -> NonEmpty Caption -> Caption
fromGroupOfCaptions grouping captions =
    let
        allNames =
            NonemptyList.map getFullName captions
                |> NonemptyList.toList

        fullName =
            List.intersperse
                (Grouping.interleavingPrefix grouping
                    |> String.trim
                )
                allNames
                |> List.map String.trim
                |> String.join " "
                |> String.toSentenceCase
    in
    create
        { name =
            if String.length fullName > nameLengthLimit then
                let
                    shortName =
                        combinedShortName grouping allNames
                in
                String.toSentenceCase shortName

            else
                fullName
        , fullName = fullName
        , subtitle = Nothing
        }


trimNameByUserDefinedLimit : Caption -> Caption
trimNameByUserDefinedLimit (Caption data) =
    Caption { data | name = String.left maxUserDefinedNameLength data.name }
