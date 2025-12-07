/**
   This files define interface specific to single-spa framework
   which make crosstab builder pluggable component of platform2-lib repository.

   This entry is meant to be compiled to AMD or Systemjs module
   with public interface containing:

   * bootstrap
   * mount
   * unmount
*/
import { ximport } from "@globalwebindex/platform2-lib";
import React from "react";
import { createRoot, Root } from "react-dom/client";

import keysInit from "../../_initializer/keys";
import p2UrlInit from "../../_initializer/p2-url";
import analyticsInit from "../../_initializer/analytics";

import analyticsPorts from "../../_port/analytics";
import windowPorts from "../../_port/window";
import { p2EnvPlatform } from "../../_helpers/platform";
import beforeUnloadConfirmPorts from "../../_port/beforeunload-confirm";
import scrollPorts from "../../_port/scroll";
import selectTextInFieldPorts from "../../_port/selectTextInField";
import intercomPorts from "../../_port/intercom";
import accessTokenHandler from "../../_port/accessToken";
import clipboardPorts from "../../_port/clipboard";
import * as Sentry from "@sentry/browser";

import "regenerator-runtime/runtime";

import { App } from "./src/App";
import { Flags } from "./src/types";

require("@webcomponents/webcomponentsjs/webcomponents-bundle.js");
require("@webcomponents/webcomponentsjs/custom-elements-es5-adapter.js");
// styles
require("./main.scss");

// New Web Components
require("../../webcomponents");
require("../../custom-elements/x-cooltip/component.ts");
require("../../custom-elements/x-cooltip/style.scss");
require("../../custom-elements/x-simplebar/component.ts");
require("../../custom-elements/x-simplebar/style.scss");
require("../../custom-elements/x-resize-observer/component.ts");

// Sentry
// @ts-ignore
if (process.env.TARGET_ENV !== "development" && !Boolean(window.Sentry)) {
    Sentry.init({
        dsn: "https://8742bda92d694e6f8296c8bc514e98b7@o356571.ingest.us.sentry.io/4504486294978565",
        integrations: [
            Sentry.browserTracingIntegration(),
            Sentry.replayIntegration({
                maskAllText: false,
                blockAllMedia: false
            }),
            Sentry.thirdPartyErrorFilterIntegration({
                filterKeys: ["crosstabs"],
                behaviour: "drop-error-if-contains-third-party-frames"
            })
        ],
        tracesSampleRate: 0,
        tracePropagationTargets: ["localhost", /^\//],
        environment: process.env.TARGET_ENV,

        replaysSessionSampleRate: 0,
        replaysOnErrorSampleRate: 1.0
    });
}

// CONFIG DEFINITIONS
const styleHref = "/assets/crosstabs.css";

interface AppState {
    checkBeforeLeave: boolean;
    ignoreNextRouteChangeCounter: number;
    lastUrl: string;
    currentUrl: string;
    domEl?: HTMLElement;
    reactRoot?: Root;
    navigateTo?: (str: string) => void;
    checkBeforeLeaveSubscription?: (edited: boolean) => void;
    routeChanged?: () => void;
    beforeRouting?: (evt: CustomEvent) => void;
    interruptRoutingStatusHandler?: (state: boolean) => void;
}

const state: AppState = {
    checkBeforeLeave: false,
    ignoreNextRouteChangeCounter: 0,
    lastUrl: "",
    currentUrl: ""
};

function getDomElement(domId?: string): HTMLElement {
    const htmlId = domId !== undefined ? domId : "container";

    let domElement = document.getElementById(htmlId);
    if (!domElement) {
        domElement = document.createElement("div");
        domElement.id = htmlId;
        document.body.appendChild(domElement);
    }

    return domElement;
}

function initENV(props: any): Flags {
    const ENV = JSON.parse(JSON.stringify(props));
    ENV.platform = ENV.platform || p2EnvPlatform;
    keysInit(ENV);
    p2UrlInit(ENV);
    
    // Convert to Flags type
    const flags: Flags = {
        token: ENV.token,
        user: ENV.user,
        env: ENV.env,
        feature: ENV.feature || undefined,
        pathPrefix: ENV.pathPrefix || undefined,
        can: ENV.can || { useCrosstabs: true },
        helpMode: ENV.helpMode || false,
        supportChatVisible: ENV.supportChatVisible || false,
        revision: ENV.revision || undefined,
        referrer: ENV.referrer === "Platform2Referrer" ? "Platform2Referrer" : "OtherReferrer",
        platform2Url: ENV.platform2Url || ""
    };
    
    return flags;
}

// SINGLE-SPA INTERFACE LOGIC

/** Bootstrap function needs to handle provision of all resources
as well as take core of main intialization of the app.
*/
export function bootstrap(props: { domId?: string }) {
    return ximport(styleHref).then(() => {
        const domElement = getDomElement(props.domId);
        domElement.innerHTML = "";

        // wrapper is a dom node we use to control the lifecycle
        const wrapper = document.createElement("div");
        wrapper.className = "xb2-wrapper";
        domElement.appendChild(wrapper);

        state.domEl = wrapper;
    });
}

/** Mount application should handle render of the DOM of the application
and hook to events / subscriptions which are not necessary un unmounted state.
*/
export function mount(props: { domId?: string }) {
    const { domEl } = state;
    if (!domEl) {
        throw new Error("App not bootstrapped");
    }

    const flags = initENV(props);
    analyticsInit(props);

    // Create React root and render app
    const reactRoot = createRoot(domEl);
    state.reactRoot = reactRoot;

    let isMounted = false;

    const handleMounted = () => {
        isMounted = true;
    };

    const handleUnmounted = () => {
        isMounted = false;
    };

    state.navigateTo = async function (str: string) {
        // @ts-ignore
        if (window.singleSpaNavigate) {
            // @ts-ignore
            window.singleSpaNavigate(str);
        }
    };

    state.checkBeforeLeaveSubscription = async function (edited: boolean) {
        state.checkBeforeLeave = edited;
    };

    state.routeChanged = function () {
        if (state.lastUrl !== window.location.href) {
            if (state.ignoreNextRouteChangeCounter <= 0) {
                // Route change handled by React Router
            } else {
                state.ignoreNextRouteChangeCounter--;
            }
        }
        state.lastUrl = window.location.href;
    };

    state.beforeRouting = (evt: CustomEvent) => {
        if (
            state.checkBeforeLeave &&
            evt.detail.newUrl.indexOf("/crosstabs") === -1
        ) {
            evt.detail.cancelNavigation();
            /**
             * This whole SPA whatever kernel thing is wird as ***, you have `before-routing-event`
             * but even if it's before route change is already done and if you cancel it, it just simply
             * jump back to previous route so there are two route changes triggered even if nothing should happen.
             * And yes, I tried preventDefault and stopPropagation usual JS magic, but no luck here.
             * So here comes this hack. It's terribly stupid, but because SPA is 4rd party lib,
             * I did not see other reasonable option.
             * */
            state.ignoreNextRouteChangeCounter = 2;
            // TODO: Implement route interruption check for React
        }
        /** Another great behaviour of single-spa. If there is routing-event, but for different app
         *  (like going from Dashboards to reports/insights..) it will not fire `single-spa:routing-event`
         * for this APP. But `single-spa:before-routing-event` is still fired. What a intuitive behaviour.
         * So we need to set lastUrl here in case of different URL
         *
         * */
        if (evt.detail.newUrl.indexOf("/crosstabs") === -1) {
            state.lastUrl = window.location.href;
        }
    };

    // Hook routing
    window.addEventListener("single-spa:routing-event", state.routeChanged);
    window.addEventListener("single-spa:before-routing-event", state.beforeRouting);

    // Book a demo analytics listening
    window.addEventListener("CrosstabBuilder-bookDemoEvent", () => {
        // TODO: Implement analytics tracking
    });

    // Splash screen events
    window.addEventListener("CrosstabBuilder-talkToAnExpertEvent", () => {
        // TODO: Implement analytics tracking
    });
    window.addEventListener("CrosstabBuilder-upgradeEvent", () => {
        // TODO: Implement analytics tracking
    });

    // Render React app
    reactRoot.render(
        React.createElement(App, {
            flags,
            isAppMounted: true,
            onMounted: handleMounted,
            onUnmounted: handleUnmounted,
        })
    );

    // Resolve immediately since React handles mounting asynchronously
    return Promise.resolve();
}

/** Unmount should take care of destruction of DOM
including event handlers / subscriptions that are not needed in unmounted state.
*/
export function unmount(props: { domId?: string }) {
    return new Promise<void>((resolve) => {
        // Unmount React app
        if (state.reactRoot) {
            state.reactRoot.unmount();
            state.reactRoot = undefined;
        }

        // Remove event listeners
        if (state.routeChanged) {
            window.removeEventListener("single-spa:routing-event", state.routeChanged);
        }
        if (state.beforeRouting) {
            window.removeEventListener("single-spa:before-routing-event", state.beforeRouting);
        }

        // Clean up state
        state.lastUrl = "";
        state.ignoreNextRouteChangeCounter = 0;
        state.checkBeforeLeave = false;
        state.navigateTo = undefined;
        state.checkBeforeLeaveSubscription = undefined;
        state.routeChanged = undefined;
        state.beforeRouting = undefined;
        state.interruptRoutingStatusHandler = undefined;

        // DOM operation
        const domElement = getDomElement(props.domId);
        domElement.innerHTML = "";

        resolve();
    });
}
