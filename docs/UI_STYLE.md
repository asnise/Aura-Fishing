# Aura Fishing — UI Style: **Cozy Lake** (selected 2026-11-16)

Direction E from the Figma board "Aura Fishing — UI Style Directions" (page *Out Space*).
Mood: soft pastels, cream cards, no hard outlines, rounded and friendly. Calm "chill fishing" feeling
that still pops for rare catches (rarity colours stay saturated).

Code source of truth: `src/client/UI/New.luau` → `New.Theme`. Change colours there, not in controllers.

## Colour tokens
| Token | Hex | Use |
|---|---|---|
| Scene / Mint | `#BFE8E0` | full-screen overlays, menu backdrop tint |
| Panel (cream) | `#FFF8EC` | cards, windows, chips |
| PanelLight (sand) | `#F3E9D8` | rows inside panels, secondary buttons |
| Track | `#E6DCCB` | bar tracks, dividers, panel edge |
| Text | `#3D4B5C` | primary text on cream |
| SubText | `#7A8A99` | secondary text |
| OnAccent | `#FFFFFF` | text on coloured buttons |
| Accent (coral) | `#FF9E80` / lip `#E07A5C` | primary action (CAST, Buy) |
| Sky | `#9AD4F5` / lip `#6BB3DE` | secondary action, water, depth |
| Good (mint) | `#7FD3B0` / lip `#4FAF8A` | success, XP, catch bar |
| Gold | `#F2B544` / lip `#C98B1E` | coins, Sell |
| Gem (lavender) | `#B79CF2` / lip `#8C6FD6` | gems, aura roll |
| Bad | `#F27A7A` | errors, close |

Rarity (deeper pastels so they read on cream): Common `#9AA5B1`, Uncommon `#5CC98A`, Rare `#5AA9F0`,
Epic `#B07CF0`, Legendary `#F2A93B`, Mythic `#F2668B`.

## Typography (Roblox fonts)
- **Display / numbers / buttons:** Fredoka One (`rbxasset://fonts/families/FredokaOne.json`)
- **Body / labels:** Nunito Bold (`rbxasset://fonts/families/Nunito.json`, `Enum.FontWeight.Bold`)
- Sizes: Display 40, Title 26, Heading 20, Button 20–34, Body 16, Small 14, Caption 12.

## Shapes
- Radius: windows 24, cards 18, buttons 16, chips = pill.
- **All borders use one colour: `Track` #E6DCCB, 2px** (panels, cards, windows, chips, minigame). Rarity is shown with tags/text colour, never with borders.
- Buttons: "soft lip" — Figma bottom-only inside stroke 5px; in Roblox two layers: `Lip` (full size, lip colour) + `Face` (height −5, face colour, same corner) + `Face.Label`. Hover = lighter face, press = face drops 3px onto the lip.

## Figma conventions (for FigmaRoblox export)
Use these exact hex values and fonts in Figma; name buttons `Btn …` or `[btn]`; shadows/blur must be `[img]`.

## Figma (built 2026-11-16, page *Out Space*)
- Style guide frame: **Aura Fishing — Cozy Lake Style Guide** (`3487:4345`)
- Components frame: **Aura Fishing — Components** (`3487:4280`) — Button (7 styles), Chip (4), Rarity Tag (6), Progress Bar, Catch Card, Shop Row
- Variables: collections *Aura Fishing · Cozy Lake* (colours, `cozy/*`) and *Aura Fishing · Size* (radius/space)
- Text styles: `Aura Fishing/Display, Title, Heading, Number, Button, Body, Small, Caption`
- Rebuild/update: edit `docs/figma/cozy_lake_spec.py`, run it, then send the JSON files with
  `node "Figma For Roblox/cursor-talk-to-figma-mcp/scripts/figma-run.mjs" --channel=<channel> <command> <file>`
  (fork plugin "Figma → Roblox (Aura Fishing)" open + relay on port 3055). No Figma MCP quota needed.

## Item Slot (chosen 2026-11-16: Option F "Corner Ribbon", no star)
- Square **1:1** (88px default, 84px in the Inventory drawer), white tile, radius 20, `Track` 2px border, soft shadow.
- Rarity = plain triangle in the top-left corner (rarity colour). Count = `x23` bottom-right, Fredoka One 15, text colour.
- States: Selected = coral 3px ring + coral check badge; New = coral "NEW" pill top-left; Empty = sand tile with "+"; Locked = 70% opacity + lock icon.
- Mutation = small badge (e.g. `fish/mut_glowing`) at the top-right.
- Figma: component set **Item Slot** in the Components board (variants `Rarity=… , State=…`). Spec: `item_slot()` in `docs/figma/cozy_menus_spec.py`.

## Reel Minigame (chosen 2026-11-16: Option C "Ring Reel")
- Cream circle (300px) with a sky ring track; the **green catch arc** (size = CatchBarSize stat, 0.22 ≈ 79°) spins clockwise while holding and drifts back when released.
- Fish swims around the ring; progress = gold donut + % in the centre; hint pill underneath with the rarity tag.
- Arc turns bright mint while the fish is inside, pale mint otherwise.
- Code: `FishingController.runMinigame` (built from round Frames, no image assets). Tuning: `GameConfig.Minigame.Ring*`.
- Figma: section "03 · Reel Minigame" + board "Reel Minigame · 6 options" (C marked CHOSEN). Spec: `ring_reel()` in `docs/figma/reel_options.py`.

## Roblox safe areas (CoreGui draws ABOVE our UI)
Figma frames are 1280×720 including Roblox's top bar; in code `IgnoreGuiInset = false`, so code y=0 = Figma y=58.
| Roblox UI | Where (Figma px) | Rule |
|---|---|---|
| Top bar (menu + chat buttons) | y 0–58, full width | nothing of ours above y 64 |
| Chat window (desktop, when open) | x 8–388, y 64–274 | only the Stats card may sit under it |
| Leaderboard (leaderstats) | x 1032–1268, y 64–234 | keep clear — never put close buttons here |
| Mobile thumbstick | bottom-left ~ x 50–200, y 510–660 | no buttons |
| Mobile jump button | bottom-right ~ x 1120–1216, y 550–646 | Bag/Auto/Sell lifted 150px on touch devices |
HUD placement: Stats top-left (y 70) • menu column left (y 292) • actions right-middle • depth pill + CAST bottom-centre • toasts top-centre (y 70) • windows centred and right edge ≤ 1020.
Every Figma screen has a toggleable `[skip] Roblox CoreGui (guide)` layer; section "00 · Roblox Safe Areas" shows the zones.

## HUD Stats (component set, 6 styles)
Component set **HUD Stats** (Components board) — property `Style` = A Classic Card / B Level Badge / C Top Bar Strip / D Avatar Card / E Minimal Floating / F Aura Spotlight.
**Chosen: E Minimal Floating** — no panel, no aura; `Lv.12` (Fredoka 30, white + slate outline) and `340 / 900 XP` as text (no bar); coin + gem chips below.
All screens use an instance of style E. Code: HUDController "HUDStats". Preview board: section "HUD Stats · 6 options". Spec: `docs/figma/hud_stats.py`.

## Inventory capacity
Text only: `18 / 50` pill next to the "Inventory" title (no progress bar).

## Cast & depth (2026-11-16)
- No depth panel on the HUD. CAST opens the **Cast popup**: Auto-depth checkbox, big depth readout + zone pill, zone-coloured slider (max = line), presets (Shallow / Mid / Max), species count, CAST!.
- **Auto depth** ticked → CAST casts immediately with a random reachable depth (server picks it; client sends depth = -1). Auto Fishing also uses a random depth each cycle.
- Small **DEPTH** button next to CAST shows `AUTO` or `80m` and reopens the popup.
- Code: `src/client/UI/CastPopup.luau`, FishingController `openCastPopup`, server `Settings.AutoDepth`. Figma: sections 15 and 16.

## Shop list
Max **4 rows** visible per tab (pager `< 1 / 2 >` in the footer, Figma and code).

## Dialogue
No NPC portrait, no speech-bubble tails. Close button on the dialogue box's top-right corner (clear of the mobile jump button).

## Aura Gacha — chosen: B "Reel Slot" (2026-11-16)
Section "Aura Gacha · 4 concepts" (B marked CHOSEN). Spec: `docs/figma/aura_gacha.py`.
- Flow: dim screen -> reel of aura orbs spins (tick pop per orb) -> eases out (2.0s + 0.35s x tier) with a **near-miss**: the rarest aura above the result passes the centre line right before the stop, frame tints to the rolled rarity ("so close...") -> **lock**: white flash, rotating rays, confetti (more for higher tiers); Legendary+ shakes and pauses -> **reveal card** (orb, name, rarity, chance, NEW!, stats, EQUIP / ROLL AGAIN / CLOSE). Tap anywhere to skip the spin.
- Legendary+ rolls are announced to the whole server 3.5s later.
- Code: `src/client/UI/AuraReel.luau`, `MenuController.RollAura/PlayReveal`; altar rolls fire `AuraRolled` so they play the same reveal. Orbs are tinted Frames (from `Config/Auras` Visual colours) until the orb PNGs are uploaded.
- **Figma FINAL:** section "Aura Gacha — Reel Slot (FINAL)" (page Out Space, x≈8900 y≈7400). Edit the components in "Gacha · Components (edit here)" — Reel Machine (no rod), Pity, Roll Bar (x1 / x10 -10%, Skip animation, Auto-roll until Epic+), Reveal Card, Rates — every screen G1–G6 uses instances. Spec: `docs/figma/gacha_page.py`.
- **NEW** is a corner badge on the orb (like the Item Slot), never inside the rarity/chance tag row.

## Windows & lists (2026-11-16)
- Every list window (Shop tabs, Auras, Fishdex) is a **fixed 760×610** in Figma and in code (UIScale shrinks it on small screens) — never content-sized. Rows are a fixed 80px.
- Overflow → **pager** `< 1 / N >` in the footer: Shop 4 rows/page, Auras 3 rows/page, Fishdex 6 cards/page (3×2, card 228×184: picture, full name, rarity + depth, caught + best).
- Info that used to be "a  •  b  •  c" text is now a **row of badges** (`New.BadgeRow` in code; neutral = sand, coloured = rarity / mutation / mode colours).

## Aura Card (component set)
"Aura Card" on the Components board: Size = Large / Row / Compact × Rarity = Common…Mythic. Used by the gacha Reveal Card, 08 Roll Result, 07 Auras (equipped + list) and G6 x10.
Overrides: Name, Chance, Stat 1–3 (hide unused), Status, New Badge. Orb image: name the instance `… {img:auras/<Id>}` then run `tools/art/figma_images.py`.
Spec + targeted patches: `docs/figma/aura_card.py`, applied with `docs/figma/apply_patch.py` (replaces single nodes in place — hand edits elsewhere are kept).

## Reel Minigame — FINAL: A2 Twin tubes (2026-11-17, replaces Pond Card)
Figma 03 · Reel Minigame frame 3526:22708 (spec `a2_card()` in `docs/figma/reel_tube_variants.py`). Builder `UI/Screens/Minigame.luau`, logic `FishingController.runMinigame` (same mechanic + numbers as Pond Card, so server validation is unchanged).
Narrow card 140×394, r20, track border • header: rarity pill + time left • water tube 25×300 (light→deep gradient, bubbles, track border) at x30 • catch bar 31 wide (3px overhang each side, white rim, r9) + `fish/MysteryFish` 39px in an unclipped "Lane" over the tube • reel tube 25×300 at x86 (track colour, gold fill from the bottom) with the `ui/status/bobber` image riding the fill • hint "HOLD TO REEL" y362 • tension = catch bar colour (mint on the fish / gold slipping / red near snap); no tension chips, no depth chip.

## (old) Reel Minigame — Pond Card (2026-11-16, replaced by Twin tubes)
Figma 03 · Reel Minigame (option D). Code: `FishingController.runMinigame` (vertical catch bar: hold = rise, release = sink).
Header: rarity tag + depth + time left • water column light→deep with bubbles • mint catch bar (white rim) • fish = **`fish/MysteryFish`** (species never revealed before the catch) • REEL meter (gold) with a bobber riding the fill • tension chips LOOSE / GOOD / SNAP! (GameConfig `Minigame.SnapWarning`).

## Figma -> Roblox text sizes (measured 2026-11-16)
Roblox draws glyphs smaller than Figma at the same size number. Explicit `TextSize` in `New.Text/Title/Button`, badges and baked
screens is a **Figma px** value; `New.FigmaSize(font, px)` converts it: Fredoka One x1.17, Nunito Bold x1.27, Nunito ExtraBold x1.36.
Button lip = layered `New.Button` (Lip/Face/Label; TextButton itself transparent and keeps the Text/BackgroundColor3 API, synced by `New.HookButton`; baked screens hooked in `Baked.Get`). `New.ButtonLip` (gradient) is legacy only.
HUD side menu (Figma 01): transparent 80×88 button holding Tile (64×64 cream, r20, track stroke, 50px Icon) + Label under the tile in outlined Fredoka 14 (white, T.Text outline). Menu hub icon = equipment/StarterPouch.
Unusable buttons (can't afford, level lock): face `T.Disabled` #D8D1C4, lip #BCB3A4, text #8A8478, currency icon faded — muted/dull, darker than list rows (white or bright reads as clickable).
Prices / numbers inside body text: `New.Highlight(text)` (RichText, Nunito heavy, gold-lip) — Figma: ExtraBold + cozy/gold-lip on that range.
Equipped Aura Card (pinned above the list on every page): mint tint `#D2F0E2` card + 2px mint stroke + mint EQUIPPED pill with white text.
Visual check: `node tools/ui/preview.mjs <view>` -> `tools/studio-mcp/scripts/capture.mjs <path> out.png --padding=18` -> `python -I tools/ui/compare.py figma.png out.png prefix`.

## Shadows = 9-slice (2026-11-16)
UICorner draws the rounded shapes (same radius as Figma). Drop shadows come from Figma section **"Roblox 9-slice (export)"**
(`docs/figma/nine_slice.py`): white shape + exact shadow, exported to `assets/ui-global/slice_shadow_{window,modal,glass}.png`.
`New.Shadow(panel, key)` puts it behind the panel (ScaleType Slice, tinted with the panel colour); until uploaded the panel looks as before.

## Screens & components (2026-11-17)
- Every screen is baked into StarterGui from `src/client/UI/Screens/<Name>.luau` (`node tools/ui/bake.mjs [Name]`): HUD, CastPopup, Minigame, AuraReel, Modal, Menus, MainMenu, Components. Controllers only `Baked.Get` + `Baked.Find` by name and bind data — no runtime-built ScreenGuis.
- Components (prefabs): `Screens/Components.luau` `Make.<Name>()` builders are used by every screen builder; one sample of each is baked in `StarterGui.Components.Sheet.<Name>.Sample`, and runtime pieces are `UI/Components.Clone("<Name>")` (Badge, CurrencyChip, MenuTile, NotifyPill, CatchCard, ZoneBand, Chip, Button). Screen-specific repeats live in a `Templates` folder in that screen (AuraReel: Cell, Confetti).
- Child names are the API. Rename only together with the controller. Hand-edits: set `Locked = true` on the ScreenGui so re-bakes skip it.

## Pager position (2026-11-20)
Every paged window puts the Pager ("< 1 / N >", `New.Pager`) in the footer at the **bottom-left**, same spot everywhere (Shop, Fishdex, Aura Index). Right side of the footer is for the wallet / main action.

## Pop transition (2026-11-20, tuned: no wobble)
Everything that appears pops: scale 0.7 -> 1, `TweenInfo.new(0.25, Back, Out)` (one small overshoot, no elastic wobble) (`New.Pop` in UI/New.luau).
- Automatic for every panel that uses `New.FitToScreen` / `New.FitWindow` / `Window.Shell`: plays when its ScreenGui is enabled or the panel turns Visible.
- Anything else calls `New.Pop(obj)` when it shows (Gacha canvas, Daily Login window, Item Card, catch card, toasts).
- Only while the game runs (no animation in Studio edit mode / bake).

## Rounded clipping (2026-11-20)
`ClipsDescendants` clips to the rectangle, not to UICorner: fills / sand footers / rays poke out of rounded corners. Use a CanvasGroup instead: `New.Panel({ Clip = true, ... })`, `Window.Shell({ Clip = true })`, or `New("CanvasGroup", ...)`.
