module XB2.Share.Analytics.Common exposing
    ( commaSeparated
    , list
    , regionsFromLocations
    , yearsFromWaves
    )

import Json.Encode as Encode exposing (Value)
import List.Extra as List
import XB2.Share.Data.Labels exposing (Location, Wave, waveYear)


list : (a -> String) -> List a -> Value
list toString =
    Encode.list (Encode.string << toString)


commaSeparated : (a -> String) -> List a -> Value
commaSeparated toString =
    List.map toString
        >> String.join ","
        >> Encode.string


regionsFromLocations : List Location -> List String
regionsFromLocations locations =
    locations
        |> List.map (.region >> XB2.Share.Data.Labels.regionName)
        |> List.unique


yearsFromWaves : List Wave -> List String
yearsFromWaves =
    List.map (waveYear >> String.fromInt) >> List.unique
