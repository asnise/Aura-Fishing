// Builds dist/classes.json (ClassName -> { super, props }) from the luau-lsp Roblox definitions.
// The Studio plugin downloads it from GET /classes so get_properties knows which properties exist.
// Usage: node scripts/gen-classes.mjs [path/to/globalTypes.d.luau]
import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const here = dirname(fileURLToPath(import.meta.url));
const defsPath = process.argv[2] || process.env.LUAU_DEFS || "D:/tools/luau-defs/globalTypes.d.luau";
const out = join(here, "..", "dist", "classes.json");

const lines = readFileSync(defsPath, "utf8").split(/\r?\n/);
const classes = {};
let current = null;
let deprecated = false;
const header = /^declare extern type (\w+)(?: extends (\w+))? with/;
const prop = /^\t(\w+): (.+)$/;

for (const line of lines) {
  const h = header.exec(line);
  if (h) {
    const [, name, sup] = h;
    // Skip Enum*, datatypes (no "extends Instance" chain) are filtered after parsing.
    current = name.startsWith("Enum") ? null : { super: sup || null, props: [] };
    if (current) classes[name] = current;
    deprecated = false;
    continue;
  }
  if (!current) continue;
  if (line === "end") { current = null; continue; }
  if (/^\t@deprecated/.test(line)) { deprecated = true; continue; }
  const p = prop.exec(line);
  if (p) {
    const [, name, type] = p;
    if (!deprecated && !type.startsWith("RBXScriptSignal") && !name.startsWith("_")) current.props.push(name);
    deprecated = false;
  } else if (/^\t\S/.test(line)) {
    deprecated = false;
  }
}

// Keep only Instance subclasses.
const isInstance = (n, seen = 0) => n === "Instance" || (classes[n]?.super && seen < 50 && isInstance(classes[n].super, seen + 1));
const result = {};
for (const [n, c] of Object.entries(classes)) if (isInstance(n)) result[n] = c;

mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, JSON.stringify(result));
console.error(`classes.json: ${Object.keys(result).length} classes from ${defsPath}`);
