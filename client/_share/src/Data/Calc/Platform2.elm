module Data.Calc.Platform2 exposing
    ( SimpleFilters
    , activeLocationsByNamespaceCode
    , activeWavesByNamespaceCode
    )

{-| The same as Data.Calc.Core, just using Data.Platform2 versions of entities
-}

import Data.Labels
    exposing
        ( Location
        , LocationCode
        , NamespaceCode
        , Wave
        , WaveCode
        )
import Data.Platform2
import Dict.Any
import RemoteData
import Store.Platform2



--  Result


type alias SimpleFilters =
    Data.Platform2.SimpleFilters


activeWavesByNamespaceCode : Store.Platform2.Store -> NamespaceCode -> List WaveCode -> List Wave
activeWavesByNamespaceCode store namespaceCode activeWaves =
    let
        namespaceCodeToUse : NamespaceCode
        namespaceCodeToUse =
            Data.Platform2.deepestNamespaceCode
                store.datasets
                store.datasetsToNamespaces
                store.lineages
                namespaceCode
                |> Maybe.withDefault namespaceCode
    in
    Dict.Any.get namespaceCodeToUse store.wavesByNamespace
        |> Maybe.andThen RemoteData.toMaybe
        |> Maybe.map Dict.Any.values
        |> Maybe.withDefault []
        |> List.filter (\{ code } -> List.member code activeWaves)


activeLocationsByNamespaceCode : Store.Platform2.Store -> NamespaceCode -> List LocationCode -> List Location
activeLocationsByNamespaceCode store namespaceCode activeLocations =
    let
        namespaceCodeToUse : NamespaceCode
        namespaceCodeToUse =
            Data.Platform2.deepestNamespaceCode
                store.datasets
                store.datasetsToNamespaces
                store.lineages
                namespaceCode
                |> Maybe.withDefault namespaceCode
    in
    Dict.Any.get namespaceCodeToUse store.locationsByNamespace
        |> Maybe.andThen RemoteData.toMaybe
        |> Maybe.map Dict.Any.values
        |> Maybe.withDefault []
        |> List.filter (\{ code } -> List.member code activeLocations)



-- SAMPLE SIZE
