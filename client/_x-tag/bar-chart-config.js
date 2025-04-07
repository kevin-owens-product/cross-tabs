var ResizeObserver = require("resize-observer-polyfill").default;

const { allMetrics, allDatapoints } = require("./chart-metrics.js");

var ro = new ResizeObserver(function (entries, observer) {
    for (var k in entries) {
        if (entries.hasOwnProperty(k)) {
            var target = entries[k].target;
            if (target.redraw) {
                target.redraw.call(target);
            }
        }
    }
});

module.exports = createConfig;

function createConfig(chart) {
    return {
        content: "<svg></svg>",
        lifecycle: {
            inserted: function () {
                var metric = this.getAttribute("chart-metric");
                this.chart = chart()
                    .allDatapoints(allDatapoints)
                    .activeDatapoints(
                        this.getActiveDatapoints(
                            JSON.parse(this.getAttribute("chart-shown-metrics"))
                        )
                    )
                    .metric(metric)
                    .axisLabel(this.getMetricName(metric))
                    .data(JSON.parse(this.getAttribute("chart-data")));

                this.redraw();

                ro.observe(this);
            },
            removed: function () {
                ro.unobserve(this);
                this.chart.remove();
            },
            attributeChanged: function (attrName, _, newValue) {
                switch (attrName) {
                    case "chart-data":
                        if (!this.chart) {
                            return;
                        }
                        this.chart.data(JSON.parse(newValue));
                        this.redraw();
                        break;
                    case "chart-metric":
                        if (!this.chart) {
                            return;
                        }
                        this.chart
                            .metric(newValue)
                            .axisLabel(this.getMetricName(newValue));
                        this.redraw();
                        break;
                    case "chart-shown-metrics":
                        if (!this.chart) {
                            return;
                        }
                        this.chart.activeDatapoints(
                            this.getActiveDatapoints(JSON.parse(newValue))
                        );
                        this.redraw();
                        break;
                }
            }
        },
        methods: {
            redraw: function () {
                d3.select(this).select("svg").call(this.chart);
            },
            getActiveDatapoints: function (shownMetrics) {
                return allMetrics.filter(function (metric) {
                    return shownMetrics.indexOf(metric.id) !== -1;
                });
            },
            getMetricName: function (id) {
                for (var i in allMetrics) {
                    var metric = allMetrics[i];
                    if (metric.id === id) {
                        return metric.name;
                    }
                }
                return;
            }
        }
    };
}
