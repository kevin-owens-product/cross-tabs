module Platform2.Router exposing
    ( Route(..)
    , toUrlString
    )

import Basics.Extra exposing (flip)
import Config exposing (Flags)
import Data.Id as Id
import Data.Platform2
    exposing
        ( AudienceId
        , ChartId
        )
import Maybe.Extra as Maybe


type Route
    = AudienceBuilderNew
    | AudienceBuilderDetail AudienceId
    | ChartBuilderChart ChartId
    | Insights


toUrlString : Flags -> Route -> String
toUrlString flags route =
    let
        host =
            flags.platform2Url

        cleanFeature =
            Maybe.andThen
                (\feature ->
                    case String.split "/" feature of
                        _ :: [] ->
                            Nothing

                        cleanPart :: _ ->
                            Just cleanPart

                        [] ->
                            Nothing
                )

        path =
            "/"
                ++ (case route of
                        AudienceBuilderNew ->
                            "audiences/new"

                        AudienceBuilderDetail audienceId ->
                            "audiences/" ++ Id.unwrap audienceId

                        ChartBuilderChart chartId ->
                            "chart-builder/chart/" ++ Id.unwrap chartId

                        Insights ->
                            "insights"
                   )
    in
    host ++ (Maybe.unwrap path (flip (++) path << (++) "/") <| cleanFeature flags.feature)
