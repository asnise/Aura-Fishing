# VFX Production Pipeline Specification: Nebula Koi Aura

> **Aura Identity:** Nebula Koi (Epic - 1 in 3,000)  
> **Core Theme:** Starlight tranquil koi pond reflecting cosmic nebulas, floating astral stardust ribbons, and celestial spirit koi fish swimming in serene orbit  
> **Target Platforms:** Roblox Studio (ParticleEmitter / Attachments / PointLight) & Universal Real-Time Engine Shaders  

---

## 0. Project Configuration

```yaml
AURA_ID: "NebulaKoi"
DISPLAY_NAME: "Nebula Koi"
RARITY: "Epic"
CHANCE: 3000
PRIMARY_COLOR: "#C8AAFF"       # Astral Lavender (RGB: 200, 170, 255)
ACCENT_COLOR: "#FFA0D2"        # Cosmic Lotus Pink (RGB: 255, 160, 210)
HIGHLIGHT_COLOR: "#FFFFFF"     # Starlight Core White (RGB: 255, 255, 255)
DEEP_SPACE_COLOR: "#3E2260"    # Deep Nebula Shadow (RGB: 62, 34, 96)
TARGET_FPS: 16                 # Fluid cosmic motion for swimming spirit koi
DEFAULT_ATLAS_SIZE: 1024
```

---

## 1. Input Asset Inventory (หน้าที่และการทำงานของแต่ละ Texture)

เอกสารนี้ระบุหน้าที่เฉพาะเจาะจงของ Texture แต่ละไฟล์ เพื่อให้ AI Agent และนักพัฒนาทราบว่าภาพใดนำไปประกอบเป็นเลเยอร์ใดและทำงานอย่างไร:

| ลำดับไฟล์ | ชื่อไฟล์ภาพ | รูปแบบ (Grid / Format) | Anchor Mode | หน้าที่และการทำงานในเกม (Role & Purpose) |
| :--- | :--- | :--- | :--- | :--- |
| `01` | `01_core_nebula_mist_4x4.png` | Flipbook 4x4 (16 frames) | `bottom_center` | **Astral Vapor Ribbons:** หมอกเนบิวลาจักรวาลสีม่วงลาเวนเดอร์ ลอยตัวพริ้วไหวขึ้นคล้ายริ้วผ้าแพรไหมแห่งดวงดาวรอบลำตัวผู้เล่น |
| `02` | `02_ground_starlight_pond_4x4.png` | Flipbook 4x4 (16 frames) | `center` | **Starlight Pond Caustic:** สระน้ำสะท้อนกลุ่มดาวและเกลียวเนบิวลาแผ่ออกจากเท้า หมุนวนช้าๆ บนผิวน้ำดั่งบ่อปลาคาร์ปสวรรค์ |
| `03` | `03_orbital_koi_swim_strip.png` | Tileable Strip 1x1 (1024x256) | `none` | **Celestial Koi Spirit Stream:** จิตวิญญาณปลาคาร์ปดวงดาวโปร่งแสง ว่ายวนอย่างสง่างามในวงโคจรรอบเอวผู้เล่นใน Tier 3 ทิ้งรอยหางแสงดวงดาว |
| `04` | `04_cosmic_star_flares_4x4.png` | Flipbook 4x4 (16 frames) | `center` | **Constellation Star Flares:** ประกายดาวฤกษ์ 4 แฉก แวววาวระยิบระยับรอบตัวและสะท้อนบนเกล็ดปลาคาร์ป |
| `05` | `05_stardust_scales_atlas_2x2.png` | Static Atlas 2x2 (4 Sprites) | `center` | **Astral Scales & Stardust Atlas:** แยกเป็น 4 วัตถุย่อยตามช่อง Atlas (ดูรายละเอียดด้านล่าง) |

### รายละเอียดการแบ่งช่องใน Atlas `05_stardust_scales_atlas_2x2.png`:
- **Frame 0 (Top-Left - Ethereal Koi Scale):** ลวดลายเกล็ดปลาคาร์ปดวงดาวเรืองแสง ลอยขึ้นและหมุนเอื่อยๆ ย้อมสีม่วงลาเวนเดอร์ `#C8AAFF`
- **Frame 1 (Top-Right - 4-Point Starlight Mote):** ละอองดาวดวงเล็ก ลอยตัวขึ้นตรงๆ พร้อมกะพริบแสงสีขาวแกนชมพู `#FFA0D2`
- **Frame 2 (Bottom-Left - Celestial Lotus Petal):** กลีบดอกบัวสวรรค์สีชมพูคอสซิก ลอยละล่องแกว่งไกวตามสายน้ำเนบิวลา
- **Frame 3 (Bottom-Right - Cosmic Water Droplet):** หยดน้ำค้างดวงดาวทรงโค้ง ลอยวนรอบระดับเอวผู้เล่น

---

## 2. Phase 1: Automated Image Cleaning & Repacking

```yaml
BLACK_CUT: 0.05               # ตัดพื้นหลังสีดำสนิทเพื่อไม่ให้มีกรอบสี่เหลี่ยม
WHITE_CUT: 0.95               # ปรับ White point ให้ประกายดาวสว่างชัดเจน
BORDER_CROP: 0.03             # ตัดขอบในแต่ละช่อง 3%
GAMMA: 1.05                   # คงความนุ่มนวลของริ้วหมอกเนบิวลา
ANCHOR_MODE_CORE: "bottom_center" # ยึดโคนหมอกน้ำให้อยู่ระดับเท้า
ANCHOR_MODE_GROUND: "center"  # ให้สระน้ำดวงดาวหมุนวนสมมาตร
```

---

## 3. Phase 2: Color Gradient & Shader Mapping

- **Outer Color (ขอบนอก):** `#3E2260` (Deep Astral Nebula - นุ่มนวล กลมกลืนกับความมืด)
- **Mid Color (เนื้ออนุภาค):** `#C8AAFF` (Astral Lavender - สีหลักของ Nebula Koi)
- **Core Color (แกนสว่าง):** `#FFFFFF` (Pure Starlight - จุดประกายแสงดาวสูงสุด)
- **Accent Overlay:** `#FFA0D2` (Cosmic Lotus Pink - ใช้กับวิญญาณปลาคาร์ปและกลีบดอกบัว)
- **PointLight Tint:** `#D2AAFF` (Astral Soft Violet, Brightness: 1.5, Range: 11 Studs)

---

## 4. Phase 3: Layer Architecture & Render Order (สถาปัตยกรรมและบทบาททุกเลเยอร์)

| Sort Order | ชื่อเลเยอร์ (Layer Name) | ไฟล์ Texture / Frame | Blend Mode | รหัสสี (Color Palette) | พฤติกรรมการเคลื่อนไหวและตำแหน่ง (Transform & Behavior) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0` | `Ground_StarlightPond`| `02_ground` (All) | Additive / Screen | `#C8AAFF` | วางแบนราบกับพื้น (`FacingCameraUp`), ขนาดสเกล 2.8 Studs, หมุนช้าๆ 15 องศา/วิ |
| `1` | `Ground_LotusCaustic` | `02_ground` (All) | Additive | `#FFA0D2` (Opacity 0.4) | วงสระน้ำซ้อนทับเลเยอร์ 0 เพิ่มมิติระลอกคลื่นสีชมพูดอกบัว |
| `2` | `Core_AstralVapor` | `01_core` (All) | Additive / Screen | `#C8AAFF` -> `#FFFFFF` | ริ้วหมอกเนบิวลาแนวตั้ง ลอยขึ้นเป็นเกลียวแพรไหมช้าๆ สบายตา |
| `3` | `Core_NebulaGlow` | `01_core` (All) | Additive | `#FFA0D2` (Opacity 0.35) | เลเยอร์หมอกแสงฟุ้งรอบเสาหลัก สเกล 1.15x สร้างบรรยากาศกาแล็กซี |
| `4` | `Sparks_KoiScales` | `05_sparks` (Frame 0) | Additive | `#C8AAFF` | เกล็ดปลาคาร์ปเรืองแสง ลอยขึ้นพร้อมหมุนตัวเอื่อยๆ (RotSpeed: ±60) |
| `5` | `Sparks_LotusStardust`| `05_sparks` (Frame 1, 2)| Additive | `#FFA0D2` & `#FFFFFF` | ฝุ่นดาวและกลีบดอกบัวสวรรค์ ลอยละล่องรอบตัวละครตามกระแสลมอ่อน |
| `6` | `Flares_Constellation` | `04_flares` (All) | Additive | `#FFFFFF` | ประกายดาวฤกษ์ 4 แฉก สว่างวาบระยิบระยับรอบตัวและบนผิวน้ำ |
| `7` | `Orbital_KoiSpirit` *(Tier 3)* | `03_orbital` (Strip) | Additive | `#FFA0D2` & `#C8AAFF` | วิญญาณปลาคาร์ปดวงดาว ว่ายวนเป็นวงกลมเอียง 15 องศารอบเอวผู้เล่นอย่างอ่อนช้อย |

---

## 5. พารามิเตอร์ Particle ใน Roblox Studio

### Attachment Setup
- **ตำแหน่ง:** `HumanoidRootPart` -> `Attachment` ชื่อ `AuraVFX` (Position: `Vector3.new(0, -1.5, 0)`)
- **PointLight:** Color: `Color3.fromRGB(210, 170, 255)`, Brightness: 1.5, Range: 11

### สรุปค่า ParticleEmitter แต่ละตัว:
1. **`Core_AstralVapor`:**
   - Texture: `01_core_nebula_mist_4x4`
   - Color: `ColorSequence.new(Color3.fromRGB(200, 170, 255), Color3.fromRGB(255, 160, 210))`
   - Rate: 30 | Lifetime: 1.5s | Speed: 1.8 | Size: 0.6 -> 0.15 | LightEmission: 1.0
2. **`Ground_StarlightPond`:**
   - Texture: `02_ground_starlight_pond_4x4`
   - Orientation: `FacingCameraUp`
   - Rate: 1.8 | Lifetime: 1.6s | Speed: 0 | Size: 1.0 -> 2.8 | LightEmission: 0.85
3. **`Koi_Scales_Stardust`:**
   - Texture: `05_stardust_scales_atlas_2x2` (Frame 0/1/2)
   - Color: `ColorSequence.new(Color3.fromRGB(200, 170, 255), Color3.fromRGB(255, 160, 210))`
   - Rate: 16 | Lifetime: 1.5s | Speed: 1.2 | RotSpeed: -60~60 | LightEmission: 1.0
4. **`Constellation_Flares`:**
   - Texture: `04_cosmic_star_flares_4x4`
   - Rate: 6 | Lifetime: 0.45s | Speed: 0.3 | Size: 0.35 | LightEmission: 1.0

---

## 6. ลำดับขั้น Tier Progression

- **Tier 1 (Base Ambient):** เปิดใช้งานเลเยอร์ `0, 2, 4` (สระน้ำดวงดาว + หมอกเนบิวลา + เกล็ดปลาคาร์ป) สร้างบรรยากาศบ่อน้ำดวงดาวอันเงียบสงบ
- **Tier 2 (Enriched Starlight):** เพิ่มเลเยอร์ `1, 5, 6` พร้อม PointLight สีม่วงสว่างนวลตา มีฝุ่นดาวและประกายดาวกะพริบระยิบระยับรอบตัว
- **Tier 3 (Signature Cosmic Koi):** เปิดใช้งานเลเยอร์ `7` (วิญญาณปลาคาร์ปดวงดาวว่ายวนรอบเอวอย่างสง่างาม) ดั่งมีเทพมัจฉาแห่งสายน้ำดวงดาวคอยคุ้มครองนักตกปลา
