#!/usr/bin/env node

// src/server.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { readFileSync as readFileSync2, existsSync as existsSync2 } from "fs";
import { dirname as dirname2, join as join2 } from "path";
import { fileURLToPath as fileURLToPath2 } from "url";
import { z } from "zod";

// src/bridge.ts
import http from "http";
import { randomUUID } from "crypto";
var BRIDGE_HEADER = "x-studio-bridge";
var BRIDGE_NAME = "aura-studio-bridge";
var BridgeError = class extends Error {
};
var Bridge = class {
  queue = [];
  pending = /* @__PURE__ */ new Map();
  clients = /* @__PURE__ */ new Map();
  waiters = [];
  server;
  opts;
  constructor(opts = {}) {
    this.opts = {
      pollHoldMs: opts.pollHoldMs ?? 15e3,
      clientStaleMs: opts.clientStaleMs ?? 25e3,
      staticRoutes: opts.staticRoutes ?? {},
      log: opts.log ?? (() => {
      })
    };
  }
  // ---------------------------------------------------------------- queue
  /** Queue a command for Studio and wait for its result. */
  send(command, params = {}, timeoutMs = 3e4) {
    const cmd = { id: randomUUID(), command, params, timeoutMs };
    return new Promise((resolve2, reject) => {
      const timer = setTimeout(() => {
        const p = this.pending.get(cmd.id);
        if (!p) return;
        this.pending.delete(cmd.id);
        const i = this.queue.indexOf(cmd);
        if (i >= 0) this.queue.splice(i, 1);
        const why = p.delivered ? `Studio did not answer "${command}" within ${timeoutMs} ms (it may still be running).` : this.connectedClients().length === 0 ? `No Studio plugin connected. Open Studio, enable the "Studio Bridge" plugin and press Connect.` : `Studio did not pick up "${command}" within ${timeoutMs} ms.`;
        reject(new BridgeError(why));
      }, timeoutMs);
      this.pending.set(cmd.id, { command: cmd, resolve: resolve2, reject, timer, delivered: false });
      this.queue.push(cmd);
      this.flush();
    });
  }
  /** Called by the plugin (via /poll). Returns queued commands now, or after a wait. */
  poll(clientId, info = {}, waitMs = this.opts.pollHoldMs) {
    this.touch(clientId, info);
    if (this.queue.length > 0 || waitMs <= 0) return Promise.resolve(this.take());
    return new Promise((resolve2) => {
      const waiter = {
        clientId,
        respond: (cmds) => {
          clearTimeout(waiter.timer);
          this.waiters = this.waiters.filter((w) => w !== waiter);
          this.touch(clientId);
          resolve2(cmds);
        },
        timer: setTimeout(() => waiter.respond([]), Math.min(waitMs, this.opts.pollHoldMs))
      };
      this.waiters.push(waiter);
    });
  }
  /** Called by the plugin (via /result). Returns false if the id is unknown (e.g. timed out). */
  complete(id, ok, result, error) {
    const p = this.pending.get(id);
    if (!p) return false;
    clearTimeout(p.timer);
    this.pending.delete(id);
    if (ok) p.resolve(result);
    else p.reject(new BridgeError(error || "Studio reported an error"));
    return true;
  }
  connectedClients() {
    const now = Date.now();
    const waiting = new Set(this.waiters.map((w) => w.clientId));
    return [...this.clients.values()].filter((c) => waiting.has(c.id) || now - c.lastSeen < this.opts.clientStaleMs);
  }
  status() {
    return {
      bridge: BRIDGE_NAME,
      clients: this.connectedClients(),
      queued: this.queue.length,
      pending: this.pending.size
    };
  }
  /** Reject everything (used on shutdown). */
  cancelAll(reason = "Bridge shut down") {
    for (const [id, p] of this.pending) {
      clearTimeout(p.timer);
      p.reject(new BridgeError(reason));
      this.pending.delete(id);
    }
    this.queue.length = 0;
    for (const w of [...this.waiters]) w.respond([]);
  }
  take() {
    const cmds = this.queue.splice(0, this.queue.length);
    for (const c of cmds) {
      const p = this.pending.get(c.id);
      if (p) p.delivered = true;
    }
    return cmds;
  }
  flush() {
    if (this.queue.length === 0) return;
    const w = this.waiters[0];
    if (w) w.respond(this.take());
  }
  touch(clientId, info = {}) {
    const prev = this.clients.get(clientId);
    this.clients.set(clientId, {
      id: clientId,
      place: info.place ?? prev?.place ?? "?",
      version: info.version ?? prev?.version ?? "?",
      lastSeen: Date.now()
    });
  }
  // ---------------------------------------------------------------- HTTP
  /** Start listening on 127.0.0.1:port. Resolves false if the port is already taken. */
  listen(port) {
    return new Promise((resolve2, reject) => {
      const server2 = http.createServer((req, res) => this.handle(req, res));
      server2.keepAliveTimeout = 5e3;
      server2.requestTimeout = 0;
      server2.once("error", (e) => {
        if (e.code === "EADDRINUSE") resolve2(false);
        else reject(e);
      });
      server2.listen(port, "127.0.0.1", () => {
        this.server = server2;
        resolve2(true);
      });
    });
  }
  get listening() {
    return !!this.server;
  }
  close() {
    this.cancelAll();
    const s = this.server;
    this.server = void 0;
    return new Promise((r) => s ? s.close(() => r()) : r());
  }
  async handle(req, res) {
    const send = (code, body) => {
      const text2 = JSON.stringify(body);
      res.writeHead(code, { "Content-Type": "application/json", "Cache-Control": "no-store" });
      res.end(text2);
    };
    try {
      if (req.headers.origin || req.headers[BRIDGE_HEADER] !== "1") {
        return send(403, { ok: false, error: `missing ${BRIDGE_HEADER} header or cross-origin request` });
      }
      const url = new URL(req.url || "/", "http://127.0.0.1");
      const route = `${req.method} ${url.pathname}`;
      if (route === "GET /poll") {
        const client2 = url.searchParams.get("client") || "anonymous";
        const wait = Number(url.searchParams.get("wait") ?? this.opts.pollHoldMs);
        let closed = false;
        req.on("close", () => closed = true);
        const cmds = await this.poll(
          client2,
          { place: url.searchParams.get("place") ?? void 0, version: url.searchParams.get("version") ?? void 0 },
          Number.isFinite(wait) ? wait : this.opts.pollHoldMs
        );
        if (closed && cmds.length > 0) {
          for (const c of cmds) {
            const p = this.pending.get(c.id);
            if (p) {
              p.delivered = false;
              this.queue.unshift(c);
            }
          }
          return;
        }
        return send(200, { commands: cmds });
      }
      if (route === "POST /result") {
        const body = await readJson(req);
        if (!body || typeof body.id !== "string") return send(400, { ok: false, error: "id required" });
        const known = this.complete(body.id, body.ok !== false, body.result, body.error);
        return send(200, { ok: true, known });
      }
      if (route === "POST /command") {
        const body = await readJson(req);
        if (!body || typeof body.command !== "string") return send(400, { ok: false, error: "command required" });
        try {
          const result = await this.send(body.command, body.params ?? {}, clampTimeout(body.timeoutMs));
          return send(200, { ok: true, result });
        } catch (e) {
          return send(200, { ok: false, error: e.message });
        }
      }
      if (route === "GET /status") return send(200, this.status());
      if (req.method === "GET" && this.opts.staticRoutes[url.pathname]) {
        return send(200, this.opts.staticRoutes[url.pathname]());
      }
      return send(404, { ok: false, error: `no route ${route}` });
    } catch (e) {
      this.opts.log(`http error: ${e.stack}`);
      if (!res.headersSent) send(500, { ok: false, error: e.message });
    }
  }
};
function clampTimeout(ms, def = 3e4) {
  const n = Number(ms);
  if (!Number.isFinite(n) || n <= 0) return def;
  return Math.min(Math.max(n, 1e3), 28e4);
}
function readJson(req, limit = 20 * 1024 * 1024) {
  return new Promise((resolve2, reject) => {
    const chunks = [];
    let size = 0;
    req.on("data", (c) => {
      size += c.length;
      if (size > limit) {
        reject(new Error("body too large"));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on("end", () => {
      try {
        const text2 = Buffer.concat(chunks).toString("utf8");
        resolve2(text2 ? JSON.parse(text2) : {});
      } catch (e) {
        reject(e);
      }
    });
    req.on("error", reject);
  });
}
var BridgeClient = class {
  constructor(bridge2, port, log2 = () => {
  }) {
    this.bridge = bridge2;
    this.port = port;
    this.log = log2;
  }
  bridge;
  port;
  log;
  owner = false;
  get mode() {
    return this.owner ? "owner" : "proxy";
  }
  async start() {
    this.owner = await this.bridge.listen(this.port);
    this.log(this.owner ? `listening on 127.0.0.1:${this.port}` : `port ${this.port} in use, using proxy mode`);
  }
  async send(command, params = {}, timeoutMs = 3e4) {
    if (!this.owner) {
      try {
        return await this.remote(command, params, timeoutMs);
      } catch (e) {
        if (!(e instanceof OwnerGoneError)) throw e;
        this.owner = await this.bridge.listen(this.port);
        if (!this.owner) throw new BridgeError(`Port ${this.port} is used by something that is not the Studio bridge.`);
        this.log(`took over 127.0.0.1:${this.port}`);
      }
    }
    return this.bridge.send(command, params, timeoutMs);
  }
  async status() {
    if (this.owner) return { mode: "owner", port: this.port, ...this.bridge.status() };
    try {
      const r = await fetch(`http://127.0.0.1:${this.port}/status`, { headers: { [BRIDGE_HEADER]: "1" } });
      return { mode: "proxy", port: this.port, ...await r.json() };
    } catch {
      this.owner = await this.bridge.listen(this.port);
      return { mode: this.mode, port: this.port, ...this.bridge.status() };
    }
  }
  async remote(command, params, timeoutMs) {
    let r;
    try {
      r = await fetch(`http://127.0.0.1:${this.port}/command`, {
        method: "POST",
        headers: { "Content-Type": "application/json", [BRIDGE_HEADER]: "1" },
        body: JSON.stringify({ command, params, timeoutMs }),
        signal: AbortSignal.timeout(timeoutMs + 5e3)
      });
    } catch (e) {
      const err = e;
      const code = err.code ?? err.cause?.code;
      if (code === "ECONNREFUSED") throw new OwnerGoneError();
      throw e;
    }
    const body = await r.json();
    if (!body.ok) throw new BridgeError(body.error || `bridge error (${r.status})`);
    return body.result;
  }
};
var OwnerGoneError = class extends Error {
};

// src/capture.ts
import { execFile } from "child_process";
import { existsSync, readFileSync } from "fs";
import { dirname, join, resolve } from "path";
import { fileURLToPath } from "url";
var here = dirname(fileURLToPath(import.meta.url));
function scriptPath() {
  const p = [join(here, "..", "scripts", "capture-window.ps1"), join(here, "capture-window.ps1")].find(existsSync);
  if (!p) throw new Error("capture-window.ps1 not found next to the bridge");
  return p;
}
function ps(args2) {
  return new Promise((res, rej) => {
    execFile(
      "powershell.exe",
      ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", scriptPath(), ...args2],
      { windowsHide: true, timeout: 6e4, maxBuffer: 4 * 1024 * 1024 },
      (err, stdout, stderr) => {
        const line = stdout.trim().split(/\r?\n/).filter((l) => l.startsWith("{")).pop();
        if (line) {
          try {
            return res(JSON.parse(line));
          } catch {
          }
        }
        const msg = (stderr || String(err || "")).split(/\r?\n/).find((l) => /\S/.test(l) && !l.startsWith("At ") && !l.trim().startsWith("+")) || "capture failed";
        rej(new Error(msg.replace(/^.*?:\s*/, "").trim() || msg));
      }
    );
  });
}
var sleep = (ms) => new Promise((r) => setTimeout(r, ms));
var lit = (src) => "[==[" + src + "]==]";
function legacySend(send) {
  let loaded = false;
  return async (command, params, timeoutMs) => {
    if (!loaded) {
      const dir = [join(here, "..", "plugin", "src")].find((d) => existsSync(join(d, "Capture.luau")));
      if (!dir) throw new Error("plugin has no capture commands and plugin/src was not found; reinstall the plugin and restart Studio");
      const code = [
        'local f = Instance.new("Folder")',
        `local p = Instance.new("ModuleScript") p.Name = "Path" p.Source = ${lit(readFileSync(join(dir, "Path.luau"), "utf8"))} p.Parent = f`,
        `local c = Instance.new("ModuleScript") c.Name = "Capture" c.Source = ${lit(readFileSync(join(dir, "Capture.luau"), "utf8"))} c.Parent = f`,
        "_G.__StudioBridgeCapture = require(c)",
        "return true"
      ].join("\n");
      const r2 = await send("run_luau", { code }, 2e4);
      if (r2.error) throw new Error("loading capture code failed: " + r2.error);
      loaded = true;
    }
    const r = await send(
      "run_luau",
      { code: `return _G.__StudioBridgeCapture.${command}(game:GetService("HttpService"):JSONDecode(${lit(JSON.stringify(params))}))` },
      timeoutMs
    );
    if (r.error) throw new Error(r.error.split(String.fromCharCode(10))[0].trim());
    return r.returns[0];
  };
}
async function captureUi(send, o) {
  if (process.platform !== "win32") throw new Error("capture_ui only works on Windows");
  const out = resolve(o.out);
  const prepParams = { path: o.path, isolate: o.isolate, background: o.background };
  let prep;
  try {
    prep = await send("capture_prepare", prepParams, 2e4);
  } catch (e) {
    if (!/unknown command/.test(e.message)) throw e;
    send = legacySend(send);
    prep = await send("capture_prepare", prepParams, 2e4);
  }
  try {
    await sleep(150);
    const found = await ps(["-Mode", "find", "-Title", prep.place, "-Method", o.method || "auto"]).catch((e) => {
      throw new Error(`${e.message} (Stop Play mode; the plugin draws in the Edit viewport.)`);
    });
    const m = found.marker;
    const scaleX = m.w / prep.markerSize;
    const scaleY = m.h / prep.markerSize;
    const scale = Math.round((scaleX + scaleY) / 2 * 1e3) / 1e3;
    const pad = o.padding ?? 0;
    const x = Math.round(m.x + (prep.target.x - prep.marker.x - pad) * scaleX);
    const y = Math.round(m.y + (prep.target.y - prep.marker.y - pad) * scaleY);
    const w = Math.round((prep.target.w + pad * 2) * scaleX);
    const h = Math.round((prep.target.h + pad * 2) * scaleY);
    await send("capture_marker", { token: prep.token, visible: false }, 1e4);
    await sleep(150);
    const crop = await ps(["-Mode", "crop", "-Hwnd", String(found.hwnd), "-Method", found.method, "-X", String(x), "-Y", String(y), "-W", String(w), "-H", String(h), "-Out", out]);
    return {
      out: crop.out,
      size: { w: crop.w, h: crop.h },
      clipped: crop.clipped,
      scale,
      guiRect: prep.target,
      viewport: prep.viewport,
      viewportPx: { w: Math.round(prep.viewport.w * scaleX), h: Math.round(prep.viewport.h * scaleY) },
      method: found.method,
      window: found.title,
      note: scale !== 1 ? `Studio draws 1 GUI unit as ${scale} screen px (Windows display scaling). Divide by ${scale} to compare with 1x Figma exports.` : void 0
    };
  } finally {
    await send("capture_restore", { token: prep.token }, 1e4).catch(() => {
    });
  }
}

// src/server.ts
var VERSION = "0.1.0";
var args = process.argv.slice(2);
var flag = (n) => args.find((a) => a.startsWith(`--${n}=`))?.slice(n.length + 3);
var PORT = Number(flag("port") || process.env.STUDIO_BRIDGE_PORT || 3060);
var HTTP_ONLY = args.includes("--http-only");
var log = (m) => process.stderr.write(`[studio-bridge] ${m}
`);
var here2 = dirname2(fileURLToPath2(import.meta.url));
var classesCache;
function classes() {
  if (classesCache === void 0) {
    const p = [join2(here2, "classes.json"), join2(here2, "..", "dist", "classes.json")].find(existsSync2);
    classesCache = p ? JSON.parse(readFileSync2(p, "utf8")) : {};
  }
  return classesCache;
}
var bridge = new Bridge({ staticRoutes: { "/classes": classes }, log });
var client = new BridgeClient(bridge, PORT, log);
var server = new McpServer({ name: "StudioBridge", version: VERSION });
function text(value) {
  return { content: [{ type: "text", text: typeof value === "string" ? value : JSON.stringify(value, null, 1) }] };
}
async function call(command, params, timeoutMs = 3e4) {
  try {
    return text(await client.send(command, params, timeoutMs));
  } catch (e) {
    return { ...text(`Error: ${e.message}`), isError: true };
  }
}
var PATH_HELP = 'Instance path, dot-separated from the DataModel, e.g. "Workspace.Map.Dock" or "game.StarterGui.HUD". Pass an array of names if a name contains a dot.';
var pathSchema = z.union([z.string(), z.array(z.string())]).describe(PATH_HELP);
var VALUE_HELP = `Values use JSON. Typed values: {"Vector3":[x,y,z]}, {"Vector2":[x,y]}, {"UDim2":[xs,xo,ys,yo]}, {"UDim":[s,o]}, {"Color3":[r,g,b]} (0-1) or "#RRGGBB", {"CFrame":[x,y,z,r00..r22]} or {"CFrame":[x,y,z]}, {"BrickColor":"Bright red"}, {"Font":{"Family":"rbxasset://fonts/families/GothamSSm.json","Weight":"Bold"}} or "GothamSSm", {"NumberRange":[min,max]}, {"Rect":[x0,y0,x1,y1]}, enums as "Center" or "Enum.TextXAlignment.Center", instance references as a path string or {"Instance":"Workspace.Part"}. Plain arrays/strings are converted using the property's current type, so {"Size":[0,100,0,40]} works for UDim2 props.`;
server.tool(
  "studio_status",
  "Is Roblox Studio connected to the bridge? Lists connected Studio windows (place names).",
  {},
  async () => text(await client.status())
);
server.tool(
  "get_tree",
  "List the instance hierarchy under a path (default: the main services). Returns {name, className, children} nodes. Use small depth first; large trees are truncated at maxNodes.",
  {
    path: pathSchema.optional(),
    depth: z.number().int().min(0).max(20).optional().describe("Levels below path to include (default 2)"),
    maxNodes: z.number().int().min(1).max(5e3).optional().describe("Default 400"),
    classFilter: z.string().optional().describe("Only list descendants that IsA this class (still walks through others)")
  },
  (p) => call("get_tree", p)
);
server.tool(
  "find_instances",
  "Search descendants of a path by name (Lua pattern, case-insensitive substring by default) and/or class (IsA). Returns full paths.",
  {
    path: pathSchema.optional().describe("Root to search (default game)"),
    name: z.string().optional(),
    className: z.string().optional(),
    limit: z.number().int().min(1).max(2e3).optional().describe("Default 100")
  },
  (p) => call("find_instances", p)
);
server.tool(
  "get_properties",
  "Read all readable properties, attributes and tags of an instance (or only the listed properties). " + VALUE_HELP,
  { path: pathSchema, properties: z.array(z.string()).optional() },
  (p) => call("get_properties", p)
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
    removeTags: z.array(z.string()).optional()
  },
  (p) => call("set_properties", p)
);
server.tool(
  "create_instance",
  "Create an instance (Instance.new) under parent, set props, return its path. One undo step. " + VALUE_HELP,
  {
    className: z.string(),
    parent: pathSchema,
    props: z.record(z.any()).optional().describe("Properties incl. Name; Parent is applied last"),
    attributes: z.record(z.any()).optional()
  },
  (p) => call("create_instance", p)
);
server.tool(
  "delete_instance",
  "Destroy an instance (undoable with Ctrl+Z). Refuses services and Rojo-synced roots.",
  { path: pathSchema },
  (p) => call("delete_instance", p)
);
server.tool(
  "get_script_source",
  "Read the Source of a Script/LocalScript/ModuleScript, optionally a line range. Prefer reading src/ files on disk for Rojo-managed scripts.",
  {
    path: pathSchema,
    startLine: z.number().int().min(1).optional(),
    endLine: z.number().int().min(1).optional()
  },
  (p) => call("get_script_source", p)
);
server.tool(
  "set_script_source",
  "Replace the Source of a script that is NOT managed by Rojo. Refuses scripts under ReplicatedStorage.Shared, ServerScriptService.Server and StarterPlayer.StarterPlayerScripts.Client (edit src/ on disk instead) unless force=true.",
  { path: pathSchema, source: z.string(), force: z.boolean().optional() },
  (p) => call("set_script_source", p)
);
server.tool(
  "run_luau",
  "Run Luau code in Studio edit mode with plugin permissions (game, plugin APIs). The code is the body of a function: use `return` to send values back. A single expression line is also accepted. Returns {returns, output, error}. Changes are one undo step; on error the changes are rolled back.",
  {
    code: z.string(),
    timeoutSec: z.number().min(1).max(280).optional().describe("Default 30")
  },
  (p) => call("run_luau", { code: p.code }, (p.timeoutSec ?? 30) * 1e3)
);
server.tool("get_selection", "Paths of the instances currently selected in Studio.", {}, (p) => call("get_selection", p));
server.tool(
  "set_selection",
  "Select instances in Studio (empty array clears the selection).",
  { paths: z.array(pathSchema) },
  (p) => call("set_selection", p)
);
server.tool(
  "mount_ui_module",
  "Preview a Figma-exported UI module in Studio without Play: requires a fresh copy of the module (default lookup: StarterPlayer.StarterPlayerScripts.Client.UI.Generated.<name>, then ReplicatedStorage.Shared) and calls it with a preview ScreenGui in StarterGui (cleared first). Returns Root path and Refs.",
  {
    modulePath: pathSchema.describe('Module name ("ShopMenu") or full path'),
    screenGuiName: z.string().optional().describe('Default "FigmaPreview"'),
    solo: z.boolean().optional().describe("Hide (Enabled=false) other ScreenGuis in StarterGui while previewing; unmount restores them")
  },
  (p) => call("mount_ui_module", p)
);
server.tool(
  "unmount_ui_module",
  "Remove a preview ScreenGui created by mount_ui_module and re-enable ScreenGuis hidden by solo.",
  { screenGuiName: z.string().optional() },
  (p) => call("unmount_ui_module", p)
);
server.tool(
  "capture_ui",
  "Screenshot a GUI object as it is drawn in the Studio EDIT viewport (Windows; stop Play first), e.g. to compare with a Figma export. Temporarily makes the target visible, hides its siblings/other ScreenGuis (isolate, default true), grabs the Studio window (PrintWindow, works when Studio is covered), crops to the target and restores everything. Returns the PNG path, size and the DPI scale (screen px per GUI unit). The GUI must be under StarterGui (use mount_ui_module for generated modules).",
  {
    path: pathSchema.describe('GUI path, e.g. "StarterGui.Menus.Shop"'),
    out: z.string().describe("Output .png path (absolute, or relative to the bridge's working dir)"),
    padding: z.number().min(0).max(500).optional().describe("Extra GUI units around the target (default 0)"),
    isolate: z.boolean().optional(),
    background: z.string().optional().describe('Solid backdrop colour behind the ScreenGui, e.g. "#BFE8E0"')
  },
  async (p) => {
    try {
      return text(await captureUi((c, params, t) => client.send(c, params, t), p));
    } catch (e) {
      return { ...text(`Error: ${e.message}`), isError: true };
    }
  }
);
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
var shutdown = async () => {
  await bridge.close();
  process.exit(0);
};
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
process.stdin.on("close", () => {
  if (!HTTP_ONLY) shutdown();
});
main().catch((e) => {
  log(`fatal: ${e.stack}`);
  process.exit(1);
});
//# sourceMappingURL=server.js.map