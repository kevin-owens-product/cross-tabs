import * as helpers from "./helpers";
import Cookies from "js-cookie";

const redirectToLogin = (ENV, code) => {
    const host = helpers.susiHost(helpers.getEnvironment(ENV));
    window.location.href = `${host}/?return_to=${encodeURIComponent(
        location.href
    )}&code=${code}`;
};

const redirectToRMP = (ENV, token) => {
    const host = helpers.rmpPanelHost(helpers.getEnvironment(ENV));
    window.location.href = `${host}/?access_token=${token}`;
};

const getToken = (ENV) => {
    const params = new URLSearchParams(window.location.search);
    const urlToken = params.get(helpers.authTokenUrlParam);
    if (urlToken) {
        helpers.removeUrlParam(helpers.authTokenUrlParam);
        return { token: urlToken, tokenWasFromUrl: true };
    }

    const environment = helpers.getEnvironment(ENV);

    const masqueradingToken = Cookies.get(
        helpers.authMasqueradingTokenCookieName(environment)
    );
    if (masqueradingToken) {
        return { token: masqueradingToken, tokenWasFromUrl: false };
    }

    const normalToken = Cookies.get(helpers.authTokenCookieName(environment));
    if (normalToken) {
        return { token: normalToken, tokenWasFromUrl: false };
    }

    // we have no token at all!
    redirectToLogin(ENV, 0);
    return { token: "", tokenWasFromUrl: false };
};

const getRefreshUrlToken = () => {
    const params = new URLSearchParams(window.location.search);
    const urlToken = params.get(helpers.refreshTokenUrlParam);
    if (urlToken) {
        helpers.removeUrlParam(helpers.refreshTokenUrlParam);
    }
    return urlToken;
};

const isLocalDevelopment = (ENV) => {
    const environment = helpers.getEnvironment(ENV);
    return (
        environment === "development" || window.location.hostname.includes("localhost")
    );
};

export default async (ENV) => {
    const refreshToken = getRefreshUrlToken();
    const { token, tokenWasFromUrl } = getToken(ENV);
    const environment = helpers.getEnvironment(ENV);

    if (refreshToken && isLocalDevelopment(ENV)) {
        Cookies.set(helpers.refreshTokenCookieName(environment), refreshToken, {
            sameSite: "strict",
            secure: false,
            expires: 1
        });
    }

    // LOAD USER INFO
    const userResponse = await fetch(helpers.host(environment) + "/api/current_user", {
        method: "GET",
        headers: { Authorization: `Bearer ${token}` }
    });
    if (!userResponse.ok) {
        // token was invalid / expired / ...
        redirectToLogin(ENV, userResponse.status);
    }
    const user = (await userResponse.json()).data;

    // LOAD ORGANISATION INFO
    const organisationResponse = await fetch(
        helpers.host(environment) + `/v1/organisations/users/${user.id}/organisation`,
        {
            method: "GET",
            headers: { Authorization: `Bearer ${token}` }
        }
    );
    const organisation = (await organisationResponse.json()).organisation;

    if (user.customer_features.includes("RMP Panel Dashboard (Panel users only)")) {
        redirectToRMP(ENV, token);
    }

    if (ENV.is_headless_test) {
        // disable the "sticky P2" dialog for tests
        user.last_platform_used = "platform1";
    }
    if (tokenWasFromUrl && isLocalDevelopment(ENV)) {
        // On localhost:3000, this is the only way to login.
        // We need to set a cookie ourselves (SUSI can't do that for us).
        Cookies.set(helpers.authTokenCookieName(environment), token, {
            sameSite: "strict",
            secure: false,
            expires: 1
        });
    }

    /* The app expects the organisation info living inside the user info, for
     * legacy reasons. The backends have split though so our frontend asks both to
     * keep things as before.
     */
    ENV.user = {
        ...user,
        organisation_id: organisation.id,
        organisation_name: organisation.name
    };
    ENV.token = token;

    // @ts-ignore
    if (!!window.Sentry) {
        // @ts-ignore
        Sentry.setUser({ id: user.id });
        // @ts-ignore
        Sentry.configureScope((scope) => {
            scope.setTag("plan", user.plan_handle);
            scope.setExtra("customer_features", user.customer_features);
        });
    }

    return ENV;
};
