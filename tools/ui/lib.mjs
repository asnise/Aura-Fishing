// Shared helpers for tools/ui/*.mjs: ship the UI modules from src/ into Studio and run Luau there
// through the StudioBridge plugin (http://127.0.0.1:3060).
import { readFileSync, readdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

export const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
export const uiDir = join(root, "src", "client", "UI");
export const screenNames = () =>
  readdirSync(join(uiDir, "Screens")).filter((f) => f.endsWith(".luau")).map((f) => f.slice(0, -5));

const long = (src) => {
  let eq = "=";
  while (src.includes(`]${eq}]`)) eq += "=";
  return `[${eq}[\n${src}]${eq}]`;
};
const mod = (parent, name, file) =>
  `do local m = Instance.new("ModuleScript") m.Name = ${JSON.stringify(name)} m.Source = ${long(readFileSync(file, "utf8"))} m.Parent = ${parent} end\n`;

// Screens a screen requires (script.Parent.X), so only = [...] can ship just what is needed.
const screenDeps = (name, seen = new Set()) => {
  if (seen.has(name)) return seen;
  seen.add(name);
  const src = readFileSync(join(uiDir, "Screens", `${name}.luau`), "utf8");
  for (const m of src.matchAll(/require\(script\.Parent\.([A-Za-z0-9_]+)\)/g)) {
    if (screenNames().includes(m[1])) screenDeps(m[1], seen);
  }
  return seen;
};

// Luau prelude: `holder` (Folder, destroy at the end), `ui` (UI folder: New, MenuFill, Screens/*), `screens`.
// only = screen names to ship (plus the screens they require); default = every screen. Studio refuses a
// script Source over 200,000 characters, so bake ships only the screens it bakes.
export function modulesPrelude(extra = [], only = null) {
  let code = `local holder = Instance.new("Folder") holder.Name = "_UITool"
local ui = Instance.new("Folder") ui.Name = "UI" ui.Parent = holder
local screens = Instance.new("Folder") screens.Name = "Screens" screens.Parent = ui
`;
  code += mod("ui", "New", join(uiDir, "New.luau"));
  code += mod("ui", "UIAssets", join(root, "src", "shared", "Config", "UIAssets.luau"));
  for (const name of extra) code += mod("ui", name, join(uiDir, `${name}.luau`));
  const wanted = only ? only.reduce((acc, n) => screenDeps(n, acc), new Set()) : new Set(screenNames());
  for (const n of screenNames()) if (wanted.has(n)) code += mod("screens", n, join(uiDir, "Screens", `${n}.luau`));
  return code;
}

export const luaList = (arr) => "{" + arr.map((s) => JSON.stringify(s)).join(", ") + "}";

export async function runLuau(code, timeoutMs = 60000) {
  const r = await fetch("http://127.0.0.1:3060/command", {
    method: "POST",
    headers: { "x-studio-bridge": "1", "Content-Type": "application/json" },
    body: JSON.stringify({ command: "run_luau", params: { code }, timeoutMs }),
  }).catch((e) => {
    console.error("StudioBridge not reachable:", e.message);
    process.exit(5);
  });
  const b = await r.json();
  if (!b.ok) {
    console.error("studio error:", b.error);
    process.exit(1);
  }
  const res = b.result;
  if (res.output?.length) console.log(res.output.map((o) => o.text ?? o.message ?? JSON.stringify(o)).join("\n"));
  if (res.error) {
    console.error("luau error:", res.error);
    process.exit(1);
  }
  return res.returns?.[0];
}
