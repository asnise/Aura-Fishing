# Tidal Bloom - Aura VFX Specification

> **Rarity:** Common  
> **Chance:** 1 in 15 (Order: 2)  
> **Base Stats:** +0.06 Luck, +0.02 Bite Speed  
> **Theme Colors:** Seafoam Mint `#96EBC8` (`rgb(150, 235, 200)`) and Pastel Blossom Pink `#FFBEDC` (`rgb(255, 190, 220)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** ชายฝั่งน้ำตื้นยามฤดูใบไม้ผลิ น้ำใสสีเขียวมิ้นต์ที่มีกลีบดอกไม้ลอยมาตามระลอกคลื่นแผ่วเบา
- **คุมความเรียบง่าย (No Over-the-Top):**
  - เน้นการผสมผสานสองเฉดสีแบบพาสเทล นุ่มนวล สบายตา
  - กลีบดอกไม้และฟองคลื่นลอยขึ้นแบบส่ายไปมาเบาๆ (Gentle Swaying) ไม่มีความรุนแรง
  - ไม่ใช้แสงวาบหรือเอฟเฟกต์แฟลชขนาดใหญ่
  - วงคลื่นที่พื้นขยายตัวและจางหายอย่างช้าๆ ให้ความรู้สึกผ่อนคลายขณะตกปลา

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

ภาพต้นทางชุดแรกเจนด้วย ImageGen แยกครบ 5 ชีต กดชื่อ PNG ในตารางเพื่อเปิดไฟล์ขาวบนดำสำหรับขั้น Luma to Alpha ดู [บันทึกการสร้างและชุดพรอมป์](../AURA_VFX_PIPELINE_GUIDE.md#3-ชุดภาพต้นทาง-2026-11-23)

ฉบับสำหรับปรับเลเยอร์ใน Particle Editor [project.json](project.json)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | [`01_core_tidal_mist_4x4.png`](01_core_tidal_mist_4x4.png) | Flipbook 4x4 | หมอกไอน้ำเขียวซีโฟมและละอองน้ำลอยขึ้นช้าๆ |
| `02_Ground` | [`02_ground_blossom_ripple_4x4.png`](02_ground_blossom_ripple_4x4.png) | Flipbook 4x4 | คลื่นระลอกน้ำทรงกลมพร้อมเงากลีบดอกไม้ลอยกระจายออกรอบเท้า |
| `03_Orbital` | [`03_orbital_petal_drift_strip.png`](03_orbital_petal_drift_strip.png) | Strip 1x1 | สายกระแสน้ำวนบางๆ พาละอองกลีบดอกไม้หมุนช้าๆ รอบตัว (Tier 3) |
| `04_Flares` | [`04_floral_glints_4x4.png`](04_floral_glints_4x4.png) | Flipbook 4x4 | แสงประกายน้ำสะท้อนกลีบดอกไม้สีชมพูพาสเทล |
| `05_Sparks` | [`05_petals_foam_atlas_2x2.png`](05_petals_foam_atlas_2x2.png) | Static Atlas 2x2 | กลีบดอกไม้น้ำ, ฟองฟองคลื่นซีโฟม, เกสรเรืองแสง |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีระลอกคลื่นน้ำบางๆ ที่พื้นและละอองหมอกสีเขียวมิ้นต์ลอยเอื่อยๆ
- **Tier 2 (Enriched Blossom):** เพิ่มกลีบดอกไม้สีชมพูลอยวนขึ้นตามลม และเกสรแสงขนาดเล็ก
- **Tier 3 (Signature Tidal Bloom):** สายน้ำวนบางเบาพากลีบดอกไม้หมุนวนรอบเอวผู้เล่นอย่างอ่อนโยน
