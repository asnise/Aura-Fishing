# AGENTS.md

This file provides guidance to Claude Code agents (claude.ai/code) when working with code in this repository.

## Project Overview

MCP (Model Context Protocol) server that bridges AI agents (Cursor, Claude Code) with Figma. Three components communicate in a pipeline:

```
Claude Code / Cursor ←(stdio)→ MCP Server ←(WebSocket)→ WebSocket Relay ←(WebSocket)→ Figma Plugin
```

## Build & Development Commands

```bash
bun install              # Install dependencies
bun run build            # Build MCP server (tsup → dist/) + Figma plugin (code.js, ui.html)
bun run build:plugin     # Plugin only (add :watch to rebuild on save)
bun run test:plugin      # Plugin smoke test without Figma (mock figma global)
bun run usage            # Usage counters as tables (usage/*.json)
bun run dev              # Build in watch mode
bun socket               # Start WebSocket relay server (port 3055)
bun run start            # Run built MCP server
bun setup                # Full setup (install + write .cursor/mcp.json + .mcp.json)
```

No full test suite; `bun run test:plugin` is the smoke test. Run `bun run build && bun run test:plugin` after every change.

## Architecture

### MCP Server (`src/talk_to_figma_mcp/server.ts`)
The main server implementing the MCP protocol via `@modelcontextprotocol/sdk`. Exposes 50+ tools (create shapes, modify text, manage layouts, export images, etc.) and several AI prompts (design strategies). Communicates with the AI agent over stdio and with the WebSocket relay via `ws`. Each request gets a UUID, is tracked in a `pendingRequests` Map with timeout/promise callbacks, and resolves when the plugin responds.

### WebSocket Relay (`src/socket.ts`)
Lightweight Bun WebSocket server on port 3055 (configurable via `PORT` env). Routes messages between MCP server and Figma plugin using channel-based isolation. Clients call `join` to enter a channel; messages broadcast only within the same channel.

### Figma Plugin (`src/cursor_mcp_plugin/`)
Runs inside Figma. Sources: `src/main.js` (entry), `src/core/` (registry/dispatcher, progress, state, utils, fonts), `src/commands/<group>.js` (each exports `commands = { name: handler }`), UI in `ui/`. `build.mjs` (esbuild) bundles them into **generated** `code.js` and `ui.html` (never edit those). Structure, stability table and "add a command" steps: `src/cursor_mcp_plugin/README.md`.

## Key Patterns

- **Colors**: Figma uses RGBA 0-1 range. The MCP tools accept 0-1 floats and the filter converts to hex for display.
- **Logging**: All logs go to stderr. Stdout is reserved for MCP protocol messages.
- **Timeouts**: 30s default per command. Progress updates from the plugin reset the inactivity timer.
- **Chunking**: Large operations (scanning 100+ nodes) are chunked with progress updates to prevent Figma UI freezing.
- **Reconnection**: WebSocket auto-reconnects after 2 seconds on disconnect.
- **Zod validation**: All tool parameters are validated with Zod schemas.

## Setup

1. Run `bun setup` — installs dependencies and writes MCP config for both Cursor (`.cursor/mcp.json`) and Claude Code (`.mcp.json`)
2. `bun socket` in one terminal (WebSocket relay on port 3055)
3. In Figma: Plugins → Development → Link existing plugin → select `src/cursor_mcp_plugin/manifest.json`
4. Run plugin in Figma, join a channel, then use tools from Cursor or Claude Code

The MCP config written by `bun setup` uses the published package:

```json
{
  "mcpServers": {
    "TalkToFigma": {
      "command": "bunx",
      "args": ["cursor-talk-to-figma-mcp@latest"]
    }
  }
}
```

You can also add it manually for Claude Code via the CLI:

```bash
claude mcp add TalkToFigma -- bunx cursor-talk-to-figma-mcp@latest
```

## Agent Notes

- Always call `join_channel` before issuing any Figma commands
- Call `get_document_info` first to understand the design structure
- Use `read_my_design` or `get_selection` before making modifications
- Batch operations (`set_multiple_text_contents`, `delete_multiple_nodes`, `set_multiple_annotations`) are preferred over repeated single-node calls for performance
- All MCP tool parameters are Zod-validated; invalid inputs return structured errors
- The plugin and relay must both be running before any tool calls succeed

## Rules for agents working on this fork (Aura Fishing)

Read `HANDOFF.md` first (current state, what is stable, what is next).

1. **Never edit generated files**: `src/cursor_mcp_plugin/code.js`, `src/cursor_mcp_plugin/ui.html`, `dist/*`. Edit sources and run `bun run build`.
2. **Stable means stable.** Files tagged `// @stability stable` (and tools listed as stable in `HANDOFF.md`) are used by the MCP server or project scripts (`tools/art/*.py`, `docs/figma/*_spec.py`). Do not rename them, remove params or change the result shape. Add an optional param or a new command instead.
3. **One command = one handler in one group file**, registered in that file's `commands` map. New group -> add it to `src/commands/index.js`. One-off scripts tied to node ids go in `commands/oneoff.js`.
4. **New MCP tool**: add the command name to `type FigmaCommand` and a `server.tool(...)` in `server.ts`. Usage counting is automatic (do not add counting code per tool).
5. **Say who you are.** Usage is counted per agent:
   - MCP server: uses the MCP client name automatically (`mcp:claude-code`). Override with `--agent=<name>` in `.mcp.json` args or env `FIGMA_MCP_AGENT`.
   - `scripts/figma-run.mjs`: pass `--agent=<name>` or set env `FIGMA_AGENT` (Python tools set `py:<script>`).
   - Any other WebSocket client: send `"agent": "<name>"` with the `join` message, or `_agent` in command params.
6. **Check usage before refactoring or removing**: `get_usage_stats` (MCP) or `bun run usage`. Data lives in `usage/mcp-tools.json` (MCP tools) and `usage/plugin-commands.json` (plugin commands, all callers). Numbers only: calls, ok, errors, avgMs, maxMs, first/last used, byAgent.
7. **Start from the selection**: when the user says "this" or gives a name, call `get_selection` first (the user sees the same ids in the plugin's Selection panel). A `note` on a node is the user's description: trust it. Do not analyse image pixels; use layer name + note. Record what you learned with `set_node_note`.
8. **Be fast**: many edits = one `batch_commands` call (one round trip) instead of one tool call each. Builder commands (`build_tree`, `patch_nodes`, `upsert_variables`, ...) have no own tool: run them through `batch_commands`. Use `"$N.path"` in a batch item's params to use item N's result (e.g. `"$0.id"` after a create), and `brief: true` for big write batches. Read with `get_node_info` / `read_my_design` **in compact mode** (`depth`, `fields`, `maxNodes`; about 10x smaller) or `get_roblox_tree` for Roblox export; locate layers with `find_nodes` instead of reading whole pages. Each agent command is one undo step for the user.
9. **After a change**: `bun run build && bun run test:plugin`, then update `HANDOFF.md` (what changed, stable/new, next) and the row in `src/cursor_mcp_plugin/README.md`. In the game repo, add a line to `docs/TASKS.md`.
