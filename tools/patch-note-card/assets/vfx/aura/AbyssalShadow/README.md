# Abyssal Shadow - Aura VFX Specification

> **Rarity:** Legendary  
> **Chance:** 1 in 5,000 (Order: 11)  
> **Base Stats:** +0.50 Luck, +0.20 Auto Multiplier  
> **Mutation Synergy:** +0.03 VoidTouched Mutation Chance  
> **Theme Colors:** Abyssal Amethyst `#6E28AA` (`rgb(110, 40, 170)`) and Deep Velvet Trench `#0A0014` (`rgb(10, 0, 20)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** ความสงบเงียบอันลึกลับของร่องสมุทรลึกใต้ผืนน้ำ (Deep Ocean Trench) ที่แสงอาทิตย์ส่องไม่ถึง ละอองควันกำมะหยี่สีม่วงเข้มลอยละล่องช้าๆ แซมด้วยจุดแสงเรืองของสิ่งมีชีวิตใต้ทะเลลึก
- **คุมความเรียบง่าย (No Over-the-Top):**
  - **ไม่ใช่พลังปีศาจทำลายล้าง หรือหนามสีดำแหลมคมแบบอนิเมะต่อสู้**
  - ให้เป็นกลุ่มควันและไอหมอกน้ำลึกเนื้อเนียนนุ่ม (Velvet Trench Smoker Plumes) ที่ลอยช้าและไร้น้ำหนัก
  - ใช้ค่า LightEmission ต่ำ (`0.3`) เพื่อให้เห็นโครงร่างสีดำอมม่วงชัดเจนตัดกับผิวน้ำ
  - มีละอองเรืองแสงสีอเมทิสต์ขนาดจิ๋วช่วยเสริมความงาม ไม่แยงตาและไม่บดบังคันเบ็ด

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_abyssal_plumes_4x4.png` | Flipbook 4x4 | หมอกควันกำมะหยี่สีม่วงเข้มแห่งร่องสมุทรลอยขึ้นอย่างเชื่องช้า |
| `02_Ground` | `02_ground_trench_pool_4x4.png` | Flipbook 4x4 | แอ่งน้ำลึกสีม่วงเข้มพร้อมระลอกคลื่นความมืดหมุนวนเบาๆ ที่พื้น |
| `03_Orbital` | `03_orbital_void_tide_strip.png` | Strip 1x1 | สายกระแสน้ำวนความมืดหมุนวนรอบเอวอย่างเงียบกริบ (Tier 3) |
| `04_Flares` | `04_abyssal_bio_glints_4x4.png` | Flipbook 4x4 | แสงกะพริบของสปอร์เรืองแสงใต้ทะเลลึกสีม่วงอเมทิสต์ |
| `05_Sparks` | `05_trench_spores_atlas_2x2.png` | Static Atlas 2x2 | สปอร์เรืองแสงใต้ทะเลลึก, ฟองความมืด, สะเก็ดคริสตัลอเมทิสต์ |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีแอ่งน้ำสีม่วงเข้มที่พื้น และควันกำมะหยี่ลอยโอบล้อมรอบตัว
- **Tier 2 (Enriched Abyss):** เพิ่มจุดแสงเรืองรองชีวภาพสีม่วงอเมทิสต์สว่างวาวรอบตัว
- **Tier 3 (Signature Abyssal Majesty):** สายน้ำวนแห่งความมืดโคจรรอบตัวอย่างสง่างาม ให้ความรู้สึกถึงนักตกปลาผู้สำรวจร่องสมุทรที่ลึกที่สุด
