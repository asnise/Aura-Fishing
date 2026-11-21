# Handoff — Gacha page (B22), roll window, Inventory v2 / Item Card (B21) — 2026-11-20

Session: UI / Figma / map ("Knowlage How GDD" replacement). Talk to the user in Thai; code in English.
Read first: `CLAUDE.md`, `AGENTS.md` (Figma: existing art only, never generate art), `docs/TASKS.md` B21 + B22.

## State right now

| Piece | Code | Baked in Studio | Tested in Play | Saved (Ctrl+S) |
|---|---|---|---|---|
| Gacha page = Figma concept D "Glass Card" | done | yes | **no** | **unknown** |
| Roll window = "Altar Charge" (option 1) | done | yes | **no** | **unknown** |
| 8 gacha images uploaded + image ids | done (8/8) | n/a | — | — |
| Inventory last row filled with bubble slots | done | n/a (code only) | no | — |
| Empty slot = "Bubbles" (ItemSlot) | done | yes (Components, Inventory) | no | unknown |

`node tools/check.mjs` passes. Nothing is committed to git (project is not a repo).

## Open items (in order)
1. User: Ctrl+S in Studio, then Play test per TASKS B22 steps (Events -> Neon Tide -> ROLL x1 / x10 -> SEE ALL 10 -> summary; Skip / Auto; Rates; Shop; Featured tile -> Item Card).
2. `auras_Art/AbyssalShadow` (`rbxassetid://122339939840558`) did not render in Studio on 2026-11-20 (others did). Probably still in Roblox review. If still blank in Play: clear its `rbxassetid` in `assets/catalog.json`, then
   `python -I tools/art/upload_assets.py --user <id> --only auras_Art/AbyssalShadow` (user runs it: it asks for the API key) and `node tools/ui/resolve_decals.mjs`.
3. "UI ทะลุ" (overlap) the user reported was only fixed by hiding the page during the roll; not reproduced. Possible other cause: MenuManager gives Main-layer menus DisplayOrder 10-14, below MainMenu / CastPopup / DailyLogin (20). Re-check in Play.
4. Pay-with toggle "Tokens" only notifies "coming soon": no Star Token roll price exists in `Config/AuraBanners` (design decision for the user).
5. Aura Altar has no `Featured`, so hero / rail card use the rarest aura that has an illustration (code: `heroAura` in `UI/GachaPage.luau`). User may want a specific one -> add `Featured` to the banner.
6. B21 Inventory v2 / Item Card: implemented by another session (see TASKS B21, `UI/ItemDetail.luau`, `UI/VirtualGrid.luau`); remaining checks are listed there.

## Gacha page (B22)
- Figma: section "Gacha Redesign v2 — A / D" `3662:56161`, concept D frame `3662:56279` (user-edited; History removed; E1 parts added: Mythic pity, Milestones, Skip, Auto `3662:56492/56498/56509`; pay toggle `3662:56457`).
- `src/client/UI/Screens/GachaPage.luau` — full screen (IgnoreGuiInset), background `ui/gacha_bg_celestial`, **1280x720 Canvas** in Figma coordinates, scaled to the viewport by `UI/GachaPage.Bind`. Templates: RateRow, MilestoneCell, ResultCell, BannerCard, FeatTile. Popups: RatesPopup, MilestonesPopup, Summary (x10).
- `src/client/UI/GachaPage.luau` — fill + pull logic (unchanged remotes: PullAura, ClaimMilestone, EquipAura). Rail = open banners from `Config/AuraBanners` (events first). Hero + name plate = banner's highlight aura only (`heroAura`), never the last pull. Featured tiles -> `ItemDetail.Show({Kind="Aura", Id, Info=true})`. During a reveal the page is hidden (`w.Visible=false`) and restored on close / roll again / Stop.
- `src/client/Controllers/GachaPageController.luau` — paths check for the new bake, `ctx.openStore` (lazy require EconomyController, Store tab "Gems").
- Figma helper scripts: `docs/figma/gacha_redesign.py` (concepts + `--bg <id>` fills backgrounds with FILL), `docs/figma/send_blocks.py` (big build_tree in pieces; one huge call fails in the plugin).

## Roll window "Altar Charge" (AuraReel)
- Figma: "Gacha Roll Animation — 4 options" `3664:56516`; chosen option 1 `3664:56519` (user-edited: rays removed `3664:56560/56589`, compact result bar, Item Card beside the art).
- `src/client/UI/Screens/AuraReel.luau` — **1920x1080 Canvas** = storyboard (560x315) x 1920/560; DisplayOrder 28 (Item Card is 30).
- `src/client/UI/AuraReel.luau` — orb drops on altar -> rings + sparkles charge, colour white -> lilac -> rarity -> Legendary+ shake/pause -> glow + flash + "!" + confetti -> reveal (rarity glow, `auras_Art/<id>` or orb, result bar, `ItemDetail` beside the art). Tap = skip. API unchanged: `Play(auraId, {isNew, equipped, onEquip, onRollAgain, onClose, rollAgainText?})`. x10 passes `rollAgainText = "SEE ALL 10"` -> summary. Also used by the Auras window (`MenuController.PlayReveal`).

## Art rules learned
- `assets/art/auras/*` = round orb icons (every aura) -> small UI. `assets/art/auras_Art/*` = big illustrations (6 auras) -> hero / reveal only. Never copy one over the other (it happened once and broke other screens).
- Upload: `tools/art/upload_assets.py --only <keys>` (user runs, API key prompt) -> `node tools/ui/resolve_decals.mjs` (Studio bridge) -> UIAssets regenerated. `sync_ui_assets.py <ids.csv>` now skips blank rows.

## Tools / environment notes
- Studio bridge: if `tools/ui/bake.mjs` says "StudioBridge not reachable", start `node tools/studio-mcp/dist/server.js --http-only` (background) and have the user press Connect in the Studio Bridge plugin. Bridge works in Edit mode only (cannot start Play).
- Roblox Studio MCP (`mcp__Roblox_Studio__*`) showed no studios this session -> Play tests need the user, or the MCP enabled in Studio.
- Capture: `node tools/studio-mcp/scripts/capture.mjs <guiPath> <out.png> --method=print` (screen method grabs whatever window is in front).
- `tools/ui/preview.mjs` is broken (its Luau is over Roblox's 200k-char Source limit) — pre-existing.
- Figma relay `scripts/figma-relay.bat`, channel `aura-fishing`; if exports time out, the user restarts the plugin.
