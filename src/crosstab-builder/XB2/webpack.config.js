const webpack = require("webpack");
const path = require("path");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const { ESBuildMinifyPlugin } = require("esbuild-loader");

const baseConfig = require("../../webpack.default.config.ts");

module.exports = (env, options) => {
    const config = baseConfig({
        appName: "crosstabs",
        indexPath: path.join(__dirname, "./index.ts")
    });

    // Update module rules to prioritize TS/TSX over Elm
    // Elm loader is still included but won't be used for new React code
    config.module.rules = config.module.rules.map(rule => {
        if (rule.test && rule.test.toString().includes('\\.elm')) {
            // Keep Elm loader but make it less aggressive
            return {
                ...rule,
                exclude: [/elm-stuff/, /node_modules/, /src\/crosstab-builder\/XB2\/src\/.*\.tsx?$/]
            };
        }
        return rule;
    });

    // Add TSX support explicitly
    config.module.rules.push({
        test: /\.tsx?$/,
        use: "ts-loader",
        exclude: /node_modules/
    });

    // Update resolve extensions to prioritize TS/TSX
    config.resolve.extensions = [".tsx", ".ts", ".js", ".jsx", ".elm", ".scss"];

    return config;
};
