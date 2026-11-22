# Aura Fishing — สถาปัตยกรรมระบบและโครงสร้างไฟล์ทั้งหมด (Systems & File Architecture)

เอกสารฉบับนี้รวบรวมระบบทั้งหมดของเกม **Aura Fishing** โดยแจกแจงโครงสร้างไฟล์ (Server, Client, Shared, Config, UI), หน้าที่การทำงาน, ท่อส่งข้อมูล (Network Remotes), โครงสร้างข้อมูลเซฟ (DataStore Schema) และจุดเชื่อมต่อสำคัญ เพื่อใช้ประกอบการวิเคราะห์และวางแผนการ Rework ระบบในขั้นต่อไป

---

## สารบัญระบบหลัก (Table of Systems)

1. [ภาพรวมสถาปัตยกรรม (High-Level Architecture)](#1-ภาพรวมสถาปัตยกรรม-high-level-architecture)
2. [ระบบวงจรการตกปลาหลัก (Core Fishing Loop)](#2-ระบบวงจรการตกปลาหลัก-core-fishing-loop)
3. [ระบบไอเทม กระเป๋า และหีบสมบัติ (Inventory, Bag & Treasures)](#3-ระบบไอเทม-กระเป๋า-และหีบสมบัติ-inventory-bag--treasures)
4. [ระบบร้านค้า การติดตั้ง และตีบวกอุปกรณ์ (Shop, Equipment & Enhance)](#4-ระบบร้านค้า-การติดตั้ง-และตีบวกอุปกรณ์-shop-equipment--enhance)
5. [ระบบออร่าและกาชา (Auras, Gacha & Star Tokens)](#5-ระบบออร่าและกาชา-auras-gacha--star-tokens)
6. [ระบบบ่อปลาและรายได้ออฟไลน์ (Aquarium & Idle Pearls)](#6-ระบบบ่อปลาและรายได้ออฟไลน์-aquarium--idle-pearls)
7. [ระบบสเตตัส เลเวล สกิล และรีเบิร์ธ (Progression, Skills & Rebirth)](#7-ระบบสเตตัส-เลเวล-สกิล-และรีเบิร์ธ-progression-skills--rebirth)
8. [ระบบเควสต์และกิจกรรมโลก (Quests, Daily Login, Hot Fish & Tide Event)](#8-ระบบเควสต์และกิจกรรมโลก-quests-daily-login-hot-fish--tide-event)
9. [ระบบการเงินจริงและการเติมเงิน (Monetization, Passes & Boosts)](#9-ระบบการเงินจริงและการเติมเงิน-monetization-passes--boosts)
10. [ระบบ UI Framework และการจัดการหน้าต่าง (UI Kit & Menu Manager)](#10-ระบบ-ui-framework-และการจัดการหน้าต่าง-ui-kit--menu-manager)
11. [ระบบบันทึกข้อมูลและซิงค์ข้อมูล (Persistence & Data Pipeline)](#11-ระบบบันทึกข้อมูลและซิงค์ข้อมูล-persistence--data-pipeline)
12. [ตารางความเชื่อมโยงของระบบสำหรับการ Rework (System Impact Matrix)](#12-ตารางความเชื่อมโยงของระบบสำหรับการ-rework-system-impact-matrix)

---

## 1. ภาพรวมสถาปัตยกรรม (High-Level Architecture)

โปรเจกต์ Aura Fishing พัฒนาด้วย **Luau** ภายใต้โครงสร้าง **Rojo 7.7.1** โดยใช้หลักการ:
- **Server Authoritative:** การคำนวณเงิน, โอกาสสุ่ม (Roll), ตรวจสอบเงื่อนไข, อัปเกรด, และการได้ของ ทำที่ Server ทั้งหมด Client ทำหน้าที่แสดงผลและส่งอินพุต
- **Single Stat Pipeline (`Stats.Compute`):** สเตตัสของผู้เล่นทุกชนิด (Luck, ReelSpeed, Resilience, AutoWait, CastRange, ExtraLines) ถูกคำนวณผ่านท่อรวมท่อเดียว โดยรวมผลจาก เบ็ด, สาย, เหยื่อ, ออร่า, ดาวออร่า, Mastery, สกิล, บูสต์ และ Gamepass
- **Data-Driven Design (`Registry.luau`):** สเปกและตัวเลขทั้งหมดอยู่ใน `src/shared/Config/` โดยมี `Registry.luau` ตรวจสอบความถูกต้อง (Validation) ตั้งแต่เริ่มเปิดเกม
- **State Synchronization (`DataSync`):** ข้อมูลผู้เล่น (Profile) ถูกส่งแบบ Snapshot ทางเดียวจาก Server สู่ Client ผ่าน RemoteEvent `DataSync` ทำให้ Client ฝั่ง Controller ตอบสนองต่อการเปลี่ยนแปลงข้อมูลทันที

```
[ Roblox Client ]                                 [ Roblox Server ]
  Controllers & UI Kit <--- (DataSync Snapshot) --- Services (DataService)
       |                                                 |
       +--- (RemoteEvent / RemoteFunction Calls) ------->+ (Authoritative Logic)
                                                         |
                                                  [ Stats.Compute / Roll ]
                                                         |
                                                  [ DataStore Profile ]
```

---

## 2. ระบบวงจรการตกปลาหลัก (Core Fishing Loop)

ควบคุมตั้งแต่การเหวี่ยงเบ็ด, การสุ่มปลา, การรอปลาฮุบเบ็ด, มินิเกมดึงปลา, และการแจกรางวัล

### รายการไฟล์
- **Server:**
  - `src/server/Services/FishingService.luau` (State machine การตก, ตรวจความลึก, ตรวจทิศทางน้ำ, คำนวณเวลารอ, เริ่มมินิเกม, แจกปลา/หีบ/Gems, Multi-Cast)
  - `src/server/Services/HotspotService.luau` (สุ่มจุดฟองปลาสีทอง 4 จุดในน้ำ, ตรวจการเหวี่ยงลงวง, ให้บัฟ Luck +50%)
- **Client:**
  - `src/client/Controllers/FishingController.luau` (ควบคุมอินพุตการกดค้างเล็งเหวี่ยงเบ็ด, แถบพลังเหวี่ยง, ป้าย bite alert "!" บนหัวตัวละคร, วิ่งมินิเกม, ระบบตกออโต้)
  - `src/client/UI/Screens/Minigame.luau` (UI มินิเกมบาร์เขียวจับปลา)
  - `src/client/UI/Screens/CastPopup.luau` (UI ปรับระดับความลึก)
  - `src/client/UI/Screens/HUD.luau` (ปุ่ม CAST, DEPTH, AUTO, SELL ALL)
- **Shared & Config:**
  - `src/shared/Roll.luau` (สูตรสุ่มปลาตามโซน, ขนาดปลา, น้ำหนัก, มูลค่า, การกลายพันธุ์ Mutation)
  - `src/shared/FishingSpot.luau` / `src/shared/PlayArea.luau` (ตรวจจุดยืนริมน้ำและขอบเขตแมพ)
  - `src/shared/Config/Fish.luau` (สถิติปลาทุกสายพันธุ์, โซนที่พบ, น้ำหนักต่ำสุด-สูงสุด)
  - `src/shared/Config/Mutations.luau` (การกลายพันธุ์ เช่น Albino, Golden, Abyssal และตัวคูณราคา)
  - `src/shared/Config/DepthZones.luau` (โซนความลึกน้ำ เช่น Shallow, Twilight, Midnight, Abyss)
  - `src/shared/Config/MinigamePatterns.luau` (พฤติกรรมการเคลื่อนที่ของปลาในมินิเกม)
  - `src/shared/Config/GameConfig.luau` (ค่าคงที่การตก, ตัวคูณ Perfect Cast, Hot Streak, อัตราดรอปหีบ 3%)

### ท่อส่งข้อมูล (Remotes)
- `Cast(depth)` (Client -> Server: เริ่มเหวี่ยงเบ็ด)
- `Hook(token)` (Client -> Server: กดยกเบ็ดเมื่อมี "!")
- `ReelResult(token, success, perfect)` (Client -> Server: ส่งผลมินิเกม)
- `CancelFishing()` / `SetAuto(enabled)` (Client -> Server: ยกเลิก / เปิด-ปิด Auto)
- `Bite(token, { Rarity })` (Server -> Client: แจ้งเตือนปลาติดเบ็ด)
- `StartMinigame(token, params)` (Server -> Client: ส่งค่ามินิเกม)
- `CatchResult(result)` (Server -> Client: แจ้งข้อมูลปลาที่ตกได้)
- `Streak(data)` (Server -> Client: แจ้งสถานะ Hot Streak)

---

## 3. ระบบไอเทม กระเป๋า และหีบสมบัติ (Inventory, Bag & Treasures)

ระบบบริหารช่องกระเป๋า, การรวมกองปลา (Stacking), การขายปลา, และการเปิดหีบสมบัติ

### รายการไฟล์
- **Server:**
  - `src/server/Services/ShopService.luau` (ตรรกะการขายปลาทีละกอง `SellStack`, ขายทั้งหมด `SellAll`, และเปิดหีบ `OpenTreasure`, `OpenAllTreasure`)
  - `src/server/Services/DataService.luau` (โครงสร้าง `profile.Bag` และ `profile.Consumables`)
- **Client:**
  - `src/client/Controllers/InventoryController.luau` (จัดการแสดงผลแท็บกระเป๋า 7 หมวด, การเลือกช่อง, การอัปเกรดกระเป๋า)
  - `src/client/Controllers/CharacterController.luau` (จัดการหน้าตัวละครและช่องสวมใส่อุปกรณ์)
  - `src/client/UI/ItemDetail.luau` / `src/client/UI/Screens/ItemDetail.luau` (การ์ดแสดงรายละเอียดไอเทมเมื่อกดเลือก)
  - `src/client/UI/Screens/Inventory.luau` (หน้าต่างกระเป๋าแบบ Bookmark Tabs)
  - `src/client/UI/Screens/Character.luau` (หน้าต่างสวมใส่อุปกรณ์ตัวละคร)
  - `src/client/UI/VirtualGrid.luau` (ระบบแสดงผลช่องกระเป๋าเฉพาะส่วนที่มองเห็นเพื่อประหยัดทรัพยากร)
- **Shared & Config:**
  - `src/shared/Inventory.luau` (ตรรกะรวมกองปลาชนิด+Mutation เดียวกันสูงสุด 10 ตัว/ช่อง, การหาช่องว่าง, บันไดขนาดกระเป๋า)
  - `src/shared/Config/Treasures.luau` (ตารางดรอปและของรางวัลในหีบสมบัติ)
  - `src/shared/Config/Equipment.luau` (ความจุของกระเป๋าแต่ละระดับ Starter 6 ถึง Hold 30 ช่อง)

### โครงสร้างข้อมูลปัจจุบันในเซฟ
```lua
profile.Bag = {
    {
        Kind = "Fish",          -- "Fish" | "Treasure"
        Id = "Bluegill",        -- รหัสปลา หรือรหัสหีบ
        Mutation = "Golden",    -- รหัส Mutation (ถ้ามี)
        Count = 3,              -- จำนวนในกอง (สูงสุด 10)
        Value = 1500,           -- มูลค่าเงินรวมของกอง
        Best = 2.45,            -- น้ำหนักตัวที่หนักที่สุดในกอง
        New = "guid-string",    -- รหัสกำกับไอเทมใหม่
    }
}
profile.Consumables = {
    Baits = { ["Worm"] = 15 }   -- เหยื่อไม่กินช่องกระเป๋า
}
```

---

## 4. ระบบร้านค้า การติดตั้ง และตีบวกอุปกรณ์ (Shop, Equipment & Enhance)

ระบบซื้อคันเบ็ด, สายเบ็ด, เหยื่อ, การสวมใส่อุปกรณ์ และการตีบวกระดับคันเบ็ด (+1 ถึง +10)

### รายการไฟล์
- **Server:**
  - `src/server/Services/ShopService.luau` (ฟังก์ชัน `Buy`, `Equip`, `Enhance`)
- **Client:**
  - `src/client/Controllers/MenuController.luau` (ควบคุมหน้าต่างร้านค้า Shop)
  - `src/client/Controllers/DialogueController.luau` (ระบบบทสนทนากับ Old Marlin ที่ร้าน)
  - `src/client/UI/Screens/Menus.luau` (หน้าต่าง Shop / Fishdex)
  - `src/client/UI/EnhancePopup.luau` (ป๊อปอัปยืนยันการตีบวกคันเบ็ด)
  - `src/client/UI/Screens/Dialogue.luau` (หน้าต่างคุยกับ NPC)
- **Shared & Config:**
  - `src/shared/Enhance.luau` (สูตรโอกาสสำเร็จ, ค่าใช้จ่าย Coins, สเตตัสที่เพิ่มขึ้นจากการตีบวก)
  - `src/shared/Config/Equipment.luau` (รายการคันเบ็ด, สายเบ็ด, เหยื่อ, ราคา, สเตตัสพื้นฐาน)
  - `src/shared/Config/Dialogues.luau` (บทสนทนาและตัวเลือกของ NPC Old Marlin, Sela)

### โครงสร้างข้อมูลปัจจุบันในเซฟ
```lua
profile.Owned = {
    Rods = { ["BambooRod"] = true, ["CarbonRod"] = true },
    Lines = { ["MonoLine"] = true },
}
profile.Equipped = {
    Rods = "CarbonRod",
    Lines = "MonoLine",
    Baits = "Worm",
}
profile.Enhance = {
    Rods = { ["CarbonRod"] = 3 }, -- เลเวลตีบวกผูกกับ ID คันเบ็ด
}
```

---

## 5. ระบบออร่าและกาชา (Auras, Gacha & Star Tokens)

ระบบสุ่มออร่าจากแท่นบูชา (Altar) หรือหน้าตู้กาชา (Banners), ระบบการันตี (Pity), และระบบอัปเกรดดาวออร่า 1–5 ดาว

### รายการไฟล์
- **Server:**
  - `src/server/Services/AuraService.luau` (ฟังก์ชันสุ่ม `PullAura`, เคลมเป้าหมาย `ClaimMilestone`, สวมใส่ออร่า `EquipAura`, และเพิ่มดาว `StarUpAura`)
- **Client:**
  - `src/client/Controllers/GachaPageController.luau` (หน้าตู้กาชาแบบ Glass Card)
  - `src/client/Controllers/AuraFXController.luau` (แสดงผลพาร์ติเคิลออร่ารอบตัวผู้เล่น, รองรับโหมด Low FX)
  - `src/client/UI/GachaPage.luau` / `src/client/UI/Screens/GachaPage.luau` (หน้าจอหลักตู้กาชา)
  - `src/client/UI/AuraReel.luau` / `src/client/UI/Screens/AuraReel.luau` (แอนิเมชันแท่นชาร์จ Altar Charge)
  - `src/client/UI/AuraRevealMotion.luau` (การระเบิดแสงและการ์ดแสดงผลลัพธ์)
- **Shared & Config:**
  - `src/shared/AuraStars.luau` (ตรรกะการแปลงออร่าซ้ำเป็น Star Tokens และการอัปดาว)
  - `src/shared/Roll.luau` (ฟังก์ชันสุ่มออร่าคำนวณตามเรทและ Pity)
  - `src/shared/Config/Auras.luau` (รายการออร่าทั้งหมด, สเตตัส, โมเดลพาร์ติเคิล)
  - `src/shared/Config/AuraBanners.luau` (ตู้กาชาที่เปิดอยู่, Milestone รางวัล)
  - `src/shared/Config/AuraStars.luau` (ค่าใช้จ่าย Star Tokens และสเตตัสโบนัสของดาว 1–5)
  - `src/shared/Config/Rarities.luau` (ระดับความหายาก สี และน้ำหนักการสุ่ม)

### โครงสร้างข้อมูลปัจจุบันในเซฟ
```lua
profile.Auras = {
    Owned = { ["RadiantSun"] = 1, ["AbyssalShadow"] = 1 },
    Equipped = "RadiantSun",
    TotalRolls = 142,
    Stars = { ["RadiantSun"] = 2 }, -- ระดับดาว
    StarTokens = 15,                -- โทเค็นที่ได้จากตัวซ้ำ
}
profile.Gacha = {
    Pity = { ["Altar"] = 23 },      -- นับรอบ Pity
    PityHard = { ["Altar"] = 123 }, -- Hard pity
    Pulls = { ["Altar"] = 123 },
    Claimed = {},
}
```

---

## 6. ระบบบ่อปลาและรายได้ออฟไลน์ (Aquarium & Idle Pearls)

ระบบนำปลาที่ตกได้มาปล่อยลงบ่อเพื่อสร้างรายได้ไข่มุก (Pearls) แบบเรียลไทม์ต่อวินาที พร้อมระบบสะสมรายได้ขณะออฟไลน์

### รายการไฟล์
- **Server:**
  - `src/server/Services/AquariumService.luau` (เอาปลาใส่บ่อ `PutInTank`, ถอนปลาคืนกระเป๋า `TakeFromTank`, ซื้อช่องบ่อเพิ่ม `BuyTankSlot`, และคำนวณรายได้ออฟไลน์เมื่อผู้เล่นเข้าเกม)
- **Client:**
  - `src/client/Controllers/EconomyController.luau` (ควบคุมการเปิดหน้าต่าง Aquarium, การอัปเดตตัวเลข Pearls แบบ Live per-second)
  - `src/client/UI/AquariumScreen.luau` (หน้าจอหลักของ Aquarium ตามดีไซน์ Figma)
  - `src/client/UI/TankQuantity.luau` (หน้าต่างเลือกปลาจากกระเป๋าเพื่อใส่ลงบ่อ)
- **Shared & Config:**
  - `src/shared/Aquarium.luau` (สูตรคำนวณอัตรา Pearls/วินาที จากน้ำหนักและ Mutation, คำนวณราคาขยายช่อง, สูตรจำกัดเวลาออฟไลน์)
  - `src/shared/Config/GameConfig.luau` (ช่องเริ่มต้น 6 ช่อง, เพดานออฟไลน์พื้นฐาน 4 ชม.)

### โครงสร้างข้อมูลปัจจุบันในเซฟ
```lua
profile.Pearls = 12450.85, -- ค่าไข่มุกสะสม
profile.Aquarium = {
    Slots = 10,
    Fish = {
        {
            Uid = 1,
            Id = "GoldenTrout",
            Mutation = "Golden",
            Weight = 4.2,
            Value = 3500, -- อัตราผลิต Pearls ต่อวินาทีคำนวณจากค่าน้ำหนักและมูลค่านี้
        }
    }
},
profile.LastOnline = 1732278000 -- ใช้เทียบหาเวลาออฟไลน์ตอน Join เกม
```

---

## 7. ระบบสเตตัส เลเวล สกิล และรีเบิร์ธ (Progression, Skills & Rebirth)

ระบบคำนวณสเตตัสตัวละครแบบศูนย์รวม, การเก็บค่าประสบการณ์ (XP), สกิลถาวร, ฉายาเหนือหัว, และระบบรีเบิร์ธ

### รายการไฟล์
- **Server:**
  - `src/server/Services/ProgressionService.luau` (การให้ค่า XP, การเลเวลอัป, แต้มสกิล, ฟังก์ชัน `UpgradeSkill`)
  - `src/server/Services/RebirthService.luau` (การตรวจสอบเลเวลขั้นต่ำ เลเวล 50, ล้างข้อมูลที่กำหนด, เพิ่มรอบรีเบิร์ธและตัวคูณ `Rebirth`)
- **Client:**
  - `src/client/Controllers/SkillsController.luau` (ควบคุมหน้าต่างอัปเกรดสกิล)
  - `src/client/Controllers/TitleController.luau` (วาดฉายาสีทองบนหัวตัวละครตามจำนวนรอบรีเบิร์ธ)
  - `src/client/UI/MasteryScreen.luau` (หน้าจออัปเกรดความชำนาญ 7 สายด้วยไข่มุก)
- **Shared & Config:**
  - `src/shared/Stats.luau` (แกนกลางการคำนวณสเตตัสตัวละครทั้งหมด `Stats.Compute`)
  - `src/shared/Skills.luau` (สกิล Keen Eye, Quick Hands, Multi-Cast)
  - `src/shared/Rebirth.luau` (สูตรเลเวลที่ต้องใช้ 50, 60, 70... และรายชื่อฉายา 5 ระดับ)
  - `src/shared/Mastery.luau` (ตรรกะ Mastery 7 สาย: Luck, Patience, PearlPacing, Resilience, OfflineCap...)
  - `src/shared/Config/Skills.luau` / `src/shared/Config/Mastery.luau` (ตัวเลขสเตตัสและราคา)
  - `src/shared/Config/StatDefs.luau` (นิยามสเตตัสทั้งหมดในเกม)

### โครงสร้างข้อมูลปัจจุบันในเซฟ
```lua
profile.Level = 52,
profile.XP = 1420,
profile.Skills = {
    Points = 2,
    Levels = { ["KeenEye"] = 10, ["MultiCast"] = 1 }
},
profile.Rebirths = 1, -- ตัวคูณ +0.25x ต่อรอบ
profile.Mastery = {
    ["Mastery_Luck"] = 5,
    ["Mastery_OfflineCap"] = 2,
}
```

---

## 8. ระบบเควสต์และกิจกรรมโลก (Quests, Daily Login, Hot Fish & Tide Event)

ระบบภารกิจประจำวัน, ปฏิทินของขวัญล็อกอิน 7 วัน, ระบบปลาขายดีประจำชั่วโมง, และอีเวนต์สุ่มในทะเล

### รายการไฟล์
- **Server:**
  - `src/server/Services/QuestService.luau` (สุ่มเควสต์ประจำวัน 3 ข้อ, ตรวจสอบความคืบหน้า, เคลมรางวัล Gems ผ่าน `ClaimQuest`)
  - `src/server/Services/DailyLoginService.luau` (ตรวจสอบสิทธิ์รายวันรีเซ็ตเที่ยงคืน UTC, นับ Streak 7 วัน ผ่าน `ClaimDailyLogin`)
  - `src/server/Services/TideEventService.luau` (สุ่มเกิดโซน Naga Tide ในทะเลทุก :00/:30 น., คำนวณ Crowd Bonus เมื่อมีผู้เล่นมารวมตัวกันตก)
- **Client:**
  - `src/client/Controllers/QuestController.luau` / `src/client/UI/QuestsScreen.luau`
  - `src/client/Controllers/DailyLoginController.luau` / `src/client/UI/Screens/DailyLogin.luau`
  - `src/client/Controllers/HotFishController.luau` (แสดงป้ายปลาคูณ 3 บนหัวร้านค้าและในกระเป๋า)
  - `src/client/Controllers/TideEventController.luau` / `src/client/UI/Screens/TideEvent.luau`
  - `src/client/Controllers/EventController.luau` / `src/client/UI/Screens/Events.luau` (ศูนย์รวมอีเวนต์ Event Hub)
- **Shared & Config:**
  - `src/shared/Quests.luau` / `src/shared/Config/Quests.luau`
  - `src/shared/DailyLogin.luau` / `src/shared/Config/DailyLogin.luau`
  - `src/shared/HotFish.luau` (คำนวณปลาขายดีแบบ Deterministic อิงจากวันและชั่วโมง UTC ปัจจุบัน)
  - `src/shared/Config/TideEvents.luau` / `src/shared/Config/Events.luau`

---

## 9. ระบบการเงินจริงและการเติมเงิน (Monetization, Passes & Boosts)

ระบบรับชำระเงิน Robux (Game Passes และ Developer Products), สิทธิประโยชน์ VIP และไอเทมบูสต์จับเวลา

### รายการไฟล์
- **Server:**
  - `src/server/Services/MonetizationService.luau` (ประมวลผลใบเสร็จ `ProcessReceipt`, ตรวจสอบ Game Passes, จัดการเปิด-ปิดบูสต์ในเซฟ)
- **Client:**
  - `src/client/Controllers/EconomyController.luau` (เปิดหน้าร้าน Store ตามชิปที่กด, ซื้อบูสต์)
  - `src/client/UI/StoreScreen.luau` (หน้าต่างร้านค้า Store แสดงแท็บ Passes, Gems, Boosts & Packs)
  - `src/client/UI/StarterPackModal.luau` / `src/client/UI/Screens/StarterPackModal.luau` (หน้าต่างเสนอขาย Starter Pack)
- **Shared & Config:**
  - `src/shared/Boosts.luau` (คำนวณเวลาบูสต์คงเหลือ 2x Coins, 2x Pearls)
  - `src/shared/Config/Products.luau` (รหัส ID ของ Pass และ Developer Products, ราคา Robux)

### รายการ Gamepass และสิทธิประโยชน์หลัก
1. **VIP (149 R$):** ฉายา VIP, เพิ่มเพดานออฟไลน์ +8 ชม., สิทธิ์พิเศษ
2. **Infinite Bag (349 R$):** ความจุกระเป๋าไม่จำกัด
3. **Auto-Fish Pro (249 R$):** ลดเวลารอตกออโต้
4. **Extra Cast (รอกำหนดราคา):** เพิ่มสายเบ็ด Extra Lines +1 เส้น

---

## 10. ระบบ UI Framework และการจัดการหน้าต่าง (UI Kit & Menu Manager)

ระบบ Component กลาง, มาตรฐานหน้าต่าง, ธีม Cozy Lake, และตัวคุมลำดับชั้นหน้าจอ

### รายการไฟล์
- **แกนกลาง UI Framework:**
  - `src/client/UI/New.luau` (Cozy Lake Theme, สี, ฟอนต์, ระบบสร้าง UI Instance แบบ Declarative, เอฟเฟกต์ปุ่ม Face+Lip, แอนิเมชัน Pop)
  - `src/client/UI/Window.luau` (`Window.Shell` แกนกลางมาตรฐานของหน้าต่างทั้งหมด มีหัวข้อ ปุ่มปิด X แถบเลื่อน รองรับการปรับขนาดตามหน้าจอ)
  - `src/client/UI/MenuManager.luau` (ตัวจัดการลำดับชั้น 5 ชั้น: Hub, Main, Dialogue, Popup, Modal พร้อมระบบเปิดซ้อน `StackOn` และปุ่มลัด ESC / Gamepad B)
  - `src/client/UI/VirtualGrid.luau` (ระบบเลื่อน Grid แบบ Pool เพื่อรองรับไอเทมจำนวนมากโดยไม่กระตุก)
  - `src/client/UI/Modal.luau` (หน้าต่างยืนยัน Pop-up มาตรฐาน)
- **หน้าจอที่ Bake จาก Figma (`src/client/UI/Screens/`):**
  - HUD, CastPopup, Minigame, AuraReel, GachaPage, Inventory, Character, ItemDetail, MainMenu, Menus (Shop/Fishdex), Modal, StarterPackModal, Dialogue, DailyLogin, Events, TideEvent

---

## 11. ระบบบันทึกข้อมูลและซิงค์ข้อมูล (Persistence & Data Pipeline)

### รายการไฟล์
- **Server:**
  - `src/server/Services/DataService.luau` (สร้าง Template เริ่มต้น, ตรวจสอบความปลอดภัยเซฟ, ทำ Auto-save ทุก 30 วินาที, Session Locking ป้องกันของหาย, จัดการฟังก์ชัน `sanitize()` ย้ายเวอร์ชันเซฟ `SCHEMA_VERSION = 5`)
- **Client:**
  - `src/client/Controllers/DataController.luau` (รับ Snapshot ข้อมูลจากเซิร์ฟเวอร์, กระจายสัญญาณ Signal ให้ Controller และ UI หน้าต่างๆ รีเฟรชแบบเรียลไทม์)

### สรุปฟิลด์ทั้งหมดใน Data Template (Schema v5)
| ฟิลด์ข้อมูล | ชนิดข้อมูล | หน้าที่ |
|---|---|---|
| `Version` | number | เวอร์ชัน Schema เซฟ (ปัจจุบัน = 5) |
| `Coins`, `Gems`, `Pearls` | number | 3 สกุลเงินหลักของเกม |
| `Level`, `XP` | number | ระดับและค่าประสบการณ์ผู้เล่น |
| `Bag` | array | รายการช่องกระเป๋า (Fish, Treasure) |
| `Owned`, `Equipped` | table | อุปกรณ์ถาวรที่ครอบครองและสวมใส่อยู่ |
| `Consumables` | table | ไอเทมใช้หมดไป (เหยื่อ Baits) |
| `Enhance` | table | ระดับการตีบวกของคันเบ็ดและสาย |
| `Auras` | table | ออร่าที่มี, ออร่าที่ใส่, ดาว, Star Tokens |
| `Gacha` | table | รอบ Pity และสถิติการสุ่มของแต่ละตู้ |
| `Aquarium` | table | ขนาดบ่อ และรายการปลาในตู้ Aquarium |
| `Skills` | table | แต้มสกิลและเลเวลสกิล 3 สาย |
| `Rebirths` | number | จำนวนรอบรีเบิร์ธ |
| `Mastery` | table | เลเวล Mastery 7 สาย |
| `Quests` | table | เควสต์ประจำวันและสถานะการเคลม |
| `DailyLogin` | table | วันล็อกอินและสถิติ Streak 7 วัน |
| `Passes`, `Purchases` | table | Gamepass ที่เป็นเจ้าของและประวัติใบเสร็จ Robux |
| `Boosts` | table | บูสต์ที่กำลังทำงานและเวลาสิ้นสุด |
| `Fishdex` | table | สมุดบันทึกสถิติปลาทุกสายพันธุ์ที่เคยตกได้ |
| `LastOnline` | number | เวลาออฟไลน์ล่าสุด (Unix timestamp) |

---

## 12. ตารางความเชื่อมโยงของระบบสำหรับการ Rework (System Impact Matrix)

ตารางสรุปผลกระทบเมื่อเริ่มทำ Rework ตามมติการประชุม [docs/DESIGN_DECISIONS_2026-11-21.md](file:///d:/Roblox%20Project/Aura%20Fishing/docs/DESIGN_DECISIONS_2026-11-21.md):

| ระบบปัจจุบัน | โครงสร้างที่ต้องปรับในการ Rework | ระดับผลกระทบ | ไฟล์หลักที่จะถูกแก้ไข |
|---|---|---|---|
| **Inventory (C2)** | แปลงจากกอง (Stack) เป็น Instance Item เพื่อรองรับระบบเทรด, แท็ก Bound, และตาราง Mod คันเบ็ด | **สูงมาก (แกนกลาง)** | `src/shared/Inventory.luau`, `DataService.luau`, `InventoryController.luau` |
| **Rod Fusion & Mods** | เปลี่ยนระบบคันเบ็ดจาก Boolean ID เป็นคันเบ็ดที่มี UUID ประจำตัว, สุ่ม 2 Prefix + 2 Suffix และระบบทำลายคันรอง | **สูงมาก (ระบบใหม่)** | `src/server/Services/ShopService.luau`, `Equipment.luau`, `Enhance.luau` |
| **Trading System** | สร้างระบบเทรด 4 ช่อง, การตรวจสอบ Trade License, การตรวจจับแท็ก Bound, หักภาษี Coins | **สูง (ระบบใหม่)** | สร้าง `TradeService.luau`, `TradeController.luau`, `TradeScreen.luau` |
| **Rebirth (C3)** | เปลี่ยนจากตัวคูณ Flat เป็น Prestige Tree (RP 3 สาย), เพิ่มเงื่อนไขล้างปลาในตู้ Aquarium และล้างเหยื่อทั่วไป | **สูง** | `src/shared/Rebirth.luau`, `RebirthService.luau`, `AquariumService.luau` |
| **Gear Enhance (C16)** | ปรับให้เลเวลตีบวกผูกกับคันเบ็ดรายชิ้น (UUID) แทนการผูกกับ ID ชนิดเบ็ด | **ปานกลาง** | `src/shared/Enhance.luau`, `ShopService.luau`, `EnhancePopup.luau` |
| **Gems Economy (C12)** | ปรับจูนอัตราดรอป Gems จากปลา Uncommon+ (การันตี 1 Gem) ให้ได้ 250 Gems/ชม. สำหรับตกมือ | **น้อย (ปรับ Config)** | `src/shared/Roll.luau`, `FishingService.luau`, `Quests.luau` |
| **Gamepasses (C6)** | ปรับตัวคูณ Luck ของ Gamepass เป็น x1.25 เท่าตามมติ | **น้อยมาก (ปรับ Config)** | `src/shared/Config/Products.luau`, `Stats.luau` |
| **Core Fishing / Minigame** | ไม่กระทบต่อฟิสิกส์การเหวี่ยงและการเล่นมินิเกม | **ไม่มีผลกระทบ (ปลอดภัย)** | - |
| **Aura & Gacha (C17)** | ไม่กระทบเนื่องจากออร่าแยกโมดูลอิสระและถูกตั้งกฎห้ามเทรดถาวร | **ไม่มีผลกระทบ (ปลอดภัย)** | - |
| **UI Framework (C24/C28)** | Window.Shell และ MenuManager รองรับหน้าต่างระบบใหม่ได้ทันที | **ไม่มีผลกระทบ (ปลอดภัย)** | - |
