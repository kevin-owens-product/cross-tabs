import * as Utils from "../../utils";

const ACTIVE_ELLIPSIS_CLASS = "active-ellipsis";

const isEllipsisActive = (e) =>
    e.offsetWidth < e.scrollWidth || e.offsetHeight < e.scrollHeight;

/**
 * <x-cooltip> shows a tooltip next to your mouse when hovering a target.
 *
 * Usage:
 * ------
 * There are three different ways to use <x-cooltip>, corresponding to the type
 * CoolTip.Type:
 *
 *   1) Normal
 *   2) RelativeAncestor
 *   3) Global
 *
 *
 * 1) Normal:
 *      Should be the default, first thing to try to use.
 *
 * <x-cooltip offset="10"><!-- offset is optional -->
 *
 *     <x-cooltip-target>
 *         <... whatever you want the user to hover to show the tooltip ...>
 *     </x-cooltip-target>
 *
 *     <x-cooltip-tooltip>
 *         <... content of the tooltip, shown only when hovered ...>
 *     </x-cooltip-tooltip>
 *
 * </x-cooltip>
 *
 *
 * 2) RelativeAncestor:
 *      Used whenever there is some other relatively-positioned ancestor between
 *      your target element and the one you want to base the CoolTip position on.
 *
 *      This way you can say which element to look at for the mouse coordinates.
 *
 * <x-cooltip ... relative-ancestor-selector=".foo__bar--baz">
 *     ...as before...
 * </x-cooltip>
 *
 *
 * 3) Global:
 *      Moves the tooltip element to <body>.
 *
 *      Dangerous(?) option that gambles with the Elm virtual DOM invariants, but
 *      it has proven to be a way out of some tricky situations (looking at you,
 *      XB2 table + lazy loading + scrolling).
 *
 *      Use as a last resort!
 *
 * <x-cooltip ... global="true"><!-- or anything else, the value is not checked -->
 *     ...as before...
 * </x-cooltip>
 *
 *
 * !! WARNING: RANT ABOUT CSS AND INTERNAL IMPLEMENTATION BELOW !!
 *
 * To show the cooltip next to the mouse pointer and to the hovered target
 * element, we'd normally use a `position: relative` style on the cooltip wrapper,
 * but this conflicts with the Gemini toolbar's `overflow: hidden`.
 *
 * You can only break out of that `overflow: hidden` if the first
 * `position: relative` ancestor is also an ancestor of that `overflow: hidden`
 * element.
 *
 * Hence we need a different approach than `position: relative`: we're catching
 * `mousemove` events and tracking the mouse position. Then we have the cooltip
 * have a `position: fixed` (which works on the whole window, not some parent
 * element) and give it that position dynamically through
 * `transform: translate(...)`.
 *
 * The reason we don't just do that in Elm is that the `mousemove` listener would
 * have to be registered globally, even when no cooltips are shown.
 *
 * With WebComponent, we can do that dynamically with `mouseover` and `mouseout`.
 * We could do the same thing in Elm, but it would be managed then, and that's
 * a huge hassle. WebComponents will keep it encapsulated.
 *
 * Note that for `position: fixed` to work, no parent elements can have
 * `transform: translate(...)`. (Yeah, it's a mess.)
 */
class XCooltip extends HTMLElement {
    static get observedAttributes() {
        return ["offset", "global", "relative-ancestor-selector", "show-when-ellipsis"];
    }

    constructor() {
        super();

        this.mouseEnter = this.mouseEnter.bind(this);
        this.mouseLeave = this.mouseLeave.bind(this);
    }

    isGlobal: boolean;
    showWhenEllipsis: boolean;
    resizeObserver: ResizeObserver;
    clone: HTMLElement;
    tooltip: HTMLElement;
    ancestor: HTMLElement;
    ellipsisElement: HTMLElement;

    updateTooltip = (fn) => {
        if (this.isGlobal) {
            fn(this.clone);
        } else {
            fn(this.tooltip);
        }
    };

    connectedCallback() {
        this.showWhenEllipsis = this.hasAttribute("show-when-ellipsis");
        this.tooltip = this.querySelector("x-cooltip-tooltip");
        if (this.hasAttribute("offset")) {
            const offset = this.getAttribute("offset");
            this.tooltip.style.setProperty("--cooltip-offset", `${offset}px`);
        }
        if (this.hasAttribute("relative-ancestor-selector")) {
            this.ancestor = document.querySelector(
                this.getAttribute("relative-ancestor-selector")
            );
        } else if (this.hasAttribute("global")) {
            this.isGlobal = true;
            this.clone = this.tooltip.cloneNode(true) as HTMLElement;
            document.querySelector("body").appendChild(this.clone);
            this.tooltip.style.display = "none";
        }

        this.addEventListener("mouseenter", this.mouseEnter);
        this.addEventListener("mouseleave", this.mouseLeave);
    }

    attributeChangedCallback(attrName, oldValue, newValue) {
        if (attrName === "offset") {
            if (!this.tooltip) {
                return; // children weren't yet connected properly
            }
            this.updateTooltip((el) =>
                el.style.setProperty("--cooltip-offset", `${newValue}px`)
            );
        }
    }

    disconnectedCallback() {
        if (this.tooltip && this.isGlobal) {
            this.clone.remove();
        }

        if (this.resizeObserver) {
            this.resizeObserver.unobserve(this);
            this.ellipsisElement = null;
        }

        this.removeEventListener("mouseenter", this.mouseEnter);
        this.removeEventListener("mouseleave", this.mouseLeave);
    }

    mouseEnter(event) {
        if (!this.tooltip) {
            return; // children weren't yet connected properly
        }

        if (this.isGlobal) {
            //this is to change the content of the tooltip if the user renames it
            let tooltipGlobal = this.tooltip.cloneNode(true) as HTMLElement;
            this.clone.remove();
            this.clone = tooltipGlobal;
            document.querySelector("body").appendChild(this.clone);
        }

        if (this.showWhenEllipsis) {
            const ellipsisElement = this.querySelector(
                this.getAttribute("show-when-ellipsis")
            );
            const showTooltip = ellipsisElement && isEllipsisActive(ellipsisElement);

            if (showTooltip) {
                ellipsisElement.classList.add(ACTIVE_ELLIPSIS_CLASS);

                this.updateTooltip((el) => {
                    el.style.display = "";
                });
            } else {
                this.updateTooltip((el) => {
                    el.style.display = "none";
                });

                if (ellipsisElement) {
                    ellipsisElement.classList.remove(ACTIVE_ELLIPSIS_CLASS);
                }

                return;
            }
        }

        const cooltipTarget = event.target.querySelector("x-cooltip-target");
        const childElement =
            cooltipTarget.childNodes &&
            cooltipTarget.childNodes.length === 1 &&
            cooltipTarget.childNodes[0];
        const rect = childElement
            ? childElement.getBoundingClientRect()
            : event.target.getBoundingClientRect();
        const ancestorRect = this.ancestor ? this.ancestor.getBoundingClientRect() : null;
        const ancestorX = ancestorRect ? ancestorRect.x : 0;
        const ancestorY = ancestorRect ? ancestorRect.y : 0;

        this.updateTooltip((el) => {
            el.style.setProperty("--cooltip-target-x", `${rect.x - ancestorX}px`);
            el.style.setProperty("--cooltip-target-y", `${rect.y - ancestorY}px`);
            el.style.setProperty("--cooltip-target-width", `${rect.width}px`);
            el.style.setProperty("--cooltip-target-height", `${rect.height}px`);
            el.style.opacity = 0; //avoid visible jumping till is width and height set

            if (this.isGlobal) {
                // This 'block' will bite us in ass one day. Most cooltips have 'flex'.
                el.style.display = "block";
            }
        });

        this.updateTooltip((el) => {
            setTimeout(() => {
                const elRect = this.isGlobal
                    ? this.clone.getBoundingClientRect()
                    : el.getBoundingClientRect();
                el.style.opacity = 1;
                el.style.setProperty("--cooltip-width", `${elRect.width}px`);
                el.style.setProperty("--cooltip-height", `${elRect.height}px`);
            }, 100);
        });
    }

    mouseLeave(event) {
        if (!this.tooltip) {
            return; // children weren't yet connected properly
        }

        this.updateTooltip((el) => {
            el.style.removeProperty("--cooltip-target-x");
            el.style.removeProperty("--cooltip-target-y");
            el.style.removeProperty("--cooltip-target-width");
            el.style.removeProperty("--cooltip-target-height");
            el.style.removeProperty("--cooltip-width");
            el.style.removeProperty("--cooltip-height");

            if (this.isGlobal) {
                el.style.display = "none";
            }
        });
    }
}

Utils.register("x-cooltip", XCooltip);
