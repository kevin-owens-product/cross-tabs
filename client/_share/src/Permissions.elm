module Permissions exposing
    ( Can
    , Permission(..)
    , fromUser
    , toString
    )

-- modules

import Basics.Extra exposing (flip)
import Data.User exposing (Feature(..), Plan(..), User)
import Gwi.List as List
import Set.Any as AnySet


type Permission
    = CreateAudiences
    | SeeExtendedAudiences
    | AccessChartBuilder
    | AccessDashboards
    | AccessReports
    | AccessAudienceBuilder
    | CreateCuratedAudiences
    | CreateDashboards
    | ReceiveEmailExports
    | UseXB1
    | DowngradePlan
    | UseTV1
    | UseTV2
    | DownloadInfographics
    | DownloadReports
    | Export
    | SearchProducts
    | SearchQuestionsAndDatapoints
    | UseDebugButtons
    | UseXB50kTableLimit
    | UseXB2
    | UseDashboards2
    | SeeSupportChat
    | BeDashboardsGWICreator
    | BeDashboardsNonGWICreator
    | EditAudiencesAndChartsInDashboards2
    | UseP1AfterSunset
    | ShareOpenAccessDashboard


type alias Can =
    Permission -> Bool


fromUser : User -> Can
fromUser { planHandle, customerFeatures } =
    let
        planBased =
            case planHandle of
                Free ->
                    [ AccessAudienceBuilder
                    , AccessChartBuilder
                    , AccessReports
                    , AccessDashboards
                    , CreateAudiences
                    , SearchProducts
                    , SearchQuestionsAndDatapoints
                    , SeeSupportChat
                    ]

                FreeReports ->
                    [ AccessAudienceBuilder
                    , AccessChartBuilder
                    , AccessReports
                    , AccessDashboards
                    , CreateAudiences
                    , SearchProducts
                    , SearchQuestionsAndDatapoints
                    , SeeSupportChat
                    ]

                Dashboards ->
                    [ AccessAudienceBuilder
                    , AccessDashboards
                    , AccessReports
                    , SeeExtendedAudiences
                    , SearchProducts
                    , SearchQuestionsAndDatapoints
                    , SeeSupportChat
                    ]

                Professional ->
                    [ AccessAudienceBuilder
                    , CreateAudiences
                    , SeeExtendedAudiences
                    , AccessChartBuilder
                    , AccessDashboards
                    , AccessReports
                    , UseXB1
                    , SearchProducts
                    , SearchQuestionsAndDatapoints
                    , SeeSupportChat
                    ]

                Api ->
                    [ CreateAudiences
                    , SearchProducts
                    , SearchQuestionsAndDatapoints
                    , SeeSupportChat
                    ]

                Student ->
                    [ AccessReports
                    , SearchProducts
                    ]

                ViewOnly ->
                    [ AccessAudienceBuilder
                    , AccessChartBuilder
                    , AccessReports
                    , AccessDashboards
                    , SeeSupportChat
                    ]

                OpenAccessViewOnly ->
                    [ AccessDashboards ]

                Plus ->
                    []

                PlusEnterprise ->
                    []

                AnotherPlan _ ->
                    []

        canExport =
            not <| AnySet.member ExportBlocked customerFeatures
    in
    planBased
        |> List.addIf
            (AnySet.member CanShareOpenAccessDashboard customerFeatures)
            ShareOpenAccessDashboard
        |> List.addIf (AnySet.member Curator customerFeatures) CreateDashboards
        |> List.addIf (AnySet.member Curator customerFeatures) CreateCuratedAudiences
        |> List.addIf (AnySet.member EmailExports customerFeatures) ReceiveEmailExports
        |> List.addIf (AnySet.member CanUseTV customerFeatures) UseTV1
        |> List.addIf (AnySet.member TVForPlatform2 customerFeatures) UseTV2
        |> List.addIf (AnySet.member CanDowngrade customerFeatures) DowngradePlan
        |> List.addIf (planHandle /= Free && planHandle /= Api && canExport) DownloadInfographics
        |> List.addIf (planHandle /= Free && planHandle /= Api && canExport) DownloadReports
        |> List.addIf canExport Export
        |> List.addIf (AnySet.member CanUseDebugButtons customerFeatures) UseDebugButtons
        |> List.addIf (AnySet.member XB50kTableLimit customerFeatures) UseXB50kTableLimit
        |> List.addIf (planHandle == Professional && AnySet.member XBForPlatform2 customerFeatures) UseXB2
        |> List.addIf (AnySet.member DashboardsForPlatform2 customerFeatures) UseDashboards2
        |> List.addIf (AnySet.member DashboardsGWICreator customerFeatures) BeDashboardsGWICreator
        |> List.addIf (AnySet.member DashboardsNonGWICreator customerFeatures) BeDashboardsNonGWICreator
        |> List.addIf (AnySet.member CanUseP1AfterSunset customerFeatures) UseP1AfterSunset
        |> List.addIf (not (planHandle == Dashboards && AnySet.member DashboardsOnly_NoAudiencesCharts customerFeatures)) EditAudiencesAndChartsInDashboards2
        |> AnySet.fromList toString
        |> flip AnySet.member


toString : Permission -> String
toString permission =
    case permission of
        CreateAudiences ->
            "CreateAudiences"

        SeeExtendedAudiences ->
            "SeeExtendedAudiences"

        AccessChartBuilder ->
            "AccessChartBuilder"

        AccessDashboards ->
            "AccessDashboards"

        AccessReports ->
            "AccessReports"

        AccessAudienceBuilder ->
            "AccessAudienceBuilder"

        CreateCuratedAudiences ->
            "CreateCuratedAudiences"

        CreateDashboards ->
            "CreateDashboards"

        ReceiveEmailExports ->
            "ReceiveEmailExports"

        UseXB1 ->
            "UseQueryBuilder"

        DowngradePlan ->
            "DowngradePlan"

        UseTV1 ->
            "UseTV1"

        UseTV2 ->
            "UseTV2"

        DownloadInfographics ->
            "DownloadInfographics"

        DownloadReports ->
            "DownloadReports"

        Export ->
            "Export"

        SearchProducts ->
            "SearchProducts"

        SearchQuestionsAndDatapoints ->
            "SearchQuestionsAndDatapoints"

        UseDebugButtons ->
            "UseDebugButtons"

        UseXB50kTableLimit ->
            "UseXB50kTableLimit"

        UseXB2 ->
            "UseXB2"

        UseDashboards2 ->
            "UseDashboards2"

        SeeSupportChat ->
            "SeeSupportChat"

        BeDashboardsGWICreator ->
            "BeDashboardsGWICreator"

        BeDashboardsNonGWICreator ->
            "BeDashboardsNonGWICreator"

        EditAudiencesAndChartsInDashboards2 ->
            "EditAudiencesAndChartsInDashboards2"

        UseP1AfterSunset ->
            "UseP1AfterSunset"

        ShareOpenAccessDashboard ->
            "ShareOpenAccessDashboard"
