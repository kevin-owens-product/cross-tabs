var GeminiScrollbar = require("gemini-scrollbar");
var debounce = require("debounce");

xtag.register("x-gemini-scrollbar", {
    lifecycle: {
        inserted() {
            const scrollbars = new GeminiScrollbar({
                element: this,
                autoshow: this.getAttribute("autoshow") === "true",
                forceGemini: true, // true since ATC-1033. If needed, we can make
                // it conditional similarly to `autoshow` above.
                createElements: false // required!
            });

            window.requestAnimationFrame(() => {
                this._gemini = scrollbars.create();

                const observerConfig = {
                    attributes: true,
                    characterData: true,
                    childList: true,
                    subtree: true
                };

                const observerCallback = debounce(() => {
                    window.requestAnimationFrame(() => {
                        if (!this._gemini) {
                            return;
                        }
                        this._gemini.update();
                    });
                }, 100);
                this._observer = new MutationObserver(observerCallback);
                this._observer.observe(this, observerConfig);
            });
        },

        removed() {
            // Sometimes this is being run before `inserted()` (seen in Firefox 65).
            if (this._observer) {
                this._observer.disconnect();
            }
            if (this._gemini) {
                this._gemini.destroy();
            }
        }
    }
});
