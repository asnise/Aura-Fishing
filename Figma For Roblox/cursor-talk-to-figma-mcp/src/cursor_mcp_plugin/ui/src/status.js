import { connectButton, connectionStatus, mcpConfigSection, mcpJson, portInput } from "./dom.js";
import { state } from "./state.js";

export function updateConnectionStatus(isConnected, message) {
  state.connected = isConnected;

  let statusMessage =
    message ||
    (isConnected ? "Connected to Cursor MCP server" : "Not connected to Cursor MCP server");

  if (!isConnected) {
    statusMessage +=
      "<br><br>Start the fork relay, then connect<br><code>scripts\\figma-relay.bat</code><br>(not <code>bunx cursor-talk-to-figma-socket</code>: that is the upstream relay without the usage counter)";
  }

  connectionStatus.innerHTML = statusMessage;
  connectionStatus.className = `status ${isConnected ? "connected" : "disconnected"}`;

  connectButton.textContent = isConnected ? "Disconnect" : "Connect";
  connectButton.className = isConnected ? "secondary" : "primary";
  portInput.disabled = isConnected;

  mcpConfigSection.className = `section ${isConnected ? "" : "hidden"}`;
  if (isConnected) updateMcpConfig();
}

export function setStatusInfo() {
  connectionStatus.className = "status info";
}

function updateMcpConfig() {
  const mcpConfig = {
    mcpServers: {
      TalkToFigma: {
        command: "bunx",
        args: ["cursor-talk-to-figma-mcp@latest"],
      },
    },
  };
  mcpJson.value = JSON.stringify(mcpConfig, null, 2);
}
