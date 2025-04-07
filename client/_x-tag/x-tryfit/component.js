function initialize(mainContent, extraContent) {
    return function perform() {
        mainContent.setAttribute("style", "");
        extraContent.setAttribute("style", "");

        var innerWidth = Math.max.apply(
            this,
            Array.prototype.slice.call(mainContent.children).map(function (c) {
                return c.offsetWidth;
            })
        );

        // this contition isn't as robust as it should be but it's enough for our current usecase
        if (innerWidth + mainContent.offsetLeft * 2 > this.offsetWidth) {
            extraContent.setAttribute("style", "display: block;");
            mainContent.setAttribute(
                "style",
                "overflow: hidden; text-overflow: ellipsis"
            );
        }
    }.bind(this);
}

xtag.register("x-tryfit", {
    lifecycle: {
        inserted: function () {
            var mainContent = this.querySelector("x-fitmain");
            var extraContent = this.querySelector("x-fitextra");

            this._eventHandler = initialize.call(this, mainContent, extraContent);
            window.addEventListener("resize", this._eventHandler);
            this._eventHandler();
        },
        removed: function () {
            window.removeEventListener("resize", this._eventHandler);
        },
        attributeChanged: function (attrName) {
            if (this._eventHandler) {
                let attempts = 5;
                while (attempts-- > 0) {
                    window.setTimeout(this._eventHandler, 100 * attempts);
                }
            }
        }
    }
});
