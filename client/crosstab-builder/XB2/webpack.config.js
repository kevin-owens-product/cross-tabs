const webpack = require("webpack");
const path = require("path");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const { ESBuildMinifyPlugin } = require("esbuild-loader");

const baseConfig = require("../../webpack.default.config.ts");

module.exports = (env, options) => {
    return baseConfig({
        appName: "crosstabs",
        indexPath: path.join(__dirname, "./index.ts")
    });
};
