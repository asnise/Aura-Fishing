# Figma plugin: "Figma to Roblox MCP (Aura Fishing)"

Runs inside Figma. It receives commands from the local relay (`src/socket.ts`, ws://localhost:3055)
and runs them against the Figma API.

```
MCP server / figma-run.mjs / python tools --ws--> relay :3055 --ws--> ui.html (iframe) --postMessage--> code.js (Figma API)
```

## Files: edit these, not the generated ones

| Path | What it is | Edit? |
|---|---|---|
| `manifest.json` | Plugin manifest (`main: code.js`, `ui: ui.html`) | rarely |
| `build.mjs` | esbuild: `src/` -> `code.js`, `ui/` -> `ui.html` | rarely |
| `code.js` | **GENERATED** plugin main thread bundle | **no** |
| `ui.html` | **GENERATED** UI (template + css + bundled js inlined) | **no** |
| `src/main.js` | Entry point: showUI, UI message bridge, settings | yes |
| `src/core/registry.js` | Command registry + `handleCommand()` dispatcher | rarely |
| `src/core/*.js` | Shared helpers (progress, state, utils, serialize, fonts) | carefully |
| `src/commands/*.js` | **One file per command group.** Each exports `commands = { name: handler }` | yes |
| `src/commands/index.js` | List of command groups | when adding a group |
| `ui/index.html` | UI markup (`/*@inline ...*/` placeholders) | yes |
| `ui/styles.css` | UI styles | yes |
| `ui/src/*.js` | UI logic: `socket.js` (relay link), `status.js`, `progress.js`, `dom.js`, `config.js` (port, channel) | yes |

Build (from the repo root `cursor-talk-to-figma-mcp/`):

```
bun run build:plugin          # once
bun run build:plugin:watch    # rebuild on save
bun run build                 # MCP server (tsup) + plugin
npm run dev                   # rebuild server and plugin when their source changes
```

Leave `npm run dev` running while editing. The watcher ignores generated bundles. Check the active
Figma development plugin with `list_commands` after a rebuild. If it still reports an older build,
close and reopen the plugin in Figma. The project MCP configs run `scripts/mcp-live.mjs`. It keeps
stdio open, waits for active calls, and switches to the newly built TypeScript server after a
successful `npm run dev` rebuild. Clients that handle MCP tool-list notifications refresh their tools
automatically. Sessions started directly on `dist/server.js` must start once with the updated config.
Run `npm run test:mcp-live` to verify the rollover.

## Command groups

| File | Commands | Stability |
|---|---|---|
| `document.js` | get_document_info, get_selection (+ path, note, size, text, image flag), get_node_note, set_node_note, get_node_info, get_nodes_info, read_my_design, get_reactions, set_focus, set_selections | stable |
| `create.js` | create_rectangle, create_frame, create_text, create_section, clone_node | stable |
| `style.js` | set_fill_color, set_stroke_color, set_image_fill, set_corner_radius, get_styles | stable |
| `nodes.js` | move_node, resize_node, rename_node, set_parent, delete_node, delete_multiple_nodes | stable |
| `text.js` | set_text_content, scan_text_nodes, set_multiple_text_contents | stable |
| `components.js` | get_local_components, create_component_instance, get_instance_overrides, set_instance_overrides | stable |
| `layout.js` | set_layout_mode, set_padding, set_axis_align, set_layout_sizing, set_item_spacing | stable |
| `annotations.js` | get_annotations, set_annotation, set_multiple_annotations, scan_nodes_by_types | stable |
| `connectors.js` | set_default_connector, create_connections | stable |
| `export.js` | export_node_as_image | stable |
| `roblox.js` | get_roblox_tree, get_image_by_hash (fork) | stable (fork) |
| `builder.js` | upsert_variables, upsert_text_styles, build_tree, set_fills_empty, patch_nodes (fork) | stable (fork) |
| `motion.js` | motion_keyframes, export_motion_video | new |
| `oneoff.js` | remove_tinted_and_export (hard-coded node id) | one-off, delete when done |
| `core/selection.js` | Selection panel feed (`selectionchange`), per-node notes (`setPluginData("agentNote")`), `describeNode()` | new |
| `core/registry.js` (built-in) | `list_commands`, `batch` (`{ commands: [{ command, params }], stopOnError, brief }` -> per-item `ok/result/error/ms`; `"$N.path"` params = result of item N); unknown-command suggestions, not-found hints | new |
| `core/compact.js` + `document.js` | compact mode for get_node_info / get_nodes_info / read_my_design (`depth`, `fields`, `maxNodes`, `skipHidden`, `textMax`), `find_nodes` | new (Phase 1) |
| `main.js` | `figma.commitUndo()` after each agent command (batch = one undo step) | new (Phase 1) |

`motion_keyframes` reads a node's Motion tracks when passed only `nodeId`. To animate a layer, send
`tracks: [{ property: "SCALE_XY", keyframes: [{ time: 0, value: 0 }, { time: 0.6, value: 10, easing: "EASE_OUT" }] }]`.
Other supported properties are `OPACITY`, `ROTATION`, `TRANSLATION_X` and `TRANSLATION_Y`.
Use `export_motion_video` with a top-level frame ID and the CLI flag `--out=preview.mp4`.

Use **Workbench** to inspect the selected layer, read its Motion tracks or list available commands directly in the plugin.
Use **Agent Handoff** to copy the selection, layer notes, task, constraints and workflow for another
agent. The prompt is copied to the clipboard on request.

Every file starts with a `// @stability ...` line. **stable** = in use by the MCP server or by
project scripts; keep its name, params and result shape. To change one, add a new command or an
optional param instead of breaking the old one.

## Add a command

1. Pick the group file in `src/commands/` (or create `src/commands/<group>.js` and add it to `src/commands/index.js`).
2. Write the handler and register it in that file's map:
   ```js
   export async function setOpacity(params) {
     const { nodeId, opacity } = params || {};
     const node = await figma.getNodeByIdAsync(nodeId);
     if (!node) throw new Error(`Node not found: ${nodeId}`);
     node.opacity = opacity;
     return { id: node.id, opacity: node.opacity };
   }

   export const commands = {
     // ...
     set_opacity: setOpacity,
   };
   ```
   A handler gets `params` (already without `_agent`) and returns a JSON-able result, or throws an
   `Error` (its message goes back to the caller). For long jobs use `sendProgressUpdate` from
   `core/progress.js` with `params.commandId`.
3. `bun run build:plugin` and re-open the plugin. Duplicate names fail at plugin start.
4. Expose it to agents: add the name to `type FigmaCommand` and a `server.tool(...)` in
   `src/talk_to_figma_mcp/server.ts`, then `bun run build`. Scripts can call it right away with
   `node scripts/figma-run.mjs --channel=aura-fishing set_opacity params.json`.
5. Add a row to the table above.

## Usage counter

Every command that reaches this plugin is counted by the relay into `usage/plugin-commands.json`
(calls, errors, avg ms, per agent). See `../../HANDOFF.md`. The plugin itself stores nothing.
