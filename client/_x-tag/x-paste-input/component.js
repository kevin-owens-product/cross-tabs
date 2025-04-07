/**
 * <x-paste-input> has the property that it fires `pastedata` event
 * with `{detail: "pasted string"}`. This is more desirable than the `paste`
 * event which Elm can't get the data from.
 *
 * Note we proxy only the minimum amount of events for the TV.Edit table
 * functionality to work; THIS IS NOT A GENERAL INPUT.
 * If you want to use this component for something else, you'll likely need
 * to add the features yourself.
 *
 * //RANT//
 * Note this would be much, much easier if the "customized built-in element"
 * web components worked in every browser. But noooooo. No no no no.
 * Firefox works fine, Chrome should but doesn't, and Safari outright rejected
 * implementing that.
 * So we have to implement our own custom element from scratch and connect its
 * attributes etc. to the <input> it hosts inside. Sigh.
 */
xtag.register("x-paste-input", {
    content: "<input />",
    lifecycle: {
        created: function () {
            this.xtag.input = this.querySelector("input");
            this.xtag.val = "0";
            this.xtag.isPasting = false;
            this.xtag.pasteData = "";
        }
    },
    methods: {
        focus: function () {
            this.xtag.input.focus();
        }
    },
    accessors: {
        value: {
            set: function (val) {
                this.xtag.input.value = val;
            }
        }
    },
    events: {
        paste: function (event) {
            event.preventDefault();
            const clipboardData = event.clipboardData || window.clipboardData; // IE hack
            const pasteData = clipboardData.getData("Text");
            this.xtag.pasteData = pasteData;
            this.xtag.isPasting = true;
            xtag.fireEvent(this, "pastedata", { detail: pasteData });
        },

        input: function (event) {
            if (
                this.xtag.val === "0" &&
                this.xtag.input.value !== "0" &&
                !this.xtag.isPasting
            ) {
                newval = this.xtag.input.value.replace(/0/g, "");
                this.xtag.val = newval;
                // Trigger a custom event with the modified value
                xtag.fireEvent(this, "inputdata", { detail: newval });
            } else if (this.xtag.isPasting) {
                xtag.fireEvent(this, "inputdata", { detail: this.xtag.pasteData });
            } else {
                this.xtag.val = this.xtag.input.value;
                const inputValue = this.xtag.val;
                xtag.fireEvent(this, "inputdata", { detail: inputValue });
            }

            this.xtag.isPasting = false;
        }
    }
});
