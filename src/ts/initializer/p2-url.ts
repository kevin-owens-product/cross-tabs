import { getEnvironment } from "./helpers";

export default (ENV) => {
    const environment = getEnvironment(ENV);

    switch (environment) {
        case "development":
        case "testing":
            ENV.platform2Url = "https://app-testing.globalwebindex.com";
            break;
        case "staging":
            ENV.platform2Url = `https://app-staging.globalwebindex.com`;
            break;
        default:
            if (window.location.host === "legacy.globalwebindex.com") {
                ENV.platform2Url = "https://app.globalwebindex.com";
            } else if (window.location.host === "legacy.gwi.com") {
                ENV.platform2Url = "https://app.gwi.com";
            } else {
                ENV.platform2Url = window.location.origin;
            }
    }

    return ENV;
};
