import { handlers } from "./helpers";
import Cookies from "js-cookie";

const deleteCookie = (app) => (name) => Cookies.remove(name);

export default handlers({
    deleteCookie
});
