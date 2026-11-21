# Aura Fishing — Brief สำหรับ Agent สายวิเคราะห์ (snapshot 2026-11-17)

วิธีใช้: คัดลอกตั้งแต่ "PROMPT" ถึงท้ายไฟล์ ส่งให้ agent วิเคราะห์ได้เลย (ข้อมูลเกมอยู่ในไฟล์นี้ครบ ไม่ต้องเปิดโค้ด)
ถ้าต้องการให้ agent ดูโค้ดจริงด้วย: ให้สิทธิ์อ่านโฟลเดอร์ `src/shared/Config/` และ `src/server/Services/`

---

## PROMPT

You are a senior free-to-play game economy & retention designer with deep Roblox experience
(simulator / RNG / fishing genre: Fisch, Sol's RNG, Pet Simulator 99, Grow a Garden).

Analyse the game below and propose how to make its **core loop sticky** — players should feel
constant, satisfying progression, keep coming back, and gradually want things that make play
**more comfortable/convenient** (which is what we will sell) — **without** breaking the economy,
draining content too fast, or using harmful dark patterns (audience is ages 9–24; follow Roblox
policies: paid random items must disclose odds, no pay-to-win that free players can never reach).

The owner's direction (must respect):
1. Core = play to collect currency (coins / gems) to **roll the aura gacha often**.
2. **Generous economy** — "give a lot, money comes easily". The dopamine should come from
   **spending, buying and selling often**. But not so much that the system breaks.
3. Cozy, relaxed play; progression visible at all times; content must not be exhausted quickly.
4. An **idle system** where some value keeps rising (even offline) and is spent on real
   **character progression**.
5. Friction should be solvable step by step through play; paid items are shortcuts/comfort,
   never the only way.

### What we need from you (answer in Thai, numbers and tables welcome)
1. **Diagnosis** — what in the current loop/economy will hurt retention or game feel (D1, D7, D30), ranked.
2. **Core loop design** — the moment-to-moment, session and daily/weekly loops; where each dopamine hit lands.
3. **Systems to add or change**, each with: purpose in the loop, how it connects to existing systems,
   key numbers (start values), risks (inflation, content drain, exploit), and how to measure it.
   Prefer systems that reuse what exists (stat sources, banners, events, inventory) over brand-new ones.
4. **Friction → solution ladder** — list the convenience frictions (bag full, walking to sell, auto stopping,
   offline cap, bait rebuy, single line...) and for each: free progression fix, paid shortcut, when it should
   start to hurt (minute/hour/day of play).
5. **Economy pacing** — target time-to-next-purchase, gem income per hour, gacha pulls per hour, and the
   sinks that keep it stable at hour 1 / 10 / 100. Check our draft numbers below and correct them.
6. **Monetization map** — gamepasses, dev products, packages, starter pack; price tiers in Robux; which
   friction each one relieves; what must stay free.
7. **Priority roadmap** — what to build first for the biggest retention gain per effort (we are a small team:
   1 dev + AI agents; UI/art is the slow part).
8. **Metrics** — the events/analytics to log so we can tune after launch.

Do not propose player-to-player trading yet (scam/dupe risk). Flag anything you are unsure of as an assumption.

---

## GAME DATA (current build)

### Identity
- Roblox, Luau, server-authoritative. Genre: fantasy fishing simulator + aura gacha (RNG).
- Map: "Stilt Boardwalk" — wooden boardwalk hub in an open sea; reserved slots for Quest board,
  Leaderboard, Rebirth shrine, Boat, Boss arena.
- Desktop first; mobile layout exists but not polished.

### Core loop (implemented)
1. Stand at water, pick **target depth** (slider, capped by fishing line) → CAST.
2. Wait 2.5–6 s (reduced by BiteSpeed) → "!" → click within 2.2 s (HOOK).
3. **Reel minigame** (hold to lift a catch bar over a moving fish; progress fills while overlapping; empties
   when not; 0 = line snaps). Fish identity hidden (`???`) until caught.
4. Catch card: rarity, weight, mutation, Manual/Auto, PERFECT (never left bar), NEW!.
5. Fish go into a **slot bag** (stacks of 10 per species+mutation; 3% chance of a treasure chest per catch).
6. Sell at the Merchant (Sell All or per stack) → coins → buy rods/lines/bags/baits.
7. Gems → **aura gacha** → equip aura (stat buffs + particle VFX, server announcement for Legendary+).
- **Manual** sell value ×1.5 (+0.25 if PERFECT), XP ×1.5. **Auto**: one fish every 9 s × (1 − AutoSpeed) × (1 − BiteSpeed×0.5), value ×1.0, no minigame, stops when bag full.

### Formulas
- Fish roll weight = rarity weight × (1 + Luck)^((tier − 1) × 0.75)
- Sell value = BaseValue × clamp((kg/avgKg)^0.7, 0.4, 3) × mutation mult × mode mult × SellMultiplier
- XP to next level = floor(60 × Level^1.45); +5 gems per level. Cumulative XP: Lv10 6k, Lv25 62k, Lv50 347k, Lv100 1.92M
- Gems per catch by rarity: Rare 1, Epic 3, Legendary 10, Mythic 30 (manual and auto alike)
- Treasure chest: 3% per catch × (1 + Luck×0.5) → 60% 150–600 coins / 25% 3–10 gems / 15% 3 shrimp bait
- Start: 0 coins, 15 gems

### Rarities (base roll weight / XP)
Common 1000/5 · Uncommon 400/10 · Rare 120/25 · Epic 30/60 · Legendary 6/150 · Mythic 1/400

### Fish (20) — name, rarity, depth m, base coins, difficulty 1–10
| Zone | Fish |
|---|---|
| Shallow | Pebble Minnow C 0–40 4 d1 · Bubble Carp C 0–50 6 d1 · Reed Perch C 5–60 8 d2 · Sunscale Sardine C 0–30 5 d2 · Pearl Clam U 10–50 22 d1 · Lily Trout U 0–45 18 d3 · Dewdrop Koi R 0–35 70 d4 · Crystal Guppy E 0–50 240 d6 |
| Mid | Stripe Bass C 40–140 14 · Tide Snapper C 50–160 16 · Armored Crab U 60–120 34 · Silver Ray U 70–200 40 · Razor Pike R 60–180 110 · Moon Jelly R 80–200 95 · Ember Tuna E 100–200 420 · Coral Seahorse L 50–150 1500 d8 |
| Deep | Lantern Angler U 200–400 90 · Glow Eel R 220–500 260 · Ancient Coelacanth L 250–600 3200 · Naga Hatchling **Mythic** 200–300 12000 d9 |
Location "Starter Bay" max depth 300 m (only location).

### Equipment (coins; stats are additive)
- Rods: Driftwood 0 · Bamboo 400 · Coral 2,500 · Moonsilver 15,000 (Lv10, Luck .35, AutoSpeed .1) · Naga Scale 90,000 (Lv25, Luck .75, AutoSpeed .2, Mutation +2%)
- Lines (max depth): Cotton 30 m free · Hemp 80 m 300 · Nylon 150 m 1,800 · Spider-Silk 300 m 9,000 (no level gate)
- Bags (slots): 6 / 10 (250) / 15 (1,500) / 20 (8,000) / 30 (40,000)
- Baits (per 10, consumed 1 per catch): Worm 20 (Luck .1) · Shrimp 150 (Luck .3, BiteSpeed .1) · Glow Grub 900 (Luck .75, AutoSpeed .1)
- Stats available: Luck, CatchBarSize, ReelPower, Resilience, FishStability, MaxDepth, BiteSpeed, AutoMultiplier, AutoSpeed (max 75%), MutationChance, SellMultiplier, XPMultiplier, ExtraLines (reserved for multi-cast)

### Mutations (chance per catch / value ×)
Glowing 2% ×1.8 · Sun-Forged 0% (aura only) ×2.5 · Golden 0.5% ×3 · Void-Touched 0% (aura only) ×5

### Auras (5) — shown odds, buffs
Sparkling Dew 1/10 Luck +5% · Neon Wave 1/100 Luck +15%, bar +2.2%, Glowing +3% · Solar Flare 1/750 Luck +35%, Sun-Forged +10% ·
Abyssal Shadow 1/5,000 Luck +50%, Auto ×+0.2, Void +3% · Dragon Emperor 1/50,000 Luck +100%, stability +30%, Golden +25%.
Duplicates currently give nothing.

### Gacha banners
- Altar (permanent): 5 gems/pull; x10 = 45 gems and guarantees Epic+; **pity: Mythic guaranteed every 100 pulls**.
- Neon Tide (event, 2 weeks): same + rate-up ×2 on Neon Wave & Abyssal Shadow; milestones by pulls
  10→20 gems, 30→50 gems, 50→10 shrimp, 100→2 chests, 200→150 gems, 400→Abyssal Shadow.

### Other systems built
Save data (DataStore), levels/XP, Fishdex (20 species, sort, counts), events hub (cards → actions),
dev/admin commands, sea boundary, aura VFX with Low-FX option.

### Planned / backlog (not built)
Rebirth + titles (planned Lv100, +0.25× permanent multiplier, keeps rods/auras/Fishdex) · Skills from skill points
(Keen Eye luck, Quick Hands bite speed, Multi-Cast lines) · Naga boss every 30 min, co-op reel, rewards by contribution ·
Gamepasses (VIP luck +15%, Auto-Fish Pro, Infinite Bag, Extra Cast) · Daily quests (3/day, +5 gems) · Daily login.

### Our analysis so far (please verify)
Assumes manual ≈ 12 s per fish (~5 fish/min).
| Line | best depth | coins/fish | gems/fish |
|---|---|---|---|
| Cotton 30 m | 10 m | 10 | 0.04 |
| Hemp 80 m | 80 m | 29 | 0.10 |
| Nylon 150 m | 141 m | 43 | 0.23 |
| Silk 300 m | 250 m | 174 | 0.40 (Mythic 1 in 527 catches) |
Problems found:
1. Auto gives more fish/min than manual (6.7 vs ~5); manual earns only ~12% more coins and less gems/chests per minute.
2. 250–300 m has no Common fish → 4× income jump, Mythic 1/527, reachable ~45 min in with the starter rod.
3. Coins far outpace XP: everything affordable within ~1 h, then level gates wall (Lv25 ≈ 9 h); no coin sink afterwards; Lv100 rebirth ≈ 270 h.
4. Gacha: Mythic pity at 500 gems while shown as 1/50,000; x10 gives a "1/750" aura every 45 gems; dupes useless; only 5 auras → gems lose purpose after ~4 h of deep fishing.
5. Late-game luck stacking (≈ +250%) → 5% Mythic per catch, ~2,500 coins and 3 gems per catch.
6. Starter bag 6 slots vs 8 shallow species (fills often, auto stops); deep zone has 4 species (bag rarely fills).
   Hardest fish (difficulty 9, erratic) may be near-impossible with starter rod (needs playtest). Reel success is reported by the client (exploit risk).

### Our draft direction (please critique and improve)
- ×10 all values/prices (big numbers), start with 500 coins, purchase every 1–3 min early / 3–10 min to hour 2 / bigger items 30–120 min.
  Draft ladder: Basket 800, Hemp 1k, Bamboo 1.5k, Crate 6k, Coral 12k, Nylon 15k, Coolbox 40k, Moonsilver 120k (Lv10), Silk 150k (Lv12), Hold 250k, Naga Rod 900k (Lv25).
- Bottomless sinks: Gear Enhance (+1…+10, cost 10% of item × 1.5^lv), aquarium slot expansion, consumable bait.
- "Hot fish of the hour" at the Merchant (×2–×3 sell price for 1–2 species, server-wide).
- **Idle: Aquarium** — put caught fish in instead of selling; they generate **Pearls** per minute by rarity
  (C .2, U .5, R 1.5, E 4, L 12, M 40 × mutation mult), offline cap 4 h; slots bought with coins.
  Pearls → **Mastery** (infinite levels, cost ×1.15/level: Luck, Catch Bar, Reel, Auto Wait, Pearl Rate, offline cap, Sell Mult).
- Gacha: ~15 pulls/h early, ~8–10/h later; dupes → stars ★1–★5 (+20% stats each); pity Legendary@100, Mythic@300; x10 guarantees Rare+; show true odds; new aura banner every ~2 weeks.
- Fixes: Auto 14 s and half gems/chests; manual Hot Streak +5% per consecutive catch (max +50%); Silk line Lv12; Naga roll weight 0.2; add a deep Common fish; XP exponent 1.3; rebirth at Lv50; luck tier exponent 0.6.
- Friction ladder: bag full → bigger bags / Infinite Bag; walk to sell → Mastery remote sell / pass; auto stops when full → auto-sell commons; offline cap → Mastery / VIP; bait rebuy → auto-rebuy; one line → Multi-Cast skill / Extra Cast pass.

### Constraints
- Content is data-driven (config files); new stats/items are cheap, new UI screens and art are the slow part.
- Server-authoritative; avoid systems that need heavy anti-cheat unless worth it.
- Keep it cozy: no punishing mechanics (losing items, decay that wipes progress).
