module PermissionsTest exposing (permissionsDecoderTest)

import Data.User
    exposing
        ( Feature(..)
        , Plan(..)
        , planToString
        , toFeatureSet
        )
import Expect
import Factory.User
import Permissions exposing (Permission(..))
import Set.Any
import Test exposing (..)


permissionsDecoderTest : Test
permissionsDecoderTest =
    describe "Permissions.fromUser" <|
        [ test "Can access CreateDashboards when is curator" <|
            \() ->
                let
                    user =
                        Factory.User.withPlan Free

                    can =
                        Permissions.fromUser { user | customerFeatures = Set.Any.insert Curator user.customerFeatures }
                in
                Expect.equal True (can CreateDashboards)
        , test "Freemium user access" <|
            \() ->
                let
                    user =
                        Factory.User.withPlan Free

                    can =
                        Permissions.fromUser { user | customerFeatures = toFeatureSet [] }
                in
                Expect.equal
                    [ True
                    , True
                    , True
                    , True
                    , True
                    , True
                    ]
                <|
                    List.map can
                        [ AccessAudienceBuilder
                        , CreateAudiences
                        , AccessChartBuilder
                        , AccessDashboards
                        , CreateAudiences
                        , AccessAudienceBuilder
                        ]
        , test "Can ReceiveEmailExports" <|
            \() ->
                let
                    user =
                        Factory.User.withPlan Dashboards

                    can =
                        Permissions.fromUser { user | customerFeatures = toFeatureSet [ EmailExports ] }
                in
                Expect.equal True (can ReceiveEmailExports)
        ]
            ++ List.map
                (\( plan, abilities, notAttrs ) ->
                    let
                        can =
                            Permissions.fromUser <| Factory.User.withPlan plan

                        abilityTest thing =
                            test ("Can " ++ Permissions.toString thing) <|
                                \() -> Expect.equal True (can thing)

                        notAbilitiesTest thing =
                            test ("Can't " ++ Permissions.toString thing) <|
                                \() -> Expect.equal False (can thing)
                    in
                    describe ("For plan " ++ planToString plan) <|
                        List.map abilityTest abilities
                            ++ List.map notAbilitiesTest notAttrs
                            ++ List.map notAbilitiesTest [ ReceiveEmailExports, CreateDashboards ]
                )
                [ ( Free
                  , [ AccessAudienceBuilder
                    , AccessChartBuilder
                    , AccessDashboards
                    , CreateAudiences
                    ]
                  , []
                  )
                , ( FreeReports
                  , [ AccessAudienceBuilder
                    , AccessReports
                    , AccessChartBuilder
                    , AccessDashboards
                    , CreateAudiences
                    ]
                  , []
                  )
                , ( Dashboards
                  , [ AccessAudienceBuilder
                    , AccessDashboards
                    , AccessReports
                    , SeeExtendedAudiences
                    ]
                  , [ AccessChartBuilder
                    , CreateAudiences
                    ]
                  )
                , ( Professional
                  , [ AccessAudienceBuilder
                    , AccessChartBuilder
                    , AccessDashboards
                    , AccessReports
                    , CreateAudiences
                    , SeeExtendedAudiences
                    ]
                  , []
                  )
                , ( Api, [ CreateAudiences ], [] )

                -- TODO Student is missing
                ]
