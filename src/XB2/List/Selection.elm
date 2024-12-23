module XB2.List.Selection exposing
    ( Selection(..)
    , empty
    , isAnySelected
    , isSelected
    , selectAll
    , selectedCount
    , toggle
    )

import List.NonEmpty as NonemptyList exposing (NonEmpty)
import Maybe.Extra as Maybe
import XB2.Data
    exposing
        ( XBProjectId
        )


type Selection
    = NotSelected
    | SelectedProjects (NonEmpty XBProjectId)


empty : Selection
empty =
    NotSelected


toggleItem : a -> NonEmpty a -> Maybe (NonEmpty a)
toggleItem item list =
    if NonemptyList.member item list then
        NonemptyList.filter ((/=) item) list

    else
        Just <| NonemptyList.cons item list


toggle : XBProjectId -> Selection -> Selection
toggle projectId selection =
    case selection of
        NotSelected ->
            SelectedProjects <| NonemptyList.singleton projectId

        SelectedProjects projects ->
            toggleItem projectId projects
                |> Maybe.unwrap NotSelected SelectedProjects


selectAll : List XBProjectId -> Selection -> Selection
selectAll projects selection =
    case selection of
        NotSelected ->
            NonemptyList.fromList projects
                |> Maybe.unwrap NotSelected SelectedProjects

        SelectedProjects list ->
            List.foldr NonemptyList.cons list projects
                |> NonemptyList.unique
                |> SelectedProjects


isSelected : XBProjectId -> Selection -> Bool
isSelected projectId selection =
    case selection of
        NotSelected ->
            False

        SelectedProjects projects ->
            NonemptyList.any ((==) projectId) projects


isAnySelected : Selection -> Bool
isAnySelected selection =
    case selection of
        NotSelected ->
            False

        SelectedProjects _ ->
            True


selectedCount : Selection -> Int
selectedCount selection =
    case selection of
        NotSelected ->
            0

        SelectedProjects projects ->
            NonemptyList.length projects
