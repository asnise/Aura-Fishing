import { watchFile, unwatchFile } from "node:fs";
import { fileURLToPath } from "node:url";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema, CallToolResultSchema, CompleteRequestSchema, CompleteResultSchema,
  GetPromptRequestSchema, GetPromptResultSchema, ListPromptsRequestSchema, ListPromptsResultSchema,
  ListToolsRequestSchema, ListToolsResultSchema,
} from "@modelcontextprotocol/sdk/types.js";

const workerPath = fileURLToPath(new URL("../dist/server.js", import.meta.url));
const stamp = fileURLToPath(new URL("../dist/.mcp-reload", import.meta.url));
const args = process.argv.slice(2);
const host = new Server({ name: "TalkToFigmaMCP", version: "1.0.0" }, {
  capabilities: { tools: { listChanged: true }, prompts: { listChanged: true } },
});
let worker;
let candidate;
let joinedChannel;
let inFlight = 0;
let drained;
let reloading;
let reloadRequested = false;
let closed = false;
let lastError;
const log = (error) => console.error("[mcp-live]", error.message ?? error);

async function replaceWorkers() {
  while (reloadRequested && !closed) {
    reloadRequested = false;
    if (inFlight) await new Promise((resolve) => { drained = resolve; });
    if (closed) break;

    const next = new Client(host.getClientVersion() ?? { name: "figma-mcp", version: "1.0.0" });
    candidate = next;
    try {
      const workerArgs = joinedChannel
        ? [`--channel=${joinedChannel}`, ...args.filter((arg) => !arg.startsWith("--channel="))]
        : args;
      await next.connect(new StdioClientTransport({
        command: process.execPath,
        args: [workerPath, "--reload-worker", ...workerArgs],
        env: process.env,
      }), { timeout: 10000 });
    } catch (error) {
      lastError = error;
      log(error);
      await next.close().catch(log);
      continue;
    } finally {
      candidate = undefined;
    }
    if (closed) {
      await next.close().catch(log);
      break;
    }

    const old = worker;
    worker = next;
    lastError = undefined;
    next.onclose = () => { if (worker === next) worker = undefined; };
    if (old) {
      await old.close().catch(log);
      await Promise.all([host.sendToolListChanged(), host.sendPromptListChanged()]).catch(log);
    }
  }
}

function reload() {
  if (closed) return;
  reloadRequested = true;
  reloading ??= replaceWorkers().finally(() => { reloading = undefined; });
}

for (const [schema, resultSchema] of [
  [ListToolsRequestSchema, ListToolsResultSchema],
  [CallToolRequestSchema, CallToolResultSchema],
  [ListPromptsRequestSchema, ListPromptsResultSchema],
  [GetPromptRequestSchema, GetPromptResultSchema],
  [CompleteRequestSchema, CompleteResultSchema],
]) {
  host.setRequestHandler(schema, async (request, { signal }) => {
    if (!worker && !reloading) reload();
    while (reloading) await reloading;
    if (signal.aborted) throw signal.reason;
    if (!worker) throw lastError ?? new Error("Figma MCP worker is unavailable");
    inFlight++;
    try {
      const result = await worker.request(request, resultSchema, { timeout: 180000 });
      if (request.method === "tools/call" && request.params.name === "join_channel" &&
          result.content?.[0]?.text === `Successfully joined channel: ${request.params.arguments?.channel}`) {
        joinedChannel = request.params.arguments.channel;
      }
      return result;
    } finally {
      if (--inFlight === 0 && drained) {
        drained();
        drained = undefined;
      }
    }
  });
}

host.oninitialized = () => {
  reload();
  watchFile(stamp, { interval: 350, persistent: false }, (current, previous) => {
    if (current.mtimeMs && current.mtimeMs !== previous.mtimeMs) reload();
  });
};
function close() {
  closed = true;
  unwatchFile(stamp);
  drained?.();
  void worker?.close().catch(log);
  void candidate?.close().catch(log);
}
host.onclose = close;
process.stdin.once("end", close);
await host.connect(new StdioServerTransport());
