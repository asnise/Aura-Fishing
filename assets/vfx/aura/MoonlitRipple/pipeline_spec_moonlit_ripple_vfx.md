# VFX Production Pipeline Specification: Moonlit Ripple Aura

> **Aura Identity:** Moonlit Ripple (Rare - 1 in 250)  
> **Core Theme:** Serene midnight lake under a full moon, pristine concentric ripples, diamond water reflections, and quiet silver halo  
> **Target Platforms:** Roblox Studio (ParticleEmitter / Attachments / PointLight) & Universal Real-Time Engine Shaders  

---

## 0. Project Configuration

```yaml
AURA_ID: "MoonlitRipple"
DISPLAY_NAME: "Moonlit Ripple"
RARITY: "Rare"
CHANCE: 250
PRIMARY_COLOR: "#C8DCFF"       # Moonlit Silver (RGB: 200, 220, 255)
SECONDARY_COLOR: "#283CA0"     # Midnight Deep Indigo (RGB: 40, 60, 160)
ACCENT_COLOR: "#829FFF"        # Lunar Glow Lavender (RGB: 130, 159, 255)
HIGHLIGHT_COLOR: "#FFFFFF"     # Specular Starlight White (RGB: 255, 255, 255)
TARGET_FPS: 14                 # Smooth, tranquil cadence for calm nocturnal reflection
DEFAULT_ATLAS_SIZE: 1024
```

---

## 1. Input Asset Inventory (หน้าที่และการทำงานของแต่ละ Texture)

เอกสารนี้ระบุหน้าที่เฉพาะเจาะจงของ Texture แต่ละไฟล์ เพื่อให้ AI Agent และนักพัฒนาทราบว่าภาพใดนำไปประกอบเป็นเลเยอร์ใดและทำงานอย่างไร:

| ลำดับไฟล์ | ชื่อไฟล์ภาพ | รูปแบบ (Grid / Format) | Anchor Mode | หน้าที่และการทำงานในเกม (Role & Purpose) |
| :--- | :--- | :--- | :--- | :--- |
| `01` | `01_core_moonbeam_mist_4x4.png` | Flipbook 4x4 (16 frames) | `bottom_center` | **Moonbeam Vapor Column:** ลำแสงไอหมอกสีเงินสะท้อนแสงจันทร์ ลอยตัวขึ้นในแนวตั้งอย่างเงียบสงบ ให้ความรู้สึกเหมือนลำแสงจันทร์ส่องลอดเมฆลงมากระทบตัวผู้เล่น |
| `02` | `02_ground_lunar_concentric_ripple_4x4.png` | Flipbook 4x4 (16 frames) | `center` | **Concentric Lunar Ripples:** วงระลอกคลื่นน้ำสีเงินทรงกลมหลายชั้น (Concentric Rings) ค่อยๆ ขยายตัวออกจากจุดศูนย์กลางรอบเท้าและจางหายอย่างนุ่มนวล จำลองหยดน้ำกระทบผิวน้ำนิ่งยามค่ำคืน |
| `03` | `03_orbital_silver_halo_strip.png` | Tileable Strip 1x1 (1024x256) | `none` | **Orbital Lunar Halo:** วงแหวนสายน้ำสีเงินโคจรระนาบเอียงรอบเอวผู้เล่นใน Tier 3 ทอแสงนวลตาเสริมความสง่างาม |
| `04` | `04_moonlit_diamond_glints_4x4.png` | Flipbook 4x4 (16 frames) | `center` | **Specular Diamond Glints:** ประกายแสงรูปเพชร 4 แฉก วาบขึ้นบนผิวน้ำและรอบตัวผู้เล่นเหมือนแสงสะท้อนดวงดาวบนผิวน้ำที่นิ่งสนิท |
| `05` | `05_silver_droplets_atlas_2x2.png` | Static Atlas 2x2 (4 Sprites) | `center` | **Nocturnal Droplet Atlas:** แยกเป็น 4 วัตถุย่อยตามช่อง Atlas (ดูรายละเอียดด้านล่าง) |

### รายละเอียดการแบ่งช่องใน Atlas `05_silver_droplets_atlas_2x2.png`:
- **Frame 0 (Top-Left - Pristine Water Droplet):** หยดน้ำทรงกลมใสสะท้อนเงาจันทร์ ลอยขึ้นจากผิวน้ำ ย้อมสีเงินคราม `#C8DCFF`
- **Frame 1 (Top-Right - Crescent Water Motif):** หยดน้ำทรงเสี้ยวพระจันทร์ ปลิวหมุนช้าๆ ในแนวเฉียง ย้อมสี `#829FFF`
- **Frame 2 (Bottom-Left - Luminous Stardust Orb):** ละอองเกสรแสงดาวกลมฟุ้ง ลอยล่องช้าๆ รอบระดับอกผู้เล่น
- **Frame 3 (Bottom-Right - Micro Diamond Glint):** สะเก็ดแสงประกายเพชรขนาดจิ๋ว สว่างวาบแผ่วเบาเพื่อสร้างมิติดั่งผิวน้ำระยิบระยับ

---

## 2. Phase 1: Automated Image Cleaning & Repacking

```yaml
BLACK_CUT: 0.05               # ตัด Noise ดำรอบขอบให้เหลือเพียงแสงสีเงิน
WHITE_CUT: 0.95               # รักษาระดับ White Core ให้มีประกายแสงสะท้อน
BORDER_CROP: 0.03             # ตัดขอบ 3%
GAMMA: 1.0                    # คงความเนียนนุ่มของแสงสะท้อนผิวน้ำ
ANCHOR_MODE_CORE: "bottom_center" # ยึดโคนลำแสงให้อยู่ระดับผิวน้ำ
ANCHOR_MODE_GROUND: "center"  # ให้วงคลื่นน้ำขยายออกจากจุดสัมผัสพื้นอย่างแม่นยำ
```

---

## 3. Phase 2: Color Gradient & Shader Mapping

- **Outer Color (ขอบนอก):** `#1E2850` (Deep Nocturne Navy - กลมกลืนกับน้ำยามดึก)
- **Mid Color (เนื้ออนุภาค):** `#829FFF` (Moonlit Lavender-Blue - เนื้อแสงจันทร์)
- **Core Color (แกนสว่าง):** `#FFFFFF` (Pure Silver Specular - จุดสะท้อนแสงจันทร์สูงสุด)
- **PointLight Tint:** `#C8DCFF` (Silver-Blue Soft Glow, Brightness: 1.2, Range: 10 Studs)

---

## 4. Phase 3: Layer Architecture & Render Order (สถาปัตยกรรมและบทบาททุกเลเยอร์)

| Sort Order | ชื่อเลเยอร์ (Layer Name) | ไฟล์ Texture / Frame | Blend Mode | รหัสสี (Color Palette) | พฤติกรรมการเคลื่อนไหวและตำแหน่ง (Transform & Behavior) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0` | `Ground_LunarRipples` | `02_ground` (All) | Additive / Screen | `#C8DCFF` | วางแบนราบกับพื้น (`FacingCameraUp`), ขนาดสเกล 2.6 Studs, วงคลื่นน้ำขยายตัวช้าๆ |
| `1` | `Ground_CausticHalo` | `02_ground` (All) | Additive | `#829FFF` (Opacity 0.4) | วงแหวนแสงนุ่มที่พื้น ซ้อนทับวงคลื่นเพื่อสร้างเงาสะท้อนแสงจันทร์ตกกระทบน้ำ |
| `2` | `Core_MoonbeamColumn`| `01_core` (All) | Additive / Screen | `#C8DCFF` -> `#FFFFFF` | เสาหมอกแสงจันทร์แนวตั้ง ลอยขึ้นอย่างสุขุม ไม่บังตัวละครหรือคันเบ็ด |
| `3` | `Core_SoftMoonGlow` | `01_core` (All) | Additive | `#829FFF` (Opacity 0.35) | เลเยอร์หมอกแสงฟุ้งรอบเสาหลัก สเกล 1.15x สร้างบรรยากาศไอหมอกยามค่ำ |
| `4` | `Sparks_SilverDroplets`| `05_sparks` (Frame 0, 1)| Additive | `#C8DCFF` | หยดน้ำสะท้อนแสงจันทร์ ลอยขึ้นจากผิวน้ำช้าๆ หมุนตัวแผ่วเบา |
| `5` | `Sparks_StardustMotes` | `05_sparks` (Frame 2, 3)| Additive | `#FFFFFF` & `#829FFF` | ละอองเกสรดาวและประกายเพชร ลอยวนระดับอกผู้เล่น |
| `6` | `Flares_DiamondGlints` | `04_flares` (All) | Additive | `#FFFFFF` | แสงแฟลร์ประกายเพชร 4 แฉก แวววาวรอบตัวและบนผิวน้ำตามจังหวะคลื่น |
| `7` | `Orbital_SilverHalo` *(Tier 3)* | `03_orbital` (Strip) | Additive | `#C8DCFF` & `#FFFFFF` | วงแหวนสายน้ำสีเงิน ทรงกระบอกเอียง 20 องศา โคจรอย่างเงียบสงบรอบเอว |

---

## 5. พารามิเตอร์ Particle ใน Roblox Studio

### Attachment Setup
- **ตำแหน่ง:** `HumanoidRootPart` -> `Attachment` ชื่อ `AuraVFX` (Position: `Vector3.new(0, -1.5, 0)`)
- **PointLight:** Color: `Color3.fromRGB(200, 220, 255)`, Brightness: 1.2, Range: 10

### สรุปค่า ParticleEmitter แต่ละตัว:
1. **`Core_MoonbeamColumn`:**
   - Texture: `01_core_moonbeam_mist_4x4`
   - Color: `ColorSequence.new(Color3.fromRGB(200, 220, 255), Color3.fromRGB(255, 255, 255))`
   - Rate: 18 | Lifetime: 1.4s | Speed: 1.4 | Size: 0.45 -> 0.15 | LightEmission: 1.0
2. **`Ground_ConcentricRipple`:**
   - Texture: `02_ground_lunar_concentric_ripple_4x4`
   - Orientation: `FacingCameraUp`
   - Rate: 1.4 | Lifetime: 1.6s | Speed: 0 | Size: 0.8 -> 2.6 | LightEmission: 0.8
3. **`Silver_Droplets`:**
   - Texture: `05_silver_droplets_atlas_2x2` (Frame 0/1)
   - Color: `ColorSequence.new(Color3.fromRGB(200, 220, 255))`
   - Rate: 10 | Lifetime: 1.3s | Speed: 0.8 | LightEmission: 0.9
4. **`Diamond_Glints`:**
   - Texture: `04_moonlit_diamond_glints_4x4`
   - Rate: 5 | Lifetime: 0.45s | Speed: 0.2 | Size: 0.28 | LightEmission: 1.0

---

## 6. ลำดับขั้น Tier Progression

- **Tier 1 (Base Ambient):** เปิดใช้งานเลเยอร์ `0, 2, 4` (วงคลื่นน้ำสีเงิน + เสาหมอกแสงจันทร์ + หยดน้ำสะท้อนแสง) สร้างบรรยากาศผืนน้ำใต้แสงจันทร์อันสงบ
- **Tier 2 (Enriched Nocturne):** เพิ่มเลเยอร์ `1, 5, 6` พร้อม PointLight สีเงินนวล ส่องสว่างรอบตัว พร้อมประกายเพชรระยิบระยับสะท้อนผิวน้ำ
- **Tier 3 (Signature Lunar Calm):** เปิดใช้งานเลเยอร์ `7` (วงแหวนสายน้ำสีเงินโคจรรอบเอว) ดุจนักตกปลาผู้ได้รับพรอันศักดิ์สิทธิ์จากดวงจันทร์เต็มดวง
