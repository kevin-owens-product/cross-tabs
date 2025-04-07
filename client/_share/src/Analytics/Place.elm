module Analytics.Place exposing (Place(..), encode)

import Json.Encode as Encode exposing (Value)


type Place
    = TVPlanner


encode : Place -> Value
encode place =
    Encode.string <|
        case place of
            TVPlanner ->
                "tv_planner"
