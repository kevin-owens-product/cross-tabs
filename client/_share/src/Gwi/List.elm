module Gwi.List exposing
    ( addIf
    , combineRemoteData
    , fastConcat
    , fastConcatMap
    , groupOn
    , remoteDataValues
    , reverseSortBy
    , selectRange
    , toggle
    )

{-| Our own List.Extra module.
-}

import List.Extra as List
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..))


{-| A faster List.concat alternative.
TODO: could be removed if/after <https://github.com/elm/core/pull/1027> is merged
and we bump to elm/core with that "fix".
-}
fastConcat : List (List a) -> List a
fastConcat =
    List.foldr (++) []


{-| List.concatMap alternative using our `fastConcat`.
-}
fastConcatMap : (a -> List b) -> List a -> List b
fastConcatMap f =
    List.foldr (f >> (++)) []


reverseSortBy : (a -> comparable) -> List a -> List a
reverseSortBy toComparable =
    List.sortBy toComparable >> List.reverse


addIf : Bool -> a -> List a -> List a
addIf cond =
    if cond then
        (::)

    else
        always identity


combineRemoteData : List (RemoteData e a) -> RemoteData e (List a)
combineRemoteData list =
    List.foldl (RemoteData.map2 (::)) (Success []) list


remoteDataValues : List (RemoteData e a) -> List a
remoteDataValues list =
    list
        |> List.filterMap
            (\remoteData ->
                case remoteData of
                    Success val ->
                        Just val

                    _ ->
                        Nothing
            )


{-| Groups together consecutive runs of items that have the same result of `fn`:
groupOn isEven [ 1, 3, 5, 2, 3, 5, 2, 4 ]
-->
[ ( False, ( 1, [ 3, 5 ] ) )
, ( True, ( 2, [] ) )
, ( False, ( 3, [ 5 ] ) )
, ( True, ( 2, [ 4 ] ) )
]
-}
groupOn : (a -> b) -> List a -> List ( b, ( a, List a ) )
groupOn fn list =
    list
        |> List.groupWhile (\a b -> fn a == fn b)
        |> List.map (\( x, xs ) -> ( fn x, ( x, xs ) ))


toggle : a -> List a -> List a
toggle item list =
    if List.member item list then
        List.remove item list

    else
        list ++ [ item ]


{-| Can be used for selecting range with shift+click where you know already selected and item you clicked to select
See tests for better understanding
-}
selectRange : { isSelected : item -> Bool, itemToSelect : item -> Bool } -> List item -> List item
selectRange { isSelected, itemToSelect } allItems =
    let
        selectedAround : { nextSelected : Maybe Int, previousSelected : Maybe Int, keyIndex : Maybe Int }
        selectedAround =
            allItems
                |> List.indexedFoldl
                    (\index item acc ->
                        if isSelected item then
                            if Maybe.isJust acc.keyIndex && acc.nextSelected == Nothing then
                                { acc | nextSelected = Just index }

                            else if acc.keyIndex == Nothing then
                                { acc | previousSelected = Just index }

                            else
                                acc

                        else if itemToSelect item then
                            { acc | keyIndex = Just index }

                        else
                            acc
                    )
                    { nextSelected = Nothing, previousSelected = Nothing, keyIndex = Nothing }

        fromPreviousToKey : ( Int, Int )
        fromPreviousToKey =
            case ( selectedAround.previousSelected, selectedAround.keyIndex ) of
                ( Just previousSelected, Just keyIndex ) ->
                    ( previousSelected, keyIndex )

                ( Nothing, Just keyIndex ) ->
                    ( keyIndex, keyIndex )

                _ ->
                    ( -1, -1 )

        fromKeyToNext : ( Int, Int )
        fromKeyToNext =
            case ( selectedAround.nextSelected, selectedAround.keyIndex ) of
                ( Just nextSelected, Just keyIndex ) ->
                    ( keyIndex, nextSelected )

                ( Nothing, Just keyIndex ) ->
                    ( keyIndex, keyIndex )

                _ ->
                    ( -1, -1 )

        ( from, to ) =
            if Maybe.isJust selectedAround.previousSelected then
                fromPreviousToKey

            else
                fromKeyToNext
    in
    allItems
        |> List.indexedFoldr
            (\index currentItem ->
                if from <= index && index <= to && (not <| isSelected currentItem) then
                    (::) currentItem

                else
                    identity
            )
            []
