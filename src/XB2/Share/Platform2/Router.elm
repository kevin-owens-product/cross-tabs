module XB2.Share.Platform2.Router exposing
    ( Route(..)
    , toUrlString
    )

import Basics.Extra exposing (flip)
import Maybe.Extra as Maybe
import XB2.Share.Config exposing (Flags)
import XB2.Share.Data.Id as Id
import XB2.Share.Data.Platform2
    exposing
        ( AudienceId
        )


type Route
    = AudienceBuilderNew
    | AudienceBuilderDetail AudienceId


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
                   )
    in
    host ++ (Maybe.unwrap path (flip (++) path << (++) "/") <| cleanFeature flags.feature)
