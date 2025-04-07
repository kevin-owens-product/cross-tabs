module UndoRedo exposing
    ( UndoRedo
    , commit
    , current
    , hasFuture
    , hasPast
    , init
    , lengthFuture
    , lengthPast
    , new
    , redo
    , undo
    )


type alias UndoRedoData tag state =
    -- Nothing : Maybe tag == initial state
    { previous : List ( Maybe tag, state )
    , current : ( Maybe tag, state )
    , future : List ( Maybe tag, state )
    , maxHistoryLength : Int
    }


type UndoRedo tag state
    = UndoRedo (UndoRedoData tag state)


init : Int -> state -> UndoRedo tag state
init maxHistoryLength initState =
    UndoRedo <| UndoRedoData [] ( Nothing, initState ) [] maxHistoryLength


addWithLimit : Int -> ( Maybe tag, state ) -> List ( Maybe tag, state ) -> List ( Maybe tag, state )
addWithLimit maxHistoryLength state list =
    case list of
        [] ->
            [ state ]

        firstAdded :: rest ->
            if List.length list >= maxHistoryLength then
                rest ++ [ state ]

            else
                firstAdded :: rest ++ [ state ]


moveCurrentToPrevious : UndoRedoData tag state -> UndoRedoData tag state
moveCurrentToPrevious data =
    { data | previous = addWithLimit data.maxHistoryLength data.current data.previous }


current : UndoRedo tag state -> state
current (UndoRedo data) =
    Tuple.second data.current


commit : tag -> (state -> state) -> UndoRedo tag state -> UndoRedo tag state
commit tag updateState (UndoRedo undoRedo) =
    moveCurrentToPrevious undoRedo
        |> (\d ->
                { d
                    | current =
                        ( Just tag
                        , updateState <| Tuple.second d.current
                        )
                    , future = []
                }
           )
        |> UndoRedo


new : tag -> state -> UndoRedo tag state -> UndoRedo tag state
new tag state =
    commit tag (always state)


hasPast : UndoRedo tag state -> Bool
hasPast (UndoRedo undoRedo) =
    not <| List.isEmpty undoRedo.previous


hasFuture : UndoRedo tag state -> Bool
hasFuture (UndoRedo undoRedo) =
    not <| List.isEmpty undoRedo.future


lengthPast : UndoRedo tag state -> Int
lengthPast (UndoRedo undoRedo) =
    List.length undoRedo.previous


lengthFuture : UndoRedo tag state -> Int
lengthFuture (UndoRedo undoRedo) =
    List.length undoRedo.future


undo : UndoRedo tag state -> UndoRedo tag state
undo (UndoRedo data) =
    UndoRedo <|
        case List.reverse data.previous of
            [] ->
                data

            lastAdded :: restOfPrevious ->
                { data
                    | future = addWithLimit data.maxHistoryLength data.current data.future
                    , current = lastAdded
                    , previous = List.reverse restOfPrevious
                }


redo : UndoRedo tag state -> UndoRedo tag state
redo (UndoRedo data) =
    UndoRedo <|
        case List.reverse data.future of
            [] ->
                data

            lastAdded :: restOfFuture ->
                { data
                    | previous = addWithLimit data.maxHistoryLength data.current data.previous
                    , current = lastAdded
                    , future = List.reverse restOfFuture
                }
