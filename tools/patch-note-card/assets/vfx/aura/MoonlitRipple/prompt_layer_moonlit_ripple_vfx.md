# ชุด Prompt แยก Layer สำหรับ Moonlit Ripple (Monochrome Luma Matte)

> **วิธีใช้:** คัดลอก Prompt ด้านล่างส่งให้ Image Gen AI  
> ทุกภาพเป็น **Monochrome สีขาวบนพื้นหลังสีดำสนิท `#000000`**

---

## ทิศทางภาพชุดถัดไป

ระลอกสีเงินขยายเป็นวงเปิด ประกายเพชรตอบรับริ้วน้ำที่โคจรช้า

แกน 01 เล่นต่อเนื่องที่ขนาดคงที่และเฟดตามจังหวะ ระลอก 02 กับอนุภาค 05 พาแรงออกจากศูนย์กลาง ส่วน 03 เป็นแถบหลักสำหรับโคจรและประกบริ้วรองที่บางกว่า

[เปิดพรีวิวออร่า](preview.html) · [แนวจัดเลเยอร์จาก Dark Arcane](../AURA_VFX_PIPELINE_GUIDE.md#4-ทิศทางภาพก่อนเจนรอบถัดไป)

## 1. Core Wisps & Moonbeam Mist (หมอกไอน้ำลำแสงจันทร์)
- **ชื่อไฟล์:** `01_core_moonbeam_mist_4x4.png`
- **โครงสร้าง:** 4x4 Flipbook Grid (16 เฟรม เรียงซ้ายไปขวา บนลงล่าง)

```text
Exactly one square 1024x1024 4x4 flipbook sheet with 16 equal cells, read left to right then top to bottom. Keep all art inside its cell with at least 10% clear black padding.

A single slim silver vapor column with a long folded edge and sparse specks inside it. Let the curved moonbeam slip upward through a translucent midtone wash.

Keep one fixed bottom-center pivot at 85% of each cell height. Hold the outer scale and placement stable across the entire sequence. Internal ribbons flow upward as intensity rises and falls. Frames 1-4 gently fade in, 5-12 carry the movement, 13-16 fade out into the start of the loop. Clear silhouettes at mid-cycle. Keep floor ripples, orbit rings and separated particles in their own sheets.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```

---

## 2. Ground Lunar Ripple (วงคลื่นน้ำสีเงินที่พื้น)
- **ชื่อไฟล์:** `02_ground_lunar_concentric_ripple_4x4.png`
- **โครงสร้าง:** 4x4 Flipbook Grid (16 เฟรม)

```text
Exactly one square 1024x1024 4x4 flipbook sheet with 16 equal cells, read left to right then top to bottom. Keep all art inside its cell with at least 10% clear black padding.

Orthographic overhead view, one fixed central origin in every cell.

Two to three clean concentric rim highlights travel across a clear mirror-like surface. Keep the thin outer wave legible at its widest radius and use sparse bright reflection flecks.

Frames 1-4 start with a tight wave, 5-9 expand beyond the origin, 10-13 send the brightest edge and sparse spray farther outward, 14-16 continue outward while fading. The final visible radius is the widest. Keep the middle open and use disconnected fine edge detail. Show the shallow surface itself with no horizon or upright plume.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```

---

## 3. Orbital Silver Halo (วงแหวนสายน้ำสีเงิน - Tier 3)
- **ชื่อไฟล์:** `03_orbital_silver_halo_strip.png`
- **โครงสร้าง:** 1x1 Seamless Horizontal Tileable Strip (1024x256)

```text
Exactly one 1024x256 continuous 4:1 horizontal water texture band, flat across the middle third of the canvas height.

One narrow silky current with spaced diamond glints along the water line. Keep the profile slender and the spaces around the glints clear.

Wrap from right to left with matching brightness, vertical position and slope at both ends. Reserve water-only space near both edges so the engine can reuse a short part for a tapering companion trail. The UV strip is flat, the preview bends it around the player. Space out its highlights and keep the upper and lower margins pure black.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```

---

## 4. Moonlit Diamond Glints (ประกายเพชรสะท้อนแสงจันทร์)
- **ชื่อไฟล์:** `04_moonlit_diamond_glints_4x4.png`
- **โครงสร้าง:** 4x4 Flipbook Grid (16 เฟรม)

```text
Exactly one square 1024x1024 4x4 flipbook sheet with 16 equal cells, read left to right then top to bottom. Keep all art inside its cell with at least 10% clear black padding.

One centered brief glint per cell with the same anchor.

A small four-point diamond with one strong horizontal specular streak, a tiny clear core, and a silver halo that fades smoothly.

Start dim and pinpoint-sized, briefly increase intensity at frames 6-9 and taper through 16. Leave room for additive bloom. Keep the surrounding area empty.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```

---

## 5. Silver Droplets Atlas (หยดน้ำเงิน & ละอองแสง)
- **ชื่อไฟล์:** `05_silver_droplets_atlas_2x2.png`
- **โครงสร้าง:** 2x2 Static Texture Atlas (4 รูปทรงแยก)

```text
Exactly one 512x512 2x2 atlas of four distinct isolated particles in row-major order.

Top left: pristine round liquid droplet with sharp highlight. Top right: delicate crescent moon motif droplet. Bottom left: soft glowing stardust orb. Bottom right: tiny diamond specular glint.

Give each particle an independent, readable outline and soft falloff at small game scale. Center each object inside its quadrant with at least 15% black padding on each edge. These are individual particles for radial scatter and slow drift.

White and grayscale luma matte on perfectly solid black #000000 for a Cozy Lake fantasy fishing game. Use a small, bright white highlight, a readable midtone shape and a restrained feathered edge. Keep transparent-looking negative space. Flat 2D game texture. No scene, character, combat burst, captions, grid lines, borders or watermark.
```
