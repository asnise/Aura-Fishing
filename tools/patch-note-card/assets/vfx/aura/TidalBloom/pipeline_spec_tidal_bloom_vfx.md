# VFX Production Pipeline Specification: Tidal Bloom Aura

> **Aura Identity:** Tidal Bloom (Common - 1 in 15)  
> **Core Theme:** Shallow lagoon springtime tide carrying floating blossom petals and soft seafoam mist  
> **Target Platforms:** Roblox Studio (ParticleEmitter / Attachments) & Universal Real-Time Engine Shaders  

---

## 0. Project Configuration

```yaml
AURA_ID: "TidalBloom"
DISPLAY_NAME: "Tidal Bloom"
RARITY: "Common"
CHANCE: 15
PRIMARY_COLOR: "#96EBC8"       # Seafoam Mint (RGB: 150, 235, 200)
ACCENT_COLOR: "#FFBEDC"        # Pastel Sakura Pink (RGB: 255, 190, 220)
HIGHLIGHT_COLOR: "#E8FFF6"     # Pure Shallow Water Highlight (RGB: 232, 255, 246)
TARGET_FPS: 14                 # Gentle fluid framerate for tranquil spring motion
DEFAULT_ATLAS_SIZE: 1024
```

---

## 1. Input Asset Inventory (หน้าที่และการทำงานของแต่ละ Texture)

เอกสารนี้ระบุหน้าที่เฉพาะเจาะจงของ Texture แต่ละไฟล์ เพื่อให้ AI Agent และนักพัฒนาทราบว่าภาพใดนำไปประกอบเป็นเลเยอร์ใดและทำงานอย่างไร:

| ลำดับไฟล์ | ชื่อไฟล์ภาพ | รูปแบบ (Grid / Format) | Anchor Mode | หน้าที่และการทำงานในเกม (Role & Purpose) |
| :--- | :--- | :--- | :--- | :--- |
| `01` | `01_core_tidal_mist_4x4.png` | Flipbook 4x4 (16 frames) | `bottom_center` | **Core Vapor Column:** ควันไอน้ำและหมอกน้ำตื้น ลอยตัวขึ้นจากข้อเท้าสู่ช่วงอกอย่างแผ่วเบา เป็นแกนกลางโปร่งแสงของออร่า |
| `02` | `02_ground_blossom_ripple_4x4.png` | Flipbook 4x4 (16 frames) | `center` | **Ground Water Wavelet:** วงคลื่นน้ำตื้นและระลอกน้ำซัดชายฝั่ง ขยายตัวแผ่ออกจากจุดศูนย์กลางรอบเท้าผู้เล่นพร้อมเงากลีบดอกไม้ลอยน้ำ |
| `03` | `03_orbital_petal_drift_strip.png` | Tileable Strip 1x1 (1024x256) | `none` | **Orbital Water Ribbon:** ริบบิ้นกระแสน้ำวนแนวนอน หมุนวนรอบเอว/สะโพกผู้เล่นใน Tier 3 พาละอองกลีบดอกไม้พริ้วไหวรอบตัว |
| `04` | `04_floral_glints_4x4.png` | Flipbook 4x4 (16 frames) | `center` | **Floral Specular Glints:** ประกายแสงระยิบระยับเหมือนหยาดน้ำสะท้อนแสงแดดยามเช้า กระจายรอบลำตัวเป็นระยะ |
| `05` | `05_petals_foam_atlas_2x2.png` | Static Atlas 2x2 (4 Sprites) | `center` | **Ambient Particles Atlas:** แยกเป็น 4 วัตถุย่อยตามช่อง Atlas (ดูรายละเอียดด้านล่าง) |

### รายละเอียดการแบ่งช่องใน Atlas `05_petals_foam_atlas_2x2.png`:
- **Frame 0 (Top-Left - Single Blossom Petal):** กลีบดอกไม้น้ำเดี่ยว ปลิวลอยขึ้นและส่ายซ้าย-ขวาตามกระแสลม (Gentle Sway) ย้อมสีชมพูพาสเทล `#FFBEDC`
- **Frame 1 (Top-Right - Paired Lily Petals):** กลีบดอกบัวคู่ ลอยตัวช้าๆ หมุนเอื่อยๆ รอบตัวละคร
- **Frame 2 (Bottom-Left - Seafoam Bubble Cluster):** ฟองคลื่นน้ำสีเขียวซีโฟม ลอยขึ้นตรงๆ แล้วแตกสลายอย่างนุ่มนวล ย้อมสี `#96EBC8`
- **Frame 3 (Bottom-Right - Luminous Pollen Mote):** ละอองเกสรเรืองแสงขนาดจิ๋ว ลอยล่องอิสระรอบตัวผู้เล่นเพื่อสร้างมิติความลึก

---

## 2. Phase 1: Automated Image Cleaning & Repacking

```yaml
BLACK_CUT: 0.05               # ตัดพื้นหลังสีดำบริสุทธิ์เพื่อป้องกันขอบสี่เหลี่ยม
WHITE_CUT: 0.95               # ปรับ White point ให้แกนเรืองแสงคมชัด
BORDER_CROP: 0.03             # ตัดขอบในแต่ละช่อง 3% กันเส้นกรอบตาราง
GAMMA: 1.05                   # รักษาน้ำหนักเฉดเทาให้อนุภาคนุ่มนวล ไม่แข็งกระด้าง
ANCHOR_MODE_CORE: "bottom_center" # ยึดฐานหมอกน้ำให้อยู่ติดพื้น ไม่กระโดดลอย
ANCHOR_MODE_GROUND: "center"  # ระลอกคลื่นน้ำแผ่ออกจากจุดศูนย์กลางรอบเท้า
```

---

## 3. Phase 2: Color Gradient & Shader Mapping

Monochrome Luma Matte จะถูกนำไปย้อมสีในเอนจินผ่าน 3 Color Stops:
- **Outer Color (ขอบนอก):** `#4A8B71` (Deep Lagoon Teal - อ่อนนุ่ม กลมกลืนกับผิวน้ำ)
- **Mid Color (เนื้ออนุภาค):** `#96EBC8` (Seafoam Mint - สีเอกลักษณ์ของ Tidal Bloom)
- **Core Color (แกนสว่าง):** `#E8FFF6` (Pale Water Highlight - สว่างประกายผิวน้ำกระทบแดด)
- **Accent Overlay:** `#FFBEDC` (Pastel Blossom Pink - ใช้กับกลีบดอกไม้และประกายแสง)

---

## 4. Phase 3: Layer Architecture & Render Order (สถาปัตยกรรมและบทบาททุกเลเยอร์)

| Sort Order | ชื่อเลเยอร์ (Layer Name) | ไฟล์ Texture / Frame | Blend Mode | รหัสสี (Color Palette) | พฤติกรรมการเคลื่อนไหวและตำแหน่ง (Transform & Behavior) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0` | `Ground_CausticWave` | `02_ground` (All) | Additive / Screen | `#96EBC8` | วางแบนราบกับพื้น (`FacingCameraUp`), ขนาดสเกล 2.4 Studs, แผ่ขยายออกช้าๆ |
| `1` | `Ground_PetalRipples` | `02_ground` (All) | Additive | `#FFBEDC` | วางแบนราบกับพื้น ซ้อนทับเลเยอร์ 0 ด้วยสเกลเล็กกว่าเล็กน้อย (`0.9x`) เพิ่มมิติกลีบดอกไม้ |
| `2` | `Core_SeafoamMist` | `01_core` (All) | Additive / Screen | `#96EBC8` -> `#E8FFF6` | บิลบอร์ดแนวตั้ง จุดหมุนชิดพื้น (`bottom_center`), ลอยขึ้นช้าๆ ไม่บังใบหน้าผู้เล่น |
| `3` | `Core_MistAmbient` | `01_core` (All) | Additive | `#96EBC8` (Opacity 0.3) | เลเยอร์หมอกฟุ้งเบลอ สเกลใหญ่กว่าแกนหลัก 1.15 เท่า สร้างบรรยากาศไอความเย็นผิวน้ำ |
| `4` | `Sparks_SeafoamBubbles`| `05_sparks` (Frame 2) | Additive | `#96EBC8` | ฟองคลื่นฟองอากาศ ลอยขึ้นตรงๆ ด้วยความเร็วคงที่ 0.8 Studs/s แล้วจางหาย |
| `5` | `Sparks_SwayingPetals` | `05_sparks` (Frame 0, 1) | AlphaBlend / Additive | `#FFBEDC` | กลีบดอกไม้ชมพู ลอยขึ้นพร้อมแกว่งตัวซ้าย-ขวา (Sinusoidal Sway `±0.2 Studs`) หมุนช้าๆ |
| `6` | `Flares_FloralTwinkle` | `04_flares` (All) | Additive | `#FFFFFF` -> `#FFBEDC` | ประกายน้ำระยิบระยับ เกิดและดับอย่างรวดเร็ว (0.35s) สุ่มตำแหน่งรอบลำตัว |
| `7` | `Orbital_PetalStream` *(Tier 3)* | `03_orbital` (Strip) | Additive | `#96EBC8` & `#FFBEDC` | สายน้ำวนล้อมรอบเอว เอียง 15 องศา หมุนวนรอบตัวผู้เล่นอย่างต่อเนื่อง |

---

## 5. พารามิเตอร์ Particle ใน Roblox Studio

### Attachment Setup
- **ตำแหน่ง:** `HumanoidRootPart` -> `Attachment` ชื่อ `AuraVFX` (Position: `Vector3.new(0, -1.5, 0)`)

### สรุปค่า ParticleEmitter แต่ละตัว:
1. **`Core_SeafoamMist`:**
   - Texture: `01_core_tidal_mist_4x4`
   - Color: `ColorSequence.new(Color3.fromRGB(150, 235, 200), Color3.fromRGB(232, 255, 246))`
   - Rate: 8 | Lifetime: 1.3s | Speed: 1.0 | Size: 0.35 -> 0.1 | LightEmission: 0.7
2. **`Ground_Wavelet`:**
   - Texture: `02_ground_blossom_ripple_4x4`
   - Orientation: `FacingCameraUp`
   - Rate: 1.5 | Lifetime: 1.6s | Speed: 0 | Size: 0.8 -> 2.4 | LightEmission: 0.6
3. **`Floating_Petals`:**
   - Texture: `05_petals_foam_atlas_2x2` (Frame 0/1)
   - Color: `ColorSequence.new(Color3.fromRGB(255, 190, 220))`
   - Rate: 6 | Lifetime: 1.8s | Speed: 0.6 | RotSpeed: -45~45 | LightEmission: 0.8
4. **`Floral_Glints`:**
   - Texture: `04_floral_glints_4x4`
   - Rate: 4 | Lifetime: 0.4s | Speed: 0.2 | Size: 0.25 | LightEmission: 1.0

---

## 6. ลำดับขั้น Tier Progression

- **Tier 1 (Base Ambient):** เปิดใช้งานเลเยอร์ `0, 2, 4` (ระลอกคลื่นพื้น + หมอกซีโฟม + ฟองคลื่น) มอบความรู้สึกสดชื่นยามเช้าอย่างสงบ
- **Tier 2 (Enriched Blossom):** เพิ่มเลเยอร์ `1, 5, 6` (ระลอกน้ำซ้อนกลีบ + กลีบดอกไม้พริ้วไหว + ประกายแสงวิบวับ) ให้มิติสีชมพูพาสเทลตัดกับเขียวมิ้นต์อย่างลงตัว
- **Tier 3 (Signature Tidal Stream):** เปิดใช้งานเลเยอร์ `7` (สายน้ำวนกลีบดอกไม้ลอยรอบเอว) ตัวละครจะเสมือนมีกระแสน้ำฤดูใบไม้ผลิโอบอุ้มขณะยืนตกปลา
