import ResizeObserver from "resize-observer-polyfill";
import * as Utils from "../../utils";

/**
 * <x-resize-observer target-selector=".my-target">
 *   <!-- whatever HTML you put inside -->
 *   <div>
 *     ...
 *     <div class="my-target"> ... </div>
 *     ...
 *   </div>
 * </x-resize-observer>
 *
 * will send an event "targetresize" with {detail: {width: Int, height: Int}} JSON.
 *
 * It can even be the element itself!
 * <x-resize-observer class="here" target-selector=".here">
 * </x-resize-observer>
 *
 * NOTE:
 * The targeted element needs to have some height (can be usually done using
 * `height: 100%` or something similar).
 * You can check this using the web inspector. If you're getting height: 0 in
 * the events, you'll see an element with height 0 in the web inspector too and
 * can experiment with how to make it have proper height.
 */
class XResizeObserver extends HTMLElement {
    static get observedAttributes() {
        return ["target-selector", "propagate-values-to-css"];
    }

    constructor() {
        super();
        this.propagateValueToCss = false;
    }

    resizeObserver: ResizeObserver;
    observedSelector: string;
    propagateValueToCss: boolean;

    connectedCallback() {
        setTimeout(() => {
            // We wrap it in requestAnimationFrame to avoid this error - ResizeObserver loop limit exceeded
            this.resizeObserver = new ResizeObserver((entries) => {
                window.requestAnimationFrame(() => {
                    if (!Array.isArray(entries) || !entries.length) {
                        return;
                    }
                    for (const entry of entries) {
                        let dimensions = {
                            width: entry.contentRect.width,
                            height: entry.contentRect.height
                        };

                        if (entry.borderBoxSize) {
                            // new spec
                            // see https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry

                            // Even with the new spec there are compatibility problems.
                            // Firefox 83 sends an inlined object; Chrome 86 sends an array.
                            // Sigh. Let's support both variants.
                            const borderBoxSize = Array.isArray(entry.borderBoxSize)
                                ? entry.borderBoxSize[0]
                                : entry.borderBoxSize;

                            dimensions = {
                                // These two should be swapped if your `writing-mode` is vertical - we do not use it in our codebase, keeping the comment here just in case it will happen
                                width: borderBoxSize.inlineSize,
                                height: borderBoxSize.blockSize
                            };
                        }

                        // with Elm the observer runs quite often with 0 dimensions first and then with
                        // proper values - we want to ignore the 0 dimensions cases as they were
                        // delivered later and mess with change events order.
                        if (dimensions.width !== 0 && dimensions.height !== 0) {
                            this.dispatchEvent(
                                new CustomEvent("targetresize", {
                                    detail: dimensions,
                                    bubbles: false
                                })
                            );

                            const element = document.querySelector(this.observedSelector);
                            if (this.propagateValueToCss && element) {
                                //@ts-ignore
                                element.style.setProperty(
                                    "--element-width",
                                    dimensions.width + "px"
                                );
                                //@ts-ignore
                                element.style.setProperty(
                                    "--element-height",
                                    dimensions.height + "px"
                                );
                            }
                        }
                    }
                });
            });

            const element = document.querySelector(this.observedSelector);

            if (this.propagateValueToCss && element) {
                window.requestAnimationFrame(() => {
                    const d = element.getBoundingClientRect();
                    //@ts-ignore
                    element.style.setProperty("--element-width", d.width + "px");
                    //@ts-ignore
                    element.style.setProperty("--element-height", d.height + "px");
                });
            }

            if (element) {
                this.resizeObserver.observe(element);
            }
        }, 0);
    }

    disconnectedCallback() {
        const element = document.querySelector(this.observedSelector);
        if (element && this.resizeObserver) {
            this.resizeObserver.unobserve(element);
        }
        this.observedSelector = null;
    }

    attributeChangedCallback(attrName, _, newValue) {
        if (attrName === "target-selector" && newValue) {
            const element = document.querySelector(this.observedSelector);
            if (this.resizeObserver && element) {
                this.resizeObserver.unobserve(element);
            }

            this.observedSelector = newValue;

            const newElement = document.querySelector(this.observedSelector);
            if (this.resizeObserver && newElement) {
                this.resizeObserver.observe(newElement);
            }
        } else if (attrName === "propagate-values-to-css" && newValue) {
            this.propagateValueToCss = newValue;
        }
    }
}

Utils.register("x-resize-observer", XResizeObserver);
