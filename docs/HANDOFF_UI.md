# HANDOFF — UI systems & Figma → Roblox conversion (Aura Fishing)

For the next conversation that implements the game systems and converts the Figma UI into Roblox.
Read this first, then `CLAUDE.md`, `docs/UI_STYLE.md`, `docs/ASSET_CATALOG.md`, `docs/TASKS.md` (task list — update it after every finished screen: status + Done when + Thai test steps). Talk to the user in Thai; code in English.

---

## 1. Where everything is

| What | Where |
|---|---|
| Game code (Rojo) | `src/` — server `src/server`, client `src/client`, shared `src/shared` (Config = all content data) |
| Place file with the user's map | **`places/AuraFishing.rbxlx`** — open this in Studio. `build/AuraFishing.rbxlx` is overwritten by `scripts/build.bat` |
| UI style rules | `docs/UI_STYLE.md` (Cozy Lake, safe areas, windows, badges, Item Slot, Aura Card, gacha) |
| Theme in code | `src/client/UI/New.luau` → `New.Theme`, helpers `New.Panel/Title/Text/Button/SetButtonColor/BadgeRow/Pill/Lip` |
| Asset catalog | `assets/catalog.json` (machine) + `docs/ASSET_CATALOG.md` (human) |
| Asset files | `assets/ui-global/*.png` (15 white tintable shapes) + `assets/art/<folder>/*.png` (81 full-colour, 512px) |
| Asset ids in code | `src/shared/Config/UIAssets.luau` (generated; `rbxassetid://0` = not uploaded yet) |
| Figma file | `givb0hmQYmmaOy7p7DGtb2`, page **Out Space** (`3465:14993`) |
| Figma build specs | `docs/figma/*.py` (generate JSON) → sent with the fork plugin (section 4) |

### Figma map (page Out Space)
| Section / board | Node id | Status |
|---|---|---|
| Cozy Lake Style Guide | `3489:5654` | reference (tokens, type, components) |
| Components board | `3487:4280` | **source of truth** — Button, Chip, Rarity Tag, Progress Bar, Catch Card, Shop Row, Item Slot, HUD Stats, Aura Card |
| Aura Fishing — Game Menus (Cozy Lake) | `3492:16631` | screens 00–16 (see section 2) |
| Aura Gacha — Reel Slot (FINAL) | `3492:20547` | gacha components + G1–G6 |
| Global Assets (export) | see `assets/catalog.json` → `global_assets_section` | white shapes for export |
| Art Library | `3491:6690` | all 81 art PNGs |
| Option boards (ItemSlot, Reel, HUD Stats, Gacha concepts, Style directions) | various | **exploration only — do not implement** |

The user edits Figma by hand. **Never rebuild a whole section**; patch single nodes (`replaceId`, section 4). Ask before any bigger rebuild.

---

## 2. Screen status (Figma vs code)

| Figma screen | Code today | What's left |
|---|---|---|
| 00 Roblox Safe Areas | rules applied in HUDController | keep every new screen inside the safe zones |
| 01 HUD | HUDController (HUD Stats style E, side menu, actions + depth stepper, mobile CAST, cast charge bar; C25) | swap text menu buttons for icon tiles once assets are uploaded |
| 02 HUD States | FishingController | complete |
| 03 Reel Minigame | baked Minigame (Twin tubes A2) + FishingController.runMinigame | complete |
| 04 Catch Result | Components prefab CatchCard + HUD.ShowCatch | complete |
| 05/06 Shop | baked Menus/Shop (UI/Screens/Menus) + MenuController.fillShop | complete |
| 07 Auras | baked Menus/Auras + fillAuras (Aura Card rows, equipped card, pager) | complete |
| 08 Aura Roll Result | replaced by the gacha reveal (UI/AuraReel) | complete |
| 09 Fishdex | baked Menus/Fishdex + fillFishdex (3x2 cards, progress bar, pager) | complete |
| 10 Notifications | HUD.Notify | complete |
| 11 Dialogue | baked Dialogue (UI/Screens/Dialogue) | complete |
| 12 Main Menu | baked MainMenu (UI/Screens/MainMenu) + MainMenuController | complete |
| 13 Inventory | baked Inventory + ItemDetail + Character (UI/Screens/Inventory) | complete |
| 14 Modal | baked Modal (UI/Screens/Modal) + UI/Modal.Confirm | complete |
| 15/16 Cast Popup | removed in C25 (depth stepper on the HUD, hold-to-cast) | Figma 15/16 sections are outdated |
| Gacha G1 Altar page | baked GachaPage (UI/Screens/GachaPage, machine, rates, pity, x1/x10, skip, auto) | complete |
| Gacha G2-G5 | UI/AuraReel (Reel Slot) | complete |
| Gacha G6 x10 | baked GachaPage (Summary popup x10) | complete |

---

### UI is stored in the place (decided 2026-11-16)
Screens are **baked into `StarterGui`** of `places/AuraFishing.rbxlx`, not built when the game starts.
- Layout: `src/client/UI/Screens/<Name>.luau` -> `{ Name, Build(): ScreenGui }` (static, `New.*` helpers, fixed slots for lists/pagers).
- Bake: `node tools/ui/bake.mjs [Name ...] [--force]` (StudioBridge, no Rojo needed), then the user saves the place. ScreenGui attribute `Locked = true` = bake skips it (hand-edited).
- Runtime: `UI/Baked.Get(name)` + `Baked.Find(gui, "A/B/C")`; controllers only fill data. Images: `New.Image({ Key = ... })` stores attribute `ImageKey`, resolved at runtime (`New.ApplyImages`), so uploads need no re-bake.
- Studio tools: `tools/ui/preview.mjs <view>` (sample data from `UI/SampleData`), `tools/ui/compare.py` (Figma vs capture), "Aura UI" panel plugin (`tools/ui/plugin`, `install-plugin.bat`), `tools/ui/collect_asset_ids.mjs` (ids after Bulk Import + Insert).
- Still runtime-built (to convert): HUD, CastPopup, AuraReel, Pond Card minigame, catch card, toasts.

## 3. How to convert a Figma screen

Two ways — pick per screen:

1. **Hand-build with `UI/New` (recommended for anything interactive / data-driven)** — read the Figma node (sizes, colours from the token names), rebuild with `New.*` helpers and `New.Theme`. Matches existing controllers, easy to bind to profile data.
2. **FigmaRoblox `export_to_roblox`** (static layouts, e.g. Main Menu shell, Modal) — MCP server `FigmaRoblox` in `.mcp.json`. Writes `src/client/UI/Generated/<Module>.luau` returning `function(parent) -> { Root, Refs }`. Wire behaviour in a controller via `Refs["Btn …"]`; never hand-edit generated files. Layer hints: `[btn] [img] [skip] [scroll]`; buttons named `Btn …`.

Rules that must hold (details in `docs/UI_STYLE.md`):
- Colours/fonts only via `New.Theme`; one border colour (`Track`, 2px); rarity shown with tags/text/corner, never borders.
- List windows fixed size (760×610, same as Figma; `New.FitWindow` adds a UIScale on small screens); pagers or scroll, never content-sized windows.
- Info rows are **badges** (`New.BadgeRow`), not `a • b • c` text.
- Safe areas: top bar 58px, leaderboard top-right, chat top-left, mobile thumbstick bottom-left, jump bottom-right. CoreGui draws above our UI.
- Item Slot = option F (white tile, rarity corner, count bottom-right, NEW corner badge, FaLock for locked). Aura Card = Large / Row / Compact.

### Assets in code
```lua
local UIAssets = require(ReplicatedStorage.Shared.Config.UIAssets)
icon.Image = UIAssets.Global.icon_lock            -- white shape
icon.ImageColor3 = New.Theme.SubText               -- tint
fish.Image = UIAssets.GetArt("fish/BubbleCarp")    -- full colour
if not UIAssets.IsUploaded(fish.Image) then --[[ fall back to a coloured Frame ]] end
```
Global shapes are white on purpose: one file per shape, any colour via `ImageColor3`.

### Uploading assets (user does this in Studio)
1. Studio → **Asset Manager → Bulk Import** → select `assets/ui-global/` and the needed `assets/art/<folder>/` files.
2. Copy each asset id into `assets/catalog.json` (`rbxassetid`) — or write `key,id` lines into a CSV.
3. `python -I tools/art/sync_ui_assets.py [ids.csv]` → regenerates `UIAssets.luau` + `ASSET_CATALOG.md`.
Font Awesome FaLock needs a credit line (CC BY 4.0).

---

## 4. Tools you can use

| Tool | Use |
|---|---|
| Fork Figma plugin **"Figma → Roblox (Aura Fishing)"** + relay | user runs `bunx cursor-talk-to-figma-socket`, opens the plugin (Development), Connect → fixed channel **`aura-fishing`** |
| `node "Figma For Roblox/cursor-talk-to-figma-mcp/scripts/figma-run.mjs" --channel=aura-fishing <command> <params.json>` | commands: `get_roblox_tree`, `build_tree`, `patch_nodes`, `export_node_as_image`, `set_image_fill`, `upsert_variables`, `upsert_text_styles`, `get_document_info` |
| `python -I docs/figma/apply_patch.py <ops.json>` | replace single nodes in place (`replaceId`, keeps position) / remove nodes |
| `python -I tools/art/figma_images.py --root <id>` | fill `Img <path>` layers (and `{img:…}` instance overrides) from `assets/art` |
| `python -I tools/art/extract_assets.py` | re-export global shapes, rescan Figma usage, regenerate the catalog |
| **StudioBridge** MCP (`tools/studio-mcp`, 14 tools incl. `run_luau`, `mount_ui_module`) | drive Studio: inspect tree, preview generated UI without Play. Studio must have the AuraStudioBridge plugin connected |
| Official Figma MCP | Starter plan quota is usually exhausted — prefer the fork plugin |
| Checks | `rojo sourcemap` + `luau-lsp analyze` (commands in `CLAUDE.md`) must be clean after every change |

---

## 5. Open decisions for the user
1. ~~Reel Minigame~~ — decided: **Pond Card** (done in code).
2. Upload assets to Roblox (needed before icons/art appear in game).
3. Inventory data model (items beyond fish: baits, treasures) before building screen 13.
