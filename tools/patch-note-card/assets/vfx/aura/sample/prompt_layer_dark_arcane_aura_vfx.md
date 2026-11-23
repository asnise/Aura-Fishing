# ชุด Prompt แยกตาม Layer (Copy-Paste)

ทุก Prompt ถูกออกแบบเป็น **Monochrome / White-on-Black (`#000000`)** เพื่อแปลงค่าความสว่างเป็น Alpha (Luma Matte) และคุม Gradient สี (ขาว -> ฟ้า -> ม่วง/ดำ) ด้วย Shader ใน Engine ซึ่งประหยัด VRAM และคุมโทนสีให้ตรงกันทุกชิ้นได้ง่ายกว่าให้ AI ลงสีเอง

---

## 1. เปลวพลังงาน & ควันขอบคม (ใช้ทั้ง Dark Wisps และ Blue Flames)
* **ชื่อไฟล์แนะนำเมื่อบันทึก:** `01_core_wisps_4x4.png`

```text
2D game VFX sprite sheet, 4x4 flipbook grid, 16 frames animation sequence from left to right top to bottom, stylized anime dark energy flame burst rising upward and dissolving into sharp wispy tendrils, cel-shaded painterly brushwork, crisp jagged silhouette, monochrome pure white and bright gray on solid pure black background #000000, strictly orthographic flat 2D, each frame evenly spaced and centered in its grid cell, no grid lines, no borders, no text, high contrast, game asset
```

---

## 2. คลื่นแฉกพลังงานบนพื้น (Ground Radial Splash)
* **ชื่อไฟล์แนะนำเมื่อบันทึก:** `02_ground_burst_4x4.png`

```text
2D game VFX sprite sheet, 4x4 flipbook grid, 16 frames animation sequence from left to right top to bottom, top-down view radial spiky energy shockwave expanding outward from center into sharp ink-like tendrils and dissolving, anime stylized VFX, crisp hard edges with motion streaks, monochrome white on solid pure black background #000000, orthographic top-down view, evenly spaced and centered in each cell, no grid lines, no borders, no text, game asset
```

---

## 3. วงโค้งพลังงานหมุนรอบตัว (Orbital Crescent Slash Arcs — Tier 3)

### แบบ A: Flipbook Grid (สำหรับ Billboard หรือ Mesh เปลี่ยนเฟรม)
* **ชื่อไฟล์แนะนำเมื่อบันทึก:** `03_orbital_arc_4x4.png`

```text
2D game VFX sprite sheet, 4x4 flipbook grid, 16 frames animation sequence from left to right top to bottom, curved crescent energy slash arc sweeping in a circular motion and eroding into sharp fragments along the tail, anime stylized VFX, razor-sharp leading edge with stylized holes and notched trail, monochrome pure white on solid pure black background #000000, flat 2D orthographic, evenly aligned in grid cells, no grid lines, no borders, no text
```

### แบบ B: Tileable Strip Texture (แนะนำกว่าสำหรับงาน Real-time — แปะลง Mesh วงแหวนแล้ว Pan UV)
* **ชื่อไฟล์แนะนำเมื่อบันทึก:** `03_orbital_strip.png`

```text
Seamless horizontal tiling 2D game VFX texture strip, stylized anime energy slash trail with razor-sharp bright top edge and jagged dissolving flame-like tail with small carved holes, hand-painted cel-shaded style, pure white on solid pure black background #000000, flat 2D texture map, high contrast, no perspective, no borders
```

---

## 4. แสงแฟลร์ 4 แฉก & แกนกลาง (4-Point Anime Star Flares)
* **ชื่อไฟล์แนะนำเมื่อบันทึก:** `04_star_flares_4x4.png`

```text
2D game VFX sprite sheet, 4x4 flipbook grid, 16 frames animation sequence, stylized anime 4-point diamond star glint flare expanding rapidly from a pinpoint to a bright cross flare with long horizontal streak and shrinking back to nothing, crisp glowing core, monochrome pure white on solid pure black background #000000, centered in each cell, no grid lines, no borders, no text
```

---

## 5. สะเก็ด, เศษพลังงาน & เม็ดแสง (Static Particle Atlas 2x2)
* **ชื่อไฟล์แนะนำเมื่อบันทึก:** `05_sparks_atlas_2x2.png`

```text
2D game VFX particle texture atlas, 2x2 grid containing 4 distinct isolated shapes: top-left sharp glowing circular orb, top-right thin elongated needle spark streak, bottom-left angular jagged anime diamond shard flake, bottom-right irregular spiky energy droplet, stylized cel-shaded game VFX, pure white on solid pure black background #000000, well-padded margins, no grid lines, no borders, no text
```