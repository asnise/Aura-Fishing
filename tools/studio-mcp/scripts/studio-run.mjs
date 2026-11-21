// Send one command to Studio through the running bridge (http://127.0.0.1:3060) and print the result.
// Usage: node scripts/studio-run.mjs <command> [params.json | '{"inline":"json"}'] [--timeout=30] [--port=3060]
//        node scripts/studio-run.mjs --status
// The bridge must be running: either an MCP client started dist/server.js, or `node dist/server.js --http-only`.
import { readFileSync, existsSync } from "fs";

const args = process.argv.slice(2);
const flag = (n) => args.find((a) => a.startsWith(`--${n}=`))?.slice(n.length + 3);
const port = Number(flag("port") || 3060);
const timeoutSec = Number(flag("timeout") || 30);
const positional = args.filter((a) => !a.startsWith("--"));
const H = { "x-studio-bridge": "1", "Content-Type": "application/json" };
const base = `http://127.0.0.1:${port}`;

try {
  if (args.includes("--status")) {
    console.log(JSON.stringify(await (await fetch(`${base}/status`, { headers: H })).json(), null, 1));
    process.exit(0);
  }
  const [command, p] = positional;
  if (!command) {
    console.error("usage: studio-run.mjs <command> [params.json|json] [--timeout=30]");
    process.exit(2);
  }
  const params = !p ? {} : existsSync(p) ? JSON.parse(readFileSync(p, "utf8")) : JSON.parse(p);
  const r = await fetch(`${base}/command`, {
    method: "POST",
    headers: H,
    body: JSON.stringify({ command, params, timeoutMs: timeoutSec * 1000 }),
  });
  const body = await r.json();
  if (!body.ok) {
    console.error("studio error:", body.error);
    process.exit(1);
  }
  console.log(JSON.stringify(body.result, null, 1));
} catch (e) {
  console.error("bridge not reachable:", e.cause?.code || e.message, "(start: node dist/server.js --http-only)");
  process.exit(5);
}
