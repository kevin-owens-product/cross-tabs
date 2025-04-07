export const allMetrics = [
    {
        id: "percentage",
        name: "Audience %",
        selected: true,
        tip: function (attrs) {
            return `Audience % shows how many people in your audience match with the data point. <br><br>
                  For example, across the market(s) and wave(s) of research you have applied, ${attrs.percentage}% of the ${attrs.audience_name} audience match with the ${attrs.datapoint_name} data point.<br><br>
                  Please note: if you have not applied any markets or waves of research, the Audience % will show a global average across all possible markets and research waves.`;
        }
    },
    {
        id: "horizontal_percentage",
        name: "Data point %",
        selected: false,
        tip: function (attrs) {
            return `Data point % shows the contribution that your selected audience makes to the total audience that matches with a data point.<br><br>
                  For example, across the market(s) and wave(s) of research you have applied, the ${attrs.audience_name} audience accounts for ${attrs.horizontal_percentage}% of the people who match with the ${attrs.datapoint_name} data point.<br><br>
                  Please note: a data point score of 100% means that everyone who matches with that data point is included within the audience that you have applied. Please also be aware that if you have not applied any markets or waves of research, the Data point % will be a global average across all possible markets and research waves.`;
        }
    },
    {
        id: "weighted_universe_count",
        name: "Universe",
        selected: false,
        tip: function (attrs) {
            return `The Universe shows GlobalWebIndex’s estimate of how many real-world people are represented by the Audience %. <br><br>
                  For example, across the market(s) and wave(s) of research you have applied, there are an estimated ${attrs.weighted_universe_count} real-world people in the ${attrs.audience_name} audience who match the ${attrs.datapoint_name} data point.<br><br>
                  Please note: if you have not applied any markets or waves of research, the Universe will show a global average across all possible markets and research waves.`;
        }
    },
    {
        id: "index",
        name: "Index",
        selected: false,
        tip: function (attrs) {
            return `Index compares your Audience to the base audience you have applied, showing how much more or less likely they are to match with a data point.<br><br>
                  For example, across the market(s) and wave(s) of research you have applied, an index figure above 100 means that your Audience is more likely than the base audience to match with that datapoint. An index figure below 100 means your Audience is less likely than the base audience to match with that data point.<br><br>
                  The numerical distance from 100 shows the percentage difference compared to the base audience. For example, an index figure of 110.0 means that your Audience is 10% more likely than the base audience to match with a data point.<br><br>
                  Please note: if you have not applied any markets or waves of research, the Index will show the average index score of your audience across all possible markets and research waves. If you have not applied a base audience, the index will compare your audience to the average internet user.`;
        }
    },
    {
        id: "responses_count",
        name: "Responses",
        selected: false,
        tip: function (attrs) {
            return `Responses shows the number of people from our panel who match with the data point.<br><br>
                  For example, across the market(s) and wave(s) of research you have applied, ${attrs.responses_count} from the ${attrs.audience_name} audience match with the ${attrs.datapoint_name} data point.<br><br>
                  Please note: if you have not applied any markets or waves of research, the Responses will show the aggregated total across all possible markets and research waves.`;
        }
    }
];

export const allDatapoints = allMetrics.map(function (metric) {
    return metric.id;
});
