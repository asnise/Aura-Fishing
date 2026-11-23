# Moonlit Ripple - Aura VFX Specification

> **Rarity:** Rare  
> **Chance:** 1 in 250 (Order: 6)  
> **Base Stats:** +0.20 Luck, +0.05 Auto Speed  
> **Mutation Synergy:** +0.04 Glowing Mutation Chance  
> **Theme Colors:** Moon Silver `#C8DCFF` (`rgb(200, 220, 255)`) and Midnight Indigo `#283CA0` (`rgb(40, 60, 160)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** ทะเลสาบยามค่ำคืนอันเงียบสงัดภายใต้แสงจันทร์เต็มดวง ผิวน้ำสะท้อนเงาจันทร์สีเงินบริสุทธิ์ มีระลอกคลื่นน้ำแผ่ออกอย่างแผ่วเบา
- **คุมความเรียบง่าย (No Over-the-Top):**
  - เน้นความสงบนิ่ง (Tranquility) เป็นหลัก ไม่มีแสงกระพริบฉูดฉาด
  - ระลอกคลื่นที่พื้นเป็นวงกลมคอนเซนตริก (Concentric Circles) ที่แผ่ขยายออกช้าๆ อย่างประณีต
  - ละอองแสงสีเงินลอยขึ้นช้าๆ คล้ายลำแสงจันทร์ส่องลอดเมฆกระทบผิวน้ำ
  - มีแสง PointLight สีเงินนวล ส่องสว่างเบาๆ รอบตัวผู้เล่น เหมาะสำหรับการตกปลาใต้แสงจันทร์

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

ภาพต้นทางชุดแรกเจนด้วย ImageGen แยกครบ 5 ชีต กดชื่อ PNG ในตารางเพื่อเปิดไฟล์ขาวบนดำสำหรับขั้น Luma to Alpha ดู [บันทึกการสร้างและชุดพรอมป์](../AURA_VFX_PIPELINE_GUIDE.md#3-ชุดภาพต้นทาง-2026-11-23)

ฉบับสำหรับปรับเลเยอร์ใน Particle Editor [project.json](project.json)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | [`01_core_moonbeam_mist_4x4.png`](01_core_moonbeam_mist_4x4.png) | Flipbook 4x4 | ละอองหมอกแสงจันทร์สีเงินลอยขึ้นในแนวตั้งอย่างนุ่มนวล |
| `02_Ground` | [`02_ground_lunar_concentric_ripple_4x4.png`](02_ground_lunar_concentric_ripple_4x4.png) | Flipbook 4x4 | วงคลื่นน้ำสีเงินสะท้อนแสงจันทร์แผ่ออกเป็นวงกลมหลายชั้นบนพื้น |
| `03_Orbital` | [`03_orbital_silver_halo_strip.png`](03_orbital_silver_halo_strip.png) | Strip 1x1 | สายน้ำวนสีเงินสว่างหมุนวนรอบตัวอย่างเงียบสงบ (Tier 3) |
| `04_Flares` | [`04_moonlit_diamond_glints_4x4.png`](04_moonlit_diamond_glints_4x4.png) | Flipbook 4x4 | ประกายแสงเพชรสะท้อนผิวน้ำใต้เงาจันทร์ สว่างนวลตา |
| `05_Sparks` | [`05_silver_droplets_atlas_2x2.png`](05_silver_droplets_atlas_2x2.png) | Static Atlas 2x2 | หยดน้ำสะท้อนแสงจันทร์, ละอองดวงดาวสีเงิน, เสี้ยวพระจันทร์จิ๋ว |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีวงคลื่นน้ำสีเงินแผ่ที่พื้น และมีหมอกแสงจันทร์ลอยแผ่วเบารอบขา
- **Tier 2 (Enriched Nocturne):** แสง PointLight สีเงินนวลสว่างขึ้น พร้อมประกายเพชรสะท้อนแสงจันทร์ระยิบระยับ
- **Tier 3 (Signature Moonlit Calm):** เพิ่มวงแหวนสายน้ำสีเงินลอยวนรอบตัว สร้างบรรยากาศทะเลสาบใต้แสงจันทร์อันสมบูรณ์แบบ
