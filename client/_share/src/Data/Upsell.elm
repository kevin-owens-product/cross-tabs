module Data.Upsell exposing (Resource(..))

import Data.Core
    exposing
        ( AudienceId
        )


type Resource
    = AudienceResource AudienceId
