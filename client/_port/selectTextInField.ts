import { handlers } from "./helpers";

const selectTextInField = (app) => (elementId) => {
    try {
        // @ts-ignore
        document.getElementById(elementId).select();
    } catch (e) {}
};

export default handlers({
    selectTextInField,
    selectTextInFieldXB2: selectTextInField
});
