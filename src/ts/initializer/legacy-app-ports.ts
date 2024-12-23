export default (app) => {
    // @ts-ignore
    window.PlatformElmPorts = {
        send(name, params) {
            app.ports[name].send(params);
        },
        subscribe(name, callback) {
            try {
                app.ports[name].subscribe(callback);
            } catch (e) {
                console.error("Unable to subscribe to port", name, "\n", e);
            }
        },
        unsubscribe(name, callback) {
            try {
                app.ports[name].unsubscribe(callback);
            } catch (e) {
                console.error("Unable to unsubscribe from port", name, "\n", e);
            }
        }
    };

    return app;
};
