import { handlers } from "./helpers";

const subscribedScrolls = {};

const scrollSusbcriptionHandler = (elementId, app) => {
    function Handler(elementId) {
        let timeout;
        let start = null;
        let scrollStarted = false;
        let lastKnownScroll = { scrollTop: 0, scrollLeft: 0 };
        let debounce = { start: null, fn: false };

        function checkScrollPosition(timestamp) {
            if (!start) start = timestamp;

            if (timestamp - start > 100) {
                start = timestamp;

                let element = document.getElementById(elementId);
                if (typeof element !== "undefined" && element) {
                    if (
                        lastKnownScroll.scrollTop !== element.scrollTop ||
                        lastKnownScroll.scrollLeft !== element.scrollLeft
                    ) {
                        if (scrollStarted === false) {
                            app.ports.onScrollStart_ &&
                                app.ports.onScrollStart_.send(elementId);
                            scrollStarted = true;
                        }

                        debounce.start = timestamp;
                        // @ts-ignore
                        debounce.fn = () => {
                            app.ports.onScrollEnd_ &&
                                app.ports.onScrollEnd_.send([
                                    elementId,
                                    // @ts-ignore
                                    parseInt(element.scrollTop),
                                    // @ts-ignore
                                    parseInt(element.scrollLeft)
                                ]);
                            scrollStarted = false;
                        };
                    }
                    lastKnownScroll.scrollTop = element.scrollTop;
                    lastKnownScroll.scrollLeft = element.scrollLeft;

                    if (debounce.fn !== false && timestamp - debounce.start > 100) {
                        // @ts-ignore
                        debounce.fn();
                        debounce.fn = false;
                    }
                }
            }
            window.requestAnimationFrame(checkScrollPosition);
        }

        window.requestAnimationFrame(checkScrollPosition);
    }

    subscribedScrolls[elementId] = new Handler(elementId);
};

// needs `onScrollEnd_ : (... -> msg) -> Sub msg` and `onScrollStart_ : (.. -> msg) -> Sub msg`
const debouncedScrollEvent = (app) => (elementId) => {
    if (typeof subscribedScrolls[elementId] === "undefined") {
        scrollSusbcriptionHandler(elementId, app);
    }
};

export default handlers({
    debouncedScrollEvent
});
