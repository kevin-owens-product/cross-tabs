import { handlers } from "./helpers";

const track = (app) => (arg) => {
    const eventName = arg[0];
    const properties = arg[1];

    // window.analytics is defined by _initializer/analytics.js
    // @ts-ignore
    window.analytics.track(eventName, properties);
};

const batch = (app) => (events) => {
    // window.analytics is defined by _initializer/analytics.js
    // @ts-ignore
    window.analytics.batch(events);
};

export default handlers({
    track,
    batch
});
