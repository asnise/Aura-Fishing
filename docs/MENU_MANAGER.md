# Menu Manager (core menu rules)

`src/client/UI/MenuManager.luau` is the one place that decides which screens may be open together.
Before it, every controller closed other screens by hand (or forgot to), so windows piled up on top of
each other. Now every screen registers once with a **layer**, and the manager closes whatever conflicts.

Added 2026-11-19. Tested in Play (see "Test log" below).

## 1. Layers

| Layer | Screens | Opening it closes | Notes |
|---|---|---|---|
| Hub | MainMenu | Main, Dialogue, Popup | The phone-style hub (key M). |
| Main | Inventory, Character, Shop, Fishdex, Auras (Aura Dex), Aquarium, Mastery, PutInTank, Store, Skills, Quests, Events, GachaPage, DailyLogin, Credits | Hub, Dialogue, Popup, and every other Main **except** the ones in its `StackOn` | One window at a time, unless stacking is allowed. |
| Dialogue | Dialogue (Old Marlin, Sela) | Hub, Main, Popup, other Dialogue | Opening any Main closes the dialogue. |
| Popup | ItemDetail (item card) | other Popup | Closed whenever a Main opens or closes. |
| Modal | Modal (confirm), AuraReel (reveal) | nothing | Always on top (baked DisplayOrder 30 / 50). |

Not managed on purpose (HUD-level, may show over anything): HUD, CastPopup, Minigame, TideEvent, DevPanel,
the offline reward popup, the Inventory "Bag Upgrade" overlay (internal to Inventory).

## 2. Stacking (windows that may sit on another window)

Set in the screen's registration (`StackOn`):

| Window | May stay on top of | Opened from |
|---|---|---|
| Skills | Character | SKILLS button in the Character header |
| Auras (Aura Dex) | Inventory | AURA DEX button in the Inventory footer (Auras tab) |
| GachaPage | Events, Inventory, Auras | Events card OPEN, ROLL AURA (Inventory), Go to Altar (Aura Dex) |
| PutInTank | Aquarium | + slot in the Aquarium (closing the picker shows the tank again) |

Rules:
- Closing a window also closes every window stacked on it (close Character = Skills closes too).
- Closing the top window shows the one below again (close Aura Dex = back to the Inventory).
- The manager sets DisplayOrder for Main windows: 10, 12, 14... by stack depth, so the top one is always
  drawn above. Do not hand-tune DisplayOrder of Main windows any more; the baked value is overwritten.
- GachaPage "back" arrow: if a window is under it, it just closes; otherwise it opens Events (old behaviour).

## 3. API

```lua
local MenuManager = require(UI.MenuManager)

MenuManager.Register(name, {
	Layer = "Main",                 -- "Hub" | "Main" | "Dialogue" | "Popup" | "Modal"
	Close = Controller.Close,       -- required
	Open = Controller.Open,         -- needed for MenuManager.Open / Toggle
	IsOpen = Controller.IsOpen,     -- lets the manager drop screens closed behind its back
	StackOn = { "Character" },      -- Main only
	Gui = function() return gui end, -- Main only: ScreenGui whose DisplayOrder the manager sets
})

MenuManager.WillOpen(name)  -- first line of the screen's Open (closes conflicts, pushes on the stack)
MenuManager.Closed(name)    -- last line of the screen's Close (safe to call twice)

MenuManager.Open(name, ...) / Close(name) / Toggle(name, ...)
MenuManager.IsOpen(name)
MenuManager.Top()           -- top-most screen name (Modal > Popup > Main > Dialogue > Hub)
MenuManager.CloseTop()      -- back button: closes only the top-most screen
MenuManager.CloseAll(layer?) -- nil = everything except Modal
MenuManager.OpenList(layer?) -- open names, oldest first
MenuManager.Describe()      -- "Main: Inventory > Auras | Popup: ItemDetail" (debug)
MenuManager.Changed         -- Signal (name, isOpen)
```

## 4. How to add a new screen (checklist)

1. Pick the layer from the table in section 1. When unsure, it is `Main`.
2. Code-built window: `Window.Create({ Name = "X", ..., StackOn = {...}? , Layer = "Main"? })` registers
   itself. Nothing else to do.
3. Baked screen with its own controller:
   - top of `Open`: `MenuManager.WillOpen("X")`
   - end of `Close`: `MenuManager.Closed("X")`
   - bottom of the module (before `return`): `MenuManager.Register("X", { ... })`
4. **Do not** close other screens yourself (`MainMenuController.Close()`, `ItemDetail.Hide()`,
   `InventoryController.Close()` before opening something). That is the manager's job; manual closes
   break stacking (this was the Skills bug found in testing).
5. Want it to sit on another window? Add that window's name to `StackOn`.
6. Run `node tools/check.mjs`, then test in Play with the Studio checks in section 6.

## 5. Where it is wired (2026-11-19)

| File | Screen names |
|---|---|
| `UI/Window.luau` | every `Window.Create` window (Skills, Store, PutInTank) |
| `UI/AquariumScreen.luau`, `UI/MasteryScreen.luau`, `UI/QuestsScreen.luau`, `UI/Credits.luau` | Aquarium, Mastery, Quests, Credits |
| `UI/ItemDetail.luau` | ItemDetail (Popup) |
| `UI/Modal.luau`, `UI/AuraReel.luau` | Modal, AuraReel (Modal) |
| `Controllers/MainMenuController.luau` | MainMenu (Hub) |
| `Controllers/InventoryController.luau`, `CharacterController.luau`, `EventController.luau`, `GachaPageController.luau`, `DailyLoginController.luau` | Inventory, Character, Events, GachaPage, DailyLogin |
| `Controllers/MenuController.luau` | Shop, Fishdex, Auras (three entries sharing the baked `Menus` ScreenGui) |
| `Controllers/DialogueController.luau` | Dialogue |

Removed manual closes: Quest/Economy/Dialogue `MainMenuController.Close()`, Economy Aquarium/Mastery
closing each other, Dialogue `ItemDetail.Hide()` and `Close()` before Shop / Altar, Character
`Close()` before Skills, Inventory `Close()` before Aura Dex / ROLL AURA, Events `Close()` before a banner,
Aura Dex `Close()` before ROLL AURA, Window kit's own `openWindows` loop.

## 6. Checking it in Studio

`execute_luau` on the Client gets its own module copies, so it cannot read the live manager state.
Read the PlayerGui instead:

```lua
local pg = game.Players.LocalPlayer.PlayerGui
local out = {}
for _, g in pg:GetChildren() do
	if g:IsA("ScreenGui") and g.Enabled then table.insert(out, g.Name .. "@" .. g.DisplayOrder) end
end
local vis = {}
for _, f in pg.Menus:GetChildren() do if f:IsA("GuiObject") and f.Visible then table.insert(vis, f.Name) end end
table.sort(out)
return table.concat(out, ", ") .. " | Menus: " .. table.concat(vis, ",")
```

Drive the game with `user_keyboard_input` (B, C, M) and `user_mouse_input` using the button's
`AbsolutePosition` (mouse x/y = GUI coordinates, not screenshot pixels).

## 7. Test log (Claude, 2026-11-19, Play)

- B: Inventory@10. Then C: Character@10, Inventory closed.
- SKILLS in Character: Character@10 + Skills@12 (stacked). Then M: both closed, MainMenu@20.
- B from Main Menu: Main Menu closed, Inventory@10. Auras tab, AURA DEX: Inventory@10 + Aura Dex@12.
  X on Aura Dex: back to Inventory.
- HUD Shop button while Inventory is open: Inventory closed, Shop open.
- No script errors in the console.
- Not tested yet: Dialogue (walk to an NPC), GachaPage stacking, Store / Aquarium / Mastery / Quests /
  Events / DailyLogin / Credits, Modal over a window, item card closing on window change.

Found while testing (not part of this change): `src/shared/Remotes.luau` line 64 had been changed to call
`RunService:IsEdit()`, which client scripts may not call, so the whole client failed to load. Changed to
`not RunService:IsRunning()` (same meaning in Edit mode, safe on the client).

## 8. Hand-off: remaining work (for the next agent)

Do these in order. Each is small; finish one, run check, test in Play, tick it in `docs/TASKS.md` (C24).

1. **M1 Play test of the untested paths** in section 7 (Dialogue, GachaPage from ROLL AURA / Events,
   Store, Aquarium -> Put in Tank, Mastery, Quests, Events, DailyLogin, Credits, Modal over Inventory,
   item card closes when switching windows). Fix anything that still opens two Main windows.
2. **[done 2026-11-20, test in Play] M2 Put in Tank stacks on Aquarium**: `EconomyController` closes the Aquarium before opening PutInTank
   (check how it returns to the tank). Change to `Window.Create({ Name = "PutInTank", ..., StackOn = { "Aquarium" } })`
   and remove the manual `aquarium.Close()` / reopen, so closing the picker shows the tank again.
3. **[done 2026-11-20, test in Play: `MenuManager.BindBackKey()` from `Main.client.luau`; ButtonB = CloseTop, Escape only when Dialogue is on top; Backspace not bound, waiting for the user] M3 Back key**: one input handler that calls `MenuManager.CloseTop()` for gamepad `ButtonB`
   (and Backspace on PC if the user agrees). Move the Dialogue Escape handler onto it. Note: Roblox
   always opens its own menu on Escape, so ask the user before binding Escape globally.
4. **[done 2026-11-20, test in Play: removed MainMenu avatar close, MenuController dead close, GachaPage openStore close, EventActions Gacha/Menu/DailyLogin `ctx.closeHub()` (and `closeHub` itself); Gacha from Events now stacks on Events] M4 Leftover manual closes**: grep `\.Close()` and `ItemDetail.Hide()` in controllers; any call made
   only to "make room" before opening another screen should be removed (keep closes that are the
   button's own job, e.g. a window's X button, or closing the item card after a sale).
5. **M5 Decision for the user (ask, do not guess)**: should a window opened from the Main Menu go back
   to the Main Menu when closed? (Today: it closes to the game.) If yes, add Hub support to `StackOn`
   or a `ReturnTo = "MainMenu"` field in the manager, not per controller.
6. **M6 Optional**: hide the HUD side buttons while a Main window is open on small screens, using
   `MenuManager.Changed` (ties in with C11 mobile).

Rules that still apply: no "✓", "•" or emoji in UI text or code; English in code; Thai to the user;
type check clean after every change; do not spend the user's in-game currency while testing.

## Window core (`UI/Window.luau` → `Window.Shell`) — 2026-11-20
Every code-built window gets its shell from `Window.Shell(opts)`: ScreenGui in PlayerGui (never StarterGui),
cream panel, standard header (title Fredoka 26 + red X 73x57), FitToScreen, Open/Close/IsOpen + MenuManager.Register,
and `SetLoading(true, target?)` (spinner overlay). Options: Name, Title, Close, Size, Padding, Radius, Layer, StackOn,
DisplayOrder, Dim, WindowName, AutoHeight. Uses it: Store, Aquarium, Mastery, Quests, Credits, EnhancePopup, and
`Window.Create` (Put in Tank, Skills). Baked screens (UI/Screens/*) keep their own ScreenGui but already open/close
through MenuManager. New window = `Window.Shell` + its content; don't hand-build a ScreenGui.
