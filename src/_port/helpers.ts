const subscriptions = {};

const capitalize = (str: string) =>
    str ? str.charAt(0).toLocaleUpperCase() + str.slice(1) : str;

const complainAboutMissingPort = (portName) =>
    console.error(
        `Port '${portName}' isn't exposed by the Elm app. Perhaps it was dead code eliminated? You should most likely remove the subscribe${capitalize(
            portName
        )} and unsubscribe${capitalize(portName)} calls from the index.js file.`
    );

export const subscribe = (portName, fn) => (app) => {
    if (portName in app.ports) {
        subscriptions[portName] = fn(app);
        app.ports[portName].subscribe(subscriptions[portName]);
    } else {
        complainAboutMissingPort(portName);
    }
};
export const unsubscribe = (portName, fn) => (app) => {
    if (portName in app.ports) {
        app.ports[portName].unsubscribe(subscriptions[portName]);
        delete subscriptions[portName];
    } else {
        complainAboutMissingPort(portName);
    }
};
export const handlers = (portHandlers) => {
    /* Expects to be called like
     *
     *   handlers({
     *     portName1: (app) => (portArgs) => {...},
     *     portName2: (app) => (portArgs) => {...},
     *   });
     *
     * (The app argument is there if you need to send messages through JS->Elm ports.)
     *
     * Creates object with fns like:
     *
     *   {
     *     subscribePortName1: (app) => {...},
     *     subscribePortName2: (app) => {...},
     *     unsubscribePortName1: (app) => {...},
     *     unsubscribePortName2: (app) => {...},
     *   }
     *
     * which you can then run where you deal with the Elm `app` and ports.
     */

    return Object.keys(portHandlers).reduce((acc, portName) => {
        const capitalizedPortName = capitalize(portName);
        const handler = portHandlers[portName];
        acc[`subscribe${capitalizedPortName}`] = subscribe(portName, handler);
        acc[`unsubscribe${capitalizedPortName}`] = unsubscribe(portName, handler);
        return acc;
    }, {});
};
