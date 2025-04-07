const newAccessTokenHandler = (app) => {
    const eventListener = (event) => {
        if (event && event.detail && event.detail.token) {
            app.ports.setNewAccessToken.send(event.detail.token);
        }
    };
    return {
        init: () => {
            window.addEventListener("accessTokenChanged", eventListener);
        },

        clear: () => {
            window.removeEventListener("accessTokenChanged", eventListener);
        }
    };
};

export default newAccessTokenHandler;
