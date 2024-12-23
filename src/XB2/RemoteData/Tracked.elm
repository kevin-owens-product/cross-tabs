module XB2.RemoteData.Tracked exposing
    ( RemoteData(..)
    , TrackerId
    , WebData
    , fromResult
    , getTrackerId
    , isDone
    , isFailure
    , isLoading
    , isNotAsked
    , isSuccess
    , loading
    , map
    , toMaybe
    , withDefault
    )

import XB2.Share.Gwi.Http exposing (Error)


{-| Slight modification of krisajenkins/remotedata with `Loading` constructor changed to include `TrackerId`.
This makes it possible to cancel request in progress via Http.cancel

This module doesn't provide Applicative / Monad functions (like andMap / andThen) because it's not clear how to combine
`Loading tracker1` with `Loading tracker2` without losing information.

-}
type RemoteData e a
    = NotAsked
    | Loading (Maybe TrackerId)
    | Failure e
    | Success a


type alias TrackerId =
    String


type alias WebData err a =
    RemoteData (Error err) a


map : (a -> b) -> RemoteData e a -> RemoteData e b
map f remoteData =
    case remoteData of
        Success value ->
            Success (f value)

        Loading trackerId ->
            Loading trackerId

        NotAsked ->
            NotAsked

        Failure error ->
            Failure error


fromResult : Result e a -> RemoteData e a
fromResult result =
    case result of
        Err e ->
            Failure e

        Ok x ->
            Success x


withDefault : a -> RemoteData e a -> a
withDefault default remoteData =
    case remoteData of
        Success x ->
            x

        _ ->
            default


toMaybe : RemoteData e a -> Maybe a
toMaybe =
    map Just >> withDefault Nothing


isDone : RemoteData e a -> Bool
isDone remoteData =
    case remoteData of
        Success _ ->
            True

        Failure _ ->
            True

        Loading _ ->
            False

        NotAsked ->
            False


isSuccess : RemoteData e a -> Bool
isSuccess remoteData =
    case remoteData of
        Success _ ->
            True

        _ ->
            False


isLoading : RemoteData e a -> Bool
isLoading remoteData =
    case remoteData of
        Loading _ ->
            True

        _ ->
            False


isFailure : RemoteData e a -> Bool
isFailure remoteData =
    case remoteData of
        Failure _ ->
            True

        _ ->
            False


isNotAsked : RemoteData e a -> Bool
isNotAsked remoteData =
    remoteData == NotAsked



-- Additional functions to track / cancel requests


loading : TrackerId -> RemoteData e a
loading trackerId =
    Loading (Just trackerId)


getTrackerId : RemoteData e a -> Maybe TrackerId
getTrackerId remoteData =
    case remoteData of
        Loading maybeTrackerId ->
            maybeTrackerId

        _ ->
            Nothing
