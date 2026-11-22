# Aura Fishing — แผนการพัฒนาระบบไอเทม OOP และการรีเวิร์ก (Item OOP Rework Master Plan)

เอกสารฉบับนี้จัดทำขึ้นเป็นคู่มือและพิมพ์เขียวการทำงาน (Master Implementation Plan) สำหรับ AI Coding Agent ในการรื้อระบบไอเทมเดิม (Stack-based) และสร้างระบบไอเทมใหม่แบบ **Object-Oriented Programming (Item Definition / Model vs ItemInstance)** ครอบคลุมทั้งฝั่ง Shared, Server, Client, DataStore และ UI

---

## 1. วัตถุประสงค์และขอบเขต (Objective & Scope)

1. **เปลี่ยนผ่านสู่ OOP 2 เลเยอร์:**
   - **Layer 1: Item Models (Definitions):** พิมพ์เขียวและสเตตัสคงที่ (Static Blueprint) อยู่ในหน่วยความจำ ไม่เซฟลง DataStore
   - **Layer 2: Item Instances:** อ็อบเจกต์ไอเทมจริงที่ผู้เล่นครอบครอง มีรหัสเฉพาะตัว (UUID), สถานะ Bound, สิทธิ์การเทรด, สิทธิ์การขาย และสเตตัสเฉพาะตัว
2. **ปลาไม่รวมกอง (Fish Non-Stackable):** ปลาทุกตัวที่ตกได้จะนับเป็น 1 ตัวเดี่ยวๆ (`IsStackable = false`, `MaxStack = 1`) มีค่าน้ำหนักจริง, ชนิดการกลายพันธุ์ Mutation, แท็กพิเศษ (Perfect, Hotspot, Manual/Auto) และราคาเฉพาะตัว
3. **คันเบ็ดรองรับ 4 Mods และการหลอม (Rod Modifiers & Fusion Ready):** คันเบ็ดแต่ละคันเป็น Instance เดี่ยว รองรับ 2 Prefix + 2 Suffix และเลเวลตีบวก (+Enhance) รายคัน
4. **รองรับระบบเทรด 4 ช่อง (Trading Ready):** ควบคุมสิทธิ์ด้วย `IsTradable` และ `BoundStatus` (`"Unbound"`, `"Bound"`, `"RebirthProtected"`, `"BoundOnUse"`)
5. **กระเป๋าเป็น Equipment Upgrade ถาวร (ไม่กินช่องกระเป๋า):** กระเป๋าเป็นบันไดการอัปเกรดความจุของตัวละคร (Bag Capacity Ladder: Starter 6, Woven 10, Crate 15, Coolbox 20, Hold 30, Bottomless Infinite) อัปเกรดแล้วถาวร ไม่มีวันย้อนกลับ และไม่ใช้ช่องกระเป๋า
6. **คันเบ็ดซื้อซ้ำเป็นชิ้นๆ ได้ และขายคืนร้านได้ (Multi-Purchase & Sellable Rods):** ยกเลิกระบบซื้อครั้งเดียว คันเบ็ดสามารถซื้อซ้ำได้หลายคันเพื่อนำมาหา Mod หรือใช้เป็นวัตถุดิบหลอม Rod Fusion และสามารถขายคืนร้านค้าแลกเงิน Coins ได้ (`IsSellable = true`)

---

## 2. นโยบายการเคลียร์ข้อมูลเซฟ (Data Reset & Schema v6 Policy)

เนื่องจากระบบไอเทมใหม่เปลี่ยนแปลงโครงสร้างข้อมูลจากเดิมอย่างสิ้นเชิง:
- **ปรับเพิ่มเวอร์ชันเซฟ:** ปรับ `SCHEMA_VERSION = 6` ใน `src/server/Services/DataService.luau`
- **การล้างข้อมูลไอเทมเก่า (Item Data Reset):** ทำการเคลียร์กระเป๋า (`Bag = {}`), อุปกรณ์ที่ครอบครอง (`Owned = {}`), อุปกรณ์ที่สวมใส่ (`Equipped = {}`), และบ่อปลา (`Aquarium.Fish = {}`) เป็นค่าเริ่มต้นใหม่ทั้งหมด
- **คงเหลือข้อมูลความคืบหน้าระยะยาว (Preserved Fields):** คงเหลือเงิน Coins, Gems, Pearls, เลเวล (Level/XP), สกิล (Skills), รอบรีเบิร์ธ (Rebirths), สถิติสมุดปลา (Fishdex), และ Gamepass ที่เคยซื้อไว้ เพื่อไม่ให้กระทบต่อความพยายามของผู้เล่นเดิม

---

## 3. กฎเหล็กในการเขียนโค้ด (Coding Constraints & Rules)

AI Agent ที่เข้ามารับงานนี้ **ต้องปฏิบัติตามกฎต่อไปนี้อย่างเคร่งครัด 100%**:
1. **ห้ามใช้อักขระต้องห้ามเด็ดขาด:** ห้ามใช้เครื่องหมายเช็คถูก, เครื่องหมาย bullet point หรือ emojis ใดๆ ทั้งสิ้นใน UI text, โค้ด, คอมเมนต์, หรือเอกสาร
2. **ภาษาการสื่อสาร:** สื่อสารกับผู้ใช้เป็นภาษาไทย ส่วนโค้ด, คอมเมนต์ และตัวแปรเป็นภาษาอังกฤษล้วน
3. **Type Check ต้องสะอาด 100%:** หลังการแก้ไขทุกขั้นตอน ต้องรันคำสั่งตรวจสอบ:
   ```powershell
   D:\tools\rojo\rojo.exe sourcemap default.project.json -o sourcemap.json
   luau-lsp analyze --definitions=D:/tools/luau-defs/globalTypes.d.luau --sourcemap=sourcemap.json src
   ```
   ผลลัพธ์ต้องไม่มี Error (ยกเว้นคำเตือน `GetRankInGroupAsync` เดิม)
4. **Server Authoritative:** การสร้างไอเทม, การสุ่ม Mod, การขาย, การลบ หรือการโอนย้ายไอเทม ต้องเกิดขึ้นที่ Server เท่านั้น Client ทำได้เพียงส่งคำขอผ่าน Remotes
5. **No Blind Overwrite:** ห้ามเขียนทับโค้ดทั้งไฟล์โดยไม่จำเป็น ให้แก้ไขเฉพาะฟังก์ชันที่เกี่ยวข้อง

---

## 4. โครงสร้างโฟลเดอร์ไฟล์ใหม่ที่จะสร้าง (File Tree)

สร้างโฟลเดอร์ใหม่ทั้งหมดที่ `src/shared/Items/`:

```
src/shared/Items/
  |-- ItemTypes.luau            -- นิยาม Type ทั้งหมด (Definitions, Instances, Enums)
  |-- ItemFactory.luau          -- โรงงานสร้าง Instance (Create, Deserialize, RollMods)
  |-- ItemContainer.luau        -- คลาสจัดการช่องกระเป๋าและคลังไอเทม
  |
  |-- Definitions/              -- Layer 1: Item Blueprint Models
  |     |-- Item.luau           -- Base Definition Class
  |     |-- FishItem.luau       -- สเปกปลา (น้ำหนัก, โซน, อัตราผลิตไข่มุก)
  |     |-- RodItem.luau        -- สเปกคันเบ็ด (Base stats, Mod limits)
  |     |-- LineItem.luau       -- สเปกสายเบ็ด (Max depth, Resilience)
  |     |-- BaitItem.luau       -- สเปกเหยื่อ (Luck, Bite speed, Unlimited)
  |     |-- ConsumableItem.luau -- สเปกน้ำยาบัฟ / กล่อง
  |     +-- TreasureItem.luau   -- สเปกหีบสมบัติ
  |
  +-- Instances/                -- Layer 2: Runtime Item Instances
        |-- ItemInstance.luau   -- Base Instance Class
        |-- FishInstance.luau   -- ข้อมูลปลา (Weight, Mutation, Tags, Value)
        |-- RodInstance.luau    -- ข้อมูลเบ็ด (Enhance, 2 Prefix, 2 Suffix)
        |-- BaitInstance.luau   -- ข้อมูลเหยื่อ (Count, IsUsed)
        +-- ConsumableInstance.luau
```

---

## 5. การออกแบบคลาสและ Type Definitions เชิงลึก

### 5.1 นิยาม Types หลัก (`src/shared/Items/ItemTypes.luau`)

```lua
--!strict
export type ItemCategory = "Fish" | "Rod" | "Line" | "Bait" | "Treasure" | "Consumable" | "Aura"
export type RarityType = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"
export type BoundType = "Unbound" | "Bound" | "RebirthProtected" | "BoundOnUse"

export type ModEntry = {
    Id: string,
    Name: string,
    Stat: string,
    Value: number,
}

export type FishTags = {
    Perfect: boolean?,
    Hotspot: boolean?,
    CaughtMode: string?, -- "Manual" | "Auto"
    Event: string?,
}

export type SerializedItem = {
    UUID: string,
    Id: string,
    Count: number?,
    Bound: BoundType?,
    Tradable: boolean?,
    Sellable: boolean?,
    -- Fish properties
    Weight: number?,
    Mutation: string?,
    Tags: { string }?,
    Value: number?,
    -- Rod properties
    Enhance: number?,
    Prefixes: { ModEntry }?,
    Suffixes: { ModEntry }?,
    -- Consumable / Bait properties
    IsUsed: boolean?,
    UsesLeft: number?,
}
```

### 5.2 Layer 1: Base Model `Item.luau`

```lua
--!strict
local Item = {}
Item.__index = Item

export type ItemDef = {
    Id: string,
    Name: string,
    Description: string,
    Category: string,
    Rarity: string,
    Icon: string,
    BasePrice: number,
    IsStackable: boolean,
    MaxStack: number,
    IsTradable: boolean,
    IsSellable: boolean,
}

function Item.new(data: ItemDef)
    local self = setmetatable({}, Item)
    self.Id = data.Id
    self.Name = data.Name
    self.Description = data.Description or ""
    self.Category = data.Category
    self.Rarity = data.Rarity or "Common"
    self.Icon = data.Icon or ""
    self.BasePrice = data.BasePrice or 0
    self.IsStackable = data.IsStackable or false
    self.MaxStack = if data.IsStackable then (data.MaxStack or 99) else 1
    self.IsTradable = if data.IsTradable ~= nil then data.IsTradable else true
    self.IsSellable = if data.IsSellable ~= nil then data.IsSellable else true
    return self
end

return Item
```

### 5.3 Layer 2: Base Instance `ItemInstance.luau`

```lua
--!strict
local HttpService = game:GetService("HttpService")
local ItemTypes = require(script.Parent.Parent.ItemTypes)

local ItemInstance = {}
ItemInstance.__index = ItemInstance

function ItemInstance.new(id: string, definition: any, customProps: any?)
    local self = setmetatable({}, ItemInstance)
    self.UUID = (customProps and customProps.UUID) or HttpService:GenerateGUID(false)
    self.Id = id
    self._def = definition
    self.Category = definition.Category
    self.Count = (customProps and customProps.Count) or 1
    self.BoundStatus = (customProps and customProps.BoundStatus) or "Unbound"
    self.IsTradable = if customProps and customProps.IsTradable ~= nil then customProps.IsTradable else definition.IsTradable
    self.IsSellable = if customProps and customProps.IsSellable ~= nil then customProps.IsSellable else definition.IsSellable
    self.CreatedAt = (customProps and customProps.CreatedAt) or os.time()
    return self
end

function ItemInstance:GetDefinition()
    return self._def
end

function ItemInstance:CanTrade(): (boolean, string?)
    local def = self:GetDefinition()
    if not def.IsTradable or not self.IsTradable then
        return false, "This item cannot be traded."
    end
    if self.BoundStatus ~= "Unbound" then
        return false, "Bound items cannot be traded."
    end
    if self.IsEquipped then
        return false, "Unequip item before trading."
    end
    if self.IsInTank then
        return false, "Remove fish from aquarium before trading."
    end
    return true, nil
end

function ItemInstance:CanStackWith(other: any): boolean
    local def = self:GetDefinition()
    if not def.IsStackable then
        return false
    end
    if self.Id ~= other.Id then
        return false
    end
    if self.BoundStatus ~= other.BoundStatus or self.IsTradable ~= other.IsTradable then
        return false
    end
    if (self.Count + other.Count) > def.MaxStack then
        return false
    end
    return true
end

return ItemInstance
```

### 5.4 Specialized Instances

#### A. `FishInstance.luau`
- เก็บ: `Weight` (kg), `Mutation` (string?), `Tags` (FishTags), `CalculatedValue` (number)
- เมทอด:
  - `GetSellPrice(multiplier)`: คืนค่าเงิน Coins ที่ได้เมื่อขาย
  - `GetPearlRate()`: คืนค่าอัตราผลิตไข่มุกต่อวินาทีในบ่อปลา
  - `Serialize()`: บันทึกเฉพาะข้อมูลจำเป็น

#### B. `RodInstance.luau`
- เก็บ: `EnhanceLevel` (0–10), `Prefixes` (ตาราง Mod สูงสุด 2 รายการ), `Suffixes` (ตาราง Mod สูงสุด 2 รายการ)
- เมทอด:
  - `GetTotalLuck()`: คืนค่า Luck รวมจากเบ็ด + Enhance + Mods
  - `CanFuseWith(subRod)`: เช็คว่า `self.Id == subRod.Id` หรือไม่
  - `ApplyFusion(subRod, targetSlot, sourceMod)`: นำ Mod จากคันรองมาใส่คันหลัก

---

## 6. แผนการพัฒนาทีละขั้นตอน (Step-by-Step Implementation Roadmap)

การพัฒนานี้แบ่งออกเป็น 6 เฟสตามลำดับความขึ้นต่อกัน (Dependencies):

```
Phase 1: Core OOP Classes (src/shared/Items/)
    |
    v
Phase 2: Registry & Definitions Initialization
    |
    v
Phase 3: DataStore Schema v6 & Migration
    |
    v
Phase 4: Server Systems Refactoring (Fishing, Shop, Aquarium)
    |
    v
Phase 5: Client & UI Adaptation (Inventory, Character, ItemDetail)
    |
    v
Phase 6: Typecheck, Build QA Data & Verification
```

### เฟส 1: สร้างชุดโมดูล OOP ใน `src/shared/Items/`
- [ ] **1.1 สร้าง Type Definitions:** สร้าง `src/shared/Items/ItemTypes.luau`
- [ ] **1.2 สร้าง Base Definitions:** สร้าง `src/shared/Items/Definitions/Item.luau` และคลาสลูก (FishItem, RodItem, LineItem, BaitItem, ConsumableItem, TreasureItem)
- [ ] **1.3 สร้าง Base Instances:** สร้าง `src/shared/Items/Instances/ItemInstance.luau` และคลาสลูก (FishInstance, RodInstance, BaitInstance, ConsumableInstance)
- [ ] **1.4 สร้าง ItemFactory:** สร้าง `src/shared/Items/ItemFactory.luau` ทำหน้าที่ Instantiate, Serialize, Deserialize และ Generate Mod สุ่ม
- [ ] **1.5 สร้าง ItemContainer:** สร้าง `src/shared/Items/ItemContainer.luau` บริหารจัดการลิสต์ช่องไอเทม (Add, Remove, Move, Swap, FindSpace, Filter)

### เฟส 2: เชื่อมโยงเข้าสู่ `Registry.luau`
- [ ] **2.1 โหลด Items เข้า Registry:** ใน `src/shared/Registry.luau` ให้วนลูป Config เดิม (`Config/Fish`, `Config/Equipment`, `Config/Treasures`) แล้วสร้าง Item Definition เก็บไว้ใน `Registry.Items[id]`
- [ ] **2.2 เพิ่มเมทอด Registry:** เพิ่มฟังก์ชัน `Registry.GetItem(id)` และ `Registry.GetItemsByCategory(cat)`

### เฟส 3: ปรับปรุง DataStore และ Schema v6 (`DataService.luau`)
- [ ] **3.1 อัปเกรดเวอร์ชัน:** ใน `src/server/Services/DataService.luau` เปลี่ยน `SCHEMA_VERSION = 6`
- [ ] **3.2 โครงสร้าง Template ใหม่:**
  - `Bag`: เปลี่ยนเป็นลิสต์ของ `SerializedItem`
  - `Equipped`: เก็บ UUID ของคันเบ็ดและสายเบ็ดที่สวมใส่อยู่ (หรือเก็บ Id หากเป็น starter)
- [ ] **3.3 จัดการฟังก์ชัน `sanitize()`:** เมื่อพบผู้เล่นเวอร์ชันเดิม (`v < 6`) ให้ล้าง `Bag = {}`, รีเซ็ตอุปกรณ์กลับเป็นอุปกรณ์เริ่มต้น (Starter Rod, Starter Line, Starter Pouch) และเคลียร์ `Aquarium.Fish = {}`

### เฟส 4: ปรับปรุงระบบฝั่ง Server (Authoritative Services)
- [ ] **4.1 `FishingService.luau`:**
  - ตอนตกปลาได้สำเร็จ ให้ใช้ `ItemFactory.CreateFish(fishId, weight, mutation, tags, value)`
  - สั่ง `ItemContainer.AddItem(profile.Bag, fishInstance)` โดยไม่รวมกอง (1 ตัว = 1 ช่อง)
  - ถ้ากระเป๋าเต็ม ให้แจ้งเตือน "Bag full - the fish was released"
- [ ] **4.2 `ShopService.luau`:**
  - `Buy(categoryId, itemId)`:
    - สำหรับคันเบ็ด (`Rods`): ยกเลิกเงื่อนไข "Already owned" อนุญาตให้ซื้อซ้ำได้เป็นชิ้นๆ ไม่จำกัดจำนวน โดยสร้าง `RodInstance` ชิ้นใหม่ (สุ่ม Mod เริ่มต้นตาม Rarity ถ้ามี) แล้วใส่ลงในกระเป๋า
    - สำหรับกระเป๋า (`Bags`): ทำงานเป็น Equipment Upgrade Ladder ไม่ใส่ของลงในช่องกระเป๋า แต่ปรับระดับความจุ `profile.BagCapacity` ตามขั้นถัดไป (Starter 6, Woven 10, Crate 15, Coolbox 20, Hold 30) และไม่สามารถซื้อย้อนกลับได้
  - `SellItem(uuid)`: ฟังก์ชันใหม่สำหรับขายไอเทมเดี่ยวๆ (เช่น ขายคันเบ็ดที่ไม่ได้ใช้ หรือขายปลาทีละตัว) ได้รับเงิน Coins ตามราคาขาย `item:GetSellPrice()`
  - `SellAll()`: ขายเฉพาะปลาทั้งหมดในกระเป๋า (หีบสมบัติและคันเบ็ดยังคงอยู่)
  - `OpenTreasure`: เปิดหีบและดรอปของรางวัล
  - `Enhance`: ปรับให้อ้างอิงตีบวกตาม UUID ของคันเบ็ด
- [ ] **4.3 `AquariumService.luau`:**
  - `PutInTank`: ย้าย `FishInstance` จากกระเป๋าไปใส่ในตู้ปลา โดยคงข้อมูล Weight, Mutation, Tags และ Value ไว้ครบถ้วน
  - `TakeFromTank`: ย้ายปลากลับเข้ากระเป๋า

### เฟส 5: ปรับปรุงฝั่ง Client และ UI
- [ ] **5.1 `InventoryController.luau`:** ปรับการแสดงผลให้เรียกผ่าน `ItemInstance` และใช้ไอคอน Badge แสดง Tags บนช่อง
- [ ] **5.2 `ItemDetail.luau`:** แสดงสเตตัสละเอียด:
  - ปลา: แสดงป้าย Tags (Perfect / Hotspot / Mutation) และน้ำหนักตัวจริง มีปุ่ม Sell สำหรับขายปลาตัวนั้น
  - คันเบ็ด: แสดงระดับตีบวก +N, รายการ Prefix 2 บรรทัด และ Suffix 2 บรรทัด มีปุ่ม Equip และปุ่ม Sell สำหรับขายคันเบ็ดที่ไม่ใช้
- [ ] **5.3 `VirtualGrid.luau`:** รองรับการ Render รายการปลาจำนวนมากแบบช่องเดี่ยวได้อย่างลื่นไหล

### เฟส 6: การตรวจสอบความสมบูรณ์และ Typecheck
- [ ] **6.1 รัน Luau Type Check:** ตรวจสอบโค้ดด้วย `luau-lsp analyze`
- [ ] **6.2 รัน Build QA Data:** ตรวจสอบความถูกต้องของสเปกด้วย `node qa/tools/build.mjs`
- [ ] **6.3 บันทึกประวัติในเอกสาร:** อัปเดต `docs/TASKS.md` และสรุปผลใน `docs/DESIGN_DECISIONS_2026-11-21.md`

---

## 7. เกณฑ์การตรวจรับงาน (Definition of Done)

งานจะถือว่าเสร็จสมบูรณ์เมื่อ:
1. ปลาทุกตัวที่ตกได้ ไม่รวมกองลงในช่องเดียวกัน ปลาแต่ละตัวมีช่องของตัวเอง มีน้ำหนัก, Mutation และ Tags เฉพาะตัว
2. คันเบ็ดสามารถซื้อซ้ำเป็นชิ้นๆ ได้หลายคันในกระเป๋า มี UUID แยก และสามารถขายคืนร้านค้าได้ (Sell Item)
3. การอัปเกรดกระเป๋าทำงานเป็น Equipment Upgrade Ladder ขยายช่องความจุกระเป๋าถาวร โดยไม่กินช่องกระเป๋า
4. คันเบ็ดรองรับโครงสร้างตาราง 2 Prefix และ 2 Suffix พร้อมสำหรับการทำ Rod Fusion
5. สิทธิ์ `IsTradable` และ `BoundStatus` แสดงผลและตรวจสอบได้อย่างถูกต้อง
6. เซฟเกมโหลดและบันทึกข้อมูล `SCHEMA_VERSION = 6` ได้อย่างราบรื่น ไม่มีข้อมูลตกค้างที่ทำให้เกมแครช
7. รัน `luau-lsp analyze` สะอาด 100% ปราศจาก Error ใหม่
