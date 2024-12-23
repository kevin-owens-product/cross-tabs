import { navigateTo } from "./helpers";

export default (app) => {
    // navigateTo, setLocationFromDashboards20
    app.ports.navigateToD2.subscribe(async (route) => {
        navigateTo(route, app.ports.setLocationFromDashboards20.send);
    });

    app.ports.setSharedStateForChartBuilderAndNavigateTo.subscribe(
        async ([sharedState, route]) => {
            navigateTo(route, app.ports.setLocationFromDashboards20.send);
        }
    );

    // dummySetRouteForDashboards20, routeChangedD2
    app.ports.dummySetRouteForDashboards20.subscribe(async (value) => {
        if (!value.match(window.location.origin)) {
            value = window.location.origin + value;
        }
        app.ports.routeChangedD2.send(value);
    });

    // setTextareaCursorPosition
    app.ports.setTextareaCursorPosition.subscribe(async ([id, value]) => {
        const element = document.getElementById(id);
        if (element) {
            // @ts-ignore
            await element.setSelectionRange(value, value);
        }
    });
};
