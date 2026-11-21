// WebSocket link to the local relay (src/socket.ts). Commands arriving from the
// MCP server are forwarded to the plugin main thread; results go back here.
import { CHANNEL, DEBUG, REQUEST_TIMEOUT_MS } from "./config.js";
import { postToPlugin } from "./plugin.js";
import { state } from "./state.js";
import { updateConnectionStatus } from "./status.js";

function send(id, message, type = "message") {
  state.socket.send(JSON.stringify({ id, type, channel: state.channel, message }));
}

function isOpen(what) {
  if (!state.connected || !state.socket) {
    console.error(`Cannot send ${what}: socket not connected`);
    return false;
  }
  return true;
}

export async function connectToServer(port) {
  try {
    if (state.connected && state.socket) {
      updateConnectionStatus(true, "Already connected to server");
      return;
    }

    state.serverPort = port;
    state.socket = new WebSocket(`ws://localhost:${port}`);

    state.socket.onopen = () => {
      console.log("Joining channel:", CHANNEL);
      state.channel = CHANNEL;
      state.socket.send(JSON.stringify({ type: "join", channel: CHANNEL }));
    };

    state.socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (DEBUG) console.log("Received message:", data);

        if (data.type === "system") {
          if (data.message && data.message.result) {
            state.connected = true;
            const channelName = data.channel;
            updateConnectionStatus(true, `Connected to server in channel: <strong>${channelName}</strong>`);
            postToPlugin({
              type: "notify",
              message: `Connected to Cursor MCP server on port ${port} in channel: ${channelName}`,
            });
          }
        } else if (data.type === "error") {
          console.error("Error:", data.message);
          updateConnectionStatus(false, `Error: ${data.message}`);
          state.socket.close();
        }

        handleSocketMessage(data);
      } catch (error) {
        console.error("Error parsing message:", error);
      }
    };

    state.socket.onclose = () => {
      state.connected = false;
      state.socket = null;
      updateConnectionStatus(false, "Disconnected from server");
    };

    state.socket.onerror = (error) => {
      console.error("WebSocket error:", error);
      updateConnectionStatus(false, "Connection error");
      state.connected = false;
      state.socket = null;
    };
  } catch (error) {
    console.error("Connection error:", error);
    updateConnectionStatus(false, `Connection error: ${error.message || "Unknown error"}`);
  }
}

export function disconnectFromServer() {
  if (state.socket) {
    state.socket.close();
    state.socket = null;
    state.connected = false;
    updateConnectionStatus(false, "Disconnected from server");
  }
}

async function handleSocketMessage(payload) {
  const data = payload.message;
  if (DEBUG) console.log("handleSocketMessage", data);

  // Response to a request this UI sent (sendCommand)
  if (data.id && state.pendingRequests.has(data.id)) {
    const { resolve, reject } = state.pendingRequests.get(data.id);
    state.pendingRequests.delete(data.id);
    if (data.error) reject(new Error(data.error));
    else resolve(data.result);
    return;
  }

  // New command from the MCP server -> plugin main thread
  if (data.command) {
    try {
      state.activeRequestId = data.id;
      postToPlugin({ type: "execute-command", id: data.id, command: data.command, params: data.params });
    } catch (error) {
      sendErrorResponse(data.id, error.message || "Error executing command");
    }
  }
}

// UI-originated request to the server (unused today, kept for debugging tools)
export async function sendCommand(command, params) {
  return new Promise((resolve, reject) => {
    if (!state.connected || !state.socket) {
      reject(new Error("Not connected to server"));
      return;
    }
    const id = generateId();
    state.pendingRequests.set(id, { resolve, reject });
    send(id, { id, command, params });
    setTimeout(() => {
      if (state.pendingRequests.has(id)) {
        state.pendingRequests.delete(id);
        reject(new Error("Request timed out"));
      }
    }, REQUEST_TIMEOUT_MS);
  });
}

export function sendSuccessResponse(id, result) {
  if (!isOpen("response")) return;
  send(id, { id, result });
}

export function sendErrorResponse(id, errorMessage) {
  if (!isOpen("error response")) return;
  send(id, { id, error: errorMessage, result: {} });
}

export function sendProgressUpdateToServer(progressData) {
  if (!isOpen("progress update")) return;
  if (DEBUG) console.log("Sending progress update to server:", progressData);
  const requestId = state.activeRequestId || progressData.commandId;
  send(requestId, { id: requestId, type: "progress_update", data: progressData }, "progress_update");
}

function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
}
