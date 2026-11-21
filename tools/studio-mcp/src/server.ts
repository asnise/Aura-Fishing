#!/usr/bin/env node
// Studio Bridge MCP server (stdio). Also hosts the localhost HTTP bridge the Studio plugin polls.
// Usage: node dist/server.js [--port=3060] [--http-only]
//   --http-only  run only the HTTP bridge (no MCP stdio), e.g. for scripts/studio-run.mjs testing.

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { readFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { z } from "zod";
import { Bridge, BridgeClient } from "./bridge.js";
import { captureUi } from "./capture.js";

const VERSION = "0.1.0";
const args = process.argv.slice(2);
const flag = (n: string) => args.find((a) => a.startsWith(`--${n}=`))?.slice(n.length + 3);
const PORT = Number(flag("port") || process.env.STUDIO_BRIDGE_PORT || 3060);
const HTTP_ONLY = args.includes("--http-only");

const log = (m: string) => process.stderr.write(`[studio-bridge] ${m}\n`);

// classes.json is generated at build time next to server.js (see scripts/gen-classes.mjs).
const here = dirname(fileURLToPath(import.meta.url));
let classesCache: unknown;
function classes() {
  if (classesCache === undefined) {
    const p = [join(here, "classes.json"), join(here, "..", "dist", "classes.json")].find(existsSync);
    classesCache = p ? JSON.parse(readFileSync(p, "utf8")) : {};
  }
  return classesCache;
}

const bridge = new Bridge({ staticRoutes: { "/classes": classes }, log });
const client = new BridgeClient(bridge, PORT, log);

// ------------------------------------------------------------------ MCP tools

const server = new McpServer({ name: "StudioBridge", version: VERSION });

type Params = Record<string, unknown>;
function text(value: unknown) {
  return { content: [{ type: "text" as const, text: typeof value === "string" ? value : JSON.stringify(value, null, 1) }] };
}
async function call(command: string, params: Params, timeoutMs = 30_000) {
  try {
    return text(await client.send(command, params, timeoutMs));
  } catch (e) {
    return { ...text(`Error: ${(e as Error).message}`), isError: true };
  }
}

const PATH_HELP =
  'Instance path, dot-separated from the DataModel, e.g. "Workspace.Map.Dock" or "game.StarterGui.HUD". ' +
  "Pass an array of names if a name contains a dot.";
const pathSchema = z.union([z.string(), z.array(z.string())]).describe(PATH_HELP);
const VALUE_HELP =
  'Values use JSON. Typed values: {"Vector3":[x,y,z]}, {"Vector2":[x,y]}, {"UDim2":[xs,xo,ys,yo]}, {"UDim":[s,o]}, ' +
  '{"Color3":[r,g,b]} (0-1) or "#RRGGBB", {"CFrame":[x,y,z,r00..r22]} or {"CFrame":[x,y,z]}, ' +
  '{"BrickColor":"Bright red"}, {"Font":{"Family":"rbxasset://fonts/families/GothamSSm.json","Weight":"Bold"}} or "GothamSSm", ' +
  '{"NumberRange":[min,max]}, {"Rect":[x0,y0,x1,y1]}, enums as "Center" or "Enum.TextXAlignment.Center", ' +
  'instance references as a path string or {"Instance":"Workspace.Part"}. Plain arrays/strings are converted using the ' +
  "property's current type, so {\"Size\":[0,100,0,40]} works for UDim2 props.";

server.tool(
  "studio_status",
  "Is Roblox Studio connected to the bridge? Lists connected Studio windows (place names).",
  {},
  async () => text(await client.status()),
);

server.tool(
  "get_tree",
  "List the instance hierarchy under a path (default: the main services). Returns {name, className, children} nodes. " +
    "Use small depth first; large trees are truncated at maxNodes.",
  {
    path: pathSchema.optional(),
    depth: z.number().int().min(0).max(20).optional().describe("Levels below path to include (default 2)"),
    maxNodes: z.number().int().min(1).max(5000).optional().describe("Default 400"),
    classFilter: z.string().optional().describe("Only list descendants that IsA this class (still walks through others)"),
  },
  (p) => call("get_tree", p),
);

server.tool(
  "find_instances",
  "Search descendants of a path by name (Lua pattern, case-insensitive substring by default) and/or class (IsA). Returns full paths.",
  {
    path: pathSchema.optional().describe("Root to search (default game)"),
    name: z.string().optional(),
    className: z.string().optional(),
    limit: z.number().int().min(1).max(2000).optional().describe("Default 100"),
  },
  (p) => call("find_instances", p),
);

server.tool(
  "get_properties",
  "Read all readable properties, attributes and tags of an instance (or only the listed properties). " + VALUE_HELP,
  { path: pathSchema, properties: z.array(z.string()).optional() },
  (p) => call("get_properties", p),
);

server.tool(
  "set_properties",
  "Set properties (and optionally attributes/tags) on an instance. One undo step (Ctrl+Z in Studio). " + VALUE_HELP,
  {
    path: pathSchema,
    props: z.record(z.any()).optional(),
    attributes: z.record(z.any()).optional().describe("Attribute values to set"),
    removeAttributes: z.array(z.string()).optional(),
    addTags: z.array(z.string()).optional(),
    removeTags: z.array(z.string()).optional(),
  },
  (p) => call("set_properties", p),
);

server.tool(
  "create_instance",
  "Create an instance (Instance.new) under parent, set props, return its path. One undo step. " + VALUE_HELP,
  {
    className: z.string(),
    parent: pathSchema,
    props: z.record(z.any()).optional().describe("Properties incl. Name; Parent is applied last"),
    attributes: z.record(z.any()).optional(),
  },
  (p) => call("create_instance", p),
);

server.tool(
  "delete_instance",
  "Destroy an instance (undoable with Ctrl+Z). Refuses services and Rojo-synced roots.",
  { path: pathSchema },
  (p) => call("delete_instance", p),
);

server.tool(
  "get_script_source",
  "Read the Source of a Script/LocalScript/ModuleScript, optionally a line range. Prefer reading src/ files on disk for Rojo-managed scripts.",
  {
    path: pathSchema,
    startLine: z.number().int().min(1).optional(),
    endLine: z.number().int().min(1).optional(),
  },
  (p) => call("get_script_source", p),
);

server.tool(
  "set_script_source",
  "Replace the Source of a script that is NOT managed by Rojo. Refuses scripts under ReplicatedStorage.Shared, " +
    "ServerScriptService.Server and StarterPlayer.StarterPlayerScripts.Client (edit src/ on disk instead) unless force=true.",
  { path: pathSchema, source: z.string(), force: z.boolean().optional() },
  (p) => call("set_script_source", p),
);

server.tool(
  "run_luau",
  "Run Luau code in Studio edit mode with plugin permissions (game, plugin APIs). The code is the body of a function: " +
    "use `return` to send values back. A single expression line is also accepted. Returns {returns, output, error}. " +
    "Changes are one undo step; on error the changes are rolled back.",
  {
    code: z.string(),
    timeoutSec: z.number().min(1).max(280).optional().describe("Default 30"),
  },
  (p) => call("run_luau", { code: p.code }, (p.timeoutSec ?? 30) * 1000),
);

server.tool("get_selection", "Paths of the instances currently selected in Studio.", {}, (p) => call("get_selection", p));

server.tool(
  "set_selection",
  "Select instances in Studio (empty array clears the selection).",
  { paths: z.array(pathSchema) },
  (p) => call("set_selection", p),
);

server.tool(
  "mount_ui_module",
  "Preview a Figma-exported UI module in Studio without Play: requires a fresh copy of the module " +
    "(default lookup: StarterPlayer.StarterPlayerScripts.Client.UI.Generated.<name>, then ReplicatedStorage.Shared) and " +
    "calls it with a preview ScreenGui in StarterGui (cleared first). Returns Root path and Refs.",
  {
    modulePath: pathSchema.describe('Module name ("ShopMenu") or full path'),
    screenGuiName: z.string().optional().describe('Default "FigmaPreview"'),
    solo: z.boolean().optional().describe("Hide (Enabled=false) other ScreenGuis in StarterGui while previewing; unmount restores them"),
  },
  (p) => call("mount_ui_module", p),
);

server.tool(
  "unmount_ui_module",
  "Remove a preview ScreenGui created by mount_ui_module and re-enable ScreenGuis hidden by solo.",
  { screenGuiName: z.string().optional() },
  (p) => call("unmount_ui_module", p),
);

server.tool(
  "capture_ui",
  "Screenshot a GUI object as it is drawn in the Studio EDIT viewport (Windows; stop Play first), e.g. to compare with a Figma export. " +
    "Temporarily makes the target visible, hides its siblings/other ScreenGuis (isolate, default true), grabs the Studio window " +
    "(PrintWindow, works when Studio is covered), crops to the target and restores everything. Returns the PNG path, size and the " +
    "DPI scale (screen px per GUI unit). The GUI must be under StarterGui (use mount_ui_module for generated modules).",
  {
    path: pathSchema.describe('GUI path, e.g. "StarterGui.Menus.Shop"'),
    out: z.string().describe("Output .png path (absolute, or relative to the bridge's working dir)"),
    padding: z.number().min(0).max(500).optional().describe("Extra GUI units around the target (default 0)"),
    isolate: z.boolean().optional(),
    background: z.string().optional().describe('Solid backdrop colour behind the ScreenGui, e.g. "#BFE8E0"'),
  },
  async (p) => {
    try {
      return text(await captureUi((c, params, t) => client.send(c, params, t), p));
    } catch (e) {
      return { ...text(`Error: ${(e as Error).message}`), isError: true };
    }
  },
);

// ------------------------------------------------------------------ start

async function main() {
  await client.start();
  if (HTTP_ONLY) {
    if (client.mode !== "owner") {
      log(`port ${PORT} already in use; nothing to do`);
      process.exit(1);
    }
    log("http-only mode; Ctrl+C to stop");
    return;
  }
  const transport = new StdioServerTransport();
  await server.connect(transport);
  log(`MCP ready (v${VERSION}, ${client.mode})`);
}

const shutdown = async () => {
  await bridge.close();
  process.exit(0);
};
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
process.stdin.on("close", () => {
  if (!HTTP_ONLY) shutdown();
});

main().catch((e) => {
  log(`fatal: ${(e as Error).stack}`);
  process.exit(1);
});
