// Print the usage counters as tables (most used first).
// Usage: node scripts/usage-report.mjs [--top=30] [--dir=usage] [--json]
// Data is written automatically by the relay (plugin-commands.json) and the
// MCP server (mcp-tools.json); see src/usage/tracker.ts.
import { existsSync, readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const args = process.argv.slice(2);
const flag = (n) => { const a = args.find((x) => x.startsWith(`--${n}=`)); return a ? a.slice(n.length + 3) : undefined; };
const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const dir = flag("dir") || process.env.FIGMA_USAGE_DIR || join(root, "usage");
const top = Number(flag("top") || 30);

const files = [
  ["MCP tools (server.ts)", "mcp-tools.json"],
  ["Plugin commands (relay, any caller)", "plugin-commands.json"],
];

const out = {};
for (const [title, name] of files) {
  const p = join(dir, name);
  if (!existsSync(p)) {
    console.log(`\n== ${title}: no data yet (${p})`);
    continue;
  }
  const data = JSON.parse(readFileSync(p, "utf8"));
  out[name] = data;
  if (args.includes("--json")) continue;
  const rows = Object.entries(data.items).sort((a, b) => b[1].calls - a[1].calls).slice(0, top);
  console.log(`\n== ${title}  (updated ${data.updatedAt})`);
  console.log(`   total ${data.totals.calls} calls, ${data.totals.errors} errors`);
  console.log(`   by agent: ${Object.entries(data.byAgent).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k}=${v}`).join("  ")}`);
  const w = Math.max(10, ...rows.map(([n]) => n.length));
  console.log(`   ${"name".padEnd(w)}  ${"calls".padStart(6)}  ${"err".padStart(4)}  ${"avgMs".padStart(6)}  ${"avgKB".padStart(7)}  last used`);
  for (const [n, it] of rows) {
    console.log(`   ${n.padEnd(w)}  ${String(it.calls).padStart(6)}  ${String(it.errors).padStart(4)}  ${String(it.avgMs).padStart(6)}  ${String(it.avgKB ?? "-").padStart(7)}  ${it.lastUsed.slice(0, 16).replace("T", " ")}`);
  }
}
if (args.includes("--json")) console.log(JSON.stringify(out, null, 2));
