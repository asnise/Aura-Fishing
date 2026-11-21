// Smoke test for the built Figma plugin (code.js) without Figma: loads the
// bundle with a mock `figma` global, then checks the command registry.
// Usage: node scripts/plugin-smoke.mjs        (run after bun run build:plugin)
// Fails (exit 1) if the bundle does not load, a command the MCP server sends is
// missing from the plugin, or the dispatcher misbehaves.
import { readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import vm from "vm";
import { formatHandoff } from "../src/cursor_mcp_plugin/ui/src/handoff.js";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const code = readFileSync(join(root, "src/cursor_mcp_plugin/code.js"), "utf8");

const posted = [];
let onmessage = null;
const figma = {
  showUI() {},
  ui: {
    postMessage: (m) => posted.push(m),
    set onmessage(f) { onmessage = f; },
    get onmessage() { return onmessage; },
  },
  on() {},
  notify() {},
  clientStorage: { getAsync: async () => null, setAsync: async () => {} },
  mixed: Symbol("mixed"),
};
// one selected node with a parent frame, plugin data in a Map
const pluginData = new Map();
const page = { id: "0:1", name: "Page 1", type: "PAGE" };
const frame = { id: "1:1", name: "Shop", type: "FRAME", parent: page, children: [] };
const icon = {
  id: "1:2", name: "Coin", type: "RECTANGLE", visible: true, parent: frame, width: 32.4, height: 32,
  fills: [{ type: "IMAGE", imageHash: "abc" }],
  getPluginData: (k) => pluginData.get(k) || "",
  setPluginData: (k, v) => pluginData.set(k, v),
};
frame.children.push(icon);
Object.assign(frame, { x: 10, y: 20, width: 200, height: 100, visible: true, fills: [{ type: "SOLID", color: { r: 1, g: 1, b: 1 }, opacity: 1 }], layoutMode: "NONE",
  getPluginData: () => "", setPluginData() {} });
Object.assign(icon, { x: 4, y: 5 });
const all = [frame, icon];
figma.currentPage = {
  id: "0:1", name: "Page 1", type: "PAGE", selection: [icon], children: [frame],
  findAll: (fn) => all.filter((n) => !fn || fn(n)),
  findAllWithCriteria: ({ types }) => all.filter((n) => types.includes(n.type)),
};
let undoCommits = 0;
figma.commitUndo = () => undoCommits++;
figma.getNodeByIdAsync = async (id) => all.find((n) => n.id === id) || null;
figma.viewport = { scrollAndZoomIntoView() {} };
vm.runInNewContext(code, { figma, __html__: "", console, setTimeout, Promise, Map, Set, Symbol, Date, Math, JSON, Object, Array, Error });

async function run(command, params) {
  const id = String(posted.length + 1);
  await onmessage({ type: "execute-command", id, command, params });
  return posted.find((m) => m.id === id);
}

let failed = 0;
const check = (ok, msg) => { console.log(`${ok ? "ok  " : "FAIL"} ${msg}`); if (!ok) failed++; };

const list = await run("list_commands", {});
check(list && list.type === "command-result", "list_commands answers");
const names = new Set(Object.values(list.result.groups).flat());
console.log(`     ${list.result.count} commands in ${Object.keys(list.result.groups).length} groups`);

const server = readFileSync(join(root, "src/talk_to_figma_mcp/server.ts"), "utf8");
const sent = new Set([...server.matchAll(/sendCommandToFigma\(\s*"([a-z_]+)"/g)].map((m) => m[1]));
sent.delete("join"); // handled by the relay
const missing = [...sent].filter((n) => !names.has(n));
check(missing.length === 0, `every command server.ts sends exists in the plugin${missing.length ? ": missing " + missing.join(", ") : ""}`);

const unknown = await run("no_such_command", {});
check(unknown.type === "command-error" && /Unknown command/.test(unknown.error), "unknown command -> error");

const bad = await run("get_node_info", { _agent: "smoke" });
check(bad.type === "command-error" && bad.error === "Missing nodeId parameter", "param validation still works");

const batch = await run("batch", { commands: [{ command: "list_commands" }, { command: "no_such_command" }, { command: "batch" }] });
check(batch.type === "command-result" && batch.result.ok === 1 && batch.result.failed === 2, "batch runs items, reports per-item errors");

const boot = posted.find((m) => m.type === "selection");
check(boot && boot.data.selection[0].id === "1:2", "selection is pushed to the UI at start");

const noted = await run("set_node_note", { nodeId: "1:2", note: "coin icon, opens shop" });
const sel = await run("get_selection", {});
const s0 = sel.result.selection[0];
check(noted.type === "command-result" && s0.note === "coin icon, opens shop" && s0.path === "Shop" && s0.image && s0.size.w === 32,
  "get_selection returns note, path, size, image flag");

// --- Phase 1: compact reads, find_nodes, batch refs, errors, undo ---
const c1 = await run("get_node_info", { nodeId: "1:1", depth: 1 });
const k = c1.result && c1.result.children && c1.result.children[0];
check(c1.type === "command-result" && c1.result.fill === "#ffffff" && c1.result.w === 200 && k && k.fill === "image" && k.w === 32.4 && k.note === "coin icon, opens shop" && c1.result.nodeCount === 2,
  "get_node_info compact (depth 1): fill hex, box, image fill, note");
const c0 = await run("get_node_info", { nodeId: "1:1", depth: 0, fields: ["box"] });
check(c0.result.childCount === 1 && !c0.result.children && c0.result.fill === undefined, "compact depth 0 + fields: childCount only, no fill");
const ci = await run("get_nodes_info", { nodeIds: ["1:2", "9:9"], depth: 0 });
check(Array.isArray(ci.result) && ci.result[0].id === "1:2" && ci.result[1].error, "get_nodes_info compact, missing id reported per item");

const f = await run("find_nodes", { name: "coin" });
check(f.type === "command-result" && f.result.count === 1 && f.result.nodes[0].id === "1:2" && f.result.nodes[0].path === "Shop", "find_nodes by name");
const ft = await run("find_nodes", { type: ["FRAME"] });
check(ft.result.count === 1 && ft.result.nodes[0].id === "1:1", "find_nodes by type");
const fe = await run("find_nodes", {});
check(fe.type === "command-error", "find_nodes without filters -> error");

const ref = await run("batch", { commands: [
  { command: "get_selection" },
  { command: "get_node_note", params: { nodeId: "$0.selection.0.id" } },
  { command: "get_node_note", params: { nodeId: "$9.id" } },
] });
check(ref.result.results[1].ok && ref.result.results[1].result.id === "1:2" && !ref.result.results[2].ok, "batch \$N.path references (and bad reference fails)");
const brief = await run("batch", { brief: true, commands: [{ command: "get_selection" }] });
check(brief.result.ok === 1 && brief.result.results[0].result === undefined, "batch brief drops results");

const near = await run("get_node", {});
check(/Did you mean: .*get_node_info/.test(near.error), "unknown command suggests close names");
const nf = await run("get_node_note", { nodeId: "9:9" });
check(/not found/i.test(nf.error) && /find_nodes/.test(nf.error), "node not found error has a hint");
check(undoCommits > 0, "commitUndo after each command");

let timelineDuration = 1;
icon.manualKeyframeTracks = { ROTATION: { keyframes: [] } };
Object.defineProperty(icon, "timelines", {
  get: () => [{ id: "1:1", duration: timelineDuration }],
});
icon.setTimelineDuration = (id, duration) => {
  if (id !== frame.id) throw new Error("Wrong timeline");
  timelineDuration = duration;
};
icon.applyManualKeyframeTrack = (field, track) => {
  if (field.type !== "PROPERTY") throw new Error("Expected a property track");
  icon.manualKeyframeTracks[field.name] = track;
};
const scale = {
  property: "SCALE_XY",
  keyframes: [{ time: 0, value: 0 }, { time: 1.2, value: 10, easing: "EASE_OUT" }],
};
const motion = await run("motion_keyframes", { nodeId: icon.id, tracks: [scale], duration: 2 });
const readMotion = await run("motion_keyframes", { nodeId: icon.id });
check(motion.type === "command-result" && readMotion.result?.timelines[0].duration === 2 &&
  readMotion.result?.tracks.ROTATION && readMotion.result?.tracks.SCALE_XY?.keyframes[1].timelinePosition === 1.2 &&
  readMotion.result?.tracks.SCALE_XY?.keyframes[1].value.value.y === 10 &&
  readMotion.result?.tracks.SCALE_XY?.keyframes[1].easing.type === "EASE_OUT",
  "motion_keyframes writes and reads native scale keys, extends the timeline, and keeps unrelated tracks");
const invalidMotion = await run("motion_keyframes", { nodeId: icon.id, tracks: [scale, {
  property: "OPACITY", keyframes: [{ time: 1, value: 0 }, { time: 0, value: 1 }],
}] });
check(invalidMotion.type === "command-error" && /increasing/.test(invalidMotion.error),
  "motion_keyframes rejects non-increasing keyframe times");
const missingMotion = await run("motion_keyframes", { nodeId: frame.id });
check(missingMotion.type === "command-error" && /Motion API/.test(missingMotion.error),
  "motion_keyframes reports unavailable Motion APIs");

frame.exportAsync = async ({ format, fps, constraint }) => {
  if (format !== "MP4" || fps !== 24 || constraint.type !== "WIDTH" || constraint.value !== 960) {
    throw new Error("Expected native MP4 export settings");
  }
  return Uint8Array.of(1, 2, 3);
};
const video = await run("export_motion_video", { nodeId: frame.id });
check(video.result?.videoData === "AQID" && video.result.mimeType === "video/mp4",
  "export_motion_video encodes the native MP4 for the relay");

await onmessage({ type: "workbench-read", view: "motion", nodeId: icon.id, request: 7 });
const motionRead = posted.find((message) => message.type === "workbench-result" && message.request === 7);
check(motionRead?.result?.tracks?.SCALE_XY?.keyframes[1].value.value.x === 10,
  "Workbench can read the selected layer's Motion tracks locally");
await onmessage({ type: "workbench-read", view: "layer", nodeId: icon.id, request: 8 });
check(posted.find((message) => message.type === "workbench-result" && message.request === 8)?.result?.id === icon.id,
  "Workbench inspects the selected node");
await onmessage({ type: "workbench-read", view: "commands", request: 9 });
check(posted.find((message) => message.type === "workbench-result" && message.request === 9)?.result?.groups.motion.includes("motion_keyframes"),
  "Workbench lists the installed commands");
const handoff = formatHandoff({
  channel: "aura-fishing", selection: sel.result, mode: "motion", task: "Retiming", done: "Preserve the original",
});
check(["aura-fishing", "Page 1 (0:1)", "Coin (1:2)", "coin icon, opens shop", "Retiming", 'motion_keyframes({"nodeId":"1:2"})', "Preserve the original"]
  .every((value) => handoff.includes(value)), "Agent Handoff combines selection, note, task, workflow and constraints");
const ui = readFileSync(join(root, "src/cursor_mcp_plugin/ui.html"), "utf8");
check(["tab-workbench", "content-workbench", "tab-agent-handoff", "content-agent-handoff"].every((id) => ui.includes(`id="${id}"`)),
  "Bundled plugin UI contains Workbench and Agent Handoff tabs");

process.exit(failed ? 1 : 0);
