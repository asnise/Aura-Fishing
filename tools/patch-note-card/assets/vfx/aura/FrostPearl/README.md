# Frost Pearl - Aura VFX Specification

> **Rarity:** Epic  
> **Chance:** 1 in 1,500 (Order: 9)  
> **Base Stats:** +0.40 Luck, +0.10 Resilience  
> **Mutation Synergy:** +0.06 Glowing Mutation Chance  
> **Theme Colors:** Iridescent Pearl White `#EBFAFF` (`rgb(235, 250, 255)`) and Glacial Ice Cyan `#A0D2FF` (`rgb(160, 210, 255)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** ความงดงามของไข่มุกน้ำแข็งบรรพกาลจากทะเลสาบเยือกแข็งบนยอดเขา ละอองไอเย็นสีขาวมุกประกายสีรุ้งอ่อนๆ พร้อมผลึกหิมะหกเหลี่ยมขนาดจิ๋วที่หมุนวนอย่างสงบนิ่ง
- **คุมความเรียบง่าย (No Over-the-Top):**
  - ไม่ใช่พายุหิมะโหมกระหน่ำ (No Blizzard) หรือการระเบิดหนามน้ำแข็งแหลมคม
  - ผลึกน้ำแข็งมีรูปทรงหกเหลี่ยมประณีต ละมุนตา
  - วงคลื่นที่พื้นเป็นลายเกล็ดน้ำแข็งบางใส (Frost Lattice Ring) แผ่ออกแผ่วเบา
  - การเคลื่อนไหวช้า นิ่ง สงบ ช่วยสร้างสมาธิในการตกปลาท่ามกลางความเย็นสดชื่น

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_glacial_vapor_4x4.png` | Flipbook 4x4 | หมอกไอเย็นบริสุทธิ์สีขาวมุกลอยขึ้นอย่างสงบในแนวตั้ง |
| `02_Ground` | `02_ground_frost_lattice_4x4.png` | Flipbook 4x4 | ลายผลึกน้ำแข็งโปร่งแสงแผ่ตัวออกเป็นวงกลมบนพื้นรอบเท้า |
| `03_Orbital` | `03_orbital_pearl_mist_strip.png` | Strip 1x1 | สายละอองไอเย็นและไข่มุกน้ำแข็งโคจรรอบเอวช้าๆ (Tier 3) |
| `04_Flares` | `04_pearl_prismatic_glints_4x4.png` | Flipbook 4x4 | ประกายแสงสีรุ้งอ่อนๆ สะท้อนผิวมุกและเกล็ดน้ำแข็ง |
| `05_Sparks` | `05_frost_crystals_atlas_2x2.png` | Static Atlas 2x2 | ผลึกหิมะหกเหลี่ยมจิ๋ว, เม็ดมุกเรืองแสง, ละอองไอเย็น |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีลายผลึกน้ำแข็งบางๆ ที่พื้น และไอเย็นสีขาวมุกลอยขึ้นรอบขา
- **Tier 2 (Enriched Glacial Luster):** มีประกายแสงสีรุ้งของไข่มุกระยิบระยับ พร้อมผลึกน้ำแข็งจิ๋วหมุนวนรอบตัว
- **Tier 3 (Signature Frost Sovereignty):** สายหมอกไอเย็นและไข่มุกเรืองแสงโคจรรอบตัวอย่างประณีต ดุจนักตกปลาแห่งธารน้ำแข็ง
