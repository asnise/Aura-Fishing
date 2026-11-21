# Aura Fishing: Economy & Monetization Architecture Model

## 1. เศรษฐกิจแบบ "Circular Flow & Pressure-Relief" (ภาพรวมโมเดลเศรษฐกิจ)
เพื่อตอบโจทย์ผู้เล่นช่วงอายุ 9–24 ปี (Gen Z / Gen Alpha) ที่ต้องการความเร็วในการเสพความสุข (Instant Gratification) แต่ยังคงความยั่งยืนของเกม (D30 Retention) เราใช้โมเดลเศรษฐกิจแบบ **"Generous Faucet with Compounding Sinks"** (ให้เยอะ, ใช้เยอะ, แต่เพิ่มทางเลือกสบายด้วยเงินจริง)

```
[ Active Play / Idle Aquarium ] 
       │ (Faucet: Coins, Gems, Pearls)
       ▼
[ Core Loop Spending ] ──> Rods, Baits, Bag Expansion
       │
       ▼ (Late Game Bottleneck)
[ Heavy Sinks ] ──> Gear Enhancement (+1 ถึง +10), Aquarium Slots
       │
       ▼ (Friction Points)
[ Monetization Relief ] ──> Gamepasses / Convenience Dev Products
```

---

## 2. ตัวเลขเศรษฐกิจหลัก (Key Economy Pacing & Tables)

### A. อัตราการหาทรัพยากร (Income Rates per Hour)
| ช่วงเวลาในเกม | รายได้เหรียญ/ชม. (Coins) | รายได้เพชร/ชม. (Gems) | จำนวนเปิดกาชา/ชม. | เป้าหมายการใช้จ่าย (Next Purchase) |
|---|---|---|---|---|
| **Hour 1 (ช่วงต้น)** | 3,000 – 5,000 | 15 – 25 | 3 – 5 ครั้ง | อัปเกรดกระเป๋า, ซื้อเบ็ด Bamboo/Coral |
| **Hour 2–10 (ช่วงกลาง)** | 25,000 – 60,000 | 35 – 50 | 7 – 10 ครั้ง | ปลดล็อกสาย Nylon/Spider-Silk, ขยายตู้ปลา Idle |
| **Hour 10+ (ช่วงปลาย)** | 150,000+ | 60 – 80 | 10 – 15 ครั้ง | ตีบวกอุปกรณ์ขั้นสูง (Gear Enhance), ซื้อช่อง Aquarium ทั้งหมด |

### B. ตารางปรับสมดุลราคาและรางวัล (Economy Balance Sheet)
* **ราคาคันเบ็ด:** Driftwood (0) $\rightarrow$ Bamboo (4,000) $\rightarrow$ Coral (25,000) $\rightarrow$ Moonsilver (150,000) $\rightarrow$ Naga Scale (900,000)
* **ราคาช่องกระเป๋า:** 10 ช่อง (2,500) $\rightarrow$ 15 ช่อง (15,000) $\rightarrow$ 20 ช่อง (80,000) $\rightarrow$ 30 ช่อง (400,000)
* **ค่าใช้จ่ายระบบตีบวก (Gear Enhancement Sinks):** 
  - สูตรต้นทุน: $\text{Base Cost} \times (1.5)^{\text{Level}}$
  - *เป้าหมาย:* ดูดเหรียญส่วนเกินของผู้เล่นระดับสูง (Late-game Sink) เพื่อแก้ปัญหาเงินเฟ้อ

---

## 3. Monetization Model: แผนการสร้างรายได้ (Monetization Architecture)

เราเลือกใช้โมเดลผสมผสานระหว่าง **Convenience-First Gamepasses** (จ่ายเพื่อความสบาย ไม่โกงเกม) และ **Consumable Gacha / Boosts** (จ่ายเพื่อความเร็วและลุ้นของสวยงาม) 

### 1. Permanent Gamepasses (ซื้อครั้งเดียวคุ้มตลอดชีพ - High Conversion Focus)
* **Infinite Bag (499 Robux):** 
  - *แก้ปัญหาความรำคาญ:* กระเป๋าเต็มต้องเดินกลับไปขายบ่อยๆ หรือเปิด Auto-Sell ไม่ได้ดั่งใจ
  - *มูลค่าทางจิตวิทยา:* ผู้เล่นรู้สึกว่า "ซื้อความสะดวกครั้งเดียวจบ เล่นได้ยาวๆ ข้ามคืนสบาย"
* **Auto-Fish Pro (399 Robux):** 
  - *แก้ปัญหาความรำคาญ:* โหมด Auto ปกติได้เงินน้อยลงและตัดสิทธิ์บางส่วน
  - *มูลค่าทางจิตวิทยา:* ทำให้การฟาร์มตอนนอนหลับหรือทำการบ้านมีประสิทธิภาพสูงสุด 100% เท่า Manual
* **VIP Club (199 Robux):** 
  - *สิทธิประโยชน์:* Luck +15%, ขยายเวลาออฟไลน์ Aquarium เป็น 12 ชม. (จาก 4 ชม.), ชื่อสีทองพิเศษบนหัวและช่องแชท

### 2. Micro-Transactions & Dev Products (ซ้ำได้เรื่อยๆ - Impulse Buys)
* **Starter Pack (80 Robux - จำกัดสิทธิ์ 1 ครั้งต่อไอดี):**
  - คันเบ็ดพิเศษเทียบเท่า Coral Rod + เพชร 150 เม็ด + เหรียญ 10,000 + กระเป๋า 15 ช่องทันที
  - *เป้าหมาย:* ดึงดูดผู้เล่นใหม่ให้เปลี่ยนสถานะเป็น Paying User ครั้งแรก (Conversion Rate สูงสุด)
* **Gacha Gem Bundles (ราคาไล่ระดับ 40 / 160 / 400 Robux):**
  - ซื้อเพชรเพื่อเร่งเปิดตู้กาชา Rate-up ประจำสัปดาห์ หรือกดเร่งตู้ Pity
* **Instant Cash / Pearl Boosters (80 / 200 Robux):**
  - ซื้อบัฟคูณ 2 เหรียญหรือเพิร์ลเป็นเวลา 2 ชั่วโมง (สำหรับสายเร่งรีบเวลาน้อย)

---

## 4. ป้องกันกับดักทางเศรษฐกิจ (Economy Safeguards & Anti-Inflation)

1. **Anti-Dupe & Star Token Sink:** 
   - ออร่าซ้ำจากการเปิดกาชาจะไม่สูญเปล่า แต่จะถูกแปลงเป็น **Star Token** เพื่อนำไปอัปเกรดดาวให้ออร่าเดิม (★1 ถึง ★5) เป็นการสร้าง Sink สำหรับผู้เล่นสายเติมหนัก (Whales) โดยไม่ทำลายสมดุลเกลือของฟรี
2. **Hard Caps บนระบบ Idle Aquarium:** 
   - จำกัดเวลาสะสมทรัพยากรออฟไลน์สูงสุด 4 ชั่วโมง (ขยายเป็น 12 ชั่วโมงสำหรับ VIP) ป้องกันการปั๊มทรัพยากรผ่านไอดีรอง (Alt Accounts)
3. **Dynamic Material Sinks:** 
   - เมื่อผู้เล่นผ่านช่วงกลางเกม เหรียญจะไม่สามารถซื้อความเก่งได้โดยตรง แต่ต้องผ่านการใช้ **Pearls** จากตู้ปลาและวัตถุดิบจากการตกปลาลึกมารวมกันเพื่อตีบวกอุปกรณ์

---

## 5. สรุปความคุ้มค่าเชิงธุรกิจ (Business Projected Outcome)
* **ARPU (Average Revenue Per User):** คาดหวังการเข้าซื้อ Starter Pack 80 Robux จากผู้เล่นประมาณ 12-15% และการซื้อ Infinite Bag จากผู้เล่นประจำประมาณ 8-10%
* **Retention Balance:** การันตีว่าผู้เล่นสายฟรี (Free-to-Play) จะสามารถเข้าถึงทุกไอเทมได้ด้วยการเล่น (Grindable) ป้องกันความรู้สึกเป็น Pay-to-Win แต่ผู้เล่นที่จ่ายเงินจะได้ความเร็วและความสบาย (Pay-for-Convenience) เป็นการรักษาฐานประชากรในเซิร์ฟเวอร์ให้อยู่ในระดับสูงตลอดเวลา