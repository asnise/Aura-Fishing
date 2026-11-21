// Plugin entry (bundled to ../code.js by ../build.mjs).
// Boot order: show UI -> wire messages -> load settings.

import { handleCommand } from "./core/registry.js";
import { focusFromUi, saveNoteFromUi, watchSelection } from "./core/selection.js";
import { loadSettings, updateSettings } from "./core/state.js";

figma.showUI(__html__, { width: 350, height: 600 });

// Messages from ui.html (which relays MCP commands from the WebSocket)
figma.ui.onmessage = async (msg) => {
  switch (msg.type) {
    case "update-settings":
      updateSettings(msg);
      break;
    case "notify":
      figma.notify(msg.message);
      break;
    case "set-note":
      await saveNoteFromUi(msg);
      break;
    case "focus-node":
      await focusFromUi(msg);
      break;
    case "close-plugin":
      figma.closePlugin();
      break;
    case "workbench-read": {
      const id = figma.currentPage.selection[0]?.id;
      const isCatalogue = msg.view === "commands";
      if (!isCatalogue && (!id || id !== msg.nodeId)) break;
      try {
        const command = isCatalogue ? "list_commands" : msg.view === "motion" ? "motion_keyframes" : "get_node_info";
        const result = await handleCommand(command, isCatalogue ? {} : { nodeId: id, depth: 2, fields: ["box", "text", "note"] });
        figma.ui.postMessage({ type: "workbench-result", request: msg.request, result });
      } catch (error) {
        figma.ui.postMessage({ type: "workbench-result", request: msg.request, error: error.message });
      }
      break;
    }
    case "execute-command":
      try {
        const result = await handleCommand(msg.command, msg.params);
        figma.ui.postMessage({ type: "command-result", id: msg.id, result });
      } catch (error) {
        figma.ui.postMessage({
          type: "command-error",
          id: msg.id,
          error: error.message || "Error executing command",
        });
      } finally {
        // One agent command (a whole batch included) = one Ctrl+Z step for the user
        if (typeof figma.commitUndo === "function") figma.commitUndo();
      }
      break;
  }
};

// Plugin launched from the menu -> connect straight away
figma.on("run", () => {
  figma.ui.postMessage({ type: "auto-connect" });
});

loadSettings();
watchSelection();
