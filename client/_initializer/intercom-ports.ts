import Intercom from "@globalwebindex/platform2-lib/dist/intercom";

export default (app) => {
    if (Intercom) {
        window.addEventListener(Intercom.STATE_CHANGED_EVENT, (event) => {
            // @ts-ignore
            app.ports.setChatVisibility.send(event.detail.isOpened);
        });
    }
};
