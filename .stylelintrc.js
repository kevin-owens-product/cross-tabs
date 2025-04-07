// Avoid making it work like a formatter as much as possible.
module.exports = {
    customSyntax: require("postcss-scss"),
    rules: {
        "property-no-unknown": true,
        "unit-no-unknown": true,
        "block-no-empty": true,
        "at-rule-disallowed-list": ["import", "debug"],
        "color-no-invalid-hex": true,
        "color-hex-length": "long",
        "no-duplicate-selectors": true,
        "selector-attribute-quotes": "always",
        "declaration-no-important": true,
        "function-url-quotes": "always",
        "comment-whitespace-inside": "always"
    },
    ignoreFiles: []
};
