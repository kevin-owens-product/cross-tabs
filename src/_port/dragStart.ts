import { handlers } from "./helpers";

const dragstart = (app) => (event) => {
    try {
        /* This needs to be done because of Firefox. Elm doesn't allow the change of core
         props in runtime to avoid XSS injections.
         
         See: https://github.com/norpan/elm-html5-drag-drop/blob/3.1.4/example/index.html#L17
         */
        event.dataTransfer.setData("text", "");
    } catch (e) {
        // @ts-ignore
        if (e instanceof NoModificationAllowedError) {
        } // sometimes happens if you try to drag too fast? dunno... ~janiczek
        else {
            throw e;
        }
    }
};

export default handlers({
    dragstart
});
