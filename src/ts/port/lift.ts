export default function Port(app) {
    return {
        port: function (port) {
            port(app);
            return Port(app);
        },
        app: function () {
            return app;
        }
    };
}
