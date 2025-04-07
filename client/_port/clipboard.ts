import { handlers } from "./helpers";

const addHostAndCopyToClipboard = (app) => (url) => {
    navigator.clipboard.writeText(window.location.origin + url);
};

export default handlers({
    addHostAndCopyToClipboard
});
