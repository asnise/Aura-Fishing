# Aura Fishing — Agent Playbook (how Claude works this project)

For Codex, Antigravity and any coding agent. Written 2026-11-19 by Claude after a long working session
(B21, Economy UI, C21 content, C22 zone fix, B7 dialogue). Every rule below comes from something that
actually happened in this project, including mistakes. Follow it and you skip the mistakes.

Read order before any work: `AGENTS.md` (root) -> this file -> `CLAUDE.md` -> the relevant part of
`docs/TASKS.md`. Workspace memory: `C:/Users/User/AppData/Local/Roblox/AURA_FISHING_MEMORY.md`.
Step-by-step runbooks for each kind of task (coding and Figma design): `docs/AGENT_RUNBOOKS.md`.

---

## 1. Reading the user's request

The user writes short Thai messages. Classify the message before touching anything.

| User says | Means | Do |
|---|---|---|
| `งาน`, `งานต่อไปมีอะไร`, `เหลืองานอะไร` | "Give me the remaining work, prioritised" | Read TASKS overview + memory + quick source checks. Answer with a numbered list in groups (fix first / new work / user-only / decisions), a recommendation, and one question. **Do not start coding.** |
| `ข้ามงานตรวจ` / "skip testing" | Leave out items whose only remaining step is testing | Filter out `รอทดสอบ` items; list real work only |
| `เริ่ม X`, a number from your last list (`1.`, `2. งานเล็ก ๆ`) | Do exactly that item / group | Implement end to end (section 3) |
| `หยุดแล้ว bake เลย`, `หยุดแล้วทดสอบเลย` | Permission to stop Studio Play | Stop Play, bake, test. Permission is for this step only |
| A mid-task remark (e.g. "Aura tab should be normal items, Aura dex optional") | Course correction | Apply it to the current task immediately, mention it in the report |
| `ใช่ ฉันกดเอง` style answers | Answer to your question | Close the question, do not re-investigate |

Rules:
- A list request is not a work request. A work request is not permission to stop Play, spend the
  user's in-game currency, or publish.
- When the request is a group ("1. หน้าจอ UI ที่ค้าง"), first **verify which parts are really missing**.
  TASKS was stale: Aquarium, Mastery, Store, Quests, Boost and Tide HUD already existed although TASKS
  said "waiting for UI session". Grep the client for each hook before building anything (section 4).
- Ask only when the decision is truly the user's (game design numbers that change the economy,
  stopping their Play session, anything irreversible). Otherwise pick the sensible default, do it, and
  state the decision in the report so they can veto it.

## 2. Priority order (what to do first)

1. **User data and money safety.** Never click UPGRADE / ROLL / Sell-confirm / Buy in a test on the
   user's real save. Open the confirm dialog, then Cancel. If you see currency change unexpectedly,
   report it with numbers and ask; do not guess (in this project the user had enhanced gear himself).
2. **Bugs that can corrupt gameplay** (e.g. backup map in ServerStorage counted as fishing water) before
   features. Small, verifiable, high value.
3. **Finish what is half done** (a feature with code but no wiring) before starting new features.
4. **Unblock the user**: list the things only they can do (Ctrl+S, Creator Hub product IDs, uploads).
5. New features in TASKS order; mobile polish (A17/C11) last.

Within a task: correctness > matching the Figma design > nice-to-haves. Cut nice-to-haves into a
written TODO in TASKS instead of silently skipping them.

## 3. The standard task loop

Every task, every time:

1. **Plan list** (short imperative steps). Keep it current; it is what the user watches.
2. **Orient (cheap reads only)**
   - TASKS section for the item (Done when, decisions, Figma node ids).
   - `grep -n` for the system's names across `src/`; read function headers (`grep -n "^function\|^local function"`)
     before reading whole files. Read whole files only for the 1-3 you will edit.
   - Figma: the spec scripts in `docs/figma/*.py` and exported PNGs in `docs/figma/*.png` describe the
     designs. Read the PNG for the screen you build. Do not rebuild Figma (AGENTS rule).
3. **Check what already exists** (avoids double work): remotes in `shared/Remotes.luau`, server
   functions, shared helpers (`Inventory`, `Enhance`, `AuraStars`, `HotFish`, `Skills`, `Boosts`),
   UI kits (`New`, `Window`, `VirtualGrid`, `ItemSlots`, `ItemDetail`, `Modal`). In B21 every action the
   new card needed already had a remote, so **no new save fields** were needed - always look for that.
4. **Design inside the architecture** (CLAUDE.md rules):
   - Content = data in `src/shared/Config/*`, validated in `Registry.luau` (add a check block for new configs).
   - Server authoritative; new client->server call = add the name to `Remotes.luau` first.
   - UI: layout in `UI/Screens/<Name>.luau` (baked), behaviour in a controller found with `Baked.Get/Find`.
     Colours/fonts only through `New.Theme`. Only existing art keys from `Config/UIAssets.luau`.
   - Controllers start from `Main.client.luau` ORDER; add new ones there.
   - Cross-controller calls: use `HUD.<X>Requested` signals to avoid require cycles
     (MainMenu cannot require Economy because Economy requires MainMenu).
5. **Implement** with targeted edits. For many edits across files, write a Python edit script to the
   scratchpad and run it (see 5.1). Each replacement asserts the old text exists, so a wrong anchor fails loudly.
6. **QA**: `node tools/check.mjs` (sourcemap + luau-lsp + banned characters). Must print ALL CHECKS PASSED.
7. **Bake** changed screens (section 5.3), Edit mode only.
8. **Play test in Studio** (section 5.4) - drive it like a player, verify with text reads, screenshots
   only for layout.
9. **Fix what the test found**, re-check, re-bake, re-test the broken part only.
10. **Document**: TASKS (status line in the overview + a section with what changed, files, Done when,
    numbered Thai test steps, and a dated line in `บันทึกการอัปเดต`). Update the workspace memory file if a
    fact there became false.
11. **Report** in Thai (section 7).

## 4. Fast "does it already exist?" checks

```
grep -rln "<Remote or signal or config key>" src/client
grep -n "^function\|^local function" <file>
grep -n "Requested = Signal.new" src/client/Controllers/HUDController.luau
```
Example from this session: searching `"Streak"`, `PityHard`, `AuraRates`, `UpgradeSkill`, `Pass_VIP`,
`HotFish` in `src/client` gave the exact list of missing economy UI in one command.

Find unused uploaded art (content ideas): compare `Config/UIAssets.luau` keys that have a real id with
the ids in `Config/Fish.luau`, `Auras.luau`, `Equipment.luau` (C21 found 26 unused assets this way).
`docs/ART_PROMPTS.md` holds the intended look of each asset; use it for names and descriptions.

## 5. Tools and how to use them well

### 5.1 Editing
- Small change: exact-string edit. Large multi-file change: Python script in the scratchpad with an
  `edit(path, [(old, new), ...])` helper that asserts each `old` is present; run with `python -I script.py <root>`.
- **Do not pass big Python through a bash heredoc** when the code contains quotes/backticks: bash broke
  on it once. Write the script to a file, then run it.
- Luau gotchas seen here:
  - An inline `-- comment` placed before the comma of a table field swallows the comma (syntax error).
  - Tables in `if ... then {A} else {B}` with different fields fail type inference: assign to `local x: any`.
  - Don't name a local `select` (shadows the builtin).
  - `row.Name` is the Instance's Name property: never name a child "Name" if you index it as `row.Name`.
    Use `Key`, `Label`, `Title`.
  - `New.Button({ [New.Children] = {...} })` **replaces** the button's own Lip/Face layers: add extra
    children (e.g. `UIFlexItem`) after creation.
  - `UIPadding` on a panel also shrinks its 9-slice `Shadow` child (which draws the panel background):
    put padding on an inner `Content` frame.
  - `CollectionService:GetTagged` also returns tagged parts in ServerStorage/backups: filter with
    `IsDescendantOf(Workspace)` (`FishingSpot.ActiveTagged`).

### 5.2 QA command
`node tools/check.mjs`. If the output looks odd (exit 66, "FAILED" with 0 errors), redirect to a file
and read it; rerun once - it was a transient sourcemap race, not a real failure.

### 5.3 Baking UI into the place
- Normal: `node tools/ui/bake.mjs <Screen> [...]` (needs StudioBridge on http://127.0.0.1:3060, Studio in Edit).
- It ships only the requested screens + their `require(script.Parent.X)` dependencies (Studio rejects a
  script Source over 200,000 characters - fixed in `tools/ui/lib.mjs`).
- If StudioBridge is down: bake through the Roblox Studio MCP `execute_luau` (Edit): clone
  `StarterPlayer.StarterPlayerScripts.Client.UI.Screens.<Name>`, `require(copy).Build()`, set attributes
  `BakedFrom` / `BakedAt`, replace `StarterGui.<Name>`, destroy the clone. Same result.
- Rojo sync can lag 1-2 s: before baking or Play, check the synced Source contains your new text.
- Stale bake check: `BakedAt` is UTC, file mtimes are local (Asia/Bangkok, UTC+7). Convert before comparing.
- A screen built at runtime warning (`not baked`) can be a timing issue, not a missing bake: `Baked.Get`
  now waits 60 s and removes a late duplicate.

### 5.4 Studio (Roblox Studio MCP)
- `list_roblox_studios` first. If mode is **Play, the user is probably playing**: do not stop it
  without asking. Read-only checks in the Server/Client datamodel are fine.
- `execute_luau` on Client/Server **creates separate module instances**. Requiring a controller from
  there and calling `Open()` ran a second copy that destroyed the real grid's content. Never call
  controller functions from execute_luau; drive the game with input instead and read state.
- Driving the game: `user_keyboard_input` (B, C, M, E for prompts, F2 dev panel), `user_mouse_input`.
  Mouse coordinates = GUI coordinates (screenshot y minus the 58 px top bar). Get exact targets with
  `execute_luau`: `obj.AbsolutePosition + obj.AbsoluteSize/2`. Add a small wait between move and click.
- Teleport for tests on the Server: `char:PivotTo(part.CFrame * ...)` next to the prompt, then press E on the Client.
- Verify with text first (`Line.Text`, `gui.Enabled`, counts); screenshot only to judge layout.
  Images load asynchronously: an empty image right after opening a window is often just loading -
  verify with `ContentProvider:PreloadAsync` before "fixing" anything. 3D can render black in captures.
- Console: `get_console_output`. The CorePackages timeouts and `rbxassetid://203785492` messages are
  Roblox noise; look for your script names.
- Data in Play persists to the user's save: never spend their currency; cancel confirms.
- Stop Play when done so the user returns to Edit; remind them to **Ctrl+S** (baked UI is not saved
  until they save). Report "baked" and "saved" separately.

### 5.5 What not to do (cost)
- No heavy image uploads or screenshot dumps unless asked (AGENTS rule).
- Don't reread files you already have; don't read whole 1,000-line files for one function.
- Batch independent reads/commands in one turn. Run QA once per batch of edits, not per line.
- One Play restart per round of fixes; group fixes first.

## 6. Design decisions this project already made (reuse, don't re-ask)

- Inventory v2: 600x480, 7 bookmark tabs (All, Fish, Rods, Lines, Auras, Baits, Treasure), 7 columns x 72 px;
  the 84 px Components ItemSlot is scaled into a 72 px holder (`UI/ItemSlots.NewCell`).
- Item Card: `UI/ItemDetail.Show({Kind, Id, Index?, Info?}, anchor)` everywhere (Inventory, Character,
  Shop picture "Hit" buttons, Fishdex, Aura Dex). Kinds: Rod, Line, Aura, Fish, Bait, Treasure, Bag, Species.
  Buttons are 48 px, cost shown as `LABEL | icon value` on one line, short numbers (90K).
- Auras tab = owned auras as normal items; the full collection is the **Aura Dex** (old Auras window).
- Bags are upgrades (server refuses smaller bags); the last tier is the Infinite Bag pass.
- Character window: key **C** or Main Menu avatar; SKILLS button in its header opens the Skills window.
- Main Menu: 13 tiles, 4 columns, VIP pill under the avatar.
- NPC dialogue: data in `Config/Dialogues.luau`; world prompts say "Talk" and open Old Marlin / Sela.
- Opening/closing screens goes through `UI/MenuManager.luau` (layers + StackOn). Never close other
  screens by hand before opening one; read `docs/MENU_MANAGER.md` before adding a screen.
- Starter Bay depth 1000 m (lines go to 600 m / 1000 m).
- Content numbers are first guesses on the existing ladder; the user tunes them in Config.

## 7. Reporting to the user (Thai)

- Lead with the result in one sentence, then grouped details: what was added, what was fixed during
  testing (with the cause in plain words), decisions you made for them, what is NOT done or NOT tested.
- Keep these status levels distinct: code written / check passed / baked / tested in Play by the agent /
  verified by the user / saved (Ctrl+S) or published.
- Point to the TASKS item that holds the Thai test steps.
- End with **one** question with 2 choices when a decision is pending (which task next, may I stop Play).
- Never claim something was tested if you only read the code. Say "ตรวจจากโค้ด ยังไม่ได้ทดสอบ".

## 8. Case log (what was done, step by step, and the lesson)

**B21 Item Card + Inventory v2** - Read TASKS spec and Figma PNG (inventory_final.png) -> found every
needed remote existed -> decided "no new save fields", bag ladder derived from equipped bag ->
built Screens/Inventory, Screens/ItemDetail, UI/ItemDetail, rewrote InventoryController -> check -> asked
before stopping Play -> bake failed (200k Source limit) -> fixed lib.mjs to ship only needed screens ->
Play test found: buttons invisible (Children overwrite), price wrapping -> fixed. Lesson: test with real
input, not by calling controllers from execute_luau.

**B21 round 2 (Shop/Fishdex cards, Character, Aura Dex)** - Added invisible Hit buttons at runtime in
MenuController instead of rebaking Menus; extracted shared slot code to UI/ItemSlots; Character
window with ViewportFrame avatar (clone with Archivable, anchored parts, camera in front of -Z). Found
the avatar facing backwards and a `row.Name` collision during Play.

**Economy UI batch** - First grep proved most screens existed; built only the gaps (Streak tag, VIP tag,
+N, HOT badge, Merchant sign, Skills window, gacha pity rows / % rates / Star Tokens). Did not press
UPGRADE / ROLL. Noticed coins dropped -> reported and asked instead of assuming.

**Small fixes** - "HUD not baked" was a 15 s timing issue, not a missing bake; found a stale CastPopup by
comparing BakedAt (UTC) with mtimes; Main Menu updated to the Figma 13-tile hub.

**C21 content** - Listed uploaded-but-unused art, read ART_PROMPTS for intent, placed new items on the
existing value/price ladders, raised Starter Bay depth so new lines matter, verified Registry and drop
rates in Play.

**C22 zone fix** - Confirmed the bug read-only on the Server without stopping the user's Play, fixed all
three tag lookups (FishingZone, Tide spot, PlayArea) with one shared helper, updated TASKS + memory.

**B7 Dialogue** - Read the Figma spec function `s_dialogue`, used existing NPC art descriptions for names
and personality, made dialogue data-driven with Registry validation, changed prompts on the server,
baked through the MCP when StudioBridge was down, tested every choice with real input, cancelled the sale.

## 9. Handy snippets

Teleport next to a prompt and talk (Server, then Client key E):
```lua
local p = game.Players:GetPlayers()[1]
local part = workspace.Map:FindFirstChild("SellPrompt", true).Parent
p.Character:PivotTo(CFrame.new(part.Position + part.CFrame.LookVector * 6 + Vector3.new(0, 3, 0)))
```

Find a GUI target for a click (Client):
```lua
local b = game.Players.LocalPlayer.PlayerGui.Character.Window.Header.Skills
return tostring(b.AbsolutePosition + b.AbsoluteSize / 2)
```

Verify uploaded image ids load (Client):
```lua
local img = Instance.new("ImageLabel"); img.Image = "rbxassetid://<id>"
local st; game:GetService("ContentProvider"):PreloadAsync({ img }, function(_, s) st = s.Name end)
return st
```
