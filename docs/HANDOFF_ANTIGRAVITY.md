# Handoff → Antigravity (2026-11-17)

You are continuing **Aura Fishing**, a Roblox fantasy fishing RPG (Luau + Rojo). Read this file first, then `CLAUDE.md` (project rules, still valid for any agent) and `docs/TASKS.md` (task list + test steps).
**Talk to the user in Thai.** Code, identifiers, comments in English.

---

## 1. Hard rules (user decisions — do not break)
1. **UI: Figma first, always.** Any in-game UI change → change the design in Figma first (file page "Out Space", plugin channel `aura-fishing`), then make the game match it and compare screenshots (`docs/figma/*.png`).
2. **Idle income is shown per second** ("+0.045/s", never "/min") and totals **tick up live every frame** with 2 decimals (`Aquarium.FormatRate` / `Aquarium.FormatPearls` in `src/shared/Aquarium.luau`).
3. **No separate Store button.** Tap the **Gems chip** → Store "Gems" tab, **Coins chip** → "Boosts & Packs", **Pearls chip** → Aquarium.
4. Data-driven: content = config tables in `src/shared/Config`; `Registry.luau` validates everything at startup.
5. Server authoritative; every bonus is a stat source through `Stats.Compute` (one pipeline).
6. Never hand-edit `src/client/UI/Generated/*`. Baked screens in StarterGui come from `src/client/UI/Screens/*` via `node tools/ui/bake.mjs <Screen>`.
7. After every change: type check must be clean (see §3). Update `docs/TASKS.md` (status ☐/◐/☑, "Done when", Thai test steps, a line in "บันทึกการอัปเดต").
8. Never enter API keys / passwords for the user. Uploads to Roblox (`tools/art/upload_assets.py`) are run by the user.
9. Studio place: the user's cloud place "Aura Fishing" (placeId 102636300140726). The user must **Save/Publish in Studio** after any in-place change (map, baked UI).

---

## 2. Project layout (Rojo)
| Folder | In game | What |
|---|---|---|
| `src/shared` | ReplicatedStorage.Shared | `Config/*` (all numbers/content), `Registry`, `Stats`, `Roll`, `Remotes` (all remote names), shared logic modules (`Aquarium`, `Mastery`, `Enhance`, `AuraStars`, `Boosts`, `HotFish`, `Quests`, `Skills`, `Rebirth`, `Inventory`) |
| `src/server` | ServerScriptService.Server | `Main.server.luau` (ORDER of services), `Services/*` |
| `src/client` | StarterPlayerScripts.Client | `Main.client.luau` (ORDER of controllers), `Controllers/*`, `UI/*` (`New` = UI kit + Theme, `Window` = code-built window kit, `AquariumScreen`, `Screens/*` = baked Figma screens) |

Save data: `DataService` TEMPLATE + `SCHEMA_VERSION` (now **5**) + `sanitize()` migrations.

## 3. Tooling
- Rojo 7.7.1: `D:\tools\rojo\rojo.exe` → `scripts\serve.bat` (live sync; Studio plugin Rojo → Connect).
- Type check (must be clean; the one `GetRankInGroupAsync` deprecation warning is pre-existing):
  ```
  D:\tools\rojo\rojo.exe sourcemap default.project.json -o sourcemap.json
  luau-lsp analyze --definitions=D:/tools/luau-defs/globalTypes.d.luau --sourcemap=sourcemap.json src
  ```
- **StudioBridge** (edit-mode Luau in Studio, port 3060): `node tools/studio-mcp/scripts/run-file.mjs <file.luau>`; used by `tools/ui/bake.mjs`, `tools/ui/resolve_decals.mjs`, `tools/map/boardwalk.luau`.
- **Figma**: relay `scripts\figma-relay.bat` + plugin "Figma to Roblox MCP (Aura Fishing)" on channel `aura-fishing`. Send any plugin command: `node "Figma For Roblox/cursor-talk-to-figma-mcp/scripts/figma-run.mjs" --channel=aura-fishing <command> params.json --timeout=300` (big edits time out over MCP — use this runner). Fill `Img <folder>/<name>` slots from `assets/art`: `python -I tools/art/figma_images.py --channel aura-fishing --root <nodeId> ...`.
- Art: `assets/catalog.json` → `tools/art/upload_assets.py` (user runs) → `node tools/ui/resolve_decals.mjs` → `python -I tools/art/sync_ui_assets.py` (regenerates `src/shared/Config/UIAssets.luau`). **All 164 assets have image ids now.**
- **Dev commands** in game: chat `!<cmd>` or F2 panel. `help` lists them. Useful: `give coins|gems|pearls N`, `give fish <id> N [mutation]`, `clearbag`, `level N`, `offline 2h`, `mastery <track> <lv>`, `enhance Rods <id> <lv>`, `stars <aura> <n>`, `pity Altar 99 [mythic]`, `grant/revoke pass <id>`, `receipt <product> [id]`, `unbuy <product>`, `boost coins 2h`, `hotfish <fish> 3`, `quests list|reroll|done`, `rebirths N`, `skillpoints N`, `skill <id> <lv>`, `event start|stop`, `reset`.
- Testing tip (Studio MCP mouse tool): screenshot pixel coords do NOT match click coords — click by `instance_path`. PlayerGui has a disabled duplicate `HUD`; rename it before clicking `LocalPlayer.PlayerGui.HUD.Hit_Pearls`.

## 4. Figma node ids (page "Out Space")
Economy sections: `3539:27458` HUD+Streak · `3539:27706` Icons · `3546:35498` **Aquarium** (window `3546:35509`, Put in Tank variants, Quantity modal, Offline popup) · `3539:31264` Mastery · `3539:29288` Enhance · `3539:31499` Auras+Gacha · `3546:36700` Store · `3539:30574` Hot fish + Hub · `3539:26815` 17 Character. Others: Components `3487:4280`, Art Library `3491:6690`, Game Menus `3492:16631`, Events `3533:24643`.

---

## 5. State: what is DONE (server + data; tested in Studio)
C12 Balance Pass 1 · C13 Robux receipts/passes (real Pass ids + 3 Gem product ids in `Config/Products.luau`) · C14 Aquarium + Pearls + offline · C15 Mastery · C16 Gear Enhance · C17 Aura stars + Star Tokens + new pity · C7 Daily quests · C6 pass effects (Infinite Bag, `Pass_<id>` player attributes) · C19 Starter Pack + Boosts · C18 Hot fish (deterministic per UTC hour) · C3 Rebirth + titles (`TitleController`) · C4 Skills (permanent points, Multi-Cast bonus fish) · C5 **Naga Tide** event (random glowing sea patch every :00/:30, special catches, crowd bonus — the old co-op tug boss was removed) · C10 Credits window · map deck lowered to 3 studs (`tools/map/boardwalk.luau`, backup `ServerStorage.Map_Backup_Deck9`) · ItemSlot mutation badge moved bottom-left · skeleton "Mystery Fish" flicker fixed.

In-game UI that exists now (code-built, `EconomyController`): Pearls chip on HUD; **Aquarium window matches Figma** (`UI/AquariumScreen.luau`); Put in Tank window (4:3 multi-select cards — **NOT yet matching Figma**); Mastery window (Window kit placeholder); Store window (Passes/Gems/Boosts & Packs, real Robux prices); offline "Welcome back" popup; Naga Tide panel (`TideEventController`); Settings & Credits; Rebirth confirm.

Contracts for every screen (data fields, remotes): `docs/HANDOFF_ECONOMY_UI.md`.

## 6. NEXT (priority order)
1. **Put in Tank → match Figma** (`3546:35498`, frames "Put in Tank (multi-select)", "tank full", "Quantity modal"). The user liked 4:3 cards — **decide with the user**: either update Figma to 4:3 cards first, then the game; or rebuild the game screen to the Figma item-slot grid + bottom selection bar + Quantity modal. Rates in /s.
2. **Mastery window → match Figma** `3539:31264` (7 cards, Lv, +x% → +y%, price in Pearls, UPGRADE / MAX). Add live Pearls ticking in its header.
3. **Store → match Figma** `3546:36700`; HUD Streak tag / Boost ring (`3539:27458`); Enhance in Shop (`3539:29288`); Aura stars + 2 pity rows + real rates (`3539:31499`, data: `Shared/AuraStars`, `Roll.AuraRates`); Quests window (`Shared/Quests`, flip `Features.Quests.Enabled`); Skills window (`Shared/Skills`, remote `UpgradeSkill`); Inventory "TANK" button + 🔥 hot badge; VIP name tag (`TitleController`, attribute `Pass_VIP`). Each: Figma first.
4. Vector icons (`icon_timer`, `icon_star`, … in Figma `3539:27706`) are not exported/uploaded — Offline-cap pill shows a grey dot.
5. **User actions pending**: Developer Products **Starter Pack 49 R$ (3733362354), 2x Coins (2h) 39 R$ (3733362467), 2x Pearls (2h) 39 R$ (3733362542)** are created and active; Gamepass **Extra Cast** needs pass id on site; Save/Publish place; test lists in `docs/TASKS.md` (many "รอทดสอบ").
6. Backlog: C8 SFX (user supplies sounds), C9 real map/models, C11 real mobile test, A17 mobile layout, B7 NPC dialogue, Summoning Bait, Extra Cast pass (`ExtraLines` stat already works).

## 7. Gotchas
- Robux prices from `GetProductInfo` are regional (Studio shows 20/75/179 for 25/99/249) — UI must show the API price.
- The game owner owns all passes in Studio → test "not owned" with another account.
- Studio Play copies StarterGui at Play start: after `bake.mjs`, stop and restart Play.
- `Window.Clear` destroys layouts and adds an inner margin (prevents clipped card strokes) — keep using it for code-built windows.
- Chips inside UIListLayouts: clicks are handled by transparent `Hit_<name>` buttons at ScreenGui level (`EconomyController.clickable`).
- Test edits that touch the user's Studio save (coins, bag, tank) — restore or tell the user.

---

## 8. AI Agent Workflow Policy & Decisions Log
1. **Mandatory Logging:** Any AI agent completing any task MUST write a summary update with an ISO/local timestamp to the active docs/task logs (`docs/DESIGN_DECISIONS_2026-11-21.md`, `docs/TASKS.md`).
2. **Game Design Decisions (2026-11-22):**
   - Full master decisions logged in `docs/DESIGN_DECISIONS_2026-11-21.md`.
   - Gamepass Luck: x1.25 multiplier.
   - Trading System: Trade License required to initiate, 4 slots max, no Aura trading, Coins tax (gold sink).
   - Rod Fusion: Same rod type only, 2 Prefix + 2 Suffix, Sub consumed to transfer 1 mod to Base with fail chance.
   - Gems Pacing: Uncommon+ fish drops at least 1 Gem; Manual 50 rolls/h (250 Gems), Auto 25-30 rolls/h.
   - Rebirth: Prestige Tree (RP), Aquarium fish and normal bait cleared (sold for coins warning), Rods and permanent quest bait preserved.

