module RemoteData.Loaded exposing
    ( RemoteData(..)
    , WebData
    , andThen
    , isSuccess
    )

{-| Slight modification of krisajenkins/remotedata with `Loading` constructor
changed to include the previously loaded value (if we have it).

This allows for refreshing values (showing a spinner) while still seeing old results.

-}

import Http


type RemoteData e a
    = NotAskedL
    | LoadingL (Maybe a)
    | FailureL e
    | SuccessL a


type alias WebData a =
    RemoteData Http.Error a


isSuccess : RemoteData e a -> Bool
isSuccess data =
    case data of
        SuccessL _ ->
            True

        _ ->
            False


andThen : (a -> RemoteData e b) -> RemoteData e a -> RemoteData e b
andThen fn data =
    case data of
        SuccessL a ->
            fn a

        LoadingL (Just a) ->
            case fn a of
                SuccessL b ->
                    LoadingL (Just b)

                other ->
                    other

        LoadingL Nothing ->
            LoadingL Nothing

        FailureL e ->
            FailureL e

        NotAskedL ->
            NotAskedL
