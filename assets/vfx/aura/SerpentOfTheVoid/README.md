# Serpent of the Void - Aura VFX Specification

> **Rarity:** Legendary  
> **Chance:** 1 in 25,000 (Order: 13)  
> **Base Stats:** +0.75 Luck, +0.03 Mutation Chance  
> **Mutation Synergy:** +0.05 VoidTouched Mutation Chance  
> **Theme Colors:** Void Magenta `#FF78DC` (`rgb(255, 120, 220)`) and Planar Cyan `#5ADCFF` (`rgb(90, 220, 255)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** รอยแยกมิติวารีลี้ลับกลางผืนน้ำที่สะท้อนแสงสองเฉดสี (Bichromatic Prismatic Rift) ระหว่างสีชมพูมาเจนตากับสีฟ้าไซแอน สายน้ำมิติเลื้อยวนคล้ายพญางูแห่งห้วงมิติที่เคลื่อนตัวอย่างสงบนิ่ง
- **คุมความเรียบง่าย (No Over-the-Top):**
  - ไม่ใช่การระเบิดพลังจักรวาลที่ฉีกหน้าจอ หรือภาพสั่นไหวที่ทำลายบรรยากาศ
  - ใช้ความงามของการเล่นสองเฉดสี (Chromatic Harmony) สลับกันอย่างกลมกลืน
  - วงคลื่นที่พื้นเป็นระลอกคลื่นหักเหแสงมิติ (Planar Caustic Rift) ที่นุ่มนวล
  - การเลื้อยวนของริบบิ้นน้ำมีสเกลไม่ใหญ่เกินตัวละคร เพื่อให้เห็นการตกปลาชัดเจน

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_planar_mist_4x4.png` | Flipbook 4x4 | หมอกไอน้ำสองเฉดสีชมพูฟ้าลอยขึ้นเป็นเกลียวมิติ |
| `02_Ground` | `02_ground_void_caustic_4x4.png` | Flipbook 4x4 | รอยแยกผิวน้ำสองสีแผ่ขยายออกเป็นวงกลมบนพื้นอย่างประณีต |
| `03_Orbital` | `03_orbital_void_serpent_strip.png` | Strip 1x1 | สายน้ำวนคู่สองสีเลื้อยวนคล้ายงูมิติรอบเอว (Tier 3) |
| `04_Flares` | `04_chromatic_void_flares_4x4.png` | Flipbook 4x4 | ประกายเพชรแสงสองสีวาบขึ้นเบาๆ สลับชมพูและฟ้า |
| `05_Sparks` | `05_planar_shards_atlas_2x2.png` | Static Atlas 2x2 | ผลึกแก้วมิติ, เกล็ดงูสองสี, ละอองแสงมิติ |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีระลอกคลื่นสองเฉดสีที่พื้น และหมอกสีชมพูฟ้าลอยรอบตัว
- **Tier 2 (Enriched Dimensionality):** แสง PointLight สีไซแอนส่องสว่างขึ้น พร้อมประกายเพชรสองสีระยิบระยับ
- **Tier 3 (Signature Void Serpent):** ริบบิ้นสายน้ำสองเฉดสีเลื้อยวนรอบตัวอย่างสง่างาม ดุจเปิดประตูสู่น่านน้ำมิติใหม่
