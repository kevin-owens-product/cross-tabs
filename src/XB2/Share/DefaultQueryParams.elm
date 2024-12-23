module XB2.Share.DefaultQueryParams exposing (fromResult)

import Url.Builder as Url exposing (QueryParameter)
import XB2.Share.Config exposing (Flags)


fromResult : Result err { a | flags : Flags } -> List QueryParameter
fromResult result =
    result
        |> Result.toMaybe
        |> Maybe.andThen
            (.flags
                >> .revision
                >> Maybe.map (Url.string "revision" >> List.singleton)
            )
        |> Maybe.withDefault []
