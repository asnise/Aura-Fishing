# Aura Fishing — Task list & test guide

วิธีใช้: ใช้ checkbox แบบ GitHub Markdown — `- [ ]` = ยังไม่เสร็จ, `- [x]` = เสร็จ (แก้ตัว `x` ในไฟล์ หรือคลิกใน viewer ที่รองรับ)
แต่ละงานมี **สถานะ** (โค้ดเสร็จ / ทดสอบผ่าน), **Done when** = เกณฑ์ว่าเสร็จจริง, **ทดสอบ** = ขั้นตอนเป็น checkbox ให้ติ๊กทีละข้อ
ทุก session ที่ทำงานเสร็จต้องอัปเดตไฟล์นี้ในรูปแบบเดียวกัน (เพิ่มงาน + Done when + ขั้นตอนทดสอบเป็น `- [ ]`)

---

## ภาพรวม (ติ๊ก = ทดสอบผ่าน/เสร็จจริง)

**A. เสร็จแล้ว — รอทดสอบ**
- [x] A1 — วงจรตกปลาหลัก (Prototype core loop)  `ทดสอบผ่าน`
- [x] A2 — ธีม UI "Cozy Lake"  `ทดสอบผ่าน`
- [ ] A3 — จัดวางหลบ UI ของ Roblox (Safe areas)  `โค้ดเสร็จ รอทดสอบ`
- [x] A4 — HUD Stats แบบ E (Minimal Floating)  `ทดสอบผ่าน`
- [x] A5 — Cast popup + Auto depth  `ทดสอบผ่าน`
- [x] A6 — มินิเกม Pond Card  `ทดสอบผ่าน`
- [x] A7 — การ์ดปลาที่ตกได้แบบ Badge  `ทดสอบผ่าน`
- [x] A8 — Aura Gacha — Reel Slot  `ทดสอบผ่าน`
- [x] A9 — หน้าต่างเมนูขนาดคงที่  `ทดสอบผ่าน`
- [x] A10 — ออร่า VFX + Low FX  `ทดสอบผ่าน`
- [x] A11 — เซฟข้อมูล (DataStore)  `ทดสอบผ่าน`
- [x] A12 — StudioBridge MCP (Claude สั่งงาน Studio ได้)  `ทดสอบผ่าน`
- [x] A13 — ไปป์ไลน์ Asset (สไลซ์รูป, Catalog, UIAssets)  `ทดสอบผ่าน`
- [x] A14 — Figma → Roblox export (FigmaRoblox MCP)  `ทดสอบผ่าน`
- [x] A16 — แผง "Aura UI" ใน Studio (เปิด/แก้หน้าจอได้ง่าย)  `ทดสอบผ่าน`
- [ ] A18 — Figma plugin แยกโมดูล + ตัวนับการใช้งาน (usage counter)  `โค้ดเสร็จ + ทดสอบนอก Figma ผ่าน รอคุณทดสอบใน Figma`
- [ ] A17 — Responsive มือถือแนวนอน (HUD + popup ทุกอัน)  `เลื่อนไปทีหลัง — ใช้ได้แต่ยังไม่สวย; ตอนนี้โฟกัส desktop`
- [x] A15 — Figma ดีไซน์ทั้งหมด (Style guide, Components, 17 หน้าจอ, Gacha FINAL, Asset section)  `ทดสอบผ่าน`

**B. กำลังทำ (UI จาก Figma)**
- [x] B0 — ปุ่มแบบ Figma (Face + Lip 5px ซ้อนกัน) + ไฮไลต์ราคาใน Modal + การ์ด Equipped สีต่าง  `ทดสอบผ่าน`
- [x] B1 — 14 Modal (ยืนยัน Sell All)  `ทดสอบผ่าน`
- [x] B2 — 07 Auras — Aura Card (Row) + การ์ด Equipped + pager  `ทดสอบผ่าน`
- [x] B3 — 05/06 Shop — รูปไอเท็ม + pager  `ทดสอบผ่าน`
- [x] B4 — 09 Fishdex — การ์ด 3×2 + pager  `ทดสอบผ่าน`
- [x] B5 — 12 Main Menu (hub แบบโทรศัพท์)  `ทดสอบผ่าน`
- [x] B10 — ย้ายทุกหน้าจอลง Explorer + Components (prefab)  `ทดสอบผ่าน`
- [x] B11 — 04 Catch Result (การ์ดปลาที่ตกได้ตาม Figma)  `ทดสอบผ่าน`
- [x] B12 — Fishdex: ปุ่ม Sort + Discovery แสดงแค่ตัวเลข (เกม + Figma 09)  `ทดสอบผ่าน`
- [x] B13 — Main Menu hub: ทุกปุ่มทำงานจริง/แจ้งตามจริง + Config/Features  `ทดสอบผ่าน`
- [x] B14 — มินิเกม Twin tubes (Figma 03 A2)  `ทดสอบผ่าน`
- [x] B15 — หน้ารวม Event (E0) แบบ data-driven + การ์ด OPEN  `ทดสอบผ่าน`
- [x] B16 — คำสั่ง Dev สำหรับทดสอบ (แชท ! + แผง F2)  `ทดสอบผ่าน`
- [x] B17 — Skeleton loading ของรูป (ปลา → Mystery Fish, ออร่า → Unknown Aura)  `ทดสอบผ่าน`
- [x] B18 — Stat ลดเวลารอ Auto Fishing (Auto Wait) บนเบ็ด/เหยื่อ + Highlight สีทอง  `ทดสอบผ่าน`
- [x] B19 — แมพหลักใหม่ "Stilt Boardwalk" (สะพานไม้ยกสูงบนเสา กลางทะเลกว้าง ไม่มีบ้าน) + ขอบทะเล  `ทดสอบผ่าน`
- [x] B6 — Gacha G1 Altar (rates, pity, x1/x10, skip, auto-roll) + ระบบ pity/x10 ฝั่ง server  `ทดสอบผ่าน`
- [ ] B7 — 11 Dialogue (NPC)  `โค้ดเสร็จ + bake แล้ว Claude ทดสอบใน Play ผ่าน รอคุณ Ctrl+S + ทดสอบ`
- [ ] B20 — Virtual Grid (Inventory / Aquarium / Mastery / Put in Tank)  `โค้ดเสร็จ รอทดสอบ`
- [ ] B21 — Item Detail Card + Inventory v2 (แท็บด้านข้างเป็นไอคอน, Rod/Line/Aura เป็นไอเท็ม, Bag เป็นอัปเกรด)  `ครบทุกส่วนในเกมแล้ว (Inventory, การ์ด, Shop, Fishdex, Character, Aura Dex) Claude ทดสอบใน Play ผ่าน รอคุณ Ctrl+S + ทดสอบส่วนที่เหลือ`
- [ ] B22 — Gacha page ใหม่ = Figma concept D "Glass Card" + ส่วนจาก E1  `แก้กรอบเลือกหมวด ใช้ช่อง Item Slot ของ Inventory และเปิด Aura Altar จาก HUD แล้ว ทดสอบผ่าน Studio Bridge`
- [x] B8 — 13 Inventory  `ทดสอบผ่าน`
- [x] B9 — G6 x10 Summary  `ทดสอบผ่าน`

**C. Backlog**
- [x] C1 — อัปโหลดรูปขึ้น Roblox  `ทดสอบผ่าน`
- [x] C2 — ตัดสินใจ data model ของ Inventory  `ตัดสินใจแล้ว 2026-11-17`
- [ ] C3 — Rebirth + ฉายา (GDD 7.2) — ย้ายไป Lv.50  `โค้ดเสร็จ รอทดสอบ`
- [ ] C4 — สกิล Keen Eye / Quick Hands / Multi-Cast (GDD 7.1)  `โค้ดเสร็จ + หน้าต่าง Skills แล้ว (ปุ่ม SKILLS ในหน้าต่าง Character) รอทดสอบ`
- [ ] C5 — อีเวนต์ Naga Tide (จุดสุ่มในทะเล ตกในวง = ลุ้นปลาพิเศษ, คนแห่มา = โอกาสสูงขึ้น)  `โค้ด HUD Cozy Lake เสร็จแล้ว รอทดสอบใน Play`
- [ ] C6 — Gamepasses (Infinite Bag 349, Auto-Fish Pro 249, VIP 149, Extra Cast)  `โค้ดเสร็จ + ป้ายชื่อ VIP เหนือหัว + ร้าน Store แล้ว รอทดสอบ — Extra Cast รอสร้าง pass บนเว็บ`
- [ ] C7 — เควสต์รายวัน  `โค้ดเสร็จ + หน้าต่างเควสต์แล้ว รอทดสอบ`
- [ ] C8 — เสียง (SFX) ตามจุดที่ระบุใน storyboard gacha/มินิเกม  `ยังไม่เริ่ม`
- [ ] C9 — แมพจริง + โมเดลปลา/คันเบ็ด  `ยังไม่เริ่ม`
- [ ] C10 — เครดิต Font Awesome (FaLock, CC BY 4.0)  `โค้ดเสร็จ รอทดสอบ`
- [ ] C11 — ทดสอบมือถือจริง + ปรับขนาดปุ่ม  `ยังไม่เริ่ม`
- [ ] C12 — Balance Pass 1 (ราคา ×10, Auto 14 วิ, Hot Streak, XP, โซนลึก, ย้ายเซฟ)  `โค้ดเสร็จ + ป้าย Streak บนปุ่ม CAST แล้ว รอทดสอบ`
- [ ] C13 — ระบบรับเงิน Robux (ProcessReceipt, ใบเสร็จ, เช็ค Gamepass)  `โค้ดเสร็จ รอทดสอบ + รอ ID จากเว็บ Roblox`
- [ ] C14 — บ่อปลา (Aquarium) + Pearls + ออฟไลน์  `โค้ดเสร็จ + หน้าจอ Aquarium/Put in Tank/popup ออฟไลน์แล้ว รอทดสอบ`
- [ ] C15 — Mastery (อัปถาวรด้วย Pearls)  `โค้ดเสร็จ + หน้าต่างตาม Figma แล้ว รอคุณทดสอบ (ใช้ไอคอนชุดใหม่แล้ว)`
- [ ] C16 — Gear Enhance +1…+10  `โค้ดเสร็จ + ENHANCE ในการ์ดไอเท็ม + ป้าย +N บนช่อง/รูป Shop แล้ว รอทดสอบ`
- [ ] C17 — ดาวออร่า 1–5 stars + Star Token + pity ใหม่ + หน้าต่าง Aura Dex (C17 Figma) + แสดง Star Token (HUD, Aura Index, Altar, ItemDetail)  `โค้ดเสร็จ + bake ใน StarterGui แล้ว รอทดสอบใน Play`
- [ ] C18 — ปลาขายดีประจำชั่วโมงที่ร้าน  `โค้ดเสร็จ + ป้าย HOT บนกองปลา, บรรทัด Hot fish bonus ใน Sell All, ป้าย HOT FISH ที่ Merchant แล้ว รอทดสอบ`
- [ ] C19 — Dev Products (Starter Pack, Gems, Boost 2x) + Modal เสนอขาย Starter Pack (Figma 3546:36782)  `Gems, Boosts และ Packs เป็นรายการใน Store แล้ว กด Buy ที่ Starter Pack เพื่อเปิด Modal พรีวิวของแถมก่อนซื้อ ปุ่มราคาใช้ไอคอน Robux ใหม่ รอทดสอบซื้อจริงใน Play`
- [ ] C20 — มินิเกม: Catch Bar เริ่มตรงตำแหน่งปลา + ช่วงพักตอนเริ่ม  `โค้ดเสร็จ รอทดสอบ`
- [ ] C21 — คอนเทนต์ใหม่จากรูปที่อัปโหลดแล้ว (ปลา 8, ออร่า 10, คันเบ็ด 2, สาย 2, เหยื่อ 4)  `โค้ดเสร็จ รอทดสอบ`
- [ ] C22 — FishingZone / PlayArea ใช้เฉพาะใน Workspace (แมพสำรองใน ServerStorage ไม่นับ)  `โค้ดเสร็จ ตรวจ logic ใน Studio แล้ว รอทดสอบ Play ใหม่`
- [ ] C23 — Daily Login ปฏิทินของขวัญ 7 วัน (Streak, เคลมรางวัล, เชื่อมการ์ด Events)  `โค้ดเสร็จ + bake แล้ว รอทดสอบใน Play`
- [ ] C24 — Core Menu Manager (แบ่งชั้นหน้าต่าง ไม่เปิดซ้อนมั่ว, ซ้อนได้เฉพาะที่กำหนด)  `โค้ดเสร็จ ทดสอบใน Play บางส่วนผ่าน — M2-M4 โค้ดเสร็จ รอทดสอบ — งานต่อ M1, M5, M6 ใน docs/MENU_MANAGER.md`
- [ ] C25 — เหวี่ยงเบ็ดใหม่: กดค้าง + Perfect Cast + ระยะเหวี่ยงตามคัน + ตัวปรับความลึกบน HUD  `โค้ดเสร็จ + bake + Figma แล้ว รอทดสอบใน Play`
- [ ] C26 — จุดฟองปลา (Hotspot): เหวี่ยงลงวงฟองได้ Luck +50%  `โค้ดเสร็จ + Figma แล้ว รอทดสอบใน Play`
- [ ] C27 — Store ไม่มีรายการ + spinner โหลด + แจ้งเตือนอยู่บนสุด + Enhance popup + Figma ตรงกับเกม  `โค้ดเสร็จ รอทดสอบใน Play`
- [ ] C28 — Window core (`Window.Shell`) + "!" ปลากินเบ็ดบนหัวตัวละคร  `โค้ดเสร็จ รอทดสอบใน Play`

---

## เตรียมก่อนทดสอบทุกครั้ง (ทำครั้งเดียวต่อรอบ)
1. เปิด Roblox Studio → เปิดไฟล์ **`places/AuraFishing.rbxlx`** (ไฟล์ที่มีแมพของคุณ — ไม่ใช่ `build/`)
2. ดับเบิลคลิก `scripts\serve.bat` → ใน Studio: **Plugins → Rojo → Connect** (โค้ดล่าสุดจะ sync เข้ามา)
3. กด **Play (F5)** เพื่อทดสอบ • ทดสอบมือถือ: แท็บ **Test → Device** เลือก iPhone/Android แล้ว Play
4. ดูหน้าต่าง **Output** (View → Output): ต้องไม่มีตัวแดง `[Registry] Content errors` หรือ error จากสคริปต์ของเรา
5. อยากให้เซฟข้อมูลระหว่างทดสอบ: Publish เกม 1 ครั้ง → Game Settings → Security → เปิด *Enable Studio Access to API Services*
6. **UI เก็บอยู่ใน place (StarterGui)** ไม่ได้สร้างตอนกด Play: หลังมีการเปลี่ยนหน้าจอ บอก Claude ให้ "bake UI" (หรือรัน `node tools/ui/bake.mjs`) → ใน Explorer ต้องเห็น `StarterGui.Modal`, `StarterGui.Menus` → **กด Save (Ctrl+S)**
   - แก้ UI เองใน Studio ได้เลย; ถ้าแก้แล้วไม่อยากให้ bake ครั้งหน้าทับ: เลือก ScreenGui นั้น → Properties → Attributes → เพิ่ม `Locked` (boolean) = true
   - ถ้า Output มีคำเตือน `[UI] ScreenGui "X" is not baked` = ยังไม่ได้ bake/Save หน้าจอนั้น (เกมยังเล่นได้ แต่ UI ถูกสร้างตอนเริ่มแทน)

---

## A. เสร็จแล้ว — รอคุณทดสอบใน Studio

### A1. วงจรตกปลาหลัก (Prototype core loop)
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: เหวี่ยง → รอ "!" → Hook → มินิเกม → ได้ปลา → ขาย → ได้เงิน → ซื้อของได้ ครบโดยไม่มี error
- ทดสอบ:
  - [x] 1. Play → เดินไปขอบเกาะ/ท่าเรือ หันหน้าเข้าน้ำ
  - [x] 2. กด **CAST** → Cast popup ขึ้น → กด **CAST!** → ควรเห็นทุ่นสีแดงลงน้ำ + ข้อความ "Waiting… (Xm)"
  - [x] 3. รอจน "!" ขึ้น → กด **HOOK!** ภายใน ~2 วินาที → มินิเกมขึ้น
  - [x] 4. ชนะมินิเกม → การ์ดปลาขึ้นกลางจอ, ตัวนับกระเป๋า `Bag x/10` เพิ่ม
  - [x] 5. หันหน้าออกจากน้ำแล้วกด CAST → ต้องขึ้น "Face the water to cast!"
  - [x] 6. ตกจนกระเป๋าเต็ม → กด CAST → ต้องขึ้น "Your bag is full!"
  - [x] 7. กด **SELL ALL** → หน้าต่างยืนยัน (B1) ขึ้น → กด **Sell** → เงินเพิ่ม, กระเป๋าว่าง (ProximityPrompt ที่ Fish Merchant ขายทันทีไม่ถาม)
  - [x] 8. เมนู **Shop** → แท็บ Rods → ซื้อ Bamboo Rod (400) → ปุ่มเปลี่ยนเป็น Equipped
  - [x] 9. เปิด **AUTO** → รอ ~9 วินาที → ได้ปลาเอง (ราคา x1.0) → กด AUTO อีกครั้งเพื่อหยุด

### A2. ธีม UI "Cozy Lake"
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: ทุกหน้าต่างพื้นครีม ขอบสีเดียว (#E6DCCB) ปุ่มมี "ขอบล่างนูน" ฟอนต์ Fredoka One/Nunito
- ทดสอบ: Play → เปิด Shop / Auras / Fishdex → เทียบกับ Figma section "Aura Fishing — Cozy Lake Style Guide" (สี, ฟอนต์, มุมโค้ง)

### A3. จัดวางหลบ UI ของ Roblox (Safe areas)
- สถานะ:
  - [x] โค้ดเสร็จ
  - [ ] ทดสอบผ่าน
- Done when: ไม่มีปุ่ม/ข้อความของเราโดน Top bar, Leaderboard, Chat, Thumbstick, Jump บัง
- ทดสอบ:
  - [x] 1. Play (คอม): Leaderboard มุมขวาบนต้องไม่ทับปุ่มใด ๆ; กดเปิด Chat (มุมซ้ายบน) → บังได้แค่ Stats เท่านั้น
  - [ ] 2. Test → Device → เลือกมือถือ → Play: จอยซ้ายล่างกับปุ่มกระโดดขวาล่างต้องไม่ทับปุ่ม Bag/Auto/Sell (ปุ่มเหล่านี้ต้องยกขึ้นเหนือปุ่ม Jump)
  - [x] 3. เทียบกับ Figma section "00 · Roblox Safe Areas"
  - หมายเหตุ 2026-11-16: ข้อ 2 บนมือถือแนวนอน**ไม่ผ่าน** (เมนูซ้ายล้นจอ/ทับ thumbstick) → แก้ใน A17 แล้ว ทดสอบใหม่ที่ A17

### A4. HUD Stats แบบ E (Minimal Floating)
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: มุมซ้ายบนแสดง `Lv.N` ตัวขาวขอบเข้ม + `XP / need XP` + ชิป Coins/Gems, ไม่มี Aura, ไม่มีแถบ XP
- ทดสอบ: Play → ตกปลา 1 ตัว → ตัวเลข XP และ Coins ต้องเปลี่ยนทันที; เลเวลอัป → `Lv.` เปลี่ยน + แจ้ง LEVEL UP

### A5. Cast popup + Auto depth
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: CAST เปิด popup เลือกความลึก; ติ๊ก Auto แล้ว CAST ครั้งถัดไปเหวี่ยงทันที; ปุ่ม DEPTH ข้าง CAST เปิด popup ได้เสมอ
- ทดสอบ:
  - [x] 1. กด CAST → popup: ลาก slider / กด Shallow-Mid-Max → ตัวเลขความลึก, ป้าย zone, "N species live here" เปลี่ยนตาม
  - [x] 2. กด CAST! → ข้อความ Waiting แสดงความลึกที่เลือก
  - [x] 3. เปิด popup อีกครั้ง → ติ๊ก **Auto depth** → CAST! → ปุ่ม DEPTH แสดง `AUTO`
  - [x] 4. กด CAST ครั้งต่อไป → ต้องเหวี่ยงทันที (ไม่มี popup) และความลึกใน "Waiting…" สุ่มเปลี่ยนไปทุกครั้ง
  - [x] 5. กดปุ่ม DEPTH → popup ขึ้น → เอาติ๊ก Auto ออก → กลับเป็นแบบเลือกเอง
  - [x] 6. ออกเกมแล้วเข้าใหม่ (ถ้าเปิด API Services) → ค่า Auto/ความลึกยังจำไว้

### A6. มินิเกม Pond Card
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: มินิเกมแนวตั้งตาม Figma 03, ปลาไม่เฉลยชนิด, ชิป LOOSE/GOOD/SNAP! เปลี่ยนตามสถานการณ์
- ทดสอบ:
  - [x] 1. Hook ปลา → แผงขึ้น: แท็ก rarity + ความลึก + เวลาถอยหลัง 0:59…
  - [x] 2. กดค้าง (คลิก/Space/แตะจอ) → แถบเขียวขึ้น, ปล่อย → แถบลง
  - [x] 3. แถบทับปลา → ชิป **GOOD** สว่าง + มิเตอร์ทองเพิ่ม + ทุ่นเลื่อนขึ้น
  - [x] 4. ปล่อยให้หลุด → **LOOSE**; หลุดนานจนมิเตอร์ต่ำ → **SNAP!** สีแดง; มิเตอร์หมด → "The line snapped!"
  - [x] 5. ปลาต้องเป็นสัญลักษณ์เทา `><>` (หรือรูป MysteryFish ถ้าอัปโหลดแล้ว) — ห้ามเห็นชนิดปลาก่อนจับได้
  - [x] 6. ปรับความยาก/ความเร็ว: `src/shared/Config/GameConfig.luau` → `Minigame` (BarLift, BarGravity, GainPerSecond, SnapWarning)

### A7. การ์ดปลาที่ตกได้แบบ Badge
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: ใต้ชื่อปลาเป็น badge (RARITY / x.x kg / Manual|Auto / PERFECT / mutation) ไม่ใช่ข้อความคั่น "•"
- ทดสอบ: ตกปลาแบบมือ 1 ตัว และแบบ Auto 1 ตัว → badge Mode ต้องต่างกัน; ตกแบบไม่หลุดเลย → มี PERFECT
- หมายเหตุ 2026-11-17: การ์ดเปลี่ยนเป็นหน้าตา Figma 04 แล้ว → ทดสอบใหม่ที่ **B11**

### A8. Aura Gacha — Reel Slot
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: กดสุ่มแล้วมีวงล้อหมุน → ช้าลง ("so close…") → ล็อก (แฟลช/แสง/คอนเฟตตี) → การ์ดผลลัพธ์; ข้ามได้; Legendary+ ประกาศทั้งเซิร์ฟ
- ทดสอบ:
  - [x] 1. ต้องมี Gems ≥ 5 (เริ่มเกมมี 15) → เมนู **Auras** → **ROLL AURA**
  - [x] 2. ดูลำดับ: SPINNING! → so close… → ชื่อ rarity → การ์ด (orb, ชื่อ, rarity, 1/N, NEW! ที่มุม orb ถ้าเพิ่งได้ครั้งแรก, badge stats)
  - [x] 3. ระหว่างหมุน แตะจอ → ต้องข้ามไปผลทันที
  - [x] 4. กด **ROLL AGAIN** → สุ่มต่อ; **EQUIP** → ออร่าเปลี่ยน (เห็นพาร์ติเคิลรอบตัว)
  - [x] 5. เดินไป **Aura Altar** (วงกลมม่วง) → ProximityPrompt → ต้องเล่นวงล้อแบบเดียวกัน
  - [ ] 6. ทดสอบ Legendary: Command bar ในโหมด Play (Server) ใส่ gems เยอะ ๆ หรือแก้ `Roll.Aura` ชั่วคราว → ได้ Legendary → ~3.5 วิ ทุกคนเห็นข้อความ "X rolled …"
  - [x] 7. Gems ไม่พอ → ขึ้นข้อความ Need 5 Gems

### A9. หน้าต่างเมนูขนาดคงที่
- สถานะ:
  - [x] (2026-11-16 เปลี่ยนเป็นขนาด Figma 760×610 + pager แทนการเลื่อน — ดู B2–B4)
  - [x] ทดสอบผ่าน
- Done when: Shop/Auras/Fishdex ขนาดเท่ากันทุกหน้าต่าง ไม่ล้นจอ
- ทดสอบ: เปิดแต่ละเมนู → ขนาดหน้าต่างต้องเท่ากัน; Test → Device → มือถือ → Play → หน้าต่างต้องย่อทั้งก้อน (ไม่ล้นจอ ไม่ทับ Top bar)

### A10. ออร่า VFX + Low FX
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: ใส่ออร่าแล้วมีพาร์ติเคิลตามสีออร่า; Low FX ซ่อนของคนอื่นแต่ของเรายังอยู่
- ทดสอบ: Test → Clients and Servers → 2 Players → ทั้งคู่ใส่ออร่า → ผู้เล่น 1 เปิด Auras → Low FX: ON → ไม่เห็นพาร์ติเคิลของผู้เล่น 2 แต่ยังเห็นของตัวเอง

### A11. เซฟข้อมูล (DataStore)
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: เงิน/ของ/ออร่า/Fishdex/Settings คงอยู่หลังออกแล้วเข้าใหม่
- ทดสอบ: เปิด API Services (เตรียมข้อ 5) → Play → ตกปลา ขาย ซื้อของ → Stop → Play ใหม่ → ทุกอย่างต้องยังอยู่ • ถ้าไม่เปิด API: Output ต้องมีคำเตือน "Using a fresh profile" และเกมยังเล่นได้

### A12. StudioBridge MCP (Claude สั่งงาน Studio ได้)
- สถานะ:
  - [x] (e2e 20/20 ผ่านแล้วโดย session studio-mcp)
  - [x] ทดสอบผ่าน (2026-11-16: Claude สั่งผ่าน bridge — get_tree StarterGui ได้ Modal/MainMenu/Menus, สร้าง/แก้/ลบ Part ได้; หมายเหตุ create_instance ใช้คีย์ `props` ไม่ใช่ `properties`)
- Done when: Claude เรียก tool ของ StudioBridge แล้วเห็นผลใน Studio
- ทดสอบ: รีสตาร์ท Claude Code → เปิด Studio + plugin AuraStudioBridge (Connected) → บอก Claude "ใช้ StudioBridge ดู tree ของ StarterGui" → ต้องได้รายการ; ลอง "สร้าง Part ใน Workspace" แล้ว Ctrl+Z ใน Studio ต้องย้อนได้

### A13. ไปป์ไลน์ Asset (สไลซ์รูป, Catalog, UIAssets)
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ทดสอบผ่าน
- Done when: มี `assets/ui-global` 15 ไฟล์, `assets/art` 81 ไฟล์ (+9 contact sheet = 90), `assets/catalog.json`, `UIAssets.luau`
- ทดสอบ:
  - [x] 1. เปิด `assets/art/*_contact.png` → รูปตรงชื่อทุกช่อง
  - [x] 2. รัน `python -I tools/art/sync_ui_assets.py` → ขึ้น "UIAssets.luau regenerated — N/99 assets have ids" (Claude รัน 2026-11-16: 99/99)
  - [x] 3. หลังอัปโหลด (B1) → ตัวเลขต้องเพิ่มตามจำนวนที่ใส่ id

### A14. Figma → Roblox export (FigmaRoblox MCP)
- สถานะ:
  - [x] ทดสอบแบบ offline แล้ว
  - [x] ทดสอบกับ Figma จริง (2026-11-16: Modal 3492:17615 → `Generated/Modal.luau` 31 instances, mount ใน Studio ตรง Figma; ข้อจำกัด: เงา/ปุ่ม lip ไม่ถูกแปลง, รูปต้องใส่ rbxassetid เอง — ใส่จาก UIAssets แล้ว)
- Done when: `export_to_roblox` สร้างไฟล์ใน `src/client/UI/Generated/` แล้วแสดงใน Studio ตรงกับ Figma
- ทดสอบ: เปิด relay + plugin (channel aura-fishing) → บอก Claude "export Modal (14) ด้วย export_to_roblox" → ดูไฟล์ใหม่ใน Generated → ใช้ StudioBridge `mount_ui_module` ดูใน Studio

### A18. Figma plugin แยกโมดูล + ตัวนับการใช้งาน (usage counter)
- สถานะ:
  - [x] แยก `code.js` 4,947 บรรทัด → `src/cursor_mcp_plugin/src/` (core + 13 กลุ่มคำสั่ง), UI → `ui/`; `build.mjs` รวมกลับเป็น `code.js`/`ui.html` (manifest เดิม ไม่ต้อง link ใหม่)
  - [x] ตัวนับ: relay นับทุกคำสั่งที่ส่งเข้า plugin → `usage/plugin-commands.json`; MCP server นับทุก tool → `usage/mcp-tools.json` (ครั้ง / error / ms / แยกตาม agent)
  - [x] ทดสอบนอก Figma: `bun run test:plugin` ผ่าน, relay ทดสอบ + MCP stdio นับถูก
  - [x] ทดสอบใน Figma จริง (2026-11-18: get_selection ได้ "Window Aquarium" 3569:40700 + path/size ใน 0.2 วิ; batch โน้ต 4 คำสั่งรอบเดียวผ่าน; เวลาเทียบ baseline: get_node_info 426→348ms, get_roblox_tree 835→662ms, export รูป 1918→1627ms; ตัวนับนับแยก agent + คำสั่งใน batch)
  - [x] เฟส 1 (2026-11-18): อ่านแบบกระชับ (`depth`/`fields`/`maxNodes`) เล็กลง ~10 เท่า (54KB → 5.6KB), `find_nodes` ค้นตามชื่อ/ชนิด/ข้อความ, batch อ้างผลข้อก่อน `"$0.id"`, 1 คำสั่ง Agent = Ctrl+Z 1 ครั้ง, error บอกชื่อคำสั่งที่ใกล้เคียง, ตัวนับเก็บขนาดผลลัพธ์ (KB) — smoke test 19 ข้อผ่าน + ทดสอบใน Figma จริงผ่าน
  - [ ] คุณลองแผง Selection เอง (คลิก layer, Copy id, พิมพ์โน้ต) + รีสตาร์ท Claude Code ให้ตัวนับฝั่ง MCP เริ่มนับ
- Done when: plugin ใน Figma ทำงานเหมือนเดิมทุกคำสั่ง และ `bun run usage` แสดงตัวเลขของคำสั่งที่เพิ่งใช้
- ทดสอบ:
  1. ปิดหน้าต่าง relay เดิม แล้วเปิด `scriptsigma-relay.bat` ใหม่ (`scripts\figma-relay.bat`)
  2. ใน Figma ปิดแล้วเปิด plugin "Figma to Roblox MCP (Aura Fishing)" ใหม่ → กด Connect (channel aura-fishing)
  3. รีสตาร์ท Claude Code แล้วบอก Claude "join_channel aura-fishing แล้ว get_selection" → ต้องได้ผลเหมือนเดิม
  4. บอก Claude "export Modal (14) ด้วย export_to_roblox" → ไฟล์ใน `src/client/UI/Generated/` ออกมาเหมือนเดิม
  5. ในโฟลเดอร์ `Figma For Roblox\cursor-talk-to-figma-mcp` รัน `bun run usage` → เห็นตาราง get_selection / export_to_roblox / get_roblox_tree พร้อมจำนวนครั้ง และ agent `mcp:claude-code`
  6. (เฟส 1) บอก Claude "find_nodes ชื่อ Window Aquarium" → ได้ id `3569:40700` พร้อม path; "get_node_info 3569:40700 depth 2" → ได้ข้อมูลสั้น (สี hex, x/y/w/h, ข้อความ)
  7. (เฟส 1) ให้ Claude แก้อะไรสักอย่างด้วย batch (เช่น เปลี่ยนสี 2 กล่อง) → ใน Figma กด Ctrl+Z ครั้งเดียว → ทั้ง batch ย้อนกลับพร้อมกัน
- เอกสาร: `Figma For Roblox/cursor-talk-to-figma-mcp/HANDOFF.md`, กฎ agent ท้าย `AGENTS.md`, โครงสร้าง plugin `src/cursor_mcp_plugin/README.md`

### A16. แผง "Aura UI" ใน Studio (เปิด/แก้หน้าจอได้ง่าย)
- สถานะ:
  - [x] ติดตั้งแล้ว (`%LOCALAPPDATA%\Roblox\Plugins\AuraUIScreens.rbxm`)
  - [x] ทดสอบผ่าน (ต้องปิด-เปิด Studio 1 ครั้ง)
- Done when: แท็บ Plugins มีปุ่ม **Aura UI** → แผงรายชื่อหน้าจอ; คลิกชื่อ → หน้าจอนั้นขึ้นใน viewport พร้อมข้อมูลตัวอย่างแบบ Figma และถูกเลือกใน Explorer
- ทดสอบ:
  - [x] 1. ปิด-เปิด Studio → `places/AuraFishing.rbxlx` → serve.bat + Rojo Connect
  - [x] 2. แท็บ **Plugins** → **Aura UI** → แผงขึ้นด้านขวา
  - [x] 3. คลิก "05 Shop - Rods" → เห็นหน้าต่าง Shop กลางจอ ข้อมูลเหมือน Figma, Explorer เลือก `StarterGui.Menus.Shop` ให้
  - [x] 4. ลองแก้ Properties (เช่น BackgroundColor3) → เห็นผลทันที → Ctrl+Z ย้อนได้
  - [x] 5. ส่วน "ล็อกหน้าจอที่แก้เอง" → กด Menus → เป็น 🔒 → ให้ Claude bake → ต้องขึ้น "Menus: skipped (Locked)"
  - [x] 6. กด **ซ่อนทั้งหมด (ก่อน Save)** → ทุกหน้าจอหาย → Ctrl+S

### A17. Responsive มือถือแนวนอน (HUD + popup ทุกอัน)
> **เลื่อนไปทีหลัง (2026-11-16):** ลองแล้วอยู่ในจอได้แต่ยังไม่สวย — ไม่ใช่ pain point ตอนนี้ โฟกัส **desktop** ก่อน แล้วค่อยกลับมาเก็บ mobile
- สถานะ:
  - [x] โค้ดเสร็จ
  - [ ] ทดสอบผ่าน
- Done when: บนมือถือแนวนอน (จอสูง ~360px) ทุกอย่างอยู่ในจอ ไม่ล้น ไม่ทับจอยซ้ายล่าง/ปุ่มกระโดดขวาล่าง; บนคอมหน้าตาเหมือนเดิม
- ทำอะไรไป: ทุกกลุ่มของ HUD (Stats, เมนู, AUTO/SELL, CAST+DEPTH, สถานะ) มี UIScale ตามขนาดจอ (ย่อได้ถึง 0.6); จอเตี้ย (< 500px) เมนู Shop/Auras/Fishdex/Menu ย้ายเป็น**แถวมุมขวาบน**; Cast popup, มินิเกม Pond Card, การ์ดปลา, วงล้อ/การ์ดกาชา ย่อให้พอดีจอเอง (`New.FitToScreen`)
- ทดสอบ:
  - [ ] 1. Test → Device → เลือกมือถือแนวนอน (เช่น iPhone 14) → Play
  - [ ] 2. เมนู Shop/Auras/Fishdex/Menu ต้องเป็นแถวแนวนอนที่**มุมขวาบน** และกดได้ทุกปุ่ม
  - [ ] 3. Lv./Coins/Gems มุมซ้ายบนเล็กลงพอดี ไม่ทับปุ่ม Roblox (โลโก้/เมนู/แชท)
  - [ ] 4. AUTO / SELL ALL / Bag อยู่เหนือปุ่มกระโดด ไม่ทับกัน; CAST + DEPTH อยู่กลางล่าง ไม่ทับจอย
  - [ ] 5. กด CAST → Cast popup ต้องอยู่ในจอทั้งหมด (เห็นปุ่ม CAST! ด้านล่าง)
  - [ ] 6. Hook ปลา → มินิเกม Pond Card อยู่ในจอทั้งหมด (เห็นชิป LOOSE/GOOD/SNAP!)
  - [ ] 7. ตกได้ → การ์ดปลาไม่ล้นจอ
  - [ ] 8. ROLL AURA → วงล้อ + การ์ดผลลัพธ์อยู่ในจอ เห็นปุ่ม EQUIP/ROLL AGAIN/CLOSE
  - [ ] 9. หมุนจอ/เปลี่ยน Device เป็นแท็บเล็ต และกลับมาโหมดคอม (Device: None) → ทุกอย่างปรับตามเอง, บนคอมเมนูกลับเป็นแนวตั้งซ้ายเหมือนเดิม

### A15. Figma ดีไซน์ทั้งหมด (Style guide, Components, 17 หน้าจอ, Gacha FINAL, Asset section)
- สถานะ:
  - [x] โค้ดเสร็จ
  - [x] ตรวจแล้ว (2026-11-16: ผู้ใช้ยืนยัน — **Figma ณ ตอนนี้คือแหล่งอ้างอิงหลัก**; ถ้าเกมไม่ตรง ให้แก้เกมตาม Figma)
- Done when: ทุกหน้าจอใน section "Aura Fishing — Game Menus" + "Aura Gacha — Reel Slot (FINAL)" ตรงกับที่คุณต้องการ
- ทดสอบ: เปิด Figma หน้า Out Space → ไล่ดูทีละ section → แก้เองได้ (session อื่นจะ patch เฉพาะ node ไม่ทับงานคุณ)

---

## B. กำลังทำ — session "Figma → Roblox UI conversion"
แต่ละข้อ: เมื่อเสร็จ session นั้นจะติ๊ก `- [x]` และเติมขั้นตอน "ทดสอบ" เป็น `- [ ]` ให้

หน้าจอทั้งหมดเก็บใน place: โครงอยู่ที่ `src/client/UI/Screens/*.luau` → bake ลง StarterGui (เตรียมข้อ 6) → controller แค่ใส่ข้อมูล
รูปทั้งหมดอัปโหลดแล้ว (C1); รูปที่เพิ่มทีหลังและยังไม่อัปโหลดจะแสดงเป็นกรอบสี/ตัวอักษรแทน — อัปโหลดแล้วรูปขึ้นเองไม่ต้อง bake ใหม่

### B12. Fishdex: Sort + Discovery ตัวเลข
- สถานะ:
  - [x] โค้ดเสร็จ + bake (`Screens/Menus.luau` buildFishdex, `MenuFill.luau` fillFishdex) + Figma 09 (ชิปตัวเลข + ปุ่ม Sort)
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน
- Done when: แถวบนของ Fishdex มีชิป [ไอคอน Fishdex] `7 / 20` (ตัวเลขอย่างเดียว ไม่มีคำว่า Discovered และไม่มีแถบ progress) ทางซ้าย และปุ่ม `Sort: Depth` ทางขวา; กดปุ่มแล้ววน Depth → Rarity → Name → Caught → Found → Depth; เปลี่ยนโหมดแล้วกลับไปหน้า 1; ปลาที่ยังไม่เจอ (???) ไม่เปิดเผยชื่อและอยู่ท้ายสุดในโหมด Name/Caught/Found; หน้าต่างยังขนาด 760×610 เท่าเดิม
- ทดสอบ:
  - [x] 1. Ctrl+S → Play → เปิด Menu → Fishdex → แถวบนเห็นชิปไอคอน + `N / 20` ทางซ้าย (ไม่มีแถบเขียว) และปุ่ม `Sort: Depth` ทางขวา หน้าตาเหมือน Figma 09
  - [x] 2. ตัวเลขในชิปตรงกับจำนวนปลาที่เคยจับได้ (จับปลาชนิดใหม่ → ตัวเลขเพิ่ม 1 ทันทีขณะหน้าต่างเปิด)
  - [x] 3. กด Sort 1 ครั้ง → `Sort: Rarity` → การ์ดเรียงจากหายากสุด (Mythic/Legendary ก่อน) ไป Common
  - [x] 4. กดอีก → `Sort: Name` → ปลาที่เจอแล้วเรียง A–Z ก่อน แล้วตามด้วย ??? ทั้งหมด (ชื่อไม่หลุด)
  - [x] 5. กดอีก → `Sort: Caught` → ปลาที่จับได้มากสุดอยู่ก่อน, ??? อยู่ท้าย
  - [x] 6. กดอีก → `Sort: Found` → ปลาที่เจอแล้วทั้งหมดอยู่หน้าแรก ๆ, ??? ตามหลัง; กดอีก → กลับเป็น `Sort: Depth`
  - [x] 7. ไปหน้า 2 ด้วยปุ่ม > แล้วกด Sort → pager กลับเป็น `1 / N`
  - [x] 8. ปุ่ม pager และปุ่ม X ยังอยู่ในกรอบหน้าต่าง ไม่ทับการ์ด

### B19. แมพหลัก "Stilt Boardwalk"
- สถานะ:
  - [x] สคริปต์สร้างแมพ `tools/map/boardwalk.luau` (รันซ้ำได้ = สร้างใหม่ทับ แต่เก็บร้าน/แท่นออร่าไว้) → `Workspace.Map` ที่จุดกลาง (0,0,0)
  - [x] **เป็นแมพหลักแล้ว (2026-11-17):** ลบแมพเกาะเดิม + terrain เดิม; ย้ายร้าน `MerchantStall` (Fish Merchant, ปุ่ม Sell) และแท่น `AuraShrine` (Aura Altar, ปุ่ม Roll) มาวางบนลานกลางฝั่งเหนือ (`Map.Buildings`); Spawn อยู่ลานกลาง
  - [x] Claude ทดสอบใน Play: เกิดที่ลานกลาง, ป้าย + ปุ่มกดของร้าน/แท่นออร่าอยู่ครบ, ตกปลาจากสะพานได้
  - [x] Claude ทดสอบใน Play: ยืนขอบสะพาน / ปลายสะพาน / แพลอย → ตกปลาได้ (StarterBay); กลางลานไม่ขึ้นปุ่ม Cast (ถูกต้อง)
  - [x] คุณดูแล้วโอเค / สั่งแก้
- หน้าตา: ลานกลาง 44×44 (เข็มทิศ, ร่ม, ม้านั่ง) → สะพานกว้าง 8 ไป 4 ทิศ; ปลายเหนือ/ตะวันออก/ตะวันตก = ลานตกปลา 28×28 พร้อมร่ม; ระหว่างทางมีลานตกปลาเล็ก 16×16; ทิศใต้มีบันไดลงแพไม้ลอยน้ำ; พื้นไม้สูงจากน้ำ 3 studs บนเสา (เดิม 9 — ปรับลง 2026-11-17), ราว + เชือก, โคมไฟ, ถัง/ลัง/คันเบ็ด
- ทะเล: 2000×2000 studs, ใต้สะพานเป็นทรายตื้น ลาดลงทะเลลึก, เกาะทรายมีมะพร้าว 4 เกาะไกลๆ, หินโผล่น้ำ, ทุ่นรอบลากูน
- จุดวางอาคารไว้ล่วงหน้า (ล่องหน) ใน `Map.Slots`: ShopSlot, AuraAltarSlot, QuestBoardSlot, LeaderboardSlot, RebirthShrineSlot (ปลายเหนือ), BoatSlot (แพใต้), BossArenaSlot (ทะเลเปิดทิศเหนือ)
- ภาพ: `docs/map/boardwalk_hub.png` (ลานกลาง + ร้าน + แท่นออร่า), `docs/map/boardwalk_overview.png`, `docs/map/boardwalk_north.png`
- ขอบทะเล (ชุดผสม, เลือกแล้ว 2026-11-17):
  - [x] แนวทุ่นแดง-ขาว + เชือก ที่รัศมี 560 = เริ่มมีกระแสน้ำ; แนวหินปะการังรัศมี ~610–670
  - [x] กระแสน้ำผลักกลับ (client `BoundaryController`) แรงขึ้นเรื่อยๆ จนว่ายสู้ไม่ได้ที่ ~680 + ข้อความเตือน (ทุก 10 วิ)
  - [x] เลยไปเกิน 720 (หลุดมาได้ด้วยวิธีอื่น) → server (`BoundaryService`) พากลับลานกลาง + ข้อความ
  - [x] หมอกขอบฟ้า (Lighting.Atmosphere) ให้ทะเลดูไม่มีที่สิ้นสุด — ตั้งใน Lighting ของเพลส
  - [x] ตั้งค่าที่ part `Map.Edge.PlayArea` (tag PlayArea): Soft / Hard / Reach / ReturnTo — แมพอื่นที่ไกลเกิน Reach ไม่โดน
  - [x] Claude ทดสอบใน Play: ในลากูนไม่มีแรงผลัก; ว่ายออกจาก 640 นาน 4 วิ ยังอยู่ 636 (โดนผลักกลับ); วาร์ปไป 800 → กลับลานกลางใน 1 วิ
  - ภาพ: `docs/map/boardwalk_edge.png`
- ทดสอบ:
  - [x] 1. Ctrl+S → Play → เกิดบนลานกลาง; เห็น Fish Merchant (ขวาหน้า) + Aura Altar (ซ้ายหน้า)
  - [x] 2. เดินไปร้าน → กด E "Sell All Fish" ได้; ไปแท่นออร่า → กด E "Roll Aura" → เปิดหน้ากาชา Altar
  - [x] 3. เดินไปขอบสะพาน/ปลายสะพาน → ปุ่ม Cast ขึ้น → ตกปลาได้
  - [x] 4. ว่ายออกไปเรื่อยๆ ผ่านแนวทุ่น → ขึ้นข้อความกระแสน้ำ + โดนดันกลับ ว่ายสู้ไม่ได้
  - [x] 5. ปรับขนาด/ระยะ: แก้ตัวเลขบนสุดของ `tools/map/boardwalk.luau` (DECK, SEA, SOFT, HARD, BUILDINGS) แล้วให้ Claude รันใหม่

### B17. Skeleton loading ของรูป
- สถานะ:
  - [x] โค้ด: `UI/New.luau` → `ApplyImage` ใส่ลูก "Skeleton" ให้รูป Art ทุกรูป (ทุกหน้าจอใช้ทางนี้อยู่แล้ว ไม่ต้องแก้ทีละหน้า)
  - [x] Claude ทดสอบใน Play: ตอนรูปยังโหลดไม่เสร็จ Skeleton ขึ้นเป็นภาพ Mystery Fish กระพริบ → รูปจริงโหลดเสร็จ Skeleton หาย
  - [x] คุณกด Save + ลองเอง
- กติกา: ปลา `fish/*` → Mystery Fish, ออร่า `auras/*` → Unknown Aura, อื่นๆ (อุปกรณ์/ui/npc) → กล่องสีอ่อนกระพริบ; ไอคอน global (ล็อก, ✓) ไม่มี skeleton — เพิ่มหมวดใหม่ได้ที่ `SKELETON_ART` ใน `New.luau`
- ทดสอบ:
  - [x] 1. Ctrl+S → Play ครั้งแรกหลังเปิด Studio (cache ยังว่าง) → เปิด Fishdex / Inventory / Shop → ช่องรูปขึ้นเงา Mystery Fish กระพริบสั้นๆ แล้วเปลี่ยนเป็นรูปจริง
  - [x] 2. รูปที่โหลดแล้วเปิดซ้ำ → ไม่เห็น skeleton (ขึ้นรูปทันที)

### B18. Stat ลดเวลารอ Auto Fishing (Auto Wait)
- สถานะ:
  - [x] Stat `AutoSpeed` (แสดงเป็น **"-20% Auto Wait"**) ใน `Config/StatDefs.luau` — `Highlight = true` = ป้ายสีทอง อยู่หน้าสุด, `Reduces = true` = แสดงเป็นลบ
  - [x] ใส่ในของ: Moonsilver Rod -10%, Naga Scale Rod -20%, Glow Grub (เหยื่อ) -10% (`Config/Equipment.luau`)
  - [x] สูตร: รอต่อตัว = `AutoCycleTime` (9 วิ) × (1 − AutoSpeed) × (1 − BiteSpeed×0.5); สูงสุดลด 75%
  - [x] ป้ายใน Shop/Inventory และการ์ดออร่าใช้ `Format.Stat` ตัวเดียวกัน
  - [x] คุณกด Save + ทดสอบ
- ใช้กับ Package/Gamepass ขาย (C6): ใส่ `Stats = { AutoSpeed = 0.25 }` ให้ของนั้น → ป้ายทอง "-25% Auto Wait" ขึ้นเอง
- ทดสอบ:
  - [x] 1. Ctrl+S → Play → Shop → Rods → Moonsilver / Naga Scale มีป้ายทอง "-10% Auto Wait" / "-20% Auto Wait" อยู่หน้าสุด
  - [x] 2. Baits → Glow Grub มีป้ายทอง "-10% Auto Wait"
  - [x] 3. F2 → `equip Rods NagaScaleRod` → เปิด Auto ริมน้ำ → ได้ปลาเร็วขึ้น (ประมาณทุก 7 วิ แทน 9 วิ)

### B16. คำสั่ง Dev สำหรับทดสอบ (เสกของ)
- สถานะ:
  - [x] โค้ดเสร็จ: `Config/Dev.luau` (ใครใช้ได้), `server/Services/DevService.luau` (คำสั่ง), แผง `DevPanel` (F2) bake แล้ว
  - [x] Claude ทดสอบใน Play ผ่าน RemoteFunction จริง: give gems/coins/chest/fish/bait, pity Altar 99 → สุ่มถัดไปได้ Mythic, x10 มี Epic+, claim milestone ได้ครั้งเดียว
  - [x] คุณกด Save + ลองเอง
- ใครใช้ได้: ใน Studio ทุกคน; เกมจริง = เจ้าของเพลส (กลุ่ม: rank ≥ 255) + UserId ใน `Config/Dev.luau` → `Admins`
- วิธีใช้: แชท `!help`, `!give gems 1000` ... หรือกด **F2** เปิดแผง (พิมพ์คำสั่งไม่ต้องมี ! / ปุ่มลัด 10 ปุ่ม)
- คำสั่ง: `give gems|coins <n>`, `give bait <id> <n>`, `give chest <id> <n>`, `give fish <id> <n> [mutation]`, `give aura <id> [n]`, `level <n>`, `xp <n>`, `pity <banner> <n>`, `pulls <banner> <n>`, `unclaim <banner>`, `equip <หมวด> <id>`, `clearbag`, `reset` (ล้างเซฟตัวเอง), `help` — ชื่อ id ไม่สนตัวพิมพ์เล็ก/ใหญ่
- ทดสอบ:
  - [x] 1. Ctrl+S → Play → กด F2 → แผงขึ้น → กด "+1,000 Gems" → เพชรเพิ่ม + บรรทัด ✓ ใน log
  - [x] 2. แชท `!give fish GlowEel 3` → แจ้ง [Dev] +3 GlowEel → เปิด Inventory เห็นกอง x3
  - [x] 3. `pity Altar 99` → เปิด Aura Altar → ROLL x1 → ได้ Mythic
  - [x] 4. `reset` → เซฟกลับเป็นผู้เล่นใหม่ (เหรียญ 0, เพชร 15)
  - [x] 5. (เกมจริง) ผู้เล่นที่ไม่ได้อยู่ใน Admins กด F2 / พิมพ์ ! → ไม่มีอะไรเกิดขึ้น

### B15 + B6 + B9. Events hub (E0) + หน้ากาชา G1/E1 + x10 Summary
- สถานะ:
  - [x] Server: banner + pity (Mythic ทุก 100, แยกต่อ banner) + x10 (-10%, การันตี Epic+) + milestone claim — `Config/AuraBanners.luau`, `AuraService.Pull/ClaimMilestone`
  - [x] ข้อมูล: `Config/Events.luau` (การ์ด = 1 รายการ, ปุ่ม OPEN รัน Action: Gacha / Menu / Teleport / Info) — เพิ่มอีเวนต์ = เพิ่มรายการ; ประเภท action ใหม่ = เพิ่มไฟล์ `UI/EventActions/<Kind>.luau`
  - [x] หน้าจอ bake แล้ว: `Events` (E0 การ์ด 2 คอลัมน์), `GachaPage` (แบบ G1 ทุก banner; banner อีเวนต์เพิ่ม ‹ ย้อนกลับ, เวลา, x2 rate-up, FEATURED, Milestones + popup; x10 Summary แบบ G6)
  - [x] Figma: E0 · Events hub, E1 (variant ของ G1) + E1b popup
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน
- ทดสอบ:
  - [x] 1. Ctrl+S → Play → Main Menu → **Events** → หน้ารวมการ์ด 4 ใบ: Neon Tide (LIMITED + เวลา), Aura Altar, Naga Boss / Daily Login (SOON จาง กดไม่ได้)
  - [x] 2. OPEN ที่ Aura Altar → หน้ากาชาแบบ G1 (ไม่มีเวลา/ไม่มี Milestones); ปุ่ม ROLL AURA ในหน้าต่าง Auras และแท่นบูชาในแมพ → เปิดหน้านี้เหมือนกัน
  - [x] 3. ROLL x1 → วงล้อหมุน + การ์ดผล; เพชรลด 5; "Mythic guaranteed in N" ลดลง 1
  - [x] 4. ROLL x10 → เพชรลด 45; มีอย่างน้อย 1 ตัว Epic ขึ้นไป; เห็นตาราง 10 ผล (G6) + EQUIP BEST / ROLL x10 AGAIN / CLOSE
  - [x] 5. ติ๊ก Skip animation → สุ่มแล้วไม่มีวงล้อ; ติ๊ก Auto-roll until Epic+ → สุ่ม x1 ต่อเนื่องจนได้ Epic+ / เพชรหมด / เอาติ๊กออก
  - [x] 6. กด ‹ → กลับหน้ารวม; OPEN Neon Tide → เวลา, x2 ที่ Neon Wave/Abyssal Shadow (1/50, 1/2,500), แถว FEATURED, แถบ Milestones N/400
  - [x] 7. สุ่มบน Neon Tide ครบ 10 ครั้ง → Milestones มีจุดแดง → View → กด CLAIM ช่อง 10 → +20 gems; กดซ้ำไม่ได้
  - [x] 8. pity ของ Neon Tide กับ Aura Altar นับแยกกัน (สุ่มที่หนึ่ง อีกที่ไม่ลด)
  - [x] 9. เพชรไม่พอ → ปุ่ม ROLL เป็นสีเทาหม่น

### B14. มินิเกม Twin tubes (Figma 03 · A2)
- สถานะ:
  - [x] โค้ดเสร็จ + bake (`Screens/Minigame.luau` ใหม่; กลไก/ตัวเลขเดิม → server ตรวจเวลาเหมือนเดิม)
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน
- Done when: มินิเกมเป็นการ์ดแคบ 2 หลอด: หลอดน้ำ (แถบจับ + ปลาลึกลับ) และหลอดทองที่มีทุ่นลอยบนระดับ; แถบจับเปลี่ยนสีตามแรงตึง (มิ้นต์ = อยู่บนปลา, ทอง = หลุด, แดง = ใกล้ขาด); ไม่มีชิป LOOSE/GOOD/SNAP และไม่มีชิปความลึก
- ทดสอบ:
  - [x] 1. Ctrl+S → Play → ตกปลา → การ์ด 2 หลอดขึ้นกลางจอ หน้าตาเหมือน Figma 03
  - [x] 2. กดค้าง → แถบจับลอยขึ้น ปล่อย → จมลง; ทับปลา → หลอดทองเพิ่ม ทุ่นลอยตาม; แถบเป็นสีมิ้นต์
  - [x] 3. ปล่อยให้หลุดจากปลา → แถบเป็นสีทอง; ใกล้แพ้ → สีแดง
  - [x] 4. ชนะ → ได้ปลา; แพ้ → ปลาหลุด; ตกตัวต่อไป → เริ่มใหม่สะอาด

### B13. Main Menu hub: ทุกปุ่มทำงานจริง หรือแจ้งตามจริง
- สถานะ:
  - [x] โค้ดเสร็จ (เฉพาะ controller ไม่ต้อง bake ใหม่)
  - [x] ทดสอบผ่าน (desktop)
- Done when: Shop/Auras/Fishdex เปิดหน้าต่าง, **Bag เปิด Inventory**, Friends เปิดหน้าชวนเพื่อนของ Roblox (ใน Studio จะแจ้งว่าใช้ได้แค่เกมจริง), Quests/Rebirth/Events/Settings แจ้งข้อความตาม `Config/Features.luau` (Rebirth บอกเลเวลที่ต้องถึง); จุดแดง Bag = มีของใหม่/กระเป๋าเต็ม; ป้าย Rebirth = `Lv.100` จนกว่าจะถึง
- เผื่อไว้: `src/shared/Config/Features.luau` มีค่าของระบบที่ยังไม่ทำ (Quests 3/วัน +5 Gems, Rebirth Lv.100 +0.25x, Events ทุก 30 นาที) — เปิดใช้โดยตั้ง `Enabled = true` แล้วเพิ่ม action ใน MainMenuController
- ทดสอบ:
  - [x] 1. Play → กด M (หรือปุ่ม Menu) → กด **Bag** → หน้าต่าง Inventory เปิด
  - [x] 2. กด Shop / Auras / Fishdex → เปิดหน้าต่างนั้น
  - [x] 3. กด Quests / Events / Settings → แจ้งข้อความ coming soon ตาม Features; Rebirth → "Rebirth is coming soon! (unlocks at Lv.100 - you are Lv.N)"
  - [x] 4. กด Friends → ใน Studio แจ้ง "Invites only work in a live game"; ในเกมจริง (publish) ขึ้นหน้าชวนเพื่อน
  - [x] 5. ตกปลาได้ตัวใหม่ → เปิด Menu → ปุ่ม Bag มีจุดแดง → เปิด Inventory แล้วเปิด Menu อีกครั้ง → จุดหาย (ถ้ากระเป๋าไม่เต็ม)
  - [x] 6. ปุ่ม Rebirth มีป้าย `Lv.100`

### B20. Virtual Grid (performance): สร้างเฉพาะช่องที่มองเห็น + ใช้ซ้ำ
- แนวคิดจาก Global Visualizer (Unity, `F:\GameProject\Pale Vertica\Packages\com.globalvisualizer.core`): ของ 500 ชิ้นใช้ทรัพยากรพอ ๆ กับ 20 ชิ้น
- โมดูล: `src/client/UI/VirtualGrid.luau` (อ่าน CellSize/Padding จาก UIGridLayout เดิมแล้วลบทิ้ง, pool ต่อชนิดการ์ด, Create ครั้งเดียว + Bind ทุกครั้ง, รองรับ UIScale ของ FitToScreen และ grid ซ้อนใน Window body)
- ใช้กับ: Inventory (ช่องไอเท็ม), Aquarium (การ์ดปลา/ช่องว่าง/ล็อก), Mastery (การ์ดสาย), Put in Tank (การ์ดปลาในกระเป๋า). ไม่ได้ทำ: Shop/Fishdex/Auras (เป็นหน้า pager ช่องคงที่อยู่แล้ว), Events/Quests (ของน้อย)
- สถานะ:
  - [x] โค้ดเสร็จ + `node tools/check.mjs` ผ่าน
  - [x] Claude ทดสอบโมดูลใน Studio (edit mode): 500 ชิ้น 5 คอลัมน์ สร้าง view แค่ 20 อัน, เลื่อนไปแถว 50 รวมแค่ 30 อัน, ตำแหน่ง/ขนาด canvas ถูก
  - [ ] ทดสอบในเกม (Play)
- Done when: 4 หน้าจอข้างบนหน้าตา/การกดเหมือนเดิมทุกอย่าง แต่ไม่ Destroy/Clone การ์ดใหม่ทุกครั้งที่ข้อมูลเปลี่ยน
- ทดสอบ:
  - [ ] 1. หยุด Play เดิม (โค้ดเก่า) → Play ใหม่ → กด **B** → Inventory ช่องเรียงเหมือนเดิม 5 คอลัมน์ ช่องว่าง "+" ครบตามความจุ
  - [ ] 2. คลิกช่อง → ขอบเลือก + ปุ่ม Sell xN; คลิกซ้ำ = ยกเลิก; สลับแท็บ/Sort แล้วรายการถูก; ขาย/เปิดกล่องแล้วช่องอัปเดตทันที
  - [ ] 3. กระเป๋าใหญ่ (Dev: เสกกระเป๋า + ปลาเยอะ) → เลื่อนลงสุด/ขึ้นสุด ไม่มีช่องว่างหาย ไม่มีช่องซ้อนกัน
  - [ ] 4. Aquarium: การ์ดปลา (กด = เอาออก), Add fish, Expand (เฉพาะช่องแรกกดได้) ทำงานเหมือนเดิม
  - [ ] 5. Put in Tank: แตะการ์ด +1, MAX/CLR, CONFIRM; เลื่อนลงแล้วแตะ ต้องเลือกปลาตัวที่แตะจริง
  - [ ] 6. Mastery: ปุ่ม UPGRADE เปลี่ยนเป็นสีเขียวทันทีที่ Pearls พอ; MAX แสดงถูก; ข้อความ "now → next" ยาวยังย่อให้พอดี
  - [ ] 7. มือถือแนวนอน (หน้าต่างถูกย่อด้วย UIScale) → เลื่อน grid แล้วการ์ดขึ้นครบ ไม่โผล่ช้า

### B22. Gacha page ใหม่ (concept D "Glass Card")
- คำขอ (2026-11-20): สร้างเมนูจริงแทนหน้า Gacha เดิม ตาม Figma concept D (`3662:56279`, ที่คุณแก้แล้ว) + เอาส่วนที่ขาดจาก E1 มาใส่: Mythic guaranteed in, Milestones, Skip animation, Auto-roll until Epic+ (เพิ่มใน Figma D ด้วย: `3662:56492`, `3662:56498`, `3662:56509`)
- โค้ด: `UI/Screens/GachaPage.luau` (layout ใหม่ทั้งหน้า: เต็มจอ, canvas 1280x720 ย่อ/ขยายตามจอ, พื้นหลัง `ui/gacha_bg_celestial`), `UI/GachaPage.luau` (เติมข้อมูล), `Controllers/GachaPageController.luau` (path ใหม่ + เปิด Store)
  - ซ้าย: การ์ดแบนเนอร์จาก `Config/AuraBanners` ที่เปิดอยู่ (Event ก่อน) กดสลับแบนเนอร์ได้
  - กลาง: Info Card (ริบบิ้น, ชื่อ, เวลา, คำอธิบาย rate-up, ออร่าเด่น, Legendary pity), กล่อง Mythic pity, กล่อง Milestones (View = popup เดิม), Skip / Auto
  - ขวา: ภาพวาด `auras_Art/*` (ถ้าออร่านั้นไม่มีภาพวาดใช้ลูกแก้วแทน) + ป้ายชื่อ rarity / ดาวที่มี, toggle Gems / Tokens (Tokens = แจ้ง "coming soon" เพราะยังไม่มีราคา), ROLL x1 / x10 (ราคาในแคปซูล + ป้าย RARE+)
  - ล่างซ้าย: Shop (เปิด Store แท็บ Gems), Rates (popup อัตราจริง), History (ผล x10 ล่าสุด); ชิป Gems ไม่มี + กดแล้วเปิด Store
  - ระบบเดิมยังอยู่ครบ: สุ่ม x1/x10, reveal, สรุป x10, รับ milestone, auto-roll, pity
- รูปใหม่ลง catalog แล้วแต่ **ยังไม่อัปโหลด** (id = 0 ในเกมจะเห็นพื้นสีแทน): `ui/gacha_bg_*` 3 รูป + `auras_Art/*` 6 รูป → ชุดพร้อมอัปโหลด `assets/upload/2026-11-20_gacha/` + `ids.csv`
- สถานะ:
  - [x] โค้ดเสร็จ + `node tools/check.mjs` ผ่าน
  - [x] bake `node tools/ui/bake.mjs GachaPage` แล้ว (764 instances), Rojo sync โค้ดใหม่เข้า Studio แล้ว, ภาพ edit mode ตรงกับ Figma D
  - [ ] Ctrl+S เซฟ place (ยังไม่ได้เซฟ)
  - [x] 2026-11-20 รอบ 2: เอา History ออก (Figma + โค้ด); ออร่าเด่นใน Info Card กดแล้วเปิด Item Card (Kind Aura); Options มุม 10 ตาม Figma; ตอนสุ่ม หน้า Gacha ซ่อนหลังหน้าต่างสุ่ม (ไม่เห็นทะลุ) แล้วกลับมาเมื่อปิด / Roll again
  - [x] ท่าสุ่มใหม่ **Altar Charge** (Figma "Gacha Roll Animation — 4 options" แบบ 1 `3664:56519`): `UI/Screens/AuraReel.luau` (กลุ่ม Charge: พื้นหลัง cosmic, แท่น, วงแหวน 3 วง, ลูกแก้วปริศนา, ประกาย) + `UI/AuraReel.luau` (ลูกแก้วตกลงแท่น → วงแหวนชาร์จ สีไล่ ขาว → ม่วง → สีความหายาก → Legendary+ สั่น + หยุด → ระเบิดแสง + rays + confetti → การ์ดผลลัพธ์เดิม); แตะเพื่อข้าม; bake AuraReel + GachaPage แล้ว
  - [x] Altar Charge รอบ 2 ตาม Figma แบบ 1 ที่คุณแก้ (`3664:56519`): ไม่มี Rays (ลบใน Figma ด้วย: `3664:56560`, `3664:56589`), การ์ดผลลัพธ์เป็นแถบเล็ก (rarity + ชื่อ + NEW! + EQUIP / ROLL AGAIN / CLOSE) ใต้ภาพวาดออร่า, Item Card ของออร่า (stats + Star Up) เปิดข้างภาพ; ขนาดตามแบบ 1920x1080 (ภาพ storyboard 560x315 x 3.43) แล้วย่อตามจอ; `UI/Screens/AuraReel.luau` + `UI/AuraReel.luau` เขียนใหม่ทั้งคู่, bake แล้ว (105 instances)
  - [x] รอบ 4: ภาพใหญ่ขวา (Hero) + ป้ายชื่อ = ออร่าเด่นของตู้นั้นเสมอ (ไม่เปลี่ยนตามที่สุ่มได้; Altar ไม่มี Featured จึงใช้ออร่าหายากสุดที่มีภาพวาด); สุ่ม x10: หลังโชว์ตัวที่หายากสุด ปุ่มกลางเป็น **SEE ALL 10** → หน้าสรุปทั้ง 10 (เดิมปุ่มนี้สุ่ม x1 ต่อทำให้ไม่เห็นผลทั้ง 10); CLOSE / EQUIP / แตะนอกการ์ด ก็ไปหน้าสรุปเหมือนกัน
  - [x] อัปโหลด 8 รูปแล้ว (`upload_assets.py`) + แปลง decal → image id (`resolve_decals.mjs` 8/8), `UIAssets.luau` 202/203; เช็คใน Studio: พื้นหลัง 2 รูป + ภาพวาด 5 รูปขึ้นแล้ว, ลูกแก้ว `auras/*` 6 ตัวเดิมยังเป็นลูกแก้วถูกต้อง (ไม่ต้องอัปใหม่)
  - [ ] `auras_Art/AbyssalShadow` (`122339939840558`) ยังไม่ขึ้นตอนเช็ค (น่าจะรอ Roblox ตรวจ) — เช็คอีกครั้งใน Play; ถ้ายังว่างให้อัปโหลดรูปนี้ใหม่
  - [ ] ทดสอบ Play: ท่าสุ่ม Altar Charge + ไม่มี UI ทะลุ + x10 → SEE ALL 10 → หน้าสรุป
  - [ ] อัปโหลด 9 รูป แล้ว `python -I tools/art/sync_ui_assets.py assets/upload/2026-11-20_gacha/ids.csv`
  - [ ] ทดสอบใน Play
- Done when: เปิด Gacha จาก Events / Auras / แท่น Altar แล้วได้หน้า D เต็มจอ ทุกปุ่มทำงาน ไม่ล้นจอทั้งจอกว้างและแคบ
- ทดสอบ:
  - [ ] 1. Play → เปิด Events → กด OPEN ที่ Neon Tide → หน้า Aura Summon เต็มจอ ซ้ายมีการ์ด Neon Tide (เลือกอยู่, ขอบหนา) และ Aura Altar
  - [ ] 2. กดการ์ด Aura Altar → ชื่อ/คำอธิบาย/ออร่าเด่น/ภาพขวาเปลี่ยน, กล่อง Milestones หายไป (Altar ไม่มี milestone)
  - [ ] 3. ROLL x1 → reveal เล่น → Gems ลด 5, ข้อความ pity ลดลง 1; ROLL x10 → ลด 45 แล้วขึ้นหน้าสรุป x10
  - [ ] 4. ติ๊ก Skip animation → สุ่มแล้วไม่มี reveal; ติ๊ก Auto-roll → สุ่มเองจนได้ Epic+ (กดอีกครั้งเพื่อหยุด)
  - [ ] 5. Rates → popup อัตราจริง, กด X หรือนอกกรอบปิด; Shop และชิป Gems → เปิด Store แท็บ Gems; กดออร่าเด่นใน Info Card → Item Card ของออร่านั้น
  - [ ] 5b. ROLL x1 → หน้า Gacha หายไป เห็นแค่ลูกแก้วตกลงแท่น วงแหวนชาร์จ สีไล่ไปทางสีความหายาก → ระเบิดแสง → การ์ดผลลัพธ์ → CLOSE แล้วหน้า Gacha กลับมา; แตะจอระหว่างชาร์จ = ข้ามไปการ์ดทันที
  - [ ] 6. กด Tokens ที่ toggle → แจ้ง coming soon และยังเลือก Gems อยู่
  - [ ] 7. Test → Device → มือถือแนวนอน → หน้าย่อพอดีจอ ไม่มีอะไรล้น

### B21. Item Detail Card + Inventory v2
- คำขอ (2026-11-18): กดไอเท็มที่ไหนก็ได้ (ช่อง Inventory, ช่องใน Character, รูปใน Shop, Fishdex ...) แล้วมีการ์ดรายละเอียดเด้งข้าง ๆ ผ่าน `ItemDetail.Show(itemId, anchor)`; ไม่ได้เป็นเจ้าของ = ไม่มี Action container; เป็นเจ้าของ = มีปุ่มตามชนิดไอเท็ม. Rod / Line / Aura กลายเป็นไอเท็ม (Rod เก็บ Modifier ได้ในอนาคต), หน้าต่าง Auras ย้ายเข้า Inventory, Bag เปลี่ยนเป็นอัปเกรด (ไม่มีวันย้อนไปกระเป๋าเล็กกว่า), แท็บหมวดย้ายไปด้านข้างเป็นไอคอน
- Figma: section "18A · Inventory v2 — 6 options" (`3597:43204`, x 27200 y 0) + "18B · Item Detail Card — 8 options" (`3597:44287`, x 27200 y 3400); สคริปต์ `docs/figma/item_detail.py`; ภาพ `docs/figma/item_inventory_options.png`, `docs/figma/item_card_options.png`
- รูปที่ต้องสร้าง: `docs/ART_PROMPTS.md` ชีต **17** (ไอคอนแท็บ `ui/tabs/*` + bag_upgrade) และ **18** (ไอคอน Mastery `ui/mastery/*`)
- สถานะ:
  - [x] ออกแบบใน Figma: การ์ด 8 แบบ (A–H), Inventory 6 แบบ (1–6), หน้าต่าง Bag Upgrade, การ์ดทุกชนิดไอเท็ม (แบบ A), API/กฎการวางการ์ด
  - [x] เพิ่ม prompt ชีต 17 + 18
  - [x] คุณเลือก Inventory แบบ 2 Bookmark Tabs (ขอให้เล็กลง) — ใช้การ์ดแบบ A
  - [x] Figma FINAL: section "18 · Inventory (Bookmark Tabs) — FINAL" (`3598:46643`, x 27200 y 6600) — หน้าต่าง 600x480, ช่อง 72, แท็บที่คั่นหนังสือ 44x40; ปุ่ม Action สูงคงที่ 48 (ชื่อ + ราคาอยู่บรรทัดเดียว, ปุ่มไอคอน 48x48); แท็บ Rods / Fish (SELL ALL) / Auras (ไม่มีของ การ์ดพลิกซ้าย); Bag Upgrade ด้วยเหรียญ และขั้นสุดท้าย **Bottomless Bag ใช้ Robux เท่านั้น** (= Infinite Bag pass 349 R$); สคริปต์ `docs/figma/inventory_final.py`, ส่งด้วย `docs/figma/send_blocks.py`; ภาพ `docs/figma/inventory_final.png`
  - [x] แก้ **17 · Character** ให้เข้ากับระบบใหม่ (`3599:48078`): หน้าต่าง 720x520, ช่องที่ใส่ = Rod / Line / Bait / Aura (เอา Bag ออก เพราะกระเป๋าเป็นอัปเกรด), แท็บมีไอคอน, กดของ = Item Card A แทนแถบรายละเอียดเดิม; ภาพ `docs/figma/character_v2.png`
  - [x] สร้างรูปชีต 17/18 (คุณ gen ให้) → ตัดแล้ว `assets/art/ui/tabs/*` (9) + `assets/art/ui/mastery/*` (9), ลง `assets/catalog.json` + `UIAssets.luau` (id ยังเป็น 0), ชุดพร้อมอัปโหลด `assets/upload/2026-11-18_icons/` (18 รูปชื่อไม่ซ้ำ + `ids.csv`)
  - [x] ใส่รูปเข้า Figma: แท็บ Inventory / Character / ตัวเลือก, การ์ด Mastery 7 สาย (แทนไอคอนเวกเตอร์ขาว) ใน section "Economy · 3 Mastery"
  - [x] อัปโหลด 18 รูปขึ้น Roblox แปลง Decal ID เป็น Image ID และซิงค์ `ids.csv`, catalog และ `UIAssets.luau` แล้ว
  - [ ] ทดสอบไอคอนใน Play: กด B ดูแท็บ Inventory ทั้ง 7 และเปิด Bag Upgrade เมื่อมีปุ่ม UPGRADE, กด C ดูแท็บ Character 4 แท็บแล้วเปิดการ์ดคันเบ็ดที่เป็นเจ้าของเพื่อดูช่อง Modifiers, เปิด Mastery ดูรูปการ์ดทั้ง 7 และป้าย Total Lv.
  - [x] เลือกช่องว่างแบบ **5 Bubbles** (ฟองน้ำเล็ก 3 เม็ดบนพื้นทราย) + ช่อง Get More เป็นลูกศร "More" สีส้มอ่อน — ใส่ใน Figma: 18 FINAL, 17 Character, component Item Slot (State=Empty) ในบอร์ด Components
  - [x] ในเกม: `Make.ItemSlot` ช่องว่างเปลี่ยนจาก "+" เป็นฟอง 3 เม็ด (`Screens/Components.luau`), bake Components + Inventory ลง Studio แล้ว — `node tools/check.mjs` ผ่าน
  - [x] โค้ด: แถวสุดท้ายของ Inventory เติมช่องฟองจนครบแถวเสมอ (แม้กระเป๋าเต็ม หรือรายการยาวเกินหนึ่งหน้า) — `InventoryController.luau` refresh, `node tools/check.mjs` ผ่าน
  - [ ] ทดสอบแถวครบ: Play (Rojo sync แล้ว) → กด **B** → แท็บ Fish ที่มีของไม่ครบแถว (เช่น 24 กอง ใน 7 คอลัมน์) → แถวสุดท้ายมีช่องฟองต่อจนครบ 7 ช่อง; ลองแท็บอื่นก็ครบแถวเหมือนกัน
  - [ ] ทดสอบช่องว่าง: Ctrl+S เซฟ place → Play → กด **B** → ช่องว่างท้ายกระเป๋าเป็นฟอง 3 เม็ด ไม่มี + แล้ว; คลิกช่องว่างไม่เกิด error; ช่อง Aquarium "Add fish" ยังเป็น + เหมือนเดิม (คนละแบบ)
  - [x] data model (2026-11-18): **ไม่เพิ่ม field ในเซฟ** — Rod/Line ใช้ `Owned`/`Equipped` เดิม, Aura ใช้ `Auras.Owned` เดิม, ระดับกระเป๋า = กระเป๋าที่ใส่อยู่ (ladder เรียงตาม Capacity ใน `Inventory.BagLadder/NextBag`), Modifiers = ช่องล็อก "Soon" (ยังไม่มีข้อมูล) — server กันซื้อ/ใส่กระเป๋าที่เล็กกว่า (`ShopService.Buy/Equip`)
  - [x] คุณขอ (2026-11-18): แท็บ Auras เป็นไอเท็มปกติ — แสดงเฉพาะออร่าที่มี ไม่มีช่องล็อก (Auras dex เก็บข้อมูลทำแยกทีหลังได้)
  - [x] ทำในเกม (Inventory): `UI/Screens/Inventory.luau` (หน้าต่าง 600x480, แท็บคั่นหนังสือ 7 แท็บ All/Fish/Rods/Lines/Auras/Baits/Treasure, ช่อง 72 x 7 คอลัมน์, ป้ายความจุ + ปุ่ม UPGRADE, หน้าต่าง Bag Upgrade), `UI/Screens/ItemDetail.luau` + `UI/ItemDetail.luau` (การ์ด A: ชื่อ/แท็ก/ดาว/สเตต/คำอธิบาย/ป้าย/Modifiers/ปุ่มสูง 48; วางขวาช่อง พลิกซ้ายเมื่อไม่พอ; กดนอกการ์ด = ปิด), `InventoryController` เขียนใหม่, ปุ่ม Auras ใน Main Menu เปิด Inventory แท็บ Auras, `Components` ItemSlot เพิ่ม `Ring` (ขอบฟ้า = ใส่อยู่) + `Locked` — `node tools/check.mjs` ผ่าน
  - [x] bake ลง Studio แล้ว (Components, Inventory, ItemDetail) — **คุณต้องกด Ctrl+S เซฟ place**. แก้ `tools/ui/bake.mjs` ให้ส่งเฉพาะหน้าจอที่ bake (+ ที่มันใช้) เพราะรวมทุกหน้าจอเกิน 200,000 ตัวอักษรที่ Studio รับได้
  - [x] Claude ทดสอบใน Play (2026-11-18): กด B เปิดได้, แท็บ All/Rods/Auras, การ์ดเหยื่อ/คันเบ็ด/ออร่าขึ้นข้างช่องถูก, EQUIP ออร่าแล้วการ์ด+ขอบฟ้าเปลี่ยนทันที (เปลี่ยนกลับเป็น Dragon Emperor แล้ว), คลิกช่องอื่นการ์ดย้ายในคลิกเดียว, คลิกที่ว่างปิดการ์ด, ไม่มี error. แก้ระหว่างทดสอบ: ปุ่มในการ์ดไม่ขึ้น (UIFlexItem ทับชั้น Face/Lip ของปุ่ม), ราคาในปุ่มย่อ (90K) ไม่ขึ้น 2 บรรทัด
  - [x] ทดสอบ Bag Upgrade ด้วยโปรไฟล์จำลอง: จ่าย 800 Coins เพื่อเพิ่มจาก 6 เป็น 10 ช่องและใส่กระเป๋าใหม่ทันที ใส่ใบเล็กลงไม่ได้ ขั้นสูงสุดแบบ Coins มี 30 ช่อง หลังจากนั้นเป็น Infinite Bag pass ผู้มี pass แล้วจะไม่เห็น UPGRADE
  - [ ] ทดสอบหน้าซื้อ Infinite Bag จริงจากบัญชีที่ยังไม่มี pass รวมถึง SELL/OPEN และแท็บ Treasure
  - [x] ผูกไอคอนชุดใหม่กับแท็บ Inventory และ Character, Bag Upgrade, ช่อง Modifiers, การ์ด Mastery และป้าย Total Lv. ส่วนไอคอน Materials ลงทะเบียนใน catalog แล้วสำหรับแท็บในอนาคต
  - [x] (2026-11-18 รอบ 2) ต่อการ์ดกับที่อื่น: กดรูปใน **Shop** (Rods/Lines/Baits/Bags) และ **Fishdex** (การ์ดปลา, ปลาที่ยังไม่ได้ = ???) → การ์ดเด้ง; ปุ่ม Hit ใสสร้างตอนเริ่มใน `MenuController`, การ์ดชนิดใหม่ `Bag`, `Species`, เหยื่อที่ยังไม่มี (Get from Shop)
  - [x] ปุ่มในการ์ดมีไอคอน: `ENHANCE | ไอคอน 1.2K`, `STAR UP | Token 4`, `SELL | เหรียญ 1.2K` บรรทัดเดียว (ปุ่มที่มีราคากว้างกว่า 1.6 เท่า); ปุ่ม Lock ไม่ทำ (ยังไม่มีระบบล็อก)
  - [x] **หน้าต่าง Character (17 v2)** ในเกม: `UI/Screens/Character.luau` + `CharacterController` — เปิดด้วยปุ่ม **C** หรือกดรูปโปรไฟล์ใน Main Menu; ตัวละครจริงหมุนได้ (ลาก), ช่องที่ใส่ Rod/Line/Bait/Aura, สเตตหลัก 5 ตัว, แท็บ Rods/Lines/Baits/Auras + ของที่มี; กดอะไรก็ได้ = การ์ด
  - [x] **Aura Dex**: หน้าต่าง Auras เดิม (ออร่าทุกตัว, ??? ถ้ายังไม่ได้, โอกาส, จำนวน) เปลี่ยนชื่อเป็น "Aura Dex" เปิดจากปุ่ม **AURA DEX** ในแท็บ Auras ของ Inventory; ปุ่ม Auras ด้านซ้ายจอ + Main Menu เปิด Inventory แท็บ Auras
  - [x] Shop แท็บ Bags: กระเป๋าที่เล็กกว่าใบที่ใช้ขึ้น "Owned" / "Smaller" (กดไม่ได้), ใบที่ใช้ = "In use"
  - [x] รวมโค้ดรายการไอเท็ม + ช่อง 72 ไว้ที่ `UI/ItemSlots.luau` (Inventory + Character ใช้ร่วมกัน)
  - [x] Claude ทดสอบใน Play: Character (C) + การ์ดจากช่องที่ใส่, การ์ดจาก Shop / Fishdex, ปุ่ม Auras ด้านซ้าย → Inventory, AURA DEX → Aura Dex, Shop Bags แสดง Owned — ไม่มี error. แก้ระหว่างทดสอบ: แถวสเตตชื่อ "Name" ชนกับ property, ตัวละครหันหลัง/ชิดชื่อ, ราคาในปุ่มล้น
- Done when: กดช่องไอเท็มที่ไหนก็ได้แล้วการ์ดเด้งข้างช่องนั้นถูกด้าน (ขวา หรือพลิกซ้ายเมื่อที่ไม่พอ); ของที่ไม่มีไม่มีปุ่ม; Inventory มีแท็บไอคอนด้านข้าง; กระเป๋าอัปเกรดได้จากชิปความจุ
- ทดสอบในเกม (หลัง bake + Ctrl+S → Play):
  - [ ] 1. กด **B** → หน้าต่าง Inventory ใหม่ (เล็กลง) มีแท็บไอคอน 7 อันด้านซ้าย; แท็บที่เลือกยื่นยาวกว่าและสีเดียวกับหน้าต่าง; ช่องว่างเป็นฟอง 3 เม็ด
  - [ ] 2. คลิกปลา → การ์ดเด้งขวาช่อง (ช่องคอลัมน์ขวาสุด = เด้งซ้าย) มี xN / kg / HOT; กด SELL ได้เงิน การ์ดปิดเมื่อกองหาย; กด TANK ปลาเข้าบ่อ
  - [ ] 3. คลิกช่องเดิมซ้ำ = ปิดการ์ด; คลิกช่องอื่น = การ์ดย้ายไปช่องนั้นในคลิกเดียว; คลิกที่ว่างในหน้าต่าง = ปิด
  - [ ] 4. แท็บ Rods / Lines: เห็นเฉพาะของที่มี, อันที่ใส่อยู่มีขอบสีฟ้า; การ์ดมีป้าย Equipped, ปุ่ม EQUIP / EQUIPPED, ENHANCE + ราคา (กดแล้ว +N ขึ้น); คันเบ็ดมีแถว Modifiers ล็อก + Soon
  - [ ] 5. แท็บ Auras: เห็นเฉพาะออร่าที่มี (ไม่มีช่องล็อก); การ์ดมีดาว, โอกาส 1/N, EQUIP / UNEQUIP, STAR UP + จำนวน Token; footer "N owned" + ROLL AURA เปิดหน้ากาชา Altar
  - [ ] 6. Main Menu → Auras → เปิด Inventory ที่แท็บ Auras
  - [ ] 7. แท็บ Baits: EQUIP / UNEQUIP; แท็บ Treasure: OPEN ได้รางวัล; แท็บ Fish: footer Total + SELL ALL (ยืนยันก่อน)
  - [ ] 8. ปุ่ม Sort ในแถวหัว: แท็บปลา/กระเป๋าวน Value/Rarity/Count/Name, แท็บอุปกรณ์วน Rarity/Name
  - [ ] 9. ป้ายความจุ → UPGRADE → หน้าต่าง Upgrade Bag: แถวกระเป๋า 5 ใบ + Bottomless, ขั้นถัดไปขอบฟ้า; เงินพอ = ปุ่มทอง กดแล้วความจุเพิ่ม; ขั้นสุดท้ายเป็นปุ่ม GET R$ 349 (เปิดหน้าซื้อ Infinite Bag)
  - [ ] 10. มี Infinite Bag แล้ว: ป้ายเป็น `/ Inf` และไม่มีปุ่ม UPGRADE; Shop แท็บ Bags ซื้อ/ใส่กระเป๋าที่เล็กกว่าไม่ได้ (แจ้งเตือน)
  - [ ] 11. กด **C** → หน้าต่าง Character: ตัวละครคุณหันหน้า ลากหมุนได้; ช่อง ROD/LINE/BAIT/AURA ตรงกับที่ใส่; กดช่อง = การ์ด; สเตตตรงกับ HUD
  - [ ] 12. Main Menu → กดรูปโปรไฟล์ (มุมซ้ายบน) → เปิด Character
  - [ ] 13. Shop → กดรูปคันเบ็ด/สาย/เหยื่อ/กระเป๋า → การ์ด (ของที่ไม่มี = แถว Get from, ไม่มีปุ่ม); Fishdex → กดรูปปลา → การ์ด (ยังไม่ได้ = ???)
  - [ ] 14. Inventory แท็บ Auras → AURA DEX → หน้าต่าง "Aura Dex" มีออร่าทุกตัว
- ทดสอบ (ใน Figma ตอนนี้):
  - [x] 1. เลือกการ์ด + Inventory แล้ว
  - [ ] 2. เปิด Figma section "18 · Inventory (Bookmark Tabs) — FINAL" → ปุ่มทุกปุ่มในการ์ดสูง 48 เท่ากัน ราคาอยู่บรรทัดเดียวกับชื่อปุ่ม ไม่ล้นการ์ด
  - [ ] 3. ดู F5: ขั้นสุดท้าย Bottomless Bag มีป้าย Robux และปุ่ม GET 349
  - [ ] 4. section "17 · Character" → ช่องที่ใส่ไม่มี Bag แล้ว มี Aura แทน

#### Aura Index แบบกริด
- [x] เลือกแบบ 06 Gem Tracker ใน Figma Ro Offline > Out Space: [หน้าต่าง Aura Index](https://www.figma.com/design/givb0hmQYmmaOy7p7DGtb2/Ro-Offline?node-id=3609-53540) และ [บอร์ดพร้อม Item Card](https://www.figma.com/design/givb0hmQYmmaOy7p7DGtb2/Ro-Offline?node-id=3611-54189)
- [x] ลบตัวเลือกอื่น, Reward rule และแถบ Collection progress เดิม; ใช้ป้าย 3 / 5 แบบ Inventory และปุ่มแบ่งหน้าแบบ Aura Dex; Chance อ่านจากค่าจริงใน Config
- [x] ตรวจค่าลิงก์ Prototype จากการ์ดที่ปลดล็อก 3 ใบไป Item Card เดิม และการ์ดล็อก 2 ใบไม่มีลิงก์เปิด
- [ ] ยืนยันจำนวน Gems ต่อ Aura และทำในเกม (Figma ใช้ +5 Gems เป็นตัวอย่าง)
- ทดสอบ Figma: เปิด Preview > คลิก Aura ที่ปลดล็อกทั้ง 3 ตัวเพื่อดู Item Card ของแต่ละตัว > คลิกพื้นที่ด้านนอกเพื่อปิด > คลิกช่องล็อกและดู Chance โดยไม่มี Item Card เปิดขึ้น
- ทดสอบใน Studio หลังติดตั้ง: เปิด Inventory > Auras > Aura Index > เช็กกริดและ Item Card > สุ่มได้ Aura ใหม่และตรวจยอด Gems > สุ่มตัวเดิมและตรวจว่ารางวัลแรกไม่ถูกแจกซ้ำ

### B8. 13 Inventory + ระบบกระเป๋าแบบช่อง (C2)
- สถานะ:
  - [x] โค้ดเสร็จ: `shared/Inventory.luau`, `Config/Treasures.luau`, server (ขายกอง/เปิดกล่อง/ดรอปกล่อง/ย้ายเซฟเก่า), หน้าจอ `Inventory` + `InventoryController`, ItemSlot component — bake แล้ว
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: กดชิปกระเป๋าบน HUD (หรือปุ่ม B) → หน้าต่าง Inventory ตาม Figma 13; ปลาชนิด+mutation เดียวกันรวมกอง (สูงสุด 10/ช่อง); ช่องเต็ม = ปลาถูกปล่อย; กล่องสมบัติเปิดได้รางวัล
- ทดสอบ:
  - [x] 1. Ctrl+S → Play ด้วยเซฟเดิมที่มีปลาในกระเป๋า → ปลาเก่ายังอยู่ (รวมเป็นกอง) ตัวเลข HUD กระเป๋าเป็น `ช่องที่ใช้ / ช่องทั้งหมด`
  - [x] 2. กดชิปกระเป๋า หรือกด **B** → หน้าต่าง Inventory ขึ้น; แท็บ All / Fish / Bait / Treasure กรองถูก; ช่องว่างเป็น "+"
  - [x] 3. ตกปลาชนิดเดิมหลายตัว → รวมเป็น xN ในช่องเดียว; ครบ 10 ขึ้นช่องใหม่; ตัวใหม่มีป้าย NEW จนกว่าจะเปิดหน้าต่าง
  - [x] 4. คลิกช่องปลา → ปุ่มซ้ายล่างเป็น "Sell xN (เหรียญ)" → กด → ได้เงินตามที่แสดง ช่องหาย
  - [x] 5. SELL ALL → ยืนยัน → ขายเฉพาะปลา (กล่องสมบัติยังอยู่)
  - [x] 6. ตกปลาเรื่อย ๆ จนได้กล่อง (โอกาส 3%) → แจ้ง "Bonus: Treasure Chest!" → แท็บ Treasure → คลิก → Open → ได้รางวัล (เหรียญ/เพชร/Shrimp x3)
  - [x] 7. ใช้ช่องจนเต็ม (Starter Pouch 6 ช่อง) แล้วตกชนิดใหม่ → แจ้ง "Bag full - the fish was released"; ทุกกองเต็มด้วย → กด CAST แล้วขึ้น "Your bag is full!"
  - [x] 8. แท็บ Bait → คลิกเหยื่อ → Use → กลายเป็น Equipped (ปุ่มเทาหม่น)
  - [x] 9. Shop → แท็บ Bags → คำอธิบายเป็น "N slots"

### B10. ย้ายทุกหน้าจอลง Explorer + Components (prefab)
- สถานะ:
  - [x] โค้ดเสร็จ + bake แล้ว: HUD, CastPopup, Minigame, AuraReel, Components (+ Modal/Menus/MainMenu เดิม) — ไม่มี UI ไหนสร้าง ScreenGui ด้วยสคริปต์แล้ว
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: StarterGui มี `HUD, CastPopup, Minigame, AuraReel, Components, Modal, Menus, MainMenu`; สคริปต์แค่หา node ตามชื่อแล้วใส่ข้อมูล; ของที่เกิดซ้ำ (แจ้งเตือน, การ์ดปลา, badge, แถบโซนความลึก, ช่องวงล้อออร่า) clone จาก `StarterGui.Components` หรือ `Templates` ในหน้าจอนั้น
- ทดสอบ:
  - [x] 1. Ctrl+S → Explorer → StarterGui เห็นครบ 8 ScreenGui; แผง **Aura UI** มีรายการ 01 HUD, 03 Reel Minigame, 15 Cast Popup, Aura Gacha - Reel Slot, Components (prefabs) → คลิกแล้วเห็นหน้าจอพร้อมข้อมูลตัวอย่าง
  - [x] 2. Play → HUD ขึ้นปกติ ตัวเลข Lv/XP/เหรียญ/เพชร/กระเป๋าตรงข้อมูลจริง; เมนูซ้ายเปิด Shop/Auras/Fishdex/Menu ได้
  - [x] 3. กด DEPTH → Cast popup ขึ้น: ลาก slider, กด preset, ติ๊ก Auto, กด CAST! → ตกปลาได้; เปิดซ้ำอีกครั้งยังปกติ (แถบโซนสีไม่ซ้อนเพิ่ม)
  - [x] 4. ตกปลา → มินิเกม Pond Card ขึ้น เล่นจนจบ → ปิดเอง; ตกตัวที่ 2 ต่อ → มินิเกมเริ่มใหม่สะอาด (แถบ/มิเตอร์รีเซ็ต)
  - [x] 5. ได้ปลา → การ์ดปลา (แบบ Figma 04, ดู B11) ขึ้นแล้วหายไป; แจ้งเตือนกลางบนขึ้น/จางหาย
  - [x] 6. Auras → ROLL → วงล้อหมุน, เด้งการ์ดผล, EQUIP/ROLL AGAIN/CLOSE ใช้ได้; ROLL ซ้ำ 2–3 ครั้งติดกัน → ไม่มีของค้าง
  - [x] 7. ลองแก้ prefab: StarterGui.Components → Sheet → NotifyPill → Sample เปลี่ยนสีพื้น → ตั้ง attribute `Locked = true` ที่ Components → Play → แจ้งเตือนทุกอันเป็นสีใหม่

### B0. ปุ่มแบบ Figma + ไฮไลต์ราคา + การ์ด Equipped (feedback หลังทดสอบ B1/B2)
- สถานะ:
  - [x] โค้ดเสร็จ + bake Modal/Menus/MainMenu ใหม่แล้ว
  - [x] Figma: การ์ด Equipped ใน 07 เป็นพื้นมิ้นต์ + ขอบมิ้นต์ + ป้าย EQUIPPED เขียว
  - [x] Figma: ไฮไลต์ "2,340 coins" ใน 14 Modal (Nunito ExtraBold + cozy/gold-lip; plugin patch_nodes รองรับ ranges แล้ว)
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: ปุ่มทุกอันเป็น 2 ชั้นแบบ Figma (หน้าปุ่ม + ขอบล่างเข้ม 5px โค้งตามมุม ไม่ใช่แถบตัดตรงแบบเดิม), ชี้แล้วสว่างขึ้น กดแล้วหน้าปุ่มยุบลง; ข้อความยืนยันขายแสดงจำนวนเหรียญสีทองตัวหนา; การ์ดออร่าที่ใส่อยู่ (ปักไว้ทุกหน้า) เป็นสีมิ้นต์ต่างจากแถวรายการ
- ทดสอบ:
  - [x] 1. Ctrl+S → Play → ดูปุ่ม CAST / SELL ALL / Shop / Auras / Menu: ขอบล่างโค้งตามมุมเหมือน Figma
  - [x] 2. ชี้ปุ่ม → สว่างขึ้นเล็กน้อย; กดค้าง → ปุ่มแบนราบ (ขอบล่างหาย ไม่มีขอบโผล่ด้านบน) ปล่อยแล้วกลับมามีขอบ; ปุ่มยังทำงานเหมือนเดิม
  - [x] 2a. Shop: ปุ่มราคาแสดงไอคอนเหรียญ + ตัวเลข (ไม่ว่างเปล่า); ซื้อไม่ได้/ติดเลเวล = ปุ่มสีเทาทึบหม่น (`T.Disabled` #D8D1C4) ตัวเลขเทาเข้ม เหรียญจาง แยกจากสีแถวรายการชัด; ปุ่ม DEPTH ข้าง CAST มีคำ DEPTH + AUTO
  - [x] 2b. HUD ตรง Figma 01: ชิปเงินมีรูปเหรียญ/เพชร สูง 40, CAST 115×57 + DEPTH 80×57, ขวาล่าง = ชิปกระเป๋า (รูปกระเป๋า + `n / cap`) + AUTO/SELL ALL 200×57
  - [x] 3. ปุ่มที่เปลี่ยนสี/ข้อความ (Shop: Buy→Equip→Equipped, Auras: Equip/Unequip, AUTO: OFF/ON) → สีและข้อความเปลี่ยนถูก ไม่มีข้อความซ้อน
  - [x] 4. SELL ALL → "You'll get **X coins**" ตัวเลขเป็นสีทองตัวหนา
  - [x] 5. Auras → การ์ดบนสุด (Equipped) สีมิ้นต์ + ป้าย EQUIPPED เขียว; กด > เปลี่ยนหน้า → การ์ดนี้ยังอยู่ (ตั้งใจ: คือออร่าที่ใส่อยู่) แต่ดูต่างจากแถวรายการชัดเจน
  - [x] 6. Cast popup และผลสุ่มออร่า (EQUIP / ROLL AGAIN / CLOSE) ปุ่มแสดงถูกต้อง
  - [x] 7. เมนูซ้ายตรง Figma 01: ช่องครีม 64×64 + ไอคอน 50 และชื่อตัวขาวขอบเข้มใต้ช่อง (แก้ล่าสุดโดย session UI-conversion); ช่อง Menu พื้นฟ้าอ่อน; ชี้แล้วขยายเล็กน้อย กดแล้วหดลง; กดเปิดหน้าต่างได้เหมือนเดิม (M ยังเปิด Menu)
  - [x] 8. เดินออกห่างน้ำ (กลางเกาะ) → CAST + DEPTH + AUTO หายไป; เดินกลับมาริมน้ำ → กลับมาภายใน ~0.3 วิ (ไม่ต้องหันหน้าหาน้ำก่อน)
  - [x] 9. ระหว่างรอปลากิน/มินิเกม หรือเปิด AUTO อยู่ → ปุ่มไม่หายแม้เดินออก (ให้กด REEL IN / ปิด AUTO ได้); บนบกกด Space → ไม่เกิดอะไร

### B1. 14 Modal (ยืนยัน Sell All)
- สถานะ:
  - [x] โค้ดเสร็จ + bake ลง StarterGui แล้ว (ตรวจขนาด/ชื่อ node อัตโนมัติผ่าน)
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: กด SELL ALL แล้วมีหน้าต่างยืนยัน (ไอคอนถุง, "Sell all N fish?", จำนวนเหรียญที่จะได้, Cancel/Sell) ตาม Figma 14; Sell = ขายจริง, Cancel/คลิกพื้นหลัง = ไม่ขาย
- ทดสอบ:
  - [x] 1. Explorer → `StarterGui.Modal` ต้องมีอยู่ (Enabled ปิดไว้ = ปกติ) → ติ๊ก Enabled ดูหน้าตาเทียบ Figma 14 ได้ แล้วปิดกลับก่อน Save
  - [x] 2. Play → ตกปลา 2–3 ตัว → กด **SELL ALL** → หน้าต่างยืนยันขึ้นกลางจอ พื้นหลังมืดลง
  - [x] 3. ตัวเลขใน "You'll get X coins" ต้องเท่ากับเงินที่เพิ่มจริงหลังขาย
  - [x] 4. กด **Cancel** → หน้าต่างปิด ปลายังอยู่ในกระเป๋า; เปิดอีกครั้งแล้วคลิกพื้นที่มืด → ปิดเหมือนกัน
  - [x] 5. กด **Sell** → ขึ้น "Sold N fish for X coins!" และ `Bag 0/…`
  - [x] 6. กระเป๋าว่างแล้วกด SELL ALL → ขึ้น "Your bag is empty" (ไม่มีหน้าต่าง)
  - [ ] 7. Test → Device → มือถือ → Play → หน้าต่างต้องอยู่ในจอทั้งหมด ปุ่มกดได้ไม่โดนปุ่ม Jump บัง

### B2. 07 Auras — Aura Card (Row) + การ์ด Equipped + pager
- สถานะ:
  - [x] โค้ดเสร็จ + bake ลง StarterGui แล้ว (ตรวจขนาด/ชื่อ node อัตโนมัติผ่าน)
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: บนสุดปุ่ม ROLL AURA + Low FX; การ์ดออร่าที่ใส่อยู่ (EQUIPPED); รายการหน้าละ 3 แถว แต่ละแถว = รูป orb, ชื่อสี rarity, แท็ก RARITY + 1/N, badge stats/mutation, จำนวน xN, ปุ่ม Equip/Unequip อยู่ในแถว; ที่ยังไม่มี = ??? ไม่มีปุ่ม; ล่างซ้าย `< 1 / N >`, ล่างขวา Gems
- ทดสอบ:
  - [x] 1. Play → กด **Auras** → เทียบกับ Figma 07
  - [x] 2. ยังไม่ได้ใส่ออร่า → การ์ดบนสุดขึ้น "No aura equipped - roll one!"
  - [x] 3. ROLL AURA 1–2 ครั้ง → ปิดการ์ดผล → ออร่าที่ได้แสดงชื่อจริง + `x1`, ที่ยังไม่ได้เป็น `???` + `-`
  - [x] 4. กด **Equip** ในแถว → การ์ดบนสุดเปลี่ยนเป็นออร่านั้น + ปุ่มในแถวเป็น **Unequip** (สีเขียว) → กด Unequip → การ์ดบนกลับเป็น "No aura equipped"
  - [x] 5. กด **>** / **<** → เปลี่ยนหน้า เลขหน้าเปลี่ยน; หน้าสุดท้ายแถวที่ไม่มีข้อมูลต้องซ่อน
  - [x] 6. ตัวเลข Gems มุมขวาล่างต้องลดหลัง roll; Low FX กดแล้วข้อความสลับ ON/OFF
  - [ ] 7. Test → Device → มือถือแนวนอน (เช่น iPhone 14) → Play → หน้าต่างย่อทั้งก้อนให้พอดีจอ ไม่ล้น ไม่ทับ Top bar และกดปุ่ม < > / ปุ่มในแถวได้

### B3. 05/06 Shop — รูปไอเท็ม + pager
- สถานะ:
  - [x] โค้ดเสร็จ + bake ลง StarterGui แล้ว (ตรวจขนาด/ชื่อ node อัตโนมัติผ่าน)
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: แท็บหมวด (สีส้ม = แท็บที่เลือก), หน้าละ 4 แถว (รูป, ชื่อ, รายละเอียด/ราคา, ปุ่ม Equipped/Equip/Buy/Lv.N), เหยื่อมีปุ่ม Use + Buy xN, ล่างซ้าย pager, ล่างขวา Coins + Gems
- ทดสอบ:
  - [x] 1. Play → **Shop** → แท็บ Rods: Driftwood Rod = **Equipped** (เขียว), คันที่เลเวลไม่ถึง = ชื่อสีเทา + ปุ่ม `Lv. N`, ที่ซื้อได้ = **Buy** สีทอง (เงินไม่พอ = สีครีม)
  - [x] 2. Rods มีมากกว่า 4 รายการ → กด **>** → เห็นรายการที่ 5 → **<** กลับ
  - [x] 3. เปลี่ยนแท็บ → เลขหน้ากลับเป็น 1 เสมอ
  - [x] 4. ซื้อคันใหม่ → ปุ่มเปลี่ยนเป็น Equip (ฟ้า) → กด → เป็น Equipped; ตัวเลข Coins มุมขวาล่างลดทันที
  - [x] 5. แท็บ Baits → กด **Buy x10** → ชื่อเป็น `Worm  x10` → ปุ่ม **Use** โผล่ → กด Use → ชื่อเป็นสีเขียว + "(equipped)" และ Use หายไป
  - [ ] 6. Test → Device → มือถือแนวนอน (เช่น iPhone 14) → Play → หน้าต่างย่อทั้งก้อนให้พอดีจอ ไม่ล้น ไม่ทับ Top bar และกดปุ่ม < > / ปุ่มในแถวได้

### B4. 09 Fishdex — การ์ด 3×2 + pager
- สถานะ:
  - [x] โค้ดเสร็จ + bake ลง StarterGui แล้ว (ตรวจขนาด/ชื่อ node อัตโนมัติผ่าน)
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: "Discovered N / 20" + แถบเขียว, การ์ด 6 ใบต่อหน้า (228×184: รูป, ชื่อ, แท็ก RARITY + ช่วงความลึก, Caught xN + Best x.xx kg), ปลาที่ยังไม่เจอ = ??? + "Not caught yet", pager กลางล่าง
- ทดสอบ:
  - [x] 1. Play → **Fishdex** → เทียบกับ Figma 09 (3 คอลัมน์ 2 แถว)
  - [x] 2. ตกปลาชนิดใหม่ 1 ตัว → เปิด Fishdex → Discovered +1, แถบเขียวยาวขึ้น, การ์ดปลานั้นมีชื่อ + Caught x1 + Best น้ำหนัก
  - [x] 3. กด **>** จนหน้าสุดท้าย (20 ตัว = 4 หน้า) → หน้าสุดท้ายการ์ดที่เกินต้องซ่อน
  - [ ] 4. Test → Device → มือถือ → การ์ดต้องไม่ล้นหน้าต่าง
### B5. 12 Main Menu (hub แบบโทรศัพท์)
- สถานะ:
  - [x] โค้ดเสร็จ + bake ลง StarterGui.MainMenu แล้ว
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: ปุ่ม **Menu** (ฟ้า) ใต้ Fishdex ทางซ้าย หรือกด **M** → เปิด hub แบบโทรศัพท์ตาม Figma 12 (กรอบแก้ว, หัวฟ้ามีรูปโปรไฟล์ผู้เล่น/นาฬิกา/ช่วงเวลา/อากาศ, ไอคอน 3×3); Shop/Auras/Fishdex เปิดหน้าต่างนั้น; ปุ่มอื่นขึ้น "coming soon"; แท็บ X ด้านขวาปิด
- ทดสอบ:
  - [x] 1. ดูหน้าตาโดยไม่ Play: แผง **Aura UI** → คลิก "12 Main Menu" (หรือ `node tools/ui/preview.mjs mainmenu`) → เทียบ Figma 12 → กด "ซ่อนทั้งหมด"
  - [x] 2. Play → กดปุ่ม **Menu** → hub ขึ้นด้านขวาของกลางจอ ไม่ทับ Stats ซ้ายบนและ Leaderboard
  - [x] 3. นาฬิกาต้องตรงกับเวลาในเกม (Lighting.ClockTime ตอนนี้ 16:30 → "16:30") และไอคอน **Day** อยู่ในวงขาว
  - [x] 4. Gems ≥ 5 → ไอคอน Auras มีจุดแดง; Gems < 5 → ไม่มีจุด
  - [x] 5. กด Shop / Auras / Fishdex → hub ปิดแล้วหน้าต่างนั้นเปิด; กด Bag/Quests/Rebirth/Events/Friends/Settings → ขึ้น "X: coming soon!"
  - [x] 6. กด **M** เปิด/ปิดได้; กดแท็บ X ด้านขวาของโทรศัพท์ → ปิด
  - [ ] 7. Test → Device → มือถือ → Play → hub ย่อทั้งก้อน ไม่ล้นจอ
  - [x] 8. รูปโปรไฟล์ = รูปหน้า avatar ของคุณ (ถ้าโหลดไม่ได้จะเป็นวงครีม/รูป Pip)
- [ ] **B6.** **Gacha G1 Altar** (rates, pity, x1/x10, skip, auto-roll) + ระบบ pity/x10 ฝั่ง server
- [ ] **B7.** **11 Dialogue** (NPC)
- [ ] **B8.** **13 Inventory** — ต้องตกลง data model ของไอเท็มก่อน (เหยื่อ/สมบัติ/ปลา)
- [ ] **B9.** **G6 x10 Summary**

---


### B11. 04 Catch Result (การ์ดปลาที่ตกได้ตาม Figma)
- สถานะ:
  - [x] โค้ดเสร็จ + bake ลง StarterGui.Components (prefab "CatchCard") แล้ว — เทียบภาพกับ Figma แล้ว (`docs/figma/compare_catch.png`)
  - [x] คุณกด Save
  - [x] ทดสอบผ่าน (desktop)
- Done when: ตกปลาได้แล้วการ์ดขึ้นกลางจอตาม Figma 04: แท็ก RARITY (สี rarity) + NEW! (ปลาใหม่) + ไอคอน mutation, รูปปลาใหญ่, ชื่อปลาสี rarity (มี mutation นำหน้าชื่อ), badge น้ำหนัก / Manual|Auto / PERFECT, เส้นคั่น, ชิป 🪙 +เงิน และ 💎 +เพชร (ถ้าได้), แถว badge ตัวคูณ (mutation xN / Manual x1.5 / Perfect +0.25), มีเงา
- ทดสอบ:
  - [x] 1. ดูหน้าตาโดยไม่ Play: แผง **Aura UI** → "Components (prefabs)" → การ์ด CatchCard เทียบ Figma 04
  - [x] 2. Play → ตกปลาแบบมือ (Manual) → การ์ดขึ้น ~2.6 วินาที: รูปปลาตรงชนิด, ชื่อสีตาม rarity, แถวล่างมี "Manual x1.5"
  - [x] 3. ตกชนิดที่ไม่เคยได้ → มีป้าย **NEW!**; ชนิดที่เคยได้แล้ว → ไม่มี
  - [x] 4. ตกแบบไม่หลุดเลย → มี badge **PERFECT** และ "Perfect +0.25" ในแถวล่าง
  - [x] 5. เปิด AUTO ให้ได้ปลาเอง → badge "Auto", ไม่มี "Manual x1.5"; ถ้าไม่มี mutation/perfect แถวล่างหายและการ์ดเตี้ยลง
  - [x] 6. ได้ปลามี mutation (เช่น Glowing) → ไอคอน mutation ข้าง NEW!, ชื่อ "Glowing …", แถวล่างมี "Glowing x1.8"
  - [x] 7. ตัวเลข 🪙 บนการ์ด = เงินที่ได้ตอนขายปลาตัวนั้น (ดูใน SELL ALL); 💎 ขึ้นเฉพาะตอนได้เพชร
  - [ ] 8. Test → Device → มือถือแนวนอน → Play → ตกปลา → การ์ดย่อให้พอดีจอ ไม่ล้น

## C. ต้องทำ / Backlog
งานค้างทั้งหมด (ติ๊กเมื่อเสร็จ) — รูปแบบ: **รหัส. งาน** — Done when • ใครทำ

- [x] **C1.** **อัปโหลดรูปขึ้น Roblox** — 99/99 อัปโหลดแล้ว (2026-11-16) และแปลงเป็น Image id ใน `UIAssets.luau` แล้ว — *Done when:* เปิดเกมแล้วเห็นรูปจริงแทนกรอบสี + เงาใต้หน้าต่าง • *ใครทำ:* รูปใหม่ภายหลัง: ใส่ใน `assets/` + catalog → `python -I tools/art/upload_assets.py` (อัปเฉพาะที่ยังไม่มี id) → `node tools/ui/resolve_decals.mjs`
- [x] **C2.** ตัดสินใจ data model ของ Inventory — *Done when:* มีรายการประเภทไอเท็ม + กติกา stack/ขาย • *ใครทำ:* คุณ + Claude
  - กระเป๋า = **ช่อง** (Bags.Capacity: Starter 6 / Woven 10 / Crate 15 / Coolbox 20 / Hold 30); 1 ช่อง = 1 กอง
  - ปลา: ชนิด + mutation เดียวกันรวมกอง สูงสุด 10/ช่อง; กองเก็บ "มูลค่ารวม" (น้ำหนักรายตัวคิดเงินไว้แล้ว) + ตัวหนักสุด → ขายได้เงินเท่าเดิม
  - กล่องสมบัติ (Treasure): ดรอปโบนัสตอนตกปลา 3% (+Luck), กินช่อง, กองละ 5, กด Open สุ่มรางวัล (เหรียญ/เพชร/เหยื่อ) — ตั้งค่าใน `Config/Treasures.luau`
  - เหยื่อ: ไม่กินช่อง (อยู่ Consumables เหมือนเดิม) แสดงในแท็บ Bait
  - ไม่มีระบบล็อก; SELL ALL ขายเฉพาะปลา กล่องยังอยู่
  - ตัวเลขทั้งหมดแก้ได้ใน `GameConfig.Inventory` + `Equipment.Bags`; เซฟเก่าแปลงอัตโนมัติ (schema 2)
- [ ] **C3.** Rebirth + ฉายา (GDD 7.2) — *Done when:* Rebirth แล้ว reset เลเวล/เงิน, ได้ multiplier +0.25x, ฉายาเหนือหัว • *ใครทำ:* Claude
  - 2026-11-17: ย้ายเลเวลที่ต้องถึงจาก Lv.100 → **Lv.50** (Lv.100 ต้องใช้ ~1.9M XP ≈ 270 ชม.); Rebirth เพิ่มตัวคูณ Pearls ด้วย; Mastery/ดาวออร่า/Fishdex ไม่ถูกล้าง (ดู `docs/BALANCE_PLAN.md`)
  - **สถานะ: โค้ดเสร็จ (2026-11-17)** — `Features.Rebirth` (เปิดแล้ว): ครั้งแรก Lv.50, ครั้งถัดไป +10 เลเวล (50 → 60 → 70 … สูงสุด Lv.100), +0.25 ต่อครั้งให้ **Sell Mult + Pearl Rate** (1 ครั้ง = ×1.25 ตาม GDD), ฉายา: 1 Novice Angler · 2 Tide Walker · 3 Abyssal Conqueror · 5 Naga Whisperer · 10 Fisher of Gods; `Shared/Rebirth.luau`, `Services/RebirthService.luau` (remote `Rebirth`), `Stats.Collect` (stat source), เซฟ `Rebirths`
  - ล้าง: เลเวล, XP, Coins (กลับเป็น 500), **ปลาในกระเป๋า** (กันเก็บปลาไว้ขายหลังรีเซ็ต — หน้าต่างยืนยันบอกไว้แล้ว); เก็บ: อุปกรณ์ + ขั้น Enhance, เหยื่อ, กล่องสมบัติ, ออร่า + ดาว, Fishdex, Mastery, บ่อปลา + Pearls, Gems, pass, เควสต์
  - Client: ปุ่ม Rebirth ใน Main Menu เปิดหน้าต่างยืนยัน (Modal เดิม) แล้วเรียก server; ป้าย `Lv.N` บนปุ่มใช้เลเวลของครั้งถัดไป; `TitleController` ใหม่ วาดฉายาสีทองเหนือหัวทุกคน (จาก attribute `Title` บนตัว Player — ทุก client เห็น); คำสั่ง Dev `rebirths <n>`
  - Claude ทดสอบแล้วใน Studio: Lv.100 → Rebirth → Lv.1, 500 coins, ปลาหาย กล่องอยู่, Sell Mult / Pearl Rate 1.00 → 1.25 ✓, ฉายา "Novice Angler" ขึ้นเหนือหัว ✓ (ภาพจริง), ครั้งต่อไปต้อง Lv.60 ✓, Rebirth ซ้ำที่ Lv.1 ถูกปฏิเสธ ✓, `rebirths 5` → "Naga Whisperer" ✓; หลังทดสอบคืนเซฟเป็น Lv.100 / 252,817 coins / 0 rebirth แล้ว (XP ในเลเวลเริ่มที่ 0)
  - ทดสอบ:
    - [ ] 1. F2 `level 50` → Main Menu → ปุ่ม Rebirth (ป้าย Lv.50 หายไป) → หน้าต่างยืนยันบอกสิ่งที่ล้าง/ได้ → กด Rebirth
    - [ ] 2. หลัง Rebirth: Lv.1, 500 coins, ปลาในกระเป๋าหาย, ของอื่นอยู่ครบ, ข้อความแจ้งทุกคนในเซิร์ฟ
    - [ ] 3. ฉายา "Novice Angler" สีทองเหนือหัว; ขายปลาได้เงิน ×1.25
    - [ ] 4. ปุ่ม Rebirth ขึ้น Lv.60; ออกแล้วเข้าใหม่ → จำนวน Rebirth + ฉายายังอยู่
- [ ] **C4.** สกิล Keen Eye / Quick Hands / Multi-Cast (GDD 7.1) — *Done when:* ใช้ skill point ได้, Multi-Cast เหวี่ยงหลายสาย • *ใครทำ:* Claude
  - **ตกลงกับคุณ (2026-11-17):** สกิล**ถาวร** — ได้ 1 แต้มทุกครั้งที่เลเวลอัป แม้เป็นเลเวลที่เคยผ่านแล้วก่อน Rebirth → Rebirth = ได้แต้มเพิ่มอีกรอบ ไม่มีอะไรหาย; Multi-Cast = สายเสริมแต่ละเส้นมีโอกาส 35% ได้**ปลาโบนัส**ทุกครั้งที่ตกได้ (ไม่ทำให้รายได้พุ่ง 10 เท่า)
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17)** — `Config/Skills.luau`: **Keen Eye** Luck +1%/Lv (สูงสุด 50), **Quick Hands** ปลากินเบ็ดเร็วขึ้น 1%/Lv (สูงสุด 30) — ราคา 1 แต้ม (Lv1–10), 2 แต้ม (Lv11–20) …; **Multi-Cast** +1 สาย/Lv (สูงสุด Lv9 = 10 สาย ตาม GDD) ราคา 5/10/15/20/30/40/50/65/80; `Shared/Skills.luau` (`State(profile)` ให้ UI), `Stats.Collect` (stat source), `ProgressionService` (+แต้มตอนเลเวลอัป, remote `UpgradeSkill`), เซฟ `Skills = { Points, Levels }`, schema 5 (เซฟเก่าได้แต้ม = เลเวล − 1 ครั้งเดียว)
  - Multi-Cast ในการตก: `FishingService.award` — ทุกครั้งที่ตกได้ (มือ/Auto) สายเสริม `ExtraLines` เส้นละ 35% สุ่มปลาที่ความลึกเดียวกัน → เข้ากระเป๋าแบบ Auto (×1, ไม่นับ Streak, Gems ครึ่ง, ไม่ใช้เหยื่อ, ไม่สุ่มหีบ), นับ Fishdex/XP/เควสต์; แสดงในการ์ดหลักผ่าน `CatchResult.Bonus = { {Entry, Value, New, Gems, Kept} }`
  - Extra Cast pass (≤299 R$) ใช้ stat `ExtraLines` เดียวกันได้ทันที — ถ้าจะขายให้สร้าง pass บนเว็บ แล้วบอก Claude ใส่ `Stats = { ExtraLines = 1 }`
  - คำสั่ง Dev: `skillpoints <n>`, `skill <id> <level>`, `skill reset`
  - Claude ทดสอบแล้วใน Studio: เซฟคุณ (Lv.100) ได้ 99 แต้ม ✓; Keen Eye Lv1 → Luck +0.01 ✓; Multi-Cast Lv1 ใช้ 5 แต้ม ✓; Lv.5 + XP 5000 → Lv.11 ได้ +6 แต้ม ✓; Multi-Cast Lv9 ตกมือ 4 ครั้ง → ปลาโบนัส 18 ตัว (ค่าคาดหวัง ≈ 13) เข้ากระเป๋าครบ 22 ตัว ✓; Output ไม่มี error; หลังทดสอบคืนเป็น 99 แต้ม สกิล 0 Lv.100
  - ทดสอบ:
    - [ ] 1. F2 `skillpoints 0` (ดูแต้ม) → (หน้าต่าง UI / remote) อัป Keen Eye → Luck +1%
    - [ ] 2. ตกปลาจนเลเวลอัป → แต้มเพิ่ม 1
    - [ ] 3. F2 `skill MultiCast 3` → ตกปลา → บางครั้งได้ปลาเพิ่มในกระเป๋ามากกว่า 1 ตัว (การ์ดจะแสดงปลาโบนัสเมื่อ UI รองรับ)
    - [ ] 4. Rebirth → สกิลที่อัปไว้ยังอยู่ครบ; เลเวลอัปใหม่ได้แต้มเพิ่ม
- [ ] **C5.** บอส พญานาค + Co-op Reel (GDD 6) — *Done when:* อีเวนต์ทุก 30 นาที, หลายคนช่วยกันดึง, แบ่งรางวัล • *ใครทำ:* Claude / Antigravity
  - **เปลี่ยนแบบตามที่คุณขอ (2026-11-17):** ยกเลิกบอสดึงเย่อ (PULL) → เป็น **Naga Tide**: ทุก :00 / :30 (UTC) มีวงน้ำเรืองแสงเกิดที่จุดสุ่มในทะเล 5 นาที; ตกปลาให้ทุ่นลงในวง (ตกมือหรือ Auto) = Luck +50% + ลุ้นปลาพิเศษ; ยิ่งมีคนตกในวงเดียวกันมาก โอกาสยิ่งสูง (+25% ต่อคน สูงสุด ×2) → คนในเซิร์ฟแห่มาจุดเดียวกัน
  - **สถานะ: โค้ดเสร็จ + HUD Cozy Lake แล้ว (2026-11-19)** — `Config/TideEvents.luau` (วงรัศมี 40, ห่างลานกลาง 45–220 studs, ปลาพิเศษ: **Naga Hatchling 0.4%** และ **Coral Seahorse 1.5%** ต่อการตก × โบนัสคน), `Services/TideEventService.luau` (ตารางเวลา, เตือนก่อน 60 วิ, หาน้ำเปิดที่ไม่อยู่ใต้สะพาน, วงเรืองแสง + ลำแสงสูง 60 studs ให้เห็นจากไกล, ประกาศทุกคนเมื่อมีคนได้ปลาพิเศษ), `FishingService` (ทอยปลา: Luck เพิ่ม + สลับเป็นปลาพิเศษเมื่อทุ่นอยู่ในวง), `Controllers/TideEventController.luau` (อัปเกรดเป็น Cozy Lake Floating HUD 480x76: ไอคอน Naga, ชิปเวลานับถอยหลัง M:SS, ป้ายทิศทาง+ระยะ studs, ป้ายจำนวนคน, แถบเรืองแสงสีเขียวมินต์ "IN TIDE: +50% LUCK", ช่อง LOOT พรีวิว Naga Hatchling และ Coral Seahorse); การ์ด Events เปลี่ยนเป็น Naga Tide; ลบระบบบอสเก่า (BossService, BossController, Config/Boss, remotes Boss*)
  - คำสั่ง Dev: `event start`, `event stop`
  - ทดสอบ:
    - [ ] 1. F2 `event start` → HUD ลอยด้านบนขึ้นมาตามดีไซน์ Cozy Lake, มีไอคอน Naga, ชิปเวลานับถอยหลัง, ช่อง LOOT พรีวิวปลาพิเศษ, และป้ายบอกระยะทาง+ทิศทาง
    - [ ] 2. ว่ายไป/หันทุ่นเข้าวง → แถบเปลี่ยนเป็นสีเขียวมินต์ "IN TIDE: +50% LUCK", ขอบการ์ดเปลี่ยนเป็นสีเขียวมินต์ → ตกปลาได้บัฟ Luck เพิ่ม
    - [ ] 3. 2 ผู้เล่นตกในวงเดียวกัน → ป้ายแสดงจำนวนคนตกเพิ่มขึ้น
    - [ ] 4. F2 `event stop` หรือรอหมดเวลา 5 นาที → แผง HUD หายไปอย่างเรียบร้อย
- [ ] **C6.** Gamepasses (VIP, Auto-Fish Pro, Infinite Bag, Extra Cast) — *Done when:* ซื้อแล้วได้ผลผ่าน stat sources • *ใครทำ:* Claude + คุณสร้าง pass ในเว็บ Roblox
  - 2026-11-17 (จาก `docs/aura_fishing_economy_monetization_model.md`): **Infinite Bag ~~499~~ 349 R$** · **Auto-Fish Pro ~~399~~ 249 R$** = Auto Wait −25% + ตัวคูณ Auto 1.25 (ตาม GDD — ยังต่ำกว่าเล่นมือ 1.5 ไม่ใช่ "เท่าเล่นมือ 100%") · **VIP ~~199~~ 149 R$** = Luck +15%, เพดานออฟไลน์บ่อปลา 12 ชม., ชื่อสีทอง · Extra Cast รอ C4 Multi-Cast (เป้า ≤ 299 R$)
  - ต้องมี C13 ก่อน • UI (session อื่น): ป้ายชื่อ VIP, ปุ่มซื้อ pass ในร้าน
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17)** — VIP: Luck +15% + เพดานออฟไลน์ +8 ชม. (stat source ตั้งแต่ C13/C14); Auto-Fish Pro: Auto Wait −25% + Auto ×1.25; **Infinite Bag**: `Inventory.Capacity` = `GameConfig.Inventory.InfiniteBagSlots` (999) + `Inventory.IsInfinite(profile)` ให้ UI แสดง "∞"; ทุก pass ตั้ง attribute `Pass_<id>` บนตัว Player ให้ client ทุกคนเห็น (ใช้ทำป้ายชื่อ VIP สีทอง); Extra Cast รอ C4 Multi-Cast
  - Claude ทดสอบแล้วใน Studio: เจ้าของเกมได้ attribute `Pass_VIP/AutoFishPro/InfiniteBag = true`, ความจุกระเป๋า 999 ✓
  - ทดสอบ:
    - [ ] 1. Play → Inventory ขึ้นความจุ 999 (UI จะเปลี่ยนเป็น ∞ ภายหลัง) และตกปลาได้ไม่เต็ม
    - [ ] 2. F2 `revoke pass InfiniteBag` → ความจุกลับเป็นตามกระเป๋าที่ใส่ (เข้าเกมใหม่จะได้คืนเพราะคุณเป็นเจ้าของเกม)
- [x] **C7.** เควสต์รายวัน — *Done when:* มีเควสต์ 3 ข้อ/วัน ให้ Gems • *ใครทำ:* Claude
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17)** — ไฟล์: `Config/Quests.luau` (คลัง 10 เควสต์: จับปลา 25/60, ตกมือ 15, Rare+ 3, Epic+ 1, mutation 2, Hot Streak x5/x10, ขาย 30, สุ่มออร่า 3 — บางข้อต้องถึงเลเวล), `Shared/Quests.luau` (`State(profile)`, `ResetsIn()`), `Services/QuestService.luau`, remote `ClaimQuest(index)` → `ok, message, State`; ใช้ตัวเลขเดิมใน `Features.Quests` (3 ข้อ/วัน, ข้อละ 5 Gems = 15/วัน ตามโมเดล, รีเซ็ต 00:00 UTC = 07:00 เวลาไทย)
  - นับความคืบหน้าจาก signal: `FishingService.FishCaught` (เพิ่ม arg `streak`), `ShopService.FishSold` (ใหม่), `AuraService.Pulled` (ใหม่) → ระบบอื่นในอนาคต (อีเวนต์/บอส) ใช้ signal เดียวกันได้
  - เซฟ `Quests = { Day, List = { {Id, Progress, Claimed} }, Unclaimed }` — `Unclaimed` คือ field ที่จุดแดงบน Main Menu รออ่านอยู่แล้ว
  - `Features.Quests.Enabled` ยังเป็น `false` (ปุ่ม Quests ใน Main Menu ยังขึ้น "coming soon") → session UI เปิดเป็น `true` ตอนทำหน้าต่างเควสต์ + ใส่ action ใน `MainMenuController.ACTIONS`
  - คำสั่ง Dev: `quests list`, `quests reroll`, `quests done`
  - Claude ทดสอบแล้วใน Studio: เข้าเกม → ได้ 3 ข้อของวันนี้; รับรางวัลข้อที่ยังไม่เสร็จ → ปฏิเสธ ✓; สุ่มออร่า 3 ครั้ง → Pull3 3/3 ✓; ขายปลา 30 ตัว → Sell30 30/30 ✓; รับ 2 ข้อ → Gems +10 ✓, รับซ้ำ → "Already claimed" ✓, `Unclaimed` กลับเป็น false ✓; ตกมือ 2 ตัว → Streak5 2/5 ✓; Output ไม่มี error (ระหว่างทดสอบใช้ `clearbag` — กระเป๋าในเซฟ Studio ถูกล้าง)
  - ทดสอบ:
    - [ ] 1. F2 `quests list` → มี 3 ข้อ ไม่ซ้ำกัน
    - [ ] 2. ทำตามข้อใดข้อหนึ่ง (เช่น ตกปลา / ขาย / สุ่มออร่า) → `quests list` ตัวเลขขึ้น + มีข้อความ "Quest done" เมื่อครบ
    - [ ] 3. (หน้าต่าง UI) กดรับรางวัล → Gems +5; กดซ้ำไม่ได้; จุดแดงบนปุ่ม Quests หายเมื่อรับครบ
    - [ ] 4. หลัง 07:00 (เวลาไทย) วันถัดไป เข้าเกม → ได้ 3 ข้อใหม่ ความคืบหน้าเริ่ม 0
- [ ] **C8.** เสียง (SFX) ตามจุดที่ระบุใน storyboard gacha/มินิเกม — *Done when:* มีเสียง cast, bite, reel tick, ka-ching, fanfare • *ใครทำ:* คุณหา/อัปโหลดเสียง + Claude ต่อโค้ด
- [ ] **C9.** แมพจริง + โมเดลปลา/คันเบ็ด — *Done when:* แมพใน `places/AuraFishing.rbxlx` มี FishingZone ครบ • *ใครทำ:* คุณ (+ Claude ช่วยผ่าน StudioBridge)
- [ ] **C10.** เครดิต Font Awesome (FaLock, CC BY 4.0) — *Done when:* มีหน้า Credits/ข้อความเครดิตในเกม • *ใครทำ:* Claude
  - **สถานะ: โค้ดเสร็จ (2026-11-17)** — `Config/Credits.luau` (รายการเครดิต; เพิ่มแถวเมื่อใช้ของที่ต้องให้เครดิต), `UI/Credits.luau` (หน้าต่าง "Settings & Credits" สร้างด้วย New), ปุ่ม **Settings** ใน Main Menu เปิดหน้าต่างนี้ (`Features.Settings.Enabled = true` จนกว่าจะมีหน้า Settings จริง — บอกในหน้าต่างว่า Low FX อยู่ในหน้า Auras), ไฟล์ `CREDITS.md` ที่ root ของ repo
  - type check ผ่าน; **ยังไม่ได้ทดสอบในเกม** — Roblox Studio หลุดการเชื่อมต่อระหว่างทดสอบ
  - ทดสอบ:
    - [ ] 1. Play → เปิด Main Menu (ปุ่ม Menu / M) → กด Settings → หน้าต่าง "Settings & Credits" มีแถว Font Awesome Free (Lock icon) • Fonticons, Inc. • CC BY 4.0
    - [ ] 2. กด Close → ปิด; กด Settings อีกครั้ง → เปิดได้; หน้าต่างอยู่ในจอทั้งหมด- [ ] **C11.** ทดสอบมือถือจริง + ปรับขนาดปุ่ม — *Done when:* เล่นบนมือถือจริงได้ครบ A1–A9 • *ใครทำ:* คุณ

- [ ] **C20.** มินิเกม: Catch Bar เริ่มตรงปลา — *Done when:* เปิดมินิเกมทุกครั้ง แถบจับ (สีเขียว) ทับปลาอยู่แล้ว ไม่ต้องรีบคลิกไล่ • *ใครทำ:* Claude
  - ปัญหาเดิม (คุณเจอ 8/10 ครั้ง): แถบเริ่มที่ก้นสุด แต่ปลาเริ่มกลางหลอด และแถบตกลงทันที → หลุดตั้งแต่วินาทีแรก
  - แก้: ปลาเกิดสุ่มช่วง 30–70% ของหลอด, แถบเกิด**กึ่งกลางที่ปลา**; **0.6 วินาทีแรก** ปลานิ่งและแถบไม่ตก (ขยับเฉพาะเมื่อกดค้าง) — ปรับได้ที่ `GameConfig.Minigame.StartGrace` / `StartFishRange`
  - ไฟล์: `src/client/Controllers/FishingController.luau`, `src/shared/Config/GameConfig.luau` • type-check ผ่าน • **ยังไม่ได้ทดสอบใน Play** (Studio ที่เปิดอยู่ยังไม่ได้ต่อ Rojo)
  - ทดสอบ:
    - [ ] 1. serve.bat + Rojo Connect → Play → ตกปลาแบบมือ 10 ครั้ง → ทุกครั้งที่มินิเกมเปิด แถบเขียวทับปลา และชิปขึ้น **GOOD** ทันที
    - [ ] 2. ไม่กดอะไรหลังเปิดมินิเกม → ประมาณครึ่งวินาทีแรกแถบกับปลานิ่ง แล้วค่อยเริ่มขยับ/แถบเริ่มตก
    - [ ] 3. ปลาไม่ได้เกิดตำแหน่งเดิมทุกครั้ง (สุ่มกลาง ๆ หลอด)
    - [ ] 4. ถ้ายังเร็วไป: บอก Claude ให้เพิ่ม `StartGrace` (เช่น 1.0 วินาที)

### Economy & Monetization (C12–C19, เพิ่ม 2026-11-17)
ที่มา: `docs/BALANCE_PLAN.md` (แผน + เหตุผล), `docs/aura_fishing_economy_monetization_model.md` (แผนขายของจาก agent วิเคราะห์), หน้าโมเดลคำนวณ `docs/economy/economy-model.html`
**ลำดับที่ตกลง:** C12 → C13 → C14 + C15 → C16 → C17 → C7 → C6 + C19 → C18 → C3 / C4 / C5
**ข้อสรุปที่ต่างจากเอกสาร agent:** ใช้รายได้เงินแบบ "แจกหนัก" ของแผนเรา (ซื้อของได้ทุก 1–3 นาทีช่วงแรก) ไม่ใช่ 3–5k/ชม.; กาชาตั้งเป้า ~10–15 ครั้ง/ชม.; Auto-Fish Pro ไม่ทำให้ Auto เท่าเล่นมือ; Starter Pack ไม่ให้ของที่ข้ามบันไดการซื้อช่วงแรก
**ช่องทาง UI:** ฝั่ง server/data ทำโดย session ระบบเกม (session นี้); หน้าจอใหม่ทุกอันจดไว้ในแต่ละงานให้ session UI/Figma ทำ — สเปก UI รวม: `docs/HANDOFF_ECONOMY_UI.md` (ส่งให้ session UI/Figma แล้ว 2026-11-17)
**รูปที่ต้อง gen:** `docs/ART_PROMPTS.md` sheet 10–16 (P1 = 10, 11, 12 ใช้ก่อน; P2 = 13–15; P3 = 16) → gen แล้วรัน `python -I tools/art/slice_grid.py <sheet id> <image.png>`

- [ ] **C12.** Balance Pass 1 — *Done when:* ตัวเลขใน config ตรงตาราง `BALANCE_PLAN.md` ข้อ 2 + 6, หน้าโมเดลกด preset "แผน Pass 1" ได้ผลใกล้เคียงกับที่เล่นจริง • *ใครทำ:* Claude
  - มูลค่าปลา/หีบ ×10 + บันไดราคาใหม่ (Basket 800 … Naga Rod 900k), เริ่มเกม 500 coins
  - Auto 9 → 14 วิ, Auto ได้ Gems/หีบ ×0.5; **Hot Streak** เล่นมือ +5%/ตัวที่จับติดกัน สูงสุด +50% (หลุด/สายขาด = รีเซ็ต)
  - `XPExponent` 1.45 → 1.3 (ลดกำแพงเลเวลอีกตามผลโมเดล); Silk Line ต้อง Lv.12; Naga Hatchling RollWeight 0.2; เพิ่มปลา Common โซนลึก 1 ชนิด (ขอรูป); `LuckTierExponent` 0.75 → 0.6
  - จับปลาชนิดใหม่ครั้งแรก +3 Gems
  - ย้ายเซฟเก่า (schema 3): เงินที่มี ×10
  - UI (session อื่น): ป้าย Hot Streak ข้างปุ่ม CAST — ข้อมูลพร้อมแล้ว: remote `Streak` ส่ง `{ Streak, Bonus, Lost }` + `CatchResult` มี `Streak`, `StreakBonus`, `NewGems`
  - **สถานะ: โค้ดเสร็จ (2026-11-17)** — ไฟล์: `Config/GameConfig` (`StartingCoins` 500, `AutoCycleTime` 14, `AutoGemMultiplier`/`AutoTreasureMultiplier` 0.5, `HotStreak`, `NewSpeciesGems` 3, `XPExponent` 1.3, `LuckTierExponent` 0.6), `Config/Fish` (มูลค่า ×10, ปลาใหม่ **Gloom Sprat** Common 200–400m มูลค่า 600, Naga `RollWeight` 0.2), `Config/Equipment` (ราคาใหม่ + Silk Lv.12), `Config/Treasures` (เหรียญ ×10), `FishingService` (Streak/Auto), `DataService` (schema 3), `Remotes` (`Streak`)
  - Hot Streak: ตัวที่ 1 = +5%, ตัวที่ 10 = +50% (MAX); สายขาด/พลาดจังหวะ "!" = รีเซ็ต; Auto ไม่นับและไม่รีเซ็ต; streak ไม่เซฟ (ออกเกม = เริ่มใหม่)
  - ย้ายเซฟ: Coins, Lifetime.CoinsEarned และมูลค่าปลาในกระเป๋า ×10 ครั้งเดียว (เช็ค `Version` ก่อน reconcile เพื่อไม่ให้ข้าม)
  - รูป Gloom Sprat ตัดแล้วแต่**ยังไม่อัปโหลด** → ในเกมแสดงเป็น Mystery Fish จนกว่าจะรัน `tools/art/upload_assets.py`
  - Claude ทดสอบแล้วใน Studio (ยิง remote จริง): จับมือ 3 ตัวติด → Mult 1.575 / 1.65 / 1.725 (= 1.5 × 1.05/1.10/1.15), สายขาด → `Streak 0 Lost=true`; Output ไม่มี error; type check ผ่าน
  - ทดสอบ:
    - [ ] 1. F2 → `reset` → เริ่มเกมมี 500 coins → เปิด Shop ซื้อ Woven Basket ได้ทันที
    - [ ] 2. ตกปลาตื้นแบบมือ ~2 นาที → เงินพอซื้อ Hemp Line (1,000) และ Bamboo Rod (1,500)
    - [ ] 3. จับปลาชนิดเดียวกันแบบมือติดกัน 3 ตัว → ราคาบนการ์ดปลาสูงขึ้นทีละ ~5% (ป้าย Streak บนจอจะมาพร้อมงาน UI); ปล่อยให้สายขาดแล้วจับใหม่ → ราคากลับมาเริ่ม +5%
    - [ ] 4. เปิด AUTO ริมน้ำ → ได้ปลาประมาณทุก 14 วิ (ไม่ใช่ 9)
    - [ ] 5. Shop → Spider-Silk Line แสดงต้อง Lv.12 (ปุ่มเทา) จนกว่าเลเวลถึง
    - [ ] 6. จับปลาชนิดที่ยังไม่เคยมี → การ์ดแสดง NEW! + 💎3
    - [ ] 7. เซฟเก่า (ก่อนอัปเดต) เข้าเกม → เงินเป็น ×10 ของเดิม ครั้งเดียว (ออกแล้วเข้าใหม่ไม่คูณซ้ำ) — เซฟ Studio ของคุณย้ายไปแล้วตอนที่ Claude กด Play (ตอนนี้มี 248,820 coins)
    - [ ] 8. ซื้อ Spider-Silk Line (Lv.12+) → ตั้งความลึก 250m → จับได้ Gloom Sprat บ่อย ๆ (รูปเป็น Mystery Fish ไปก่อน); Naga Hatchling หายากมาก
- [ ] **C13.** ระบบรับเงิน Robux — *Done when:* ซื้อ Dev Product ใน Studio (test purchase) แล้วได้ของครั้งเดียว ไม่ซ้ำแม้ server ส่ง receipt ซ้ำ; เช็ค Gamepass ตอนเข้าเกม/ตอนซื้อระหว่างเล่น • *ใครทำ:* Claude + คุณสร้าง Product/Pass บนเว็บ Roblox แล้วส่ง ID
  - `Config/Products.luau` (id → รางวัล), `MonetizationService` (ProcessReceipt + เก็บ receipt id ในเซฟ, `UserOwnsGamePassAsync` + `PromptGamePassPurchaseFinished`), ผลของ pass เข้า stat sources (`Stats.Collect`) ให้ client/server เห็นตรงกัน
  - คำสั่ง Dev: `grant pass <id>` / `revoke pass <id>` สำหรับทดสอบโดยไม่ต้องซื้อ
  - **สถานะ: โค้ดเสร็จ (2026-11-17)** — ไฟล์: `Config/Products.luau` (Passes: VIP 149 = Luck +15%, AutoFishPro 249 = Auto Wait −25% + Auto ×1.25, InfiniteBag 349 = ผลจริงทำใน C6; Products: Gems 25/110/300 = 25/99/249 R$), `Services/MonetizationService.luau`, `Stats.Collect` (pass ที่มี = stat source), `DataService` (`Passes`, `Purchases{Receipts, Once, Count}`, `SaveNow`), `Registry` (ตรวจ id ซ้ำ/รางวัลผิด), remotes `PromptPass` / `PromptProduct`
  - กติกาใบเสร็จ: ยังไม่โหลดเซฟ = NotProcessedYet; PurchaseId เคยได้แล้ว = ไม่ให้ซ้ำ; ให้ของ + จด id แล้ว**เซฟทันที** ถ้าเซฟไม่ผ่านจะดึงของคืน (แบบลบออก ไม่ทับเงินที่เพิ่งได้) แล้วให้ Roblox ส่งมาใหม่; เก็บ id ล่าสุด 100 ใบ
  - Pass: เช็คตอนเข้าเกม + ตอนซื้อเสร็จ; `Passes[id] = "Owned"` (Roblox ยืนยัน) หรือ `"Dev"` (คำสั่ง grant — ไม่ถูกลบตอนเช็ค); ถ้า Roblox ตอบว่าไม่มีแล้ว (refund) จะเอา "Owned" ออก; เช็คไม่สำเร็จ = คงค่าเดิม
  - `receipt <product> [purchaseId]` = จำลองใบเสร็จผ่านโค้ดเดียวกับของจริง; Starter Pack / Boost รอ C19; ปุ่มซื้อในเกมรอ session UI (เรียก remote `PromptPass("VIP")` / `PromptProduct("GemsSmall")`)
  - Claude ทดสอบแล้วใน Studio: grant VIP → Luck 2.00 → 2.15, AutoFishPro → AutoSpeed +0.25 / AutoMult +0.25, revoke → กลับเท่าเดิม; `receipt GemsMedium test-123` 2 ครั้ง + `receipt gemssmall` → Gems +135 (ไม่ใช่ +245); Output ไม่มี error; type check ผ่าน
  - ID จริงใส่แล้ว (2026-11-17): VIP 2094074714, Auto-Fish Pro 2094398695, Infinite Bag 2094482688; 25 Gems 3732771844, 110 Gems 3732772008, 300 Gems 3732772134
  - เช็คด้วย API จริงแล้ว: ID ทุกตัวถูก; เข้าเกมแล้วระบบตั้ง pass ทั้ง 3 เป็น "Owned" ให้เอง (เจ้าของเกมมี pass ของตัวเองอัตโนมัติ) และ stat ขึ้นตามนั้น
  - **ค้างที่คุณ:** (1) pass ทั้ง 3 ยัง**ไม่ได้เปิดขาย** (Sales → Item for Sale) (2) ราคา Developer Product ที่ API ส่งกลับมาเป็น 20 / 75 / 179 R$ ไม่ใช่ 25 / 99 / 249 → เช็คหน้า Configure ของแต่ละอันว่าราคาที่บันทึกไว้คือเท่าไหร่ และ Price Optimization / ราคาตามภูมิภาคเปิดอยู่หรือเปล่า
  - ทดสอบ:
    - [ ] 1. F2 → `grant pass VIP` → stat Luck +15% ขึ้นในหน้าข้อมูล; `revoke pass VIP` → หายไป
    - [ ] 2. F2 → `receipt GemsMedium abc` 2 ครั้ง → ครั้งแรก "granted", ครั้งสองบอก "duplicate" และ Gems เพิ่มแค่ 110
    - [ ] 3. ออกเกมแล้วเข้าใหม่ → Gems ที่ได้ยังอยู่, pass ที่ grant ยังอยู่ และไม่ได้ซ้ำ (ต้องเปิด Studio Access to API Services)
    - [ ] 4. (หลังใส่ ID จริง) Play → เรียกซื้อ 25 Gems (test purchase ใน Studio ไม่เสียเงินจริง) → ได้ 25 Gems 1 ครั้ง, Output มี `[Monetization] ... granted`
    - [ ] 5. (หลังใส่ ID จริง) ซื้อ VIP แบบ test → Luck +15% ทันที ไม่ต้องเข้าเกมใหม่
- [ ] **C14.** บ่อปลา (Aquarium) + Pearls — *Done when:* ใส่ปลาจากกระเป๋าลงบ่อได้, Pearls เพิ่มทุกวินาที, ออกเกมแล้วกลับมาได้ Pearls ตามเวลาออฟไลน์ (สูงสุด 4 ชม.; VIP 12 ชม.), ขยายช่องด้วย Coins • *ใครทำ:* Claude (server/data) + session UI
  - Pearls/นาที ตามระดับ: C 0.2 · U 0.5 · R 1.5 · E 4 · L 12 · M 40 × ตัวคูณ mutation; ช่องเริ่ม 3 ขยาย 5k → 20k → 80k → 300k → 1M …
  - UI (session อื่น): หน้าต่างบ่อปลา, ตัวนับ 🫧 บน HUD, popup "ระหว่างไม่อยู่ +X 🫧", ปุ่ม "ใส่บ่อ" ใน Inventory, จุดบ่อบนแมพ (ต้องเพิ่ม slot ใหม่ใน `Map.Slots`)
  - Remote (ตกลงกับ session UI 2026-11-17): `PutInTank({ {Id, Mutation, Count} })` ใส่หลายกองในครั้งเดียว (ใส่ตัวเดียว = Count 1) → server เช็คช่องว่างกับจำนวนในกระเป๋า ถ้าไม่ผ่านจะปฏิเสธทั้งชุด ไม่ใส่ไปบางส่วน แล้วตอบสถานะบ่อใหม่ (รูปแบบเดียวกับข้อมูล Aquarium)
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17)** — ไฟล์: `Shared/Aquarium.luau` (สูตร + `State()` ใช้ร่วม server/client), `Services/AquariumService.luau`, `GameConfig.Aquarium` (ช่องเริ่ม 3, ราคาช่อง 5k → 20k → 80k → 300k → 1M → 3.5M → 12M → 40M → 140M = สูงสุด 12 ช่อง, อัตราตาม rarity), stat ใหม่ `PearlRate` (ตัวคูณ, ใช้ใน C15) + `OfflineCapHours` (เริ่ม 4; VIP +8 = 12), เซฟ `Pearls`, `Aquarium{Slots, Fish}`, `LastOnline`, `Lifetime.PearlsEarned`
  - Remote: `PutInTank({ {Id, Mutation, Count} })`, `TakeFromTank(uid)` (กลับเข้ากระเป๋า ได้มูลค่าเดิม), `BuyTankSlot()` → ตอบ `{ ok, reason?, Aquarium = State }`; event `OfflineReward { Seconds, Credited, Pearls, Capped, CapHours }` (ส่งหลัง client พร้อม)
  - Pearls ออนไลน์: server บวกทุก 5 วิ แต่ส่ง snapshot ทุก 30 วิ → UI ให้นับขึ้นเองจาก `Aquarium.State(profile).Rate`
  - ออฟไลน์: เวลาไม่อยู่นับจาก `LastOnline` (เซฟล่าสุด) ไม่ถึง 60 วิ = ไม่ได้; ปลาในบ่อเก็บมูลค่าต่อตัว (ค่าเฉลี่ยของกอง) ไว้คืนตอนเอาออก; กองในกระเป๋าเก็บแค่น้ำหนักตัวหนักสุด → น้ำหนักในบ่อเป็นค่าประมาณ
  - Claude ทดสอบแล้วใน Studio (ยิง remote จริง): ใส่ 5 ตัวแต่มี 3 ช่อง → ปฏิเสธทั้งชุด; ใส่ Dewdrop Koi + Pebble Minnow (Golden) → 2.10/นาที (1.5 + 0.2×3) ✓; 12 วิ → +0.40 ✓; `offline 2h` → +252 ✓; `offline 20h` → ได้ 12 ชม. (คุณมี VIP) ✓; ซื้อช่อง 4 ✓; เอาออก ✓; Output ไม่มี error
  - เข้าเกมใหม่จริง (ไม่ใช่คำสั่ง Dev) ยังไม่ได้ทดสอบ — เซฟ Studio ของคุณเพิ่งเริ่มมี `LastOnline` ต้องเล่น 1 รอบก่อน
  - ทดสอบ (ใช้ F2 ไปก่อน จนกว่าหน้าจอบ่อจะมา):
    - [ ] 1. F2 → `give fish DewdropKoi 1` → (หน้าจอ UI) ใส่บ่อ → ปลาออกจากกระเป๋า, บ่อมี 1/3
    - [ ] 2. รอ 1 นาที → Pearls เพิ่มประมาณ 1.5
    - [ ] 3. F2 `offline 2h` → ได้ Pearls = อัตรา × 120 นาที + popup; `offline 20h` → ได้แค่ 12 ชม. (VIP) — ไอดีที่ไม่มี VIP ได้ 4 ชม.
    - [ ] 4. ซื้อช่องที่ 4 (5,000 coins) → บ่อเป็น 1/4
    - [ ] 5. ใส่ปลาในบ่อแล้ว ออกเกม รอ 2–3 นาที แล้วเข้าใหม่ (ต้องเปิด Studio Access to API Services) → ได้ popup Pearls ตามเวลาที่ไม่อยู่
- [ ] **C15.** Mastery — *Done when:* ใช้ Pearls อัปได้ 7 สาย (Luck, Catch Bar, Reel Power, Auto Wait, Pearl Rate, เพดานออฟไลน์, Sell Mult), ราคา ×1.15/เลเวล, ผลเข้า stat ทันที และไม่ถูก Rebirth ล้าง • *ใครทำ:* Claude + session UI
  - Luck จาก Mastery แบบ diminishing (กันซ้อนแรงช่วงท้าย)
  - UI (session อื่น): หน้าต่าง Mastery (การ์ดต่อสาย: เลเวล, ผลตอนนี้ → ถัดไป, ราคา)
  - **หน้าต่างตาม Figma เสร็จ (2026-11-18)** — `UI/MasteryScreen.luau` (Figma `3539:31275`): หัว Pearls สด + `+X/s` + "Total Lv." + "Kept after Rebirth"; การ์ด 2 คอลัมน์ ไอคอน + Lv + `ตอนนี้ → ถัดไป` + ปุ่ม UPGRADE ราคา Pearls (เขียว = พอจ่าย, เทา = ไม่พอ, MAX = เต็ม) ปุ่มเปลี่ยนเป็นเขียวเองทันทีที่ Pearls ถึง; ไอคอน/สีพื้นอยู่ใน `Config/Mastery` (`Icon`, `IconTile`)
  - ไอคอน `icon_clover / icon_bar / icon_reel / icon_timer` และไอคอนเวกเตอร์ทั้งหมด 12 ตัว export จาก Figma ไว้ที่ `assets/ui-global/` + ลง `assets/catalog.json` และ **อัปโหลดขึ้น Roblox Asset Server ได้ rbxassetid ครบทั้งหมดแล้ว** พร้อมซิงค์เข้า `UIAssets.luau` แสดงผลภาพจริงในเกมทันที
  - Claude ทดสอบในเกม (ภาพจริง): Menu → ไทล์ Mastery → หน้าต่างเปิด, Pearls วิ่ง, กด UPGRADE Luck → Lv.1, ราคา 15 → 17, Total Lv. 1, ข้อความ "Luck Lv.1!"
  - *Done when (UI):* หน้าต่างตรง Figma, อัปได้ทุกสาย, ปุ่มเทาเมื่อ Pearls ไม่พอ, MAX เมื่อเต็ม
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17)** — ไฟล์: `Config/Mastery.luau` (7 สาย, ราคาเริ่ม + `PriceGrowth` 1.15), `Shared/Mastery.luau` (สูตร + `Tracks(profile)` ให้ UI), `Stats.Collect` (Mastery = stat source), เซฟ `Mastery[trackId] = level`, remote `UpgradeMastery(trackId)` → `{ ok, reason?, Tracks, Pearls }` (อยู่ใน `AquariumService` เพราะต้อง settle Pearls ก่อนจ่าย), คำสั่ง Dev `mastery <track> <level>` / `mastery reset`
  - ค่าตั้งต้น (แก้ได้ใน config): Luck +100% สูงสุดแบบลดหลั่น (`1 − 0.98^Lv`: Lv1 +2%, Lv50 +64%, Lv100 +87%) ราคาเริ่ม 15 · Catch Bar +0.2%/Lv (สูงสุด Lv50) 10 · Reel Power +0.01/Lv 10 · Auto Wait −0.5%/Lv (สูงสุด Lv40) 12 · Pearl Rate +0.02/Lv 8 · Offline Cap +15 นาที/Lv (สูงสุด Lv32 = +8 ชม.) 20 · Sell Mult +0.01/Lv 15
  - ไม่ถูก Rebirth ล้าง: เก็บแยกใน `profile.Mastery` — ตอนทำ C3 ห้ามล้างช่องนี้
  - Claude ทดสอบแล้วใน Studio: อัป Luck → Pearls −15, ราคาถัดไป 17 → 19 (= 15 × 1.15^n) ✓, stat Luck +0.0396 หลัง 2 ขั้น ✓, Catch Bar Lv50 แล้วอัปไม่ได้ ✓, id ผิดถูกปฏิเสธ ✓; Output ไม่มี error
  - ทดสอบ:
    - [ ] 1. F2 `give pearls 1000` → (หน้าจอ UI) อัป Luck 1 ขั้น → Pearls ลดตามราคา, ป้าย Luck ใน Shop/ตัวละครเพิ่ม
    - [ ] 2. ราคาขั้นถัดไป = ราคาเดิม × 1.15 (ปัดลง)
    - [ ] 3. ออกแล้วเข้าใหม่ → เลเวล Mastery ยังอยู่
    - [ ] 4. F2 `mastery OfflineCap 32` → `offline 30h` ได้ 20 ชม. (VIP 12 + 8) / ไอดีไม่มี VIP ได้ 12 ชม.
    - [ ] 5. กด Menu → ไทล์ Mastery → เห็นการ์ด 7 ใบ 2 คอลัมน์ ตัวเลข Pearls บนหัววิ่งขึ้นเรื่อยๆ
    - [ ] 6. F2 `mastery OfflineCap 32` → การ์ด Offline Cap ขึ้น **MAX** สีเทา กดไม่ได้
    - [ ] 7. ใช้ Pearls จนเหลือน้อยกว่าราคา → ปุ่มเป็นสีเทา; รอให้ Pearls ขึ้นถึงราคา → ปุ่มกลับเป็นสีเขียวเองโดยไม่ต้องปิดเปิดหน้าต่าง
- [ ] **C16.** Gear Enhance +1…+10 — *Done when:* คัน/สายที่มีอยู่ตีบวกได้ด้วย Coins (ราคา = 10% ของราคาของ × 1.5^เลเวล), แต่ละขั้น stat หลัก +4%; ขั้นสูงใช้ Pearls (+ วัตถุดิบโซนลึก — เฟส 2) • *ใครทำ:* Claude + session UI
  - เฟส 1 = Coins อย่างเดียว; เฟส 2 = วัตถุดิบจากปลาลึก (ไอเท็มประเภทใหม่ ต้องขอรูป)
  - UI (session อื่น): ปุ่ม Enhance + แสดง +N บนการ์ดของใน Shop/Inventory
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17, เฟส 1 = Coins)** — ไฟล์: `GameConfig.Enhance` (Rods + Lines, สูงสุด +10, +4%/ขั้น, ราคา `ราคาของ × 0.1 × 1.5^ขั้น`, `PearlCosts` ว่างไว้สำหรับเฟส 2), `Shared/Enhance.luau` (สูตร + `State()` ให้ UI), `Stats.Collect` (ของที่ใส่อยู่คูณตามขั้น), เซฟ `Enhance[category][itemId] = level`, remote `Enhance(category, itemId)` → `ok, message, state`, คำสั่ง Dev `enhance <Rods|Lines> <item> <0-10>`
  - ไม่คูณ `MaxDepth` (ความลึกของสายคือขั้นของสาย) → Cotton Line / Driftwood Rod ไม่มี stat ให้คูณ = ตีบวกไม่ได้; Hemp Line มีแต่ความลึก = ตีบวกไม่ได้; Nylon/Silk คูณแค่ Resilience
  - Claude ทดสอบแล้วใน Studio: Bamboo +1 → เงิน −150 ✓, ขั้นต่อไป 225 ✓, Reel Power +0.006 / Luck +0.002 / Catch Bar +0.0012 (= 4%) ✓; +9 → +10 ได้ แล้วขึ้น MAX ✓; Cotton Line ถูกปฏิเสธ ✓; Output ไม่มี error (เงิน/ขั้นที่ใช้ทดสอบในเซฟ Studio คืนให้แล้ว)
  - ทดสอบ:
    - [ ] 1. มี Bamboo Rod → (ปุ่ม UI หรือ F2 ไปก่อน) Enhance +1 → เงินลด 150 (10% ของ 1,500), Reel Power/Luck ของคันเพิ่ม 4%
    - [ ] 2. +10 แล้วปุ่ม Enhance หายหรือเป็น MAX
    - [ ] 3. ออกแล้วเข้าใหม่ → ขั้น +N ยังอยู่; เปลี่ยนไปใช้คันอื่นแล้วกลับมา → ขั้นยังอยู่ (ผูกกับของ ไม่ใช่ช่อง)
- [ ] **C17.** ดาวออร่า + Star Token + pity ใหม่ — *Done when:* ได้ออร่าซ้ำ → ได้ Star Token; ใช้ token อัปดาว ★1–★5 (stat +20%/ดาว); pity = Legendary ทุก 100, Mythic ที่ 300 (แยกต่อ banner); x10 การันตี Rare+; หน้ากาชาแสดงอัตราจริง • *ใครทำ:* Claude + session UI
  - ย้ายเซฟ: ออร่าที่มีหลายตัวอยู่แล้ว → แปลงตัวซ้ำเป็น token ครั้งเดียว
  - UI (session อื่น): ดาวบนการ์ดออร่า, ปุ่มอัปดาว, ตัวนับ pity 2 แถว, อัตราจริงในหน้ากาชา
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17)** — ไฟล์: `Config/AuraStars.luau` (★ สูงสุด 5, +20%/ดาว, token ต่อตัวซ้ำตาม rarity C1/U2/R4/E10/L25/M60, ราคาดาว 2/4/8/15/30 × ตัวคูณ rarity C1/U2/R4/E10/L30/M80), `Shared/AuraStars.luau`, `Stats.Collect` (ออร่าที่ใส่คูณตามดาว — ไม่คูณ mutation), `AuraBanners` (Altar + NeonTide: pity **Legendary ทุก 100** + `HardPity` **Mythic ที่ 300**, x10 การันตี **Rare+**), `Roll.Aura(..., minTier, maxTier)` + **`Roll.AuraRates(luck, rateUp)`** (อัตราจริง ให้หน้ากาชาใช้), `AuraService.GiveAura` (ตัวซ้ำ → token, ใช้ทั้งสุ่ม / milestone / Dev), remote `StarUpAura(id)` → `ok, message, { Stars, StarTokens }`, ผลสุ่มมี `Tokens` ต่อช่อง
  - เซฟ schema 4: `Auras.Stars`, `Auras.StarTokens`, `Gacha.PityHard`; ย้ายเซฟเก่า: ออร่าที่มีหลายตัว → ตัวซ้ำเป็น token ครั้งเดียว (Owned = 1), pity เดิม (นับไป Mythic) → ใส่ทั้งตัวนับ Mythic และ Legendary (ไม่เกิน 99)
  - หน้ากาชาเดิมยังใช้ได้: แถบ pity เดิมตอนนี้แสดง "Legendary guaranteed in" (ทุก 100) — แถว Mythic 300 = `Gacha.PityHard` รอ session UI
  - อัตราจริง (ไม่มี luck/rate-up): Sparkling Dew 98.85% · Neon Wave 1.00% · Solar Flare 0.13% · Abyssal Shadow 0.02% · Dragon Emperor 0.002%
  - Claude ทดสอบแล้วใน Studio: เซฟคุณย้ายแล้ว (ได้ 185 token จากออร่าซ้ำ); `give aura SparklingDew 3` → +3 token; อัปดาว → −2 token, Luck +0.01 (5% → 6%) ✓; `pity Altar 99` → ได้ Abyssal Shadow (Legendary) ✓; `pity Altar 299 mythic` → ได้ Dragon Emperor ✓; x10 ห้าครั้งมี Rare+ ทุกครั้ง ✓; Output ไม่มี error (Gems ที่ใช้ทดสอบได้มาจาก `give gems`)
  - ทดสอบ:
    - [ ] 1. F2 `give aura SparklingDew 3` → Star Token เพิ่ม 3; (ปุ่ม UI หรือ `stars SparklingDew 1`) อัปดาว → stat Luck จาก 5% เป็น 6%
    - [ ] 2. `pity Altar 99` → สุ่ม x1 → ได้ Legendary (ไม่ใช่ Mythic)
    - [ ] 3. `pity Altar 299 mythic` → สุ่ม → ได้ Mythic
    - [ ] 4. สุ่ม x10 → มี Rare ขึ้นไปอย่างน้อย 1
    - [ ] 5. สุ่มได้ออร่าที่มีอยู่แล้ว → ไม่ได้ตัวที่ 2 แต่ได้ Star Token (ดูตัวเลขใน F2 `stars tokens 0`)
- [ ] **C18.** ปลาขายดีประจำชั่วโมง — *Done when:* ทุก 60 นาที ร้านสุ่มปลา 1–2 ชนิด ราคา ×2–×3 (ทั้งเซิร์ฟเหมือนกัน), ขายแล้วได้ราคานั้นจริง • *ใครทำ:* Claude + session UI
  - UI (session อื่น): ป้ายที่ร้าน + แถบใน Inventory บอกว่าชนิดไหนขายดี
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17)** — `GameConfig.HotFish` (ทุก 60 นาที, 1–2 ชนิด, ×2 / ×2.5 / ×3, เฉพาะ Common–Epic), `Shared/HotFish.luau`: **คำนวณจากชั่วโมง UTC + Seed** → ทุกเซิร์ฟและทุก client ได้ผลเดียวกันโดยไม่ต้องส่งข้อมูล; `Inventory.SellValue` คูณปลาขายดีแล้ว (Sell All / Sell กอง / ราคาที่ client แสดงตรงกันเอง) + `Inventory.HotBonus` สำหรับบรรทัด "Hot fish bonus"; การ์ดปลาที่ตกได้มี `Hot` (> 1 = ขายดี) และ `Value` รวมโบนัสแล้ว; event `HotFish` ส่งตอนเข้าเกม + ทุกครั้งที่เปลี่ยน พร้อมข้อความแจ้งทุกคน
  - คำสั่ง Dev: `hotfish` (ดูรายการ), `hotfish <fish> <mult> [5m]` (บังคับชั่วคราว — ใช้ attribute บน ReplicatedStorage ให้ client เห็นตรงกัน), `hotfish off`
  - Claude ทดสอบแล้วใน Studio: server กับ client คำนวณรายการได้ตรงกัน (ตอนทดสอบ: Tide Snapper ×3, Gloom Sprat ×2) ✓; `hotfish StripeBass 3` → ได้ event + ข้อความ ✓; ขาย Stripe Bass 10 + Tide Snapper 10 → +5,051 ตรงกับราคาที่ client คำนวณล่วงหน้า (ปกติ 2,493 + โบนัส 2,558) ✓; Output ไม่มี error
  - ทดสอบ:
    - [ ] 1. F2 `hotfish StripeBass 3` → ขาย Stripe Bass ได้ราคา ×3 + ข้อความ "hot fish +N"
    - [ ] 2. 2 ผู้เล่นใน Studio (Test → Clients and Servers, 2 players) → F2 `hotfish` ทั้งสองจอได้รายการเดียวกัน
    - [ ] 3. รอข้ามชั่วโมง (เวลา :00) → ทุกคนได้ข้อความ "Hot fish at the Merchant: ..." ชนิดใหม่
- [ ] **C19.** Dev Products — *Done when:* ซื้อแล้วได้ของครบ ผ่าน C13 • *ใครทำ:* Claude + คุณสร้าง Product บนเว็บ
  - [ ] ทดสอบ Store: เปิดทั้งสามแท็บแล้วดูว่าไอคอน Robux อยู่หน้าตัวเลขของปุ่มที่ซื้อได้ และปุ่ม OWNED / BOUGHT / SOON แสดงข้อความสถานะ
  - ราคาสรุป 2026-11-17 (คุณเลือก: เด็กเอื้อมถึง, ของถาวรแพงได้แต่ไม่เกินราคาเกมอื่น ~400 R$ ≈ $5): ของจุกจิก 25–49 R$, ของถาวรสูงสุด 349 R$, pass ทั้ง 3 รวม 747 R$ < บัตร 800 R$
  - **Starter Pack 49 R$** (ซื้อได้ครั้งเดียวต่อไอดี): **100 Gems** (20 ครั้งสุ่ม) + เหยื่อ + คันพิเศษหน้าตาสวย stat เบา (ไม่ข้ามบันไดการซื้อช่วงแรก)
  - **Gems 25 / 99 / 249 R$ → 25 / 110 / 300 Gems** (สุ่มครั้งละ 5 Gems = 5 / 22 / 60 ครั้ง; แพ็กใหญ่ได้ต่อ Robux คุ้มกว่า; เล่นฟรีได้ ~75 Gems/ชม.)
  - **Boost 2x Coins / 2x Pearls 2 ชม.** (**39 R$ ต่ออัน**) — นับเวลาเฉพาะตอนออนไลน์หรือรวมออฟไลน์: ตัดสินใจตอนทำ
  - [x] HUD Active Boosts แสดงเวลาที่เหลือของ 2x Coins / 2x Pearls ระหว่างที่มีผล และซ่อนเมื่อหมดเวลา
  - **สถานะ: โค้ดฝั่ง server เสร็จ (2026-11-17)** — `Config/Products`: **StarterPack** 49 R$ (ครั้งเดียว: 100 Gems + Shrimp 20 + **Sweetheart Rod**), **BoostCoins** / **BoostPearls** 39 R$ (2 ชม.); รางวัลแบบใหม่ `Boost`; `Shared/Boosts.luau` (`Remaining`, `Multiplier`, `Add`); `GameConfig.Boosts` (×2); ขายปลา × boost Coins (`ShopService`), Pearls × boost (`Aquarium.CurrentRate`, `State.Rate` รวม boost แล้ว + `State.Boost`); popup ออฟไลน์มี `BoostedSeconds` / `BoostPearls`
  - **ตัดสินใจ: Boost นับเวลาจริง (รวมตอนออฟไลน์)** ตาม contract `profile.Boosts[id] = endsAt` — ง่ายกว่าและผู้เล่นเข้าใจ (ซื้อ 2 ชม. = หมด 2 ชม. ต่อมา); ซื้อซ้ำ = ต่อเวลาจากที่เหลือ; ช่วงออฟไลน์ที่ boost ยังทำงานได้ Pearls ×2
  - Sweetheart Rod (`Exclusive = "StarterPack"`): ไม่ขายในร้าน (server ปฏิเสธ + หน้า Shop ซ่อนจนกว่าจะมี), stat เบากว่า Bamboo Rod เล็กน้อย (Catch Bar +4%, Reel Power +0.08, Luck +3%), ตีบวกได้ (ราคาฐาน 1,500); ใช้รูป `equipment/SweetheartRod` ที่ตัดไว้แล้ว (ยังไม่อัปโหลด)
  - คำสั่ง Dev: `boost <coins|pearls> <2h|30m|off>`, `unbuy <product>` (ให้ซื้อ OncePerPlayer ได้อีก), `receipt StarterPack` / `receipt BoostCoins`
  - Claude ทดสอบแล้วใน Studio: Starter Pack ใบที่ 1 → Gems +100, Shrimp +20, ได้ Sweetheart Rod ✓; ใบที่ 2 → ไม่ให้ซ้ำ ✓; ซื้อ Sweetheart Rod ในร้าน → "Not sold in the shop" ✓; Boost Coins → ขาย Stripe Bass 10 ตัวได้ 2,336 (ปกติ 1,168) ✓; Boost Pearls → อัตรา 0.60 → 1.20/นาที ✓, `offline 1h` → +72 (36 + 36 จาก boost) ✓; Output ไม่มี error (หลังทดสอบ `unbuy StarterPack` แล้ว — ซื้อจริงได้)
  - **คุณต้องทำ:** สร้าง Developer Products เพิ่ม 3 อัน แล้วส่ง ID: **Starter Pack** 49 R$ (รูป `assets/art/ui/shop/starter_bundle.png`), **2x Coins (2h)** 39 R$ (`boost_coins.png`), **2x Pearls (2h)** 39 R$ (`boost_pearls.png`)
  - ทดสอบ:
    - [ ] 1. (หลังใส่ ID) ซื้อ Starter Pack (test) → ได้ของครบ; กดซื้ออีกครั้ง → ขึ้น "You already bought"
    - [ ] 2. ซื้อ Boost 2x Coins (หรือ F2 `boost coins 2m`) → ขายปลาได้เงิน ×2; หมดเวลาแล้วกลับปกติ
    - [ ] 3. F2 `boost pearls 2h` → อัตรา Pearls ในบ่อ ×2

---

### UI ค้างของ Economy (C4 / C6 / C12 / C16 / C17 / C18) — ทำแล้ว 2026-11-18
- ไฟล์: `HUDController` (ป้าย Streak บน CAST), `TitleController` (ป้ายชื่อ VIP), `UI/ItemSlots` (+N, HOT), `HotFishController` (ป้ายที่ Merchant, ใหม่), `SkillsController` (หน้าต่าง Skills, ใหม่), `UI/GachaPage` + `Screens/GachaPage` (pity 2 แถว, อัตรา %, Star Token), `MenuFill` (+N รูป Shop, ดาวใน Aura Dex), Sell All 2 ที่ (HUD + Inventory) มีบรรทัด Hot fish bonus
- พบว่า Aquarium / Mastery / Store / Boost / Quests / Tide HUD มีหน้าจออยู่แล้ว (EconomyController, QuestController, TideEventController) — สถานะในภาพรวมเก่า แก้แล้ว
- Claude ทดสอบใน Play: หน้าต่าง Skills (99 แต้ม, 3 สกิล), ป้าย HOT FISH ที่ Merchant, ป้าย +3 บนคันเบ็ด, หน้ากาชา pity 2 แถว + อัตรา %, ป้าย VIP เหนือหัว — ไม่มี error. ไม่ได้กด UPGRADE / ROLL (ไม่อยากใช้แต้ม/เพชรของคุณ)
- ทดสอบ:
  - [ ] 1. ตกปลาแบบมือติดกัน → ป้าย x1..x4 สีทองที่มุมปุ่ม CAST, x5+ ส้ม, x10 ขอบเหลือง; สายขาด/พลาด → LOST 1.5 วิ แล้วหาย
  - [ ] 2. กด C → SKILLS → UPGRADE Keen Eye → แต้มลด 1, Lv.1, Luck +1%
  - [ ] 3. Inventory แท็บ Rods: คันที่ Enhance แล้วมีป้าย +N สีฟ้ามุมซ้ายล่าง; Shop แท็บ Rods ก็มี
  - [ ] 4. ตกปลาชนิดที่อยู่ในป้าย HOT FISH ที่ Merchant → กองปลาใน Inventory มีป้าย xN สีทองมุมขวาบน; SELL ALL → ข้อความมี "Hot fish bonus +N"
  - [ ] 5. หน้ากาชา: กรอบ pity 2 แถว (Legendary / Mythic) ลดลงตอนสุ่ม; อัตราเป็น %; สุ่มได้ตัวซ้ำ → แจ้ง "+N Star Token", หน้าสรุป x10 มี "+N Star Tokens from duplicates"
  - [ ] 6. คนที่มี VIP: ชื่อสีทอง + มงกุฎเหนือหัว (คนอื่นเห็นด้วย), ไม่มีชื่อขาวซ้อน

### งานเล็กหลัง B21 / Economy UI — 2026-11-18
- [x] คำเตือน `[UI] ScreenGui "HUD" is not baked`: HUD **bake อยู่แล้ว** แต่บางครั้งตัวละครโหลดเกิน 15 วิ โค้ดเลยสร้าง HUD เองตอนเริ่ม (แล้วตัวที่ bake มาถึงทีหลัง = HUD ซ้อน 2 อัน). แก้ `UI/Baked.luau`: รอ 60 วิ และถ้าต้องสร้างเองจะลบตัวที่มาทีหลังทิ้ง
- [x] bake CastPopup ใหม่ (ตัวใน place เก่ากว่าไฟล์ — bake 17 พ.ย. 00:51 แต่ไฟล์แก้ 22:22)
- [x] Main Menu ตาม Figma Economy 7: **13 ไทล์ 4 คอลัมน์** (เพิ่ม Character, Aquarium, Store; Mastery/Quests แยกกัน), ป้าย **VIP** ใต้รูปโปรไฟล์เมื่อมี pass — bake แล้ว, Claude ทดสอบ: เมนูตรง Figma, ไทล์ Aquarium/Store เปิดหน้าต่างถูก
- [x] ชิปกระเป๋าบน HUD: มี Infinite Bag แสดง `0 / Inf` แทน `0 / 999` (ยังไม่ได้ดูใน Play)
- [ ] Daily Login (การ์ดใน Figma Economy 7) ยังไม่มีระบบ — การ์ดใน Events ยังเป็น SOON
- ทดสอบ:
  - [ ] 1. กด **M** → เมนู 13 ไทล์ ไม่ต้องเลื่อน; กด Character / Aquarium / Store / Mastery / Quests → เปิดหน้าต่างของมัน
  - [ ] 2. มี VIP → ป้าย VIP สีทองใต้รูปโปรไฟล์
  - [ ] 3. เข้าเกมหลายรอบ: Output ไม่มี `HUD is not baked`, มี HUD อันเดียว

### C21. คอนเทนต์ใหม่จากรูปที่อัปโหลดแล้วแต่ยังไม่ได้ใช้ — 2026-11-18
- คำขอ: รูปปลา / คันเบ็ด / สาย / เหยื่อ / ออร่าที่อัปโหลดขึ้น Roblox แล้ว (มี id ใน `UIAssets`) แต่ยังไม่มีในเกม เอามาทำเป็นคอนเทนต์
- เพิ่มใน Config (ตัวเลขทั้งหมดแก้ได้ในไฟล์ Config ไม่ต้องแก้โค้ด):
  - **ปลา 8 ตัว** (`Config/Fish.luau`, ลึก 220-1000m): Inklet Squid (Common), Bone Carp, Pearl Nautilus (Uncommon), Lantern Jellyfish, Frost Ray (Rare), Starlight Eel (Epic), Void Koi (Legendary, 650-1000m), Abyss Leviathan (Mythic, 800-1000m, ยากสุด 10)
  - **คันเบ็ด 2**: Abyss Rod 4.5M (Lv.35), Celestial Rod 20M (Lv.50) — สเตตไต่ต่อจาก Naga Scale Rod
  - **สาย 2**: Abyss Line 600m 1.2M (Lv.30), Star Line 1000m 6M (Lv.45)
  - **เหยื่อ 4**: Squid Bait 40k/10 (Lv.20), Pearl Bait 250k/10 (Lv.30, mutation), Storm Bait 1.2M/10 (Lv.40, กินเบ็ดเร็ว), Summon Bait 60 Gems/3 (Lv.20, Luck +400%)
  - **ออร่า 10** (`Config/Auras.luau`, รวม 15): Tidal Bloom 1/15, Kelp Whisper 1/40, Coral Heart 1/60, Moonlit Ripple 1/250, Storm Current 1/400, Frost Pearl 1/1,500, Nebula Koi 1/3,000, Lotus Naga 1/12,000, Serpent of the Void 1/25,000, Celestial Leviathan 1/150,000 — `Order` ของทุกตัวเรียงใหม่ตามความหายาก (Aura Dex / หน้าอัตรา)
  - **Starter Bay ลึกสุด 300 → 1000m** (`Config/Locations.luau`) ไม่งั้นสายใหม่ไม่มีผล
- ผลกระทบ: ออร่าใหม่ทำให้โอกาสออร่าเดิมลดลงเล็กน้อย (Sparkling Dew 98.8% → 87.8%; Dragon Emperor 0.002% เท่าเดิม); Fishdex 30 ตัว, Aura Dex 15 ตัว
- ยังไม่ใช้: `fish/deco_bubbles`, `fish/deco_seaweed` (เป็นของตกแต่ง ไม่ใช่ปลา)
- Claude ทดสอบใน Play: Registry ผ่าน (ไม่มี error), ปลา 30 / ออร่า 15 / คัน 8 / สาย 6 / เหยื่อ 7, รูปโหลดได้ทุกตัว, Shop แท็บ Rods หน้า 2 มี Abyss / Celestial พร้อมรูป
- ทดสอบ:
  - [ ] 1. Shop แท็บ Lines / Baits / Rods: ของใหม่มีรูป ราคา และล็อกเลเวลถูก; กดรูป = การ์ดไอเท็ม
  - [ ] 2. ใส่ Abyss Line → ปุ่ม DEPTH ตั้งได้ถึง 600m; Star Line → 1000m
  - [ ] 3. ตกที่ 500-1000m → ได้ปลาใหม่ (Fishdex ขึ้นเป็น x / 30)
  - [ ] 4. หน้ากาชา: รายการอัตรามี 15 ออร่า เรียงจากง่ายไปยาก; Aura Dex 15 ตัว
  - [ ] 5. ถ้าราคา/สเตตไม่ถูกใจ บอก Claude หรือแก้ใน Config ได้เลย

### C22. จุดตกปลา / ขอบแมพ ใช้เฉพาะของใน Workspace — 2026-11-19
- ปัญหา: `ServerStorage.Map_Backup_Deck9` มี `FishingZone_Boardwalk` และ `PlayArea` ติดแท็กอยู่ด้วย แต่โค้ดอ่าน `CollectionService:GetTagged` ทั้งหมด -> ขอบเขตของแมพสำรอง (อยู่สูงกว่าแมพจริง ~49 studs) นับเป็นน้ำที่ตกปลาได้ / ที่เกิดอีเวนต์ Naga Tide / ขอบแมพได้
- แก้: `FishingSpot.Zones()` / `FishingSpot.ActiveTagged(tag)` คืนเฉพาะ BasePart ที่อยู่ใน Workspace; ใช้ใน `FishingSpot.ZoneAt`, `TideEventService.pickSpot`; `PlayArea.At` ข้ามของนอก Workspace ด้วย — `node tools/check.mjs` ผ่าน
- Claude ตรวจใน Studio: เจอ FishingZone + PlayArea ใน backup จริง; จุดกลางโซน backup แบบเดิมได้ `StarterBay`, แบบใหม่ได้ `nil` (ไม่ใช่น้ำ). ปลดแท็ก FishingZone และ PlayArea ออกจาก `ServerStorage.Map_Backup_Deck9` ใน Studio แล้ว และบันทึก place ขึ้น Roblox (version 158) เรียบร้อย
- ทดสอบ:
  - [ ] 1. หยุด Play แล้ว Play ใหม่ -> ตกปลาที่ท่าเรือปกติได้เหมือนเดิม (ปุ่ม CAST ขึ้นเมื่ออยู่ใกล้น้ำ)
  - [ ] 2. F2 `event start` -> วง Naga Tide เกิดบนผิวน้ำของแมพจริง ไม่ลอยกลางอากาศ
  - [ ] 3. ว่ายออกไปไกล -> กระแสน้ำผลักกลับที่ขอบแมพเดิม

### C23. Daily Login (ปฏิทินของขวัญ 7 วัน) — 2026-11-19
- หน้าต่าง Cozy Lake 680x480 ขอบมน 24px: ชิป Streak วันล็อกอินต่อเนื่อง, ชิปเวลานับถอยหลังรีเซ็ตเที่ยงคืน UTC, การ์ดของรางวัล 7 วัน (แถวแรกวันที่ 1-4, แถวล่างวันที่ 5-6 และวันที่ 7 Grand Reward ขนาดใหญ่สีทอง), ปุ่มกดรับ CLAIM DAY N สีเขียวมินต์
- ไฟล์: `Config/DailyLogin.luau`, `Shared/DailyLogin.luau`, `Services/DailyLoginService.luau`, `UI/Screens/DailyLogin.luau` (bake แล้ว), `Controllers/DailyLoginController.luau`, `UI/EventActions/DailyLogin.luau`, remote `ClaimDailyLogin`; การ์ดใน Events hub ปลดล็อคจาก SOON เป็นปุ่ม OPEN เปิดหน้าต่างเคลมรางวัล
- ของรางวัล: วันที่ 1 (1,000 Coins), วันที่ 2 (15 Worms), วันที่ 3 (15 Gems), วันที่ 4 (10 Glow Grubs), วันที่ 5 (500 Pearls), วันที่ 6 (10 Squid Baits), วันที่ 7 (50 Gems)
- ป้องกันการกดเคลมซ้ำฝั่ง server, บันทึกสถิติ Streak และรีเซ็ตอัตโนมัติหากขาดการล็อกอินเกิน 1 วัน
- ทดสอบ:
  - [ ] 1. Ctrl+S → Play → เปิดโทรศัพท์ Main Menu → Events → การ์ด Daily Login ขึ้นแท็ก DAILY และกด OPEN ได้
  - [ ] 2. หน้าต่าง Daily Login เปิดขึ้นมา แสดง Streak: 1 Day, ปุ่ม CLAIM DAY 1 สีเขียวมินต์
  - [ ] 3. กด CLAIM DAY 1 → ได้รับ 1,000 Coins, สถานะเปลี่ยนเป็น CLAIMED, ปุ่มเปลี่ยนเป็น CLAIMED TODAY สีเทา
  - [ ] 4. กดปุ่ม X หรือคลิก Backdrop พื้นหลังสีดำ → หน้าต่างปิดลงอย่างเรียบร้อย

### B7. 11 Dialogue (NPC) — 2026-11-19
- Figma 11 (`docs/figma/cozy_menus_spec.py` s_dialogue): กล่องคุยด้านล่าง 900x190, ป้ายชื่อสีมิ้นต์, ปุ่มตัวเลือกแคปซูลด้านขวา (สูงสุด 4), ปุ่ม X กลมที่มุมขวาบนของกล่อง, ไม่มีรูป NPC (NPC อยู่ในโลก 3D); ไอคอนใช้ของเดิมในโปรเจกต์ (icon_fish / icon_flame / icon_reel / icon_chat / icon_star / icon_info)
- ไฟล์: `Config/Dialogues.luau` (บทพูด + ตัวเลือก, Registry ตรวจ), `UI/Screens/Dialogue.luau` (bake แล้ว), `Controllers/DialogueController.luau`, remote ใหม่ `OpenDialogue`; server: prompt ที่ร้าน (SellPrompt) และแท่นออร่า (RollPrompt) เปลี่ยนเป็น **Talk / Old Marlin** และ **Talk / Sela** เปิดบทสนทนาแทนการขาย/เปิดกาชาทันที
- Old Marlin: Sell All Fish (ยืนยันแบบเดียวกับปุ่ม SELL ALL), Hot fish today?, Browse gear (Shop), Just chatting; ถ้ามีปลาในกระเป๋าจะทักพร้อมจำนวนปลา + เงินที่จะได้
- Sela: Open the Altar (หน้ากาชา), Star Tokens? (อธิบาย), Just chatting
- ข้อความพิมพ์ทีละตัว (กดกล่อง = แสดงทั้งหมด); ปิด: X / Esc / เดินห่างเกิน 22 studs
- หมายเหตุ: `node tools/ui/bake.mjs` ใช้ไม่ได้รอบนี้ (StudioBridge port 3060 ไม่ได้เปิด) — bake ผ่าน Roblox Studio MCP แทน (รัน `Screens/Dialogue.Build()` ใน Studio, ผลเหมือนกัน)
- Claude ทดสอบใน Play: กด E ที่ร้าน -> กล่อง Old Marlin "19 fish! I can give you 4.09M coins for the lot."; Hot fish today? -> "This hour I pay x3 for Lily Trout..."; Just chatting เปลี่ยนบรรทัดทุกครั้ง; Sell All Fish -> หน้ายืนยัน (กด Cancel ไม่ได้ขายของคุณ); Browse gear -> Shop; Sela: Open the Altar -> หน้ากาชา; เดินออกห่าง -> ปิดเอง; ไม่มี error. แก้ระหว่างทดสอบ: พื้นกล่องวาดไม่เต็ม (UIPadding ไปหด 9-slice Shadow)
- ทดสอบ:
  - [ ] 1. Ctrl+S → Play → เดินไปที่ร้าน → ป้ายบอก "Talk / Old Marlin" → กด E → กล่องคุยขึ้นด้านล่าง ข้อความพิมพ์ทีละตัว
  - [ ] 2. Sell All Fish → หน้ายืนยัน → Sell → ได้เงิน Marlin ขอบคุณพร้อมจำนวนเงิน
  - [ ] 3. Hot fish today? / Just chatting / Browse gear ทำงาน; ปุ่ม X และ Esc ปิดได้; เดินออกไปไกล = ปิดเอง
  - [ ] 4. ที่แท่นออร่า "Talk / Sela" → Open the Altar เปิดหน้ากาชา
  - [ ] 5. แก้บทพูด/เพิ่มตัวเลือกใน `Config/Dialogues.luau` ได้เลย (สูงสุด 4 ตัวเลือกต่อ NPC)

### C24. Core Menu Manager — 2026-11-19
- ปัญหาเดิม: แต่ละหน้าต่างปิดตัวอื่นเองคนละแบบ บางตัวลืมปิด → หน้าต่างเปิดทับกันเรื่อย ๆ
- ใหม่: `src/client/UI/MenuManager.luau` แบ่ง 5 ชั้น — Hub (Main Menu), Main (หน้าต่างหลัก เปิดได้ทีละอัน), Dialogue (คุย NPC), Popup (การ์ดไอเท็ม), Modal (ยืนยัน / เปิดกาชา ซ้อนได้เสมอ)
- ซ้อนได้เฉพาะที่ตั้งไว้ (StackOn): Skills บน Character, Aura Dex บน Inventory, หน้ากาชาบน Events / Inventory / Aura Dex — ปิดตัวบนแล้วกลับไปตัวล่าง, ปิดตัวล่างแล้วตัวบนปิดตาม
- วิธีใช้ + วิธีเพิ่มหน้าจอใหม่ + งานส่งต่อ: `docs/MENU_MANAGER.md`
- แก้ระหว่างทดสอบ: `src/shared/Remotes.luau` บรรทัด 64 ถูกแก้ให้เรียก `RunService:IsEdit()` ซึ่ง client เรียกไม่ได้ → client ทั้งเกมโหลดไม่ขึ้น เปลี่ยนเป็น `not RunService:IsRunning()`
- Claude ทดสอบใน Play ผ่าน: B → C (Inventory ปิดเอง), SKILLS ซ้อนบน Character, M ปิดทั้งคู่, AURA DEX ซ้อนบน Inventory และปิดแล้วกลับมา, ปุ่ม Shop ปิด Inventory; ไม่มี error
- งานส่งต่อ (ทำตามลำดับ รายละเอียดใน MENU_MANAGER.md ข้อ 8):
  - [ ] M1 ทดสอบเส้นทางที่ยังไม่ได้ลอง (Dialogue, กาชา, Store, Aquarium, Mastery, Quests, Events, Daily Login, Credits, Modal)
  - [ ] M2 Put in Tank ซ้อนบน Aquarium `โค้ดเสร็จ รอทดสอบ` (ปิดหน้าเลือกปลา / กด < Tank / CONFIRM แล้วกลับมาหน้าบ่อ)
  - [ ] M3 ปุ่มย้อนกลับ (gamepad B) → `MenuManager.CloseTop()` `โค้ดเสร็จ รอทดสอบ` (Esc ยังปิดได้แค่กล่องคุย NPC; Backspace รอคุณตัดสินใจ)
  - [ ] M4 ไล่ลบการปิดหน้าต่างด้วยมือที่เหลือ `โค้ดเสร็จ รอทดสอบ` (ลบ 6 จุด; ผลที่เปลี่ยน: เปิดแบนเนอร์จาก Events แล้วกดปิด กลับมาหน้า Events แทนที่จะปิดหมด)
  - [ ] M5 ถามคุณ: หน้าต่างที่เปิดจาก Main Menu ปิดแล้วควรกลับไป Main Menu ไหม
  - [ ] M6 (ถ้าต้องการ) ซ่อนปุ่ม HUD ด้านข้างตอนเปิดหน้าต่างบนจอเล็ก
- ทดสอบ (คุณ):
  - [ ] 1. Play → B (กระเป๋า) → C (ตัวละคร): กระเป๋าต้องปิดเอง
  - [ ] 2. ในหน้าตัวละครกด SKILLS: หน้า Skills ซ้อนบน, ปิด Skills แล้วกลับมาหน้าตัวละคร
  - [ ] 3. กระเป๋า → แท็บ Auras → AURA DEX ซ้อนบน; ROLL AURA เปิดหน้ากาชาซ้อนบนกระเป๋า
  - [ ] 4. เปิดหน้าต่างไหนอยู่ก็ได้แล้วกด M: เหลือแค่ Main Menu
  - [ ] 5. คุยกับ Old Marlin ขณะเปิดกระเป๋า: กระเป๋าปิด, Browse gear เปิด Shop และกล่องคุยปิด
  - [ ] 6. (M2) เปิด Aquarium → กดช่อง + : หน้า Put in Tank ซ้อนบนบ่อ; กด < Tank หรือ X → กลับมาหน้าบ่อ; เลือกปลาแล้ว CONFIRM → กลับมาหน้าบ่อและเห็นปลาที่ใส่
  - [ ] 7. (M3) ใช้จอย: เปิดหน้าต่างใดก็ได้แล้วกด B → ปิดแค่ตัวบนสุด (Skills บน Character กด B = เหลือ Character); คุย NPC แล้วกด Esc → กล่องคุยปิด
  - [ ] 8. (M4) Events → OPEN ที่แบนเนอร์กาชา → กดปิด/ลูกศรกลับ → กลับมาหน้า Events; Events → การ์ด Daily Login / การ์ดเปิด Shop → Events ปิดเอง เหลือหน้าที่เปิดอันเดียว; Main Menu → กดรูปตัวละคร → เปิด Character และ Main Menu ปิด; หน้ากาชา → ปุ่มซื้อ Gems → เปิด Store และหน้ากาชาปิด

### C25. เหวี่ยงเบ็ดใหม่ (กดค้าง + Perfect Cast + ระยะเหวี่ยงตามคัน) — 2026-11-20  `โค้ดเสร็จ รอทดสอบ`
- ไม่มีปุ่ม CAST กลางจอและหน้าต่างตั้งความลึกแล้ว: ตั้งความลึกที่ตัวปรับ `[-] DEPTH 80m [+]` เหนือปุ่ม AUTO (กดค้างเลื่อนเร็ว, บันทึกลงเซฟเอง, ไม่เกินความลึกสูงสุดของสาย)
- เหวี่ยง: PC คลิกซ้ายบนฉาก (ไม่ใช้ E เพราะชนปุ่มคุย NPC), จอย R2, มือถือปุ่มกลม CAST ข้างปุ่มกระโดด; ทิศ = ทิศกล้อง
- กดค้าง = แถบพลังขึ้นลงข้างตัวละคร + วงเล็งบนพื้น (ฟ้า = น้ำ, เทา = ไม่ใช่น้ำ); ปล่อยในช่วงทอง = PERFECT! (ปลากินเร็วขึ้น 30%); กดสั้น ๆ = เหวี่ยงระยะกลาง
- ไม่ลงน้ำ: ทุ่นตกพื้นแล้วม้วนกลับ + ข้อความ "Cast into the water!" ไม่เริ่มตกปลา
- AUTO: หันกล้องไปทางน้ำแล้วกด AUTO → เหวี่ยงซ้ำทิศเดิม; ข้างหน้าไม่มีน้ำ = ไม่เริ่ม; เดินออกเกิน 8 studs = หยุดเอง
- stat ใหม่ `CastRange` (ฐาน 14 studs) คันเบ็ดบวกเพิ่ม Bamboo +3 ... Celestial +18; ตัวเลขทั้งหมดใน `GameConfig.Cast` (`HoldCharge = false` = ลองแบบกดทีเดียวอย่างเดียว)
- Hot Streak ย้ายไปป้ายเล็กกลางล่าง (เดิมติดมุมปุ่ม CAST)
- Figma: 01 · HUD (ลบ Cast Row, เพิ่ม Depth Stepper ใน Actions, Btn Cast Mobile, เฟรม "Cast Charge [state: holding]") สคริปต์ `docs/figma/cast_rework.py`; ลบ CastPopup (โค้ด + StarterGui), bake HUD แล้ว
- รอบหน้า: จุดฟองปลา (Hotspot) → ทำแล้วเป็น C26
- ทดสอบ (คุณ):
  - [ ] 1. Ctrl+S → Play → เดินไปริมน้ำ: ไม่มีปุ่ม CAST กลางจอ, มีตัวปรับ DEPTH เหนือ AUTO; กด + / - และกดค้าง ตัวเลขเปลี่ยน ไม่เกินความลึกสาย
  - [ ] 2. หันกล้องไปที่น้ำ คลิกค้าง: แถบพลังขึ้นลง, วงเล็งสีฟ้าบนน้ำวิ่งใกล้-ไกล, ตัวละครหันตามกล้อง
  - [ ] 3. ปล่อยตอนเข็มอยู่ช่วงทอง: ขึ้น PERFECT! ทุ่นลอยโค้งลงน้ำ แล้วเข้าสถานะ Waiting ตามปกติ ("!" → คลิก → มินิเกม)
  - [ ] 4. คลิกสั้น ๆ: เหวี่ยงระยะกลางทันที ไม่มีแถบพลัง
  - [ ] 5. หันกล้องไปบนบกแล้วเหวี่ยง: วงเล็งเทา, ทุ่นตกพื้นแล้วม้วนกลับ, ขึ้น "Cast into the water!" (ลองเหวี่ยงขณะเดินริมฝั่งด้วย: ถ้าเห็นทุ่นลงน้ำแต่ขึ้นข้อความนี้ = server เห็นตำแหน่งช้ากว่า แจ้ง Claude)
  - [ ] 6. หันไปทางน้ำ กด AUTO: ตกเองซ้ำ ๆ; เดินออกไปไกล → Auto หยุด; หันไปบนบกแล้วกด AUTO → ไม่เริ่ม มีข้อความเตือน
  - [ ] 7. ใส่คันที่ดีกว่า (เช่น Coral): เหวี่ยงค้างสุดได้ไกลกว่าคันเริ่ม; หน้ารายละเอียดคันมี Cast Range
  - [ ] 8. มือถือ (Studio Device Emulator): ปุ่มกลม CAST ข้างปุ่มกระโดด กดค้าง/ปล่อยเหวี่ยงได้, ระหว่างรอปลาปุ่มเป็น REEL IN / HOOK!; ปุ่ม Bag/DEPTH/AUTO/SELL ไม่ทับปุ่มกระโดด

### C26. จุดฟองปลา (Hotspot) — 2026-11-20  `โค้ดเสร็จ รอทดสอบ`
- วงสีทองมีฟองอากาศโผล่ในน้ำใกล้ผู้เล่นที่ยืนริมน้ำ (ทั้งเซิร์ฟเวอร์มีได้ 4 จุด อยู่ 35-55 วินาทีแล้วหายไปโผล่ที่ใหม่) ระยะ 9-26 studs จากผู้เล่น: จุดไกลต้องใช้คันที่ CastRange สูง
- เหวี่ยงเอง (ไม่ใช่ Auto) ลงในวง = Luck +50% สำหรับการเหวี่ยงครั้งนั้น + ข้อความ "HOTSPOT!  +50% luck on this cast" + ป้าย HOTSPOT บนการ์ดปลา; วงหนึ่งใช้ได้ 2 ครั้งแล้วหาย
- ตอนกดค้างเล็ง: วงเล็งเป็นสีทอง + ป้าย HOTSPOT เมื่อเล็งเข้าวง
- ตัวเลขใน `GameConfig.Hotspot`; โค้ด `server/Services/HotspotService.luau`, ต่อเข้า FishingService (`Claim` ตอนเหวี่ยง)
- Figma: 01 · HUD เฟรม Cast Charge มีภาพจำลองวง Hotspot + วงเล็งทอง; 10 · Notifications เพิ่ม toast Hotspot และเปลี่ยน "Face the water" เป็น "Cast into the water!" (สคริปต์ `docs/figma/hotspot.py`); การ์ดปลา 04 มีป้ายทอง HOTSPOT ต่อจาก PERFECT แล้ว (prefab CatchCard ในเกมเพิ่มช่องป้ายเป็น 4 ช่อง ไม่งั้นป้ายที่ 4 ไม่ขึ้น, bake Components แล้ว)
- ทดสอบ (คุณ):
  - [ ] 1. Ctrl+S → Play → ยืนริมน้ำรอสักพัก (ไม่เกิน ~10 วินาที): มีวงทองฟองผุดในน้ำใกล้ ๆ
  - [ ] 2. กดค้างเล็งเข้าวง: วงเล็งเปลี่ยนเป็นสีทอง มีป้าย HOTSPOT; ปล่อย → ขึ้น "HOTSPOT! +50% luck..." แล้วตกปลาตามปกติ การ์ดปลามีป้าย HOTSPOT
  - [ ] 3. เหวี่ยงลงวงเดิมอีกครั้ง → วงหายไป (ใช้ครบ 2 ครั้ง)
  - [ ] 4. รอ ~1 นาที: วงที่ไม่มีคนใช้หายเองแล้วโผล่ที่ใหม่
  - [ ] 5. เปิด AUTO ขณะหันไปทางวง: ไม่ได้โบนัส (ไม่มีข้อความ HOTSPOT)
  - [ ] 6. ได้ทั้ง PERFECT (มินิเกมไม่หลุดเลย) และ HOTSPOT ในครั้งเดียว: การ์ดปลาแสดงครบ 4 ป้าย kg / Manual / PERFECT / HOTSPOT

### C27. Store ว่าง, spinner โหลด, แจ้งเตือนบนสุด, Enhance popup, Figma ให้ตรงเกม — 2026-11-20  `โค้ดเสร็จ รอทดสอบ`
- Store ว่าง: เจอ ScreenGui "Store" (และ "QuestsGui") ค้างอยู่ใน StarterGui จากการทดสอบในโหมดแก้ไข (โค้ดเดิม fallback ไป StarterGui เมื่อไม่มี PlayerGui) → ลบแล้ว + StoreScreen/QuestsScreen สร้างใน PlayerGui เท่านั้น; Render แต่ละแท็บอยู่ใน pcall ถ้าพังจะขึ้นข้อความ + warn `[Store]` ใน Output แทนหน้าว่าง
- Store: เอาฉากดำด้านหลังออก
- Spinner โหลด (`New.Spinner`): Store ตอนยังไม่มีข้อมูลเซฟ, ปุ่ม Robux หมุนจนได้ราคาจริงจาก Roblox, รูปที่ยังโหลดไม่เสร็จ (skeleton) มี spinner เทาตรงกลาง
- แจ้งเตือน (toast) ย้ายไป ScreenGui "Notifications" DisplayOrder 100 → อยู่เหนือทุกหน้าต่าง/Modal/Store
- Enhance popup ใหม่ (`UI/EnhancePopup.luau`, Figma C16): ปุ่ม ENHANCE ในการ์ดไอเท็ม → popup รูป, +3 > +4, ค่าสเตตัสก่อน/หลัง (ทศนิยม 1 ตำแหน่ง), Cancel / ปุ่มทองราคาเหรียญ → ยืนยันแล้วค่อยอัป
- Aquarium: ปุ่มยืนยัน "Return to Bag" เดิมเป็นสีเขียวเพราะ `T.Coral` ไม่มีใน Theme → เปลี่ยนเป็นสีส้ม (Accent)
- Figma: Aquarium ลบปุ่ม X บนการ์ดปลา + เพิ่มจอ "แตะปลา → Modal Return to Bag" + ปุ่ม Expand ขนาดตามเกม; ลบ "Screen C14/C18 · Inventory: put in tank + hot fish" และ "07 · Auras"; Enhance popup ลบแถว Materials (ยังไม่มีในเกม); 10 Notifications ระบุว่าอยู่บนสุด; Store section เพิ่ม "Loading states (spinner)" (สคริปต์ `docs/figma/aquarium_sync.py`, `loading_spinner.py`, ops 28-31)
- Figma (ตรวจทั้งไฟล์เทียบกับเกม): ลบจอที่เกมแทนที่ไปแล้ว 08 Aura Roll Result, 12 Main Menu (3x3 เก่า), 13 Inventory (เก่า), Reel Slot G1-G5 (เก็บเฟรม Components ไว้), E1 หน้ากาชาเก่า (เก็บ E1b Milestones), C17 Auras with stars; แก้ของค้างจาก C25 ใน 00/03/04/Economy 1 (ไม่มี CAST/DEPTH กลางจอ, Actions มี Depth Stepper, เมนูข้าง 4 ปุ่ม, ป้าย Streak กลางล่าง) — `docs/figma/c25_leftovers.py`
- Figma ที่ยังไม่ได้แก้ (รอคุณตัดสินใจ / งานต่อ):
  - [x] ดีไซน์ที่เกมยังไม่มี → ลบจาก Figma แล้ว (คุณเลือก): แท็บ Materials x3 + การ์ด Material, ปุ่ม Lock ปลา x2, ช่อง "Get More" x3, Boost ใต้เหรียญ + แผ่น countdown rings, การ์ดปลาแบบ economy, Sell All แบบแยกรายการ, popup Enhance MAX, จอ Shop with Enhance (ops 34); ไอคอนกุญแจบนช่อง Modifier ของคันเบ็ดและออร่าที่ยังไม่มี ยังเก็บไว้เพราะเกมมี
  - [ ] อัปเดตให้ตรงเกม: E0 Events (Naga Tide 30 MIN เปิดแล้ว, Daily Login DAILY เปิดแล้ว, ข้อความ Altar "Legendary every 100, Mythic at 300"), 17 Character (ปุ่ม SKILLS + สเตตัส 5 แถว), 18 Inventory (ปุ่ม AURA DEX), Economy 1 (ชิป Star Tokens, อัตรา Pearls เป็น /s), Economy 2 Put in Tank (แถบบน "< Tank" + CONFIRM(N), MAX/CLR ต่อการ์ด, ไม่มี Quantity modal), ข้อความโน้ต G6 / In-Game Workspace ที่ล้าสมัย
  - [ ] จอที่ยังไม่มีดีไซน์: Daily Login ปฏิทิน, Skills, Settings/Credits, Tide Event HUD
- ทดสอบ (คุณ):
  - [ ] 1. Ctrl+S → Play → Main Menu → Store: เห็นการ์ด Passes 4 ใบ, ไม่มีฉากดำด้านหลัง; สลับแท็บ Gems/Boosts/Packs มีรายการครบ; ปุ่มราคาอาจหมุนแวบหนึ่งก่อนขึ้นราคา
  - [ ] 2. ถ้า Store ยังว่าง: ดู Output หาบรรทัด `[Store] ... tab failed:` แล้วส่งมา
  - [ ] 3. เปิด Store หรือหน้าต่างใดก็ได้ แล้วกด SELL ALL / ทำอะไรที่มีแจ้งเตือน: ข้อความแจ้งเตือนอยู่เหนือหน้าต่าง ไม่โดนบัง
  - [ ] 4. กระเป๋า → คันเบ็ดที่มี → ENHANCE: ขึ้น popup Enhance (รูป, +N > +N+1, สเตตัสก่อน/หลัง, ราคา); Cancel = ไม่เสียเงิน; กดปุ่มราคา = อัปเลเวล
  - [ ] 5. Aquarium → แตะปลาในบ่อ: Modal "Return to Bag" ปุ่มเป็นสีส้ม
  - [ ] 6. รูปที่โหลดช้า (เช่นเปิด Fishdex ครั้งแรก): เห็นวงหมุนเทาบนช่องรูประหว่างโหลด

### C28. Window core + "!" บนหัว — 2026-11-20  `โค้ดเสร็จ รอทดสอบ`
- `UI/Window.luau` มี `Window.Shell` = แกนกลางของหน้าต่างที่สร้างด้วยโค้ด: ScreenGui ใน PlayerGui เท่านั้น, กรอบ + หัวข้อ + ปุ่ม X มาตรฐาน, ย่อขยายตามจอ, เปิด/ปิด/ลงทะเบียน MenuManager, `SetLoading` (วงหมุน) — วิธีใช้ใน `docs/MENU_MANAGER.md`
- ย้ายมาใช้แล้ว: Store, Aquarium, Mastery, Quests, Credits, Enhance popup, `Window.Create` (Put in Tank, Skills); Aquarium/Mastery/Store มีวงหมุนจนกว่าข้อมูลเซฟมา
- เปลี่ยนหน้าตาเล็กน้อย: Credits ใช้ปุ่ม X มุมขวาบนแทนปุ่ม Close ด้านล่าง; Put in Tank/Skills ใช้หัวข้อ + ปุ่ม X ขนาดมาตรฐาน (หัวข้อย่อยเลื่อนลงนิดหน่อย); Quests ชื่อ ScreenGui เป็น "Quests"
- ปลากินเบ็ด: "!" (รูป bite_alert + วงสีตามความหายาก) เด้งขึ้นเหนือหัวตัวละคร ไม่อยู่ในแถบกลางล่างแล้ว; Figma 02 HUD States อัปเดตโน้ต
- ทดสอบ (คุณ):
  - [ ] 1. Ctrl+S → Play → ตกปลาจนขึ้น "!": เห็น "!" เด้งเหนือหัว (มีวงสีตามความหายาก) ไม่มีแถบ "!" กลางล่าง; คลิกแล้วหายไปเข้ามินิเกม
  - [ ] 2. เปิด Store / Aquarium / Mastery / Quests / Settings (Credits) ทีละอัน: หน้าต่างขึ้นถูก, ปุ่ม X ปิดได้, เปิดอันใหม่แล้วอันเก่าปิดเอง
  - [ ] 3. Aquarium → + → Put in Tank ซ้อนบนบ่อ ปิดแล้วกลับบ่อ; Character → SKILLS เปิดได้
  - [ ] 4. กระเป๋า → คันเบ็ด → ENHANCE: popup ขึ้นเหนือการ์ด, Cancel ปิดได้

## เว็บ QA (`qa/`)

**สถานะ** ◐ โค้ดเสร็จ ทดสอบ UI โหมดในเครื่องแล้ว รอตั้งค่า Firebase + เปิด GitHub Pages

**Done when** ทีม QA เปิดเว็บบน GitHub Pages, เข้าสู่ระบบด้วย Google, ตรวจงานตามขั้นตอนใน "วิธีตรวจ", กดผ่าน/ไม่ผ่าน, แจ้ง Ticket ได้ และ agent ดึงผลด้วย `node qa/tools/pull.mjs`

**ทดสอบ**

- [ ] 1. ทำตาม `qa/README.md` หัวข้อ "ตั้งค่าครั้งแรก" (Firebase, rules, config.json, Pages)
- [ ] 2. เปิดเว็บ > เข้าสู่ระบบด้วยอีเมลที่อยู่ใน rules > เปิดงานใดก็ได้ > กด "ผ่าน" > รีเฟรชหน้า ผลยังอยู่
- [ ] 3. ลองกด "ไม่ผ่าน" โดยไม่เขียนความเห็น ต้องมีข้อความเตือน
- [ ] 4. แจ้ง Ticket หนึ่งอัน > `node qa/tools/pull.mjs` ต้องเห็น Ticket นั้น
- [ ] 5. `node qa/tools/fix.mjs <ticketId> "แก้แล้ว"` > commit/push > เว็บต้องขึ้น "dev แก้แล้ว รอตรวจซ้ำ"
- [ ] 6. แก้ข้อความ `ทดสอบ` ของงานที่ QA ผ่านแล้วใน TASKS.md > `node qa/tools/build.mjs` > งานนั้นต้องมีป้าย "แก้หลังตรวจ"
- [ ] 7. Publish `qa/firestore.rules` ใหม่ (มี `ideas`) > ล็อกอิน > ไปหน้า "ข้อเสนอ / ไอเดีย" > โพสต์ไอเดีย > โหวต, คอมเมนต์, เปลี่ยนสถานะ, แก้ไข ทุกอย่างต้องขึ้นเวลาในประวัติ > รีเฟรชหน้าแล้วข้อมูลยังอยู่
- [ ] 8. สร้าง service account key ของ agent ตาม `qa/README.md` > `node qa/tools/post.mjs --title "ทดสอบ" --body "ทดสอบโพสต์จาก agent"` > โพสต์ต้องขึ้นในเว็บ และ `node qa/tools/pull.mjs` ต้องเห็นในสรุปไอเดีย
- [x] ทดสอบโหมดในเครื่อง (ไม่มี config): ตาราง 69 งาน, เปิดงานเห็นขั้นตอน, ผ่าน/ไม่ผ่าน, สร้าง/ปิด Ticket, หน้าระบบเกมและประวัติ

## บันทึกการอัปเดต
- 2026-11-22T19:30:00+07:00 — เว็บ QA เพิ่มหน้า "ข้อเสนอ / ไอเดีย" แบบฟอรัม (โพสต์ โหวต คอมเมนต์ เปลี่ยนสถานะ แก้ไข พร้อมเวลาทุกจุด) เก็บใน Firestore `qa/ideas`; agent ดึงสรุปด้วย pull.mjs และโพสต์ด้วย post.mjs
- 2026-11-22T18:30:00+07:00 — เปลี่ยน Web Dashboard เป็นเว็บ QA (`qa/`): deploy GitHub Pages, ทีม QA ตรวจงาน/แจ้ง Ticket เก็บใน Firebase Firestore, agent อัปเดตผ่าน `node qa/tools/build.mjs`; ลบ `dashboard/` ออกแล้ว
- 2026-11-22T17:30:00+07:00 — Dashboard: แยกหน้า "สถานะงาน" เป็น 2 หน้า ระบบเกม (#systems) และ QA (#qa) เอาปุ่ม Collapse ออก
- 2026-11-22T17:00:00+07:00 — Dashboard: Dark theme โทน GitHub, badge สีทึบมีขอบให้ตัดกับพื้นแถว, ปุ่มแก้ไข/ลบ/Quick Pass/Review เปลี่ยนเป็นไอคอน
- 2026-11-22T16:15:00+07:00 — อัปเดตข้อมูล QA ลง Google Sheet ครบ 69 รายการจริง และแยกคอลัมน์ ID (A1, B0...), Section (หมวด A, B, C) และ Task Name ออกจากกันในตาราง QA พร้อมตัวกรองหมวดงาน
- 2026-11-22T16:05:00+07:00 — ปรับปรุง Web Dashboard: เปลี่ยนธีมเป็น Medical Palette, แยกฟอร์มแก้ไขค่า (Edit Modal), เพิ่มระบบตรวจงานและบันทึกเวลา QA พร้อมซิงก์ Google Sheets Web App และเพิ่มปุ่ม Collapse / Expand พับเก็บแผงระบบเกมและ QA Tracker ได้อิสระ
- 2026-11-22T14:02:33+07:00 — Web Dashboard ใช้สี Cozy Lake และ UI ไทย–อังกฤษ เพิ่มเมนูกลุ่ม Tuning หน้าสถานะงาน และประวัติการพัฒนาจาก TASKS.md และ report
- 2026-11-22T02:39:31+07:00 — ปรับ Web Balance Dashboard ให้ใช้ตารางตามชีต แยกสคริปต์ตามระบบ และทดสอบการเชื่อม Sheets แบบจำลอง
- 2026-11-21 — Game Design Math: `docs/economy/game_design_math/AuraFishing_GameDesignMath.xlsx` (22 ชีต สูตรสดครบ: Constants, Rarities, Fish, Fish Odds, Mutations, Sell Value, Progression, Items, Enhance, Mastery, Skills, Rebirth, Stats Calculator, Fishing Loop, Reel Minigame, Aquarium, Auras, Gacha, Monetization, Economy Totals, Live Content) พร้อม CSV ค่าล้วนใน `csv/` สร้างจาก Config จริงด้วย `node tools/balance_sheet/build.mjs` (ต้องมี luau + python) สูตรตรวจกับโค้ดเกม 122 จุดผ่านหมด (Roll.Value, AuraRates, Mastery, Enhance, Stats.Compute, XP, Rebirth, ความน่าจะเป็นปลา) ยังไม่ได้เปิดใน Google Sheets จริง
- 2026-11-21 — Aura Reveal: วง Eclipse rim และ Shockwave ใช้ภาพวงที่ export จาก Figma `3717:1434` (เส้น 5px + แสงเรือง, `auras/fx_ring`, ภาพขาว tint ตามสีระดับ rarity) แทน UIStroke เส้นขอบขยายตามวงเหมือน Figma หน้า reveal แสดงเฉพาะ Item Card Detail + ข้อความ Tap to close (ซ่อนแถบล่าง) ผ่าน `node tools/check.mjs` ดูวงใน Play แล้ว ยังไม่ได้ดูครบทั้งแอนิเมชันและสี Mythic
- 2026-11-21 — บูสต์ที่ทำงานอยู่เป็นชิปสีส้มเล็ก (ไอคอน + เวลา เช่น 31:34) วางข้างลูกศรของลิ้นชักสกุลเงิน ไม่ซ่อนในลิ้นชักแล้ว ตามแบบ Boost ใน Figma `3766:5984` ผ่าน `node tools/check.mjs` ดูใน Play แล้ว
- 2026-11-21 — HUD สกุลเงินแบบ Core + drawer (Figma `Currency HUD Options` 3766:5875 แบบ 3): Coins กับ Gems แสดงตลอด ปุ่มลูกศรเปิดลิ้นชักที่มี Pearls, Star Tokens และบูสต์ที่ทำงานอยู่ ปิดเองใน 6 วินาที มีจุดสีบนลูกศรเมื่อมีบูสต์ (`HUDController` + `EconomyController` ย้ายชิป Pearls เข้าลิ้นชัก) ผ่าน `node tools/check.mjs` เปิดดูใน Play แล้วทั้งปิดและเปิด ยังไม่ได้ทดสอบกดลูกศรจริง
- ทดสอบใน Play: กดลูกศรข้าง Gems ดูลิ้นชักเปิดและปิดเองหลัง 6 วินาที, แตะ Pearls ในลิ้นชักควรเปิด Aquarium, ซื้อบูสต์แล้วดูจุดบนลูกศร
- 2026-11-21 — HUD ปุ่มวงกลมเป็นแผ่นดำโปร่ง (fill 25%, ขอบ 5px 10%) ตาม Figma `3760:5656`: Sell All เป็นไอคอน `ui/status/sell_bag` ซ้ายล่างของ CAST (PC อยู่ซ้าย Depth), CAST สลับภาพตามสถานะ (`hook_cast` / `reel_in` / `hook_catch` ตัดจาก `assets/ui/Reel In and Hook Fishing Icons.png`, อัปโหลดผ่าน Studio) REELING กับ AUTO ยังเป็นข้อความ Figma: ตั้งชื่อปุ่ม Btn Cast/Sell/Depth/Auto และคัดลอก dock + Tide ไป 01 HUD, 04 Catch Result, Economy HUD ผ่าน `node tools/check.mjs` ผู้ใช้รายงานเหวี่ยงเบ็ดไม่ได้ ยังหาสาเหตุไม่เจอ (server รับ Cast ได้, ปุ่มรับ input, HUD เปลี่ยนสถานะ) ต้องดูอาการจริงบนมือถือ
- 2026-11-21 — ปุ่ม CAST มือถือเป็นวงกลมพร้อมภาพ hook charm จาก Figma `3760:5762` (อัปโหลดผ่าน Studio ได้ `ui/icons/hook_cast` = `rbxassetid://111371126675038`, ลง `assets/catalog.json` และ `UIAssets.luau`) สถานะอื่น (REEL IN, HOOK!, REELING, AUTO) ยังแสดงข้อความ ดูใน Play แล้วภาพโหลดและเป็นวงกลม ยังไม่ได้ทดสอบกดเหวี่ยงจริงบนมือถือ
- 2026-11-21 — HUD แบบเกมมือถือตาม Figma `3760:5656`: Bag + Sell All ซ้อนมุมขวา, ปุ่ม Depth (ทุ่น, ไม่มีเลข) และ Auto (`ui/icons/auto_pro`, สีเขียวเมื่อเปิด) เป็นวงกลม 88 ข้างปุ่ม Jump, CAST ย้ายไป 172/78 จากมุม dock ใช้ scale เดียวกับคลัสเตอร์อื่น แก้โมดัล Starter Pack ใหญ่เกินบนมือถือ (UIScale ที่ bake ไว้ไม่มี listener จึงเรียก `New.FitWindow` ตอนรัน, Depth popup ทำเหมือนกัน) ผ่าน `node tools/check.mjs` ดูใน Play: dock ตอนอยู่บนบกและโมดัลพอดีจอ ยังไม่ได้ดูตอนอยู่ใกล้น้ำ (Auto + CAST) และไม่ได้ใช้ภาพ hook ของปุ่ม CAST เพราะยังไม่มี asset id
- 2026-11-21 — Depth บน HUD เปลี่ยนเป็นปุ่มไอคอนทุ่น (`ui/status/bobber`) + ค่าความลึก กดแล้วเปิด Depth popup (`UI/CastPopup.luau`, builder `UI/Screens/CastPopup.luau`) มีเลขใหญ่, ป้ายโซน, สไลเดอร์สีตามโซน, preset Shallow/Mid/Max และจำนวนสายพันธุ์ ไม่มีสวิตช์ Auto depth และปุ่ม CAST เพราะเหวี่ยงด้วยการกดค้างในโลก (C25) ปรับ dock HUD เป็น 336 กว้าง ปุ่ม Auto/Sell มี padding 12 และยก dock บนมือถือเหนือ CAST เพิ่มการ์ด Tide และ dock ใหม่ใน Figma HUD (`3492:16667`) ผ่าน `node tools/check.mjs` เปิด popup ใน Play ได้ ยังไม่ได้ทดสอบกด preset และลากสไลเดอร์ และยังไม่ได้ bake (สร้างตอนรันพร้อมคำเตือน) รัน `node tools/ui/bake.mjs CastPopup`
- ทดสอบใน Play: กดปุ่ม Depth เปิด popup, กด Shallow/Mid/Max ดูค่าบน HUD เปลี่ยน, ลากสไลเดอร์, กดนอก popup หรือ X เพื่อปิด, เหวี่ยงเบ็ดแล้วตรวจว่าใช้ความลึกใหม่
- 2026-11-21 — Starter Pack: แตะแถวของรางวัลเพื่อเปิด Item Detail (Bait, Rod) ส่วน Gems แตะเพื่อสลับคำอธิบายบรรทัดเดียว ลด DisplayOrder ของโมดัลเป็น 25 ให้การ์ดอยู่ด้านบน เพิ่มชีต `19_shop_packs_2` (9 แพ็ก) ใน `tools/art/sheets.json` และสร้าง prompt ใหม่ใน `docs/ART_PROMPTS.md` ผ่าน `node tools/check.mjs` ยังไม่ได้ทดสอบใน Play
- ทดสอบใน Play: เปิด Starter Pack จากร้าน แตะ Shrimp และ Sweetheart Rod ดูการ์ดอยู่เหนือโมดัล แตะ Gems ดูข้อความสลับ
- 2026-11-21 — บันทึกกติกา UI native ใน `AGENTS.md` ห้ามเพิ่มฉากดำหรือฉากมืดหลังเมนูและโมดัลจนกว่าจะมีคำสั่งเปลี่ยน C14 ใช้พื้นที่รับอินพุตโปร่งใสแทน
- 2026-11-21 — Gacha มือถือแนวนอนจัดปุ่มในพื้นที่ปลอดภัยของ Roblox, HUD แสดง 2x Coins / 2x Pearls พร้อมนับถอยหลัง, C14 Quantity ใช้จาก Aquarium และ Inventory TANK, Daily Quests ใช้ไอคอน Gems ทั้งยอดและรางวัล เอาฉากดำออก และรวม Milestone เป็นการ์ดเดียวที่นับเควสต์ที่เคลม ผ่านการทดสอบ Studio Bridge และ `node tools/check.mjs`
- ทดสอบใน Play: เปิด Aura Altar ใน Device Emulator แนวนอนแล้วดู Back และ ROLL x1/x10, เปิดบ่อแล้วแตะกองปลา >1 และลอง Cancel / Half / MAX, เปิด Daily Quests แล้วเคลมเควสต์เพื่อดูแผง Milestone เปลี่ยนสถานะ
- 2026-11-21 — แยกป้าย Hot Fish ขึ้นเหนือชื่อ Fish Merchant 12 px กันคลิกทะลุระหว่างเปิดหรือกดปิดเมนู และปิด Fish Result ทันทีเมื่อเริ่มเหวี่ยงเบ็ดรอบใหม่ ทดสอบทั้งสามกรณีผ่าน Studio Bridge
- 2026-11-21 — ใช้ Eclipse จาก Figma ใน Aura Reveal, bake AuraReel และตรวจ Legendary / Mythic ใน Studio Play ด้วยโปรไฟล์จำลอง จังหวะพื้นดำ Sparkle สี rarity และ Item Card ตรง flow ทดสอบต่อด้วย ROLL x10 แล้วกด SEE ALL 10 เพื่อดูผลครบเมื่อโปรไฟล์โหลดตามปกติ
- 2026-11-21 — รวมหน้าต่างที่ออกแบบไว้ใน [Designed Game Menus](https://www.figma.com/design/givb0hmQYmmaOy7p7DGtb2/Ro-Offline?node-id=3752-5142) และผูก CoreGui Guide ทั้ง 36 จุดกับ [component set สองขนาด](https://www.figma.com/design/givb0hmQYmmaOy7p7DGtb2/Ro-Offline?node-id=3752-5168)
- 2026-11-21 — เปลี่ยนฉากของ [บอร์ด Aura Reveal Motion](https://www.figma.com/design/givb0hmQYmmaOy7p7DGtb2/Ro-Offline?node-id=3717-1180) ทั้ง 8 เฟรมเป็นพื้นดำ fade in จากโปร่งใสที่ 0.36 วินาที
- 2026-11-21 — แก้ [บอร์ด Aura Reveal Motion](https://www.figma.com/design/givb0hmQYmmaOy7p7DGtb2/Ro-Offline?node-id=3717-1180) ทั้ง 8 เฟรมให้ใช้ Sparkle และ rarity Overlay จาก Option 5 เอา shape ดาวและภาพ Aura Art ออก เปลี่ยนแบบที่ 4 เป็น Afterglow Pulse
- 2026-11-21 — เพิ่ม [บอร์ด Aura Reveal Motion](https://www.figma.com/design/givb0hmQYmmaOy7p7DGtb2/Ro-Offline?node-id=3717-1180) เทียบ Halo Burst, Eclipse, Ten Sparks และ Hero Silhouette ทั้ง Legendary/Mythic และเพิ่มแท็บ Workbench กับ Agent Handoff ในปลั๊กอิน Figma local
- 2026-11-21 — MCP local เปลี่ยนไปใช้ตัวเปิด stdio ที่สลับ server worker หลัง TypeScript rebuild ผ่าน รอคำสั่งที่กำลังทำงานและแจ้ง client ให้โหลดรายการเครื่องมือใหม่
- 2026-11-21 — Figma Option 5: ทำ [Aura Reveal Motion](https://www.figma.com/design/givb0hmQYmmaOy7p7DGtb2/Ro-Offline?node-id=3713-622) สำหรับ Solar Flare (Epic) ที่ 3.2 วินาที ตรวจจาก MP4 ที่ Figma export แล้ว เพิ่มคำสั่ง Motion และ watch mode ใน MCP local ทดสอบโดยเพิ่มคำสั่งชั่วคราวแล้วเรียกได้ผ่าน relay เดิม
- 2026-11-20 — มุมโค้งไม่ mask: `ClipsDescendants` ตัดแค่สี่เหลี่ยม ไม่ตามมุมโค้ง → เปลี่ยนเป็น CanvasGroup (`New.Panel({ Clip = true })`, `Window.Shell({ Clip = true })`): แถบพลังเหวี่ยงเบ็ด (HUD, bake แล้ว), popup Pearl ตอนเข้าเกม (Offline reward), Enhance popup, Quests, Starter Pack (bake แล้ว), กรอบรูปการ์ด Events (bake แล้ว); กฎใน `docs/UI_STYLE.md`. ทดสอบ: Ctrl+S → Play → กดค้างเหวี่ยง: สีส้มในหลอดโค้งตามหลอดทั้งบนล่าง; เข้าเกมใหม่ (มี Pearl ออฟไลน์): แถบล่างสีทรายโค้งตามมุมหน้าต่าง; Enhance / Starter Pack / Events ก็เช่นกัน
- 2026-11-20 — ปรับ pop: เปลี่ยนจาก Elastic (เด้งหลายทีเหมือนค้าง) เป็น Back Out 0.25 วิ เริ่มที่ 70% = ป๊อปทีเดียวจบ (`New.luau` POP_INFO / POP_FROM)
- 2026-11-20 — Transition elastic pop ทุกอย่างที่แสดง: `New.Pop` (ขยาย 0.5 → 1 แบบเด้ง 0.55 วิ); หน้าต่าง/ป๊อปอัปที่ใช้ FitToScreen/FitWindow/Window.Shell เด้งเองเมื่อเปิด (Store, Aquarium, Mastery, Quests, Credits, Enhance, Inventory, Character, Events, Main Menu, Shop/Fishdex/Aura Index, Modal, Starter Pack, Dialogue, Minigame, Offline reward); เรียกเองที่ Gacha, Daily Login, Item Card, การ์ดปลา, toast แจ้งเตือน; กฎใน `docs/UI_STYLE.md`. ทดสอบ: Ctrl+S → Play → เปิดหน้าต่าง/ป๊อปอัปต่าง ๆ ทุกอันเด้งตอนโผล่ ไม่ค้างขนาดผิด และย่อขยายตามจอยังถูกหลังเด้งจบ (ลองย่อหน้าต่าง Studio)
- 2026-11-20 — Pager อยู่มุมซ้ายล่างทุกหน้าต่าง: Fishdex เดิมอยู่กลาง → ย้ายซ้าย (เกม `Screens/Menus.luau` bake แล้ว + Figma 09 Fishdex); Shop และ Aura Index อยู่ซ้ายอยู่แล้ว; กฎเขียนไว้ใน `docs/UI_STYLE.md`. ทดสอบ: Ctrl+S → Play → Fishdex: ปุ่ม < 1 / N > อยู่มุมซ้ายล่างตรงกับ Shop
- 2026-11-20 — C28: `Window.Shell` แกนกลางหน้าต่าง (Store, Aquarium, Mastery, Quests, Credits, Enhance, Window.Create), "!" ปลากินเบ็ดบนหัวตัวละคร; check ผ่าน, ทดสอบเปิด/ปิดทุกหน้าต่างในโหมดแก้ไขแล้ว, ยังไม่ได้ทดสอบใน Play
- 2026-11-20 — Figma: ลบดีไซน์ที่เกมยังไม่มี (Materials, Lock ปลา, Get More, Boost rings, การ์ดปลา economy, Sell All แยกรายการ, Enhance MAX, Shop with Enhance) ตามที่คุณเลือก
- 2026-11-20 — C27: แก้ Store ว่าง (ลบ StarterGui.Store/QuestsGui ที่ค้าง + สร้างใน PlayerGui เท่านั้น + pcall ต่อแท็บ), เอาฉากดำ Store ออก, `New.Spinner` (Store/ปุ่มราคา/รูปกำลังโหลด), แจ้งเตือน DisplayOrder 100, Enhance popup ใหม่, แก้สีปุ่ม Return to Bag; Figma ปรับให้ตรงเกม (Aquarium, ลบ C14/C18 Inventory + 07 Auras + จอเก่า 08/12/13/Reel Slot G1-G5/E1/C17, ของค้าง C25 ใน 00/03/04/Economy 1, Enhance, Notifications, Loading states); check ผ่าน, ทดสอบ render Store/Enhance ในโหมดแก้ไขแล้ว, ยังไม่ได้ทดสอบใน Play
- 2026-11-20 — C26 ป้าย HOTSPOT บนการ์ดปลา: Figma 04 · Catch Result เพิ่มป้ายทองต่อจาก PERFECT (`docs/figma/hotspot.py` part 2); แก้บั๊กในเกม: prefab CatchCard มีช่องป้ายแค่ 3 ช่อง ป้ายที่ 4 ไม่ขึ้น → เพิ่มเป็น 4 ช่อง, bake Components แล้ว
- 2026-11-20 — C26 จุดฟองปลา Hotspot: `HotspotService` (วงทองฟองใกล้ผู้เล่นริมน้ำ, Luck +50% เมื่อเหวี่ยงเองลงวง, ใช้ได้ 2 ครั้ง), วงเล็งทอง + ป้าย, ป้ายบนการ์ดปลา; Figma อัปเดต (`docs/figma/hotspot.py`); check ผ่าน, ทดสอบใน Studio แล้วว่า Config โหลดได้และสุ่มจุดในน้ำของ StarterBay ได้, ยังไม่ได้ทดสอบใน Play
- 2026-11-20 — C25 เหวี่ยงเบ็ดใหม่: กดค้างเล็งด้วยกล้อง + แถบพลัง + Perfect Cast + stat CastRange, ตัวปรับความลึกบน HUD แทน Cast Popup (ลบแล้ว), ปุ่ม CAST มือถือ, Auto ใช้ทิศกล้องและหยุดเมื่อเดินออก; Figma 01 · HUD อัปเดต (`docs/figma/cast_rework.py`); bake HUD แล้ว, check ผ่าน, ยังไม่ได้ทดสอบใน Play
- 2026-11-20 — Aquarium การ์ดล็อก: ปุ่ม Expand ตัดคำ "EXPAND" ออก เหลือแค่เหรียญ + ราคา (ใหญ่ขึ้น อยู่กลางปุ่ม) ใน `AquariumScreen.createLocked` (สร้างด้วยโค้ด ไม่ต้อง bake) ทดสอบ: Play → เปิด Aquarium → เลื่อนไปการ์ดล็อก ปุ่มทองมีแค่ราคา กดแล้วยังขยายได้ เงินไม่พอปุ่มเป็นสีเทา
- 2026-11-20 — B22 Drop rates: รายการโดนตัดขอบ (กรอบทองของออร่า featured + scrollbar ทับขอบขวา) → เพิ่ม UIPadding ใน `RatesPopup.Panel.List` (บน/ล่าง/ซ้าย 4, ขวา 12), bake GachaPage แล้ว รอ Ctrl+S + ทดสอบ: กาชา → Rates → เลื่อนดู แถวทองไม่โดนตัด ขอบขวาไม่ชน scrollbar
- 2026-11-20 — C24 M2-M4: Put in Tank ซ้อนบน Aquarium (StackOn), ปุ่ม gamepad B = `MenuManager.CloseTop()` (`BindBackKey` ใน Main.client; Esc ปิดกล่องคุย NPC ย้ายมาที่เดียวกัน), ลบการปิดหน้าต่างด้วยมือ 6 จุด + `ctx.closeHub` ของ Events; check ผ่าน รอทดสอบใน Play
- 2026-11-19 — C24 Core Menu Manager: `UI/MenuManager.luau` (ชั้น Hub/Main/Dialogue/Popup/Modal + StackOn), ต่อเข้าทุกหน้าต่าง, คู่มือ + งานส่งต่อ `docs/MENU_MANAGER.md`; แก้ Remotes.luau IsEdit ที่ทำให้ client โหลดไม่ขึ้น
- 2026-11-19 — docs/AGENT_PROMPTS.md: prompt แบบเคร่งครัดสำหรับ Codex / Antigravity / agent อื่น + แม่แบบข้อความสั่งงาน
- 2026-11-19 — คู่มือสำหรับ Agent อื่น (Codex / Antigravity): docs/AGENT_PLAYBOOK.md (วิธีอ่านคำสั่ง, ลำดับความสำคัญ, ขั้นตอนทำงาน, เครื่องมือ, ข้อผิดพลาดที่เคยเจอ) + docs/AGENT_RUNBOOKS.md (ขั้นตอนทีละงาน: Part A โค้ด 11 แบบ, Part B ออกแบบ Figma D1-D7); ลิงก์จาก AGENTS.md
- 2026-11-19 — B7 NPC Dialogue: Old Marlin (ร้าน) + Sela (แท่นออร่า) ตาม Figma 11, Config/Dialogues, prompt เปลี่ยนเป็น Talk; ทดสอบใน Play ผ่าน (ดู B7)
- 2026-11-19 — C22: FishingZone / PlayArea ใช้เฉพาะของใน Workspace (แมพสำรองใน ServerStorage ไม่มีผลอีกต่อไป)

- 2026-11-19 — เลือก Gem Tracker (แบบ 06) ใน Figma ลบแบบอื่น เพิ่ม Chance จาก Config, ป้าย 3 / 5, ปุ่มเปลี่ยนหน้า และ Prototype เปิด Item Card เดิมเฉพาะ Aura ที่ปลดล็อกแล้ว
- 2026-11-19 — นำ Aura Index (Gem Tracker Figma 3611:54189) เข้าเกม: แบนเนอร์ความคืบหน้า Gems earned, กริดการ์ด 6 ช่อง (2x3), การ์ดปลดล็อกแสดง State/Chance/Gems Awarded, การ์ดล็อกแสดง ???/First find/แม่กุญแจ, ปุ่ม Go to Altar, bake ใน StarterGui.Menus แล้ว

- 2026-11-18 — Aura Index: ทำ Figma แบบกริด 6 แบบ พร้อมตัวอย่างปลดล็อกและรับ Gems เมื่อเจอครั้งแรก รอเลือกแบบและยืนยันจำนวนรางวัล
- 2026-11-18 — C21 คอนเทนต์ใหม่จากรูปที่อัปโหลดแล้ว: ปลา 8, ออร่า 10, คันเบ็ด 2, สาย 2, เหยื่อ 4; Starter Bay ลึก 1000m (ดู C21)
- 2026-11-18 — งานเล็ก: แก้ HUD ซ้อนตอนตัวละครโหลดช้า (`Baked.Get` รอ 60 วิ + ลบตัวซ้ำ), bake CastPopup ใหม่, Main Menu 13 ไทล์ + ป้าย VIP (Figma Economy 7), ชิปกระเป๋า HUD แสดง Inf
- 2026-11-18 — UI ค้างของ Economy: ป้าย Streak (C12), ป้ายชื่อ VIP (C6), +N (C16), HOT + ป้าย Merchant + Hot bonus (C18), หน้าต่าง Skills (C4), กาชา pity 2 แถว/อัตรา %/Star Token (C17), ดาวใน Aura Dex; อัปเดตสถานะภาพรวม C4–C19 ให้ตรงของจริง
- 2026-11-18 — B21 รอบ 2: การ์ดไอเท็มใน Shop + Fishdex, ไอคอนราคาในปุ่มการ์ด, หน้าต่าง Character (C / รูปโปรไฟล์ Main Menu), Aura Dex (ปุ่มในแท็บ Auras), Shop Bags ไม่ให้กลับไปกระเป๋าเล็ก, `UI/ItemSlots.luau`. bake Inventory/ItemDetail/Character แล้ว ทดสอบใน Play ผ่าน (ดู B21)
- 2026-11-18 — B21 ในเกม: Inventory v2 (แท็บคั่นหนังสือ, 600x480, ช่อง 72) + Item Card (`UI/ItemDetail`, ใช้ remote เดิมทั้งหมด ไม่เพิ่ม field เซฟ) + Bag Upgrade (ladder, ขั้นสุดท้าย = Infinite Bag pass) + server กันกระเป๋าเล็กลง; แท็บ Auras แสดงเฉพาะที่มี (ตามที่คุณขอ). check ผ่าน รอ bake + ทดสอบ (ดู B21)
- 2026-11-18 — B20 Virtual Grid: `UI/VirtualGrid.luau` (แนวคิด Global Visualizer: สร้างเฉพาะช่องที่มองเห็น + pool/rebind) ใช้กับ Inventory, Aquarium, Mastery, Put in Tank แทนการลบ/สร้างการ์ดใหม่ทุก refresh. ทดสอบ edit mode: 500 ชิ้น = 30 view. รอทดสอบใน Play (ดู B20)
- 2026-11-18 — A18 เฟส 1: compact reads (`depth`/`fields`/`maxNodes` ใน get_node_info / get_nodes_info / read_my_design, เล็กลง ~10 เท่า), tool ใหม่ `find_nodes`, batch อ้างผล `"$N.path"` + `brief`, `figma.commitUndo()` ต่อคำสั่ง (batch = undo 1 ครั้ง), error แนะนำชื่อคำสั่ง/วิธีหา id, ตัวนับเก็บ avgKB. ทดสอบ: ดูข้อ 6-7 ใน A18
- 2026-11-18 — A18 รอบ 3: แผง **Selection** ในปลั๊กอิน (ชื่อ / ชนิด / id / path, ปุ่ม Copy id, Copy all, คลิกชื่อ = ซูมไป) + **โน้ตต่อโหนด** (พิมพ์ในแผงหรือ Agent ใช้ `set_node_note`) — `get_selection` คืน path, size, text, image, note ด้วย; Agent ใช้ชื่อ + โน้ต ไม่ต้องวิเคราะห์รูป. ทดสอบ: เปิดปลั๊กอินใหม่ → คลิก layer ใน Figma → แผงขึ้นชื่อ+id ทันที → พิมพ์โน้ต กด Enter → บอก Claude "get_selection" ต้องเห็นโน้ตนั้น
- 2026-11-18 — A18 รอบ 2 (ความเร็ว): log ของ relay/MCP เหลือบรรทัดเดียว (เดิมพิมพ์ JSON เต็มรวม base64 หลาย MB), ตัดการรอคงที่ (scan_text_nodes เดิมแฟลชสีส้ม + รอ 0.1-0.5 วิ/โหนด), export_to_roblox ดึงรูปพร้อมกัน 4 รูป, MCP join ห้องเองหลัง relay รีสตาร์ท, แก้บั๊กผลลัพธ์ 0/false ค้าง 30 วิ, เพิ่ม `batch_commands` (หลายคำสั่งในรอบเดียว) + `list_plugin_commands`. พบว่า relay ที่รันอยู่เป็นของ upstream (`bunx`) ไม่ใช่ของ fork
- 2026-11-18 — A18: Figma plugin แยกเป็นโมดูล (`src/cursor_mcp_plugin/src/core` + `commands/*` 13 กลุ่ม, UI `ui/`), build ด้วย `build.mjs` (esbuild) → `code.js`/`ui.html`; คำสั่งครบ 51 ตัวเท่าเดิม + `list_commands`; ตัวนับการใช้งานเป็นตัวเลข (relay + MCP server → `usage/*.json`, tool `get_usage_stats`, `bun run usage`), สคริปต์ Python ส่งชื่อ `py:<script>`; เอกสาร HANDOFF.md / AGENTS.md rules / README plugin. รอทดสอบใน Figma
- 2026-11-17 — เขียน handoff ให้ agent ถัดไป (Antigravity): `docs/HANDOFF_ANTIGRAVITY.md` + `AGENTS.md` ที่ root; ลิงก์ไว้ใน `CLAUDE.md`
- 2026-11-17 — Aquarium ทำตาม Figma (กติกาใหม่: แก้ Figma ก่อนเสมอ): Figma "Economy · 2" อัตราทุกจุดเป็น **/s** (64 ข้อความ), ตัวเลข Pearls มีทศนิยม, เพิ่มปุ่ม **MASTERY ›** ในแถวหัว → เกม: `UI/AquariumScreen.luau` (760×610, การ์ด 162×176 น้ำ+ฟอง+รูปปลา+มุมระดับ+mutation+ชื่อ+อัตรา /s+ปุ่ม ×, Add fish, Expand 2 ช่องพร้อมราคา k/M, footer + coins), Put in Tank กับ Mastery แยกเป็นหน้าต่างของตัวเอง, ตัวเลข Pearls (HUD + หน้าบ่อ) อัปเดตทุกเฟรมทศนิยม 2 ตำแหน่ง, `Aquarium.FormatRate` / `FormatPearls`; ภาพ: `docs/figma/economy_aquarium_window.png` (Figma) vs `docs/figma/economy_aquarium_ingame.jpg` (เกม). ทดสอบ: เปิดบ่อ → เลข Pearls ขึ้นทุกวินาที (2,920.63 → .74 → .85 ที่ +0.11/s)
- 2026-11-17 — รูปชีต 10–16 (63 รูป) อัปโหลดแล้ว (คุณรัน) → `resolve_decals.mjs` ได้ image id 63/63 → `UIAssets.luau` ครบ 164/164; Figma: `figma_images.py` เติมรูปลงช่อง `Img ...` 475 ช่อง (Economy 0–7, Character, Art Library, Components); ในเกมรูป pearl / boost / starter pack / vip ขึ้นแล้ว
- 2026-11-17 — Put in Tank ใหม่ (ตามที่คุณขอ): การ์ด 4:3 เลือกได้หลายตัว (แตะการ์ด = +1, ปุ่ม MAX/CLEAR, ป้าย xN, แถบสีระดับปลา) + แถบบน "n selected • free slots" + CONFIRM (n) ส่งครั้งเดียว; แก้ขอบโดนตัดในหน้าต่างโค้ด (`Window.Clear` ล้าง layout เก่าที่ค้างตอนสลับแท็บ + เว้นขอบด้านในให้เส้นขอบ/ติ๊ก/ป้ายไม่โดนตัด); เพิ่มรูปชีต 10–16 (63 รูป) เข้า `assets/catalog.json` พร้อมอัปโหลด (`--dry-run` ผ่าน) — ยังไม่ได้อัปโหลด. Claude ทดสอบในเกม (ภาพจริง): เลือก Guppy 1 + Moon Jelly 2 → CONFIRM (3) → บ่อ 3/4, 9.4/นาที
- 2026-11-17 — หน้าจอ Economy ในเกม (สร้างด้วยโค้ด, placeholder ก่อนมี Figma): `UI/Window.luau` (ชุดสร้างหน้าต่าง + แถว) + `Controllers/EconomyController.luau` — ชิป **Pearls** บน HUD ต่อจาก Coins/Gems (ตัวเลขวิ่งขึ้นเอง, กด = บ่อปลา); **กดชิป Gems = ร้านแท็บ Gems, กดชิป Coins = ร้านแท็บ Boosts & Packs** (ไม่มีปุ่ม Store แยก ตามที่คุณขอ); หน้าต่าง **Aquarium** แท็บ Tank (ปลาในบ่อ + อัตรา/นาที, กดปลา = เอาออก, ช่อง + = เลือกปลาจากกระเป๋า "Add 1 / Add ทั้งหมด", ปุ่ม Unlock ช่องด้วย Coins) และแท็บ Mastery (7 สาย, ผลตอนนี้ -> ถัดไป, ปุ่มราคา Pearls); หน้าต่าง **Store** (Passes / Gems / Boosts & Packs, ราคาจริงจาก Roblox, OWNED / BOUGHT / เวลาที่ boost เหลือ, กดแล้วเปิดหน้าซื้อของ Roblox); popup "Welcome back" ตอนได้ Pearls ออฟไลน์; เปิดหน้าต่างพวกนี้แล้ว Main Menu hub ปิดเอง. Claude ทดสอบในเกม (ภาพจริง): ชิป Pearls ขึ้น, กดแล้วเปิดบ่อ, ใส่ Moon Jelly 2 ตัว → 3/4 ช่อง อัตรา 6.0/นาที, แท็บ Mastery, กดชิป Gems → ร้าน (ราคา 20/75/179), Passes ขึ้น OWNED. ไอคอนใหม่ (pearl, robux, gems_s/m/l, starter_bundle, boost_*, vip ...) ยังเป็นกรอบสี + ตัวอักษร เพราะรูปชีต 10–16 ยังไม่อัปโหลด
  - ทดสอบ:
    - [ ] 1. Play → ชิป Pearls ข้าง Gems ตัวเลขค่อยๆ ขึ้นเมื่อมีปลาในบ่อ
    - [ ] 2. กดชิป Pearls → Aquarium → กดช่อง + → เลือกปลา Add → ปลาเข้าบ่อ, อัตราด้านบนเพิ่ม; กดปลาในบ่อ → กลับเข้ากระเป๋า
    - [ ] 3. ปุ่ม Unlock (มีเงินพอ) → ช่องเพิ่ม 1
    - [ ] 4. แท็บ Mastery → กดอัป → Pearls ลด, เลเวลขึ้น
    - [ ] 5. กดชิป Gems → ร้าน Gems; กดชิป Coins → Boosts & Packs; กดปุ่มราคา → หน้าซื้อของ Roblox ขึ้น (Studio = test purchase)
- 2026-11-17 — แก้ Mystery Fish (skeleton) กระพริบตอนเปิดเมนู: `New.luau` จำรูปที่เคยโหลดแล้ว (ไม่โชว์ skeleton ซ้ำ) + รอ 0.25 วิ ก่อนโชว์ skeleton (รูปที่โหลดเร็วไม่แวบ); Claude ทดสอบ: เปิด Fishdex/Shop/Auras สลับกัน 5 ครั้งหลังรูปโหลดแล้ว → skeleton โผล่ 0 ครั้ง; skeleton ยังขึ้นตามปกติตอนรูปกำลังดาวน์โหลดจริงครั้งแรก
- 2026-11-17 — ช่องไอเท็ม (Inventory): ไอคอน mutation ย้ายจากมุมขวาบน (ทับติ๊ก Selected) ไปมุมซ้ายล่างในช่อง — `Screens/Components.luau` + Figma spec `cozy_menus_spec.py`; bake `Components` + `Inventory` ลง StarterGui แล้ว (ต้อง Save เพลส); ทดสอบ: Inventory → เลือกกองปลาที่มี mutation → เห็นทั้งติ๊กมุมขวาบนและไอคอน mutation มุมซ้ายล่าง
- 2026-11-17 — C5 เปลี่ยนเป็น **Naga Tide** (ตามที่คุณขอ): วงน้ำเรืองแสงสุ่มจุดทุก :00/:30 อยู่ 5 นาที, ตกในวง = Luck +50% + ลุ้น Naga Hatchling / Coral Seahorse, คนตกในวงเยอะ = โอกาสสูงขึ้น; ลบระบบบอสดึงเย่อ; คำสั่ง Dev `event start/stop`
- 2026-11-17 — แมพ: พื้นสะพานสูงจากน้ำแค่ 3 studs (เดิม 9 และในเพลสถูกยกขึ้นไปอีก 49 → ห่างน้ำ ~57) — สร้างใหม่ด้วย `tools/map/boardwalk.luau` (`DECK = 3`), ร้าน/แท่นออร่าย้ายตามครบ; แมพเดิมสำรองไว้ที่ `ServerStorage.Map_Backup_Deck9` (ลบได้เมื่อพอใจ); **ต้อง Save/Publish เพลสใน Studio**
- 2026-11-17 — C10 เครดิต: `Config/Credits`, หน้าต่าง "Settings & Credits" (ปุ่ม Settings ใน Main Menu), `CREDITS.md`; ยังไม่ได้ทดสอบในเกม (Studio หลุด)
- 2026-11-17 — C5 (แบบแรก, ยกเลิกแล้ว) บอส Grand Naga + Co-op Reel เสร็จ: `Config/Boss`, `BossService` (ทุก :00/:30, HP ตามจำนวนผู้เล่น, STRIKE ×5, จำกัด 6 ครั้ง/วิ, ระยะ 90, แบ่งรางวัลตามดาเมจ), `BossController` (แผง HP + ปุ่ม PULL/Space), การ์ด Events เปิดแล้ว, คำสั่ง Dev `boss`; โมเดลจริงรอ art
- 2026-11-17 — C4 สกิล ฝั่ง server เสร็จ: Keen Eye / Quick Hands / Multi-Cast (`Config/Skills`, `Shared/Skills`), แต้มถาวรทุกเลเวลอัป (Rebirth ไม่ล้าง), Multi-Cast = ปลาโบนัส 35% ต่อสายเสริม (`CatchResult.Bonus`), remote `UpgradeSkill`, schema 5, คำสั่ง Dev `skillpoints` / `skill`
- 2026-11-17 — C3 Rebirth + ฉายา เสร็จ: Lv.50 (+10 ต่อครั้ง), ×1.25 ต่อครั้งให้ Sell Mult + Pearl Rate, ฉายา 5 ระดับเหนือหัว (`TitleController`), ปุ่ม Rebirth ใน Main Menu + หน้าต่างยืนยัน, ล้างเลเวล/เงิน/ปลาในกระเป๋า, คำสั่ง Dev `rebirths`
- 2026-11-17 — C18 ปลาขายดีประจำชั่วโมง ฝั่ง server เสร็จ: `Shared/HotFish` (สุ่มจากชั่วโมง UTC = ตรงกันทุกเซิร์ฟ/client), ราคาขายคูณใน `Inventory.SellValue`, `Inventory.HotBonus`, `CatchResult.Hot`, event `HotFish`, คำสั่ง Dev `hotfish`
- 2026-11-17 — C6 + C19 ฝั่ง server เสร็จ: Infinite Bag (999 ช่อง), attribute `Pass_<id>` ให้ทำป้าย VIP, Starter Pack (ครั้งเดียว + Sweetheart Rod `Exclusive`), Boost 2x Coins / 2x Pearls (`Shared/Boosts`, เวลาจริงรวมออฟไลน์), คำสั่ง Dev `boost`, `unbuy`; รอ ID 3 สินค้าใหม่
- 2026-11-17 — C7 เควสต์รายวัน ฝั่ง server เสร็จ: `Config/Quests` (10 ข้อ), `Shared/Quests`, `QuestService` (สุ่มรายวันแบบถ่วงน้ำหนัก, นับจาก signal ใหม่ `ShopService.FishSold` / `AuraService.Pulled` + `FishCaught` ส่ง streak), remote `ClaimQuest`, คำสั่ง Dev `quests`; หน้าต่างรอ session UI
- 2026-11-17 — C17 ดาวออร่า + Star Token + pity ใหม่ ฝั่ง server เสร็จ: `Config/AuraStars`, `Shared/AuraStars`, pity Legendary 100 + HardPity Mythic 300, x10 Rare+, `Roll.AuraRates` (อัตราจริง), remote `StarUpAura`, เซฟ schema 4 (ตัวซ้ำเดิม → token), คำสั่ง Dev `stars`, `pity ... mythic`
- 2026-11-17 — C16 Gear Enhance ฝั่ง server เสร็จ (เฟส 1 Coins): `GameConfig.Enhance`, `Shared/Enhance`, stat ของที่ใส่อยู่คูณตามขั้น, remote `Enhance`, คำสั่ง Dev `enhance`; ไม่คูณ MaxDepth
- 2026-11-17 — C15 Mastery ฝั่ง server เสร็จ: 7 สายใน `Config/Mastery` (Luck แบบลดหลั่น, MaxLevel สำหรับ stat ที่มีเพดาน), `Shared/Mastery`, stat source, remote `UpgradeMastery`, คำสั่ง Dev `mastery`; หน้าจอรอ session UI
- 2026-11-17 — C14 บ่อปลา + Pearls ฝั่ง server เสร็จ: `Shared/Aquarium`, `AquariumService` (PutInTank ทั้งชุด/ไม่ใส่เลย, TakeFromTank, BuyTankSlot, Pearls ทุก 5 วิ, ออฟไลน์ตามเพดาน), stat `PearlRate` / `OfflineCapHours` (VIP +8 ชม.), คำสั่ง Dev `offline` + `give pearls`; หน้าจอรอ session UI
- 2026-11-17 — C13 ใส่ ID จริงของ Pass 3 + Product 3 แล้ว; เช็ค API ผ่าน (pass ยังไม่เปิดขาย, ราคา product บนเว็บไม่ตรงตาราง)
- 2026-11-17 — C13 ระบบรับเงิน Robux โค้ดเสร็จ: `Config/Products`, `MonetizationService` (ProcessReceipt กันซ้ำด้วย PurchaseId + เซฟก่อนยืนยัน, เช็ค Game Pass ตอนเข้า/ตอนซื้อ), pass เป็น stat source, คำสั่ง Dev `grant/revoke pass`, `receipt`; รอ ID จากเว็บ + ปุ่มซื้อ (session UI)
- 2026-11-17 — C12 Balance Pass 1 โค้ดเสร็จ: มูลค่า/ราคา ×10 + บันไดราคาใหม่, เริ่ม 500 coins, Auto 14 วิ (Gems/หีบ ×0.5), Hot Streak +5%/ตัว สูงสุด +50% (remote `Streak`), ปลาใหม่ +3 Gems, XP 1.3, Luck tier 0.6, Silk Lv.12, Naga RollWeight 0.2, ปลา Gloom Sprat (200–400m), เซฟ schema 3 (เงิน ×10); ป้าย Streak บนจอรอ session UI
- 2026-11-17 — ราคา Robux สรุป (คุณเลือกแนว "เด็กเอื้อมถึง"): Gems 25/99/249, Boost 2 ชม. 39, Starter Pack 49, VIP 149, Auto-Fish Pro 249, Infinite Bag 349 (C6/C19)
- 2026-11-17 — C20 มินิเกม: Catch Bar เกิดตรงปลา + ช่วงพัก 0.6 วิตอนเริ่ม (โค้ดเสร็จ รอทดสอบ); เพิ่ม art sheet 10–16 ใน `ART_PROMPTS.md` + สเปก UI `HANDOFF_ECONOMY_UI.md`
- 2026-11-17 — (session ระบบเกม) วิเคราะห์ balance + แผน economy (`docs/BALANCE_PLAN.md`), brief ให้ agent วิเคราะห์ (`docs/ANALYSIS_BRIEF.md`), หน้าโมเดลคำนวณ (`docs/economy/economy-model.html`); เพิ่มงาน C12–C19 จากแผนเรา + `aura_fishing_economy_monetization_model.md`; C3 Rebirth ย้ายไป Lv.50; C6 ใส่ราคา pass
- 2026-11-17 — B19 ทดสอบผ่าน
- 2026-11-17 — B19 Boardwalk เป็นแมพหลัก: ลบแมพเกาะเดิม, ย้ายร้าน + แท่นออร่ามาลานกลาง, Spawn ใหม่
- 2026-11-17 — B19 ขอบทะเล: ทุ่น + แนวปะการัง + กระแสน้ำผลักกลับ + server พากลับ + หมอกขอบฟ้า (Shared/PlayArea, BoundaryController, BoundaryService)
- 2026-11-17 — B19 แมพต้นแบบ Stilt Boardwalk + ทะเลกว้าง 2000×2000 (tools/map/boardwalk.luau); ลบสคริปต์ซ้ำ 29 ตัวใน Studio (Rojo sync ซ้ำ, เนื้อหาเหมือนกัน)
- 2026-11-17 — B12, B14, B15 + B6 + B9, B16 ทดสอบผ่าน
- 2026-11-17 — B17 + B18 ทดสอบผ่าน
- 2026-11-17 — B17 Skeleton loading รูป (Mystery Fish / Unknown Aura); B18 stat Auto Wait (AutoSpeed) บนเบ็ด/เหยื่อ + ป้าย Highlight สีทอง
- 2026-11-17 — B16 คำสั่ง Dev (แชท ! + แผง F2) ทดสอบใน Play แล้ว
- 2026-11-17 — B15/B6/B9: Events hub (data-driven การ์ด + Action), หน้ากาชา G1 + variant อีเวนต์ E1, pity/x10/milestones ฝั่ง server, x10 Summary; Figma E0/E1/E1b
- 2026-11-17 — B12 Fishdex: ปุ่ม Sort (Depth/Rarity/Name/Caught/Found) + Discovery เหลือแค่ชิปตัวเลข `7 / 20` (เกม + Figma 09, bake แล้ว รอทดสอบ)
- 2026-11-17 — B13 ทดสอบผ่าน; B14 มินิเกม Twin tubes ตาม Figma 03 (โค้ด + bake)
- 2026-11-17 — B13 Main Menu hub ทำงานจริง + Config/Features; แก้ภาพ Sunscale Sardine ไม่ขึ้น (id สะกดไม่ตรงชื่อรูป → เปลี่ยน id + ย้ายเซฟ)
- 2026-11-17 — B8 Inventory ทดสอบผ่าน
- 2026-11-17 — C2 ตัดสินใจ data model (กระเป๋าแบบช่อง+กอง, Treasure เปิดได้); B8 Inventory โค้ดเสร็จ + bake (รอทดสอบ)
- 2026-11-17 — B0, B10, B11 ทดสอบผ่าน (desktop)
- 2026-11-17 — B10: ย้าย HUD/CastPopup/Minigame/AuraReel ลง StarterGui (bake) + ระบบ Components (Screens/Components.luau = ต้นแบบ, UI/Components.Clone ตอนรัน) + แผง Aura UI เพิ่ม 5 รายการ
- 2026-11-17 — ปุ่มใช้ไม่ได้ = เทาหม่น (เกม + Figma 05/06); เมนูซ้ายเป็น tile 64×64 ตาม Figma 01; CAST/DEPTH/AUTO ซ่อนเมื่อไม่อยู่ใกล้น้ำ (Shared/FishingSpot ใช้ร่วม server/client)
- 2026-11-17 — B0 แก้ต่อ: ปุ่มกดแล้วแบน (ซ่อน Lip), Lip/Face ZIndex ติดลบให้ของในปุ่ม (ราคา, DEPTH) อยู่บน, UIStroke ย้ายไป Face; HUD ปรับขนาด/ไอคอนตาม Figma 01
- 2026-11-17 — B1–B5 ทดสอบผ่าน (desktop); เพิ่ม B0: ปุ่ม Face+Lip แบบ Figma, New.Highlight ราคา, การ์ด Equipped สีมิ้นต์ (เกม + Figma 07)
- 2026-11-16 — A15 ผ่าน: Figma ปัจจุบัน = source of truth ของ UI
- 2026-11-16 — A14 ทดสอบผ่าน: export Modal จาก Figma จริง → Generated/Modal.luau → mount_ui_module ใน Studio
- 2026-11-16 — A13, A16 ทดสอบผ่าน (desktop)
- 2026-11-16 — A12 ทดสอบผ่าน (Claude รันเอง: get_tree, create/set/delete Part)
- 2026-11-16 — ทดสอบ: A11 ผ่าน (DataStore ใน Studio)
- 2026-11-16 — ทดสอบ: A9, A10 ผ่าน (desktop)
- 2026-11-16 — ทดสอบ: A8 ผ่าน (ยังไม่ได้ลองประกาศ Legendary)
- 2026-11-16 — ทดสอบ: A6, A7 ผ่าน (desktop) — ความยากมินิเกมโอเค
- 2026-11-16 — ทดสอบ: A4, A5 ผ่าน (desktop)
- 2026-11-16 — ตัดสินใจ: โฟกัส desktop ก่อน; A17 (mobile) เลื่อนไปทีหลัง (ใช้ได้แต่ยังไม่สวย)
- 2026-11-16 — ทดสอบ: A1 ผ่าน, A2 ผ่าน, A3 คอมผ่าน/มือถือแนวนอนไม่ผ่าน → แก้เป็น A17 (UIScale ต่อกลุ่ม + เมนูแถวขวาบนบนจอเตี้ย + `New.FitToScreen` สำหรับ popup/มินิเกม/กาชา)
- 2026-11-16 — เปลี่ยนเป็น checkbox แบบ GFM (`- [ ]`/`- [x]`) + ภาพรวมด้านบน; ขั้นตอนทดสอบติ๊กได้ทีละข้อ
- 2026-11-16 — สร้างไฟล์: A1–A15 เสร็จ (รอทดสอบ), B1–B9 มอบให้ session Figma → Roblox, C1–C11 backlog
- 2026-11-16 — (Figma → Roblox UI) ตัดสินใจเก็บ UI ใน place (StarterGui) + เครื่องมือ `tools/ui/bake.mjs`; B1 Modal, B2 Auras, B3 Shop, B4 Fishdex โค้ดเสร็จ; แก้ A1 ข้อ 7 และ A9 ให้ตรงของใหม่
- 2026-11-16 — หน้าต่างที่ bake (Menus/Modal/MainMenu) ใช้ `New.FitToScreen` เดียวกับ popup อื่น (A17) ผ่าน `New.FitWindow`; เพิ่มขั้นตอนทดสอบมือถือแนวนอนใน B2/B3
- 2026-11-16 — รูปจริง + เงา 9-slice ขึ้นใน Studio แล้ว; capture เทียบ Figma ทุกหน้าจอ (ภาพ `docs/figma/compare_menus.png`, `compare_mainmenu.png`) ต่างกันแค่ข้อมูลตัวอย่างบางจุด; แก้ความกว้างรายละเอียดใน Shop, ช่วงเวลาใน Main Menu, ขนาดจุดแดง/รูปโปรไฟล์
- 2026-11-16 — อัปโหลดรูปครบ 99/99 (Open Cloud) + แปลง decal → image id ด้วย `resolve_decals.mjs`; รอ Roblox moderation ก่อนรูปจะขึ้นใน Studio
- 2026-11-16 — เงาหน้าต่างแบบ 9-slice export จาก Figma (section "Roblox 9-slice (export)" ใหม่ ไม่แตะของเดิม) → `assets/ui-global/slice_shadow_*.png`; ตัวอัปโหลดอัตโนมัติ `tools/art/upload_assets.py` + `tools/ui/resolve_decals.mjs`
- 2026-11-16 — เทียบ Studio กับ Figma ด้วยภาพจริง (capture_ui + `tools/ui/compare.py`): แก้ตัวอักษรบนปุ่มสีหายทั้งหมด (gradient ย้อมสีตัวอักษร), ขนาดตัวอักษรตรง Figma (Roblox วาดเล็กกว่า: Fredoka ×1.17, Nunito ×1.27/×1.36 แปลงให้อัตโนมัติ)
- 2026-11-16 — B5 Main Menu โค้ดเสร็จ + bake; ฟอนต์/ขนาดตัวอักษรตรง Figma (badge = Nunito ExtraBold 12, ปุ่ม/หัวข้อขนาดคงที่); เพิ่มแผง Aura UI (A16), `tools/ui/preview.mjs`, `tools/ui/compare.py`, `tools/ui/collect_asset_ids.mjs`
- 2026-11-16 — bake B1–B4 ลง `places/AuraFishing.rbxlx` (StarterGui.Modal, StarterGui.Menus) แล้ว รอคุณ Save + Play ทดสอบ
- 2026-11-17 — ลายเส้นเฉียง (hatch) `pattern_stripes` / `pattern_stripes_fine` (64px ต่อกันไร้รอย, สีขาวย้อมได้) + `New.Stripes(...)` สำหรับช่องว่าง / Item ว่าง / track ด้านหลังของ progress bar (ส่วนที่ยังว่าง ไม่ใช่ตัว fill, ลาย fine สี SubText opacity 10%); ภาพตัวอย่าง `docs/figma/patterns_preview.png`; อัปโหลดแล้ว (101/101 assets มี id) และทดสอบใน Studio แล้ว (`docs/figma/patterns_studio.png`)
- 2026-11-17 — ยกเลิกลายเส้นเฉียงบนหน้าจอ (ตามที่คุณสั่ง): Figma คืนเป็นสีทึบ (Progress Bar track, Item Slot Empty), เกมเอาออกจาก Fishdex; ไฟล์ลาย + `New.Stripes` ยังเก็บไว้เผื่อใช้ทีหลัง (ไม่มีหน้าจอไหนใช้)
- 2026-11-17 — B11: การ์ดปลาที่ตกได้ใช้หน้าตา Figma 04 (prefab CatchCard ใน Components + HUD.ShowCatch); เพิ่ม `tools/ui/figma_dump.py`
- 2026-11-17 — Reel Minigame: ลองทำ Glass Tube ในเกมแล้ว**ย้อนกลับ**เป็น Pond Card ตามที่สั่ง (ยังไม่เอาเข้าเกม); ทำตัวเลือก 5 แบบใน Figma section ใหม่ "Reel Minigame · Glass Tube variants (pick one)" (x 11200, y 1700) จาก Option A + art เดิม — ภาพ `docs/figma/reel_tube_variants.png`, สคริปต์ `docs/figma/reel_tube_variants.py`; รอคุณเลือก
- 2026-11-17 — Reel Minigame: คุณเลือก **A2 Twin tubes** → ใส่ใน Figma หน้า 03 · Reel Minigame แล้ว (แทนแค่ frame "Reel Minigame", ตรงกลางจอ) + ติด (CHOSEN) ใน section ตัวเลือก — ภาพ `docs/figma/reel_03_a2.png`; **ยังไม่เอาเข้าเกม** รอคุณสั่ง
- 2026-11-17 — เมนูด้านซ้าย (Shop/Auras/Fishdex/Menu): กล่องไอคอน 64×64 + ชื่อใต้กล่องเป็นตัวหนังสือขอบ (ขาว + ขอบเข้ม แบบ Lv.) และปุ่ม Menu ใช้ไอคอน StarterPouch — ทั้ง Figma 01 HUD (`docs/figma/menu_tiles.py`) และเกม (prefab MenuTile) — ภาพ `docs/figma/compare_menu_tiles.png`; ทดสอบ: Play → ดูเมนูซ้าย, เอาเมาส์ชี้แล้วกล่องเด้ง, กดแต่ละปุ่มเปิดได้เหมือนเดิม
- 2026-11-17 — Economy UI ขั้น 1 (HUD + Streak, ตาม `docs/HANDOFF_ECONOMY_UI.md` ข้อ 1): Figma section ใหม่ "Economy · 1 HUD + Streak (C12/C14/C19)" (x 14400, y 0) — HUD มีชิป Pearls + อัตรา/นาที, ชิป Boost นับถอยหลัง, วิดเจ็ต "ของชิ้นต่อไป" กลางบน, ป้าย Hot Streak ข้าง CAST (x2/x7/x10 MAX/LOST), ป้ายชื่อ VIP, การ์ด Catch Result มีป้าย streak + HOT, กติกาตัวเลข k/M — ภาพ `docs/figma/economy_hud.png`, สคริปต์ `docs/figma/economy_hud.py`; รูป pearl/hot_streak/boost/vip ยังเป็นช่องสีแทน (รอ gen จาก ART_PROMPTS); ยังไม่แตะ 01 HUD / 04 เดิม และยังไม่เอาเข้าเกม
- 2026-11-17 — Economy UI ขั้น 1 (แก้ตาม session ระบบเกม): "ของชิ้นต่อไป" = ของถาวรที่ถูกสุดที่ยังไม่มี (Rods/Lines/Bags ไม่รวม Bait) + แบบติดเลเวลแสดงแม่กุญแจ "Reach Lv.N" แทนแถบ; Hot Streak: ตกแบบ Auto ไม่นับ, สายขาด/พลาดจังหวะเบ็ด = LOST — Figma section เดียวกัน, ภาพ `docs/figma/economy_hud.png`
- 2026-11-17 — Economy UI ขั้น 1 รอบ 2 (ตามที่คุณสั่ง): Hot Streak เหลือแท็กเล็กมุมขวาบนปุ่ม CAST (x2 ทอง / x7 ส้ม / x10 เรือง / LOST เทา), Pearls อยู่แถวเงิน, Boost เป็นไอคอนกลมมีวงนับถอยหลัง 360° + เวลาแบบย่อหน่วยเดียว (2D / 23h / 45m / 30s), VIP แสดงบนหัวตัวละครอย่างเดียว, เอาวิดเจ็ต "ของชิ้นต่อไป" ออก — ภาพ `docs/figma/economy_hud.png`
- 2026-11-17 — ตัดภาพ ART_PROMPTS ชีต 10–16 (`assets/ui/10–16.png`) ด้วย `slice_grid.py` → `assets/art/ui/status|icons|shop`, `fish`, `materials`, `auras`, `equipment` (63 รูป) — **ยังไม่ upload** (ต้องรัน `tools/art/upload_assets.py` เองตอนจะเอาเข้าเกม)
- 2026-11-17 — ออกแบบหน้าต่างใหม่ **17 · Character** (สลับอุปกรณ์ที่ซื้อแล้วโดยไม่ต้องเข้า Shop) ใน Figma section "17 · Character (equipment swap)" (x 14400, y 1800): ตัวละคร + ช่องที่ใส่อยู่ (Rod/Line/Bag/Bait) + สถิติรวม, แท็บ Rods/Lines/Bags/Baits, ช่องของที่มี (ติ๊กส้ม = ใส่อยู่), การ์ดเทียบค่ากับของที่ใส่อยู่ + ปุ่ม EQUIP — ภาพ `docs/figma/character_window.png`, สคริปต์ `docs/figma/character_window.py`; ยังไม่เอาเข้าเกม
- 2026-11-17 — Economy UI ใน Figma ครบทุกข้อของ `docs/HANDOFF_ECONOMY_UI.md` (ยังไม่เอาเข้าเกม, ไม่แตะหน้าจอเดิม) — สคริปต์ `docs/figma/economy_screens.py`, section ใหม่คอลัมน์ x 17000:
  - 0 Icons: รูปใหม่ชีต 10–16 ทั้ง 63 รูป + ไอคอนเวกเตอร์ขาว 12 ตัว (`icon_star`, `icon_star_empty`, `icon_arrow_up`, `icon_flame`, `icon_infinity`, `icon_timer`, `icon_info`, `icon_lock`, `icon_robux`, `icon_clover`, `icon_bar`, `icon_reel`) — ภาพ `docs/figma/economy_icons.png`
  - 2 Aquarium (C14/C18): หน้าบ่อ 8 ช่อง (ปลา/ว่าง/ล็อกพร้อมราคาขยาย), ตัวเลือกปลา, popup ระหว่างไม่อยู่ (ปกติ + ชนเพดาน), Inventory มีปุ่ม TANK/SELL + ป้าย 🔥xN + แท็บ Materials — `economy_aquarium.png`
  - 3 Mastery (C15): 7 การ์ด + สถานะ อัปได้/เงินไม่พอ/MAX — `economy_mastery.png`
  - 4 Enhance (C16): Shop มีป้าย +N, ปุ่ม ENHANCE, ราคา k/M, ล็อกเลเวล + popup Enhance (ปกติ/MAX) — `economy_enhance.png`
  - 5 Auras + Gacha (C17): ดาว ★1–5 + ปุ่ม STAR UP + ตัวนับ Star Token, pity 2 แถว, x10 RARE+, popup อัตราจริง, ผลซ้ำ +1 Star Token, G6 x10 แบบ token — `economy_auras.png`
  - 6 Store (C6/C19): แท็บ Passes/Gems/Boosts/Packs, ลิงก์อัตราสุ่ม, Starter Pack ครั้งเดียว — ราคา Gems/Boost เป็น **draft** — `economy_store.png`
  - 7 Hot fish + Hub (C18): Sell All มีโบนัสปลาขายดี, ป้าย HOT FISH ที่ร้าน, Main Menu 13 ไทล์ (Character/Aquarium/Mastery/Store ใหม่, Rebirth Lv.50, ป้าย VIP), การ์ด Daily Login — `economy_hot.png`
- 2026-11-17 — Economy UI: รูปแบบข้อมูลยืนยันกับ session ระบบเกมแล้ว — Aquarium Fish มี `Uid`/`Weight`; Mastery ส่งตัวเลข (client ใช้ `Format.Stat`); ดาวออร่า `profile.Auras.Stars[id]` + `StarTokens`, ราคาใน `Config/AuraStars`; Boost = `profile.Boosts{Coins,Pearls = endsAtUnix}`; Hot fish = `{FishId, Mult, EndsAt}` ส่งทุกคน; อัตราสุ่มคำนวณฝั่ง client; Character ใช้ remote `Equip` เดิม (ถอดเหยื่อ = `Equip("Baits", nil)`); ราคา Gems/Boost ใน Figma ยังเป็น draft รอคุณเลือก
- 2026-11-17 — Figma Aquarium: เพิ่มหน้าต่างแยก **Put in Tank** (ตามที่ผู้ใช้ขอ) — เปิดจากปุ่ม "+ Add fish" ใน Aquarium และปุ่ม TANK ใน Inventory (เลือกกองนั้นไว้ให้แล้ว); แสดงปลาทุกกองในกระเป๋า เลือกได้หลายตัว แล้วกด CONFIRM (n); กองที่มีมากกว่า 1 ตัวจะเปิด **Quantity modal** (slider, ปุ่ม −/+, ปุ่มลัด 1 / Half / MAX, จำนวนสูงสุด = min(ที่มี, ช่องว่างที่เหลือ)), ช่องที่เลือกแสดง `2/41`; สถานะบ่อเต็ม = ช่องอื่นจางลง; ส่งไป server ครั้งเดียว `{ {Id, Mutation, Count} }`. เอา fish picker อันเก่าออกแล้ว. ภาพ: `docs/figma/economy_put_in_tank.png`
- 2026-11-17 — Figma Store/Starter: ใส่ราคา Robux จริงแทนราคาร่างแล้ว — Gems 25/99/249, Boost 39, Starter 49, Auto-Fish Pro 249, Infinite Bag 349 (VIP 149 กับ Extra Cast ≤299 เขียนไว้ใน Rules เพราะการ์ดแสดงเป็น OWNED / COMING SOON). จำนวน Gems (40/160/400, Starter 300) ยังเป็นค่าเดิม. ช่อง Data ของ Aquarium เพิ่มเงื่อนไข PutInTank ว่าต้องสำเร็จทั้งชุดหรือไม่เพิ่มเลย
- 2026-11-17 — Figma Store: จำนวน Gems ตามราคาใหม่ — 25 / 110 / 300 Gems (5 / 22 / 60 ครั้ง), Starter Pack ได้ 100 Gems
- 2026-11-17 — Put in Tank ปรับเป็นการ์ด 4:3 สไตล์ Fishdex: Figma (Screen C14 · Put in Tank) อัปเดตเป็นการ์ด 4:3 (228×171) จัดเป็นตาราง 3 คอลัมน์ กรอบ Picture สีฟ้าอ่อน #F4FAFD มีรูปปลา 96×64, ป้าย Rarity Tag สีตามระดับ, ป้ายอัตรา Pearls/วินาที +X/s, จำนวนในกระเป๋า xN, สถานะการเลือก (SELECTED หรือ x/y สี Coral), แถบสรุปด้านล่าง Thumbs + ยอดรวมอัตรา /s + ปุ่ม CONFIRM; และอัปเดตโค้ดเกม `EconomyController.luau` ให้ตรงตาม Figma ทุกจุด (CellSize 220×165, กรอบ Picture, Rarity tag, อัตรา /s, แสดง preview อัตราที่ได้เพิ่มบนแถบบน, ป้ายสถานะการเลือก, ปุ่ม MAX/CLR สำหรับกอง > 1)
- 2026-11-17 — ปรับ Put in Tank ตามคำสั่ง: ลบหน้าจอ `Put in Tank · full` ออกจาก Figma โดยสิ้นเชิง (เหลือหน้าจอเดียว), ย้ายกระดาน Flow chart ขึ้นมาแทนที่, ปรับคำอธิบาย Flow ใน Figma; อัปเดตทั้งใน Figma และในเกม (`EconomyController.luau`) ให้ปุ่ม Confirm เปลี่ยนข้อความเป็น "Full" และ Disable ปุ่มอัตโนมัติเมื่อถังเต็ม (`free == 0`) หรือเลือกเกิน (`total > free`) — type check Luau สะอาด 100% และ Figma เชื่อมโยง Image Assets ครบ 72 ช่อง
- 2026-11-17 — กฎเคร่งครัดเรื่องตัวอักษร: กำจัด "✓", "•", และ emoji ทั้งหมดออกจากโปรเจกต์อย่างสิ้นเชิง ทั้งในโค้ดเกม (`src/`), UI ทั้งหมด, สคริปต์ Figma (`docs/figma/`), และกระดาน Figma Section 2 Aquarium — เปลี่ยนป้ายแสดงผลเป็นข้อความตัวหนังสือชัดเจน เช่น "SELECTED", "x / y", ตัวแบ่งใช้ "|" หรือ "-", กล่องเช็คถูกใช้ Frame Indicator แทนสัญลักษณ์, และเพิ่มกฎข้อที่ 6 ใน `AGENTS.md` ห้ามใช้สัญลักษณ์เหล่านี้เด็ดขาด
- 2026-11-17 — ปรับป้ายช่องว่าง Put in Tank: เปลี่ยนจาก "Free slots 2 / 6" เป็น "2/6" (รูปแบบ N/N กะทัดรัด) ทั้งใน Figma (`info_pill` คู่กับไอคอนบ่อปลา) และในโค้ดเกม `EconomyController.luau` แถบบนแสดง `[เลือก] selected (+rate/s) | N/N` ให้ตรงกัน
- 2026-11-17 — เพิ่มการแสดงอัตรา +X/s บน Pearls Chip ใน Roblox และแก้ใน Figma: เพิ่ม TextLabel "Rate" บน `pearlsChip` ของแถบ Currencies HUD ในเกม (`EconomyController.luau`) แสดงรายได้ต่อวินาทีตามจริงและนับ live ทุกเฟรม (`+0/s` เมื่อไม่มีปลา หรือ `+0.22/s` ตามปลาในบ่อ) สีเขียวมินต์ `T.GoodLip` สไตล์ Figma; และแก้ไขค่า draft ใน Figma `economy_hud.py` จาก `+1.5/m` เป็น `+0.025/s` ซิงค์ลงกระดาน Figma Section 2 เรียบร้อย (Node 3569:40840)
- 2026-11-17 — ปรับการแสดงผลยอด Pearls เป็นจำนวนเต็มปกติ: แก้ไข `Aquarium.FormatPearls` ใน `Aquarium.luau` ให้เรียกผ่าน `Format.Number` แสดงผลเป็นตัวเลขจำนวนเต็มปกติ (เช่น `1,250`, `45`, `0`) ไม่มีจุดทศนิยม ทั้งบน HUD Chip, หน้าต่าง Aquarium, และหน้าต่าง Mastery — ไม่แตะต้องหน้าจอ Figma ของผู้ใช้
- 2026-11-17 — เชื่อม Live Pearls ในหน้าต่าง Mastery: ปรับ `EconomyController.luau` ให้ Header ของ Mastery แสดง Pearls เป็นจำนวนเต็มแบบ Real-time พร้อมอัตราการผลิต `+X/s` สีเขียวมินต์นับสดทุกเฟรมตามปลาในตู้; ปุ่มอัปเกรดแสดงราคา Pearls เป็นจำนวนเต็มปกติ; ผ่านการตรวจ Type check สะอาด 100% ภายใต้ Fast Code-First Workflow
- 2026-11-17 — เพิ่ม Mastery ลง Main Menu Hub ("Menu") + แก้ Padding Gem Chip + แก้ Flow Gacha x10: เพิ่มไทล์ Mastery ใน Main Menu (`Screen.Tiles`, `MainMenuController.ACTIONS`, `EconomyController.OpenMastery`); ปรับชิป Gems ในหน้าต่างเมนูให้ใช้ `AutomaticSize` พร้อม `UIPadding` ซ้าย 10 ขวา 16 เพื่อไม่ให้ตัวเลขเบียดขอบ; ปรับ Flow Gacha x10 ให้แสดงการ์ดเปิดตัว You roll (AuraReel) ก่อน เมื่อผู้เล่นกด Close/Equip แล้วจึงเปิดหน้าสรุป X10 Result — Type check ผ่าน 100% สะอาด ไร้ error
- 2026-11-17 — สร้าง Section ตัวเลือกการ์ด Aquarium 6 แบบใน Figma: สร้าง Section "Aquarium · Card Remove Variants (6 Options)" (Node `3571:41388`) บน Page "Out Space" ใน Figma พร้อมเรนเดอร์ภาพปลา Ancient Coelacanth และเหรียญทองครบ 18 slots สำหรับเทียบ UX ทั้ง 6 แบบโดยไม่แตะต้องหน้าจอเดิม
- 2026-11-17 — นำ Option 2 (Clean Card) เข้าสู่เกมจริง: ปรับ `AquariumScreen.luau` เอาปุ่มลบ x ออกจากการ์ดทั้งหมด เพิ่มพื้นที่แสดงชื่อปลาและ Rate เต็มความกว้างการ์ด; แตะที่การ์ดปลาจะเปิด Confirm Modal แสดงรายละเอียดปลา พร้อมปุ่ม "Return to Bag" ยืนยันการนำปลากลับเข้ากระเป๋า ป้องกันการกดผิด 100% — Type check ผ่าน 100% สะอาด ไร้ error
- 2026-11-17 — แก้ไข Padding ของ Currency Chip ทุกหน้าจอ: เพิ่มฟังก์ชัน `New.FormatCurrencyChip` ใน `New.luau` จัดการขยายขนาดตามตัวเลขจริงอัตโนมัติ (`AutomaticSize = X`) พร้อมใส่ `UIPadding` ซ้าย 12px ขวา 20px ให้มีระยะเว้นจากขอบโค้งอย่างสวยงาม ไม่ติดขอบขวาอีกต่อไป; ผูกใช้งานใน `MenuFill.luau` (Shop/Auras/Fishdex), `InventoryController.luau`, `EventController.luau`, `GachaPage.luau` — Type check ผ่าน 100% สะอาด ไร้ error
- 2026-11-17 — กวาดแก้ Padding ชิปเงินทั้งหมดในเกม (Coins, Gems, Pearls, Bag, Rate): ปรับปรุงตัวแสดงผลค่าเงินและสถิติต่างๆ ในกล่องโค้งมนทุกจุด ทั้ง HUD (Coins, Gems, Pearls, Bag Capacity), Catch Result Cards (Rewards Coins/Gems), Aquarium Header (Pearls 20px, Offline Cap 14px, Rate), Put in Tank cards (Rate pill, Bag count) ให้มี `UIPadding` ขวา 12-20px และกึ่งกลางแนวตั้งพอดี ไม่ชิดขอบขวาอีกต่อไป — Type check ผ่าน 100% สะอาด ไร้ error
- 2026-11-17 — ถอดปุ่ม Mastery ออกจาก Aquarium Header และเชื่อมต่อ Main Menu สมบูรณ์: ลบปุ่ม Btn Mastery ออกจาก Aquarium Head โดยสิ้นเชิง ขยาย Spacer แบบ FlexFill ดัน Slots ชิดขอบขวาอย่างลงตัว; ย้ายทางเข้า Mastery ไปไว้ที่โทรศัพท์ Main Menu Hub ("Menu") พร้อมระบบ auto-fallback รองรับการเปิดหน้าจอได้ทันที; Re-bake หน้าจอ MainMenu, Menus, HUD, Inventory, Events ลง StarterGui ใน Roblox Studio อัตโนมัติ — Type check สะอาด 100% ไร้ error
- 2026-11-18 — เพิ่มปลาใหม่ Golden Koi: ระดับ Legendary, ความลึก 0-40m, BaseValue 12000, น้ำหนัก 3-10 kg, Difficulty 7, Pattern Erratic ลงใน Config/Fish.luau — Type check Luau สะอาด 100% ไร้ error ตามกฎ Fast Code-First Workflow และไม่มีอักขระต้องห้ามตามกฎ Strict Character Rule
- 2026-11-19 — เก็บไอคอน Golden Koi ที่ `assets/art/fish/GoldenKoi.png` และลงทะเบียน `fish/GoldenKoi` ใน catalog แล้ว อัปโหลดแล้วและอ่าน Image ID `109436578580598` จาก Decal ใน Studio สำเร็จ ซิงก์เข้า `UIAssets.luau` แล้ว
  - [ ] หลังซิงก์ Rojo เข้า Play → เปิด F2 แล้วพิมพ์ `give fish GoldenKoi 1` → เปิด Inventory และตรวจว่าการ์ด Golden Koi แสดงรูปปลาสีทอง
- 2026-11-18 — C14 Offline reward popup ปรับให้ตรงตาม Figma เป๊ะ: กรอบหน้าต่าง Modal 520px ขอบมน 36px, รูปภาพ offline_reward 110x110, หัวข้อ "While you were away", เวลาที่หายไป (Away Xh Xm พร้อมแจ้ง capped at N h เมื่อชนเพดาน), แถบยอด Pearls สีม่วง 8C6FD6 ขนาด 38px พร้อมไอคอน pearl, แถบเตือน Cap full pill สีแดงสำหรับแจ้งเตือนเพดาน, Footer สี Sand พร้อมปุ่ม COLLECT สีเขียวมินต์ T.Good และปุ่ม x2 Boost (เมื่อมีสิทธิ์); ทดสอบได้ทันทีด้วยคำสั่ง Dev "!offline 2h" ใน Roblox Studio — Type check สะอาด 100% ไร้ error
- 2026-11-18 — C15 หน้าต่าง Mastery ทำตาม Figma "Economy · 3 Mastery" (`UI/MasteryScreen.luau`, แทนหน้าต่าง Window kit เดิม): การ์ด 352×92 2 คอลัมน์, ปุ่ม UPGRADE/ราคา Pearls/MAX, หัว Pearls สด + /s + Total Lv.; ตัวเลขโบนัสแบบสั้น (+22% → +23%, ตัวคูณ Reel Power/Pearl Rate/Sell Mult แสดงเป็น %, Offline Cap เป็นชั่วโมง/นาที); export ไอคอน 4 อันจาก Figma ลง catalog (รออัปโหลด). เพิ่ม **`tools/check.bat`** (`node tools/check.mjs`) = rojo sourcemap + luau-lsp (error = ไม่ผ่าน, lint = เตือน) + หาอักขระต้องห้าม (✓ • อีโมจิ) ในสตริงที่ผู้เล่นเห็น — คำสั่งเดียวจบ
- 2026-11-18 — Global vector icons (§5) ลบแถบ Tinted และ Export ไอคอน: ลบ Frame Tinted ใน Figma ออกตามคำสั่งเพื่อความกระชับสะอาดตา และ Export ไอคอน 64px PNG ทั้ง 12 ตัว (`icon_star`, `icon_star_empty`, `icon_arrow_up`, `icon_flame`, `icon_infinity`, `icon_timer`, `icon_info`, `icon_lock`, `icon_robux`, `icon_clover`, `icon_bar`, `icon_reel`) เก็บไว้ใน `assets/ui-global/` ครบทั้งหมด
- 2026-11-18 — C14 แก้ไขและปรับแต่ง Offline reward popup ให้ทำงานได้จริงและหน้าตาตรง Figma 100%: แก้ไขฟังก์ชัน offlinePopup ใน `EconomyController.luau` ให้ TextLabel ทุกชิ้นมี Size และ AutomaticSize ชัดเจน, ฟอนต์ Fredoka One (หัวข้อ 26px, ยอด Pearls 40px) และ Nunito Bold (Away time 16px), แถบเตือน Cap full pill สีแดงและ Footer ใช้สี PanelLight (#F3E9D8) ถูกต้องตามธีมแทนสีเทา, ปุ่ม COLLECT สีเขียวมินต์ 354x54 และปุ่ม x2 Boost สีม่วง 82x54 วางเรียงข้างกันพร้อมไอคอน boost_pearls สไตล์ Figma, กด x2 จะ PromptProduct("BoostPearls") ทันทีหากยังไม่มี Boost — ทดสอบ Capture หน้าจอใน Roblox Studio ทั้งแบบปกติและแบบชนเพดาน (Capped) ผ่านสวยงาม 100% ไร้ error และไร้อักขระต้องห้าม
- 2026-11-18 — Global vector icons (§5) Export และอัปโหลดขึ้น Roblox สมบูรณ์: Export ภาพบอร์ดลง `docs/figma/shots/global_vector_icons.png`, Export ไอคอน 64px PNG ทั้ง 12 ตัว, ลงทะเบียน `assets/catalog.json`, อัปโหลดขึ้น Roblox Asset Server ผ่าน Roblox Studio MCP ได้ `rbxassetid://` ครบ 100% ทั้ง 12 ไอคอน พร้อมซิงค์ `UIAssets.luau` (175/175 มี asset id ครบทั้งหมด) — ตรวจสอบ `tools/check.mjs` ผ่าน 100%
- 2026-11-18 — C7 สร้าง Section ตัวเลือกหน้าจอ Daily Quests 3 แบบใน Figma: สร้าง Section "C7 · Daily Quests — 3 Design Layouts (Pick One)" (Node `3588:41853`) บน Page "Out Space" (x 25000, y 2000) ผ่าน JSON Builder ของ Plugin ใหม่ (120+ โหนด สร้างเสร็จใน 4 วินาที, เติมรูป 20 ช่องอัตโนมัติ) เพื่อทดสอบงานใหญ่: Option 1 Classic Cozy Deck (760x610 แถบ Milestone 1/3, 2/3, 3/3 พร้อมการ์ด 3 สถานะ In Progress/Claimable/Claimed), Option 2 Adventure Journal (840x610 แบบแบ่งฝั่ง Quest List + Grand Mega Chest), Option 3 Full Flow Preview (หน้าต่างเควสต์คู่กับป๊อปอัปฉลอง Quest Reward Claimed 520x390) — ไร้อักขระต้องห้าม 100%
- 2026-11-18 — C7 นำ Option 1 (Classic Cozy Deck) เข้าสู่โค้ดเกมจริงสมบูรณ์: สร้าง `UI/QuestsScreen.luau` ขนาด 760x610 ตาม Figma เป๊ะ (Header แสดง Title, ResetsIn timer, Gems chip, ปุ่มปิดสีแดง; Milestone Track 1/3, 2/3, 3/3 Daily Chests; Quest Cards 3 แถบแบ่ง 3 สถานะ In Progress, Claimable, Claimed); สร้าง `Controllers/QuestController.luau` ผูก RemoteFunc ClaimQuest และ DataController; ผูกปุ่ม Quests ใน Main Menu และเปิดใช้งานใน Features.Quests.Enabled = true — ตรวจสอบ `node tools/check.mjs` สะอาด 0 error ไร้อักขระต้องห้าม และเรนเดอร์ใน Roblox Studio สำเร็จ 100%
- 2026-11-18 — แก้ HUD Stats ซ้อนกัน + หน้า Daily Quests ให้ตรง Figma (3588:41856 Option 1). สาเหตุ: label ที่ใช้ AutomaticSize วัดความกว้างก่อนฟอนต์ Fredoka/Nunito โหลดเสร็จ จึงแคบเกิน ("Lv.100" ทับข้อความ XP, "Daily Quests" ทับป้ายเวลา) → เพิ่ม `New.FitTextWidth` (วัดด้วย TextService ด้วยฟอนต์จริง) ใช้กับ Level/XP ใน HUD และป้ายข้อความทุกอันใน Quests; การ์ดเควสใช้ `UIFlexItem` Fill ในช่องข้อมูล (เดิมกว้างตายตัว `1,-260` ทำให้ปุ่ม CLAIM / IN PROGRESS ล้นขอบการ์ด); ขนาดตาม Figma: Header 57, ปุ่ม X 73x57 r16, ชื่อเควส/Daily Chest Progress 20px, ช่องว่างโหนดหีบ 12, ป้ายรางวัล/สถานะสูง 26, ขอบการ์ด 2px (เคลมแล้ว 1px). ตรวจใน Studio: ปุ่ม CLAIM จบที่ 16px จากขอบการ์ด, Lv.100 กับ XP ห่าง 10px. ทดสอบ: Play → ดู HUD มุมซ้ายบน "Lv.xx" ต้องไม่ทับ "xxx / xxx XP" → เปิด Daily Quests → ชื่อ "Daily Quests" ไม่ทับป้าย "Resets in", ปุ่ม CLAIM และป้าย IN PROGRESS อยู่ในกรอบการ์ดทุกใบ
- 2026-11-18 — B21 ออกแบบ Item Detail Card 8 แบบ (A Classic, B Hero, C Rarity Band, D Compact, E Compare Table, F Trading Card, G Wide Split, H Bubble) + Inventory v2 6 แบบ (1 Rail Inside, 2 Bookmark Tabs, 3 Docked Detail, 4 Right Drawer, 5 Labelled + Filters, 6 Backpack Bar) + หน้าต่าง Bag Upgrade ใน Figma section 18A/18B (x 27200) — สคริปต์ `docs/figma/item_detail.py`; เพิ่ม prompt รูปชีต 17 (ไอคอนแท็บ Inventory) และ 18 (ไอคอน Mastery) ใน `docs/ART_PROMPTS.md`; ยังไม่แตะโค้ดเกม
- 2026-11-18 — B21 เลือก Inventory แบบ 2 (Bookmark Tabs) ทำต่อเป็น FINAL ขนาดเล็กลง 600x480 + การ์ด A ปุ่มสูงคงที่ 48; Bag Upgrade ขั้นสุดท้าย Bottomless Bag = Robux เท่านั้น (Infinite Bag pass 349); สร้าง 17 · Character ใหม่ (Rod/Line/Bait/Aura ไม่มี Bag, ใช้ Item Card) — Figma `3598:46643` + `3599:48078`, สคริปต์ `docs/figma/inventory_final.py` + `send_blocks.py`; ยังไม่แตะโค้ดเกม
- 2026-11-18 — ตัดรูปชีต 17 (ไอคอนแท็บ) + 18 (ไอคอน Mastery) ลง `assets/art/ui/tabs|mastery`, เพิ่ม 18 คีย์ใน catalog/UIAssets (ยังไม่อัปโหลด, ชุดพร้อมอัปโหลดที่ `assets/upload/2026-11-18_icons/`); ใส่รูปใน Figma ทุก section ใหม่ + การ์ด Mastery 7 สาย; แท็บที่คั่นหนังสือยื่นออกมากขึ้น (50x42) ให้เห็นไอคอนเต็ม; ออกแบบช่องว่างไม่มี + 6 แบบ (Recessed, Dashed, Silhouette, Numbered, Bubbles, Glass) + ช่อง Get More แบบใหม่ — section `3599:48461`, สคริปต์ `docs/figma/empty_slots.py`
- 2026-11-18 — ช่องว่างแบบ 5 Bubbles: Figma (18 FINAL, 17 Character, component Item Slot State=Empty) + ในเกม `Make.ItemSlot` เลิกใช้ "+" เป็นฟอง 3 เม็ด, bake Components/Inventory แล้ว (ต้องกด Ctrl+S เซฟ place)
- 2026-11-18 — แปลงรูปชีต 17/18 ทั้ง 18 รายการเป็น Image ID และผูกไอคอนกับ Inventory, Character, Bag Upgrade, Modifiers และ Mastery. เกณฑ์ผ่านคือรูปโหลดครบในหน้าจอที่ระบุด้านบน
- 2026-11-18 — Store ใช้ไอคอน Robux คู่กับราคาในปุ่มสินค้าที่ซื้อได้ทั้ง Passes, Gems และ Boosts & Packs และแสดง OWNED / BOUGHT / SOON สำหรับปุ่มสถานะ
- 2026-11-18 — จัดชั้นไอคอนเหนือของตกแต่งในช่องไอเท็มและรางวัล Gacha, โปสเตอร์ Events, แท็บ Inventory และปุ่มราคา Store
  - [ ] ทดสอบใน Studio โดยเปิด Inventory, Character, Item Detail, Events, รางวัล Gacha และ Store แล้วดูว่ารูปอยู่เหนือพื้นตกแต่งและป้ายสถานะยังอ่านได้ เมื่อ viewport แคบ หัวข้อ Gacha ต้องไม่ซ้อนกับไอคอน และยังเปิด VIEW ได้
- 2026-11-18 — แก้ Bookmark Tabs ให้ตรง Figma FINAL โดยเรียงเงา, แท็บ, และแผงหน้าต่างจากหลังมาหน้า
  - [ ] ทดสอบ Inventory: กด B สลับแท็บแล้วดูว่าปลายแท็บสอดใต้ขอบซ้ายของหน้าต่าง ไอคอนแสดงเต็ม และแท็บยังคลิกได้
- 2026-11-18 — เพิ่มระยะระหว่างชื่อ Inventory กับป้ายความจุ และเพิ่มขอบซ้ายขวาในป้ายเป็น 12 px
  - [ ] ทดสอบ Inventory: กด B แล้วดูว่าป้ายความจุมีระยะรอบเลขทั้งแบบมี UPGRADE และแบบ Inf
- 2026-11-18 — Inventory แสดงช่องว่างตามความจุกระเป๋า กระเป๋า Inf เติมเฉพาะช่องที่เห็นได้ในหน้าต่าง เปิดการเลื่อนเมื่อมีรายการเกินพื้นที่ และใช้ VirtualGrid เดิม
  - [ ] ทดสอบแท็บ All, Fish และ Treasure: กระเป๋าปกติมีช่องว่างตามที่เหลือ กระเป๋า Inf เติมเต็มหน้าจอ เมื่อล้นแล้วเลื่อนได้ และเมื่อของลดลงจนพอดีจะกลับไปด้านบน
- 2026-11-19 — Inventory แสดงช่องว่างทุกหมวด และล้าง NEW เป็นรายกองเมื่อกด หรือเมื่อรูปโหลดแล้วและช่องอยู่ในพื้นที่ที่เห็นอย่างน้อย 75% ต่อเนื่อง 0.6 วินาที
  - [ ] ทดสอบ: เปิด Inventory มีปลาใหม่เกินจอแรก ป้ายของกองที่ยังอยู่นอกจอต้องอยู่ต่อ กดช่องหนึ่งให้ป้ายหายทันที แล้วเลื่อนมาหยุดที่กองอื่นจนป้ายหาย ตรวจช่องว่างครบทั้ง 7 หมวด
- 2026-11-19 — แก้ภาพ Skeleton ค้างทับไอคอนที่โหลดแล้วใน HUD และ Store/Shop โดยยกเลิกภาพชั่วคราวเมื่อโหลดสำเร็จ เปลี่ยนรูป หรือหมดเวลารอ
  - [ ] ทดสอบเปิด Inventory เลื่อนสลับไอเท็ม แล้วเปิด Shop ดูสถานะเหรียญและเจม รูปที่โหลดแล้วต้องไม่จางจาก Skeleton
- 2026-11-19 — Inventory: แถวสุดท้ายเติมช่องฟอง (empty placeholder) จนครบแถวเสมอ แม้กระเป๋าเต็ม — `InventoryController.luau`; ยังไม่ได้ทดสอบใน Play
- 2026-11-19 — C5 Naga Tide HUD: อัปเกรดหน้าต่างลอยด้านบนเป็น Cozy Lake เต็มรูปแบบ (`Controllers/TideEventController.luau`: การ์ด 480x76, ขอบมน 18px, ไอคอน Naga Hatchling, ชิปเวลานับถอยหลัง M:SS, ป้ายทิศทาง+ระยะทาง, ป้ายจำนวนคนตก, แถบเรืองแสงสีเขียวมินต์เมื่ออยู่ในวง IN TIDE: +50% LUCK, และช่อง LOOT พรีวิวปลาพิเศษ Naga Hatchling / Coral Seahorse) — ผ่าน check.mjs สะอาด 100% ไร้ error และไร้อักขระต้องห้าม
- 2026-11-19 — C23 Daily Login: ระบบของขวัญล็อกอิน 7 วันพร้อมหน้าต่าง Cozy Lake 680x480 (`Config/DailyLogin.luau`, `Shared/DailyLogin.luau`, `Services/DailyLoginService.luau`, `UI/Screens/DailyLogin.luau`, `Controllers/DailyLoginController.luau`, `UI/EventActions/DailyLogin.luau`, remote `ClaimDailyLogin`) — รางวัล 7 วัน (Coins, Worms, Gems, Glow Grubs, Pearls, Squid Baits, Day 7 Grand Reward 50 Gems), ระบบนับ Streak และตรวจสิทธิ์รายวันรีเซ็ตเที่ยงคืน UTC, ปลดล็อคการ์ด Daily Login ใน Events hub, bake ลง StarterGui แล้ว — ผ่าน check.mjs สะอาด 100% ไร้ error และไร้อักขระต้องห้าม
- 2026-11-19 — สร้างภาพ Gacha Splash Art ของ Celestial Leviathan (Mythic 5-Star Tidal Guardian) ที่ `assets/art/auras/CelestialLeviathan-splash.png`
  - [x] Done when: ได้ภาพ PNG พื้นหลังโปร่งใสขนาด 1122x1402 เห็นตัวละครเต็มตัวพร้อมตรีศูล วาฬวิญญาณ และมังกรน้ำ
  - [x] ทดสอบ: เปิดภาพตรวจองค์ประกอบเต็มตัว และตรวจค่า alpha ของพื้นหลัง
- 2026-11-19 — Gacha Pure Aura VFX: สร้างออร่า PNG โปร่งใส 6 ภาพ ฉากหลัง 3 ภาพ และภาพแท็บ 3 ภาพจาก `docs/GACHA_ART_PROMPTS.md` เก็บไฟล์ก่อนแทนที่และภาพตัวละครรุ่นเดิมใน `build/gacha-art-pre-vfx/`
  - [x] Done when: ออร่า 1254x1254, ฉากหลัง 1440x900, แท็บ 360x180 และซิงค์ไฟล์ใน Figma Section 3646:54500
  - [x] ทดสอบ: ตรวจความโปร่งใสของไฟล์ออร่า และอ่านเลเยอร์จาก Figma ยืนยันตำแหน่งภาพใหม่ครบ 15 จุดจากการซิงค์ 49 ช่อง
- 2026-11-20 — Gacha (Aura Summon) Redesign v2 ใน Figma ตาม ref เกมกาชา: section ใหม่ "Gacha Redesign v2 — 4 concepts (refs)" (`3660:55300`, x 33000 y 2400) — A Banner Rail, B Editorial Codex, C Poster Strips, D Glass Card; ใช้แค่รูปที่มีอยู่ (gacha_bg_cosmic/celestial/cozy, ลูกแก้วออร่า, ไอคอนสถานะ) และตัวเลขจริงจาก `Config/AuraBanners` (5 Gems/ครั้ง, x10 = 45 Gems การันตี Rare+, pity Legendary 100 / Mythic 300, Neon Tide rate-up); ไม่แตะ section 8 concepts เดิม (`3646:54500`); สคริปต์ `docs/figma/gacha_redesign.py`; ตรวจภาพแล้ว (แก้ชื่อซ้อนปุ่มใน A, ขอบสีซ้อนใน B) ภาพ `docs/figma/gacha_redesign_v2.png`; รอเลือกแบบ; ยังไม่แตะโค้ดเกม
- 2026-11-20 — แยก Gacha Splash 6 ภาพไป `assets/art/auras_Art/` และกู้ไอคอนเดิม 6 ภาพใน `assets/art/auras/` จากแบ็กอัป
  - [x] Done when: ตัวสร้าง Section และเลเยอร์ Splash 6 จุดอ้าง `auras_Art/` ส่วนช่องไอคอนลูกแก้วใน Gacha v2 อ่าน `auras/`
  - [x] ทดสอบ: เทียบไฟล์ไอคอนกับแบ็กอัป ตรวจชื่อและแฮชภาพใน Figma ทั้ง 6 ช่อง Splash และ 11 ช่องไอคอน และรัน `node tools/check.mjs` ผ่าน
- 2026-11-20 — Gacha Redesign v2: เหลือตัวเลือก **A Banner Rail / D Glass Card** (ลบ B, C และ section 4 แบบเดิม `3660:55300`) → section ใหม่ "Gacha Redesign v2 — A / D" (`3660:55808`); แยกรูป 2 ชุดชัดเจน: ไอคอนเล็ก = ลูกแก้ว `art/auras/*` (ทุกออร่า), ภาพใหญ่/ตกแต่ง = ภาพวาด `art/auras_Art/*` (6 ออร่า: AbyssalShadow, CelestialLeviathan, DragonEmperor, LotusNaga, NebulaKoi, SerpentOfTheVoid) ไม่ใช้แทนกัน; เติมรูปใหม่จากโฟลเดอร์ที่คุณแก้แล้ว (ลูกแก้วถูกต้อง), ภาพ `docs/figma/gacha_redesign_v2.png`; ยังไม่แตะโค้ดเกม
- 2026-11-20 — Gacha v2 (A/D): ปุ่ม ROLL x1 / ROLL x10 กลับมาใช้สไตล์ปุ่มเดียวกับทั้งเกม (ปุ่มแบน + ขอบล่าง 5px, x1 สีม่วง Gem, x10 สีทอง, มุม 18) และทำราคาให้ชัด: ชื่อปุ่มซ้าย + แคปซูลราคาสีขอบล่าง ไอคอน Gem 26px ตัวเลข 20px, ป้าย RARE+ ติดมุมขวาบนของ x10; แทนเฉพาะแถวปุ่ม (`3662:56131`, `3662:56146`) ไม่แตะส่วนอื่น; ภาพ `docs/figma/gacha_roll_buttons.png`
- 2026-11-20 — Gacha v2 (A/D) รอบ 3 → section ใหม่ `3662:56161`: ชิป Gems / Star Tokens ไม่มีปุ่ม + แล้ว (กดชิปเปิด Top Up อยู่แล้ว); การ์ดแบนเนอร์ใช้ลูกแก้วออร่าปกติ (`art/auras`); D เปลี่ยนแท็บซ้ายเป็นการ์ดแบนเนอร์แบบ A; ภาพวาด `auras_Art` ใช้เฉพาะภาพหลักด้านขวา (เอาเงาตกแต่งอื่นออก); ภาพ `docs/figma/gacha_redesign_v2.png`; ยังไม่แตะโค้ดเกม
- 2026-11-20 — Gacha v2 แบบ D: Info Card padding 5 (บน/ล่าง) / 10 (ซ้าย/ขวา) ตามที่สั่ง, เนื้อหาข้างในชิดตาม padding เดียวกัน — node ใหม่ `3662:56405`
- 2026-11-20 — Gacha v2 (A/D): เพิ่ม toggle เลือกจ่ายด้วย Gems / Star Tokens เหนือปุ่ม Roll (ตัวที่เลือก = สีส้ม coral) เป็นโหนดใหม่อย่างเดียว ไม่แตะของที่คุณแก้ — A `3662:56450`, D `3662:56457`; ภาพ `docs/figma/gacha_pay_toggle.png`. ยังไม่ได้กำหนดราคาสุ่มด้วย Star Token และปุ่ม Roll ยังแสดงราคา Gems (ยังไม่มีในโค้ด/Config)
- 2026-11-20 — B22 Gacha page ใหม่ตาม Figma concept D + ส่วนจาก E1 (Mythic pity, Milestones, Skip, Auto-roll) ทั้งใน Figma และในโค้ด (`UI/Screens/GachaPage.luau`, `UI/GachaPage.luau`, `GachaPageController.luau`); เพิ่ม `ui/gacha_bg_*` + `auras_Art/*` ลง catalog (ยังไม่อัปโหลด); check ผ่าน; ยังไม่ได้ bake / ทดสอบเพราะ Studio ไม่ได้เปิด
- 2026-11-20 — B22 bake GachaPage ลง Studio แล้ว (ผ่าน StudioBridge `--http-only`), ภาพ edit mode ตรง Figma D; ยังไม่ได้ทดสอบ Play (Roblox Studio MCP ไม่เชื่อม) และยังไม่ได้เซฟ place. หมายเหตุ: `tools/ui/preview.mjs` ใช้ไม่ได้แล้ว (สคริปต์ยาวเกิน 200,000 ตัวอักษร) — ปัญหาเดิม ไม่เกี่ยวกับงานนี้
- 2026-11-20 — B22 รอบ 2: ออกแบบท่าสุ่ม 4 แบบใน Figma (`3664:56516`) คุณเลือกแบบ 1 Altar Charge → ทำในเกมแล้ว (แทน Reel Slot เดิม, การ์ดผลลัพธ์เหมือนเดิม); หน้า Gacha: เอา History ออก, ออร่าเด่นเปิด Item Card, Options มุม 10, ซ่อนหน้า Gacha ระหว่างสุ่ม (แก้ UI ทะลุ); bake แล้ว check ผ่าน; ยังไม่ได้ทดสอบ Play และยังไม่ได้เซฟ place
- 2026-11-20 — B22 รอบ 3: หน้าต่างสุ่ม Altar Charge ทำตาม Figma แบบ 1 ที่คุณแก้ (ไม่มี Rays, แถบผลลัพธ์, Item Card ข้างภาพ, ขนาด 1920x1080) — check ผ่าน, bake แล้ว, ภาพ edit mode ตรงแบบ; ยังไม่ได้ทดสอบ Play
- 2026-11-20 — B22 รอบ 4: Hero/ป้ายชื่อแสดงแค่ออร่าเด่นของตู้; x10 ปุ่ม SEE ALL 10 ไปหน้าสรุปทั้ง 10 (แก้บั๊ก Roll again = x1); เตรียมรูปอัปโหลด 8 รูป + `check_orbs/` 6 รูปสำรอง; check ผ่าน; ยังไม่ได้ทดสอบ Play (Studio plugin หลุดจาก bridge)
- 2026-11-20 — B22: อัปโหลดรูป Gacha 8 รูปแล้ว, แปลงเป็น image id ครบ 8/8, UIAssets 202/203; AbyssalShadow ภาพวาดยังไม่ขึ้น (รอตรวจ); ลูกแก้วเดิม 6 ตัวถูกต้อง ลบ `check_orbs/`
- 2026-11-22 01:10 — สรุปข้อตกลง Game Design 6 ข้อร่วมกับ Game Director: 1) Gamepass Luck x1.25 เท่า 2) ระบบเทรดจำกัด 4 ชิ้น ต้องมี Trade License, ห้ามเทรดออร่า, เทรดเฉพาะปลา/เบ็ด/เหยื่อ, มีระบบ Bound/Unbound และเสียภาษี Coins (Gold Sink) 3) ระบบ Mod เบ็ด (Uncommon+ มี 2 Prefix + 2 Suffix) และระบบ Rod Fusion สลับ Mod ได้เฉพาะเบ็ดชนิดเดียวกัน 4) อัตรา Gems: ปลา Uncommon+ ได้ 1 Gem; ตกมือสุ่มได้ 50 ครั้ง/ชม., ออโต้สุ่มได้ 25-30 ครั้ง/ชม. 5) Rebirth ใช้ Prestige Tree (RP), ล้างปลาในตู้และเหยื่อทั่วไป (แจ้งเตือนขายเป็น Coins), คันเบ็ดและเหยื่อเควสถาวรไม่หาย 6) ระเบียบ AI Workflow: AI ทุกตัวต้องสรุปงานและลง Timestamp ใน docs เสมอ — บันทึกลง docs/DESIGN_DECISIONS_2026-11-21.md เรียบร้อย
- 2026-11-22 01:15 — เพิ่มเติมกฎ Bound/Unbound: ไอเทมที่ได้รับจากการแจกฟรี, โค้ดของขวัญ (Giveaways), หรือรางวัล Season Rewards ทั้งหมดจะถูกตั้งเป็น Bound ถาวร ไม่สามารถนำไปเทรดได้ในทุกกรณี ป้องกันการปั๊มไอดีมาฟาร์มของรางวัลไปขายต่อ
- 2026-11-22 01:22 — ปรับโครงสร้างระบบเหยื่อ Rebirth และ Taxonomy ไอเทม: เหยื่อที่ซื้อด้วยเงินจะหายหมดเมื่อ Rebirth, เหยื่อไม่จำกัด (Unlimited Bait) มาจากเควสยาวแบบ Blox Fruits มีเตือนก่อนหายตอน Rebirth สามารถจ่ายเงินล็อกแท็ก [Rebirth Protected] เพื่อเก็บข้ามรอบได้; กำหนด Taxonomy ไอเทม 7 หมวด (ปลา, เหยื่อ, หีบ, เบ็ด, สาย, ออร่า, Consumables ยาบัฟ/กล่องสุ่ม/วัตถุดิบแปรรูปปลา)
- 2026-11-22 01:30 — เพิ่มกฎป้องกันการกักตุนไอเทมเควส (Anti-Stockpiling & Bound on Use): ไอเทมที่ติดแท็ก [Rebirth Protected] จะกลายเป็น Bound ทันทีห้ามเทรด; เหยื่อที่ถูกกดใช้งานแม้ 1 ครั้งจะติด Bound ทันที; ป้องกันไม่ให้พ่อค้าหรือคนรับจ้างเควสดอง Super Rare ข้ามรอบ Rebirth (หาแล้วต้องรีบขาย ไม่งั้นจะหายเมื่อ Rebirth หรือถ้าล็อกไว้ก็จะขายไม่ได้)
