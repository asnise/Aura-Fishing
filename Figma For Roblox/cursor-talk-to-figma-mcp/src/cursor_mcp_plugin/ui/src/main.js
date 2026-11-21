// UI entry (bundled + inlined into ../../ui.html by ../../build.mjs).
import { DEBUG, DEFAULT_PORT } from "./config.js";
import { connectButton, copyButton, mcpJson, portInput, tabContents, tabs } from "./dom.js";
import { updateProgressUI } from "./progress.js";
import {
  connectToServer,
  disconnectFromServer,
  sendErrorResponse,
  sendProgressUpdateToServer,
  sendSuccessResponse,
} from "./socket.js";
import { state } from "./state.js";
import { renderSelection } from "./selection.js";
import { setStatusInfo, updateConnectionStatus } from "./status.js";
import { updateWorkbenchSelection, renderWorkbenchResult } from "./workbench.js";

// Tabs
tabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    tabs.forEach((t) => t.classList.remove("active"));
    tabContents.forEach((c) => c.classList.remove("active"));
    tab.classList.add("active");
    document.getElementById("content-" + tab.id.slice(4)).classList.add("active");
  });
});

// Connect / disconnect toggle
connectButton.addEventListener("click", () => {
  if (state.connected) {
    updateConnectionStatus(false, "Disconnecting...");
    setStatusInfo();
    disconnectFromServer();
  } else {
    const port = parseInt(portInput.value, 10) || DEFAULT_PORT;
    updateConnectionStatus(false, "Connecting...");
    setStatusInfo();
    connectToServer(port);
  }
});

// Copy MCP config
copyButton.addEventListener("click", () => {
  mcpJson.select();
  document.execCommand("copy");
  copyButton.textContent = "Copied!";
  setTimeout(() => {
    copyButton.textContent = "Copy to Clipboard";
  }, 2000);
});

// Messages plugin main thread -> UI
window.onmessage = (event) => {
  const message = event.data.pluginMessage;
  if (!message) return;
  if (DEBUG) console.log("Received message from plugin:", message);

  switch (message.type) {
    case "connection-status":
      updateConnectionStatus(message.connected, message.message);
      break;
    case "auto-connect":
    case "auto-disconnect":
      connectButton.click();
      break;
    case "command-result":
      sendSuccessResponse(message.id, message.result);
      break;
    case "command-error":
      sendErrorResponse(message.id, message.error);
      break;
    case "selection":
      renderSelection(message.data);
      updateWorkbenchSelection(message.data);
      break;
    case "workbench-result":
      renderWorkbenchResult(message);
      break;
    case "command_progress":
      updateProgressUI(message);
      sendProgressUpdateToServer(message);
      break;
  }
};
