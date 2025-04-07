module XB2.Share.Icons.Overview exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attrs
import XB2.Share.Icons
import XB2.Share.Icons.ChartTypes as ChartTypes
import XB2.Share.Icons.FontAwesome as FaIcons
import XB2.Share.Icons.Gwi as GwiIcons
import XB2.Share.Icons.Platform2 as P2Icons


type alias Icon =
    { name : String
    , data : XB2.Share.Icons.IconData
    }


type alias Model =
    { gwiIcons : List Icon
    , faIcons : List Icon
    , p2Icons : List Icon
    , chartTypesIcons : List Icon
    }


init : Model
init =
    { gwiIcons =
        [ { name = "alphabeticalOrder", data = GwiIcons.alphabeticalOrder }
        , { name = "ascendingOrder", data = GwiIcons.ascendingOrder }
        , { name = "audience", data = GwiIcons.audience }
        , { name = "audienceSmall", data = GwiIcons.audienceSmall }
        , { name = "barChartHorizontal", data = GwiIcons.barChartHorizontal }
        , { name = "barChartVertical", data = GwiIcons.barChartVertical }
        , { name = "channels", data = GwiIcons.channels }
        , { name = "checkSmall", data = GwiIcons.checkSmall }
        , { name = "circle", data = GwiIcons.circle }
        , { name = "circleChecked", data = GwiIcons.circleChecked }
        , { name = "cross", data = GwiIcons.cross }
        , { name = "crossSmall", data = GwiIcons.crossSmall }
        , { name = "dataTable", data = GwiIcons.dataTable }
        , { name = "defaultList", data = GwiIcons.defaultList }
        , { name = "descendingOrder", data = GwiIcons.descendingOrder }
        , { name = "downAngleBracket", data = GwiIcons.downAngleBracket }
        , { name = "dragHandle", data = GwiIcons.dragHandle }
        , { name = "edit", data = GwiIcons.edit }
        , { name = "export", data = GwiIcons.export }
        , { name = "folder", data = GwiIcons.folder }
        , { name = "leftAngleBracket", data = GwiIcons.leftAngleBracket }
        , { name = "locations", data = GwiIcons.locations }
        , { name = "minus", data = GwiIcons.minus }
        , { name = "p2Combined", data = GwiIcons.p2Combined }
        , { name = "pencil", data = GwiIcons.pencil }
        , { name = "plus", data = GwiIcons.plus }
        , { name = "redo", data = GwiIcons.redo }
        , { name = "rightAngleBracketThin", data = GwiIcons.rightAngleBracketThin }
        , { name = "search", data = GwiIcons.search }
        , { name = "share", data = GwiIcons.share }
        , { name = "splitters", data = GwiIcons.splitters }
        , { name = "tick", data = GwiIcons.tick }
        , { name = "timezone", data = GwiIcons.timezone }
        , { name = "trash", data = GwiIcons.trash }
        , { name = "waves", data = GwiIcons.waves }
        ]
    , faIcons =
        [ { name = "angleDown", data = FaIcons.angleDown }
        , { name = "angleLeft", data = FaIcons.angleLeft }
        , { name = "angleRight", data = FaIcons.angleRight }
        , { name = "angleUp", data = FaIcons.angleUp }
        , { name = "arrowDown", data = FaIcons.arrowDown }
        , { name = "arrowRight", data = FaIcons.arrowRight }
        , { name = "arrowLeft", data = FaIcons.arrowLeft }
        , { name = "arrowUp", data = FaIcons.arrowUp }
        , { name = "arrowLeftRegular", data = FaIcons.arrowLeftRegular }
        , { name = "arrowRightRegular", data = FaIcons.arrowRightRegular }
        , { name = "barChart", data = FaIcons.barChart }
        , { name = "bookmark", data = FaIcons.bookmark }
        , { name = "check", data = FaIcons.check }
        , { name = "checkCircle", data = FaIcons.checkCircle }
        , { name = "checkSign", data = FaIcons.checkSign }
        , { name = "chevronDown", data = FaIcons.chevronDown }
        , { name = "chevronRightRegular", data = FaIcons.chevronRightRegular }
        , { name = "chevronUp", data = FaIcons.chevronUp }
        , { name = "cog", data = FaIcons.cog }
        , { name = "comments", data = FaIcons.comments }
        , { name = "copy", data = FaIcons.copy }
        , { name = "debug", data = FaIcons.debug }
        , { name = "download", data = FaIcons.download }
        , { name = "edit", data = FaIcons.edit }
        , { name = "ellipsisH", data = FaIcons.ellipsisH }
        , { name = "ellipsisVRegular", data = FaIcons.ellipsisVRegular }
        , { name = "exchange", data = FaIcons.exchange }
        , { name = "exclamationCircle", data = FaIcons.exclamationCircle }
        , { name = "externalLinkSquare", data = FaIcons.externalLinkSquare }
        , { name = "infoCircle", data = FaIcons.infoCircle }
        , { name = "minusSquare", data = FaIcons.minusSquare }
        , { name = "pencil", data = FaIcons.pencil }
        , { name = "plus", data = FaIcons.plus }
        , { name = "refresh", data = FaIcons.refresh }
        , { name = "sortLight", data = FaIcons.sortLight }
        , { name = "spinnerThird", data = FaIcons.spinnerThird }
        , { name = "square", data = FaIcons.square }
        , { name = "times", data = FaIcons.times }
        , { name = "timesCircle", data = FaIcons.timesCircle }
        , { name = "timesCircleRegular", data = FaIcons.timesCircleRegular }
        , { name = "toggleOff", data = FaIcons.toggleOff }
        , { name = "toggleOn", data = FaIcons.toggleOn }
        , { name = "userPlus", data = FaIcons.userPlus }
        ]
    , p2Icons =
        [ { name = "alignCenter", data = P2Icons.alignCenter }
        , { name = "alignLeft", data = P2Icons.alignLeft }
        , { name = "alignRight", data = P2Icons.alignRight }
        , { name = "alphabet", data = P2Icons.alphabet }
        , { name = "blank", data = P2Icons.blank }
        , { name = "arrowLeft", data = P2Icons.arrowLeft }
        , { name = "attribute", data = P2Icons.attribute }
        , { name = "audience", data = P2Icons.audience }
        , { name = "audienceDefault", data = P2Icons.audienceDefault }
        , { name = "audiences", data = P2Icons.audiences }
        , { name = "baseAudience", data = P2Icons.baseAudience }
        , { name = "caretDown", data = P2Icons.caretDown }
        , { name = "caretUp", data = P2Icons.caretUp }
        , { name = "chevronUp", data = P2Icons.chevronUp }
        , { name = "chevronDown", data = P2Icons.chevronDown }
        , { name = "doubleArrowsUp", data = P2Icons.doubleArrowsUp }
        , { name = "doubleArrowsDown", data = P2Icons.doubleArrowsDown }
        , { name = "navigationUp", data = P2Icons.navigationUp }
        , { name = "navigationDown", data = P2Icons.navigationDown }
        , { name = "calendar", data = P2Icons.calendar }
        , { name = "category", data = P2Icons.category }
        , { name = "changes", data = P2Icons.changes }
        , { name = "charts", data = P2Icons.charts }
        , { name = "chartsDisabled", data = P2Icons.chartsDisabled }
        , { name = "emptyChartsListCollection", data = P2Icons.emptyChartsListCollection }
        , { name = "checkboxFilled", data = P2Icons.checkboxFilled }
        , { name = "checkboxHalfFilled", data = P2Icons.checkboxHalfFilled }
        , { name = "checkboxUnfilled", data = P2Icons.checkboxUnfilled }
        , { name = "checkboxCrossed", data = P2Icons.checkboxCrossed }
        , { name = "chevronLeft", data = P2Icons.chevronLeft }
        , { name = "chevronRight", data = P2Icons.chevronRight }
        , { name = "columns", data = P2Icons.columns }
        , { name = "cross", data = P2Icons.cross }
        , { name = "crossLarge", data = P2Icons.crossLarge }
        , { name = "crossSmall", data = P2Icons.crossSmall }
        , { name = "crosstab", data = P2Icons.crosstab }
        , { name = "crosstabFTUE", data = P2Icons.crosstabFTUE }
        , { name = "crosstabSmall", data = P2Icons.crosstabSmall }
        , { name = "dataGrid", data = P2Icons.dataGrid }
        , { name = "dataMetrics", data = P2Icons.dataMetrics }
        , { name = "dataSurvey", data = P2Icons.dataSurvey }
        , { name = "datapoint", data = P2Icons.datapoint }
        , { name = "duplicate", data = P2Icons.duplicate }
        , { name = "edit", data = P2Icons.edit }
        , { name = "ellipsisVertical", data = P2Icons.ellipsisVertical }
        , { name = "ellipsisVerticalCircle", data = P2Icons.ellipsisVerticalCircle }
        , { name = "exclamationTriangle", data = P2Icons.exclamationTriangle }
        , { name = "export", data = P2Icons.export }
        , { name = "eye", data = P2Icons.eye }
        , { name = "eyeCrossed", data = P2Icons.eyeCrossed }
        , { name = "favourite", data = P2Icons.favourite }
        , { name = "favouriteFilled", data = P2Icons.favouriteFilled }
        , { name = "fileSearch", data = P2Icons.fileSearch }
        , { name = "folder", data = P2Icons.folder }
        , { name = "folderFilled", data = P2Icons.folderFilled }
        , { name = "folderCrossed", data = P2Icons.folderCrossed }
        , { name = "grid", data = P2Icons.grid }
        , { name = "group", data = P2Icons.group }
        , { name = "groupingPanelPlaceholderXB", data = P2Icons.groupingPanelPlaceholderXB }
        , { name = "groupingPanelPlaceholderDashboards", data = P2Icons.groupingPanelPlaceholderDashboards }
        , { name = "goToP2HomeBanner", data = P2Icons.goToP2HomeBanner }
        , { name = "goToP2AudiencesBanner", data = P2Icons.goToP2AudiencesBanner }
        , { name = "goToP2CrosstabBanner", data = P2Icons.goToP2CrosstabBanner }
        , { name = "goToP2ChartingBanner", data = P2Icons.goToP2ChartingBanner }
        , { name = "goToP2DashboardsBanner", data = P2Icons.goToP2DashboardsBanner }
        , { name = "goToP2InsightsBanner", data = P2Icons.goToP2InsightsBanner }
        , { name = "heatmap", data = P2Icons.heatmap }
        , { name = "info", data = P2Icons.info }
        , { name = "insights", data = P2Icons.insights }
        , { name = "list", data = P2Icons.list }
        , { name = "locations", data = P2Icons.locations }
        , { name = "move", data = P2Icons.move }
        , { name = "moveToFolder", data = P2Icons.moveToFolder }
        , { name = "moveFromFolder", data = P2Icons.moveFromFolder }
        , { name = "notes", data = P2Icons.notes }
        , { name = "plusSign", data = P2Icons.plusSign }
        , { name = "minusSign", data = P2Icons.minusSign }
        , { name = "radioButtonFilled", data = P2Icons.radioButtonFilled }
        , { name = "radioButtonUnfilled", data = P2Icons.radioButtonUnfilled }
        , { name = "radioButtonDisabled", data = P2Icons.radioButtonDisabled }
        , { name = "random", data = P2Icons.random }
        , { name = "redo", data = P2Icons.redo }
        , { name = "rename", data = P2Icons.rename }
        , { name = "refresh", data = P2Icons.refresh }
        , { name = "restore", data = P2Icons.restore }
        , { name = "rows", data = P2Icons.rows }
        , { name = "saveAsNew", data = P2Icons.saveAsNew }
        , { name = "search", data = P2Icons.search }
        , { name = "share", data = P2Icons.share }
        , { name = "shared", data = P2Icons.shared }
        , { name = "sharing", data = P2Icons.sharing }
        , { name = "migrated", data = P2Icons.migrated }
        , { name = "sort", data = P2Icons.sort }
        , { name = "sortAscending", data = P2Icons.sortAscending }
        , { name = "sortDescending", data = P2Icons.sortDescending }
        , { name = "datapointSort", data = P2Icons.datapointSort }
        , { name = "datapointSortAscending", data = P2Icons.datapointSortAscending }
        , { name = "datapointSortDescending", data = P2Icons.datapointSortDescending }
        , { name = "sync", data = P2Icons.sync }
        , { name = "textHeight", data = P2Icons.textHeight }
        , { name = "text", data = P2Icons.text }
        , { name = "tick", data = P2Icons.tick }
        , { name = "time", data = P2Icons.time }
        , { name = "trash", data = P2Icons.trash }
        , { name = "undo", data = P2Icons.undo }
        , { name = "ungroup", data = P2Icons.ungroup }
        , { name = "userFriends", data = P2Icons.userFriends }
        , { name = "verticalBarChart", data = P2Icons.verticalBarChart }
        , { name = "warning", data = P2Icons.warning }
        , { name = "warningTriangleIcon", data = P2Icons.warningTriangleIcon }
        , { name = "waves", data = P2Icons.waves }
        , { name = "segments", data = P2Icons.segments }
        , { name = "dashboards", data = P2Icons.dashboards }
        , { name = "globe", data = P2Icons.globe }
        , { name = "average", data = P2Icons.average }
        , { name = "help", data = P2Icons.help }
        , { name = "generalChange", data = P2Icons.generalChange }
        , { name = "textFormat", data = P2Icons.textFormat }
        , { name = "question", data = P2Icons.question }
        , { name = "tv", data = P2Icons.tv }
        , { name = "tvLarge", data = P2Icons.tvLarge }
        , { name = "lock", data = P2Icons.lock }
        , { name = "link", data = P2Icons.link }
        , { name = "circleArrows", data = P2Icons.circleArrows }
        , { name = "resizeArrows", data = P2Icons.resizeArrows }
        , { name = "emptyChartsSearchReuslts", data = P2Icons.emptyChartsSearchReuslts }
        , { name = "bold", data = P2Icons.bold }
        , { name = "underline", data = P2Icons.underline }
        , { name = "quote", data = P2Icons.quote }
        , { name = "bulletList", data = P2Icons.bulletList }
        , { name = "alignLeft", data = P2Icons.alignLeft }
        , { name = "alignRight", data = P2Icons.alignRight }
        , { name = "alignCenter", data = P2Icons.alignCenter }
        ]
    , chartTypesIcons =
        [ { name = "horizontalBarChart", data = ChartTypes.horizontalBarChart }
        , { name = "verticalBarChart", data = ChartTypes.verticalBarChart }
        , { name = "diverginBarChart", data = ChartTypes.diverginBarChart }
        , { name = "pieRadarChart", data = ChartTypes.pieRadarChart }
        , { name = "donutChart", data = ChartTypes.donutChart }
        , { name = "pieChart", data = ChartTypes.pieChart }
        , { name = "dataTable", data = ChartTypes.dataTable }
        , { name = "statCardWhite", data = ChartTypes.statCardWhite }
        , { name = "statCardColor", data = ChartTypes.statCardColor }
        , { name = "lineChart", data = ChartTypes.lineChart }
        , { name = "radialChart", data = ChartTypes.radialChart }
        , { name = "radarChart", data = ChartTypes.radarChart }
        ]
    }


update : a -> Model -> Model
update _ model =
    model


view : Model -> Html msg
view model =
    let
        viewIcon maybeSize icon =
            let
                iconAttrs =
                    case maybeSize of
                        Just size ->
                            [ XB2.Share.Icons.width size ]

                        Nothing ->
                            []
            in
            Html.div
                [ Attrs.style "display" "inline-block"
                , Attrs.style "border" "1px solid #909090"
                , Attrs.style "margin" "12px 4px"
                , Attrs.style "padding" "4px"
                , Attrs.style "font-size" "12px"
                , Attrs.style "min-width" "125px"
                , Attrs.style "text-align" "center"
                , Attrs.style "background-color" "#ddd"
                ]
                [ Html.div
                    [ Attrs.style "margin-top" "12px"
                    , Attrs.style "margin-bottom" "12px"
                    , Attrs.style "display" "flex"
                    , Attrs.style "align-items" "center"
                    , Attrs.style "justify-content" "center"
                    ]
                    [ Html.div
                        [ Attrs.style "background-color" "white"
                        , Attrs.style "flex-shrink" "1"
                        , Attrs.style "font-size" "0"
                        ]
                        [ XB2.Share.Icons.icon iconAttrs icon.data ]
                    ]
                , Html.span [ Attrs.class "name" ] [ Html.text icon.name ]
                ]
    in
    Html.div []
        [ Html.h1 [] [ Html.text "Pro-next Icons Overview" ]
        , Html.h2 [] [ Html.text "Icons.Gwi" ]
        , Html.div [] <| List.map (viewIcon <| Just 16) model.gwiIcons
        , Html.h2 [] [ Html.text "Icons.FontAwesome" ]
        , Html.div [] <| List.map (viewIcon <| Just 16) model.faIcons
        , Html.h2 [] [ Html.text "Platform 2 Icons" ]
        , Html.div [] <| List.map (viewIcon Nothing) model.p2Icons
        , Html.h2 [] [ Html.text "Platform 2 Chart types Icons" ]
        , Html.div [] <| List.map (viewIcon Nothing) model.chartTypesIcons
        ]


main : Platform.Program () Model msg
main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
