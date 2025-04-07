module Filters.Features exposing
    ( Feature(..)
    , Features
    , defaultFeatures
    , is
    )


type Feature
    = Audiences
    | BaseAudience
    | Locations
    | Waves
    | Splitters
    | ExcludeUserAudience
    | ToggleAllAudiences


type Features
    = Features (List Feature)


defaultFeatures : Features
defaultFeatures =
    Features
        [ Audiences
        , ToggleAllAudiences
        , BaseAudience
        , Locations
        , Waves
        , Splitters
        ]


is : Feature -> Features -> Bool
is feature (Features features) =
    List.member feature features
