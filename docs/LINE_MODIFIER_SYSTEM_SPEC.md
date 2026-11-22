# เอกสารการออกแบบระบบ Line Modifier (Line Prefix / Suffix Specification & Plan)

เอกสารฉบับนี้จัดทำขึ้นสำหรับ Coding Agent เพื่อเป็นพิมพ์เขียวการขยายระบบ Modifier (Prefix / Suffix) ไปยัง **เส้นเอ็นเบ็ด (Lines)** ในเกม Aura Fishing โดยใช้ฐานข้อมูล Attribute และกลไกเดียวกับคันเบ็ด (Rods) 100% เพื่อสร้างวงจรเศรษฐกิจ (Economic Loop) และเหตุผลที่ผู้เล่นจะต้องซื้อ ขาย และตามล่าหา God Roll ของเส้นเอ็นเบ็ด

---

## 1. ที่มาและเหตุผลเชิงการออกแบบเศรษฐกิจ (Economic Purpose & Game Design)

### 1.1 ปัญหาของระบบเดิม (Current Pain Points)
- **ซื้อครั้งเดียวจบ (One-and-done):** ผู้เล่นซื้อเส้นเอ็นเบ็ดในร้านค้าเพียงครั้งเดียวเพื่อปลดล็อกสเตตัสระยะความลึก (`MaxDepth`) เมื่อซื้อเสร็จแล้ว ผู้เล่นจะไม่มีเหตุผลใดๆ ที่จะต้องซื้อเส้นเอ็นเบ็ดซ้ำอีกเลย
- **ไม่มีมูลค่าการขายต่อ (No Resell Incentive):** เส้นเอ็นเบ็ดเก่าที่ไม่ได้ใช้ถูกเก็บค้างไว้ในกระเป๋าหรือขายทิ้งในราคาเศษเหรียญ ไม่มีความน่าสนใจในการหมุนเวียนเงิน
- **ขาดความหลากหลายของ Build:** สเตตัสของเอ็นเบ็ดตายตัว มีเพียง `MaxDepth` และ `Resilience` เล็กน้อย ทำให้การปรับแต่งตัวละครพึ่งพาคันเบ็ดเพียงชิ้นเดียว

### 1.2 สิ่งที่จะเกิดขึ้นหลังมี Line Modifier (New Economic Loop)
1. **Buy Loop (การซื้อเพื่อสุ่มหาออปชั่น):** ผู้เล่นจะมีแรงจูงใจในการนำเงินเหรียญ (Coins) มาซื้อเส้นเอ็นเบ็ดซ้ำๆ เพื่อสุ่มหาชุด Modifier ที่เข้ากับสายการเล่นของตนเอง
2. **Sell Loop (การขายเส้นเอ็นที่ไม่ใช้เพื่อคืนทุน):** เส้นเอ็นเบ็ดที่สุ่มได้ออปชั่นไม่ตรงสาย หรือสุ่มได้ระดับ Rarity สูงแต่ไม่ใช่ค่าที่ต้องการ สามารถนำไปขายคืนร้านค้าได้ราคาดีขึ้นตามมูลค่าโบนัส `CFG.ModSellBonus` ของแต่ละ Modifier
3. **Gear Synergy (การจับคู่คอมโบระหว่าง Rod + Line):** ผู้เล่นสามารถวางแผนคอมโบ เช่น:
   - ใช้ **Rod สายหาปลา:** เน้น Prefix Luck + Suffix MutationChance
   - ประกบคู่กับ **Line สายความเร็วและความเสถียร:** เน้น Prefix BiteSpeed/AutoSpeed + Suffix Resilience/CatchBarSize
   - หรือใช้ Line ช่วยทะลุขีดจำกัดด้วยออปชั่นกลุ่ม **Cap Breaker** (เช่น `MaxAutoSpeed`, `MaxCatchBarSize`)

---

## 2. การแชร์ฐานข้อมูลร่วมกับระบบปกติ (Unified Shared System Architecture)

ตามคำสั่งของระบบ จะไม่มีการสร้างตาราง Modifier แยกใหม่สำหรับ Line แต่จะ **ใช้ฐานข้อมูลเดียวกันกับ Rod Modifier ใน `src/shared/Config/ModifierDefs.luau` ทั้งหมด**:

### 2.1 องค์ประกอบที่แชร์ร่วมกัน (Shared Elements)
- **หมวดคำนำหน้า (Prefixes):** ใช้ชุดเดียวกับ Rod (Swift, Firm, Reaching, Keen, Sturdy, Fortunate, Lucky, Mighty, Brisk, Blessed, Rapid, Celestial, Hyper, Divine และกลุ่ม Cap Breaker เช่น Uncapped, Overclocked, Warp, Singularity)
- **หมวดคำต่อท้าย (Suffixes):** ใช้ชุดเดียวกับ Rod (of Grip, of Calm, of Commerce, of Tension, of Scope, of Insight, of Iron, of Stillness, of Prosperity, of Anomaly, of Tides, of Radiance, of Eternity และกลุ่ม Cap Breaker เช่น of Extension, of the Unbroken, of Serenity, of the Titan, of the Leviathan, of Adamant)
- **Drop Condition Profiles:** ใช้ Profile เดิม (`Shop`, `Fishing`, `DeepSea`, `BossRaid`, `QuestPure`)
- **ช่วงค่าสุ่ม (-N ถึง +N):** มีทั้งค่าบวก, ค่าลบ (Cursed Roll สีแดง), และค่าสูงสุด (God Roll)

### 2.2 โครงสร้างชื่อไอเทม (Procedural Item Naming)
ตัวอย่างชื่อเส้นเอ็นเบ็ดที่แสดงผลบน UI:
- *Swift Nylon Line of Iron* (Nylon Line 150m + BiteSpeed + Resilience)
- *Reaching Spider-Silk Line of the Abyss* (Silk Line 300m + CastRange + PearlRate)
- *Blessed Star Line of Mutation* (Star Line 1000m + Luck + MutationChance)
- *Overclocked Abyss Line of Calm* (Abyss Line 600m + MaxAutoSpeed [Cap Breaker] + FishStability)

---

## 3. กฎการสุ่มและระดับของเส้นเอ็นเบ็ด (Line Tiers & Slot Rules)

เช่นเดียวกับคันเบ็ด เส้นเอ็นเบ็ดระดับ **Common (ของเริ่มต้นฟรี) จะไม่มี Modifier** ส่วนระดับ Uncommon ขึ้นไปจะมีโอกาสสุ่มได้ตาม Drop Profile:

| รหัสสินค้า (Id) | ชื่อไอเทม (Name) | ราคาซื้อ (Price) | ระดับ Rarity | ระดับ Tier | โอกาสเกิดช่อง (Shop Profile) | เพดานความลึก (Base MaxDepth) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `CottonLine` | Cotton Line | 0 Coins (ฟรี) | Common | Tier 1 | 0 Slots (ไม่มี Mod) | 30 เมตร |
| `HempLine` | Hemp Line | 1,000 Coins | Uncommon | Tier 2 | Prefix 0-2 / Suffix 0-2 (Floor: Common, Ceil: Rare) | 80 เมตร |
| `NylonLine` | Nylon Line | 15,000 Coins | Rare | Tier 3 | Prefix 0-2 / Suffix 0-2 (Floor: Common, Ceil: Rare) | 150 เมตร |
| `SilkLine` | Spider-Silk Line | 150,000 Coins | Epic | Tier 4 | Prefix 0-2 / Suffix 0-2 (Floor: Common, Ceil: Rare) | 300 เมตร |
| `AbyssLine` | Abyss Line | 1,200,000 Coins | Legendary | Tier 5 | Prefix 0-2 / Suffix 0-2 (Floor: Common, Ceil: Rare) | 600 เมตร |
| `StarLine` | Star Line | 6,000,000 Coins | Mythic | Tier 6 | Prefix 0-2 / Suffix 0-2 (Floor: Common, Ceil: Rare) | 1000 เมตร |

*หมายเหตุ:* หากได้รับ Line จากการตกปลาลึกหรือกล่องสมบัติ จะใช้ Profile `DeepSea` หรือ `Fishing` ซึ่งมีโอกาสเปิดได้ Mod ระดับ Epic, Legendary และ Cap Breaker สูงกว่าการซื้อตรงจาก Shop

---

## 4. โครงสร้างข้อมูลและการคำนวณ (Data Flow & Technical Specifications)

### 4.1 ข้อมูลในโปรไฟล์กระเป๋า (`profile.Bag`)
เมื่อผู้เล่นซื้อ Line จากร้านค้า ข้อมูลจะถูกบันทึกเป็น Record เดี่ยวใน `profile.Bag` พร้อม UUID:
```lua
{
    UUID = "guid-string",
    Id = "NylonLine",
    Kind = "Line",
    Enhance = 0,
    Prefixes = {
        { Id = "p_swift", Name = "Swift", Stat = "BiteSpeed", Value = 0.08, Rarity = "Common" }
    },
    Suffixes = {
        { Id = "s_of_iron", Name = "of Iron", Stat = "Resilience", Value = 0.18, Rarity = "Rare" }
    }
}
```

### 4.2 การคำนวณสเตตัสรวม (`Stats.luau`)
ใน `src/shared/Stats.luau`:
- ฟังก์ชัน `Stats.Collect(profile)` ทำงานผ่านลูป `for catId in Registry.Equipment`:
  - เมื่อ `catId == "Lines"` จะค้นหาไอเทมสวมใส่ผ่าน `Inventory.Worn(profile, "Lines")`
  - ดึงค่า Base Stats ผ่าน `Inventory.GearStats(worn)`
  - ดึงค่า Modifier ทั้งหมดผ่าน `Inventory.ModStats(worn)`
- **ผลลัพธ์:** สเตตัสจากทั้ง Rod และ Line จะถูกรวมเข้าด้วยกันใน `Stats.Compute` โดยอัตโนมัติ รวมถึงการคำนวณเพดาน Cap Breaker (`Max<Stat>`) ร่วมกันอย่างราบรื่น

### 4.3 สูตรราคาขายคืนร้านค้า (`Inventory.SellValue`)
ใน `src/shared/Items/ItemContainer.luau`:
- ราคาขายพื้นฐานของ Gear: `BasePrice * GameConfig.Inventory.GearSellFraction` (ปกติคือ 50% ของราคาซื้อ)
- โบนัสจาก Modifier: แต่ละ Mod บนเอ็นเบ็ดจะเพิ่มมูลค่าตามระดับ Rarity:
  - Common: +5% ของ BasePrice
  - Uncommon: +10% ของ BasePrice
  - Rare: +25% ของ BasePrice
  - Epic: +50% ของ BasePrice
  - Legendary: +100% ของ BasePrice
  - Mythic: +250% ของ BasePrice
- เมื่อขายเอ็นเบ็ดที่มี Mod หายาก ผู้เล่นจะได้รับเงินคืนเป็นกอบเป็นกำ ทำให้การซื้อมาสุ่มไม่เป็นการสูญเงินเปล่า 100%

---

## 5. แผนการทำงานสำหรับ Coding Agent (Implementation Roadmap)

งานนี้เป็นงานต่อยอดที่ระบบพื้นฐาน (Foundation) รองรับไว้แล้วเกือบทั้งหมด มีจุดที่ต้องแก้ไขจริงเพียง 3 ตำแหน่ง:

### ขั้นที่ 1: เปิดการสุ่ม Modifier ให้กับ Line ตอนสร้างไอเทม
- **ไฟล์เป้าหมาย:** `src/shared/Items/ItemContainer.luau`
- **ตำแหน่ง:** ในฟังก์ชัน `Inventory.NewGear(categoryId, itemId, dropProfile)` (บรรทัด ~99)
- **การเปลี่ยนแปลง:**
  - เดิม: `if categoryId == "Rods" then`
  - ปรับเป็น: `if categoryId == "Rods" or categoryId == "Lines" then`
  - ผลลัพธ์: เมื่อผู้เล่นซื้อ Line จากร้านค้าด้วย `ShopService.Buy` (ซึ่งส่ง `dropProfile = "Shop"` อยู่แล้ว) หรือได้รับจาก Drop Line จะได้รับการสุ่ม `Prefixes` และ `Suffixes` ทันที

### ขั้นที่ 2: เปิดการแสดงผล Modifier Chips บนหน้าต่าง ItemDetail
- **ไฟล์เป้าหมาย:** `src/client/UI/ItemDetail.luau`
- **ตำแหน่ง:** ในฟังก์ชันสร้างโมเดล `buildGear` (บรรทัด ~205)
- **การเปลี่ยนแปลง:**
  - เดิม: `Mods = if item.Kind == "Rod" and gear then ...`
  - ปรับเป็น: `Mods = if (item.Kind == "Rod" or item.Kind == "Line") and gear then ...`
  - ผลลัพธ์: เมื่อผู้เล่นกดดูการ์ด Line ในกระเป๋า ตัวการ์ดจะแสดงป้ายชิปสีฟ้า (Prefix) และชิปสีม่วง (Suffix) พร้อมค่า Stat เหมือนคันเบ็ดทันที

### ขั้นที่ 3: ปรับแต่งข้อความแจ้งเตือนตอนขาย (Sell Confirmation Modal)
- **ไฟล์เป้าหมาย:** `src/client/UI/ItemDetail.luau`
- **ตำแหน่ง:** ในฟังก์ชันกดยืนยันขาย (บรรทัด ~237)
- **การเปลี่ยนแปลง:**
  - เดิม: `Message = "The {invested} on this rod is lost for good."`
  - ปรับเป็น: `Message = "The {invested} on this {string.lower(item.Kind)} is lost for good."`
  - ผลลัพธ์: ข้อความเตือนก่อนขายจะแสดงคำว่า "on this line" เมื่อขายเอ็นเบ็ดที่มี Mod หรือบวก Enhance อยู่

### ขั้นที่ 4: ตรวจสอบและทดสอบความถูกต้อง (Verification)
- ทดสอบสร้าง Line ผ่านคำสั่ง Dev: `/give HempLine`, `/give SilkLine`
- ยืนยันว่า Line มีช่อง Prefix และ Suffix สุ่มขึ้นมา
- ยืนยันว่าสวมใส่ Line แล้ว สเตตัสใน HUD / Character เพิ่มขึ้นถูกต้อง
- ยืนยันว่าขาย Line แล้วได้รับเงินพร้อม ModSellBonus
- รัน `node tools/check.mjs` เพื่อยืนยันว่า Typecheck ผ่าน `0 error(s)` และไม่มีสัญลักษณ์ต้องห้าม
