import Intercom from "@globalwebindex/platform2-lib/dist/intercom";

export default (ENV) => {
    if (!ENV.keys.intercom || !ENV.user || ENV.user.plan_handle == "student") {
        return ENV;
    }

    Intercom;

    return ENV;
};
