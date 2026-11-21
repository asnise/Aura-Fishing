# Aura Fishing — Architecture & Project Knowledge

## 1. System Overview & Technology Stack
- **Engine / Target:** Roblox (Luau)
- **Sync Tool:** Rojo 7.7.1 (`D:\tools\rojo\rojo.exe`, `default.project.json`)
- **Type Checking:** `luau-lsp analyze --definitions=D:/tools/luau-defs/globalTypes.d.luau --sourcemap=sourcemap.json src`
- **Design & Layout Rules:** Cozy Lake theme, built via `UI/New` (`New.Theme`).

## 2. Directory Layout
- `src/shared`: `ReplicatedStorage.Shared`
  - `Config/*`: Content definitions (Fish, Equipment, Auras, Mutations, Locations, StatDefs, UIAssets).
  - `Registry`: Validates configurations at startup.
  - `Stats`: Unified additive stat computation (`Stats.Compute`).
  - `Roll`: Probability and RNG algorithms.
  - `Remotes`: Single declarative registry for all client-server network remotes.
- `src/server`: `ServerScriptService.Server`
  - `Main.server.luau`: Bootstrapping entry point.
  - `Services/*`: Module singletons with `Init()` (`DataService`, `FishingService`, `ShopService`, etc.).
  - `World/*`: Dynamic world and zone generation.
- `src/client`: `StarterPlayerScripts.Client`
  - `Main.client.luau`: Client bootstrapping.
  - `Controllers/*`: Client gameplay and UI controllers.
  - `UI/New`: Programmatic UI component builders conforming to Cozy Lake styling.
  - `UI/Generated`: Figma-converted UI wrappers (never edit manually).

## 3. Core Architectural Invariants
1. **Data-Driven Content:** All items, stats, fish, and auras live strictly in `Config/*`. Never hardcode game items or mechanics inside services.
2. **Single Stat Pipeline:** All buffs/stats are additive `{ StatName = n }`. Only `Stats.Compute(profile, extraSources)` evaluates total stats across client and server.
3. **Server Authoritative:** Server determines all loot rolls, weight ranges, mutations, and auras. Server verifies action timings to prevent exploit reels.
4. **DataStore Lifecycle:** Profiles use `DataService.TEMPLATE`. Modifications mark dirty via `DataService.MarkDirty(player)`. New fields are auto-reconciled.
5. **No Emojis / Prohibited Symbols Rule:** Never use "✓", "•", or Unicode emojis in UI text, code identifiers, or Figma assets.
6. **Currency & Formatting:** Pearls format as integers without decimals (`Format.Number`). Idle income rates format strictly per second (`+X/s`).
