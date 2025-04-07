import { navigateTo } from "./helpers";

export default (app) => {
    // navigateTo, setLocationFromXB20
    app.ports.navigateToXB2.subscribe(async (route) => {
        navigateTo(route, app.ports.setLocationFromXB20.send);
    });

    // dummySetRouteForXB20, routeChanged
    app.ports.dummySetRouteForXB20.subscribe(async (value) => {
        if (!value.match(window.location.origin)) {
            value = window.location.origin + value;
        }
        app.ports.routeChangedXB2.send(value);
    });
};
