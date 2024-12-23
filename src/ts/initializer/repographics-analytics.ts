/*
The window.location will look similar to this:

  https://app.globalwebindex.com/chart-builder/questions/r4154new
     ?utm_campaign=Report Links
     &utm_source=In the past month, which of the following things have you done on the internet via any device%3F
     &utm_term=Modern_Banker_Report

We will use `utm_campaign` for checking if we should send the analytics event at all,
and `utm_term` will be a part of the event payload. `utm_source` is unused.
*/

const eventName = "Product Link Clicked";

const shouldSendEvent = (params) => {
    return params.has("utm_term");
};

const getProperties = (params) => {
    return {
        utm_campaign: params.get("utm_campaign"),
        utm_source: params.get("utm_source"),
        utm_term: params.get("utm_term"),
        utm_content: params.get("utm_content"),
        utm_medium: params.get("utm_medium"),
        url: window.location.toString(),
        question_code: getQuestionCode(window.location.pathname)
    };
};

const getQuestionCode = (pathname) => {
    const substring = "/chart-builder/questions/";
    // don't forget that feature branches will make this substring not a prefix.

    if (!pathname.includes(substring)) {
        return null;
    }
    return pathname.slice(pathname.indexOf(substring) + substring.length);
};

export default (ENV) => {
    return new Promise(function (resolve) {
        const params = new URLSearchParams(window.location.search);
        if (shouldSendEvent(params)) {
            // @ts-ignore
            window.analytics.track(eventName, getProperties(params));
        }
        resolve(ENV);
    });
};
