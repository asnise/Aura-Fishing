// Screenshot a GUI object from the Studio edit viewport (Windows).
// Usage: node scripts/capture.mjs <guiPath> <out.png> [--padding=0] [--no-isolate] [--background=#RRGGBB] [--method=auto|print|screen] [--port=3060]
// Example: node scripts/capture.mjs StarterGui.Menus.Shop shots/shop.png --padding=8
// Prints JSON: { out, size, scale, guiRect, viewport, ... }. Needs the bridge running (Claude's StudioBridge MCP or --http-only).
import { captureUi } from "../dist/capture.js";

const args = process.argv.slice(2);
const flag = (n) => args.find((a) => a.startsWith(`--${n}=`))?.slice(n.length + 3);
const [path, out] = args.filter((a) => !a.startsWith("--"));
if (!path || !out) {
  console.error("usage: capture.mjs <guiPath> <out.png> [--padding=0] [--no-isolate] [--background=#RRGGBB] [--method=auto|print|screen]");
  process.exit(2);
}
const port = Number(flag("port") || 3060);

async function send(command, params, timeoutMs = 30000) {
  const r = await fetch(`http://127.0.0.1:${port}/command`, {
    method: "POST",
    headers: { "x-studio-bridge": "1", "Content-Type": "application/json" },
    body: JSON.stringify({ command, params, timeoutMs }),
  });
  const b = await r.json();
  if (!b.ok) throw new Error(b.error);
  return b.result;
}

try {
  const result = await captureUi(send, {
    path,
    out,
    padding: Number(flag("padding") || 0),
    isolate: !args.includes("--no-isolate"),
    background: flag("background"),
    method: flag("method"),
  });
  console.log(JSON.stringify(result, null, 1));
} catch (e) {
  console.error("capture failed:", e.cause?.code === "ECONNREFUSED" ? "bridge not running (node dist/server.js --http-only)" : e.message);
  process.exit(1);
}
