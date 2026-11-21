# HANDOFF: FigmaRoblox MCP fork (Aura Fishing)

State as of 2026-11-18. Read this first, then `AGENTS.md` (rules) and `src/cursor_mcp_plugin/README.md` (plugin structure).

## Pipeline

```
Claude Code ─stdio─> MCP server (dist/server.js) ─ws─┐
scripts/figma-run.mjs ─ws────────────────────────────┤
tools/art/*.py (via figma-run.mjs) ──────────────────┼─> relay src/socket.ts :3055 ─ws─> Figma plugin (ui.html -> code.js)
                                                     │       counts: usage/plugin-commands.json
MCP server counts: usage/mcp-tools.json ─────────────┘
```

Channel is fixed to `aura-fishing` (`src/cursor_mcp_plugin/ui/src/config.js`).

## What changed in this session (2026-11-18)

1. **Plugin split into modules.** The 4,947-line `code.js` is now `src/cursor_mcp_plugin/src/`
   (`main.js`, `core/*`, `commands/*` with 13 groups). `ui.html` is now `ui/index.html` + `ui/styles.css` + `ui/src/*.js`.
   `build.mjs` (esbuild) bundles them back into `code.js` / `ui.html`, so `manifest.json` and the Figma link stay the same.
   The command list is identical to the old switch: 54 commands, checked by diff.
2. **Dispatcher became a registry** (`core/registry.js`). Each group file exports `commands = { name: handler }`.
   Duplicate names fail at plugin start.
3. **Behaviour changes (small, deliberate):**
   - `set_instance_overrides` without `targetNodeIds` used to fall through into `set_layout_mode` (a bug in the old switch). It now throws `Missing targetNodeIds parameter`.
   - The dead Google Analytics code was removed from the UI (it was already disabled, nothing was sent). The `analyticsClientId` clientStorage write is gone too.
   - `setcharacters.js` (an unused old copy of `core/fonts.js`) was deleted.
4. **Usage counter (numbers, written automatically):**
   - `src/usage/tracker.ts`: shared counter, written on every call.
   - Relay (`src/socket.ts`): counts **every plugin command from every caller** -> `usage/plugin-commands.json`.
   - MCP server (`server.ts`): wraps `server.tool()` so **every MCP tool** is counted -> `usage/mcp-tools.json`. Tools that return text starting with `Error` count as errors.
   - Agent name: MCP = `mcp:<client name>` (e.g. `mcp:claude-code`), or `--agent=` / env `FIGMA_MCP_AGENT`.
     figma-run.mjs = `--agent=` / env `FIGMA_AGENT` / `figma-run`. Python tools set `py:<script>` themselves.
     The relay reads `params._agent` or the `agent` sent with `join`. The plugin strips `_agent` before running a handler.
   - Read it: MCP tool `get_usage_stats` (top N), or `bun run usage` (tables), or open the JSON.
   - Relay port can now be changed with `PORT=` (default 3055).
5. Backup of the pre-split files: the git working tree (`git diff`) plus the previous `code.js` in the session scratchpad (temporary, do not rely on it).

## Speed + reliability pass (2026-11-18, second session)

Baseline (old upstream relay, plugin via figma-run): get_node_info 426 ms / 248 KB, get_roblox_tree 835 ms / 527 KB, export_node_as_image 1918 ms / 800 KB.

- **Logging**: relay printed every message as pretty JSON twice, MCP server stringified every response twice (incl. MB-sized base64). Now one line per message; full dumps only with `RELAY_VERBOSE=1` / `--debug` / `FIGMA_MCP_DEBUG=1`. UI console logs behind `DEBUG` in `ui/src/config.js`.
- **Fixed waits removed**: `scan_text_nodes` flashed every text node orange and waited 100-500 ms per node (and edited the document from a read command): removed. `set_multiple_text_contents` highlight is now opt-in (`highlight: true`). 1 s pauses between chunks (`delete_multiple_nodes`, `set_multiple_text_contents`) replaced with a 0 ms yield.
- **export_to_roblox** fetches images 4 at a time instead of one by one.
- **Auto-join**: the MCP server remembers the channel (`join_channel`, or `--channel=` / env `FIGMA_CHANNEL`) and rejoins after a relay restart; a command sent while reconnecting waits up to 5 s instead of failing.
- **Response bug**: replies with a falsy result (0, false, "") used to hang until the 30 s timeout. Fixed.
- **New**: plugin built-in `batch` + MCP tool `batch_commands` (many commands, one round trip; relay counts every inner command too) and MCP tool `list_plugin_commands`.
- **Found**: the relay that was running on :3055 was the upstream `bunx cursor-talk-to-figma-socket@latest`, not this fork (so nothing was counted). The plugin UI used to tell users to run that; it now points to `scriptsigma-relay.bat`. Two stale upstream MCP servers (`bunx cursor-talk-to-figma-mcp@latest`) were also running from another config.

## Selection panel + notes (2026-11-18, third pass)

- Plugin UI shows the current selection live (name, type, id, parent path, image flag) with **Copy id** / **Copy all** (`name (id) - note`). Clicking a name zooms to it.
- Each node can carry a **note** (what it is, typed by the user in the panel or by an agent via `set_node_note`), stored with `setPluginData("agentNote")` in the Figma file.
- `get_selection` now also returns `path`, `size`, `text`, `childCount`, `image`, `note`, `page` (old fields unchanged). Tool description tells agents to start there and to trust notes instead of analysing image pixels.
- Files: `src/core/selection.js`, `ui/src/selection.js`, styles at the end of `ui/styles.css`. Smoke test covers it.

Measured after the speed pass (fork relay, same nodes): get_node_info 426 -> 348 ms, get_roblox_tree 835 -> 662 ms, export_node_as_image 1918 -> 1627 ms (about 20% faster; the rest is Figma's own work). Batch of 4 note commands: one round trip, 0-6 ms each inside the plugin. Usage `avgMs` now counts successful calls only (needs a relay restart to apply).

## Phase 1: smaller answers, search, references (2026-11-18, fourth pass)

- **Compact reads**: `get_node_info` / `get_nodes_info` / `read_my_design` take `depth`, `fields` (`box fill stroke radius text layout note`), `maxNodes`, `skipHidden`, `textMax`. Any of them switches to `core/compact.js`, which walks live nodes (no `exportAsync`). Without them the old full output is unchanged.
  Output per node: `id name type [visible:false] x y w h [rotation opacity] fill stroke strokeWeight radius text fontSize font layout{mode gap pad main cross} note`, `children` or `childCount` past the depth; root has `nodeCount` and `truncated`.
- **`find_nodes`** (plugin + MCP tool): `name` (contains, or `exact`), `type[]`, `text`, `rootId`, `visibleOnly`, `limit` -> `{ root, count, truncated, nodes: describeNode[] }`. Uses `findAllWithCriteria` when a type is given.
- **Batch references**: a whole-string param `"$N.path"` = result of item N (0-based), e.g. `"$0.id"`, `"$0.nodes.0.id"`. Bad/failed reference -> that item fails with a clear error. `brief: true` drops each item's result.
- **Undo**: `figma.commitUndo()` after every command from the agent (a batch = one step), so the user's Ctrl+Z undoes one agent action, not the whole session.
- **Errors**: unknown command lists close names ("Did you mean: get_node_info, ..."); every "not found" error ends with a hint to use `get_selection` / `find_nodes`.
- **Usage**: the relay also records response size (`avgKB`, `maxKB`, `totalKB`); shown in `bun run usage` and `get_usage_stats`. Needs a relay restart.

Measured live (Window Aquarium `3569:40700`): full `get_node_info` 54 KB -> compact `depth:2` 5.6 KB (about 10x smaller); compact whole tree (all levels) 36 KB. Inside the plugin: full 17 ms, compact depth 2 11 ms; nearly all of the ~250-350 ms per call is relay / messaging, so batching is what saves time. Batch `find_nodes` + `get_node_info($0.nodes.0.id)` passed in one round trip.

## Stable vs. in progress

- The Figma plugin has Workbench for read-only selection and Motion inspection, and Agent Handoff
  for copying the selected page, layer IDs and notes together with the task and its success criteria.
- The Option 5 comparison board is `3717:1180` on Out Space. Its eight editable Motion frames cover
  Halo Burst, Eclipse, Ten Sparks and Afterglow Pulse at Legendary and Mythic. They reuse the
  Option 5 Sparkle, rarity Overlay gradient and centered Item Card.

- Native Figma Motion is available through `motion_keyframes` for reading and writing property tracks.
  Export an animated top-level frame with `export_motion_video` via `scripts/figma-run.mjs --out=preview.mp4`.
- `npm run dev` watches server and plugin source. After a successful TypeScript build,
  `scripts/mcp-live.mjs` drains existing calls, replaces the server worker and sends the MCP tool-list
  change notification without closing the client connection. Both local project configs use this
  launcher. Sessions started directly on `dist/server.js` pick it up on their next start.

| Part | Status | Notes |
|---|---|---|
| Upstream plugin commands (document, create, style, nodes, text, components, layout, annotations, connectors, export) | stable | logic copied as-is during the split |
| `get_roblox_tree`, `get_image_by_hash`, `export_to_roblox` + `roblox.ts` converter | stable (fork) | tested A14 in `docs/TASKS.md` |
| Builder: `upsert_variables`, `upsert_text_styles`, `build_tree`, `set_fills_empty`, `patch_nodes` | stable (fork) | used by `docs/figma/cozy_menus_spec.py`, `tools/art/*.py` |
| `remove_tinted_and_export` | one-off | hard-coded board `3539:27990`; delete when not needed |
| Selection panel, notes, richer `get_selection` | new | verified in real Figma 2026-11-18 (get_selection, batch note set/get/clear) |
| `batch` / `batch_commands`, `list_plugin_commands`, auto-join | new | smoke-tested without Figma |
| Usage counter | new | verified with a test relay + MCP stdio session; needs a relay restart to start counting |
| Compact reads, `find_nodes`, batch `$N` refs + `brief`, commitUndo, error hints, `avgKB` | new (Phase 1) | smoke test (19 checks) + live in Figma 2026-11-18 |
| Plugin UI (`ui/`) | stable | split only, same behaviour |

## Not done / next

- Phase 2 (planned, not started): `verify` (small thumbnail after edits), `get_context` (selection + page + parents in one call), `documentchange` log ("what did the user change"), server-side cache, cancel / per-command timeout.
- Phase 3 (planned): leaner tool list from usage data, one command spec for plugin + server, split `server.ts`, replay tests.

- **Restart the relay** (`scripts\figma-relay.bat`) and **re-open the plugin in Figma** so the new build is loaded. Restart Claude Code so the MCP server with the counter is loaded.
- Not tested live inside Figma in this session (no Figma window attached). First check: run the plugin, `join_channel`, `get_selection`, `export_to_roblox` on a known node.
- After a week or two of real use: `bun run usage` -> commands with 0 calls are candidates to drop from the MCP tool list (fewer tools = less agent context). Do not delete stable ones that project scripts call.
- `server.ts` (3.5k lines) is still one file. Same split pattern would work (tools/<group>.ts registering on `server`); do it after the usage data shows which groups matter.

## Verify after any change

```
bun run build                       # server + plugin, must succeed
node scripts/usage-report.mjs       # counters readable
```
Plugin smoke test without Figma (mock `figma` global): see the snippet in `AGENTS.md`.
