# Aura Fishing — Agent Runbooks (one per kind of task)

Companion to `docs/AGENT_PLAYBOOK.md` (rules, tools, pitfalls). This file replays **every kind of task
Claude did in this project** (2026-11-18 .. 2026-11-19) as a runbook: how to read the order, the
steps with the tool used at each step, the budget, what to watch for, when it is done, and how to
report. Pick the runbook that matches the user's message and follow it top to bottom.

Budget legend: **S** = a few tool calls, one turn. **M** = 10-30 calls, one turn. **L** = 30-80 calls,
may need the user once (Studio Play). Time = rough wall-clock at normal speed.

Index
1. Status / backlog question ("งาน", "งานต่อไปมีอะไร", "เหลืองานอะไร")
2. Build a new UI system from a Figma design (B21 Inventory v2 + Item Card)
3. Extend an existing system to more screens (B21 round 2: Shop, Fishdex, Character, Aura Dex)
4. "Finish the pending UI" batch (Economy UI: C4, C6, C12, C16, C17, C18)
5. Small fixes found during other work (HUD bake warning, stale bake, Main Menu hub, HUD chip)
6. Add game content from existing art (C21: fish, auras, rods, lines, baits)
7. Bug fix from code / Studio inspection (C22: backup map tagged parts)
8. New gameplay-facing system with data + UI + server hook (B7 NPC Dialogue)
9. Unexpected data change seen while testing (coins dropped)
10. Tooling failure during work (bake 200k limit, StudioBridge down, check.mjs flake)
11. Writing docs / handoffs for other agents (this file)

Part B — Design (Figma): design rules, Figma connection checklist, D1 explore options, D2 FINAL section,
D3 edit an existing screen, D4 design to code (match + compare), D5 Figma to Roblox export, D6 art and
icon pipeline, D7 screen with no design yet, design report template.

---

## 1. Status / backlog question

**Trigger:** `งาน`, `งานต่อไปมีอะไร`, `ลำดับงาน ... ข้ามงานตรวจ`, `เหลืองานอะไร`.
**Analysis:** the user wants a prioritised list, not code. "ข้ามงานตรวจ" = drop items that only wait for testing.
**Budget:** S, 1-3 minutes.

Steps
1. Read `AURA_FISHING_MEMORY.md` (workspace) and `docs/TASKS.md` overview (lines ~9-80). Tool: shell `sed -n` / file read.
2. If you are new to the session, also list recent Claude/Codex sessions or handoff docs only if TASKS
   looks out of date (the first ever request was answered from `Claude-Sessions/SESSIONS.md` +
   TASKS of the most recently active project).
3. Spot-check anything that decides priority (e.g. "is Daily Login built?" -> `grep -rni dailylogin src`).
4. Group the answer: **fix first** (bugs, place baseline) / **new work** in TASKS order / **user-only**
   (Ctrl+S, Creator Hub IDs, uploads) / **decisions waiting** (design questions).
5. Recommend one item with a one-line reason; end with one question offering 2 choices.

Watch for: TASKS statuses can be stale (several "waiting for UI" items already had screens). Say
"needs checking" rather than asserting status you did not verify.
Exact answer format and an example: docs/AGENT_PROMPTS.md section 0 (BACKLOG ANSWER RULE).
Done when: user picks an item.

## 2. Build a new UI system from a Figma design (B21)

**Trigger:** `เริ่ม B21` (an item with a finished Figma design in TASKS).
**Analysis:** the TASKS section lists the chosen Figma options, sizes, node ids, PNG exports and open
data-model questions. Answer the data-model question yourself if existing data covers it.
**Budget:** L, 45-90 minutes. Needs Studio Edit mode once (ask before stopping Play).

Steps
1. Plan list (5-6 steps). Read the TASKS section + `CLAUDE.md` rules.
2. Look at the design: read `docs/figma/<screen>.png`; read the spec script (`docs/figma/*.py`) for exact
   sizes (window 600x480, slot 72, buttons 48, card 280).
3. Inventory of existing pieces: remotes (`Remotes.luau`), shared helpers (`Enhance`, `AuraStars`,
   `Inventory`), current controller + screen, `VirtualGrid`, `Components` (ItemSlot is 84 px).
   Result here: every action already had a remote -> **no save-schema change**.
4. Server first (small): rules the UI depends on (bag ladder helpers, refuse smaller bags in Buy/Equip).
5. Screen builders (`UI/Screens/X.luau`) with Figma sample content; controller(s) that bind data.
   Scale the 84 px component into 72 px cells with a holder + `UIScale` instead of a new component.
6. `node tools/check.mjs` -> fix type errors (union-table inference: `local x: any`).
7. Ask to stop Play -> bake -> Play test with real input (key B, clicks). Read state with `execute_luau`
   text queries; screenshot for layout.
8. Fix what Play shows (invisible buttons = Children overwrite; wrapped prices = short numbers, no wrap).
9. TASKS: status line, files, decisions, numbered Thai test steps, what is NOT tested (Bag Upgrade
   when the save owns Infinite Bag), update log line.

Watch for: calling controller functions from `execute_luau` (second module copy breaks the UI);
spending the user's currency while testing; a mid-task user correction (Auras tab = owned only) must
be applied immediately.
Done when: screens baked, every visible part exercised in Play, untested parts listed.

## 3. Extend an existing system to more screens (B21 round 2)

**Trigger:** "finish B21" / a list of places the feature must also appear.
**Budget:** L, 40-60 minutes.

Steps
1. Read how each target screen is filled today (`MenuFill.fillShop`, `fillFishdex`, Auras rows).
2. Prefer **runtime hooks over rebaking big screens**: invisible `Hit` TextButtons added once in the
   controller's `ensure()`, handler set per fill. Menus did not need a rebake.
3. Extend the shared module with new kinds (`Bag`, `Species`, `Info` for catalogue items) instead of a
   second card.
4. Extract duplicated code the moment a second window needs it (`UI/ItemSlots.luau` for Inventory + Character).
5. New window (Character): screen builder + controller + entry points (key C, Main Menu avatar) + `Main.client` ORDER.
6. Use signals for cross-controller opening (`HUD.CharacterRequested`, `HUD.SkillsRequested`).
7. Bake only changed screens; Play test each entry point; check layout of 3D content (ViewportFrame
   avatar faced backwards -> fix pivot; camera framing).
8. TASKS + test steps.

Watch for: a child named `Name` (collides with the property); 3D in screenshots may render black - verify
with data (model exists, camera CFrame) before changing code.

## 4. "Finish the pending UI" batch (Economy UI)

**Trigger:** `1. หน้าจอ UI ที่ค้าง` (a group of items).
**Analysis:** a group order means "close the gaps", not "rebuild everything".
**Budget:** L, 60-90 minutes.

Steps
1. **Gap check first** (5 minutes saves an hour): grep the client for each item's hook
   (`"Streak"`, `PityHard`, `AuraRates`, `UpgradeSkill`, `Pass_VIP`, `HotFish`, `Boosts.Remaining`).
   Read the handoff doc for the data contract (`docs/HANDOFF_ECONOMY_UI.md`). Result: Aquarium, Mastery,
   Store, Boost, Quests, Tide HUD already existed.
2. Read the Figma exports for the real gaps (`economy_hud.png`, `economy_auras.png`, `economy_hot.png`,
   `economy_enhance.png`).
3. Order: smallest first so progress is visible (VIP tag -> Streak tag -> +N badge -> HOT badges +
   Merchant sign -> Skills window -> gacha pity/rates/tokens).
4. Reuse kits: code-built `Window` + `Window.Row` for a screen with no Figma design (Skills); runtime
   badges in shared cell code; a world BillboardGui controller for the Merchant sign.
5. One check run after each item; one bake + Play session for the whole batch.
6. Test without spending: open UPGRADE / ROLL screens but do not press them.
7. Correct the stale TASKS overview statuses for every item you verified.

Watch for: unexpected currency changes (runbook 9).

## 5. Small fixes found during other work

**Trigger:** `2. งานเล็ก ๆ ที่เห็นระหว่างทำ`.
**Budget:** M, 20-30 minutes.

Steps
1. Reproduce the claim before fixing: "HUD is not baked" -> `StarterGui` listing showed HUD **was**
   baked -> real cause: `Baked.Get` waited only 15 s for a slow first spawn -> fix: wait 60 s and drop a
   late duplicate.
2. Look for siblings of the issue: compare every screen's `BakedAt` (UTC) with file mtimes (UTC+7);
   CastPopup was stale -> rebake.
3. Design drift: compare the in-game screen with the Figma export (Main Menu had 10 tiles, Figma 13 +
   VIP pill) -> update the builder, add actions via signals.
4. Fix tiny inconsistencies you see in screenshots (HUD bag chip `/ 999` -> `/ Inf`) and say they were
   not separately tested if you did not look again.

## 6. Add game content from existing art (C21)

**Trigger:** "รูปที่อัปโหลดแล้วยังไม่ได้ใช้ เอาไปเพิ่ม content".
**Analysis:** content = Config data only. Numbers are design; choose sensible defaults on the existing
ladder and tell the user they can tune them.
**Budget:** M, 20-40 minutes.

Steps
1. Script: list `UIAssets` keys with a real id that no Config uses (fish/, auras/, equipment/).
2. Read intent from `docs/ART_PROMPTS.md` (descriptions) and GDD depth bands.
3. Read the current ladders (fish BaseValue by rarity/depth, rod stats/prices, bait luck, aura chance
   and stats) and the Registry checks (Difficulty 1..10, known Pattern, Currency, BuyAmount).
4. Place new items on the ladder; fix anything that would make them useless (Starter Bay max depth 300
   -> 1000 for 600 m / 1000 m lines). Re-number `Order` so lists stay sorted by rarity.
5. Apply with one Python edit script; run check.
6. Play: wait for Rojo sync (check Source), then read counts and drop rates with `execute_luau`; open the
   Shop to see new art (images may load late).
7. Report effects on existing balance (old aura odds shift) and unused art (`deco_*`).

## 7. Bug fix from inspection (C22)

**Trigger:** `แก้ FishingZone ก่อน` (an item flagged by inspection, not by a crash).
**Budget:** S-M, 10-20 minutes.

Steps
1. Find every lookup of the same pattern (`GetTagged` for FishingZone, TideEvent spot, **and PlayArea**),
   not only the two named in the note.
2. One shared helper (`FishingSpot.ActiveTagged/Zones`) used by all call sites; remove unused locals
   (luau-lsp warns).
3. Verify read-only on the live Server without stopping the user's Play: list tagged parts with
   `IsDescendantOf(workspace)`, compute old vs new result for the backup zone centre.
4. TASKS + update the memory file line that described the bug as open.

## 8. New system with data + UI + server hook (B7 Dialogue)

**Trigger:** `เริ่ม B7`.
**Budget:** L, 40-60 minutes.

Steps
1. Design source: `docs/UI_STYLE.md` rules + `cozy_menus_spec.py` function for the screen (`s_dialogue`)
   for sizes/positions on the 1280x720 frame.
2. World inventory (read-only Studio Server): ProximityPrompts and NPC models -> Merchant SellPrompt,
   Altar RollPrompt. Character identities from `docs/ART_PROMPTS.md` (Old Marlin, Sela).
3. Icons: only existing `icon_*` keys (fish, flame, reel, chat, star, info).
4. Data-driven: `Config/Dialogues.luau` + Registry validation block; new remote `OpenDialogue`.
5. Server: prompts become "Talk / <NPC>" and fire the remote (keep the old behaviour as fallback if the
   config entry is missing).
6. Client: screen builder (box, speaker tag, 4 choice bubbles, round close) + controller (typewriter,
   actions: SellAll with the same confirm modal, HotFish, Banner, Menu, Say, Talk; close on X / Esc /
   walking away).
7. Bake (MCP fallback if StudioBridge is down), Play: teleport next to each prompt, press E, click every
   choice, Cancel the sale, test walk-away. Fix layout (padding vs 9-slice shadow).
8. TASKS + memory; tell the user that the shop prompt no longer sells instantly.

## 9. Unexpected data change seen while testing

**Trigger:** your screenshot shows currency/items different from before.
**Budget:** S, 5 minutes.

Steps
1. Stop and compute: old value, new value, difference; match it against costs in Config (enhance 3 levels
   = 90k + 135k + 202.5k, plus a 15k line = exactly the difference).
2. List your own inputs since the last known value; say plainly whether any could have caused it.
3. Ask the user one question with two answers ("I did it" / "please investigate"). Do not "fix" data.
4. Remember: the user also plays in the same Studio between your turns; numbers change (levels, coins).

## 10. Tooling failure during work

| Symptom | Cause found | Fix / workaround |
|---|---|---|
| bake: "Source length >= 200000" | prelude shipped every screen | `lib.mjs` ships only requested screens + their `script.Parent.X` deps |
| bake: "StudioBridge not reachable" | port 3060 server not running | bake through Roblox Studio MCP `execute_luau` (clone screen module, Build, replace StarterGui child) |
| check prints FAILED with 0 errors / exit 66 | transient sourcemap/IO race | redirect output to a file, read it, rerun once |
| bash heredoc "unexpected EOF" | quotes/backticks in inline Python | write the script to scratchpad, run the file |
| Play shows old config | Rojo sync lag | check the synced Source contains new text, restart Play |
| Click lands in the wrong place | screenshot vs GUI coordinate offset (58 px) | compute targets from `AbsolutePosition` |

## 11. Writing docs / handoffs for other agents

**Trigger:** "ทำเป็น .md ให้ Agent อื่นอ่าน".
**Budget:** M, 15-30 minutes.

Steps
1. Write from evidence of the session (actual commands, incidents, fixes), not generic advice.
2. Split: rules/tools/pitfalls (`AGENT_PLAYBOOK.md`) vs per-task runbooks (this file).
3. English for agents (short sentences, tables, commands); Thai only for user-facing test steps.
4. Link from the root `AGENTS.md` read order so every agent finds it; add a TASKS log line.
5. Keep facts that will go stale (current status) in TASKS / memory, not here.

---

## Report template (Thai, end of every task)

```
<ผลลัพธ์ 1 ประโยค + สถานะ: เขียนโค้ด / check ผ่าน / bake แล้ว / ทดสอบใน Play / ยังไม่ได้เซฟ>

**สิ่งที่ทำ**
- ...
**แก้ระหว่างทดสอบ**
- <อาการ> เพราะ <สาเหตุ> แก้โดย ...
**ข้อควรรู้ / สิ่งที่ตัดสินใจแทน**
- ...
**ยังไม่ได้ทำ / ยังไม่ได้ทดสอบ**
- ... (ขั้นตอนทดสอบอยู่ใน TASKS ข้อ X)

<คำถามเดียว + 2 ตัวเลือก ถ้ามีเรื่องให้ตัดสินใจ>
```

---

# Part B — Design (Figma) runbooks

Source: the project's design tooling and its recorded history (TASKS A14/A15/A18/B0-B21, the Figma
fork `HANDOFF.md` + `AGENTS.md`, `docs/figma/*.py`, `tools/art/*`, `tools/ui/*`). In the 2026-11-19
session Claude did not open Figma; these runbooks describe how design work is done in this project
and how it feeds the code runbooks above.

## Design rules that override everything

1. **Never invent art.** Only existing project artwork and icons (`assets/art`, `Config/UIAssets`,
   Figma Art Library / global icons `3539:27990`). Missing art = empty slot or existing placeholder.
2. **Never overwrite the user's manual Figma work.** No automatic rebuild of a section. Add new
   sections (free x/y on page "Out Space") or patch the named nodes the user asked about.
3. **Figma first or code first?** Root `AGENTS.md` (code-first for gameplay, fixes, UI tweaks, config)
   supersedes the older "Figma first, always" in `docs/HANDOFF_ANTIGRAVITY.md`. Practical rule:
   - new screen or big layout change: look for an existing Figma design first; if there is none, ask
     whether to design it first or ship a placeholder built with the `Window` kit and log a design TODO;
   - tweaks, fixes, data, wiring: code directly, keep matching the existing design.
   (The Skills window and the Character SKILLS button shipped code-first with no Figma frame: recorded design debt.)
4. Cozy Lake only: tokens in `docs/UI_STYLE.md` = `New.Theme`; one border colour (Track #E6DCCB, 2px);
   buttons = Face + 5px Lip; radius windows 24 / cards 18 / buttons 16 / chips pill; Fredoka One for
   display, Nunito Bold for body. No check marks, bullets or emoji in any text (AGENTS rule 6).
5. Numbers: Pearls as integers, rates `+X/s`, every money field fits 6 characters (12.4k, 1.2M).

## Figma connection checklist (before any Figma command)

1. `scripts\figma-relay.bat` is running (the fork relay on port 3055, not the upstream `bunx` relay).
2. Figma desktop is open on the Aura Fishing file, plugin "Figma to Roblox MCP (Aura Fishing)" is open,
   channel `aura-fishing`.
3. MCP: `join_channel`, then `get_selection` (start from what the user selected; trust node `note`s).
4. Scripts: `node "Figma For Roblox/cursor-talk-to-figma-mcp/scripts/figma-run.mjs" --channel=aura-fishing --agent=<you> <command> <params.json>`.

If any step fails, stop and tell the user which one; do not guess node ids.

Speed (from the fork AGENTS.md): compact reads (`depth`, `fields`, `maxNodes`) are about 10x smaller;
`find_nodes` instead of reading whole pages; many edits = one `batch_commands` (use `"$0.id"`
references, `brief: true`); big `build_tree` ops go through `docs/figma/send_blocks.py` (about 150 nodes
per call). Each agent command is one undo step for the user.

## D1. Explore options for a new screen (Inventory v2, Item Card, empty slot)

**Trigger:** a new screen or component with no chosen look ("ออกแบบ", "ขอหลายแบบ", a TASKS item with "options").
**Budget:** L, 45-90 minutes. The output is a Figma board, not code.

Steps
1. Read the TASKS request and `UI_STYLE.md`; collect the data the screen must show (Config / shared
   modules) so every option shows real content.
2. Write or extend a spec script `docs/figma/<name>.py` (patterns: `item_detail.py`, `itemslot_options.py`,
   `empty_slots.py`): small builder helpers (`card`, `btn`, `img`, `text`) produce `build_tree` ops; one
   section "<nn>A · <Name> — N options" at a free x/y on "Out Space".
3. Make 4-8 clearly different options (layout, density, tab style) with the same real sample data.
4. Send with `send_blocks.py`; fill images with `tools/art/figma_images.py --root <sectionId>`
   (layers named `Img <folder>/<name>`).
5. Export a PNG of the board to `docs/figma/<name>_options.png` for review in chat.
6. Ask the user to pick and how to adjust. Record the choice and node ids in TASKS.

Watch for: art that does not exist yet. Leave the `Img` slot empty and list the missing assets
(`docs/ART_PROMPTS.md` sheets) instead of drawing placeholders.

## D2. Build the FINAL section from the chosen option

**Trigger:** the user picked ("เลือกแบบ 2 แต่เล็กลง", "ใช้การ์ด A").
**Budget:** M-L, 30-60 minutes.

Steps
1. New script (pattern `inventory_final.py`) that imports the options script and overrides sizes
   (window 600x480, slot 72, buttons fixed 48).
2. Build every state the code will need: each tab, owned vs not owned, selected / empty / equipped,
   popups (Bag Upgrade normal + last tier), and a spec card with exact sizes.
3. New section "<nn> · <Name> — FINAL"; never edit the options board.
4. Update screens affected by the new model (Character v2 lost the Bag slot) as new frames.
5. Export `docs/figma/<name>_final.png`; write sizes, node ids and scripts into TASKS ("Figma FINAL").
6. Hand over to code: runbook 2 (Part A).

## D3. Edit an existing (possibly hand-tuned) Figma screen

**Trigger:** "แก้ใน Figma ...", "ปรับ X ให้ตรงกับเกม", the user selected a node.
**Budget:** S-M.

Steps
1. `get_selection` (ids, path, note). If nothing is selected, `find_nodes` by name inside the section id from TASKS.
2. Compact read of only that subtree (`get_node_info` with `depth: 2` and `fields`).
3. Patch only the named nodes (`patch_nodes`, text, fills) in one `batch_commands`.
4. Leave a `set_node_note` saying what changed and why.
5. Re-export the PNG if docs reference it. Log in TASKS.

Watch for: rebuilding a section to "fix" it destroys the user's manual tweaks. Forbidden.

## D4. Design to code (make the game match Figma)

**Trigger:** code work for a screen that has a FINAL frame.
**Budget:** part of the code runbook.

Steps
1. Get exact numbers from the spec script (sizes, paddings, gaps, font sizes) or
   `python -I tools/ui/figma_dump.py <nodeId>` (one line per node: position, size, fill, radius, text).
2. Build `UI/Screens/<Name>.luau` with the Figma layer names where possible; Figma sizes as offsets;
   fonts via `New.FigmaSize`; colours only from `New.Theme`; images via `New.Image` keys.
3. Bake, then compare: `node tools/ui/preview.mjs <view>` shows the screen with Figma sample data in the
   Studio viewport; capture it and run `python -I tools/ui/compare.py <figma.png> <studio.png> <out>`
   (heatmap + worst tiles). Fix the worst tiles first. Run `preview.mjs off` before saving.
4. Where Roblox cannot match exactly (UIPadding vs the 9-slice shadow, AutomaticSize text measuring),
   note the deviation in the screen builder's header comment.

## D5. Figma to Roblox export (generated modules)

**Trigger:** a frame should become a Roblox module automatically (the A14 path).
`export_to_roblox` (figmaUrl / nodeId / selection) writes `src/client/UI/Generated/<Module>.luau` and
`assets/ui/<Module>/*.png`; layer hints `[btn] [img] [skip] [scroll]`; upload the images, paste the ids
into the module's `Images` table; wire behaviour from a controller via `Refs`. **Never hand-edit
generated files**: change Figma or the converter (`src/talk_to_figma_mcp/roblox.ts`) and re-export.
Use it for static, art-heavy layouts; hand-build (D4) data-driven windows.

## D6. Art and icon pipeline (shared by design and code)

1. Asset list and cell order: `tools/art/sheets.json`; prompts doc `docs/ART_PROMPTS.md`
   (`python -I tools/art/make_prompts.py`). The **user** generates the sheet images; agents do not.
2. Slice: `python -I tools/art/slice_grid.py <sheet_id> <image.png>` -> `assets/art/<folder>/<name>.png`.
3. Catalog: `assets/catalog.json` -> `docs/ASSET_CATALOG.md`; upload batch folder `assets/upload/<date>/`
   with `ids.csv`; the **user** uploads in the Studio Asset Manager; then
   `python -I tools/art/sync_ui_assets.py <ids.csv>` regenerates `Config/UIAssets.luau`.
4. Decal ids must be resolved to Image ids (`tools/ui/resolve_decals.mjs`); verify in Play with
   `ContentProvider:PreloadAsync` (snippet in the playbook).
5. Into Figma: `tools/art/figma_images.py --root <id>` fills `Img <path>` layers.
6. Uploaded but unused art is a content opportunity (runbook 6, Part A).

## D7. A screen with no design yet

**Trigger:** code needs a window and there is no Figma frame (Skills; Store before its design).

Steps
1. Search TASKS and the Figma exports for an existing design (the economy PNGs cover most HUD and
   economy pieces).
2. If there is none and the user wants it now: build it with the `UI/Window` kit (`Window.Create`,
   `Window.Row`) in Cozy Lake, keep it simple, and log "design TODO: <screen>" in TASKS.
3. Offer the user a D1 options board as the next step instead of designing silently in code.

## Design report template (Thai)

```
<สิ่งที่ออกแบบ + section ใน Figma (ชื่อ + node id + ตำแหน่ง x/y)>
- ตัวเลือก / FINAL มีอะไรบ้าง (ภาพ: docs/figma/<name>.png)
- ใช้รูปที่มีอยู่แล้ว: ...  ช่องที่ยังไม่มีรูป: ... (ต้อง gen ชีต N)
- ไม่ได้แตะ section เดิมของคุณ
คำถาม: เลือกแบบไหน / ปรับอะไร
```
