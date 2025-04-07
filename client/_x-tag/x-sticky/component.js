const SCROLLABLE_CLASS = "gm-scroll-view";

/* This function resolves closest scrollable parent
- Scrollable parent is matched by class name defined in constant
- Closest parent is returned (iteration goes from node to window)
- If no parent matches class name than window itself is returned
*/
function parentScrollElement($el, scrollableElmClass) {
    let parent = $el.parentNode;
    const matchClass = scrollableElmClass || SCROLLABLE_CLASS;

    while (parent) {
        if (parent.classList && parent.classList.contains(matchClass)) {
            return parent;
        }

        // look into its parrent in next iter
        parent = parent.parentNode;
    }

    // return window in case there is no scrollable parent
    return window;
}

/* This function returns offset of one element to it's given parent
 */
function getOffsetTopTo(element, parent) {
    let offsetTop = element.offsetTop;

    // keep counting until you hit the parent
    while (element.parentNode !== parent) {
        offsetTop = +element.parentNode.offsetTop;
        element = element.parentNode;
    }

    return offsetTop;
}

xtag.register("x-sticky", {
    lifecycle: {
        inserted: function () {
            var parent = (this._scrollParent = parentScrollElement(
                this,
                this.attributes.scrollparent.nodeValue
            ));
            var offsetTop = getOffsetTopTo(this, parent);
            var settings = {
                offset: parseInt(this.attributes.offset.nodeValue),
                space: parseInt(this.attributes.space.nodeValue)
            };
            var scrollableHeight = parent.parentNode.getClientRects()[0].height;

            this._scrollHandler = function () {
                var content = this.childNodes[0];
                //when page is in loading state, container is missing and rest of code is running to error
                if (!content) return;

                var clientRect = content.getClientRects()[0];
                if (!clientRect) return;

                var scrolled = parent.scrollTop + offsetTop - settings.offset;
                var overflows = clientRect.height - scrollableHeight;
                var top;

                // scroll down
                if (clientRect.bottom + settings.space < scrollableHeight) {
                    top =
                        scrolled > 0
                            ? scrolled -
                              (overflows > 0
                                  ? overflows + settings.space
                                  : -settings.space)
                            : 0;
                }
                // scroll up
                else {
                    top = scrolled > 0 ? scrolled + settings.space : 0;
                }

                content.style.top = String(top) + "px";
            };

            // attach listener
            parent.addEventListener("scroll", this._scrollHandler.bind(this));
        },
        removed: function () {
            this._scrollParent.removeEventListener("scroll", this._scrollHandler);
        }
    }
});
