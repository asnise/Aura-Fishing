# Handoff: Items, Modifiers, Rod Fusion (2026-11-22)

ไฟล์เดียวสำหรับ Agent ตัวถัดไป. รายละเอียดเฉพาะเรื่อง:
`docs/HANDOFF_ITEM_REWORK.md`, `docs/HANDOFF_MODIFIERS.md`, `docs/MODIFIER_SYSTEM_SPEC.md`, `docs/ROD_FUSION_COST.md`.
ข้อทดสอบทั้งหมดอยู่ใน `docs/TASKS.md` หัวข้อ C29 (ไอเทม), C30 (Modifier), C31 (Fusion).

## สถานะ
- โค้ดเสร็จและ `node tools/check.mjs` ผ่านทั้งหมด. ยังไม่เคยทดสอบใน Play (Studio ไม่ได้เชื่อม MCP ระหว่างทำ).
- ยังไม่ได้ commit งานหลัง `23a49b6` (Bag Upgrade, HUD 5 ทางลัด, Modifier, Fusion, ดรอปเบ็ด). ไฟล์ใหม่และที่แก้ดู `git status`.
- ลำดับแนะนำ: เปิด Studio, เล่นตามข้อทดสอบ C29 ถึง C31, แก้บั๊ก, แล้ว commit.

## สิ่งที่มีแล้ว
- Item rework: ไอเทมเป็นเรคคอร์ด UUID ใน `profile.Bag` (ปลาไม่รวมกอง, คัน/สายซื้อซ้ำ ขายคืน Enhance รายชิ้น), เซฟ v6 ล้างไอเทมเก่า. โค้ดหลัก `src/shared/Items/ItemContainer.luau` (`Shared.Inventory` เป็น alias).
- Bag Upgrade: popup 2 ปุ่ม ซื้อที่ Inventory เท่านั้น, MAX เมื่อสุดบันไดหรือมี Infinite pass (Infinite ขายที่ Store).
- HUD ซ้าย: 5 ทางลัด Bag, Shop, Auras, Quests, Menu พร้อมจุดแดง (`HUDController.RefreshDots`).
- การ์ดไอเทม: ปุ่ม action แถวละไม่เกิน 2, ปุ่ม Enhance สีม่วงไม่มีราคา, mod แสดงเป็นชิป 4 ช่อง (Prefix ฟ้า, Suffix ม่วง, ค่าติดลบแดง).
- Modifier: `Config/ModifierDefs.luau` (Prefix 18, Suffix 20, โปรไฟล์ Shop/Fishing/DeepSea/BossRaid/QuestPure), `Items/ModifierRoll.luau`, Cap Breaker ใน `Stats.Compute` (เพดานเด็ดขาด 0.95/0.85/0.75), `Format.Mod`.
- แหล่งได้คันเบ็ดพร้อม mod: ร้านค้า (Shop), ตกปลา (`GameConfig.RodDrop`, DeepSea เมื่อลึก 200m ขึ้นไปหรือจุดฟอง), หีบสมบัติ (รางวัล Kind "Rod"), Dev `give rods <id> [profile]`. Helper: `Items/RodDrop.luau`.
- ราคาขายคืนคันเบ็ด: 40% ของ (ราคา x (1 + โบนัส mod ตามความหายาก) + เหรียญ Enhance).
- Rod Fusion: `Items/Fusion.luau` (กติกา+ราคา), `FusionService` + remote `FuseRods`, `FusionController` (หน้าต่าง 4 ขั้น + ผลลัพธ์), เปิดจากปุ่ม "Fuse rods" ของ Old Marlin. ล้มเหลว 5% หายแค่คัน Material ไม่หักเงิน, Guard ด้วย Gems การันตีสำเร็จ, เซิร์ฟเวอร์ตรวจระยะ 40 studs จาก Marlin.

## ตัวเลขที่ปรับสมดุลได้ (ไม่ต้องแก้โค้ด)
- `Config/Equipment.luau`: ความจุกระเป๋า 10/16/24/36/50.
- `GameConfig.Inventory`: GearSellFraction 0.4, ModSellBonus, TreasureStackMax.
- `GameConfig.RodDrop`: Chance 0.004, LuckScale, DeepDepth.
- `GameConfig.Fusion`: FeeFraction, RarityMult, PearlCost, FailChance, GuardGems, NpcRange.
- `Config/ModifierDefs.luau`: ช่วงค่าของ mod และน้ำหนักช่องในแต่ละโปรไฟล์.
- `Config/Treasures.luau`: น้ำหนักรางวัลคันเบ็ดในหีบ.

- ของเริ่มต้นฟรี (Driftwood Rod, Cotton Line): มีในตัวแล้วซื้อซ้ำไม่ได้. Shop แสดงปุ่ม Owned สีเทา (`MenuFill`), เซิร์ฟเวอร์ปฏิเสธด้วย "You already have it" (`ShopService.Buy`). Figma: แถว Driftwood Rod ใน 05 Shop Rods (node `3492:21102`) มี note อธิบาย; หน้า Shop Lines ยังไม่มีในดีไซน์ ใช้กติกาเดียวกัน.
- ลบ empty chip ของ mod ออกจากการ์ดไอเทม (เกมซ่อนช่องว่าง, Figma ลบแล้ว). ถ้าคันไม่มี mod เลย ไม่แสดงบล็อก.
- ลบ black overlay หลังหน้า Daily Login, Bag Upgrade และ Offline Reward (ยังรับการกดนอกหน้าต่างอยู่).

- ช่องกระเป๋า: ปลา คันเบ็ด สายเบ็ด (รวมที่สวมอยู่) หีบ และเหยื่อ (1 ช่องต่อชนิด) นับหมด; Aura กับกระเป๋าไม่นับ (`Inventory.Used`). ซื้อเหยื่อชนิดใหม่ตอนเต็มไม่ได้. ถ้ารู้สึกคับให้เพิ่มความจุใน `Config/Equipment`.
- ทดสอบโดยไม่มี Infinite Bag: Dev `revoke pass InfiniteBag` (ปิดค้างแม้ออกแล้วเข้าใหม่), `grant pass InfiniteBag` เปิดกลับ.

## ที่ยังไม่ทำ
- แหล่งดรอปของโปรไฟล์ BossRaid และ QuestPure: ยังไม่มีระบบบอส/เควสไอเทม. เมื่อมีให้เรียก `RodDrop.Create(profile, level, rng)` แล้ว `Inventory.Add`.
- เทียบหน้าตาหน้าต่าง Fusion ในเกมกับ Figma จริง (สร้างด้วยโค้ดใน `FusionController`, ยังไม่เคยเห็นใน Studio).
- ปุ่ม "Fuse rods" แทนที่ "Just chatting" ของ Marlin (หน้าบทสนทนาที่ bake มีได้ 4 ปุ่ม). ถ้าอยากได้ครบ 5 ต้องแก้ `UI/Screens/Dialogue` แล้ว re-bake.
- หน้าตา ItemDetail/Bag Upgrade ที่ต่างจาก Figma: ปุ่ม UPGRADE ใน Figma มีเส้นคั่นและไอคอนเหรียญ แต่เกมเป็นข้อความ (ต้อง re-bake).
- DataSync ส่งทั้งโปรไฟล์: ปลาไม่รวมกองทำให้ข้อมูลโตในกระเป๋า Infinite. ถ้ากระตุกให้ส่งเฉพาะส่วนที่เปลี่ยน.
- เซฟ v6 ล้างไอเทมผู้เล่นทุกคนไม่คืนเงิน. ตัดสินใจก่อน publish ถ้ามีผู้เล่นจริงแล้ว.

## Figma (ไฟล์ Ro-Offline, channel `aura-fishing`)
- Rod Fusion: `Screen 19 - Rod Fusion steps` node `3782:24507` (4 ขั้น, สถานะ Compare, หน้าผลลัพธ์ FUSED/FAILED). ตัวเลือกเก่า `3782:24274` และ `3781:24173` ลบได้.
- Mod ชิป: ตัวเลือก 6 แบบ node `3779:24001`, เลือกแบบ D. การ์ด Rod ใน Item Card A `3600:50783`.
- Bag Upgrade: F4 `3600:50618`, F5 สถานะ MAX `3779:969`.
- เครื่องมือ: `Figma For Roblox/cursor-talk-to-figma-mcp/scripts/figma-run.mjs --channel=aura-fishing <command> <params.json>` (เช่น `build_tree`, `batch`). เติมรูปคันเบ็ด: `python -I tools/art/figma_images.py --root <nodeId>`.
- ข้อควรระวัง: `set_stroke_color` ทำลายขอบหนาด้านล่างของปุ่ม. ใช้ `patch_nodes` กับ `stroke`, `strokeSides: {b: 5}` แทน. ปุ่มมาตรฐาน: สูง 48, มุม 16, ขอบล่างหนา 5. ปุ่มปิดใช้ `Btn Close` ตัวเดียวกับเมนูอื่น.

## ความต้องการของผู้ใช้
- คุยภาษาไทย, โค้ดอังกฤษ. ข้อความสั้น ไม่เยิ่นเย้อ.
- ห้ามใช้ตัวอักษร `|` ทั้งในแชทและข้อความ UI (โค้ดเดิมยังมีเหลือที่หน้าตู้ปลา, Credits, Gacha ถ้าผู้ใช้ขอให้เอาออกทั้งหมด).
- แก้ UI ใน Figma ก่อนเสมอ แล้วค่อยแก้เกม. ปุ่มทุกตัวใช้มาตรฐานเดียวกัน.
- หลังแก้ `docs/TASKS.md` รัน `node qa/tools/build.mjs`.

## เคล็ดลับโค้ด
- โปรไฟล์ถูกเซฟและส่งไป client ทั้งก้อน: ห้ามใส่ metatable ลงในไอเทม.
- ห้ามวนลูป `for _, x in { a or {}, b or {} } do` กับชนิด optional (luau-lsp ฟ้อง union). ใช้ฟังก์ชันช่วยแล้วเช็ค nil.
- Heredoc ใน Bash ที่มีเครื่องหมาย ' อาจพัง: เขียนสคริปต์ผ่านไฟล์แล้วรัน `python -I`.
- ถามก่อนทำลายของที่ลงแรงไปแล้ว: ขายคันที่มี +N หรือ mod (`Inventory.Investment`, Modal ใน ItemDetail, เซิร์ฟเวอร์ต้องได้ confirmed = true) และ FUSE เมื่อคัน Material มี +N หรือ mod หลายบรรทัด.

## อัปเดต 2026-11-23: Responsive, Bake, ไอเทมเด่น
- แผน: `docs/RESPONSIVE_MENU_PLAN.md` (ข้อ 8 = ปัญหาที่เจอและเฟส 6 ถึง 8). C32 และ C33 ใน `docs/TASKS.md`.
- ทำแล้ว: ป้าย UP, TOP, ขอบเรืองบนสล็อต (`ItemSlots`), Sort Newest + ปุ่ม NEW n (`VirtualGrid:ScrollToIndex`), Highlights shelf (`InventoryController.updateShelf`, เกณฑ์ที่ `ItemSlots.NotablePriority`), ItemDetail กลางจอบนจอเล็ก, Daily Login 3 โหมด (`DailyLoginController.applyLayout`), Enhance popup ตาม Figma + โหมดกะทัดรัด, ลบ black overlay (Daily Login, Bag Upgrade, Offline Reward), ลบ stroke popup Depth, ขอบปุ่ม Depth บน HUD เท่า AUTO/SELL.
- แก้หน้าต่างเด้งใหญ่ตอนเปิดครั้งแรกบนมือถือ: `New.FitToScreen` ซ่อนที่ scale 0.05 จนวัดขนาดได้แล้วค่อย pop (ใช้กับทุกหน้าต่างที่เรียก FitToScreen/FitWindow).
- Bake: ทำทั้ง 18 หน้าแล้ว ด้วย `node tools/ui/bake.mjs <ชื่อ>` ทีละหน้า (ทั้งชุดเกิน 200,000 ตัวอักษรของ Studio). ต้อง Save place หลัง bake. แก้ซอร์สใน `UI/Screens/*` แล้วต้อง bake ใหม่ (หรือแก้ที่ controller ตอนรันให้ทนของ bake เก่า).
- ที่ยังไม่ได้ตรวจ: Safe Area รายหน้า, เวอร์ชันมือถือของหน้าอื่นนอกจาก Daily Login, Device Emulator ทุกขนาดตามตารางข้อ 5 ของแผน. ผู้ใช้แจ้งว่า "UI ขนาดและ responsive มีปัญหาหนักมาก": ต้องไล่ตรวจทีละหน้าใน Play (ดูข้อทดสอบ C33) แล้วแก้ทีละหน้า.
- ข้อควรรู้เรื่องเครื่องมือ: `StudioBridge` (run_luau, capture_ui) ใช้ได้ตอน Studio อยู่โหมด Edit; `capture_ui` แสดงเลย์เอาต์ที่ bake ไม่ใช่หลังปรับตามจอตอนรัน. Roblox Studio MCP (execute_luau) ต้องระบุ datamodel_type และเรียกไม่ได้ขณะ Play.
- ข้อผิดพลาดที่เจอ: เพิ่มชนิด action ใหม่ในบทสนทนา (Config/Dialogues) ต้องเพิ่มในรายการที่ `Registry` ตรวจด้วย ไม่งั้นทุกอย่างโหลดไม่ขึ้น (HUD หาย) และ `check.mjs` จับไม่ได้.
- (23 พ.ย. ต่อ) เครื่องมือวัด responsive จริง: เปิด Play ใน Studio (หน้าต่าง Studio ขนาดเล็กเทียบมือถือแนวนอน) แล้วเรียก `execute_luau` (datamodel_type Client) ด้วย `ReplicatedStorage.UITest:Invoke(<ชื่อเมนู>)` แล้ววัด AbsoluteSize ของหน้าต่างเทียบ ScreenGui หรือใช้ `screen_capture`. ต้อง Stop แล้ว Start Play ใหม่ทุกครั้งที่แก้สคริปต์ (รอ Rojo sync ~8 วินาที). `require` จากสคริปต์ทดสอบได้โมดูลสำเนาใหม่ จึงใช้ UITest แทน.
- `Window.Shell` โหมดเลื่อนบนจอเตี้ย: เปิดอัตโนมัติเมื่อสูงใช้งานน้อยกว่า 520 และหน้าต่างออกแบบสูงเกิน 380; ปิดได้ด้วย `NoScroll = true`; หน้าต่างที่ Close = false ไม่เข้าโหมดนี้ (ใช้ Quests ที่ลดความสูงเป็น 500 แทน).
- หน้าที่ยังไม่ได้ดูภาพจริงบนจอเล็ก: Character, Events, Fishdex, Auras, Skills, Mastery, Aquarium, Hub (MainMenu), Gacha, Minigame, Modal, StarterPack. ตัวเลข scale วัดแล้ว: Character 0.57, Events 0.55, Inventory 0.62 (อ่านได้แต่เล็ก).

## อัปเดต 2026-11-23 (ท้ายวัน): C34
- รายละเอียดและวิธีทดสอบ: `docs/TASKS.md` หัวข้อ C34.
- กฎใหม่จากผู้ใช้: Store ห้ามเป็น scroller (ใช้ปุ่ม < > แบ่งหน้า). Item Card ไม่ scroll. Daily แสดงบน HUD เฉพาะตอนยังไม่รับ และมี tile ใน Main Menu. ไม่ใช้ `|` ในข้อความ.
- `MenuManager.updateBackdrop`: พื้นดำเต็มจอใต้เมนู Main/Hub (ScreenGui `MenuBackdrop`, ScreenInsets None).
- `Window.IsShortScreen()` และ `opts.ScrollOnShort`: scroll บนจอสั้นเป็นแบบเลือกเปิด (Aquarium, Mastery ยังเปิดอยู่ ควรเปลี่ยนเป็นแบ่งหน้า).
- Line Modifier ใช้ `Inventory.NewGear` เดียวกับ Rod (`categoryId == "Rods" or "Lines"`). Fusion ยังรองรับเฉพาะ Rod.
- Starter (price 0) ขายได้ 0 โคอิน: `Inventory.SellBlock` อนุญาตให้ Rod/Line ที่ `Sellable ~= false`; ซื้อซ้ำไม่ได้ถ้ามีอยู่.
- ยังไม่ได้ทดสอบใน Play: ทุกข้อของ C34. ยังไม่ได้ดูภาพมือถือจริง (Studio ปรับขนาดหน้าต่างไม่ได้).
- ค้าง: ตรวจ responsive หน้าที่เหลือ (Character, Events, Fishdex, Auras, Skills, Aquarium, Mastery, Gacha, Minigame), จอแนวตั้ง, Safe Area, Rod จาก Boss/Quest, ตัดสินใจ publish เซฟ v6.
