import { handlers } from "./helpers";

const openNewWindow = (app) => (url) => {
    var w = window.open(url, "_blank");
    //fallback for Safari and other browser blocking new tab/window opening
    if (w === null || w === undefined) {
        try {
            var a = window.document.createElement("a");
            a.target = "_blank";
            a.href = url;
            a.download = url;

            var e = window.document.createEvent("MouseEvents");
            e.initMouseEvent(
                "click",
                true,
                true,
                window,
                0,
                0,
                0,
                0,
                0,
                true,
                false,
                false,
                false,
                0,
                null
            );
            a.dispatchEvent(e);
        } catch (e) {
            console.error("Something bad happend with URL downloading", e);
            window.location.href = url;
        }
    }
};

export default handlers({
    openNewWindow,
    openNewWindowD2: openNewWindow,
    openNewWindowXB2: openNewWindow,
    openNewWindowTV2: openNewWindow
});
