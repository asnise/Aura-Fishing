# Aura Fishing — Art prompts (3×3 grid, 1:1)

> Generated from `tools/art/sheets.json` by `tools/art/make_prompts.py`. Don't edit by hand — edit the JSON and re-run.

## How to use
1. Copy one **Prompt** block into your image generator. Set the aspect ratio to **1:1** (1024×1024 or larger).
2. If your generator has a negative prompt box, paste the **Negative** line into it.
3. Save the image, then slice it:
   ```
   python -I tools/art/slice_grid.py <sheet id> <image.png>
   ```
   You get transparent 512×512 PNGs in `assets/art/<folder>/<name>.png` plus `assets/art/<sheet id>_contact.png` to check what landed where.
4. If a cell came out wrong, regenerate the whole sheet or swap in the cell from another attempt (the slot order never changes).
5. Cell order is always **left → right, top → bottom** (1 = top-left, 9 = bottom-right).

## Sheets
| # | Sheet id | Purpose | Saved to |
|---|---|---|---|
| 1 | `01_menu_icons` | UI menu icons (Main Menu tiles / HUD buttons) | `assets/art/ui/icons/` |
| 2 | `02_currency_status` | Currency & status icons | `assets/art/ui/status/` |
| 3 | `03_fish_shallow` | Fish icons - Shallow water (0-50m) | `assets/art/fish/` |
| 4 | `04_fish_mid` | Fish icons - Mid water (50-200m) | `assets/art/fish/` |
| 5 | `05_fish_deep_mutations` | Deep fish + mutation badges | `assets/art/fish/` |
| 6 | `06_rods_lines` | Rods (5) + fishing line spools (4) | `assets/art/equipment/` |
| 7 | `07_bags_baits` | Bags (5) + baits (4) | `assets/art/equipment/` |
| 8 | `08_aura_orbs` | Aura orbs (Auras menu + roll reveal) | `assets/art/auras/` |
| 9 | `09_npc_portraits` | NPC portraits for the Dialogue box (bust, 3 NPCs x 3 expressions) | `assets/art/npc/` |
| 10 | `10_economy_status` | [P1] Economy currency & status icons (Pearls, Star Token, Streak, Boost...) | `assets/art/ui/status/` |
| 11 | `11_menu_icons_2` | [P1] New menu / hub tile icons (Aquarium, Mastery, Store, passes) | `assets/art/ui/icons/` |
| 12 | `12_shop_packs` | [P1] Robux store pack art (gems, coins, boosts, starter) | `assets/art/ui/shop/` |
| 13 | `13_fish_deep_2` | [P2] Deep & abyssal fish (cell 1 GloomSprat needed for C12; rest = future zones) | `assets/art/fish/` |
| 14 | `14_materials` | [P2] Enhance materials (Gear Enhance phase 2) | `assets/art/materials/` |
| 15 | `15_aura_orbs_2` | [P2] New aura orbs for future banners (gacha content) | `assets/art/auras/` |
| 16 | `16_equipment_2` | [P3] Equipment for later tiers + Starter Pack rod | `assets/art/equipment/` |
| 17 | `17_inventory_tabs` | Inventory side-tab icons (+ Bag Upgrade) | `assets/art/ui/tabs/` |
| 18 | `18_mastery_icons` | Mastery track icons (full-colour set) | `assets/art/ui/mastery/` |
| 19 | `19_shop_packs_2` | [P2] Robux bundle pack art (starter-style offers, 9 new packs) | `assets/art/ui/shop/` |

---

## 1. `01_menu_icons` — UI menu icons (Main Menu tiles / HUD buttons)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `shop.png` | a small market stall with a coral and cream striped awning |
| 2 | top-center | `auras.png` | a glowing lavender magic orb with a sparkle star inside |
| 3 | top-right | `fishdex.png` | a thick sky-blue book with a small fish emblem on the cover |
| 4 | middle-left | `bag.png` | a plump gold fishing satchel with a buckle strap |
| 5 | center | `quests.png` | a mint green scroll with a small gold ribbon tied around it |
| 6 | middle-right | `rebirth.png` | a pink circular arrow loop around a tiny glowing star |
| 7 | bottom-left | `events.png` | a coral gift box with a cream ribbon bow |
| 8 | bottom-center | `friends.png` | two cute round fish-shaped badges side by side, sky blue and mint |
| 9 | bottom-right | `settings.png` | a soft slate-grey rounded gear cog |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Simple bold glyph-like objects that read clearly at 48px. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a small market stall with a coral and cream striped awning. Cell 2 (top-center): a glowing lavender magic orb with a sparkle star inside. Cell 3 (top-right): a thick sky-blue book with a small fish emblem on the cover. Cell 4 (middle-left): a plump gold fishing satchel with a buckle strap. Cell 5 (center): a mint green scroll with a small gold ribbon tied around it. Cell 6 (middle-right): a pink circular arrow loop around a tiny glowing star. Cell 7 (bottom-left): a coral gift box with a cream ribbon bow. Cell 8 (bottom-center): two cute round fish-shaped badges side by side, sky blue and mint. Cell 9 (bottom-right): a soft slate-grey rounded gear cog.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 2. `02_currency_status` — Currency & status icons

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `coin.png` | a shiny round gold coin with a small fish symbol embossed in the middle |
| 2 | top-center | `gem.png` | a faceted lavender crystal gem |
| 3 | top-right | `xp_star.png` | a chubby mint green star with a soft glow |
| 4 | middle-left | `bobber.png` | a classic round fishing bobber, coral red top and cream bottom, floating |
| 5 | center | `bite_alert.png` | a round cream speech bubble containing a bold coral exclamation mark shape (a symbol, not a letter) |
| 6 | middle-right | `lock.png` | a cute rounded gold padlock |
| 7 | bottom-left | `treasure_chest.png` | a small wooden treasure chest with gold trim, slightly open, glowing |
| 8 | bottom-center | `auto_timer.png` | a mint green hourglass with sand flowing |
| 9 | bottom-right | `sell_bag.png` | a small cream coin pouch tied with a string, with two gold coins peeking out |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Small iconic objects used inside chips and toasts. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a shiny round gold coin with a small fish symbol embossed in the middle. Cell 2 (top-center): a faceted lavender crystal gem. Cell 3 (top-right): a chubby mint green star with a soft glow. Cell 4 (middle-left): a classic round fishing bobber, coral red top and cream bottom, floating. Cell 5 (center): a round cream speech bubble containing a bold coral exclamation mark shape (a symbol, not a letter). Cell 6 (middle-right): a cute rounded gold padlock. Cell 7 (bottom-left): a small wooden treasure chest with gold trim, slightly open, glowing. Cell 8 (bottom-center): a mint green hourglass with sand flowing. Cell 9 (bottom-right): a small cream coin pouch tied with a string, with two gold coins peeking out.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 3. `03_fish_shallow` — Fish icons - Shallow water (0-50m)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `PebbleMinnow.png` | a tiny grey-blue minnow with pebble-like speckles |
| 2 | top-center | `BubbleCarp.png` | a round chubby orange-cream carp with little bubbles near its mouth |
| 3 | top-right | `ReedPerch.png` | a green and gold striped perch with a spiky dorsal fin |
| 4 | middle-left | `SunscaleSardine.png` | a slim silver sardine with warm yellow sun-shine scales |
| 5 | center | `PearlClam.png` | a pastel pink clam shell slightly open showing a glossy pearl |
| 6 | middle-right | `LilyTrout.png` | a pink-spotted trout with a tiny lily pad stuck on its back |
| 7 | bottom-left | `DewdropKoi.png` | a white and sky-blue koi with water droplet patterns |
| 8 | bottom-center | `CrystalGuppy.png` | a small translucent lavender guppy with a crystal-like fan tail |
| 9 | bottom-right | `MysteryFish.png` | a plain soft slate-grey fish silhouette with a lighter question-mark-free belly, used for undiscovered fish |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Every fish in full side view facing LEFT, whole body visible, same size relationship (bigger fish fill the cell more). The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a tiny grey-blue minnow with pebble-like speckles. Cell 2 (top-center): a round chubby orange-cream carp with little bubbles near its mouth. Cell 3 (top-right): a green and gold striped perch with a spiky dorsal fin. Cell 4 (middle-left): a slim silver sardine with warm yellow sun-shine scales. Cell 5 (center): a pastel pink clam shell slightly open showing a glossy pearl. Cell 6 (middle-right): a pink-spotted trout with a tiny lily pad stuck on its back. Cell 7 (bottom-left): a white and sky-blue koi with water droplet patterns. Cell 8 (bottom-center): a small translucent lavender guppy with a crystal-like fan tail. Cell 9 (bottom-right): a plain soft slate-grey fish silhouette with a lighter question-mark-free belly, used for undiscovered fish.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 4. `04_fish_mid` — Fish icons - Mid water (50-200m)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `StripeBass.png` | a sturdy olive bass with dark horizontal stripes |
| 2 | top-center | `TideSnapper.png` | a coral red snapper with wave-shaped fin edges |
| 3 | top-right | `ArmoredCrab.png` | a chunky steel-blue crab with rounded armored shell plates, front view |
| 4 | middle-left | `SilverRay.png` | a silver manta ray seen from above, wings spread |
| 5 | center | `RazorPike.png` | a long sleek pike with a pointed snout and teal back |
| 6 | middle-right | `MoonJelly.png` | a glowing pale lavender jellyfish with a moon-shaped bell |
| 7 | bottom-left | `EmberTuna.png` | a big tuna with orange ember-like glowing scales |
| 8 | bottom-center | `CoralSeahorse.png` | a pink and gold seahorse decorated with tiny coral branches, side view |
| 9 | bottom-right | `LanternAngler.png` | a cute dark-teal anglerfish with a warm glowing lantern lure |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Every fish in full side view facing LEFT, whole body visible. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a sturdy olive bass with dark horizontal stripes. Cell 2 (top-center): a coral red snapper with wave-shaped fin edges. Cell 3 (top-right): a chunky steel-blue crab with rounded armored shell plates, front view. Cell 4 (middle-left): a silver manta ray seen from above, wings spread. Cell 5 (center): a long sleek pike with a pointed snout and teal back. Cell 6 (middle-right): a glowing pale lavender jellyfish with a moon-shaped bell. Cell 7 (bottom-left): a big tuna with orange ember-like glowing scales. Cell 8 (bottom-center): a pink and gold seahorse decorated with tiny coral branches, side view. Cell 9 (bottom-right): a cute dark-teal anglerfish with a warm glowing lantern lure.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 5. `05_fish_deep_mutations` — Deep fish + mutation badges

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `GlowEel.png` | a long curvy eel with glowing cyan spots |
| 2 | top-center | `AncientCoelacanth.png` | a big ancient lobe-finned fish, deep blue with pale spots |
| 3 | top-right | `NagaHatchling.png` | a baby emerald-green sea serpent (naga) with a tiny gold crest, curled S-shape |
| 4 | middle-left | `mut_glowing.png` | a round mint badge with a glowing teal water drop symbol |
| 5 | center | `mut_sunforged.png` | a round orange badge with a stylised sun symbol |
| 6 | middle-right | `mut_golden.png` | a round gold badge with a shining gold fish scale symbol |
| 7 | bottom-left | `mut_voidtouched.png` | a round deep purple badge with a swirling dark mist symbol |
| 8 | bottom-center | `deco_seaweed.png` | a cute bundle of mint green seaweed |
| 9 | bottom-right | `deco_bubbles.png` | a cluster of shiny pastel blue bubbles |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Cells 1-3 are fish in side view facing LEFT. Cells 4-7 are round emblem badges. Cells 8-9 are decorations. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a long curvy eel with glowing cyan spots. Cell 2 (top-center): a big ancient lobe-finned fish, deep blue with pale spots. Cell 3 (top-right): a baby emerald-green sea serpent (naga) with a tiny gold crest, curled S-shape. Cell 4 (middle-left): a round mint badge with a glowing teal water drop symbol. Cell 5 (center): a round orange badge with a stylised sun symbol. Cell 6 (middle-right): a round gold badge with a shining gold fish scale symbol. Cell 7 (bottom-left): a round deep purple badge with a swirling dark mist symbol. Cell 8 (bottom-center): a cute bundle of mint green seaweed. Cell 9 (bottom-right): a cluster of shiny pastel blue bubbles.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 6. `06_rods_lines` — Rods (5) + fishing line spools (4)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `DriftwoodRod.png` | a simple fishing rod made of pale driftwood with a small wooden reel |
| 2 | top-center | `BambooRod.png` | a green bamboo fishing rod with knotted joints |
| 3 | top-right | `CoralRod.png` | a pink coral fishing rod with little shell decorations |
| 4 | middle-left | `MoonsilverRod.png` | a silver fishing rod with a crescent moon charm and soft blue glow |
| 5 | center | `NagaScaleRod.png` | an emerald fishing rod covered in gold-edged scales, serpent head tip |
| 6 | middle-right | `CottonLine.png` | a spool of soft white cotton fishing line |
| 7 | bottom-left | `HempLine.png` | a spool of tan hemp rope line |
| 8 | bottom-center | `NylonLine.png` | a spool of shiny sky-blue nylon line |
| 9 | bottom-right | `SilkLine.png` | a spool of glittering lavender spider-silk line with a tiny web pattern |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Rods drawn diagonally from bottom-left to top-right with a reel; spools drawn front view. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a simple fishing rod made of pale driftwood with a small wooden reel. Cell 2 (top-center): a green bamboo fishing rod with knotted joints. Cell 3 (top-right): a pink coral fishing rod with little shell decorations. Cell 4 (middle-left): a silver fishing rod with a crescent moon charm and soft blue glow. Cell 5 (center): an emerald fishing rod covered in gold-edged scales, serpent head tip. Cell 6 (middle-right): a spool of soft white cotton fishing line. Cell 7 (bottom-left): a spool of tan hemp rope line. Cell 8 (bottom-center): a spool of shiny sky-blue nylon line. Cell 9 (bottom-right): a spool of glittering lavender spider-silk line with a tiny web pattern.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 7. `07_bags_baits` — Bags (5) + baits (4)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `StarterPouch.png` | a small cream cloth pouch with a drawstring |
| 2 | top-center | `WovenBasket.png` | a woven straw fishing basket with a lid |
| 3 | top-right | `Crate.png` | a wooden fish crate with rope handles |
| 4 | middle-left | `Coolbox.png` | a sky-blue ice cooler box with a white lid and ice cubes |
| 5 | center | `Hold.png` | a sturdy ship's barrel with gold metal bands |
| 6 | middle-right | `Worm.png` | a cute pink earthworm wiggling |
| 7 | bottom-left | `Shrimp.png` | a curled coral shrimp |
| 8 | bottom-center | `GlowGrub.png` | a chubby glowing mint grub with soft light |
| 9 | bottom-right | `SummonBait.png` | a mystical bait: a glowing purple orb wrapped in seaweed (for boss summoning) |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Bags in 3/4 front view, baits as small cute objects. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a small cream cloth pouch with a drawstring. Cell 2 (top-center): a woven straw fishing basket with a lid. Cell 3 (top-right): a wooden fish crate with rope handles. Cell 4 (middle-left): a sky-blue ice cooler box with a white lid and ice cubes. Cell 5 (center): a sturdy ship's barrel with gold metal bands. Cell 6 (middle-right): a cute pink earthworm wiggling. Cell 7 (bottom-left): a curled coral shrimp. Cell 8 (bottom-center): a chubby glowing mint grub with soft light. Cell 9 (bottom-right): a mystical bait: a glowing purple orb wrapped in seaweed (for boss summoning).
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 8. `08_aura_orbs` — Aura orbs (Auras menu + roll reveal)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `SparklingDew.png` | a clear orb filled with sparkling water droplets, pale cyan |
| 2 | top-center | `NeonWave.png` | an orb with a glowing neon blue ocean wave inside |
| 3 | top-right | `SolarFlare.png` | an orb with a swirling orange-gold sun flame inside |
| 4 | middle-left | `AbyssalShadow.png` | an orb with dark purple mist and shadow tentacles inside |
| 5 | center | `DragonEmperor.png` | an orb with a tiny golden eastern dragon coiled inside |
| 6 | middle-right | `SerpentOfTheVoid.png` | an orb with an iridescent rainbow crystal serpent (naga) coiled inside |
| 7 | bottom-left | `UnknownAura.png` | an empty frosted glass orb with a faint grey swirl, mysterious |
| 8 | bottom-center | `fx_sparkle.png` | a single four-pointed white-gold sparkle shape |
| 9 | bottom-right | `fx_glow.png` | a soft round radial glow blob, pale cyan fading to white |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Each cell is a round glowing orb with a different magical element inside; same orb size in every cell. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a clear orb filled with sparkling water droplets, pale cyan. Cell 2 (top-center): an orb with a glowing neon blue ocean wave inside. Cell 3 (top-right): an orb with a swirling orange-gold sun flame inside. Cell 4 (middle-left): an orb with dark purple mist and shadow tentacles inside. Cell 5 (center): an orb with a tiny golden eastern dragon coiled inside. Cell 6 (middle-right): an orb with an iridescent rainbow crystal serpent (naga) coiled inside. Cell 7 (bottom-left): an empty frosted glass orb with a faint grey swirl, mysterious. Cell 8 (bottom-center): a single four-pointed white-gold sparkle shape. Cell 9 (bottom-right): a soft round radial glow blob, pale cyan fading to white.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 9. `09_npc_portraits` — NPC portraits for the Dialogue box (bust, 3 NPCs x 3 expressions)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `Marlin_neutral.png` | Old Marlin, a kind old fish merchant with a white beard, cream fisherman hat and mint scarf, calm expression |
| 2 | top-center | `Marlin_happy.png` | the same Old Marlin, big warm smile, eyes closed happily |
| 3 | top-right | `Marlin_surprised.png` | the same Old Marlin, eyebrows raised, mouth open in surprise |
| 4 | middle-left | `Sela_neutral.png` | Sela, a young aura altar keeper with lavender hair, star hairpin and flowing lavender robe, calm expression |
| 5 | center | `Sela_happy.png` | the same Sela, cheerful smile |
| 6 | middle-right | `Sela_surprised.png` | the same Sela, amazed wide eyes, hands near cheeks |
| 7 | bottom-left | `Pip_neutral.png` | Pip, a small dock kid with a coral beanie, sky-blue raincoat and a tiny fishing net, curious expression |
| 8 | bottom-center | `Pip_happy.png` | the same Pip, grinning with a thumbs up |
| 9 | bottom-right | `Pip_surprised.png` | the same Pip, shocked open mouth, beanie popping up |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Chest-up bust portraits, front 3/4 view, blocky toy-like characters with rounded edges (Roblox-friendly proportions), same framing in every cell. Row 1 = Old Marlin, Row 2 = Sela, Row 3 = Pip; columns = neutral, happy, surprised. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): Old Marlin, a kind old fish merchant with a white beard, cream fisherman hat and mint scarf, calm expression. Cell 2 (top-center): the same Old Marlin, big warm smile, eyes closed happily. Cell 3 (top-right): the same Old Marlin, eyebrows raised, mouth open in surprise. Cell 4 (middle-left): Sela, a young aura altar keeper with lavender hair, star hairpin and flowing lavender robe, calm expression. Cell 5 (center): the same Sela, cheerful smile. Cell 6 (middle-right): the same Sela, amazed wide eyes, hands near cheeks. Cell 7 (bottom-left): Pip, a small dock kid with a coral beanie, sky-blue raincoat and a tiny fishing net, curious expression. Cell 8 (bottom-center): the same Pip, grinning with a thumbs up. Cell 9 (bottom-right): the same Pip, shocked open mouth, beanie popping up.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 10. `10_economy_status` — [P1] Economy currency & status icons (Pearls, Star Token, Streak, Boost...)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `pearl.png` | a single lustrous round pearl with a soft pink-lavender sheen, resting in a small open cream clam shell |
| 2 | top-center | `star_token.png` | a chunky warm gold coin shaped like a five-pointed star with a small lavender gem in the centre |
| 3 | top-right | `hot_streak.png` | a lively coral flame with a tiny cream fish silhouette inside it |
| 4 | middle-left | `hot_price.png` | a coral price tag with a gold string and a small sparkle on its corner |
| 5 | center | `boost.png` | a warm gold lightning bolt inside a round mint badge |
| 6 | middle-right | `offline_reward.png` | a sleepy cream cloud with a small crescent moon and three tiny pearls floating under it |
| 7 | bottom-left | `enhance.png` | a small slate-grey anvil with a gold sparkle burst on top |
| 8 | bottom-center | `mastery_up.png` | a round mint badge with a bold chunky upward arrow shape and a tiny star |
| 9 | bottom-right | `pearl_pile.png` | a small heap of lustrous pink-lavender pearls in a cream clam shell |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Small iconic objects used inside HUD chips, toasts and badges. Must read clearly at 32-48px. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a single lustrous round pearl with a soft pink-lavender sheen, resting in a small open cream clam shell. Cell 2 (top-center): a chunky warm gold coin shaped like a five-pointed star with a small lavender gem in the centre. Cell 3 (top-right): a lively coral flame with a tiny cream fish silhouette inside it. Cell 4 (middle-left): a coral price tag with a gold string and a small sparkle on its corner. Cell 5 (center): a warm gold lightning bolt inside a round mint badge. Cell 6 (middle-right): a sleepy cream cloud with a small crescent moon and three tiny pearls floating under it. Cell 7 (bottom-left): a small slate-grey anvil with a gold sparkle burst on top. Cell 8 (bottom-center): a round mint badge with a bold chunky upward arrow shape and a tiny star. Cell 9 (bottom-right): a small heap of lustrous pink-lavender pearls in a cream clam shell.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 11. `11_menu_icons_2` — [P1] New menu / hub tile icons (Aquarium, Mastery, Store, passes)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `aquarium.png` | a small round glass fish tank with sky-blue water, one coral fish and a few bubbles |
| 2 | top-center | `mastery.png` | a sky-blue open book with a glowing mint star rising from its pages |
| 3 | top-right | `store.png` | a lavender shopping bag with a gold sparkle star on the front |
| 4 | middle-left | `vip.png` | a shiny warm gold crown with three round lavender gems |
| 5 | center | `infinite_bag.png` | a plump gold fishing satchel with a mint infinity-loop charm hanging from the strap (a loop shape, not a letter) |
| 6 | middle-right | `auto_pro.png` | a mint green fishing reel with a small gold gear and soft speed lines |
| 7 | bottom-left | `extra_cast.png` | three small fishing rods fanned out like a hand of cards, coral, mint and sky blue |
| 8 | bottom-center | `starter_pack.png` | a coral gift box with a cream bow and a small fishing rod sticking out of the top |
| 9 | bottom-right | `daily_login.png` | a cream tear-off calendar page with a gold star sticker |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Simple bold glyph-like objects that read clearly at 48px. Same style as sheet 01_menu_icons. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a small round glass fish tank with sky-blue water, one coral fish and a few bubbles. Cell 2 (top-center): a sky-blue open book with a glowing mint star rising from its pages. Cell 3 (top-right): a lavender shopping bag with a gold sparkle star on the front. Cell 4 (middle-left): a shiny warm gold crown with three round lavender gems. Cell 5 (center): a plump gold fishing satchel with a mint infinity-loop charm hanging from the strap (a loop shape, not a letter). Cell 6 (middle-right): a mint green fishing reel with a small gold gear and soft speed lines. Cell 7 (bottom-left): three small fishing rods fanned out like a hand of cards, coral, mint and sky blue. Cell 8 (bottom-center): a coral gift box with a cream bow and a small fishing rod sticking out of the top. Cell 9 (bottom-right): a cream tear-off calendar page with a gold star sticker.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 12. `12_shop_packs` — [P1] Robux store pack art (gems, coins, boosts, starter)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `gems_s.png` | a small cluster of three faceted lavender gems |
| 2 | top-center | `gems_m.png` | a cream pouch overflowing with faceted lavender gems |
| 3 | top-right | `gems_l.png` | an open wooden treasure chest overflowing with faceted lavender gems, soft glow |
| 4 | middle-left | `coins_s.png` | a small stack of shiny gold fish coins |
| 5 | center | `coins_m.png` | a cream sack overflowing with shiny gold fish coins |
| 6 | middle-right | `coins_l.png` | a big wooden crate overflowing with shiny gold fish coins, soft glow |
| 7 | bottom-left | `boost_coins.png` | a shiny gold fish coin with a warm gold lightning bolt in front of it |
| 8 | bottom-center | `boost_pearls.png` | a lustrous pink-lavender pearl with a mint lightning bolt in front of it |
| 9 | bottom-right | `starter_bundle.png` | a coral gift box with the lid open showing a small fishing rod, two lavender gems and a worm bait tin |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Store product pictures. Bigger tiers look visibly bigger and richer than smaller tiers, same camera angle. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a small cluster of three faceted lavender gems. Cell 2 (top-center): a cream pouch overflowing with faceted lavender gems. Cell 3 (top-right): an open wooden treasure chest overflowing with faceted lavender gems, soft glow. Cell 4 (middle-left): a small stack of shiny gold fish coins. Cell 5 (center): a cream sack overflowing with shiny gold fish coins. Cell 6 (middle-right): a big wooden crate overflowing with shiny gold fish coins, soft glow. Cell 7 (bottom-left): a shiny gold fish coin with a warm gold lightning bolt in front of it. Cell 8 (bottom-center): a lustrous pink-lavender pearl with a mint lightning bolt in front of it. Cell 9 (bottom-right): a coral gift box with the lid open showing a small fishing rod, two lavender gems and a worm bait tin.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 13. `13_fish_deep_2` — [P2] Deep & abyssal fish (cell 1 GloomSprat needed for C12; rest = future zones)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `GloomSprat.png` | a small slim navy-blue fish with a single tiny glowing mint dot on its head, plain and common |
| 2 | top-center | `InkletSquid.png` | a small round slate-blue squid with short curly tentacles and big friendly eyes |
| 3 | top-right | `PearlNautilus.png` | a cream and coral striped nautilus shell with a lavender pearl glinting in its opening |
| 4 | middle-left | `FrostRay.png` | a pale sky-blue manta ray with frosty white wing tips |
| 5 | center | `LanternJellyfish.png` | a round lavender jellyfish with a soft glowing gold core and short ribbon tentacles |
| 6 | middle-right | `BoneCarp.png` | a pale cream carp with a gentle skeleton pattern on its side, cute not scary |
| 7 | bottom-left | `StarlightEel.png` | a long deep-purple eel speckled with tiny gold star dots |
| 8 | bottom-center | `AbyssLeviathan.png` | a chunky dark teal sea serpent head and coil with glowing mint eyes, majestic |
| 9 | bottom-right | `VoidKoi.png` | an elegant black and lavender koi with wisps of purple smoke trailing from its fins |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Fish seen from the side facing right, cute rounded shapes, same scale. Deep-sea fish have soft bioluminescent dots. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a small slim navy-blue fish with a single tiny glowing mint dot on its head, plain and common. Cell 2 (top-center): a small round slate-blue squid with short curly tentacles and big friendly eyes. Cell 3 (top-right): a cream and coral striped nautilus shell with a lavender pearl glinting in its opening. Cell 4 (middle-left): a pale sky-blue manta ray with frosty white wing tips. Cell 5 (center): a round lavender jellyfish with a soft glowing gold core and short ribbon tentacles. Cell 6 (middle-right): a pale cream carp with a gentle skeleton pattern on its side, cute not scary. Cell 7 (bottom-left): a long deep-purple eel speckled with tiny gold star dots. Cell 8 (bottom-center): a chunky dark teal sea serpent head and coil with glowing mint eyes, majestic. Cell 9 (bottom-right): an elegant black and lavender koi with wisps of purple smoke trailing from its fins.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 14. `14_materials` — [P2] Enhance materials (Gear Enhance phase 2)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `abyss_scale.png` | a single dark teal fish scale with a faint glowing mint edge |
| 2 | top-center | `glow_ink.png` | a small round glass vial of glowing cyan ink with a cork |
| 3 | top-right | `coral_shard.png` | a pink crystal coral shard |
| 4 | middle-left | `naga_scale.png` | an emerald green serpent scale with a gold rim |
| 5 | center | `void_essence.png` | a swirl of purple and black mist inside a tiny teardrop bottle |
| 6 | middle-right | `enhance_stone.png` | a smooth round mint whetstone with a white sparkle |
| 7 | bottom-left | `moon_pearl.png` | a large silver-blue pearl with a crescent moon reflection |
| 8 | bottom-center | `kelp_fiber.png` | a neat coiled bundle of green kelp rope |
| 9 | bottom-right | `star_shard.png` | a small jagged warm gold crystal shard shaped like a broken star |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Crafting materials dropped from deep fishing. Small, gem-like, readable at 40px. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a single dark teal fish scale with a faint glowing mint edge. Cell 2 (top-center): a small round glass vial of glowing cyan ink with a cork. Cell 3 (top-right): a pink crystal coral shard. Cell 4 (middle-left): an emerald green serpent scale with a gold rim. Cell 5 (center): a swirl of purple and black mist inside a tiny teardrop bottle. Cell 6 (middle-right): a smooth round mint whetstone with a white sparkle. Cell 7 (bottom-left): a large silver-blue pearl with a crescent moon reflection. Cell 8 (bottom-center): a neat coiled bundle of green kelp rope. Cell 9 (bottom-right): a small jagged warm gold crystal shard shaped like a broken star.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 15. `15_aura_orbs_2` — [P2] New aura orbs for future banners (gacha content)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `TidalBloom.png` | a mint orb with a small water flower blooming inside |
| 2 | top-center | `CoralHeart.png` | a coral pink orb with a heart-shaped coral branch glowing inside |
| 3 | top-right | `MoonlitRipple.png` | a deep blue orb with a crescent moon over gentle silver ripples inside |
| 4 | middle-left | `KelpWhisper.png` | a green orb with swaying kelp strands and tiny bubbles inside |
| 5 | center | `StormCurrent.png` | a sky-blue orb with a swirling whirlpool and small gold lightning sparks inside |
| 6 | middle-right | `FrostPearl.png` | a pale icy orb with a single white pearl surrounded by snowflake sparkles |
| 7 | bottom-left | `NebulaKoi.png` | a lavender and pink galaxy orb with a small glowing koi swimming inside |
| 8 | bottom-center | `LotusNaga.png` | an emerald orb with a coiled naga serpent around a pink lotus inside, majestic |
| 9 | bottom-right | `CelestialLeviathan.png` | a rainbow prismatic orb with a crystal sea serpent coiling inside, the most dazzling of the set |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Same orb style as sheet 08_aura_orbs: a glowing orb with the aura motif swirling inside, no character. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a mint orb with a small water flower blooming inside. Cell 2 (top-center): a coral pink orb with a heart-shaped coral branch glowing inside. Cell 3 (top-right): a deep blue orb with a crescent moon over gentle silver ripples inside. Cell 4 (middle-left): a green orb with swaying kelp strands and tiny bubbles inside. Cell 5 (center): a sky-blue orb with a swirling whirlpool and small gold lightning sparks inside. Cell 6 (middle-right): a pale icy orb with a single white pearl surrounded by snowflake sparkles. Cell 7 (bottom-left): a lavender and pink galaxy orb with a small glowing koi swimming inside. Cell 8 (bottom-center): an emerald orb with a coiled naga serpent around a pink lotus inside, majestic. Cell 9 (bottom-right): a rainbow prismatic orb with a crystal sea serpent coiling inside, the most dazzling of the set.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 16. `16_equipment_2` — [P3] Equipment for later tiers + Starter Pack rod

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `SweetheartRod.png` | a cute coral and cream candy-striped fishing rod with a small heart-shaped bobber |
| 2 | top-center | `AbyssRod.png` | a dark teal fishing rod with glowing mint runes along the handle |
| 3 | top-right | `CelestialRod.png` | an elegant white and gold fishing rod with a small star at the tip |
| 4 | middle-left | `AbyssLine.png` | a spool of dark teal glowing fishing line |
| 5 | center | `StarLine.png` | a spool of shimmering gold fishing line with tiny stars |
| 6 | middle-right | `BottomlessBag.png` | a lavender satchel with a swirling galaxy pattern inside its open flap |
| 7 | bottom-left | `PearlBait.png` | a small tin of lustrous pearl beads used as bait |
| 8 | bottom-center | `SquidBait.png` | a small jar of slate-blue squid bait pieces |
| 9 | bottom-right | `StormBait.png` | a small glass jar with a tiny glowing storm cloud inside |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Same look as sheets 06_rods_lines and 07_bags_baits: item shown diagonally, same scale. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a cute coral and cream candy-striped fishing rod with a small heart-shaped bobber. Cell 2 (top-center): a dark teal fishing rod with glowing mint runes along the handle. Cell 3 (top-right): an elegant white and gold fishing rod with a small star at the tip. Cell 4 (middle-left): a spool of dark teal glowing fishing line. Cell 5 (center): a spool of shimmering gold fishing line with tiny stars. Cell 6 (middle-right): a lavender satchel with a swirling galaxy pattern inside its open flap. Cell 7 (bottom-left): a small tin of lustrous pearl beads used as bait. Cell 8 (bottom-center): a small jar of slate-blue squid bait pieces. Cell 9 (bottom-right): a small glass jar with a tiny glowing storm cloud inside.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 17. `17_inventory_tabs` — Inventory side-tab icons (+ Bag Upgrade)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `all.png` | a small cozy wooden treasure crate overflowing with a fish, a coin and a little orb, all four items tiny and simple |
| 2 | top-center | `fish.png` | a single plump sky-blue cartoon fish facing left with a tiny coral fin |
| 3 | top-right | `rods.png` | a short chunky fishing rod drawn diagonally with a gold reel and a curled line |
| 4 | middle-left | `lines.png` | a round spool of mint fishing line with the loose end curling out |
| 5 | center | `auras.png` | a glowing lavender magic orb with a small sparkle star inside |
| 6 | middle-right | `baits.png` | a small cream tin of bait with a pink worm peeking over the rim |
| 7 | bottom-left | `treasure.png` | a small coral treasure chest with gold trim, lid slightly open with a soft glow |
| 8 | bottom-center | `materials.png` | three stacked crafting materials: a sky-blue crystal shard, a mint fish scale and a small pearl |
| 9 | bottom-right | `bag_upgrade.png` | a plump gold fishing satchel with a big mint up-arrow badge on its front |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Inventory v2 icon rail. Must read clearly at 36px: one bold simple object each, strong silhouette, very little detail. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a small cozy wooden treasure crate overflowing with a fish, a coin and a little orb, all four items tiny and simple. Cell 2 (top-center): a single plump sky-blue cartoon fish facing left with a tiny coral fin. Cell 3 (top-right): a short chunky fishing rod drawn diagonally with a gold reel and a curled line. Cell 4 (middle-left): a round spool of mint fishing line with the loose end curling out. Cell 5 (center): a glowing lavender magic orb with a small sparkle star inside. Cell 6 (middle-right): a small cream tin of bait with a pink worm peeking over the rim. Cell 7 (bottom-left): a small coral treasure chest with gold trim, lid slightly open with a soft glow. Cell 8 (bottom-center): three stacked crafting materials: a sky-blue crystal shard, a mint fish scale and a small pearl. Cell 9 (bottom-right): a plump gold fishing satchel with a big mint up-arrow badge on its front.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 18. `18_mastery_icons` — Mastery track icons (full-colour set)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `luck.png` | a lucky mint four-leaf clover with a tiny gold sparkle |
| 2 | top-center | `catch_bar.png` | a short vertical glass tube gauge with a glowing mint bar segment inside and a tiny fish silhouette |
| 3 | top-right | `reel_power.png` | a chunky gold fishing reel with a small coral handle and motion swoosh |
| 4 | middle-left | `auto_wait.png` | a round sky-blue stopwatch with a small fish-shaped hand and a mint fast-forward arrow |
| 5 | center | `pearl_rate.png` | a pink-white glossy pearl resting in a small open lavender clam with an up sparkle |
| 6 | middle-right | `offline_cap.png` | a cozy crescent moon with a small sleeping fishing bobber hanging from it |
| 7 | bottom-left | `sell_mult.png` | a small cream coin pouch with a gold coin and a coral x2 shaped ribbon tag (no readable text, just a ribbon) |
| 8 | bottom-center | `locked.png` | a soft slate-grey rounded padlock with a small mint keyhole glow |
| 9 | bottom-right | `total_level.png` | a gold star medal with a lavender ribbon and a small up-arrow on the star |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Replaces the white vector icons on Mastery cards. One matching set; must read clearly at 46px. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a lucky mint four-leaf clover with a tiny gold sparkle. Cell 2 (top-center): a short vertical glass tube gauge with a glowing mint bar segment inside and a tiny fish silhouette. Cell 3 (top-right): a chunky gold fishing reel with a small coral handle and motion swoosh. Cell 4 (middle-left): a round sky-blue stopwatch with a small fish-shaped hand and a mint fast-forward arrow. Cell 5 (center): a pink-white glossy pearl resting in a small open lavender clam with an up sparkle. Cell 6 (middle-right): a cozy crescent moon with a small sleeping fishing bobber hanging from it. Cell 7 (bottom-left): a small cream coin pouch with a gold coin and a coral x2 shaped ribbon tag (no readable text, just a ribbon). Cell 8 (bottom-center): a soft slate-grey rounded padlock with a small mint keyhole glow. Cell 9 (bottom-right): a gold star medal with a lavender ribbon and a small up-arrow on the star.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## 19. `19_shop_packs_2` — [P2] Robux bundle pack art (starter-style offers, 9 new packs)

| Cell | Position | File | Content |
|---|---|---|---|
| 1 | top-left | `pack_angler.png` | a cream tackle satchel with a gold buckle, a mint fishing rod poking out and a small coral worm bait tin beside it |
| 2 | top-center | `pack_aura_roller.png` | a lavender glowing magic orb on a small gold stand with three faceted gems floating around it and a soft sparkle |
| 3 | top-right | `pack_lucky.png` | a mint four-leaf clover charm on a gold chain lying on top of a small cream coin pouch |
| 4 | middle-left | `pack_deep_sea.png` | a navy-blue diving helmet with a round glass window, a coral lantern fish charm and two lavender pearls beside it |
| 5 | center | `pack_pearl_boost.png` | a lustrous pink-lavender pearl in an open cream clam, with a mint lightning bolt and a tiny gold up arrow |
| 6 | middle-right | `pack_aquarium.png` | a small round glass fish bowl with a cute sky-blue fish, a mint seaweed sprig and a few gold pebbles |
| 7 | bottom-left | `pack_naga_tide.png` | a coiled teal sea dragon figurine with a gold crest curled around a lavender wave crystal |
| 8 | bottom-center | `pack_mastery.png` | a gold star medal with a mint ribbon on top of a stack of three small coral books |
| 9 | bottom-right | `pack_legend_chest.png` | a big gold-trimmed wooden treasure chest with a lavender gem on the lid, slightly open with a warm glow and two sparkles |

**Prompt**
```text
Game asset sprite sheet for a cozy pastel fishing game (Cozy Lake style). Square 1:1 image split into a perfect 3x3 grid of 9 equal square cells, separated by clean, straight, evenly spaced pure white gutters. Every cell has a flat solid pure white (#FFFFFF) background and contains exactly ONE centered object that fills about 70% of the cell and never touches or crosses the cell edges. Art style: soft cel-shaded 3D cartoon, chunky rounded friendly shapes, gentle top-left lighting with one soft highlight, outlines in a slightly darker shade of each object's own color (never black), soft pastel palette (mint #7FD3B0, coral #FF9E80, sky blue #9AD4F5, warm gold #F2B544, lavender #B79CF2, cream #FFF8EC, slate #3D4B5C for small details). Same camera angle, scale and lighting in all 9 cells so they look like one matching set. No text, no letters, no numbers, no watermark, no frames, no cell borders, no background scenery, no cast shadow on the white background. Set note: Bundle pictures for store offers. Each is a small themed bundle that reads as a gift pack at 150px; richer packs look bigger and glow slightly more. Same camera angle as the starter bundle. The 9 cells, in reading order left to right, top to bottom: Cell 1 (top-left): a cream tackle satchel with a gold buckle, a mint fishing rod poking out and a small coral worm bait tin beside it. Cell 2 (top-center): a lavender glowing magic orb on a small gold stand with three faceted gems floating around it and a soft sparkle. Cell 3 (top-right): a mint four-leaf clover charm on a gold chain lying on top of a small cream coin pouch. Cell 4 (middle-left): a navy-blue diving helmet with a round glass window, a coral lantern fish charm and two lavender pearls beside it. Cell 5 (center): a lustrous pink-lavender pearl in an open cream clam, with a mint lightning bolt and a tiny gold up arrow. Cell 6 (middle-right): a small round glass fish bowl with a cute sky-blue fish, a mint seaweed sprig and a few gold pebbles. Cell 7 (bottom-left): a coiled teal sea dragon figurine with a gold crest curled around a lavender wave crystal. Cell 8 (bottom-center): a gold star medal with a mint ribbon on top of a stack of three small coral books. Cell 9 (bottom-right): a big gold-trimmed wooden treasure chest with a lavender gem on the lid, slightly open with a warm glow and two sparkles.
```
**Negative**
```text
text, letters, numbers, watermark, signature, black outline, photorealistic, noisy texture, gradient background, colored background, scenery, multiple objects in one cell, objects crossing cell borders, uneven grid, 4x4 grid, 2x2 grid, cropped objects
```

---

## Bonus — single images (not grids)

**Game icon (1:1, 512×512, for the Roblox game page)**
```text
Roblox game icon, cozy pastel fishing game called Aura Fishing. A cute chunky round fish jumping out of calm mint-blue water, surrounded by a soft lavender and gold magical aura glow, a coral and cream fishing bobber in the corner. Soft cel-shaded 3D cartoon, rounded friendly shapes, pastel palette (mint #7FD3B0, coral #FF9E80, sky #9AD4F5, gold #F2B544, lavender #B79CF2), bright and readable at small size, centered composition, no text, no letters.
```

**Game thumbnail (16:9, 1920×1080)**
```text
Wide cozy scene for a Roblox fishing game: a small round grassy island with a wooden dock on a calm pastel lake at golden hour, a blocky toy-like Roblox-style character casting a fishing rod with a glowing lavender aura swirling around them, a big shiny fish leaping from the water, soft cel-shaded 3D cartoon, pastel palette mint, coral, sky blue, warm gold, lavender, soft light, lots of empty sky on the right for a title, no text.
```

**Loading screen background (16:9)**
```text
Soft dreamy pastel lake at dawn seen from a wooden dock, gentle ripples, floating sparkles, distant small islands, mint and sky-blue water, cream and peach sky, cozy and calm, soft cel-shaded 3D cartoon, very low detail in the centre so UI can sit on top, no characters, no text.
```
