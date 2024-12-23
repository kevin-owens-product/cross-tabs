module XB2.Data.Crosstab exposing
    ( Crosstab
    , addBase
    , addColumn
    , addColumnAtIndex
    , addColumns
    , addRow
    , addRowAtIndex
    , addRows
    , all
    , any
    , colCount
    , empty
    , filterColumns
    , filterRows
    , foldr
    , getColumns
    , getRange
    , getRemovedValues
    , getRows
    , getValues
    , insert
    , isEmpty
    , map
    , moveItemsToColumnIndex
    , moveItemsToRowIndex
    , removeBase
    , removeColumn
    , removeRow
    , reorderColumns
    , reorderRows
    , rowCount
    , size
    , switchRowsAndColumns
    , toListForBase
    , update
    , updateColumnKeys
    , updateKeys
    , updateRowKeys
    , value
    )

{-| THREE-DIMENSIONAL TABLE

This module implements abstraction for creating tables where value in cell
is a function of column key, row key and base audience.

You can thus think about it as of three-dimensional table,
or as of collection of tables, one for each base audience.

    base1:

         |         col1         |         col2
    -----+----------------------+----------------------
    row1 | f(row1, col1, base1) | f(row1, col2, base1)
    row2 | f(row2, col1, base1) | f(row2, col2, base1)

    base2:

         |         col1         |         col2
    -----+----------------------+----------------------
    row1 | f(row1, col1, base2) | f(row1, col2, base2)
    row2 | f(row2, col1, base2) | f(row2, col2, base2)

    etc...

-}

import Dict.Any exposing (AnyDict)
import List.Cartesian
import List.Extra as List
import Maybe.Extra as Maybe
import XB2.Data.Range as Range exposing (Range)


{-| Type parameters:

  - h = row or column key
  - b = the "third dimension" - in our case, the BaseAudience
  - a = value of the cell

In addition to `b -> String` for the bases, you'll need to supply
a `h -> (Int, String)` function for the rows and columns. The `Int` is the index
of the key inside the rows / columns (as you can have one key multiple times
there!)

-}
type Crosstab h b a
    = Crosstab
        { columns : List h
        , rows : List h
        , values : AnyDict ( String, String, String ) { row : h, col : h, base : b } a
        , rowCount : Int
        , colCount : Int
        }


keyToComparable :
    (h -> String)
    -> (b -> String)
    -> { row : h, col : h, base : b }
    -> ( String, String, String )
keyToComparable headerToComparable baseToComparable { row, col, base } =
    ( headerToComparable row
    , headerToComparable col
    , baseToComparable base
    )


{-| init empty crosstab
-}
empty : (h -> String) -> (b -> String) -> Crosstab h b a
empty headerToComparable baseToComparable =
    Crosstab
        { columns = []
        , rows = []
        , values = Dict.Any.empty (keyToComparable headerToComparable baseToComparable)
        , rowCount = 0
        , colCount = 0
        }


isEmpty : Crosstab h b a -> Bool
isEmpty (Crosstab { rows, columns }) =
    List.isEmpty rows && List.isEmpty columns


insertAtIndex : Int -> a -> Int -> List a -> List a
insertAtIndex index newItem listLength list =
    if listLength == 0 then
        [ newItem ]

    else
        let
            newIndex =
                clamp 0 listLength index
        in
        if newIndex == listLength then
            -- insert at the end
            list ++ [ newItem ]

        else
            List.indexedFoldr
                (\idx item acc ->
                    if idx == newIndex then
                        newItem :: item :: acc

                    else
                        item :: acc
                )
                []
                list


rowCount : Crosstab h b a -> Int
rowCount (Crosstab ct) =
    ct.rowCount


colCount : Crosstab h b a -> Int
colCount (Crosstab ct) =
    ct.colCount


size : Crosstab h b a -> Int
size crosstab =
    rowCount crosstab * colCount crosstab


{-| Ignores total row/column.

For this starting state:

  - crosstab [row0, row1]
  - table [total, row0, row1]

It will behave like:

    addRowAtIndex 0 "foo" bases crosstab
    --> crosstab: [foo, row0, row1]
    --> table: [total, foo, row0, row1]

    addRowAtIndex 1 "foo" bases crosstab
    --> crosstab: [row0, foo, row1]
    --> table: [total, row0, foo, row1]

    addRowAtIndex 2 "foo" bases crosstab
    --> crosstab: [row0, row1, foo]
    --> table: [total, row0, row1, foo]

-}
addRowAtIndex : a -> Int -> h -> List b -> Crosstab h b a -> Crosstab h b a
addRowAtIndex val index headerValue bases (Crosstab state) =
    Crosstab
        { state
            | rows = insertAtIndex index headerValue state.rowCount state.rows
            , values =
                List.Cartesian.map2 Tuple.pair state.columns bases
                    |> List.foldr
                        (\( column, base ) ->
                            Dict.Any.insert
                                { row = headerValue
                                , col = column
                                , base = base
                                }
                                val
                        )
                        state.values
            , rowCount = state.rowCount + 1
        }


moveMultipleToIndex : Int -> List item -> List item -> List item
moveMultipleToIndex index itemsToMove list =
    let
        filter =
            List.filter (\item -> not <| List.member item itemsToMove)
    in
    if List.length list <= index then
        filter list
            ++ itemsToMove

    else if index < 0 then
        itemsToMove ++ filter list

    else
        list
            |> List.indexedFoldl
                (\i item acc ->
                    let
                        itemToAppend =
                            if List.member item itemsToMove then
                                []

                            else
                                [ item ]
                    in
                    if i == index then
                        acc ++ itemsToMove ++ itemToAppend

                    else
                        acc ++ itemToAppend
                )
                []


filterInvalidItemsToMove : { rows : List item, columns : List item } -> Crosstab item b a -> { rows : List item, columns : List item }
filterInvalidItemsToMove { rows, columns } (Crosstab state) =
    let
        allCurrentItems =
            state.rows ++ state.columns
    in
    { rows = List.filter (\row -> List.member row allCurrentItems) rows
    , columns = List.filter (\col -> List.member col allCurrentItems) columns
    }


moveItemsToColumnIndex :
    (item -> a)
    -> Int
    -> { rows : List item, columns : List item }
    -> List b
    -> Crosstab item b a
    -> Crosstab item b a
moveItemsToColumnIndex toVal index itemsToMove bases (Crosstab state) =
    let
        { rows, columns } =
            filterInvalidItemsToMove itemsToMove (Crosstab state)

        newColumns =
            moveMultipleToIndex index (rows ++ columns) state.columns

        newRows =
            List.filter (\key -> List.member key rows |> not) state.rows
    in
    Crosstab
        { state
            | columns = newColumns
            , rows = newRows
            , values =
                rows
                    |> List.foldr
                        (\key acc ->
                            List.Cartesian.map2 Tuple.pair state.rows bases
                                |> List.foldr
                                    (\( row, base ) ->
                                        Dict.Any.insert
                                            { row = row
                                            , col = key
                                            , base = base
                                            }
                                            (toVal key)
                                    )
                                    acc
                        )
                        state.values
                    |> Dict.Any.filter (\{ row } _ -> not <| List.member row rows)
            , rowCount = List.length newRows
            , colCount = List.length newColumns
        }


moveItemsToRowIndex :
    (item -> a)
    -> Int
    -> { rows : List item, columns : List item }
    -> List b
    -> Crosstab item b a
    -> Crosstab item b a
moveItemsToRowIndex toVal index itemsToMove bases (Crosstab state) =
    let
        { rows, columns } =
            filterInvalidItemsToMove itemsToMove (Crosstab state)

        newRows =
            moveMultipleToIndex index (rows ++ columns) state.rows

        newColumns =
            List.filter (\key -> List.member key columns |> not) state.columns
    in
    Crosstab
        { state
            | rows = newRows
            , columns = newColumns
            , values =
                columns
                    |> List.foldr
                        (\key acc ->
                            List.Cartesian.map2 Tuple.pair state.columns bases
                                |> List.foldr
                                    (\( col, base ) ->
                                        Dict.Any.insert
                                            { row = key
                                            , col = col
                                            , base = base
                                            }
                                            (toVal key)
                                    )
                                    acc
                        )
                        state.values
                    |> Dict.Any.filter (\{ col } _ -> not <| List.member col columns)
            , rowCount = List.length newRows
            , colCount = List.length newColumns
        }


{-| add row to the end of crosstab
-}
addRow : a -> h -> List b -> Crosstab h b a -> Crosstab h b a
addRow val headerValue bases crosstab =
    addRows [ { value = val, key = headerValue } ] bases crosstab


{-| add multiple rows to the end of crosstab at once
-}
addRows : List { value : a, key : h } -> List b -> Crosstab h b a -> Crosstab h b a
addRows values bases (Crosstab state) =
    let
        newKeysList =
            List.map .key values

        valuesColumnsAndBases =
            List.Cartesian.map3 (\v c b -> ( v, c, b ))
                values
                state.columns
                bases

        xbValues =
            valuesColumnsAndBases
                |> List.foldr
                    (\( v, column, base ) ->
                        Dict.Any.insert
                            { row = v.key
                            , col = column
                            , base = base
                            }
                            v.value
                    )
                    state.values
    in
    Crosstab
        { state
            | rows = state.rows ++ newKeysList
            , values = xbValues
            , rowCount = state.rowCount + List.length values
        }


{-| Ignores total row/column.

For this starting state:

  - crosstab [row0, row1]
  - table [total, row0, row1]

It will behave like:

    addColumnAtIndex 0 "foo" bases crosstab
    --> crosstab: [foo, row0, row1]
    --> table: [total, foo, row0, row1]

    addColumnAtIndex 1 "foo" bases crosstab
    --> crosstab: [row0, foo, row1]
    --> table: [total, row0, foo, row1]

    addColumnAtIndex 2 "foo" bases crosstab
    --> crosstab: [row0, row1, foo]
    --> table: [total, row0, row1, foo]

-}
addColumnAtIndex : a -> Int -> h -> List b -> Crosstab h b a -> Crosstab h b a
addColumnAtIndex val index headerValue bases (Crosstab state) =
    Crosstab
        { state
            | columns = insertAtIndex index headerValue state.colCount state.columns
            , values =
                List.Cartesian.map2 Tuple.pair state.rows bases
                    |> List.foldr
                        (\( row, base ) ->
                            Dict.Any.insert
                                { row = row
                                , col = headerValue
                                , base = base
                                }
                                val
                        )
                        state.values
            , colCount = state.colCount + 1
        }


{-| add column to the end of crosstab
-}
addColumn : a -> h -> List b -> Crosstab h b a -> Crosstab h b a
addColumn val headerValue bases ((Crosstab state) as crosstab) =
    addColumnAtIndex val state.colCount headerValue bases crosstab


{-| add multiple columns to the end of crosstab at once
-}
addColumns : List { value : a, key : h } -> List b -> Crosstab h b a -> Crosstab h b a
addColumns values bases (Crosstab state) =
    let
        newKeysList =
            List.map .key values

        valuesRowsAndBases =
            List.Cartesian.map3 (\v r b -> ( v, r, b ))
                values
                state.rows
                bases

        xbValues =
            valuesRowsAndBases
                |> List.foldr
                    (\( v, row, base ) ->
                        Dict.Any.insert
                            { row = row
                            , col = v.key
                            , base = base
                            }
                            v.value
                    )
                    state.values
    in
    Crosstab
        { state
            | columns = state.columns ++ newKeysList
            , values = xbValues
            , colCount = state.colCount + List.length values
        }


{-| get cell value
-}
value : { row : h, col : h, base : b } -> Crosstab h b a -> Maybe a
value key (Crosstab { values }) =
    Dict.Any.get key values


{-| Determine if all values satisfy some test
-}
all : (a -> Bool) -> Crosstab h b a -> Bool
all predicate (Crosstab { values }) =
    Dict.Any.values values
        |> List.all predicate


any : (a -> Bool) -> Crosstab h b a -> Bool
any predicate (Crosstab { values }) =
    Dict.Any.values values
        |> List.any predicate


{-| get list of rows
-}
getRows : Crosstab h b a -> List h
getRows (Crosstab { rows }) =
    rows


{-| get list of columns
-}
getColumns : Crosstab h b a -> List h
getColumns (Crosstab { columns }) =
    columns


{-| insert (replace on collision) cell in crosstab cell
-}
insert : { row : h, col : h, base : b } -> a -> Crosstab h b a -> Crosstab h b a
insert key val (Crosstab ({ values } as rec)) =
    Crosstab { rec | values = Dict.Any.insert key val values }


update : { row : h, col : h, base : b } -> (Maybe a -> Maybe a) -> Crosstab h b a -> Crosstab h b a
update key fn (Crosstab ctData) =
    Crosstab { ctData | values = Dict.Any.update key fn ctData.values }


updateRowKeys : (h -> h) -> Crosstab h b a -> Crosstab h b a
updateRowKeys f (Crosstab state) =
    Crosstab
        { state
            | rows = List.map f state.rows
            , values =
                Dict.Any.foldr
                    (\key -> Dict.Any.insert { key | row = f key.row })
                    (Dict.Any.removeAll state.values)
                    state.values
        }


updateColumnKeys : (h -> h) -> Crosstab h b a -> Crosstab h b a
updateColumnKeys f (Crosstab state) =
    Crosstab
        { state
            | columns = List.map f state.columns
            , values =
                Dict.Any.foldr
                    (\key -> Dict.Any.insert { key | col = f key.col })
                    (Dict.Any.removeAll state.values)
                    state.values
        }


updateKeys : (h -> h) -> Crosstab h b a -> Crosstab h b a
updateKeys f (Crosstab state) =
    Crosstab
        { state
            | columns = List.map f state.columns
            , rows = List.map f state.rows
            , values =
                Dict.Any.foldr
                    (\key ->
                        Dict.Any.insert
                            { key
                                | row = f key.row
                                , col = f key.col
                            }
                    )
                    (Dict.Any.removeAll state.values)
                    state.values
        }


{-| Remove row with given key
-}
removeRow : h -> Crosstab h b a -> Crosstab h b a
removeRow key =
    filterRows ((/=) key)


{-| Keep only the rows satisfying the predicate
-}
filterRows : (h -> Bool) -> Crosstab h b a -> Crosstab h b a
filterRows predicate (Crosstab ({ values, rows } as rec)) =
    let
        filteredRows =
            List.filter predicate rows
    in
    Crosstab
        { rec
            | values = Dict.Any.filter (\{ row } _ -> predicate row) values
            , rows = filteredRows
            , rowCount = List.length filteredRows
        }


{-| Remove column with given key
-}
removeColumn : h -> Crosstab h b a -> Crosstab h b a
removeColumn key =
    filterColumns ((/=) key)


{-| Keep only the columns satisfying the predicate
-}
filterColumns : (h -> Bool) -> Crosstab h b a -> Crosstab h b a
filterColumns predicate (Crosstab ({ values, columns } as rec)) =
    let
        filteredColumns =
            List.filter predicate columns
    in
    Crosstab
        { rec
            | values = Dict.Any.filter (\{ col } _ -> predicate col) values
            , columns = filteredColumns
            , colCount = List.length filteredColumns
        }


{-| map crosstab values
-}
map : ({ row : h, col : h, base : b } -> a1 -> a2) -> Crosstab h b a1 -> Crosstab h b a2
map f (Crosstab rec) =
    Crosstab
        { columns = rec.columns
        , rows = rec.rows
        , values = Dict.Any.map f rec.values
        , rowCount = rec.rowCount
        , colCount = rec.colCount
        }


{-| Foldr crosstab
-}
foldr : ({ row : h, col : h, base : b } -> a -> acc -> acc) -> acc -> Crosstab h b a -> acc
foldr f acc (Crosstab { values }) =
    Dict.Any.foldr f acc values


toListForBase : b -> Crosstab h b a -> List ( { row : h, col : h, base : b }, a )
toListForBase wantedBase (Crosstab { values }) =
    values
        |> Dict.Any.filter (\{ base } _ -> base == wantedBase)
        |> Dict.Any.toList


switchRowsAndColumns : (a -> a) -> Crosstab h b a -> Crosstab h b a
switchRowsAndColumns modifyValue (Crosstab state) =
    Crosstab
        { state
            | rows = state.columns
            , columns = state.rows
            , values =
                Dict.Any.foldr
                    (\key v -> Dict.Any.insert { key | row = key.col, col = key.row } (modifyValue v))
                    (Dict.Any.removeAll state.values)
                    state.values
            , rowCount = state.colCount
            , colCount = state.rowCount
        }


{-| Retrieve values from the first crosstab, which are associated with keys, which are not present in the second crosstab.
-}
getRemovedValues : Crosstab h b a -> Crosstab h b a -> List a
getRemovedValues (Crosstab before) (Crosstab after) =
    Dict.Any.values <| Dict.Any.diff before.values after.values


{-| Gets the range for a specific base.
-}
getRange : (a -> Maybe Float) -> b -> Crosstab h b a -> Range
getRange getNum base crosstab =
    let
        f key val range =
            if key.base == base then
                Maybe.unwrap
                    range
                    (\n -> Range.extendWith n range)
                    (getNum val)

            else
                range
    in
    -- Initial min is Infinity
    foldr f Range.init crosstab


getValues : Crosstab h b a -> AnyDict ( String, String, String ) { row : h, col : h, base : b } a
getValues (Crosstab { values }) =
    values


{-| Adds the given value for all row x column combinations and the given base.
Leaves rows and columns untouched.
-}
addBase : b -> a -> Crosstab h b a -> Crosstab h b a
addBase base value_ (Crosstab r) =
    let
        newValues : AnyDict ( String, String, String ) { row : h, col : h, base : b } a
        newValues =
            List.Cartesian.map2 Tuple.pair r.rows r.columns
                |> List.foldl
                    (\( row, col ) ->
                        Dict.Any.insert
                            { row = row
                            , col = col
                            , base = base
                            }
                            value_
                    )
                    (Dict.Any.removeAll r.values)
    in
    Crosstab { r | values = Dict.Any.union newValues r.values }


{-| Removes all values with the given base from the crosstab.
Leaves rows and columns untouched.
-}
removeBase : b -> Crosstab h b a -> Crosstab h b a
removeBase base (Crosstab r) =
    Crosstab
        { r
            | values =
                Dict.Any.filter
                    (\key _ -> key.base /= base)
                    r.values
        }


{-| Assumes you don't add / remove any items.
-}
reorderRows : List h -> Crosstab h b a -> Crosstab h b a
reorderRows newRows (Crosstab r) =
    Crosstab { r | rows = newRows }


{-| Assumes you don't add / remove any items.
-}
reorderColumns : List h -> Crosstab h b a -> Crosstab h b a
reorderColumns newColumns (Crosstab r) =
    Crosstab { r | columns = newColumns }
