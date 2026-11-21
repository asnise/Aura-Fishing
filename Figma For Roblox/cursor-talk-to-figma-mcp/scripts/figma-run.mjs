// Send one command to the Figma plugin through the local relay (ws://localhost:3055).
// Usage: node scripts/figma-run.mjs --channel=<name> <command> [params.json] [--out=file] [--timeout=120] [--agent=<who>]
// --agent (or env FIGMA_AGENT) names the caller in usage/plugin-commands.json (default "figma-run").
// Prints JSON. With --out, imageData or videoData is saved to a file. --png still saves PNGs.
import WebSocket from "ws";
import { readFileSync, writeFileSync } from "fs";
import { randomUUID } from "crypto";

const args = process.argv.slice(2);
const flag = (n) => { const a = args.find(x => x.startsWith(`--${n}=`)); return a ? a.slice(n.length + 3) : undefined; };
const positional = args.filter(a => !a.startsWith("--"));
const channel = flag("channel");
const png = flag("png");
const outFile = flag("out");
const timeoutSec = Number(flag("timeout") || 120);
const agent = flag("agent") || process.env.FIGMA_AGENT || "figma-run";
const [command, paramsFile] = positional;
if (!channel || !command) {
  console.error("usage: figma-run.mjs --channel=<name> <command> [params.json] [--out=file]");
  process.exit(2);
}
const params = paramsFile ? JSON.parse(readFileSync(paramsFile, "utf8")) : {};

const ws = new WebSocket("ws://localhost:3055");
const joinId = randomUUID();
const cmdId = randomUUID();
const timer = setTimeout(() => { console.error(`timeout after ${timeoutSec}s`); process.exit(3); }, timeoutSec * 1000);

ws.on("open", () => {
  ws.send(JSON.stringify({ id: joinId, type: "join", channel, agent }));
});
ws.on("message", (raw) => {
  let msg;
  try { msg = JSON.parse(raw.toString()); } catch { return; }
  const m = msg.message;
  if (msg.type === "system" && m && m.id === joinId) {
    ws.send(JSON.stringify({ id: cmdId, type: "message", channel, message: { id: cmdId, command, params: { ...params, commandId: cmdId, _agent: agent } } }));
    return;
  }
  if (msg.type === "error") { console.error("relay error:", msg.message); process.exit(4); }
  if (m && m.id === cmdId && (m.result !== undefined || m.error !== undefined)) {
    clearTimeout(timer);
    if (m.error) { console.error("figma error:", m.error); ws.close(); process.exit(1); }
    let result = m.result;
    if (outFile && (result?.videoData || result?.imageData)) {
      writeFileSync(outFile, Buffer.from(result.videoData || result.imageData, "base64"));
      result = { savedFile: outFile, mimeType: result.mimeType };
    } else if (png && result && result.imageData) {
      writeFileSync(png, Buffer.from(result.imageData, "base64"));
      result = { savedPng: png, mimeType: result.mimeType };
    }
    console.log(JSON.stringify(result, null, 1));
    ws.close();
    process.exit(0);
  }
});
ws.on("error", (e) => { console.error("ws error:", e.message, "(is scripts\\figma-relay.bat running?)"); process.exit(5); });
