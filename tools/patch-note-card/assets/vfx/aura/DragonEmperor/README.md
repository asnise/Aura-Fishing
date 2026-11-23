# Dragon Emperor - Aura VFX Specification

> **Rarity:** Mythic  
> **Chance:** 1 in 50,000 (Order: 14)  
> **Base Stats:** +1.00 Luck, +0.30 Fish Stability  
> **Mutation Synergy:** +0.25 Golden Mutation Chance  
> **Theme Colors:** Sovereign Imperial Gold `#FFD700` (`rgb(255, 215, 0)`) and Radiant Dragon Amber `#FF8C00` (`rgb(255, 140, 0)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** บารมีแห่งองค์จักรพรรดิมังกรทองแห่งลุ่มน้ำ ตำนานปลาหลี่ฮื้อกระโดดข้ามประตูมังกร (Carp Leaping over Dragon Gate) ละอองหมอกสีทองคำอร่ามและควันมงคลลอยขึ้นอย่างสง่างาม พร้อมจิตวิญญาณมังกรทองตัวเรียวลอยวนอย่างสุขุม
- **คุมความเรียบง่าย (No Over-the-Top):**
  - **ไม่ใช่การระเบิดไฟแบบเกมต่อสู้อนิเมะ หรือคลื่นพลังงานสีเหลืองท่วมจอ**
  - เน้นความสง่างาม บารมีอันศักดิ์สิทธิ์ (Majestic Serenity)
  - หมอกสีทองเนื้อละเอียดโปร่งแสง ไม่บังตัวละครหรือจุดทุ่นตกปลา
  - ลวดลายที่พื้นเป็นวงคลื่นน้ำมงคลผสมลายเมฆมังกรจีน (Auspicious Cloud Ripples)
  - แสง PointLight สีทองบริสุทธิ์เปล่งประกายอย่างอบอุ่นและมีเกียรติ

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_sovereign_vapor_4x4.png` | Flipbook 4x4 | หมอกควันมงคลสีทองคำจักรพรรดิลอยขึ้นเป็นเกลียวสง่างาม |
| `02_Ground` | `02_ground_dragon_crest_4x4.png` | Flipbook 4x4 | วงระลอกคลื่นน้ำทองคำผสานลายเมฆมงคลแผ่กว้างบนพื้น |
| `03_Orbital` | `03_orbital_golden_dragon_strip.png` | Strip 1x1 | จิตวิญญาณมังกรทองโปร่งแสงเลื้อยวนรอบเอวอย่างสุขุม (Tier 3) |
| `04_Flares` | `04_imperial_dragon_flares_4x4.png` | Flipbook 4x4 | แสงแฟลร์เพชรทองคำ 8 แฉกประกายแสงบารมีจักรพรรดิ |
| `05_Sparks` | `05_dragon_scales_gold_2x2.png` | Static Atlas 2x2 | เกล็ดมังกรทองคำ, ลูกแก้วมังกรมงคล, ละอองทองลอยละล่อง |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีลายคลื่นเมฆทองคำที่พื้น และหมอกสีทองจักรพรรดิลอยรอบตัว
- **Tier 2 (Enriched Auspiciousness):** แสงไฟสีทองสว่างเรืองรอง พร้อมเกล็ดมังกรทองและลูกแก้วมังกรลอยวน
- **Tier 3 (Signature Sovereign Dragon):** จิตวิญญาณมังกรทองคำเลื้อยวนรอบตัวผู้เล่นอย่างสง่างาม ดุจจักรพรรดิแห่งสายน้ำ
