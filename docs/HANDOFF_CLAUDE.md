# Handoff → Claude (2026-11-18)

Continuing **Aura Fishing** after the Antigravity session.
Read this file, `CLAUDE.md`, and `docs/TASKS.md` (all tasks and Thai test steps).
**Talk to the user in Thai.** Code, identifiers, comments in English.

---

## 1. What was completed in this session

1. **Aquarium Fish Cards — Option 2: Clean Card (Tap for Details)**:
   - Removed the separate remove `x` button (`Btn Remove`) from tank cards in `AquariumScreen.luau`.
   - Card displays full-width `FishName` and `Rate` pill (`+X/s`) cleanly without truncation.
   - Tapping the card opens a detail confirmation modal (`Modal.Confirm`) showing fish name, icon, rate, and mutation badge with a "Return to Bag" button.

2. **Mastery Button Removed from Aquarium & Added to Main Menu Hub**:
   - Removed `Btn Mastery` entirely from Aquarium Header in `AquariumScreen.luau`. `Spacer` now uses `UIFlexItem` (`FlexMode = Fill`), pushing `Slots` cleanly to the right edge.
   - Added `Mastery` tile (`T.TintMint`, icon `ui/icons/mastery`) to `MainMenu` (`src/client/UI/Screens/MainMenu.luau`).
   - `MainMenuController.luau`: binds `Mastery` tile to `ACTIONS.Mastery` (`HUD.MasteryRequested:Fire()`), which opens the Mastery window via `EconomyController.OpenMastery()`.
   - Included runtime auto-fallback: if the place in Studio has an older baked `MainMenu` without `Mastery`, it automatically converts the unbuilt `Quests` tile into `Mastery`.

3. **Currency Container Padding & Margin (Coins, Gems, Pearls, Bag Capacity, Rate)**:
   - Implemented `New.FormatCurrencyChip(c, padRight)` in `src/client/UI/New.luau`:
     - Forces `AutomaticSize = Enum.AutomaticSize.X`.
     - Adds `UIPadding` with Left = 12px, Right = 20px, Top = 6px, Bottom = 6px.
     - Adds `UIListLayout` (Center, 8px gap) and sets `Value.AutomaticSize = X`.
   - Applied dynamically to:
     - HUD Currencies (Coins, Gems, Pearls, Bag Capacity).
     - Catch Result Cards (Rewards Coins & Gems).
     - Menu Wallets (Shop, Auras, Fishdex via `MenuFill.luau`).
     - Inventory, Event, and Gacha currency chips.
     - Aquarium Header (Pearls chip, Offline Cap pill, Rate pill).

4. **Gacha x10 Flow Enhancement**:
   - Rolling x10 now shows the single "Your roll" (AuraReel reveal of the best pull) first.
   - The x10 Result Summary (`Summary.Panel`) only appears when the player closes or equips from the AuraReel, creating suspense.
   - Fixed potential double-callback trigger on `Equip`.

5. **Baked Screens Updated in Studio**:
   - Baked latest versions into `StarterGui` via `node tools/ui/bake.mjs`:
     - `MainMenu` (250 instances)
     - `Menus` (803 instances)
     - `HUD` (144 instances)
     - `Inventory` (602 instances)
     - `Events` (302 instances)

6. **Figma Artifacts**:
   - Generated Section "Aquarium · Card Remove Variants (6 Options)" (Node `3571:41388`) on page "Out Space" via `docs/figma/card_remove_variants.py`.

7. **Verification**:
   - `sourcemap.json` regenerated with Rojo 7.7.1.
   - `luau-lsp analyze` clean with 0 errors.
   - Strict character rule verified (no "✓", "•", or emojis).

---

## 2. Active Priorities & Next Steps for Claude

1. **Mastery Window Polish** (`docs/HANDOFF_ANTIGRAVITY.md` item 2):
   - Current Mastery window uses standard `Window.Create`.
   - Match Figma `3539:31264` (7 upgrade cards, Lv, current bonus → next bonus, price in Pearls, UPGRADE / MAX buttons).
   - Ensure header displays real-time ticking Pearls and rate (`+X/s`).

2. **Store Window Polish** (`docs/HANDOFF_ANTIGRAVITY.md` item 3):
   - Match Figma `3546:36700` (Passes, Gems, Boosts & Packs).
   - Link with developer products and game passes (`Config/Products.luau`).

3. **Put in Tank Window**:
   - Ensure multi-select flow and Quantity modal align with Figma and user preferences.

---

## 3. Collaboration Feedback & Requests for Claude

Tools that would make future agent passes much faster:
1. **Single-command QA runner (`tools/check.bat` or `tools/verify.mjs`)**:
   - Runs `rojo sourcemap` + `luau-lsp analyze` + check for banned chars (`✓`, `•`, emojis) in one go.
2. **UI Padding / Layout Linter**:
   - Script checking that all currency chips and text containers in `src/client/UI/Screens/` have `AutomaticSize = X` and right padding $\ge 16$px.
3. **Figma Section / Variant Scaffolder**:
   - CLI helper to create side-by-side comparison variants on Figma "Out Space" without writing 200 lines of manual Python script each time.
