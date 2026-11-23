# Nebula Koi - Aura VFX Specification

> **Rarity:** Epic  
> **Chance:** 1 in 3,000 (Order: 10)  
> **Base Stats:** +0.45 Luck, +0.10 XP Multiplier  
> **Mutation Synergy:** +0.03 Golden Mutation Chance  
> **Theme Colors:** Astral Lavender `#C8AAFF` (`rgb(200, 170, 255)`) and Cosmic Lotus Pink `#FFA0D2` (`rgb(255, 160, 210)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** บ่อปลาคาร์ปยามราตรีที่สะท้อนเงาของกาแล็กซีและเนบิวลาบนผืนน้ำ มีวิญญาณปลาคาร์ปดวงดาวสีพาสเทลว่ายวนอย่างอ่อนช้อย นำพาละอองฝุ่นดาวและความสิริมงคล
- **คุมความเรียบง่าย (No Over-the-Top):**
  - วิญญาณปลาคาร์ปมีรูปร่างโปร่งแสง (Phantom Koi Silhouette) พริ้วไหวตามสายน้ำ ไม่ใช่ปลาทึบแสงตัวใหญ่
  - ฝุ่นดาวและเนบิวลาใช้สีม่วงลาเวนเดอร์และชมพูดอกบัว สบายตา อ่อนโยน
  - ระลอกคลื่นที่พื้นจำลองบ่อดวงดาว (Starlight Koi Pond Disk) หมุนวนช้าๆ
  - การเคลื่อนไหวว่ายวนรอบตัวเป็นไปอย่างเงียบสงบ สร้างเสน่ห์ความฝันให้กับนักตกปลา

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

ภาพต้นทางชุดแรกเจนด้วย ImageGen แยกครบ 5 ชีต กดชื่อ PNG ในตารางเพื่อเปิดไฟล์ขาวบนดำสำหรับขั้น Luma to Alpha ดู [บันทึกการสร้างและชุดพรอมป์](../AURA_VFX_PIPELINE_GUIDE.md#3-ชุดภาพต้นทาง-2026-11-23)

ฉบับสำหรับปรับเลเยอร์ใน Particle Editor [project.json](project.json)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | [`01_core_nebula_mist_4x4.png`](01_core_nebula_mist_4x4.png) | Flipbook 4x4 | หมอกเนบิวลาดวงดาวสีม่วงลาเวนเดอร์ลอยขึ้นเป็นริ้วแพรไหม |
| `02_Ground` | [`02_ground_starlight_pond_4x4.png`](02_ground_starlight_pond_4x4.png) | Flipbook 4x4 | สระน้ำสะท้อนดวงดาวและเกลียวเนบิวลาแผ่ออกอย่างแผ่วเบาที่พื้น |
| `03_Orbital` | [`03_orbital_koi_swim_strip.png`](03_orbital_koi_swim_strip.png) | Strip 1x1 | วิญญาณปลาคาร์ปโปร่งแสงว่ายวนรอบเอวผู้เล่นอย่างอ่อนช้อย (Tier 3) |
| `04_Flares` | [`04_cosmic_star_flares_4x4.png`](04_cosmic_star_flares_4x4.png) | Flipbook 4x4 | ประกายดาวระยิบระยับแบบ 4 แฉกสะท้อนเกล็ดปลาคาร์ป |
| `05_Sparks` | [`05_stardust_scales_atlas_2x2.png`](05_stardust_scales_atlas_2x2.png) | Static Atlas 2x2 | ฝุ่นดวงดาวประกาย, เกล็ดปลาคาร์ปเรืองแสง, ดอกบัวสวรรค์จิ๋ว |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีเงาสระน้ำดวงดาวที่พื้น และหมอกสีม่วงลาเวนเดอร์ลอยรอบตัว
- **Tier 2 (Enriched Starlight):** แสงไฟสีม่วงอมชมพูส่องสว่างขึ้น พร้อมประกายดาวและเกล็ดปลาเรืองแสงลอยรอบลำตัว
- **Tier 3 (Signature Cosmic Koi):** วิญญาณปลาคาร์ปเนบิวลาว่ายวนรอบตัวผู้เล่นอย่างสงบ ดุจการตกปลาท่ามกลางแม่น้ำดวงดาว
