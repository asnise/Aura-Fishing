# Aura Fishing — project guide for Claude

Roblox fantasy fishing RPG. Design source of truth: `docs/AURA_FISHING_GDD.md` (Thai).
Current stage: **vertical-slice prototype** (GDD Phase 1 + core of Phase 2).
Talk to the user in Thai; code, identifiers and comments in English.

## Tooling
- Rojo 7.7.1: `D:\tools\rojo\rojo.exe` (not on PATH). `scripts\serve.bat` = live sync, `scripts\build.bat` = `build\AuraFishing.rbxlx`.
- QA after every change, must pass: **`node tools/check.mjs`** (or `tools\check.bat`) = sourcemap + luau-lsp (errors fail, lints warn) + banned chars (check marks, bullets, emoji) in player-visible strings. Same as running:
  ```
  D:\tools\rojo\rojo.exe sourcemap default.project.json -o sourcemap.json
  luau-lsp analyze --definitions=D:/tools/luau-defs/globalTypes.d.luau --sourcemap=sourcemap.json src
  ```
- Roblox Studio MCP is configured in `.mcp.json` (Studio must be open with MCP enabled in Assistant settings).

## Layout (Rojo)
| Folder | In game | Contents |
|---|---|---|
| `src/shared` | ReplicatedStorage.Shared | `Config/*` (all content data), `Registry` (validates + helpers), `Stats`, `Roll`, `Remotes`, `Util/*` |
| `src/server` | ServerScriptService.Server | `Main.server.luau` boot, `Services/*`, `World/WorldBuilder` |
| `src/client` | StarterPlayerScripts.Client | `Main.client.luau` boot, `Controllers/*`, `UI/New` (instance builder) |

## Architecture rules
1. **Data-driven content.** Fish, rods, lines, bags, baits, auras, mutations, locations, rarities, stats live in `src/shared/Config`. Adding content = adding a table entry; no code change. `Registry` validates every entry at startup and errors with the exact bad key.
2. **One stat pipeline.** Every bonus is an additive `Stats = { StatName = n }` on some source. `Stats.Compute(profile, extraSources)` is the only place stats are combined (server and client both use it). New stat → add to `Config/StatDefs`, then read `stats.Values.X` where needed. New stat source (gamepass, skill, potion, event) → pass it via `extraSources` or extend `Stats.Collect`.
3. **Server authoritative.** Server rolls fish, weight, mutation, aura; client only sends inputs (cast depth, hook, minigame success). `FishingService` rejects reel results faster than the theoretical minimum.
4. **Remotes are declared in one list** (`shared/Remotes.luau`). Add the name there first.
5. **Save data** = `DataService` TEMPLATE. New fields get filled into old saves automatically (reconcile). Removed content is cleaned by `sanitize`. Mutate profile then `DataService.MarkDirty(player)`.
6. **Services/Controllers** are modules with `Init()`, started in order from `Main.server.luau` / `Main.client.luau`.
7. **Hooks for future systems:** `FishingService.FishCaught` signal (quests, boss damage, events, leaderboards).
8. UI is built in code (`UI/New`). Menus are generated from Config (`MenuController.BUILDERS`). **UI style = Cozy Lake** (`docs/UI_STYLE.md`): colours/fonts only via `New.Theme`; use `New.Panel/Title/Text/Button/SetButtonColor`, never raw Color3 in controllers.
9. World: if `Workspace.Map` exists, `WorldBuilder` does nothing. Real maps need terrain water + a Part tagged `FishingZone` with attribute `LocationId`.

## How to add content (examples)
- **Fish:** add to `Config/Fish.luau` (`Rarity`, `DepthMin/Max`, `BaseValue`, `Weight`, `Difficulty`, `Pattern`, optional `Locations`).
- **Rod/Line/Bag/Bait:** add to the category in `Config/Equipment.luau`. New category = new key with `Kind` "Permanent"/"Consumable" (shop tab appears automatically; save template adds it).
- **Aura:** add to `Config/Auras.luau` (Chance, Stats, Mutations, Visual). Hand-made VFX: put a model named after the aura id in `ReplicatedStorage.AuraVFX`.
- **Mutation:** `Config/Mutations.luau`. **Location/island:** `Config/Locations.luau` + FishingZone part.

## Roadmap status (GDD §11)
- Done (prototype): cast, bite "!", Ring Reel minigame, depth selector + line max depth, 20 fish, bag + capacity, sell, shop (rods/lines/bags/baits), Manual 1.5x vs Auto 1.0x, aura roll/equip/VFX, mutations, XP/levels, gems, Fishdex, Low FX, DataStore saves.
- Next: Rebirth + titles, skills (Keen Eye / Quick Hands / Multi-Cast via `ExtraLines` stat), boss events + co-op reel, quests, gamepasses (as stat sources), sounds, real map + art, mobile UI polish.

## Figma → Roblox UI (FigmaRoblox MCP)
- Fork of cursor-talk-to-figma-mcp in `Figma For Roblox/cursor-talk-to-figma-mcp` (analytics removed). Rebuild after edits: `bun run build` there (server + plugin) then `bun run test:plugin`; converter test: `bun scripts/test-roblox.ts <out.luau>`.
- Fork docs: `HANDOFF.md` (state, stable vs new), agent rules at the end of `AGENTS.md`, plugin structure `src/cursor_mcp_plugin/README.md`. Plugin sources are `src/cursor_mcp_plugin/src/` + `ui/`; `code.js`/`ui.html` are generated.
- Usage counters (numbers): `usage/plugin-commands.json` (relay, all callers) + `usage/mcp-tools.json` (MCP tools); read with MCP `get_usage_stats` or `bun run usage`. Scripts calling `figma-run.mjs` should pass `--agent=<name>` or env `FIGMA_AGENT`.
- Needs: `scripts\figma-relay.bat` running + Figma plugin "Figma to Roblox MCP (Aura Fishing)" open → `join_channel` with the channel shown in the plugin.
- `export_to_roblox` (figmaUrl or nodeId or current selection) writes `src/client/UI/Generated/<Module>.luau` + `assets/ui/<Module>/*.png`. Generated modules: `require(Generated.X)(screenGui)` → `{ Root, Refs }`. Never hand-edit generated files; wire behaviour from a controller via `Refs`. Re-export keeps filled `rbxassetid` values.
- Converter: `src/talk_to_figma_mcp/roblox.ts` (font map `FONT_FAMILIES`, layer hints `[btn] [img] [skip] [scroll]`). Default scale mode + UIAspectRatioConstraint on root.
- Images must be uploaded to Roblox (Studio Asset Manager → Bulk Import) and ids pasted into the module's `Images` table.

## Art pipeline (AI image sheets)
- Asset list + cell order: `tools/art/sheets.json` (9 sheets × 3×3). Prompts doc is generated: `python -I tools/art/make_prompts.py` → `docs/ART_PROMPTS.md`.
- Slice a generated sheet: `python -I tools/art/slice_grid.py <sheet_id> <image.png>` → transparent 512px PNGs in `assets/art/<folder>/<name>.png` + `<sheet_id>_contact.png`. File names match Config ids (fish/rods/auras) so code can map them directly.
- Figma menus: `docs/figma/cozy_menus_spec.py` (14 screens, Sections) built with the fork plugin on fixed channel `aura-fishing`.
- Art into Figma: layers named `Img <folder>/<name>` are image slots. After (re)building menus run
  `python -I tools/art/figma_images.py --root <menusRootId> [--root <artLibraryId>]` to fill them from `assets/art` (256px, FIT).
  Chip component icons: `--root 3487:4313 --set "Type=Coins/Icon=ui/status/coin" ...`. Art Library section lives at x=7100 on page Out Space.

## Handoff / assets
- **Latest full handoff (any agent): `docs/HANDOFF_ANTIGRAVITY.md`** — state after C3–C19, rules (Figma first, rates per second), next tasks, Figma node ids.
- Next-conversation brief: **`docs/HANDOFF_UI.md`** (screen status, conversion rules, tools, open decisions).
- Asset catalog: `assets/catalog.json` + `docs/ASSET_CATALOG.md`; ids in code via `Shared.Config.UIAssets` (generated). Upload then `tools/art/sync_ui_assets.py`.
- Place file with the map: `places/AuraFishing.rbxlx` (do not overwrite with `build/`).
- **QA site (`qa/`, GitHub Pages + Firebase):** after editing `docs/TASKS.md` run `node qa/tools/build.mjs` and commit `qa/data/qadata.json`; at session start run `node qa/tools/pull.mjs` for failed tasks / open tickets, `pull.mjs` also prints ideas waiting for a decision / approved ideas; post summaries or ideas to the forum with `node qa/tools/post.mjs --title ... --category ... --body ...` (needs `qa/.agent.env`); after fixing a ticket run `node qa/tools/fix.mjs <id> "note"`; publish the site with `git subtree push --prefix qa origin gh-pages` (GitHub Pages serves branch `gh-pages`, no Actions). Full agent guide + prompts to give other agents: `qa/SKILL.md`. Details: `qa/README.md`.
- **Task list & test guide: `docs/TASKS.md`.** Every session that finishes a piece of work MUST update it: set the status (☐/◐/☑), add "Done when" and step-by-step "ทดสอบ" (Thai) the user can follow in Studio, and add a line to "บันทึกการอัปเดต".
