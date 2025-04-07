module DefaultQueryParams exposing (fromResult)

import Config exposing (Flags)
import Url.Builder as Url exposing (QueryParameter)


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
