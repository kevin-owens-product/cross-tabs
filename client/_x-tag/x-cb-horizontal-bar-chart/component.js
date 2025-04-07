var d3 = require("d3");
var Chart = require("d3-charts").getChartBuilderChart("advanced_horizontal_bar_chart");
var config = require("../bar-chart-config")(Chart);

xtag.register("x-cb-horizontal-bar-chart", config);
