var d3 = require("d3");
var Chart = require("d3-charts").getChartBuilderChart("advanced_vertical_bar_chart");
var config = require("../bar-chart-config")(Chart);

xtag.register("x-cb-vertical-bar-chart", config);
