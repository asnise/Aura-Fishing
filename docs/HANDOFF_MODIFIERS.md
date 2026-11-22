# Handoff: Rod Modifier System & Cap Breaker Engine (2026-11-22)

เอกสารส่งต่องานสำหรับ Coding Agent ในการเริ่มเขียนโค้ดพัฒนาระบบ Modifier ของคันเบ็ด (Prefix / Suffix), การสุ่มค่า -N ถึง +N, ระบบขยายเพดานสเตตัส (Stat Max Cap Breaker) และการเตรียมต่อยอดสู่ Rod Fusion

เอกสารอ้างอิงหลัก:
- สเปกระบบฉบับสมบูรณ์: `docs/MODIFIER_SYSTEM_SPEC.md`
- มติการออกแบบเกม: `docs/DESIGN_DECISIONS_2026-11-21.md` (ข้อ 3)
- แผนรีเวิร์กไอเทม: `docs/ITEM_REWORK_PLAN.md`
- รายการงานทดสอบ: C30 ใน `docs/TASKS.md`

---

## 1. สถานะงานปัจจุบัน (Current State)

เอกสารสเปกและพิมพ์เขียวการทำงานถูกจัดเตรียมไว้ครบถ้วนใน `docs/MODIFIER_SYSTEM_SPEC.md` โดยยังไม่มีการแก้ไขไฟล์สคริปต์ใน `src/` เพื่อให้ Coding Agent ได้เริ่มดำเนินการเขียนโค้ดตามลำดับขั้นตอนที่ถูกต้องอย่างเป็นระบบ

---

## 2. ขั้นตอนการทำงานสำหรับ Coding Agent (Implementation Roadmap)

### ขั้นที่ 1: กำหนดข้อมูลและ Types ใน Shared
1. อัปเดต `src/shared/Items/ItemTypes.luau`:
   - เพิ่มฟิลด์ `Rarity: string?` ใน `ModEntry`
2. สร้าง `src/shared/Config/ModifierDefs.luau`:
   - บันทึก PrefixDefs, SuffixDefs (รวม Attribute ปกติและ Attribute สาย Cap Breaker ตาม Catalog ในสเปก)
   - บันทึก DropConditionProfiles (Shop, Fishing, DeepSea, BossRaid, QuestPure)
3. ลงทะเบียนใน `src/shared/Registry.luau`:
   - ผูก `Registry.ModifierDefs` พร้อม validation ตรวจสอบความถูกต้องของสเตตัสและช่วงตัวเลข

### ขั้นที่ 2: สร้างระบบคำนวณสเตตัสและการขยายเพดาน (Stats.Compute Overcap)
1. ใน `src/shared/Stats.luau`:
   - ปรับ `Stats.Compute` ให้อ่านออฟชั่นกลุ่ม `Max<StatName>` จาก `modStats` เพื่อนำมาบวกขยายเพดาน `EffectiveMax = def.Max + bonusMax`
   - ใส่ Absolute Safety Ceiling:
     - Resilience ไม่เกิน 0.95
     - AutoSpeed ไม่เกิน 0.85
     - CatchBarSize ไม่เกิน 0.75
2. ใน `src/shared/Util/Format.luau`:
   - ปรับ `Format.Stat` ให้รองรับค่าติดลบ เช่น `-5% Luck` และรองรับสเตตัสกลุ่ม Cap Breaker เช่น `+4% Max Catch Bar`

### ขั้นที่ 3: สร้าง Rolling Engine สำหรับสุ่มออฟชั่น
1. สร้าง `src/shared/Items/ModifierRoll.luau`:
   - ฟังก์ชัน `RollSlots(profileName, rng)`: สุ่มจำนวนช่อง 0, 1 หรือ 2 ช่องแยก Prefix / Suffix
   - ฟังก์ชัน `RollModifiers(profileName, rng)`: สุ่ม Attribute ตาม Rarity Weight และสุ่มค่า Value ในช่วง `[MinValue, MaxValue]` พร้อมปัดเศษทศนิยม
2. ใน `src/shared/Items/ItemContainer.luau`:
   - ปรับ `Inventory.NewGear(categoryId, itemId, dropProfile)`: เมื่อสร้างเบ็ดระดับ Uncommon ขึ้นไปและมี dropProfile ให้เรียก `ModifierRoll.RollModifiers` สุ่มออฟชั่นติดตัว

### ขั้นที่ 4: เชื่อมต่อบริการ Server และคำสั่ง Dev
1. ใน `src/server/Services/ShopService.luau`:
   - เมื่อผู้เล่นซื้อคันเบ็ด ให้ส่งโปรไฟล์ `"Shop"` เข้า `Inventory.NewGear`
2. ใน `src/server/Services/DevService.luau`:
   - ปรับคำสั่ง `give Rods <id> [profile]` ให้รองรับการส่งชื่อโปรไฟล์สำหรับทดสอบ (เช่น `Shop`, `BossRaid`, `QuestPure`)

### ขั้นที่ 5: ปรับปรุงการแสดงผล UI
1. ใน `src/client/UI/ItemDetail.luau`:
   - ตรวจสอบ `mod.Value`: หากมีค่าติดลบ (< 0) ให้ปรับพื้นหลังชิปเป็นสีแดงเตือนภัย `T.Bad` แทนสีปกติ (ฟ้า/ม่วง)

### ขั้นที่ 6: ต่อยอดสู่ระบบ Rod Fusion (Next Phase)
- สร้าง Remote `FuseRods` ใน `Remotes.luau`
- ตรวจสอบเงื่อนไขคันเบ็ดโมเดลเดียวกัน ทำลายคันรอง และสลับ Mod บรรทัดที่ต้องการไปยังคันหลัก

---

## 3. ขั้นตอนการทดสอบหลังเขียนโค้ดเสร็จ (QA Test Steps)

1. รันการตรวจสอบระบบ:
   ```powershell
   node tools/check.mjs
   ```
   ผลลัพธ์ต้องผ่าน 100% ไร้ error และไม่มีอักขระต้องห้าม
2. เปิด Roblox Studio กด Play (F5):
   - เปิด Dev Console หรือกด F2 พิมพ์: `give Rods CarbonRod BossRaid`
   - ตรวจสอบในกระเป๋า (กด B): เปิดการ์ดคันเบ็ดดูช่อง Mod ว่าแสดงชิปสเตตัสถูกต้อง
   - หากสุ่มได้ค่าติดลบ ชิปต้องแสดงสีแดงเตือนภัย
   - หากสุ่มได้ Cap Breaker (เช่น `Max Catch Bar`) ให้ทดสอบเข้ามินิเกมว่าขนาดหลอดขยายเกินเพดานเดิม 60% ได้ตามจริง

## อัปเดต (2026-11-22)
ขั้น 1-5 ทำแล้ว (ดู C30 ใน docs/TASKS.md). เหลือขั้น 6 Rod Fusion และการเรียกโปรไฟล์ Fishing, DeepSea, BossRaid จากแหล่งดรอปจริง. Cap Breaker ใช้ชื่อ Stat รูปแบบ Max<Stat> ที่ Stat เป้าหมายต้องอยู่ใน StatDefs (MaxDepth ไม่ใช่ Cap Breaker).
Rod Fusion: ค่าใช้จ่ายและโอกาสล้มเหลวอยู่ใน docs/ROD_FUSION_COST.md (ขั้น 6).
Rod Fusion ทำแล้ว (C31): FusionService, FusionController, Items/Fusion, GameConfig.Fusion. เหลือ Guard (Gems) และตรวจระยะ NPC ฝั่งเซิร์ฟเวอร์.
อัปเดตล่าสุด: ดรอปคันเบ็ดจากตกปลา/หีบ (Items/RodDrop), ราคาขายคืนรวม mod, Fusion Guard (Gems) และตรวจระยะ NPC ทำแล้ว. เหลือแค่แหล่งดรอปของโปรไฟล์ BossRaid/QuestPure ซึ่งรอระบบบอสและเควสไอเทม (เรียก RodDrop.Create(profile, level, rng) ได้เลย).
