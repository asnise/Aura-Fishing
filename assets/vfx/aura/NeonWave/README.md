# Neon Wave - Aura VFX Specification

> **Rarity:** Rare  
> **Chance:** 1 in 100 (Order: 5)  
> **Base Stats:** +0.15 Luck, +0.022 Catch Bar Size  
> **Mutation Synergy:** +0.03 Glowing Mutation Chance  
> **Theme Colors:** Electric Neon Cyan `#00C8FF` (`rgb(0, 200, 255)`) and Deep Bioluminescent Azure `#005AFF` (`rgb(0, 90, 255)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** ชายหาดเรืองแสงยามราตรี ปรากฏการณ์ธรรมชาติของแพลงก์ตอนเรืองแสงสีฟ้าสดใส (Bioluminescent Sea of Stars) ที่สว่างขึ้นเมื่อถูกระลอกคลื่นซัด
- **คุมความเรียบง่าย (No Over-the-Top):**
  - แม้จะมีสีนีออนสะดุดตา แต่เป็นการเรืองแสงแบบชีวภาพในธรรมชาติ (Organic Bioluminescence)
  - ไม่ใช่แสงไฟนีออนไซเบอร์พังก์ หรือลำแสงเลเซอร์ทำลายล้าง
  - ระลอกคลื่นใต้เท้าแผ่เป็นรูปวงคลื่นทะเลซัดเข้าฝั่งเป็นจังหวะ
  - มี PointLight ส่องสว่างนวลตาในระยะ 10 Studs รอบตัว ช่วยสร้างบรรยากาศตกปลากลางคืนอันน่าหลงใหล

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_biowave_mist_4x4.png` | Flipbook 4x4 | หมอกไอน้ำนีออนสีฟ้าสดใสลอยขึ้นจากผิวน้ำรอบลำตัว |
| `02_Ground` | `02_ground_biotide_crest_4x4.png` | Flipbook 4x4 | วงคลื่นทะเลเรืองแสงซัดแผ่ออกรอบเท้าเป็นจังหวะน้ำขึ้น-น้ำลง |
| `03_Orbital` | `03_orbital_tide_stream_strip.png` | Strip 1x1 | สายกระแสน้ำนีออนโคจรรอบเอวผู้เล่นอย่างสง่างาม (Tier 3) |
| `04_Flares` | `04_neon_caustic_glints_4x4.png` | Flipbook 4x4 | ประกายแสงวาบของแพลงก์ตอนเรืองแสงสีฟ้าสว่างแกนขาว |
| `05_Sparks` | `05_bio_plankton_atlas_2x2.png` | Static Atlas 2x2 | เม็ดแพลงก์ตอนเรืองแสง, ฟองฟองคลื่นนีออน, หยดน้ำสว่าง |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีระลอกคลื่นเรืองแสงสีฟ้าแผ่จากเท้า และละอองนีออนลอยขึ้นบางๆ
- **Tier 2 (Enriched Tide):** มีแสง PointLight สีฟ้าส่องพื้นสว่างชัดขึ้น พร้อมแพลงก์ตอนประกายแสงระยิบระยับรอบตัว
- **Tier 3 (Signature Neon Surge):** เพิ่มสายน้ำวนเรืองแสงสีฟ้าแอซูร์หมุนวนรอบตัว สร้างความรู้สึกเป็นนักตกปลาแห่งผืนน้ำราตรี
