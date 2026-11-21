#!/usr/bin/env bun

import { Server, ServerWebSocket } from "bun";
import * as path from "path";
import { createUsageTracker, resolveUsageDir } from "./usage/tracker";

// Usage counter: every command that passes through the relay to the Figma
// plugin (from the MCP server, scripts/figma-run.mjs, python tools, ...).
// Agent = params._agent, else the "agent" sent with "join", else "unknown".
const usage = createUsageTracker(
  path.join(resolveUsageDir(path.resolve(import.meta.dir, "..")), "plugin-commands.json"),
  "plugin-commands"
);
const connectionAgent = new WeakMap<object, string>();
const inFlight = new Map<string, { command: string; agent: string; t: number }>();
const IN_FLIGHT_TTL_MS = 10 * 60 * 1000;
const VERBOSE = process.env.RELAY_VERBOSE === "1";

function trackUsage(ws: ServerWebSocket<any>, data: any, bytes?: number) {
  const msg = data && data.message;
  if (!msg || typeof msg !== "object") return;
  if (data.type === "message" && typeof msg.command === "string") {
    const agent = (msg.params && msg.params._agent) || connectionAgent.get(ws) || "unknown";
    inFlight.set(String(msg.id ?? data.id), { command: msg.command, agent: String(agent), t: Date.now() });
    return;
  }
  const id = msg.id !== undefined ? String(msg.id) : undefined;
  if (id && inFlight.has(id) && (msg.result !== undefined || msg.error !== undefined)) {
    const req = inFlight.get(id)!;
    inFlight.delete(id);
    usage.record(req.command, req.agent, !msg.error, Date.now() - req.t, msg.error, bytes);
    // batch: also count each inner command (name, ok, ms come back in the result)
    if (req.command === "batch" && msg.result && Array.isArray(msg.result.results)) {
      for (const r of msg.result.results) {
        if (r && typeof r.command === "string") usage.record(r.command, req.agent, !!r.ok, r.ms || 0, r.error);
      }
    }
  }
}

// Requests that never got an answer count as errors ("timeout")
setInterval(() => {
  const now = Date.now();
  for (const [id, req] of inFlight) {
    if (now - req.t > IN_FLIGHT_TTL_MS) {
      inFlight.delete(id);
      usage.record(req.command, req.agent, false, now - req.t, "timeout (no response)");
    }
  }
}, 60 * 1000);

// Store clients by channel
const channels = new Map<string, Set<ServerWebSocket<any>>>();

function handleConnection(ws: ServerWebSocket<any>) {
  // Don't add to clients immediately - wait for channel join
  console.log("New client connected");

  // Send welcome message to the new client
  ws.send(JSON.stringify({
    type: "system",
    message: "Please join a channel to start chatting",
  }));

  ws.close = () => {
    console.log("Client disconnected");

    // Remove client from their channel
    channels.forEach((clients, channelName) => {
      if (clients.has(ws)) {
        clients.delete(ws);

        // Notify other clients in same channel
        clients.forEach((client) => {
          if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({
              type: "system",
              message: "A user has left the channel",
              channel: channelName
            }));
          }
        });
      }
    });
  };
}

const server = Bun.serve({
  port: Number(process.env.PORT) || 3055,
  // uncomment this to allow connections in windows wsl
  // hostname: "0.0.0.0",
  fetch(req: Request, server: Server) {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    // Handle WebSocket upgrade
    const success = server.upgrade(req, {
      headers: {
        "Access-Control-Allow-Origin": "*",
      },
    });

    if (success) {
      return; // Upgraded to WebSocket
    }

    // Return response for non-WebSocket requests
    return new Response("WebSocket server running", {
      headers: {
        "Access-Control-Allow-Origin": "*",
      },
    });
  },
  websocket: {
    open: handleConnection,
    message(ws: ServerWebSocket<any>, message: string | Buffer) {
      try {
        const text = typeof message === "string" ? message : message.toString();
        const data = JSON.parse(text);
        trackUsage(ws, data, text.length);
        // One line per message. RELAY_VERBOSE=1 prints full JSON (slow with base64 images).
        if (data.message?.command) {
          console.log(`-> ${data.message.command} [${data.channel}] ${String(data.id).slice(0, 8)}`);
        } else if (data.message && (data.message.result !== undefined || data.message.error !== undefined)) {
          console.log(`<- ${data.message.error ? "error" : "result"} ${String(data.id).slice(0, 8)} ${(text.length / 1024).toFixed(1)} KB`);
        }
        if (VERBOSE) console.log(`Full message:`, JSON.stringify(data, null, 2));

        if (data.type === "join") {
          const channelName = data.channel;
          if (!channelName || typeof channelName !== "string") {
            ws.send(JSON.stringify({
              type: "error",
              message: "Channel name is required"
            }));
            return;
          }

          // Create channel if it doesn't exist
          if (!channels.has(channelName)) {
            channels.set(channelName, new Set());
          }

          if (typeof data.agent === "string" && data.agent) connectionAgent.set(ws, data.agent);

          // Add client to channel
          const channelClients = channels.get(channelName)!;
          channelClients.add(ws);

          console.log(`\n✓ Client joined channel "${channelName}" (${channelClients.size} total clients)`);

          // Notify client they joined successfully
          ws.send(JSON.stringify({
            type: "system",
            message: `Joined channel: ${channelName}`,
            channel: channelName
          }));

          ws.send(JSON.stringify({
            type: "system",
            message: {
              id: data.id,
              result: "Connected to channel: " + channelName,
            },
            channel: channelName
          }));

          // Notify other clients in channel
          channelClients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({
                type: "system",
                message: "A new user has joined the channel",
                channel: channelName
              }));
            }
          });
          return;
        }

        // Handle regular messages
        if (data.type === "message") {
          const channelName = data.channel;
          if (!channelName || typeof channelName !== "string") {
            ws.send(JSON.stringify({
              type: "error",
              message: "Channel name is required"
            }));
            return;
          }

          const channelClients = channels.get(channelName);
          if (!channelClients || !channelClients.has(ws)) {
            ws.send(JSON.stringify({
              type: "error",
              message: "You must join the channel first"
            }));
            return;
          }

          // Broadcast to all OTHER clients in the channel (not the sender)
          // This prevents echo and ensures proper request-response flow
          let broadcastCount = 0;
          channelClients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
              broadcastCount++;
              const broadcastMessage = {
                type: "broadcast",
                message: data.message,
                sender: "peer",
                channel: channelName
              };
              if (VERBOSE) console.log(JSON.stringify(broadcastMessage, null, 2));
              client.send(JSON.stringify(broadcastMessage));
            }
          });
          
          if (broadcastCount === 0) {
            console.log(`⚠️  No other clients in channel "${channelName}" to receive message!`);
          } else {
            console.log(`✓ Broadcast to ${broadcastCount} peer(s) in channel "${channelName}"`);
          }
        }

        // Forward progress_update messages to the MCP server so it can reset
        if (data.type === "progress_update") {
          const channelName = data.channel;
          if (!channelName) return;

          const channelClients = channels.get(channelName);
          if (!channelClients || !channelClients.has(ws)) return;

          channelClients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify(data));
            }
          });
        }
      } catch (err) {
        console.error("Error handling message:", err);
      }
    },
    close(ws: ServerWebSocket<any>) {
      // Remove client from their channel
      channels.forEach((clients) => {
        clients.delete(ws);
      });
    }
  }
});

console.log(`WebSocket server running on port ${server.port}`);
