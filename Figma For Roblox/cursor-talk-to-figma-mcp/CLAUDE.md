# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MCP (Model Context Protocol) server that bridges Cursor AI IDE with Figma. Three components communicate in a pipeline:

```
Cursor AI ←(stdio)→ MCP Server ←(WebSocket)→ WebSocket Relay ←(WebSocket)→ Figma Plugin
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
The main server implementing the MCP protocol via `@modelcontextprotocol/sdk`. Exposes 50+ tools (create shapes, modify text, manage layouts, export images, etc.) and several AI prompts (design strategies). Communicates with Cursor over stdio and with the WebSocket relay via `ws`. Each request gets a UUID, is tracked in a `pendingRequests` Map with timeout/promise callbacks, and resolves when the plugin responds.

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
2. `bun socket` in one terminal (WebSocket relay)
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

## Aura Fishing fork changes
- Plugin: Google Analytics disabled (`ui.html` track() no-op, GA domain removed from `manifest.json`), renamed "Figma to Roblox MCP (Aura Fishing)".
- **Read `HANDOFF.md` and the agent rules at the bottom of `AGENTS.md` before changing anything.**
- Plugin is modular since 2026-11-18 (`src/cursor_mcp_plugin/src/`, built by `build.mjs`); fork commands in `commands/roblox.js` (`get_roblox_tree`, `get_image_by_hash`) and `commands/builder.js`; built-in `list_commands`.
- Usage counters (numbers, automatic): relay -> `usage/plugin-commands.json`, MCP server -> `usage/mcp-tools.json`; MCP tool `get_usage_stats`, `bun run usage`.
- MCP tools added: `get_roblox_tree`, `export_to_roblox` (bottom of `server.ts`, converter in `roblox.ts`). `--roblox-project=<dir>` sets the output project.
- Test: `bun scripts/test-roblox.ts out.luau`.
- Run from local `dist/server.js` (not `bunx ...@latest`, which would fetch the upstream package without these changes).
