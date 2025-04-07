import { getEnvironment } from "./helpers";

export default (ENV) => {
    const environment = getEnvironment(ENV);
    switch (environment) {
        case "production":
            ENV.keys = {
                intercom: "f0q8xhcx"
            };
            break;
        case "testing":
        case "staging":
        case "alpha":
        case "development":
            ENV.keys = {
                intercom: "zj1fxfxa"
            };
            break;
        default:
            throw `Unknown environment: "${environment}"!`;
    }

    return ENV;
};
