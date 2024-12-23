import * as helpers from "./helpers";
import Cookies from "js-cookie";

const MISSING_REFRESH_TOKEN_ERROR = "MISSING_REFRESH_TOKEN_ERROR";

const parseJWT = (token) => {
    var base64Url = token.split(".")[1];
    var base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    var jsonPayload = decodeURIComponent(
        atob(base64)
            .split("")
            .map(function (c) {
                return "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2);
            })
            .join("")
    );

    return JSON.parse(jsonPayload);
};

const getExpirationFromToken = (token) => {
    const parsed = parseJWT(token);
    return new Date(parsed.exp * 1000);
};

const setCookie = (ENV, name, value) => {
    let options = {};
    if (helpers.getEnvironment(ENV) === "development") {
        options = {
            sameSite: "strict",
            secure: false,
            expires: 1
        };
    } else {
        options = { domain: helpers.domain, expires: 1 };
    }
    Cookies.set(name, value, options);
};

const refreshToken = (app, ENV) => {
    const environment = helpers.getEnvironment(ENV);
    const currentRefreshToken = Cookies.get(helpers.refreshTokenCookieName(environment));

    if (!currentRefreshToken) {
        return new Promise(function (resolve) {
            throw new Error(MISSING_REFRESH_TOKEN_ERROR);
        });
    }
    return fetch(helpers.host(environment) + "/v1/users-next/refresh_tokens", {
        method: "POST",
        headers: {
            Authorization: `Basic ${currentRefreshToken}`
        }
    })
        .then(function (response) {
            if (response.ok) {
                return response.json();
            } else {
                return { error: response.json(), status: response.status };
            }
        })
        .then(function (decoded) {
            if (decoded.access_token) {
                setCookie(
                    ENV,
                    helpers.refreshTokenCookieName(environment),
                    decoded.refresh_token
                );
                setCookie(
                    ENV,
                    helpers.authTokenCookieName(environment),
                    decoded.access_token
                );
                app.ports.setToken.send(decoded.access_token);
            }
            return decoded;
        });
};

const getToken = (ENV) => {
    return Cookies.get(helpers.authTokenCookieName(helpers.getEnvironment(ENV)));
};

export const silentTokenRefresh = (app, ENV) => {
    const checkExpirationFrequency = 10 * 1000;
    let tokenExpireAt = new Date();
    const token = getToken(ENV);

    if (token) {
        tokenExpireAt = getExpirationFromToken(token);
    }

    const checkExpiration = () => {
        let dateToCheck = new Date();
        //Expires in next 10 minutes?
        dateToCheck.setMinutes(dateToCheck.getMinutes() + 10);

        if (dateToCheck.getTime() >= tokenExpireAt.getTime()) {
            refreshToken(app, ENV).then(
                (data) => {
                    // @ts-ignore
                    if (data.access_token) {
                        tokenExpireAt = getExpirationFromToken(
                            // @ts-ignore
                            data.access_token
                        );
                        setTimeout(checkExpiration, checkExpirationFrequency);
                    }
                },
                (error) => {
                    //we can wait for next attempt, but if refresh token is missing we can't do much
                    if (error.error !== MISSING_REFRESH_TOKEN_ERROR) {
                        setTimeout(checkExpiration, checkExpirationFrequency);
                    }
                }
            );
        } else {
            setTimeout(checkExpiration, checkExpirationFrequency);
        }
    };

    checkExpiration();
};
