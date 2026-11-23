# Sparkling Dew - Aura VFX Specification

> **Rarity:** Common  
> **Chance:** 1 in 10 (Order: 1)  
> **Base Stats:** +0.05 Luck  
> **Theme Colors:** Soft Pastel Cyan `#B4F0FF` (`rgb(180, 240, 255)`) and Crystal Water White `#FFFFFF`  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** บรรยากาศละอองน้ำค้างยามเช้าตรู่บนผิวน้ำที่นิ่งสงบ แสงอาทิตย์อ่อนๆ ตกกระทบหยดน้ำค้างบนกอพืชริมตลิ่ง
- **คุมความเรียบง่าย (No Over-the-Top):** 
  - ขนาดของอนุภาคมีขนาดกะทัดรัด (`Size: 0.25 - 0.35`)
  - อัตราการเกิดต่ำ ละมุนตา ไม่มีการสั่นไหวที่รุนแรง (`Rate: 8`)
  - เน้นหยดน้ำทรงกลมใสที่ลอยตัวขึ้นช้าๆ คล้ายฟองไอน้ำเบาบาง
  - การเคลื่อนไหวแนวตั้งลอยขึ้นแบบนุ่มนวล ไม่บังตัวละครหรือทุ่นตกปลา

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_dew_plumes_4x4.png` | Flipbook 4x4 | หมอกไอน้ำและละอองน้ำค้างลอยขึ้นในแนวตั้งอย่างแผ่วเบา |
| `02_Ground` | `02_ground_dew_ripple_4x4.png` | Flipbook 4x4 | วงระลอกน้ำหยดติ๋งกระทบผิวดิน/สะพานไม้ แผ่ออกบางๆ รอบเท้า |
| `03_Orbital` | `03_orbital_dew_stream_strip.png` | Strip 1x1 | สายละอองน้ำค้างหมุนวนแผ่วเบารอบเอว (เฉพาะ Tier 3) |
| `04_Flares` | `04_dew_glints_4x4.png` | Flipbook 4x4 | แสงวิบวับเหมือนหยดน้ำสะท้อนแดดยามเช้า ขนาดเล็ก |
| `05_Sparks` | `05_dew_droplets_2x2.png` | Static Atlas 2x2 | หยดน้ำค้างกลมใส, ฟองอากาศเล็ก, ละอองหมอกไมโคร |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีเฉพาะ Layer `01_Core` และ `02_Ground` แบบเบาบาง ให้ความรู้สึกมีหยดน้ำค้างเกาะรอบตัว
- **Tier 2 (Enriched Dew):** เพิ่ม Layer `04_Flares` และ `05_Sparks` หยดน้ำค้างเริ่มมีประกายระยิบระยับเมื่อขยับตัว
- **Tier 3 (Signature Mist):** เพิ่ม Layer `03_Orbital` ละอองน้ำค้างโปร่งแสงลอยวนรอบตัวช้าๆ เสริมความโดดเด่นแต่ยังคงความสบายตา
