# Kelp Whisper - Aura VFX Specification

> **Rarity:** Uncommon  
> **Chance:** 1 in 40 (Order: 3)  
> **Base Stats:** +0.10 Luck, +0.05 Fish Stability  
> **Theme Colors:** Fresh Kelp Green `#6ED278` (`rgb(110, 210, 120)`) and Deep Ocean Algae `#288C50` (`rgb(40, 140, 80)`)  

---

## 1. แนวคิดการออกแบบและคุมธีม (Design & Cozy Theme Guardrails)

- **บรรยากาศ (Atmosphere):** ความสงบเงียบใต้ผืนน้ำในดงสาหร่ายเคลป์อันอุดมสมบูรณ์ ฟองอากาศและสปอร์เรืองแสงลอยขึ้นตามกระแสน้ำพัดเอื่อยๆ
- **คุมความเรียบง่าย (No Over-the-Top):**
  - อนุภาคเคลื่อนที่ช้าและแกว่งไปมาตามกระแสน้ำ (Sinusoidal Sway)
  - ฟองอากาศกลมใสมีเงาหักเหแสงตามธรรมชาติ
  - วงคลื่นที่พื้นจำลองแสงแดดสะท้อนผ่านผิวน้ำลงสู่ก้นบ่อ (Submerged Caustic Glow)
  - ไม่มีความกระพริบจัดจ้าน ให้ความรู้สึกร่มรื่น สบายตา เหมาะแก่การเฝ้ารอคอยปลา

---

## 2. สถาปัตยกรรมเลเยอร์ (Layer Architecture)

| Layer | Texture File | รูปแบบ | บทบาทในเกม |
| :--- | :--- | :--- | :--- |
| `01_Core` | `01_core_kelp_current_4x4.png` | Flipbook 4x4 | หมอกไอน้ำสีเขียวมรกตและฟองอากาศลอยขึ้นจากข้างล่าง |
| `02_Ground` | `02_ground_algae_caustic_4x4.png` | Flipbook 4x4 | ลายแสงหักเหผิวน้ำกระทบก้นสระ (Water Caustic) แผ่เบาๆ รอบเท้า |
| `03_Orbital` | `03_orbital_kelp_ribbon_strip.png` | Strip 1x1 | สายน้ำวนพริ้วไหวคล้ายใบสาหร่ายเคลป์หมุนวนรอบตัว (Tier 3) |
| `04_Flares` | `04_kelp_bio_glints_4x4.png` | Flipbook 4x4 | ประกายแสงสปอร์พืชน้ำสีเขียวอ่อนเรืองแสงนุ่มๆ |
| `05_Sparks` | `05_kelp_spores_bubbles_2x2.png` | Static Atlas 2x2 | ฟองออกซิเจนกลมใส, ละอองสปอร์เรืองแสง, เศษใบสาหร่ายจิ๋ว |

---

## 3. ลำดับขั้นออร่า (Tier Progression)

- **Tier 1 (Base Ambient):** มีลายแสง Caustic สะท้อนที่พื้น และฟองอากาศลอยขึ้นรอบตัวเป็นช่วงๆ
- **Tier 2 (Enriched Sanctuary):** เพิ่มสปอร์พืชน้ำสีเขียวมะนาวลอยวน สลับกับฟองอากาศที่แตกออกเบาๆ
- **Tier 3 (Signature Forest):** สายน้ำวนสีเขียวมรกตโอบล้อมรอบตัวผู้เล่น พร้อมแสงเรืองนวลที่ทำให้ตัวละครโดดเด่นอย่างสงบ
