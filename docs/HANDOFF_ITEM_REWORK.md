# Handoff: Item rework + Bag Upgrade (2026-11-22)

สำหรับ Agent ตัวถัดไป. แผนต้นฉบับ: `docs/ITEM_REWORK_PLAN.md`. รายการทดสอบ: C29 ใน `docs/TASKS.md`.
กฎโปรเจกต์ (ภาษาไทยกับผู้ใช้, โค้ดอังกฤษ, ห้ามเครื่องหมายถูก/bullet/emoji ใน UI, Figma ก่อนแก้ UI) อยู่ใน `CLAUDE.md`.

## สถานะ
- โค้ดเสร็จ, `node tools/check.mjs` ผ่าน. commit `23a49b6` (item rework). งาน Bag Upgrade popup + Shop ยังไม่ commit.
- ยังไม่เคยทดสอบใน Play (Studio ไม่ได้เชื่อม MCP ตอนทำ). ต้องทำตามข้อทดสอบ C29 ข้อ 1-13 ก่อนเชื่อผล.

## โมเดลข้อมูล (สำคัญ)
- `profile.Bag` = รายการเรคคอร์ดธรรมดา (ห้ามใส่ metatable: โปรไฟล์ถูกเซฟ DataStore และส่งไป client ทั้งก้อน).
  ฟิลด์: `UUID, Id, Kind("Fish"|"Rod"|"Line"|"Treasure"), Count?(หีบ), Bound?, Tradable?, Sellable?, New?, Weight, Mutation, Tags, Value (ปลา), Enhance, Prefixes, Suffixes (คัน/สาย)`. ชนิดอยู่ใน `src/shared/Items/ItemTypes.luau`.
- ตรรกะทั้งหมด: `src/shared/Items/ItemContainer.luau` (`Shared.Inventory` เป็น alias). คำนิยามไอเทม: `Registry.Items`, `Registry.GetItem`, `Registry.GetItemsByCategory`, `Registry.GearRarity`.
- `profile.Equipped.Rods/Lines` = UUID ของไอเทมใน Bag. คัน/สายที่สวมอยู่กินช่องเหมือนของอื่น (แก้ภายหลัง: ทุกอย่างนับ ยกเว้น Aura) (`Inventory.Used`). `Equipped.Bags/Baits` ยังเป็น id config. กระเป๋า = `Owned.Bags` (บันไดอัปเกรดถาวร ไม่กินช่อง). เหยื่อ = `Consumables.Baits`.
- Enhance อยู่ที่ตัวไอเทม (`item.Enhance`), `profile.Enhance` ถูกลบ. `Stats.Collect` อ่านคัน/สายที่สวม + mods ของคัน.
- ตู้ปลา: `Aquarium.Fish` เก็บเรคคอร์ดปลาเดิมทั้งตัว (UUID คงอยู่). `Aquarium.State` ยังส่งฟิลด์ `Uid` (= UUID) ให้ client.
- เซฟ `SCHEMA_VERSION = 6`: `DataService.sanitize` ล้าง Bag/Owned/Equipped/Aquarium.Fish/Enhance ครั้งเดียว (เก็บเหยื่อที่สวม), คืนของ Exclusive (Starter Pack) เป็นไอเทม Bound, `ensureGear` สร้างคัน+สายเริ่มต้นต่อโปรไฟล์ (ห้ามใส่ใน TEMPLATE เพราะ UUID ซ้ำ).

## กติกาที่ตัดสินกับผู้ใช้
- ปลา/คัน/สายไม่รวมกอง, หีบรวมได้ 5. ซื้อคัน/สายซ้ำได้ ต้องมีช่องว่าง 1 ช่อง; ซื้อแล้วสวมให้เมื่อดีกว่า (Order สูงกว่า) ที่สวมอยู่.
- ขายคืนคัน/สาย = 40% x (ราคาซื้อ + เหรียญที่ลง Enhance) (`GameConfig.Inventory.GearSellFraction`). ราคา 0, Exclusive, ราคาเป็น Gems ขายไม่ได้. ห้ามขายของที่สวม.
- ความจุกระเป๋า 10/16/24/36/50 + Infinite pass (เดิม 6/10/15/20/30) ใน `Config/Equipment.luau`.
- Remotes: `SellItem(uuid)` แทน `SellStack`; `OpenTreasure/OpenAllTreasure/Enhance(uuid)`; `Equip("Rods"|"Lines", uuid)`; `PutInTank` ยังรับ `{Id, Mutation, Count}` (เอาปลามูลค่าต่ำสุดก่อน).
- Bag Upgrade: ซื้อได้ทางเดียวคือ popup ใน Inventory (ปุ่ม UPGRADE ข้างตัวนับช่อง); แท็บ Bags ถูกเอาออกจาก Shop (`MenuFill.shopCategories`).

## Figma (ทำแล้ว)
- Screen 18 F4 "Bag Upgrade (coins)" node `3600:50618` (modal `3600:50637`): แก้เลขช่อง ladder เป็น 10/16/24/36/50 และหัวข้อเป็น "36 slots -> 50 slots" แล้ว (ผ่าน channel `aura-fishing`).

## งานที่เหลือ (เรียงตามความสำคัญ)
1. ทดสอบใน Play ตาม C29 (ข้อ 1-13) และแก้บั๊กที่เจอ. จุดเสี่ยง: DataSync ส่งทั้งโปรไฟล์ (ปลาไม่รวมกอง = ข้อมูลเยอะใน Infinite Bag), ItemDetail/MenuFill เป็น `--!nonstrict` เช็คชนิดไม่ครบ.
2. popup Bag Upgrade ให้ตรง Figma เต็มที่: ปุ่ม UPGRADE ใน Figma มีเส้นคั่น + ไอคอนเหรียญ + ราคาย่อ (250k) แต่เกมยังเป็นข้อความ "UPGRADE 250,000". แก้ที่ `src/client/UI/Screens/Inventory.luau` (ฟังก์ชัน `bagUpgrade`) แล้ว re-bake ใน Studio, แล้วปรับ `InventoryController.openUpgrade` (`u.Confirm`).
3a. ดีไซน์ Mod ของคันเบ็ด: Figma node `3778:897` (หน้าเดียวกับ Screen 18 F4, x=1420,y=1100) = บล็อก PREFIX 2 แถว + SUFFIX 2 แถว แทนแถว 3 socket ล็อกใน `UI/Screens/ItemDetail.luau` (ฟังก์ชัน `modifiers`) ยังเป็นข้อเสนอ รออนุมัติ แล้วค่อยแก้โค้ด (`UI/ItemDetail.luau` modBadges -> render แถว, เอา mod ออกจากแถว Meta) และ re-bake.
3. หน้าตา ItemDetail (ป้าย Tags, บรรทัด Prefix/Suffix, ปุ่ม SELL ของเกียร์, แถว Shop "x2 (worn)") ยังไม่ได้ออกแบบใน Figma ก่อน. ควรทำ Figma แล้วเก็บเข้า bake.
4. ยังไม่ทำ: สุ่ม Mod ให้คันเบ็ด (ช่อง Prefix 2/Suffix 2 มีแล้วแต่ว่าง), Rod Fusion, ระบบเทรดจริง (มี `Inventory.CanTrade` + สถานะ Bound), คลาส OOP แยกไฟล์ตาม §4 ของแผน (ตั้งใจใช้ตาราง plain; เสนอ wrapper ได้ถ้าผู้ใช้ต้องการ).
5. ก่อน publish: เซฟ v6 ล้างไอเทมผู้เล่นทุกคนแบบไม่คืนเงิน (ตามแผน §2). ให้ผู้ใช้ตัดสินใจถ้ามีผู้เล่นจริงแล้ว.

## ไฟล์หลักที่แก้
Shared: `Items/ItemContainer.luau, Items/ItemTypes.luau, Registry.luau, Stats.luau, Enhance.luau, Aquarium.luau, Remotes.luau, Config/Equipment.luau, Config/GameConfig.luau`.
Server: `DataService, ShopService, FishingService, AquariumService, MonetizationService, DevService`.
Client: `UI/ItemDetail, UI/ItemSlots, UI/MenuFill, Controllers/InventoryController, CharacterController, EconomyController`.
หลังแก้ TASKS.md ให้รัน `node qa/tools/build.mjs` และ commit `qa/data/qadata.json`.

## อัปเดตล่าสุด
- Bag Upgrade popup: 2 ปุ่ม, MAX เมื่อสุดบันไดหรือมี pass. Figma F5 ใหม่ node `3779:969` (F5 เดิมเปลี่ยนชื่อเป็น OLD).
- ปุ่ม action การ์ดไอเทม: แถวละไม่เกิน 2 ปุ่ม (`UI/ItemDetail.luau` render). Figma: การ์ด Rod (owned) node `3600:50788`.
- Mod ของคันเบ็ด: PREFIX 2 + SUFFIX 2 แถว สร้างตอนรันใน `UI/ItemDetail.luau` (Figma `3778:897`). ไม่ต้อง re-bake.
- กฎจากผู้ใช้: ข้อความสั้น ไม่ใช้ตัวอักษร | ทั้งในแชทและ UI.
- Figma mod design now inside Item Card A (3600:50783) and the Inventory/Character rod cards; 3778:897 is the old proposal.
- Mod design chosen: option D Chips (Figma 3779:24001 shows all 6). Code in UI/ItemDetail.luau (ModChips); Figma cards updated.
