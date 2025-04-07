module Filters.ActiveAudiences exposing
    ( ActiveAudiences
    , empty
    , getBase
    , getColor
    , getQuantifier
    , isActive
    )

import Array exposing (Array)
import Data.Core exposing (AudienceId, AudienceIdTag)
import Data.Id exposing (IdDict, IdSet)
import Dict.Any
import Quantify exposing (Quantifier)
import Set.Any


type ActiveAudiences
    = ActiveAudiences
        { ids : IdSet AudienceIdTag
        , colors : IdDict AudienceIdTag ( Int, String )
        , ordered : Array AudienceId
        , selected_ : IdSet AudienceIdTag
        , base : Maybe AudienceId
        , loaded : IdSet AudienceIdTag
        }


empty : ActiveAudiences
empty =
    ActiveAudiences
        { ids = Data.Id.emptySet
        , colors = Data.Id.emptyDict
        , ordered = Array.empty
        , selected_ = Data.Id.emptySet
        , base = Nothing
        , loaded = Data.Id.emptySet
        }


isActive : AudienceId -> ActiveAudiences -> Bool
isActive id (ActiveAudiences { ids }) =
    Set.Any.member id ids


getColor : AudienceId -> ActiveAudiences -> Maybe String
getColor id (ActiveAudiences { colors }) =
    Dict.Any.get id colors
        |> Maybe.map Tuple.second


all : ActiveAudiences -> List AudienceId
all (ActiveAudiences { ids, ordered }) =
    Array.toList ordered
        |> List.filter (\id -> Set.Any.member id ids)


getQuantifier : List AudienceId -> ActiveAudiences -> Quantifier
getQuantifier list active =
    let
        activeList =
            all active
    in
    Quantify.list (\item -> List.member item activeList) list


getBase : ActiveAudiences -> Maybe AudienceId
getBase (ActiveAudiences { base }) =
    base
