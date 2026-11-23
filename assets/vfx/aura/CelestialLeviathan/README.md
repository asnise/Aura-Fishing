# Celestial Leviathan - Aura VFX Specification

> **Rarity:** Mythic  
> **Chance:** 1 in 150,000 (Order: 15)  
> **Base Stats:** +1.40 Luck, +0.35 Fish Stability, +0.05 Mutation Chance  
> **Mutation Synergy:** +0.30 Golden Mutation Chance, +0.05 VoidTouched Mutation Chance  
> **Theme Colors:** Starlight White `#FFFFFF` (`rgb(255, 255, 255)`) and Astral Violet `#B48CFF` (`rgb(180, 140, 255)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** ความยิ่งใหญ่ระดับตำนานแห่งวาฬดาราศาสตร์บรรพกาลผู้แหวกว่ายข้ามมหาสมุทรแห่งดวงดาว ริ้วแสงออโรร่าสีขาวประกายม่วงพาสเทลลอยขึ้นสู่ฟากฟ้า พร้อมจิตวิญญาณวาฬคอสมิกว่ายวนอย่างเงียบสงบนิ่งรอบตัวผู้เล่น
- **คุมความเรียบง่าย (No Over-the-Top):**
  - **แม้จะเป็นออร่าระดับสูงสุด (Mythic 1 in 150,000) แต่ออร่าเน้น "ความงามสงบ สง่า และลึกซึ้ง" (Majestic Serenity) มากกว่าการระเบิดทำลายล้าง**
  - ริ้วแสงออโรร่าโปร่งแสงเนื้อเนียน ไม่บดบังทัศนวิสัยขณะเหวี่ยงเบ็ด
  - ลวดลายที่พื้นเป็นสระน้ำสะท้อนกลุ่มดาวจักรวาล (Constellation Lake Disk)
  - จิตวิญญาณวาฬดวงดาวเคลื่อนที่ด้วยท่วงท่าแหวกว่ายช้าๆ นุ่มนวล ชวนให้เกิดความอัศจรรย์ใจ

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_aurora_ribbons_4x4.png` | Flipbook 4x4 | ริ้วแสงออโรร่าดวงดาวและละอองไอน้ำจักรวาลลอยขึ้นในแนวตั้ง |
| `02_Ground` | `02_ground_constellation_pond_4x4.png` | Flipbook 4x4 | สระน้ำสะท้อนแผนที่กลุ่มดาวและระลอกคลื่นคอสมิกแผ่กว้างบนพื้น |
| `03_Orbital` | `03_orbital_leviathan_glide_strip.png` | Strip 1x1 | จิตวิญญาณวาฬดาราศาสตร์ว่ายวนรอบตัวผู้เล่นอย่างสง่างาม (Tier 3) |
| `04_Flares` | `04_celestial_supernova_flares_4x4.png` | Flipbook 4x4 | ประกายดาวกลุ่มดาวระยิบระยับแบบ 8 แฉกสีขาวบริสุทธิ์แกนม่วง |
| `05_Sparks` | `05_astral_stardust_atlas_2x2.png` | Static Atlas 2x2 | ฝุ่นดวงดาวคอสมิก, ครีบวาฬดวงดาว, ละอองแสงกาแล็กซี |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีลายกลุ่มดาวสะท้อนที่พื้น และริ้วแสงออโรร่าสีขาวม่วงลอยขึ้นรอบตัว
- **Tier 2 (Enriched Starlight):** แสงไฟสีม่วงอ่อนประกายขาวสว่างนวลตา พร้อมละอองดวงดาวระยิบระยับรอบตัว
- **Tier 3 (Signature Cosmic Sovereign):** จิตวิญญาณวาฬดาราศาสตร์แหวกว่ายรอบตัวผู้เล่นอย่างสง่างาม ดุจจ้าวแห่งมหาสมุทรดวงดาว
