# Handoff: UI สำหรับ Economy & Monetization (C12–C19) — 2026-11-17

จาก: session ระบบเกม (server/shared/config) → ถึง: session UI/Figma
เป้าหมาย: ออกแบบใน **Figma ก่อน** ขนานไปกับงานระบบ ฝั่ง server จะส่งข้อมูลตามรูปแบบด้านล่าง (ชื่อ field อาจปรับเล็กน้อยตอนทำจริง — จะแจ้งใน TASKS)
อ้างอิง: `docs/TASKS.md` (C12–C19 + Done when), `docs/BALANCE_PLAN.md`, รูปที่จะ gen: `docs/ART_PROMPTS.md` sheet 10–16

สไตล์: Cozy Lake เดิม (`docs/UI_STYLE.md`), ตัวเลขใหญ่ขึ้น ×10 → ทุกช่องตัวเลขต้องรองรับ **1.2M / 950k** (ใช้ตัวย่อ k/M ตั้งแต่ 10,000)

> **อัปเดต 2026-11-17 (หลังออกแบบ Figma แล้ว — section ใหม่ที่ x14400 / x17000, ภาพ `docs/figma/economy_*.png`):**
> คุณเปลี่ยน: Streak = ป้ายเล็กบนปุ่ม CAST · Boost = วงแหวนนับถอยหลัง · **ตัดวิดเจ็ต "ของชิ้นต่อไป"** · เพิ่มหน้า **17 · Character** (เปลี่ยนอุปกรณ์ ย้ายปุ่ม Equip ออกจาก Shop)
> ข้อมูลจาก server ที่ตกลงกับ session UI:
> - Streak: `CatchResult.Streak` (จำนวน), `CatchResult.StreakBonus` (0–0.5); **ทำจริงแล้ว (C12):** ทุกครั้งที่เปลี่ยนจะมี event `Streak` `{ Streak, Bonus, Lost }` — หลุด = `{ Streak = 0, Lost = true }` (ไม่ได้ส่งผ่าน `FishingState`)
> - Aquarium: `{ Slots, MaxSlots, NextSlotPrice, Fish = { {Uid, Id, Mutation, Weight, Rate} }, Rate, OfflineCapHours }`
> - ใส่บ่อ: `PutInTank({ {Id, Mutation, Count} })` → ตอบสถานะ Aquarium ใหม่; ถ้าช่องหรือจำนวนไม่พอ ปฏิเสธทั้งชุด (`{ ok = false, reason }`)
> - **ทำจริงแล้ว (C14):** RemoteFunction `PutInTank` / `TakeFromTank(uid)` / `BuyTankSlot()` ตอบ `{ ok, reason?, Aquarium = State }`; สถานะจาก snapshot ใช้ `require(Shared.Aquarium).State(profile)` ได้เลย; Pearls = `profile.Pearls` (ทศนิยม → ปัดลง) ส่ง snapshot ทุก 30 วิ ให้ UI นับขึ้นเองด้วย `State.Rate` (ต่อนาที); popup ออฟไลน์ = event `OfflineReward { Seconds, Credited, Pearls, Capped, CapHours }` (ให้ Pearls แล้ว ปุ่ม COLLECT แค่ปิด popup)
> - **ร้าน Robux (C13 ทำจริงแล้ว):** ปุ่มซื้อเรียก event `PromptPass(key)` / `PromptProduct(key)` (key ตาม `Config/Products`); pass ที่มี = `profile.Passes[key]`; **ราคาให้ดึงจริงจาก `MarketplaceService:GetProductInfo`** (Roblox อาจลดราคาตามภูมิภาค — ทดสอบได้ 20/75/179 แทน 25/99/249) ใช้ `Price` ใน config เป็นค่าสำรองตอนโหลดไม่ได้
> - Mastery: `Tracks = { {Id, Stat, Level, Current, Next, Price} }` เป็นตัวเลข → client จัดรูปด้วย `Format.Stat`
> - ดาวออร่า: `profile.Auras.Stars[auraId]` (0–5), `profile.Auras.StarTokens`; ราคาอัปดาวใน `Config/AuraStars` (shared)
> - **ทำจริงแล้ว (C17):** ราคาดาว = `require(Shared.AuraStars).Cost(auraId, stars)` (nil = MAX), stat หลังดาว = `AuraStars.ScaledStats(aura.Stats, stars)`; ปุ่ม = RemoteFunction `StarUpAura(id)` → `ok, message, { Stars, StarTokens }`; ผลสุ่ม `PullAura` แต่ละช่องมี `Tokens` (> 0 = ตัวซ้ำ แสดง "+N Star Token"); pity 2 แถว: `Gacha.Pity[banner]` / `banner.PityPulls` (Legendary) และ `Gacha.PityHard[banner]` / `banner.HardPity.Pulls` (Mythic); อัตราจริง = `Roll.AuraRates(0, banner.RateUp)` → `{ [auraId] = ความน่าจะเป็น 0..1 }`
> - Boost: `profile.Boosts = { Coins = endsAt, Pearls = endsAt }` (unix time)
> - **ทำจริงแล้ว (C6/C19):** เวลาที่เหลือ = `require(Shared.Boosts).Remaining(profile, "Coins")` (วินาที, 0 = ไม่มี), ตัวคูณ = `Boosts.Multiplier(...)`; ราคาขายในหน้า Sell All/Inventory ต้องคูณ `Boosts.Multiplier(profile, "Coins")` ด้วย (server คูณแล้ว); บ่อ: `Aquarium.State().Rate` รวม boost แล้ว + `State.Boost`; popup ออฟไลน์มี `BoostedSeconds`, `BoostPearls`; ร้าน: สินค้าใหม่ `StarterPack` (OncePerPlayer — ซื้อแล้วดู `profile.Purchases.Once.StarterPack`), `BoostCoins`, `BoostPearls`; Infinite Bag: `Inventory.IsInfinite(profile)` → แสดง "∞" แทน `/ 999`; ป้ายชื่อ VIP: อ่าน `player:GetAttribute("Pass_VIP")` (ทุก client เห็น); Sweetheart Rod มี `Exclusive` → Shop ซ่อนจนกว่าจะมี (แก้ใน `MenuFill.fillShop` แล้ว)
> - ปลาขายดี: `{ {FishId, Mult, EndsAt} }` ส่งทุกคนตอนเปลี่ยน/ตอนเข้าเกม
> - **ทำจริงแล้ว (C18):** client เรียก `require(Shared.HotFish).Current()` ได้เองตลอด (ได้ค่าเดียวกับ server ไม่ต้องรอ event) หรือฟัง event `HotFish` (ส่งตอนเข้าเกม + ตอนเปลี่ยน); ป้าย 🔥 บนกอง = `HotFish.Mult(stack.Id) > 1`; ราคาใน Inventory/Sell All ใช้ `Inventory.SellValue` ซึ่งรวมโบนัสแล้ว; บรรทัด "Hot fish bonus +N" = `Inventory.HotBonus(profile, sellMult)`; การ์ด Catch Result: `CatchResult.Hot` (> 1 → ป้าย `HOT x3`), `CatchResult.Value` รวมโบนัสแล้ว; เวลาที่เหลือ = `EndsAt - os.time()`
> - หน้า Rates: client คำนวณเองจาก config (Roll + RateUp ของ banner)
> - Character: ใช้ remote `Equip` เดิม; ถอดเหยื่อ = `Equip("Baits", nil)`
> - **ราคา Robux สรุปแล้ว:** Gems 25/99/249 R$ = 25/110/300 Gems · Starter Pack ให้ 100 Gems · Boost 2x Coins / 2x Pearls 2 ชม. 39 ต่ออัน · Starter Pack 49 · VIP 149 · Auto-Fish Pro 249 · Infinite Bag 349 · Extra Cast ≤ 299 (รอ C4)

---

## 1. HUD (Figma 01) — แก้ของเดิม
| สิ่งที่เพิ่ม/แก้ | รายละเอียด | งาน | รูป |
|---|---|---|---|
| ชิป **Pearls** ข้าง Coins/Gems | ตัวเลขวิ่งขึ้นต่อเนื่อง (idle) + จุดเล็ก "+1.5/นาที" | C14 | `ui/status/pearl` |
| ป้าย **Hot Streak** ข้างปุ่ม CAST | `x7  +35%` ไฟลุกขึ้นเรื่อย ๆ ตามจำนวน; หลุดแล้วดับ (animation หาย) | C12 | `ui/status/hot_streak` |
| ชิป **Boost** ใต้สถิติ | `2x Coins 1:42:10` นับถอยหลัง, มีได้หลายอัน (Coins / Pearls) | C19 | `ui/status/boost` |
| วิดเจ็ต **"ของชิ้นต่อไป"** (แนะนำ) | ชื่อ + รูป + แถบ % เงินที่เก็บได้ (Goal gradient) — กดแล้วเปิด Shop ที่ของนั้น | C12 | ใช้รูปของเดิม |
| ป้ายชื่อ **VIP** เหนือหัว (BillboardGui) | ชื่อสีทอง + มงกุฎเล็ก | C6 | `ui/icons/vip` |

## 2. หน้าจอใหม่
### 2.1 Aquarium (บ่อปลา) — C14
- หน้าต่างขนาดเดียวกับ Shop (760×610) + pager
- ส่วนหัว: Pearls ที่มี, อัตรารวม `+12.5 🫧/นาที`, เพดานออฟไลน์ `4 ชม.` (VIP 12 ชม.)
- ช่องบ่อ (grid): ปลาในบ่อ (รูป, rarity มุมซ้ายบน, mutation, `+1.5/นาที`), ปุ่ม "เอาออก" ; ช่องว่าง = "+"; ช่องล็อก = ราคาขยาย `5,000 🪙`
- ข้อมูลจาก server: `{ Slots, MaxSlots, NextSlotPrice, Fish = { {Id, Mutation, Rate} }, Rate, OfflineCapHours }`

### 2.2 Popup "ระหว่างคุณไม่อยู่" — C14
- โผล่ตอนเข้าเกม: รูป `ui/status/offline_reward`, `ไม่อยู่ 3 ชม. 20 น. → +2,450 🫧` (ถ้าชนเพดานเขียน "เต็มเพดาน 4 ชม. — อัปเพดานได้ใน Mastery / VIP")
- ปุ่ม COLLECT (+ ปุ่ม x2 ด้วย boost ถ้ามี — เผื่อไว้)

### 2.3 Mastery — C15
- 7 การ์ด (Luck, Catch Bar, Reel Power, Auto Wait, Pearl Rate, Offline Cap, Sell Mult): ไอคอน, `Lv.12`, ผล `+12% → +13%`, ราคา `🫧 407`, ปุ่ม UPGRADE (เทาเมื่อไม่พอ)
- ส่วนหัว: Pearls ที่มี + "เลเวลรวม 84"
- ข้อมูล: `{ Tracks = { {Id, Level, Current, Next, Price} } }`
- **ทำจริงแล้ว (C15):** `require(Shared.Mastery).Tracks(profile)` → `{ {Id, Name, Stat, Level, Current, Next?, Price?} }` (Next/Price = nil เมื่อเต็ม → ปุ่มเป็น MAX); ตัวเลขเป็นหน่วย stat → `Format.Stat(Stat, StatDefs[Stat], v)`; "เลเวลรวม" = `Mastery.TotalLevel(profile)`; อัป = RemoteFunction `UpgradeMastery(Id)` → `{ ok, reason?, Tracks, Pearls }`

### 2.4 Store (ร้าน Robux) — C6 + C19
- แท็บ: **Passes** (Infinite Bag 349, Auto-Fish Pro 249, VIP 149, Extra Cast) · **Gems** (25/99/249) · **Boosts** (2x Coins / 2x Pearls 2 ชม. 39 R$) · **Packs** (Starter Pack ซื้อได้ครั้งเดียว)
- การ์ดสินค้า: รูป (`ui/shop/*`, `ui/icons/*`), ชื่อ, ประโยชน์ 1–2 บรรทัด, ปุ่มราคา Robux, สถานะ OWNED / ซื้อแล้ว
- **ต้องมี:** ของสุ่มที่ซื้อด้วย Robux ทางอ้อม (Gems → กาชา) → ปุ่ม "อัตราการสุ่ม" ลิงก์ไปหน้า rates ของกาชา

### 2.5 Starter Pack offer popup — C19
- โผล่ครั้งเดียวหลังผู้เล่นซื้อของชิ้นแรก/เลเวล 3 (ไม่ใช่ตอนเข้าเกมทันที), ปิดได้ทันที, ไม่มีตัวจับเวลาเร่ง
- รูป `ui/shop/starter_bundle` + รายการของ + ปุ่ม 49 R$

## 3. แก้หน้าจอเดิม
| หน้าจอ | แก้อะไร | งาน |
|---|---|---|
| **05/06 Shop** | ป้าย `+3` บนการ์ดของที่ตีบวกแล้ว, ปุ่ม **ENHANCE** (ราคา + stat ก่อน→หลัง), สถานะ MAX; ตัวเลขราคาใหม่ (1.5k, 120k, 900k); ของที่ติดเลเวลแสดง `Lv.12` | C12, C16 |
| ↳ ทำจริงแล้ว (C16) | ข้อมูลการ์ด: `require(Shared.Enhance).State(profile, cat, itemId)` → `{ Level, MaxLevel, Coins?, Pearls?, Stats, NextStats? }` (nil = ตีบวกไม่ได้ เช่น Driftwood/Cotton/Hemp → ไม่ต้องมีปุ่ม; `Coins` nil = MAX); ปุ่ม = RemoteFunction `Enhance(cat, itemId)` → `ok, message, state`; stat ในหน้าร้านควรแสดง `State.Stats` แทน `item.Stats` | C16 |
| **13 Inventory** | ปุ่ม **ใส่บ่อ** บนกองปลา (ข้าง Sell), ป้าย 🔥 `x3` บนกองที่เป็นปลาขายดี, แท็บ Materials (เฟส 2) | C14, C18, C16 |
| **07 Auras** | ดาว ★1–★5 บนการ์ดออร่า, ปุ่ม **อัปดาว** (ใช้ Star Token N อัน), ตัวนับ Star Token ที่หัวหน้าต่าง, stat แสดงตามดาว | C17 |
| **G1/E1 หน้ากาชา** | pity 2 แถว: `Legendary ใน 37` และ `Mythic ใน 263`; x10 การันตี **Rare+** (เปลี่ยนข้อความ); ปุ่ม **Rates** → popup ตารางอัตราจริงทุกออร่า; ผลตัวซ้ำแสดง `+1 Star Token` | C17 |
| **G6 x10 Summary** | ตัวซ้ำแสดงเป็น token แทน NEW! | C17 |
| **04 Catch Result** | ป้าย Streak `x7 +35%` บนการ์ด, ป้าย `HOT x3` ถ้าเป็นปลาขายดี, ราคาตัวเลขใหญ่ขึ้น | C12, C18 |
| **14 Modal (Sell All)** | บรรทัดโบนัสปลาขายดี `Hot fish bonus +12,400`; ตัวเลขยอดขายวิ่ง (count-up) | C18 |
| **12 Main Menu hub** | tile ใหม่: **Aquarium**, **Mastery**, **Store** (+ VIP badge บนโปรไฟล์); Rebirth ป้าย `Lv.50` | C14, C15, C6 |
| ↳ ทำจริงแล้ว (C3) | ปุ่ม Rebirth ทำงานแล้ว (หน้าต่างยืนยัน + remote `Rebirth`); ป้ายเลเวล = `require(Shared.Rebirth).RequiredLevel(profile)` (50, 60, 70 …); ฉายาเหนือหัว = `TitleController` (attribute `Title`) — ถ้าจะทำป้ายชื่อ VIP ให้ต่อในไฟล์เดียวกัน (attribute `Pass_VIP`) | C3 |
| **Naga Tide (C5)** | ทำจริงแล้วแบบ placeholder ใน `Controllers/TideEventController.luau`: แผงบนสุด (ชื่อ, ระยะ + ทิศ, เวลา, จำนวนคนตก, "you're in the tide!"); ข้อมูล: event `TideEvent` `{ Active, Id, Name, Center, Radius, EndsAt, NextStart, Anglers, LuckBonus, Catches = { {Fish, Chance} } }` (เวลาเทียบกับ `workspace:GetServerTimeNow()`); ควรมี: ลูกศรชี้ไปที่วง, นับถอยหลัง "Naga Tide ครั้งต่อไป" ในการ์ด Events (`NextStart`), ป้าย "EVENT" บนการ์ดปลาที่ได้จากวง | C5 |
| **Skills (หน้าต่างใหม่)** | ทำจริงแล้ว (C4): `require(Shared.Skills).State(profile)` → `{ {Id, Name, Stat, Description, Level, MaxLevel, Current, Next?, Cost?} }` (Cost nil = MAX), แต้ม = `Skills.Points(profile)`; ปุ่ม = RemoteFunction `UpgradeSkill(Id)` → `ok, message, { Points, Skills }`; ต้องมีทางเข้า (เช่น tile ใน Main Menu หรือปุ่มในหน้า Character) + จุดแดงเมื่อมีแต้มพอ; การ์ด Catch Result: `CatchResult.Bonus` = ปลาโบนัสจาก Multi-Cast (แสดง "+N bonus fish" + รูปเล็ก) | C4 |
| **E0 Events** | การ์ด Daily Login ใช้ไอคอน `ui/icons/daily_login` | C7 |
| **Quests (หน้าต่างใหม่)** | ทำจริงแล้ว (C7): `require(Shared.Quests).State(profile)` → `{ {Index, Id, Text, Progress, Target, Done, Claimed, RewardGems, Icon?} }` (3 ข้อ), นับถอยหลังรีเซ็ต = `Quests.ResetsIn()` (วินาที); ปุ่ม CLAIM = RemoteFunction `ClaimQuest(Index)` → `ok, message, State`; จุดแดง Main Menu อ่าน `profile.Quests.Unclaimed` อยู่แล้ว; ตอนทำเสร็จเปิด `Features.Quests.Enabled = true` + เพิ่ม action `Quests` ใน `MainMenuController.ACTIONS` | C7 |

## 4. ที่ร้าน Merchant ในแมพ (session แมพ)
- ป้ายกระดาน "HOT FISH" ข้าง `MerchantStall` (BillboardGui/SurfaceGui): รูปปลา 1–2 ตัว, `x3`, เวลาที่เหลือ
- จุดวางบ่อปลา (Aquarium) ใหม่ใน `Map.Slots` → ใส่ `AquariumSlot`

## 5. ไอคอน global (vector ใน Figma, ขาว ย้อมสีได้)
`icon_star` (ดาวออร่า), `icon_star_empty`, `icon_arrow_up` (Upgrade/Mastery), `icon_flame` (streak เล็ก), `icon_infinity`, `icon_timer`, `icon_info` (ปุ่ม Rates)

## 6. ลำดับที่แนะนำสำหรับ Figma
1. HUD (Pearls, Streak, Boost, ของชิ้นต่อไป) + Catch Result streak — ใช้ใน C12 ก่อน
2. Aquarium + Offline popup + Inventory "ใส่บ่อ" (C14)
3. Mastery (C15)
4. Shop Enhance (C16)
5. Auras ดาว + หน้ากาชา pity/Rates (C17)
6. Store + Starter Pack (C6/C19)
7. Hot fish (C18)
