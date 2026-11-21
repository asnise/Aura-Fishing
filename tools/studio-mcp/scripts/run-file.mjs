// Run a .luau file in Studio through the bridge (run_luau). Usage: node scripts/run-file.mjs <file.luau> [--timeout=120]
import { readFileSync } from "fs";
const file = process.argv[2];
const timeoutSec = Number(process.argv.find((a) => a.startsWith("--timeout="))?.slice(10) || 120);
if (!file) { console.error("usage: run-file.mjs <file.luau>"); process.exit(2); }
const r = await fetch("http://127.0.0.1:3060/command", {
  method: "POST",
  headers: { "x-studio-bridge": "1", "Content-Type": "application/json" },
  body: JSON.stringify({ command: "run_luau", params: { code: readFileSync(file, "utf8") }, timeoutMs: timeoutSec * 1000 }),
}).catch((e) => { console.error("bridge not reachable:", e.message); process.exit(5); });
const b = await r.json();
if (!b.ok) { console.error("studio error:", b.error); process.exit(1); }
console.log(JSON.stringify(b.result, null, 1));
process.exit(b.result.error ? 1 : 0);
