// Command registry + dispatcher. Builds one name -> handler map from all
// command groups and fails loudly on duplicate names at plugin start.
// @stability stable (core) - shared by many commands

import { COMMAND_GROUPS } from "../commands/index.js";

const handlers = new Map();
const groupOf = new Map();

for (const [group, commands] of Object.entries(COMMAND_GROUPS)) {
  for (const [name, handler] of Object.entries(commands)) {
    if (handlers.has(name)) {
      throw new Error(`Duplicate command "${name}" in groups "${groupOf.get(name)}" and "${group}"`);
    }
    if (typeof handler !== "function") {
      throw new Error(`Command "${name}" in group "${group}" is not a function`);
    }
    handlers.set(name, handler);
    groupOf.set(name, group);
  }
}

export function listCommands() {
  return [...handlers.keys()].sort();
}

// Built-in: what this plugin build can do, grouped (for agents and scripts/plugin-smoke.mjs)
handlers.set("list_commands", () => {
  const groups = {};
  for (const [name, group] of groupOf) (groups[group] ||= []).push(name);
  return { count: groupOf.size, groups };
});

// "$N.path" in a batch item's params = value from the result of item N (0-based),
// e.g. { command: "create_frame" } then { command: "set_fill_color", params: { nodeId: "$0.id" } }.
// Only whole-string values are replaced.
const REF = /^\$(\d+)((?:\.[A-Za-z0-9_]+)*)$/;

export function resolveRefs(value, results) {
  if (typeof value === "string") {
    const m = REF.exec(value);
    if (!m) return value;
    const item = results[Number(m[1])];
    if (!item) throw new Error(`${value}: there is no item ${m[1]} before this one`);
    if (!item.ok) throw new Error(`${value}: item ${m[1]} (${item.command}) failed`);
    let v = item.result;
    for (const key of m[2].split(".").slice(1)) {
      if (v === null || v === undefined) break;
      v = v[key];
    }
    if (v === undefined) throw new Error(`${value}: not found in the result of item ${m[1]} (${item.command})`);
    return v;
  }
  if (Array.isArray(value)) return value.map((v) => resolveRefs(v, results));
  if (value && typeof value === "object") {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = resolveRefs(v, results);
    return out;
  }
  return value;
}

// Built-in: run many commands in ONE round trip (each relay hop costs ~150 ms).
// params: { commands: [{ command, params }], stopOnError?: boolean, brief?: boolean }
// result: { ok, failed, results: [{ command, ok, ms, result | error }] }
// brief: true drops each item's result (only ok/ms/error) to keep the answer small.
handlers.set("batch", async (params) => {
  const list = params && params.commands;
  if (!Array.isArray(list)) throw new Error("batch needs commands: [{ command, params }]");
  const results = [];
  let failed = 0;
  for (const item of list) {
    const name = item && item.command;
    const t = Date.now();
    try {
      if (name === "batch") throw new Error("batch cannot contain batch");
      const itemParams = resolveRefs((item && item.params) || {}, results);
      const result = await handleCommand(name, itemParams);
      results.push({ command: name, ok: true, ms: Date.now() - t, result });
    } catch (error) {
      failed++;
      results.push({ command: name, ok: false, ms: Date.now() - t, error: error.message || String(error) });
      if (params.stopOnError) break;
    }
  }
  if (params.brief) for (const r of results) delete r.result;
  return { ok: results.length - failed, failed, results };
});

groupOf.set("batch", "builtin");
groupOf.set("list_commands", "builtin");

// Closest command names for an unknown one (shared words, e.g. "get_node" -> get_node_info)
function suggest(name) {
  const words = String(name || "").toLowerCase().split(/[_\s]+/).filter((w) => w.length > 2);
  const scored = [...handlers.keys()]
    .map((n) => [n, words.filter((w) => n.includes(w)).length])
    .filter(([, s]) => s > 0)
    .sort((a, b) => b[1] - a[1]);
  return scored.slice(0, 5).map(([n]) => n);
}

const NOT_FOUND_HINT = " (get a valid id from get_selection or find_nodes)";

export async function handleCommand(command, params) {
  const handler = handlers.get(command);
  if (!handler) {
    const near = suggest(command);
    throw new Error(`Unknown command: ${command}.${near.length ? " Did you mean: " + near.join(", ") + "?" : ""} list_commands shows all.`);
  }
  // _agent is only for the relay's usage counter (src/usage/tracker.ts)
  if (params && typeof params === "object" && "_agent" in params) {
    params = Object.assign({}, params);
    delete params._agent;
  }
  try {
    return await handler(params);
  } catch (error) {
    const msg = (error && error.message) || String(error);
    if (/not found/i.test(msg) && !msg.includes("find_nodes")) throw new Error(msg + NOT_FOUND_HINT);
    throw error;
  }
}
