export const monkeyPatchXtag = () => {
    if (!window.xtag) {
        console.error(
            "window.xtag not found. The x-tag monkey-patching has to be done AFTER you require x-tag itself."
        );
    }
    // In P2.0 we can sometimes try to register WebComponents more than once.
    // This prevents the crash that follows.
    // See ATC-969.
    const originalXtagRegister = xtag.register;
    window.xtag.register = (name, klass) => {
        try {
            return originalXtagRegister(name, klass);
        } catch {}
    };
};

export const register = (tag, cls) => {
    if (!customElements.get(tag)) {
        customElements.define(tag, cls);
    }
};

declare global {
    var xtag: {
        register: any;
    };
}
