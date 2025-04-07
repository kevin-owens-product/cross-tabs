module XB2.Share.UndoRedo.Step exposing (Step, andThen, map, runAndCommit)

import XB2.Share.UndoRedo exposing (UndoRedo)


{-| Step is in fact state monad implementation.
-}
type alias Step s a =
    s -> ( s, a )


map : (a -> b) -> Step s a -> Step s b
map f step =
    Tuple.mapSecond f << step


andThen : (a -> Step s b) -> Step s a -> Step s b
andThen f step =
    (\( newState, value ) -> f value newState) << step


{-| This is like `runState` but it works with `UndoRedo` type
and does commit the change to its history
-}
runAndCommit : tag -> UndoRedo tag s -> Step s a -> ( UndoRedo tag s, a )
runAndCommit tag state step =
    XB2.Share.UndoRedo.current state
        |> step
        |> Tuple.mapFirst (\s -> XB2.Share.UndoRedo.commit tag (always s) state)
