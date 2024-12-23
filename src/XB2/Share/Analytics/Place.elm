module XB2.Share.Analytics.Place exposing (Place(..), encode)

import Json.Encode as Encode exposing (Value)


type Place
    = CrosstabBuilder
    | CrosstabBuilderBase
    | CrosstabBuilderList
      -- UnknownPlace used when firing open menu events from NotFoundRoute
    | UnknownPlace


encode : Place -> Value
encode place =
    Encode.string <|
        case place of
            CrosstabBuilder ->
                "query_builder"

            CrosstabBuilderBase ->
                "query_builder_base"

            CrosstabBuilderList ->
                "query_builder_list"

            UnknownPlace ->
                "unknown"
