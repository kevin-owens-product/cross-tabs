module.exports = {
    plugins: [
        require("cssnano")({
            preset: [
                "default",
                {
                    cssDeclarationSorter: {
                        exclude: true
                    }
                }
            ]
        }),
        require("autoprefixer")
    ]
};
