export const register = (tag: string, customElement) => {
    if (!customElements.get(tag)) {
        customElements.define(tag, customElement);
    }
};
