import assert from "node:assert/strict";
import { copyFile, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { ToolListChangedNotificationSchema } from "@modelcontextprotocol/sdk/types.js";

const root = await mkdtemp(join(process.cwd(), ".mcp-live-test-"));
const worker = join(root, "dist", "server.js");
const stamp = join(root, "dist", ".mcp-reload");
const entered = join(root, "entered");
const launcher = join(root, "scripts", "mcp-live.mjs");
const client = new Client({ name: "hot-reload-smoke", version: "1" });
let notifications = 0;
const toolText = (text) => ({ content: [{ type: "text", text }] });
client.setNotificationHandler(ToolListChangedNotificationSchema, () => { notifications++; });

function version(name) {
  return `
import { writeFile } from "node:fs/promises";
import { setTimeout as delay } from "node:timers/promises";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
const server = new McpServer({ name: "fixture", version: "1" });
let channel = process.argv.find(arg => arg.startsWith("--channel="))?.slice(10);
const text = text => ({ content: [{ type: "text", text }] });
server.tool("join_channel", { channel: z.string() }, ({ channel: target }) => {
  channel = target;
  return text("Successfully joined channel: " + target);
});
server.tool(${JSON.stringify(name)}, {}, () => text(channel || "missing"));
server.tool("slow", {}, async () => {
  await writeFile(${JSON.stringify(entered)}, "started");
  await delay(850);
  return text(${JSON.stringify(name)});
});
await server.connect(new StdioServerTransport());
`;
}

async function waitFor(predicate) {
  const deadline = Date.now() + 6000;
  while (!(await predicate())) {
    assert.ok(Date.now() < deadline, "Timed out waiting for the rebuilt tool list");
    await delay(50);
  }
}

try {
  await mkdir(join(root, "dist"));
  await mkdir(join(root, "scripts"));
  await writeFile(worker, version("before"));
  await copyFile("scripts/mcp-live.mjs", launcher);
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [launcher],
    stderr: "pipe",
  });
  let stderr = "";
  transport.stderr.on("data", (chunk) => { stderr += chunk; });
  await client.connect(transport);
  assert.ok((await client.listTools()).tools.some(({ name }) => name === "before"));
  assert.deepEqual(await client.callTool({ name: "join_channel", arguments: { channel: "test-channel" } }), toolText("Successfully joined channel: test-channel"));
  const slow = client.callTool({ name: "slow", arguments: {} });
  await waitFor(() => readFile(entered, "utf8").then(() => true, () => false));
  await writeFile(worker, version("after"));
  await writeFile(stamp, "second build");
  assert.deepEqual(await slow, toolText("before"));
  await waitFor(() => notifications === 1);
  const names = (await client.listTools()).tools.map(({ name }) => name);
  assert.ok(names.includes("after") && !names.includes("before"));
  assert.deepEqual(await client.callTool({ name: "after", arguments: {} }), toolText("test-channel"));
  await writeFile(worker, "throw new Error('broken test candidate');");
  await writeFile(stamp, "broken build");
  await waitFor(() => stderr.includes("[mcp-live]"));
  assert.deepEqual(await client.callTool({ name: "after", arguments: {} }), toolText("test-channel"));
  assert.equal(notifications, 1);
  console.log("Client kept its connection, drained the old request, loaded the new tool with the same channel, and kept serving after a failed reload.");
} finally {
  await client.close();
  await rm(root, { recursive: true, force: true });
}
