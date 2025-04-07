import SimpleBar from "simplebar";

import * as Utils from "../../utils";

const getElementWindow = (element) =>
    !element || !element.ownerDocument || !element.ownerDocument.defaultView
        ? window
        : element.ownerDocument.defaultView;

class PlatformSimpleBar extends SimpleBar {
    contentWrapperEl: HTMLElement;
    contentEl: HTMLElement;
    axis: Map<String, HTMLElement>;
    mouseY: number;
    mouseX: number;
    options: {
        clickOnTrack: boolean;
        scrollbarMinSize: number;
        scrollbarMaxSize: number;
    };

    getCorrectTrackSize(axis) {
        if (axis === "y") {
            const barStyles = getComputedStyle(
                document.querySelector(".simplebar-track.simplebar-vertical")
            );
            return parseInt(barStyles.height, 10) + parseInt(barStyles.bottom, 10);
        } else {
            const barStyles = getComputedStyle(
                document.querySelector(".simplebar-track.simplebar-horizontal")
            );
            return parseInt(barStyles.width, 10) + parseInt(barStyles.right, 10);
        }
    }

    onTrackClick(e, axis = "y") {
        if (!this.options.clickOnTrack) return;

        const elWindow = getElementWindow(this.el);
        this.axis[axis].scrollbar.rect =
            this.axis[axis].scrollbar.el.getBoundingClientRect();
        const scrollbar = this.axis[axis].scrollbar;
        const scrollbarOffset = scrollbar.rect[this.axis[axis].offsetAttr];
        const hostSize = this.getCorrectTrackSize(axis);

        let scrolled = this.contentWrapperEl[this.axis[axis].scrollOffsetAttr];
        const t =
            axis === "y" ? this.mouseY - scrollbarOffset : this.mouseX - scrollbarOffset;
        const dir = t < 0 ? -1 : 1;
        const scrollSize = dir === -1 ? scrolled - hostSize : scrolled + hostSize;
        const speed = 100;

        const scrollTo = () => {
            if (dir === -1) {
                if (scrolled > scrollSize) {
                    scrolled -= speed;
                    this.contentWrapperEl.scrollTo({
                        [this.axis[axis].offsetAttr]: scrolled
                    });
                    elWindow.requestAnimationFrame(scrollTo);
                }
            } else {
                if (scrolled < scrollSize) {
                    scrolled += speed;
                    this.contentWrapperEl.scrollTo({
                        [this.axis[axis].offsetAttr]: scrolled
                    });
                    elWindow.requestAnimationFrame(scrollTo);
                }
            }
        };

        scrollTo();
    }

    getScrollbarSize(axis = "y") {
        if (!this.axis[axis].isOverflowing) {
            return 0;
        }

        const contentSize = this.contentEl[this.axis[axis].scrollSizeAttr];
        const trackSize = this.getCorrectTrackSize(axis);
        let scrollbarSize;

        let scrollbarRatio = trackSize / contentSize;

        // Calculate new height/position of drag handle.
        scrollbarSize = Math.max(
            ~~(scrollbarRatio * trackSize),
            this.options.scrollbarMinSize
        );

        if (this.options.scrollbarMaxSize) {
            scrollbarSize = Math.min(scrollbarSize, this.options.scrollbarMaxSize);
        }

        return scrollbarSize;
    }
}

class SimpleBarComponent extends HTMLElement {
    static get observedAttributes() {
        return ["scrollable-selector", "variant"];
    }

    _simplebar: SimpleBar | PlatformSimpleBar;
    createSimpleBar: () => void;

    constructor() {
        super();

        this.createSimpleBar = function () {
            const variant = this.getAttribute("variant");

            if (variant === "simple") {
                this._simplebar = new SimpleBar(this);
            } else {
                this._simplebar = new PlatformSimpleBar(this);
            }
        };
    }

    connectedCallback() {
        /* Handle issue when simplebar is set to element and also CSS is changed by additional class in the same moment.
       Simplebar could be initialised with wrong (not CSS recomputed) state.
       This little delay gives browser time to re-render all HTML based on latest CSS changes.
    */
        setTimeout(() => this.createSimpleBar(), 100);
    }

    disconnectedCallback() {
        if (this._simplebar) {
            this._simplebar.unMount();
            delete this._simplebar;
        }
    }

    attributeChangedCallback(attrName, oldValue, newValue) {
        if (this._simplebar === undefined) {
            return;
        }

        if (attrName === "scrollable-selector" && newValue) {
            // @ts-ignore
            this._simplebar.scrollableSelector = newValue;
        } else if (attrName === "variant" && oldValue !== newValue) {
            this._simplebar.unMount();
            this.createSimpleBar();
        }
    }
}

Utils.register("x-simplebar", SimpleBarComponent);
