import { navigateTo } from "./helpers";

export default (app) => {
    // navigateTo, setLocationFromTV20
    app.ports.navigateToTV2.subscribe(async (route) => {
        navigateTo(route, app.ports.setLocationFromTV20.send);
    });

    // dummySetRouteForTV20, routeChanged
    app.ports.dummySetRouteForTV20.subscribe(async (value) => {
        if (!value.match(window.location.origin)) {
            value = window.location.origin + value;
        }
        app.ports.routeChangedTV2.send(value);
    });
};
