module XB2.Data.AudienceCrosstab.Sort exposing (SortConfig, convertSortToSortConfig, sortAxisBy)

import Dict.Any exposing (AnyDict)
import XB2.Data.AudienceCrosstab as AC exposing (CrosstabTable, Key)
import XB2.Data.AudienceItem as AudienceItem
import XB2.Data.AudienceItemId as AudienceItemId exposing (AudienceItemId)
import XB2.Data.BaseAudience exposing (BaseAudience)
import XB2.Data.Calc.AudienceIntersect as AudienceIntersect
import XB2.Data.Caption as Caption
import XB2.Data.Crosstab as Crosstab
import XB2.Share.Gwi.List as List
import XB2.Sort
    exposing
        ( Axis(..)
        , AxisSort(..)
        , SortDirection(..)
        )


type alias SortConfig =
    { mode : AxisSort
    , axis : Axis
    }


convertSortToSortConfig : XB2.Sort.Sort -> Maybe SortConfig
convertSortToSortConfig sort =
    if sort.rows /= NoSort then
        Just { mode = sort.rows, axis = Rows }

    else if sort.columns /= NoSort then
        Just { mode = sort.columns, axis = Columns }

    else
        Nothing


sortAxisBy :
    SortConfig
    -> BaseAudience
    -> AnyDict ( AudienceItemId.ComparableId, String ) ( AudienceItem.AudienceItem, BaseAudience ) AC.Cell
    -> AnyDict AudienceItemId.ComparableId AudienceItemId Key
    -> CrosstabTable
    -> CrosstabTable
sortAxisBy { axis, mode } base totals keyMapping crosstab =
    case mode of
        NoSort ->
            crosstab

        ByName direction ->
            sortByName axis direction crosstab

        ByOtherAxisAverage averageItemId direction ->
            Dict.Any.get averageItemId keyMapping
                |> Maybe.map
                    (\averageKey ->
                        let
                            valueForKey : Key -> Float
                            valueForKey key =
                                crosstab
                                    |> Crosstab.value
                                        (case axis of
                                            Rows ->
                                                { base = base, row = key, col = averageKey }

                                            Columns ->
                                                { base = base, row = averageKey, col = key }
                                        )
                                    |> Maybe.andThen (.data >> AC.getAverageData)
                                    |> Maybe.map .value
                                    |> Maybe.withDefault (infinityForDirection direction)
                        in
                        sortByOtherAxis axis direction valueForKey crosstab
                    )
                |> Maybe.withDefault crosstab

        ByOtherAxisMetric avaItemId metric direction ->
            Dict.Any.get avaItemId keyMapping
                |> Maybe.map
                    (\avaKey ->
                        let
                            valueForKey : Key -> Float
                            valueForKey key =
                                crosstab
                                    |> Crosstab.value
                                        (case axis of
                                            Rows ->
                                                { base = base, row = key, col = avaKey }

                                            Columns ->
                                                { base = base, row = avaKey, col = key }
                                        )
                                    |> Maybe.andThen (.data >> AC.getAvAData)
                                    |> Maybe.map (AudienceIntersect.getValue metric)
                                    |> Maybe.withDefault (infinityForDirection direction)
                        in
                        sortByOtherAxis axis direction valueForKey crosstab
                    )
                |> Maybe.withDefault crosstab

        ByTotalsMetric metric direction ->
            let
                valueForKey : Key -> Float
                valueForKey key =
                    Dict.Any.get ( key.item, base ) totals
                        |> Maybe.andThen (.data >> AC.getAvAData)
                        |> Maybe.map (AudienceIntersect.getValue metric)
                        |> Maybe.withDefault (infinityForDirection direction)
            in
            sortByOtherAxis axis direction valueForKey crosstab


sortListBy : SortDirection -> (a -> comparable) -> List a -> List a
sortListBy direction =
    case direction of
        Ascending ->
            List.sortBy

        Descending ->
            List.reverseSortBy


getItemsForAxis : Axis -> CrosstabTable -> List Key
getItemsForAxis axis crosstab =
    case axis of
        Rows ->
            Crosstab.getRows crosstab

        Columns ->
            Crosstab.getColumns crosstab


reorder : Axis -> List Key -> CrosstabTable -> CrosstabTable
reorder axis new crosstab =
    case axis of
        Rows ->
            Crosstab.reorderRows new crosstab

        Columns ->
            Crosstab.reorderColumns new crosstab


{-| Makes the non-existent cells go to the back.
-}
infinityForDirection : SortDirection -> Float
infinityForDirection direction =
    case direction of
        Ascending ->
            1 / 0

        Descending ->
            -1 / 0


sortByName : Axis -> SortDirection -> CrosstabTable -> CrosstabTable
sortByName axis direction crosstab =
    let
        newItems : List Key
        newItems =
            crosstab
                |> getItemsForAxis axis
                |> sortListBy direction
                    (.item
                        >> AudienceItem.getCaption
                        >> Caption.getName
                        >> String.toLower
                    )
    in
    reorder axis newItems crosstab


sortByOtherAxis : Axis -> SortDirection -> (Key -> Float) -> CrosstabTable -> CrosstabTable
sortByOtherAxis axis direction valueForKey crosstab =
    let
        newItems : List Key
        newItems =
            crosstab
                |> getItemsForAxis axis
                |> sortListBy direction valueForKey
    in
    reorder axis newItems crosstab
