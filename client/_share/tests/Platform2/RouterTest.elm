module Platform2.RouterTest exposing (suite)

import Config exposing (Flags)
import Data.Id
import Expect
import Factory.Flags
import Platform2.Router as Router exposing (Route(..))
import Test exposing (..)


flagsWith : Maybe String -> Flags
flagsWith feature =
    let
        f =
            Factory.Flags.withFeature Nothing
    in
    { f | feature = feature, platform2Url = "https://p2-url.gwi.com" }


suite : Test
suite =
    describe "Platform2.Router"
        [ describe "toUrlString"
            ([ ( AudienceBuilderNew, flagsWith (Just "dashboards"), "/audiences/new" )
             , ( Insights, flagsWith (Just "dashboards"), "/insights" )
             , ( Insights, flagsWith (Just "ATC-666/dashboards"), "/ATC-666/insights" )
             , ( ChartBuilderChart (Data.Id.fromString "q1"), flagsWith (Just "ATC-666/dashboards"), "/ATC-666/chart-builder/chart/q1" )
             , ( ChartBuilderChart (Data.Id.fromString "q1"), flagsWith (Just "dashboards"), "/chart-builder/chart/q1" )
             ]
                |> List.indexedMap
                    (\i ( route, flags, expected ) ->
                        test ("Route should be correct " ++ String.fromInt i) <|
                            \() ->
                                Router.toUrlString flags route
                                    |> Expect.equal (flags.platform2Url ++ expected)
                    )
            )
        ]
