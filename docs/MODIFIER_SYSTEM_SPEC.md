# เอกสารการออกแบบระบบ Modifier (Prefix / Suffix System Specification)

เอกสารฉบับนี้จัดทำขึ้นสำหรับ Coding Agent เพื่อเป็นพิมพ์เขียวการพัฒนาระบบ Modifier ของอุปกรณ์สวมใส่ (Rods และ Lines) ในเกม Aura Fishing ครอบคลุมกฎการสุ่มจำนวนช่อง (Slot Roll), แคตตาล็อก Attribute แยกตาม Rarity, กลไกสุ่มค่าตัวเลข -N ถึง +N (มีทั้งผลบวกและผลลบ), และระบบพิเศษ **การขยายเพดานสเตตัสสูงสุด (Stat Max Cap Breaker / Overcap)** ที่สเกลตามระดับ Rarity
(ดูรายละเอียดส่วนขยายของเส้นเอ็นเบ็ดเพิ่มเติมใน `docs/LINE_MODIFIER_SYSTEM_SPEC.md`)

---

## 1. ภาพรวมของระบบ (System Overview)

1. อุปกรณ์สวมใส่ประเภท Gear (Rods และ Lines) สามารถมี Modifier ได้ 2 ประเภท:
   - Prefix (คำนำหน้า): เน้นสเตตัสแอคชั่น, ความเร็ว, พลังดึง, โชค, และการ Overclock เพดานสปีด
   - Suffix (คำต่อท้าย): เน้นสเตตัสความเสถียร, ตัวคูณผลตอบแทน, การขยายขนาดหลอด, และการทะลุเพดานความคงทน
2. ขีดจำกัดช่องสูงสุดต่อชิ้นอุปกรณ์ (ทั้ง Rod และ Line):
   - Prefix สูงสุด 2 ช่อง
   - Suffix สูงสุด 2 ช่อง
   - รวมกันสูงสุด 4 ช่องต่อ 1 ชิ้นอุปกรณ์ (สวมใส่ 2 ชิ้น Rod + Line รวมกันได้สูงสุด 8 Modifiers)
3. โครงสร้างข้อมูล (ModEntry):
   - Id: รหัสอ้างอิงของ Modifier (string)
   - Name: ชื่อที่แสดงบนการ์ดไอเทม (string)
   - Stat: สเตตัสเป้าหมายตาม StatDefs หรือ Stat Cap เป้าหมาย (string)
   - Value: ค่าพลังที่สุ่มได้ (number มีได้ทั้งค่าบวกและค่าลบ)
   - Rarity: ระดับความหายากของ Attribute (string: Common, Uncommon, Rare, Epic, Legendary, Mythic)

---

## 2. กลไกการสุ่มจำนวนช่องและเงื่อนไขการดรอป (Slot Generation & Drop Conditions)

การได้รับคันเบ็ดในเกมมาจากหลายแหล่ง โดยแต่ละแหล่งจะใช้ Drop Condition Profile ที่กำหนดโอกาสการเกิดช่องและเกรดขั้นต่ำแตกต่างกัน

### กฎการสุ่มช่อง (Slot Allocation Rules):
- คันเบ็ดระดับ Uncommon ขึ้นไปเท่านั้นที่จะมีโอกาสสุ่มได้ Modifier (Common เป็นเบ็ดเริ่มต้น จะไม่มี Mod)
- การออกของช่อง Prefix และ Suffix จะแยกคำนวณอิสระต่อกัน:
  - Prefix Roll: มีโอกาสได้ 0, 1 หรือ 2 ช่อง
  - Suffix Roll: มีโอกาสได้ 0, 1 หรือ 2 ช่อง

### โปรไฟล์เงื่อนไขการดรอป (Drop Condition Profiles):

1. Standard Shop (ซื้อจากร้านค้าทั่วไป):
   - Prefix Chance: 0 ช่อง 50%, 1 ช่อง 45%, 2 ช่อง 5%
   - Suffix Chance: 0 ช่อง 50%, 1 ช่อง 45%, 2 ช่อง 5%
   - Attribute Rarity Floor: Common
   - Attribute Rarity Ceiling: Rare
   - Cap Breaker Chance: 0%

2. Normal Fishing Catch / Treasure Chest (ตกได้จากน้ำหรือเปิดหีบ):
   - Prefix Chance: 0 ช่อง 25%, 1 ช่อง 60%, 2 ช่อง 15%
   - Suffix Chance: 0 ช่อง 25%, 1 ช่อง 60%, 2 ช่อง 15%
   - Attribute Rarity Floor: Common
   - Attribute Rarity Ceiling: Epic
   - Cap Breaker Chance: 5% (เฉพาะเมื่อสุ่มได้ระดับ Rare หรือ Epic)

3. Deep Sea & Hotspot Fishing (จุดตกปลาน้ำลึกและบ่อพิเศษ):
   - Prefix Chance: 0 ช่อง 10%, 1 ช่อง 60%, 2 ช่อง 30%
   - Suffix Chance: 0 ช่อง 10%, 1 ช่อง 60%, 2 ช่อง 30%
   - Attribute Rarity Floor: Uncommon
   - Attribute Rarity Ceiling: Legendary
   - Cap Breaker Chance: 15%

4. Boss Raid Reward (รางวัลปราบบอส Co-op):
   - Prefix Chance: 1 ช่อง 50%, 2 ช่อง 50% (การันตีอย่างน้อย 1 ช่อง)
   - Suffix Chance: 1 ช่อง 50%, 2 ช่อง 50% (การันตีอย่างน้อย 1 ช่อง)
   - Attribute Rarity Floor: Rare
   - Attribute Rarity Ceiling: Mythic
   - Cap Breaker Chance: 35%

5. Quest Milestone / Season Event (รางวัลเควสและอีเวนต์พิเศษ):
   - ปรับแต่งได้ตามเงื่อนไขเควส เช่น:
     - เควสการันตี 2 Prefix + 2 Suffix เต็ม 4 ช่อง
     - การันตีมี Attribute สาย Cap Breaker อย่างน้อย 1 ช่อง
     - เปิดสถานะ Pure Blessing (สุ่มเฉพาะค่า 0 ถึง +N ไม่ติดลบ)

---

## 3. ระบบขยายเพดานสเตตัสสูงสุด (Stat Max Cap Breaker / Overcap System)

### ปัญหาที่ต้องแก้ไข (Design Problem):
ในเกม Aura Fishing สเตตัสหลักใน `StatDefs.luau` หลายตัวมีเพดานค่าสูงสุดตายตัว (Hard Cap) เพื่อคุมสมดุลของมินิเกม:
- CatchBarSize: Base 0.22, Cap 0.60 (60% ของความสูงหลอด)
- Resilience: Base 0.00, Cap 0.90 (ลดแรงกระชากและลดเกจ 90%)
- FishStability: Base 0.00, Cap 0.80 (ทำให้ปลาอยู่นิ่ง 80%)
- BiteSpeed: Base 0.00, Cap 0.80 (ลดเวลารอปลากินเบ็ด 80%)
- AutoSpeed: Base 0.00, Cap 0.75 (ลดรอบตกออโต้ 75%)
- OfflineCapHours: Base 4 ชม., Cap 48 ชม.

เมื่อผู้เล่นเข้าสู่ช่วง End-game สเตตัสเหล่านี้มักจะชนเพดาน ทำให้ค่าสเตตัสที่ได้เพิ่มจากคันเบ็ดระดับสูงหรือการตีบวกกลายเป็นศูนย์เปล่า

### กลไก Cap Breaker (การทะลุเพดาน):
ระบบจะเพิ่ม Attribute ประเภทพิเศษที่ทำหน้าที่ **บวกเพิ่มเข้าไปในค่า Max Cap ของสเตตัสนั้นๆ โดยตรง**
- นิยาม Stat เป้าหมาย: ใช้คีย์รูปแบบ `Max<StatName>` เช่น `MaxCatchBarSize`, `MaxResilience`, `MaxAutoSpeed`
- การคำนวณในสูตร Stats.Compute:
  - BaseMax = StatDefs[stat].Max
  - BonusCap = ModStats["Max" .. stat] or 0
  - EffectiveMax = BaseMax + BonusCap
  - ClampedValue = math.clamp(RawTotal, StatDefs[stat].Min or 0, EffectiveMax)

### การกำหนด Rarity ที่เหมาะสมและการสเกล (Rarity & Scale Calibration):
เพดานสเตตัสส่งผลต่อระบบการเล่นสูงมาก จึง **ห้ามอยู่ในระดับ Common หรือ Uncommon** เด็ดขาด และต้องมีการสเกลตัวเลขที่รัดกุมตามความอ่อนไหวของแต่ละสเตตัส:

1. Rare Tier (Minor Cap Breaker - เพิ่มเพดานระดับเริ่มต้น):
   - สเกล: +0.02 ถึง +0.04 (ช่วงสุ่ม -0.02 ถึง +0.04)
   - ผลลัพธ์: เช่น ขยาย CatchBarSize จาก 0.60 เป็น 0.64

2. Epic Tier (Moderate Cap Breaker - เพิ่มเพดานระดับกลาง):
   - สเกล: +0.03 ถึง +0.06 (ช่วงสุ่ม -0.03 ถึง +0.06)
   - ผลลัพธ์: เช่น ขยาย FishStability จาก 0.80 เป็น 0.86

3. Legendary Tier (Major Cap Breaker - เพิ่มเพดานระดับสูง):
   - สเกล: +0.05 ถึง +0.09 (ช่วงสุ่ม -0.04 ถึง +0.09)
   - ผลลัพธ์: เช่น ขยาย AutoSpeed จาก 0.75 เป็น 0.82

4. Mythic Tier (Transcendent Limit Break - ทะลุขีดจำกัดระดับตำนาน):
   - สเกล: +0.08 ถึง +0.12 (ช่วงสุ่ม -0.05 ถึง +0.12)
   - ผลลัพธ์: เช่น ขยาย CatchBarSize ทะลุเป็น 0.72 (เกือบ 3 ใน 4 ของหลอดมินิเกม)

### เพดานความปลอดภัยเด็ดขาด (Absolute Safety Ceiling):
เพื่อป้องกันไม่ให้บั๊กหรือมินิเกมพัง (เช่น หลอดจับปลาครอบทั้งจอ หรือเกจไม่ลดเลย 100%):
- Resilience Absolute Cap: 0.95 (ห้ามถึง 1.00 เด็ดขาด เพื่อให้เกจยังมีการขยับลดได้)
- AutoSpeed Absolute Cap: 0.85 (ห้ามเกิน 85% เพื่อป้องกันการตกถี่ยิบระดับสปีดแฮก)
- CatchBarSize Absolute Cap: 0.75 (สูงสุด 75% ของหน้าจอ)

---

## 4. กลไกการสุ่มค่าตัวเลขทั้งบวกและลบ (-N ~ +N Value Rolling)

เพื่อสร้างความลึกในการเล่นและการตามล่าหา God Roll ทุก Attribute จะมีช่วงค่าต่ำสุดที่เป็นลบได้:

1. Flawed / Cursed Roll (ค่าติดลบ):
   - สุ่มได้ตัวเลขติดลบ เช่น `Luck -5%` หรือในกลุ่ม Cap Breaker เช่น `Max Catch Bar -3%`
   - UI จะแสดงผลชิปเป็นสีแดงเตือนภัย (T.Bad)
   - ทำหน้าที่เป็นแรงขับเคลื่อนให้ผู้เล่นนำคันเบ็ดไปเข้าสู่ระบบ Rod Fusion เพื่อสลายคันอื่นมาย้ายทับ Mod ที่ติดลบออก
2. Standard Positive Roll (ค่าบวกทั่วไป):
   - สุ่มได้ค่าบวกปกติ ช่วยเสริมพลังตามสเตตัส
3. God Roll (แตะเพดานสูงสุดของช่วง):
   - สุ่มได้ค่าสูงสุดของ Attribute นั้นๆ เพิ่มมูลค่าการซื้อขายและใช้งานอย่างมหาศาล

---

## 5. ตารางแคตตาล็อก Attribute ฉบับสมบูรณ์ (Master Attribute Catalog)

### หมวด Prefix (คำนำหน้า)

| Id | Name | Target Stat | Rarity | Type | Value Range | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `p_swift` | Swift | BiteSpeed | Common | Normal | -0.04 ~ +0.08 | เร่งเวลาปลากินเบ็ด (-4% ถึง +8%) |
| `p_firm` | Firm | ReelPower | Common | Normal | -0.10 ~ +0.20 | กำลังดึงรอกพื้นฐาน |
| `p_long` | Reaching | CastRange | Common | Normal | -2 ~ +5 | ระยะการเหวี่ยงเบ็ด (studs) |
| `p_keen` | Keen | BiteSpeed | Uncommon | Normal | -0.06 ~ +0.14 | เพิ่มความไวในการตอบสนองของเหยื่อ (-6% ถึง +14%) |
| `p_sturdy` | Sturdy | ReelPower | Uncommon | Normal | -0.15 ~ +0.35 | แรงดึงรอกที่มั่นคง |
| `p_fortunate` | Fortunate | Luck | Uncommon | Normal | -0.05 ~ +0.12 | โชคพื้นฐานในการหาปลาหายาก (-5% ถึง +12%) |
| `p_lucky` | Lucky | Luck | Rare | Normal | -0.08 ~ +0.22 | โชคลาภเหนือน่านน้ำ (-8% ถึง +22%) |
| `p_mighty` | Mighty | ReelPower | Rare | Normal | -0.20 ~ +0.55 | แรงดึงรอกระดับสูง |
| `p_brisk` | Brisk | AutoSpeed | Rare | Normal | -0.04 ~ +0.10 | ลดเวลารอระหว่างรอบตกออโต้ (-4% ถึง +10%) |
| `p_limitless_bite` | Uncapped | MaxBiteSpeed | Rare | Cap Breaker | -0.02 ~ +0.04 | ขยายเพดานความเร็วปลากินเบ็ด (+2% ถึง +4%) |
| `p_blessed` | Blessed | Luck | Epic | Normal | -0.10 ~ +0.38 | อานุภาพโชคลาภขั้นสูง (-10% ถึง +38%) |
| `p_rapid` | Rapid | AutoSpeed | Epic | Normal | -0.06 ~ +0.18 | ร่นระยะเวลาการตกอัตโนมัติ (-6% ถึง +18%) |
| `p_overclock` | Overclocked | MaxAutoSpeed | Epic | Cap Breaker | -0.03 ~ +0.05 | ขยายเพดานความเร็วตกออโต้ (จาก 75% เป็น 80%) |
| `p_celestial` | Celestial | Luck | Legendary | Normal | -0.12 ~ +0.65 | พลังโชคแห่งดวงดาว (-12% ถึง +65%) |
| `p_hyper` | Hyper | AutoSpeed | Legendary | Normal | -0.08 ~ +0.25 | อัตราเร่งการตกออโต้ระดับสูง (-8% ถึง +25%) |
| `p_transcendent_speed` | Warp | MaxAutoSpeed | Legendary | Cap Breaker | -0.04 ~ +0.08 | ทะลุขีดจำกัดเพดานตกออโต้ (แตะเพดาน 83%) |
| `p_divine` | Divine | Luck | Mythic | Normal | -0.15 ~ +1.00 | สเตตัสโชคระดับเทวตำนาน (สูงสุด +100%) |
| `p_singularity` | Singularity | MaxAutoSpeed | Mythic | Cap Breaker | -0.04 ~ +0.10 | ทะลวงเพดานตกออโต้สู่เพดานสูงสุด (จำกัดไม่เกิน 85%) |

### หมวด Suffix (คำต่อท้าย)

| Id | Name | Target Stat | Rarity | Type | Value Range | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `s_of_grip` | of Grip | CatchBarSize | Common | Normal | -0.02 ~ +0.04 | ขยายขนาดแถบจับปลา (-2% ถึง +4% ของหลอด) |
| `s_of_ease` | of Calm | FishStability | Common | Normal | -0.04 ~ +0.08 | ปลานิ่งขึ้นเล็กน้อยระหว่างเย่อ (-4% ถึง +8%) |
| `s_of_bargain` | of Commerce | SellMultiplier | Common | Normal | -0.05 ~ +0.10 | เพิ่มราคาขายปลา (-5% ถึง +10%) |
| `s_of_tension` | of Tension | Resilience | Uncommon | Normal | -0.05 ~ +0.12 | ชะลอการลดลงของเกจเมื่อปลาหลุด (-5% ถึง +12%) |
| `s_of_width` | of Scope | CatchBarSize | Uncommon | Normal | -0.03 ~ +0.07 | เพิ่มพื้นที่แถบจับปลา (-3% ถึง +7%) |
| `s_of_wisdom` | of Insight | XPMultiplier | Uncommon | Normal | -0.05 ~ +0.15 | ได้รับค่าประสบการณ์เพิ่มขึ้น (-5% ถึง +15%) |
| `s_of_iron` | of Iron | Resilience | Rare | Normal | -0.08 ~ +0.20 | สายเอ็นทนทาน ลดแรงกระชากสูง (-8% ถึง +20%) |
| `s_of_stillness` | of Stillness | FishStability | Rare | Normal | -0.07 ~ +0.18 | สะกดการดิ้นของปลาให้อยู่นิ่ง (-7% ถึง +18%) |
| `s_of_wealth` | of Prosperity | SellMultiplier | Rare | Normal | -0.08 ~ +0.25 | เพิ่มมูลค่าเหรียญจากการขายปลา (-8% ถึง +25%) |
| `s_of_expansion` | of Extension | MaxCatchBarSize | Rare | Cap Breaker | -0.02 ~ +0.04 | ขยายเพดานขนาดแถบจับปลา (จาก 60% เป็น 64%) |
| `s_of_mutation` | of Anomaly | MutationChance | Epic | Normal | -0.01 ~ +0.03 | เพิ่มโอกาสให้ปลาติด Mutation (-1% ถึง +3%) |
| `s_of_pearls` | of Tides | PearlRate | Epic | Normal | -0.08 ~ +0.30 | เร่งอัตราการผลิตไข่มุกในบ่อปลา (-8% ถึง +30%) |
| `s_of_unyielding` | of the Unbroken | MaxResilience | Epic | Cap Breaker | -0.02 ~ +0.04 | ขยายเพดานความทนทานสายเอ็น (จาก 90% เป็น 94%) |
| `s_of_deep_calm` | of Serenity | MaxFishStability | Epic | Cap Breaker | -0.03 ~ +0.06 | ขยายเพดานความนิ่งของปลา (จาก 80% เป็น 86%) |
| `s_of_radiance` | of Radiance | MutationChance | Legendary | Normal | -0.015 ~ +0.06 | เพิ่มโอกาสกลายพันธุ์อย่างก้าวกระโดด (-1.5% ถึง +6%) |
| `s_of_the_abyss` | of the Abyss | PearlRate | Legendary | Normal | -0.12 ~ +0.60 | พลังแห่งก้นทะเล เร่งผลิตไข่มุกมหาศาล (-12% ถึง +60%) |
| `s_of_the_titan` | of the Titan | MaxCatchBarSize | Legendary | Cap Breaker | -0.03 ~ +0.08 | ทะลวงเพดานหลอดจับขนาดใหญ่ (ขยายเพดานเป็น 68%) |
| `s_of_eternity` | of Eternity | MutationChance | Mythic | Normal | -0.02 ~ +0.12 | พลังแห่งการกลายพันธุ์ระดับสูงสุด (-2% ถึง +12%) |
| `s_of_the_leviathan` | of the Leviathan | MaxCatchBarSize | Mythic | Cap Breaker | -0.04 ~ +0.12 | ทะลวงเพดานหลอดจับสู่ขนาดมหึมา (ขยายเป็น 72%, Max 75%) |
| `s_of_adamant` | of Adamant | MaxResilience | Mythic | Cap Breaker | -0.02 ~ +0.05 | เพดานความเหนียวแน่นสูงสุดของสายเอ็น (Max 95%) |

---

## 6. แนวทางการเขียนโค้ดสำหรับ Coding Agent (Implementation Guide)

เมื่อ Coding Agent เริ่มเขียนสคริปต์ ให้ปฏิบัติตามแนวทางต่อไปนี้:

1. การเก็บ Definition:
   - นำ Attribute ทั้งหมดและ Drop Condition Profiles ไปเขียนลงใน `src/shared/Config/ModifierDefs.luau`
   - เพิ่มฟิลด์ `Rarity: string?` ใน `ModEntry` ของ `src/shared/Items/ItemTypes.luau`

2. การประมวลผลเพดานใน `src/shared/Stats.luau` (`Stats.Compute`):
   - ทำการรวบรวมโบนัสเพดานก่อน (`BonusCap`):
     ```lua
     local capBonuses = {}
     for statKey, val in modStats do
         if string.sub(statKey, 1, 3) == "Max" then
             local target = string.sub(statKey, 4)
             capBonuses[target] = (capBonuses[target] or 0) + val
         end
     end
     ```
   - เมื่อทำการ Clamp ค่าสเตตัส ให้ขยายเพดานตาม `BonusCap` แต่ไม่เกิน Absolute Ceiling:
     ```lua
     local baseMax = def.Max or math.huge
     local bonusMax = capBonuses[statName] or 0
     local effectiveMax = baseMax + bonusMax
     -- Absolute safety clamps
     if statName == "Resilience" then effectiveMax = math.min(0.95, effectiveMax) end
     if statName == "AutoSpeed" then effectiveMax = math.min(0.85, effectiveMax) end
     if statName == "CatchBarSize" then effectiveMax = math.min(0.75, effectiveMax) end
     
     finalStats[statName] = math.clamp(rawTotal, def.Min or 0, effectiveMax)
     ```

3. การแสดงผลใน `src/shared/Util/Format.luau` และ `src/client/UI/ItemDetail.luau`:
   - แสดงผล Attribute Cap Breaker ด้วยข้อความเฉพาะ เช่น `+4% Max Catch Bar` หรือ `+5% Max Auto Wait`
   - ชิปของออฟชั่นที่มีค่าติดลบ (Cursed) ให้ปรับพื้นหลังเป็นสีแดง `T.Bad`
