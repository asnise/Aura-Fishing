# ชุด Prompt แยก Layer สำหรับ Solar Flare (Monochrome Luma Matte)

> **วิธีใช้:** คัดลอก Prompt ด้านล่างส่งให้ Image Gen AI  
> ทุกภาพเป็น **Monochrome สีขาวบนพื้นหลังสีดำสนิท `#000000`**

---

## ทิศทางภาพชุดถัดไป

แสงอาทิตย์สะท้อนน้ำเป็นวงทองค่อย ๆ แผ่ มีไอน้ำสีอำพันตามขอบวง

แกน 01 เล่นต่อเนื่องที่ขนาดคงที่และเฟดตามจังหวะ ระลอก 02 กับอนุภาค 05 พาแรงออกจากศูนย์กลาง ส่วน 03 เป็นแถบหลักสำหรับโคจรและประกบริ้วรองที่บางกว่า

[เปิดพรีวิวออร่า](preview.html) · [แนวจัดเลเยอร์จาก Dark Arcane](../AURA_VFX_PIPELINE_GUIDE.md#4-ทิศทางภาพก่อนเจนรอบถัดไป)

## 1. Core Wisps & Solar Vapor (ลำแสงไอน้ำประกายแดดทอง)
- **ชื่อไฟล์:** `01_core_solar_vapor_4x4.png`
- **โครงสร้าง:** 4x4 Flipbook Grid (16 เฟรม เรียงซ้ายไปขวา บนลงล่าง)

```text
Exactly one square 1024x1024 4x4 flipbook sheet with 16 equal cells, read left to right then top to bottom. Keep all art inside its cell with at least 10% clear black padding.

A single column of warm vapor over a calm lake, with crisp narrow bars of reflected sunlight inside transparent folds. Give the bright reflections a slow upward drift.

Keep one fixed bottom-center pivot at 85% of each cell height. Hold the outer scale and placement stable across the entire sequence. Internal ribbons flow upward as intensity rises and falls. Frames 1-4 gently fade in, 5-12 carry the movement, 13-16 fade out into the start of the loop. Clear silhouettes at mid-cycle. Keep floor ripples, orbit rings and separated particles in their own sheets.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```

---

## 2. Ground Sunburst Disk (รัศมีแดดสะท้อนผิวน้ำที่พื้น)
- **ชื่อไฟล์:** `02_ground_sunburst_disk_4x4.png`
- **โครงสร้าง:** 4x4 Flipbook Grid (16 เฟรม)

```text
Exactly one square 1024x1024 4x4 flipbook sheet with 16 equal cells, read left to right then top to bottom. Keep all art inside its cell with at least 10% clear black padding.

Orthographic overhead view, one fixed central origin in every cell.

Open concentric caustic rims like low sunlight reflecting on lake water. Use a few rounded reflected light spokes which lengthen with the expanding rim and fade across the water.

Frames 1-4 start with a tight wave, 5-9 expand beyond the origin, 10-13 send the brightest edge and sparse spray farther outward, 14-16 continue outward while fading. The final visible radius is the widest. Keep the middle open and use disconnected fine edge detail. Show the shallow surface itself with no horizon or upright plume.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```

---

## 3. Orbital Solar Corona (สายละอองแสงหมุนวน - Tier 3)
- **ชื่อไฟล์:** `03_orbital_solar_corona_strip.png`
- **โครงสร้าง:** 1x1 Seamless Horizontal Tileable Strip (1024x256)

```text
Exactly one 1024x256 continuous 4:1 horizontal water texture band, flat across the middle third of the canvas height.

A narrow flowing ribbon of reflected sunshine, with a white leading edge, soft vapor along the rear, and sparse pinpricks tracing its wake.

Wrap from right to left with matching brightness, vertical position and slope at both ends. Reserve water-only space near both edges so the engine can reuse a short part for a tapering companion trail. The UV strip is flat, the preview bends it around the player. Space out its highlights and keep the upper and lower margins pure black.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```

---

## 4. Golden Sun Flares (แสงแฟลร์เพชรน้ำประกายทอง)
- **ชื่อไฟล์:** `04_golden_sun_flares_4x4.png`
- **โครงสร้าง:** 4x4 Flipbook Grid (16 เฟรม)

```text
Exactly one square 1024x1024 4x4 flipbook sheet with 16 equal cells, read left to right then top to bottom. Keep all art inside its cell with at least 10% clear black padding.

One centered brief glint per cell with the same anchor.

One warm-looking four-point sun glint with an oval hotspot and a subtle bright horizon streak, like a reflection at sunset.

Start dim and pinpoint-sized, briefly increase intensity at frames 6-9 and taper through 16. Leave room for additive bloom. Keep the surrounding area empty.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```

---

## 5. Sun Embers Atlas (ละอองแดด & เม็ดแสงเพชรน้ำ)
- **ชื่อไฟล์:** `05_sun_embers_atlas_2x2.png`
- **โครงสร้าง:** 2x2 Static Texture Atlas (4 รูปทรงแยก)

```text
Exactly one 512x512 2x2 atlas of four distinct isolated particles in row-major order.

Top left: bright radiant solar orb with soft outer ring. Top right: diamond-shaped water sparkle shard. Bottom left: warm floating sun ember mote. Bottom right: tiny curved solar filament drop.

Give each particle an independent, readable outline and soft falloff at small game scale. Center each object inside its quadrant with at least 15% black padding on each edge. These are individual particles for radial scatter and slow drift.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```
