import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/server.ts", "src/capture.ts"],
  format: ["esm"],
  target: "node18",
  outDir: "dist",
  clean: false,
  sourcemap: true,
  bundle: true,
  splitting: false,
});
