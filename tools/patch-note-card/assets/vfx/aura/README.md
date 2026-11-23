# Aura Fishing - Aura VFX Catalog & Design Specification

ยินดีต้อนรับสู่แคตตาล็อกระบบ Aura VFX ของเกม **Aura Fishing** (Roblox Fantasy Fishing RPG)
เอกสารชุดนี้จัดทำขึ้นสำหรับส่งต่องานให้ **AI Agent** นำไปสร้างภาพ Sprite Sheet (Flipbook) และประกอบ VFX เข้าตัวเกมจริง

เปิด [พรีวิวออร่าทั้ง 15 แบบ](preview.html) เพื่อเทียบจังหวะการแผ่และริ้วโคจรก่อนเจนชีต ดู [ทิศทางภาพ](AURA_VFX_PIPELINE_GUIDE.md#4-ทิศทางภาพก่อนเจนรอบถัดไป) และพรอมป์ในโฟลเดอร์ของแต่ละออร่า

แก้ตำแหน่งเลเยอร์ ความเร็ว และการตัดชีตในเครื่องมือกลาง [Aura Particle Editor](../../../tools/particle-editor/README.md) โปรเจกต์ตัวอย่างอยู่ในโฟลเดอร์ Tidal Bloom, Moonlit Ripple และ Nebula Koi

---

## 1. ปรัชญาการออกแบบ: "Aura ประจำตัวนักตกปลา ที่คงธีม Cozy Fantasy"

หัวใจสำคัญสูงสุดของโปรเจกต์นี้:
**"ออร่าต้องสวย ละมุน มีเสน่ห์แบบ Fantasy Fishing ไม่เวอร์วังจนหลุดธีมเกม และไม่บดบังทัศนวิสัยการตกปลา"**

### กฎเหล็กด้านสุนทรียภาพ (Aesthetic Rules)
1. **ไม่ใช่เกมต่อสู้ (No Anime Battle / No DBZ Ki Explosions):**
   - แกนหลักหนึ่งแกนยึดที่กลางเท้า เล่น Flipbook ต่อเนื่องที่ขนาดคงที่และเฟดตามจังหวะ
   - ให้เน้นองค์ประกอบสายธรรมชาติ น้ำ เวทมนตร์ลอยละล่อง: หยดน้ำค้าง, ละอองหมอก, ฟองอากาศ, คลื่นระลอกน้ำ (Water Ripples), แสงสะท้อนผิวน้ำ (Caustics), แสงหิ่งห้อยแพลงก์ตอนเรืองแสง (Bioluminescence), กลีบดอกไม้ลอยน้ำ, ละอองฝุ่นดาว (Stardust)
2. **ความโปร่งใสและทัศนวิสัย (Visibility & Softness):**
   - ระลอกหรือ Caustic แผ่ราบจากกลางเท้า อนุภาคตามแรงแผ่ออกด้านข้างก่อนจาง
   - ขอบของอนุภาคต้องมีความฟุ้งและเฟดออกอย่างเป็นธรรมชาติ
3. **การไล่ระดับตามระดับความหายาก (Rarity Tiers):**
   - สายหลักและริ้วตามที่เอียงต่างมุม โคจรรอบเอวใน Tier 3 วิญญาณสัตว์อยู่บนสายหลัก
   - **Rare / Epic:** มีคลื่นระลอกน้ำใต้เท้าชัดเจน มีประกายแสงนุ่มนวล มีจังหวะการเคลื่อนไหวแบบสายน้ำ
   - **Legendary / Mythic:** สง่างาม อลังการด้วยจิตวิญญาณแห่งสายน้ำ (มังกร/พญานาค/คราเคน/สัตว์ในตำนาน) แต่เป็นการว่ายวนแบบนุ่มนวล ลอยละล่อง ไม่ใช่การระเบิดหน้าจอ

---

## 2. โครงสร้างโฟลเดอร์สำหรับ AI Agent

แต่ละออร่าจะมีโฟลเดอร์เฉพาะตัวตาม ID ใน `src/shared/Config/Auras.luau`:

```text
assets/vfx/aura/
├── README.md                                 <-- เอกสารรวมฉบับนี้
├── AURA_VFX_PIPELINE_GUIDE.md               <-- คู่มือสำหรับ AI Agent สร้างภาพ
├── sample/                                   <-- โฟลเดอร์ตัวอย่างเดิม
├── SparklingDew/                             <-- Common (1 in 10)
├── TidalBloom/                               <-- Common (1 in 15)
├── KelpWhisper/                              <-- Uncommon (1 in 40)
├── CoralHeart/                               <-- Uncommon (1 in 60)
├── NeonWave/                                 <-- Rare (1 in 100)
├── MoonlitRipple/                            <-- Rare (1 in 250)
├── StormCurrent/                             <-- Rare (1 in 400)
├── SolarFlare/                               <-- Epic (1 in 750)
├── FrostPearl/                               <-- Epic (1 in 1,500)
├── NebulaKoi/                                <-- Epic (1 in 3,000)
├── AbyssalShadow/                            <-- Legendary (1 in 5,000)
├── LotusNaga/                                <-- Legendary (1 in 12,000)
├── SerpentOfTheVoid/                         <-- Legendary (1 in 25,000)
├── DragonEmperor/                            <-- Mythic (1 in 50,000)
└── CelestialLeviathan/                       <-- Mythic (1 in 150,000)
```

ในแต่ละโฟลเดอร์ของออร่า จะประกอบด้วยไฟล์:
1. `README.md`: สเปกและคอนเซ็ปต์ของออร่านั้นๆ อย่างละเอียด (สี, สถิติ, ระดับ Tier)
2. `prompt_layer_<aura_id>_vfx.md`: พร้อมใช้ Copy-Paste สำหรับส่งให้ Image Gen AI (Midjourney, ComfyUI, DALL-E) แยก 5 เลเยอร์
3. `pipeline_spec_<aura_id>_vfx.md`: รายละเอียดเทคนิค พารามิเตอร์ของ Roblox ParticleEmitter และค่าคอนฟิกสำหรับ Agent ประกอบใน Engine

---

## 3. ตารางสรุป 15 ออร่าทั้งหมดในเกม (Aura Master Table)

| ID | ชื่อที่แสดง | ความหายาก | โอกาส (1 in N) | โทนสีหลัก (RGB / Palette) | องค์ประกอบภาพ (Visual Theme) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `SparklingDew` | Sparkling Dew | Common | 10 | Cyan Pastel (180, 240, 255) | หยดน้ำค้างประกายเช้าตรู่ ลอยขึ้นช้าๆ ละมุนตา |
| `TidalBloom` | Tidal Bloom | Common | 15 | Seafoam (150, 235, 200) + Sakura (255, 190, 220) | กลีบดอกไม้น้ำลอยบนระลอกคลื่นน้ำตื้น |
| `KelpWhisper` | Kelp Whisper | Uncommon | 40 | Kelp Green (110, 210, 120) + Forest (40, 140, 80) | ละอองสปอร์พืชน้ำใต้ผืนน้ำ และฟองออกซิเจนลอยวน |
| `CoralHeart` | Coral Heart | Uncommon | 60 | Coral Pink (255, 150, 160) + Ruby (255, 100, 130) | ชีพจรรังปะการังเรืองแสง ละอองแสงอบอุ่นเต้นเป็นจังหวะ |
| `NeonWave` | Neon Wave | Rare | 100 | Electric Cyan (0, 200, 255) + Azure (0, 90, 255) | คลื่นทะเลเรืองแสงยามค่ำคืน (Bioluminescent Tide) |
| `MoonlitRipple` | Moonlit Ripple | Rare | 250 | Moon Silver (200, 220, 255) + Deep Navy (40, 60, 160) | วงระลอกน้ำใต้แสงจันทร์เต็มดวง สะท้อนผิวน้ำนิ่งสงบ |
| `StormCurrent` | Storm Current | Rare | 400 | Raindrop Blue (150, 220, 255) + Spark Gold (255, 220, 90) | สายน้ำวนก่อนฝนตก ละอองน้ำหมุนวนพร้อมประกายไฟอ่อนๆ |
| `SolarFlare` | Solar Flare | Epic | 750 | Golden Sun (255, 220, 80) + Warm Amber (255, 80, 0) | แสงอาทิตย์อัสดงส่องผิวน้ำ ละอองไอน้ำสะท้อนประกายทอง |
| `FrostPearl` | Frost Pearl | Epic | 1,500 | Pearl White (235, 250, 255) + Ice Cyan (160, 210, 255) | มุกน้ำแข็งประกายสีรุ้ง เกล็ดน้ำแข็งหกเหลี่ยมหมุนวนแผ่วเบา |
| `NebulaKoi` | Nebula Koi | Epic | 3,000 | Astral Violet (200, 170, 255) + Lotus Pink (255, 160, 210) | บ่อปลาคาร์ปสะท้อนดวงดาว วิญญาณปลาคาร์ปว่ายวนในละอองดาว |
| `AbyssalShadow` | Abyssal Shadow | Legendary | 5,000 | Abyssal Violet (110, 40, 170) + Deep Trench (10, 0, 20) | ความลึกลับแห่งร่องสมุทรลึก ละอองหมอกมืดพร้อมจุดเรืองแสงลึก |
| `LotusNaga` | Lotus Naga | Legendary | 12,000 | River Jade (60, 200, 130) + Lotus Pink (255, 150, 200) | วารีพญานาคพิทักษ์สายน้ำ ดอกบัวทิพย์ลอยวนและละอองบารมี |
| `SerpentOfTheVoid` | Serpent of the Void | Legendary | 25,000 | Void Magenta (255, 120, 220) + Planar Cyan (90, 220, 255) | รอยแยกมิติวารี แสงสองเฉดสะท้อนเกล็ดพญางูแห่งห้วงมิติ |
| `DragonEmperor` | Dragon Emperor | Mythic | 50,000 | Sovereign Gold (255, 215, 0) + Dragon Amber (255, 140, 0) | บารมีมังกรทองแห่งลุ่มน้ำ ละอองทองคำจักรพรรดิและควันมงคล |
| `CelestialLeviathan` | Celestial Leviathan | Mythic | 150,000 | Starlight White (255, 255, 255) + Astral Violet (180, 140, 255) | วาฬดาราศาสตร์ลอยข้ามฟากฟ้า ละอองกลุ่มดาวประกายแสงจักรวาล |

---

## 4. โครงสร้าง 5 เลเยอร์มาตรฐานสำหรับแต่ละออร่า (5-Layer System)

ทุกออร่าถูกแบ่งสัดส่วนเป็น 5 เลเยอร์ที่ประสานงานกันอย่างลงตัว:

1. **`01_core_*_4x4.png` (Core Rising Motes / Plumes):**
   - อนุภาคหลักที่ลอยขึ้นจากรอบลำตัวผู้เล่นในแนวตั้ง ช้า ละมุน ไม่บังสายตา
2. **`02_ground_*_4x4.png` (Ground Ripple / Caustic Disk):**
   - วงคลื่นน้ำ ระลอกแสง หรือลวดลายผิวน้ำที่วางแบนราบกับพื้นรอบเท้าผู้เล่น
3. **`03_orbital_*` (Orbital Stream / Spirit Silhouette):**
   - ริบบิ้นสายน้ำ หรือดวงจิตวิญญาณขนาดเล็กที่โคจรรอบเอวผู้เล่นอย่างนุ่มนวล (สำหรับ Tier 3)
4. **`04_star_flares_*_4x4.png` (Glints & Caustic Shimmers):**
   - ประกายแสงระยิบระยับ แวววาวเหมือนแสงอาทิตย์หรือแสงจันทร์กระทบผิวน้ำ
5. **`05_sparks_atlas_*_2x2.png` (Ambient Micro Droplets & Spores):**
   - ฟองน้ำ, ละอองน้ำค้าง, กลีบดอกไม้, หรือสะเก็ดเกล็ดปลาขนาดจิ๋วที่ล่องลอยอิสระ
