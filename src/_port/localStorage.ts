import { handlers } from "./helpers";

const localStorageSet = (app) => (params) => {
    window.localStorage.setItem(params[0], params[1]);
};

export default handlers({
    localStorageSet
});
