module XB2.List.Sort exposing (ProjectOwner(..), SortBy(..), projectOwnerToString, sort, sortByToString)

import NaturalOrdering
import Time exposing (Posix)
import XB2.Share.Gwi.List as List


type SortBy
    = NameAsc
    | NameDesc
    | LastModifiedAsc
    | LastModifiedDesc
    | CreatedAsc
    | CreatedDesc
    | OwnedByAsc
    | OwnedByDesc


sortByToString : SortBy -> String
sortByToString sortBy =
    case sortBy of
        NameAsc ->
            "Name Ascending"

        NameDesc ->
            "Name Descending"

        LastModifiedAsc ->
            "Last modified Ascending"

        LastModifiedDesc ->
            "Last modified Descending"

        CreatedAsc ->
            "Date created Ascending"

        CreatedDesc ->
            "Date created Descending"

        OwnedByAsc ->
            "Onwer Ascending"

        OwnedByDesc ->
            "Onwer Descending"


keepKeywordLastSort : String -> (a -> String) -> a -> a -> Order
keepKeywordLastSort keyword f x y =
    if f x == keyword then
        GT

    else if f y == keyword then
        LT

    else
        NaturalOrdering.compare (f x) (f y)


type ProjectOwner
    = Me
    | NotMe { email : String }


projectOwnerToString : ProjectOwner -> String
projectOwnerToString ow =
    case ow of
        Me ->
            "Me"

        NotMe { email } ->
            email


sort :
    SortBy
    ->
        List
            { item : item
            , getUpdatedAt : item -> Posix
            , getCreatedAt : item -> Posix
            , getName : item -> String
            , owner : ProjectOwner
            , parent : Maybe item
            }
    -> List item
sort sortBy =
    List.map .item
        << (case sortBy of
                LastModifiedAsc ->
                    List.sortBy (\item -> item.getUpdatedAt item.item |> Time.posixToMillis)

                LastModifiedDesc ->
                    List.reverseSortBy (\item -> item.getUpdatedAt item.item |> Time.posixToMillis)

                CreatedAsc ->
                    List.sortBy (\item -> item.getCreatedAt item.item |> Time.posixToMillis)

                CreatedDesc ->
                    List.reverseSortBy (\item -> item.getCreatedAt item.item |> Time.posixToMillis)

                OwnedByAsc ->
                    List.sortWith <| keepKeywordLastSort (projectOwnerToString Me) (.owner >> projectOwnerToString)

                OwnedByDesc ->
                    List.reverseSortWith <| keepKeywordLastSort (projectOwnerToString Me) (.owner >> projectOwnerToString)

                NameAsc ->
                    List.reverseSortBy (\item -> item.getName item.item |> String.toLower)

                NameDesc ->
                    List.sortBy (\item -> item.getName item.item |> String.toLower)
           )
