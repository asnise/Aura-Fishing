# Lotus Naga - Aura VFX Specification

> **Rarity:** Legendary  
> **Chance:** 1 in 12,000 (Order: 12)  
> **Base Stats:** +0.60 Luck, +0.15 Fish Stability, +0.10 Auto Multiplier  
> **Mutation Synergy:** +0.08 Golden Mutation Chance  
> **Theme Colors:** River Jade `#3CC882` (`rgb(60, 200, 130)`) and Sacred Lotus Pink `#FF96C8` (`rgb(255, 150, 200)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** บารมีแห่งพญานาคราชผู้พิทักษ์สายน้ำอันศักดิ์สิทธิ์ สายน้ำวนสีเขียวหยกเนื้อเย็นที่หมุนวนขึ้นเป็นเกลียวอย่างอ่อนช้อย พร้อมกลีบดอกบัวทิพย์ลอยวนและละอองบุญบารมีสีทอง
- **คุมความเรียบง่าย (No Over-the-Top):**
  - ไม่ใช่สัตว์ประหลาดดุร้ายหรือพญานาคพ่นไฟทำลายล้าง
  - เน้นความสง่างาม ศักดิ์สิทธิ์ (Reverent & Graceful)
  - ริบบิ้นสายน้ำหยกเคลื่อนไหวเลื้อยวนคล้ายพญานาคในวรรณคดีอย่างนุ่มนวล
  - กลีบดอกบัวสีชมพูและละอองทองลอยสลับกันอย่างประณีต ช่วยส่งเสริมบรรยากาศมงคลแห่งการตกปลา

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_jade_stream_4x4.png` | Flipbook 4x4 | ละอองไอน้ำสีเขียวหยกและควันน้ำศักดิ์สิทธิ์ลอยขึ้นเป็นเกลียว |
| `02_Ground` | `02_ground_lotus_blessing_4x4.png` | Flipbook 4x4 | วงคลื่นน้ำลวดลายดอกบัวแปดกลีบแผ่ออกจากเท้าอย่างศักดิ์สิทธิ์ |
| `03_Orbital` | `03_orbital_naga_ribbon_strip.png` | Strip 1x1 | สายน้ำวนหยกเลื้อยวนรอบเอวคล้ายลำตัวพญานาคนุ่มนวล (Tier 3) |
| `04_Flares` | `04_sacred_lotus_glints_4x4.png` | Flipbook 4x4 | แสงประกายบารมีสีชมพูทองดั่งแสงทิพย์แห่งดอกบัว |
| `05_Sparks` | `05_lotus_petals_gold_2x2.png` | Static Atlas 2x2 | กลีบดอกบัวสีชมพู, ละอองทองคำมงคล, เกล็ดพญานาคสีหยก |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีลายคลื่นดอกบัวสีหยกที่พื้น และหมอกสีเขียวมรกตลอยรอบตัว
- **Tier 2 (Enriched Reverence):** แสง PointLight สีหยกสว่างนวลขึ้น พร้อมกลีบดอกบัวและละอองทองคำลอยวน
- **Tier 3 (Signature Naga Guardian):** สายน้ำวนพญานาคสีหยกเลื้อยวนโอบล้อมรอบตัวผู้เล่นอย่างสง่างาม ดุจได้รับพรแห่งสายน้ำ
