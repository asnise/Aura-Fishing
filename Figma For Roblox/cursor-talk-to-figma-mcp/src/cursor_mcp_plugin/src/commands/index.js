// Command catalogue. Every module in this folder exports
//   export const commands = { command_name: async (params) => result }
// and is listed here once. The command name is what the MCP server sends
// (sendCommandToFigma("command_name", params) in src/talk_to_figma_mcp/server.ts).

import { commands as document } from "./document.js";
import { commands as create } from "./create.js";
import { commands as style } from "./style.js";
import { commands as nodes } from "./nodes.js";
import { commands as text } from "./text.js";
import { commands as components } from "./components.js";
import { commands as layout } from "./layout.js";
import { commands as annotations } from "./annotations.js";
import { commands as connectors } from "./connectors.js";
import { commands as exportCommands } from "./export.js";
import { commands as roblox } from "./roblox.js";
import { commands as builder } from "./builder.js";
import { commands as motion } from "./motion.js";
import { commands as oneoff } from "./oneoff.js";

export const COMMAND_GROUPS = {
  document,
  create,
  style,
  nodes,
  text,
  components,
  layout,
  annotations,
  connectors,
  export: exportCommands,
  roblox,
  builder,
  motion,
  oneoff,
};
