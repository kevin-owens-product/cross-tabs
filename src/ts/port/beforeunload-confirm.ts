import { handlers } from "./helpers";

const beforeLeaveHandler = (e) => {
    // @ts-ignore
    if (window._beforeLeaveConfirmMsg) {
        e.preventDefault();
        // @ts-ignore
        e.returnValue = window._beforeLeaveConfirmMsg; // Gecko and Trident
        // @ts-ignore
        return window._beforeLeaveConfirmMsg; // Gecko and WebKit
    } else {
        return true;
    }
};

const setConfirmMsgBeforeLeavePage = (app) => (params) => {
    const msg = (params && params.msg) || false;
    // @ts-ignore
    window._beforeLeaveConfirmMsg = msg;

    if (!window.addEventListener || !window.removeEventListener) {
        return;
    }

    if (msg !== false) {
        window.addEventListener("beforeunload", beforeLeaveHandler, false);
    } else {
        window.removeEventListener("beforeunload", beforeLeaveHandler, false);
    }
};

export default handlers({
    setConfirmMsgBeforeLeavePage
});
