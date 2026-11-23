# Solar Flare - Aura VFX Specification

> **Rarity:** Epic  
> **Chance:** 1 in 750 (Order: 8)  
> **Base Stats:** +0.35 Luck  
> **Mutation Synergy:** +0.10 SunForged Mutation Chance  
> **Theme Colors:** Warm Solar Gold `#FFDC50` (`rgb(255, 220, 80)`) and Sunset Amber `#FF5000` (`rgb(255, 80, 0)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** บรรยากาศช่วง Golden Hour พระอาทิตย์อัสดงสาดแสงสีทองกระทบผิวน้ำทะเลสาบ เกิดเป็นละอองไอน้ำประกายทองและแสงสะท้อนดั่งเพชรบนผิวน้ำ (Water Diamonds)
- **คุมความเรียบง่าย (No Over-the-Top):**
  - แม้จะมีชื่อว่า Solar Flare แต่คุมโทนให้เป็น **แสงอาทิตย์อัสดงอันอบอุ่น** ไม่ใช่ลูกไฟระเบิดหรือพายุสุริยะทำลายล้าง
  - หมอกสีทองลอยขึ้นในแนวตั้งอย่างสง่างาม ไม่หนาทึบจนบดบังตัวละคร
  - วงคลื่นที่พื้นเป็นรัศมีแสงอาทิตย์แผ่ออกอย่างนุ่มนวล
  - แสง PointLight สีทองส้มสร้างบรรยากาศตกปลายามเย็นที่สวยงามที่สุด

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_solar_vapor_4x4.png` | Flipbook 4x4 | ลำแสงไอน้ำสีทองและละอองไอแดดยามเย็นลอยขึ้นช้าๆ |
| `02_Ground` | `02_ground_sunburst_disk_4x4.png` | Flipbook 4x4 | รัศมีแสงอาทิตย์แผ่ออกจากเท้ากระทบผิวน้ำเป็นวงคลื่นสีทอง |
| `03_Orbital` | `03_orbital_solar_corona_strip.png` | Strip 1x1 | สายละอองแสงสีทองหมุนวนรอบเอวคล้ายโคโรนาอ่อนๆ (Tier 3) |
| `04_Flares` | `04_golden_sun_flares_4x4.png` | Flipbook 4x4 | แสงแฟลร์ 4 แฉกประกายเพชรสะท้อนผิวน้ำยามเย็น |
| `05_Sparks` | `05_sun_embers_atlas_2x2.png` | Static Atlas 2x2 | สะเก็ดละอองแดดสีทอง, เม็ดแสงเพชรน้ำ, ละอองประกายอุ่น |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีรัศมีแดดสีทองแผ่ที่พื้น และหมอกสีส้มอำพันลอยรอบลำตัว
- **Tier 2 (Enriched Golden Hour):** แสงไฟสีทองสว่างขึ้น พร้อมประกายเพชรน้ำระยิบระยับรอบตัว
- **Tier 3 (Signature Solar Radiance):** วงแหวนละอองแสงสีทองหมุนวนรอบตัวอย่างสง่างาม ดุจนักตกปลาผู้ได้รับพรจากแสงตะวัน
