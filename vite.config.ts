import elmPlugin from "vite-plugin-elm";
import { defineConfig } from "vite";

type TARGET_ENV = "development" | "production";
type NODE_ENV = "development" | "testsuite" | "testing" | "staging" | "production";
type WATCH_MODE = "true" | "false";
type DEBUG_MODE = "true" | "false";
const DEFAULT_TARGET_ENV: TARGET_ENV = "development";
const DEFAULT_NODE_ENV: NODE_ENV = "development";
const DEFAULT_WATCH_MODE: WATCH_MODE = "false";
const DEFAULT_DEBUG_MODE: DEBUG_MODE = "false";
const SERVER_PORT = 3900;

export default defineConfig({
    plugins: [elmPlugin()],
    server: {
        port: SERVER_PORT
    },
    build: {
        target: "esnext",
        minify: "esbuild",
        outDir: "build",
        emptyOutDir: true,
        sourcemap: true
    }
});
