module XB2.Detail.NotificationText exposing
    ( affixed
    , created
    , edited
    , typesToString
    )

import AssocSet
import XB2.Data.AudienceCrosstab exposing (Direction)
import XB2.Detail.Common as Common
import XB2.Share.Platform2.Grouping exposing (Grouping(..))
import XB2.Share.Plural
import XB2.Views.AttributeBrowser exposing (ItemType(..))


itemTypeToString : ItemType -> String
itemTypeToString item =
    case item of
        AudienceItem ->
            "audiences"

        AttributeItem ->
            "data points"

        AverageItem ->
            "averages"


typesToString : AssocSet.Set ItemType -> String
typesToString =
    AssocSet.toList
        >> List.map itemTypeToString
        >> String.join " / "


created : Direction -> { differentDataset : Bool } -> Int -> Grouping -> AssocSet.Set ItemType -> String
created dir { differentDataset } size grouping itemTypes =
    let
        direction : String
        direction =
            if grouping == Split then
                XB2.Share.Plural.fromInt size <| Common.directionToString dir

            else
                Common.directionToString dir

        newDataSetText : String
        newDataSetText =
            if differentDataset then
                " + New dataset(s) added"

            else
                "."
    in
    (if grouping == Split then
        "Created " ++ String.fromInt size ++ " " ++ direction

     else
        "Created 1 " ++ direction ++ " with " ++ String.fromInt size ++ " " ++ typesToString itemTypes
    )
        ++ newDataSetText


edited : String -> String
edited nameOfItemEdited =
    "Edited " ++ nameOfItemEdited ++ " expression."


affixed : Int -> Int -> List String -> String
affixed rowCount colCount names =
    let
        itemString suffix =
            "data point" ++ suffix ++ " / " ++ "audience" ++ suffix

        rowCountPart =
            [ ( rowCount, "row" ), ( colCount, "column" ) ]
                |> List.filterMap
                    (\( count, desc ) ->
                        if count == 0 then
                            Nothing

                        else
                            Just <| String.fromInt count ++ " " ++ XB2.Share.Plural.fromInt count desc
                    )
                |> String.join " and "

        expressionPart =
            case names of
                [] ->
                    "."

                [ name ] ->
                    " with '" ++ name ++ "' " ++ itemString "" ++ "."

                name :: _ :: [] ->
                    " with '" ++ name ++ "' & 1 other " ++ itemString "" ++ "."

                name :: rest ->
                    " with '" ++ name ++ "' & " ++ (String.fromInt <| List.length rest) ++ " other " ++ itemString "s" ++ "."
    in
    "Appended " ++ rowCountPart ++ expressionPart
