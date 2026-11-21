import { execFile } from "node:child_process";
import { watch } from "node:fs";
import { writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { build as buildServer } from "tsup";

process.chdir(fileURLToPath(new URL("../", import.meta.url)));

const exec = promisify(execFile);
const builds = {
  server: async () => {
    await buildServer({ clean: false });
    await writeFile("dist/.mcp-reload", new Date().toISOString());
  },
  plugin: async () => {
    const { stdout } = await exec(process.execPath, ["src/cursor_mcp_plugin/build.mjs"]);
    process.stdout.write(stdout);
  },
};
const pending = new Set();
let timer;
let building = false;

function schedule(...targets) {
  for (const target of targets) pending.add(target);
  clearTimeout(timer);
  timer = setTimeout(rebuild, 150);
}

async function rebuild() {
  if (building || !pending.size) return;
  building = true;
  const targets = [...pending];
  pending.clear();
  const results = await Promise.allSettled(targets.map((target) => builds[target]()));
  for (const [index, result] of results.entries()) {
    if (result.status === "rejected") {
      console.error(`[dev] ${targets[index]} build failed:`, result.reason.stderr || result.reason.message);
    }
  }
  building = false;
  if (pending.size) schedule();
}

watch("src", { recursive: true }, (_, file) => {
  if (!file) {
    schedule("server", "plugin");
    return;
  }
  const path = file.replaceAll("\\", "/");
  if (/^cursor_mcp_plugin\/(?:src\/|ui\/|build\.mjs$)/.test(path)) {
    schedule("plugin");
  } else if (/^(?:talk_to_figma_mcp|usage)\/.*\.ts$/.test(path)) {
    schedule("server");
  }
});

console.log("[dev] watching MCP server and Figma plugin source");
schedule("server", "plugin");
