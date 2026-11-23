# Handoff: Sound system (BGM + SFX)

สถานะ: แกนระบบเสร็จแล้ว (2026-11-23) ยังไม่มีไฟล์เสียงจริง ทุกเสียงเป็น placeholder `rbxassetid://0` (เงียบ ไม่ error) ผ่าน `node tools/check.mjs` แต่ยังไม่ได้ทดสอบใน Studio

## ไฟล์
| ไฟล์ | หน้าที่ |
|---|---|
| `src/shared/Config/Sounds.luau` | ข้อมูลเสียงทั้งหมด (Buses, Music default, List) เพิ่มเสียง = เพิ่ม entry |
| `src/client/Controllers/SoundController.luau` | เล่นเสียง: Play, PlayAt, PushMusic, PopMusic, SetBusVolume, Stop |
| `src/shared/Registry.luau` | ตรวจ Config/Sounds ตอนเริ่ม (Bus, Id, Volume, Pitch, Cooldown, DefaultTrack) |
| `src/shared/Remotes.luau` | `PlaySound` (server -> client) |
| `DataService` + `ShopService` | Settings.MusicVolume / SFXVolume (บันทึกในเซฟ, ตั้งผ่าน remote `SetSetting`) |

## โครงสร้าง
- SoundGroup `AuraMaster` ใน SoundService มี 3 bus: **Music**, **SFX**, **UI** (UI ใช้ค่า SFXVolume)
- ความดังจริง = `Sound.Volume` (ใน Config) x ความดัง bus
- SFX: สร้าง Sound ต่อครั้ง ทำลายเมื่อจบ มี `Cooldown` (ตัดเสียงรัว) และ `Max` (จำนวนที่เล่นพร้อมกัน ค่าเริ่มต้น 4)
- BGM: ระบบ "คำขอ" ซ้อนกัน `PushMusic(key, track, priority)` อันที่ priority สูงสุด (เท่ากัน = มาทีหลังชนะ) จะ crossfade เข้า `PopMusic(key)` แล้วกลับไปอันถัดไปหรือ `Music.DefaultTrack`
- เสียงที่ id เป็น 0 หรือว่าง = ข้ามเงียบๆ id ที่ไม่มีใน Config = warn ครั้งเดียว
- Hook อัตโนมัติ: เมนูเปิด/ปิด (MenuManager.Changed) เล่น `ui_open` / `ui_close`

## วิธีทำงานต่อ

### 1. ใส่เสียงจริง
1. อัปโหลดไฟล์เสียงเป็น Audio ใน Roblox (Creator Hub หรือ Studio Asset Manager) ได้ asset id
2. ใส่ใน `Config/Sounds.luau` แทน `PLACEHOLDER` เช่น `ui_click = { Id = "rbxassetid://123456", Bus = "UI", ... }`
3. หลายเสียงสุ่ม: ใช้ `Ids = { "rbxassetid://1", "rbxassetid://2" }`
4. สุ่ม pitch เพื่อไม่ให้ซ้ำหู: `Pitch = { 0.95, 1.05 }`
5. ตรวจ: `node tools/check.mjs` (Registry จะบอก key ที่ผิด)

### 1.1 BGM ที่มีไฟล์แล้ว (`assets/bgm/*.mp3`)
- ผูกแล้ว: `bgm_lake` = เพลย์ลิสต์ 3 เพลง (`The_Dock_at_Daybreak`, `Morning_By_The_Dock`, `Afternoon_at_the_Cove`) เล่นต่อกันไปเรื่อยๆ เริ่มจากเพลงสุ่ม (ถ้า `Ids` มีหลายตัวใน Music จะเล่นเป็นเพลย์ลิสต์ ตัวเดียวจะวนซ้ำ)
- ยังไม่ผูก (มีไฟล์แล้ว รอตัดสินใจว่าใช้กับ id ไหน): `Beneath_the_Abyssal_Surge`, `Final_Lap_Confetti`, `High_Tide_Tournament`, `The_Final_Token` ผูกโดยใช้ `tracks("ชื่อไฟล์")` ใน Config/Sounds เช่น `bgm_tide = { Ids = tracks("High_Tide_Tournament"), Bus = "Music", ... }`
- ขั้นตอนอัปโหลด (ผู้ใช้รันเอง ต้องใช้ Open Cloud API key สิทธิ์ Assets Read + Write): `python -I tools/audio/upload_bgm.py --user <UserId>` สคริปต์ถามคีย์แบบซ่อน ไม่บันทึกคีย์ อัปโหลดเป็น Audio ทีละไฟล์ แล้วเขียน id ลง `assets/bgm/ids.json` และ `src/shared/Config/SoundAssets.luau` (ไฟล์ generated ห้ามแก้มือ) ใช้ `--only ชื่อไฟล์,ชื่อไฟล์` เพื่ออัปโหลดเฉพาะบางไฟล์ รันซ้ำได้ (ข้ามไฟล์ที่มี id แล้ว)
- Roblox ตรวจเสียงก่อนอนุมัติ (นาที-ชั่วโมง) ถ้าไฟล์ถูกปฏิเสธจะขึ้น error ในสคริปต์ และเสียงที่ยังไม่ผ่านจะเงียบในเกม

### 2. เพิ่มเสียงใหม่
เพิ่ม entry ใน `Sounds.List` แล้วเรียก `SoundController.Play("id")` จากจุดที่ต้องการ ไม่ต้องแก้ระบบ

### 3. เสียงที่ผูกแล้ว (อัปเดต 2026-11-24) และที่ยังไม่ผูก
ผูกอัตโนมัติใน `SoundController.Init` โดยฟัง remote/สถานะเดิม ไม่ต้องแก้โค้ดเกมส่วนอื่น:
| เสียง | ตัวกระตุ้น |
|---|---|
| `ui_click` | ทุกปุ่มที่ผ่าน `New.HookButton` / `New.Button` (ผ่าน `New.ClickHook`) |
| `ui_open`, `ui_close` | `MenuManager.Changed` |
| `cast`, `splash` | remote `FishingState` = Waiting (splash ช้า 0.35 วิ) |
| `bite` | `FishingState` = Bite |
| `catch`, `catch_rare` | remote `CatchResult` (rare = Tier ของปลา 4 ขึ้นไป) |
| `level_up` | `CatchResult.LevelsGained > 0` |
| `fish_escape` | Notify ที่มีข้อความ "got away" / "line snapped" |
| `tide_alert` | Notify ที่มี "Glowing water" / " rises in " |
| `coin` | Coins ในโปรไฟล์เพิ่มขึ้น |
| `aura_equip` | Auras.Equipped เปลี่ยน |
| `gacha_buildup` + `gacha_common/epic/legendary` | `GachaPageController.playReveal` (ผลตาม Tier ของออร่า, ช้า 1.2 วิหลัง buildup) |
| `dash` | ปิดไว้ (ไม่เข้ากับเกม) เปิดคืนใน DashController |

ผูกเพิ่ม (2026-11-24): `reel_tick` (minigame: ติ๊กตอนกดม้วน ถี่/สูงเมื่อปลาอยู่ในแถบ ช้า/ต่ำเมื่อปลาดึง ใน `FishingController.runMinigame`), `gacha_charge` (กดสุ่มใน `UI/GachaPage` ก่อนเรียก PullAura), `chest_open` (ItemDetail OPEN / OPEN ALL), `star_up` (ItemDetail STAR UP สำเร็จ), `pearl_tick` (Aquarium: ทุก Pearl เต็มที่เพิ่มตอนเปิดหน้าต่าง), `ui_confirm` (ปุ่มยืนยันของ Modal), `ui_error` (Notify สีแดง: `HUD.Notify`)
โค้ด UI เล่นเสียงผ่าน `New.Sfx("id")` (UI เรียก controller ตรงๆ ไม่ได้ SoundController ตั้ง `New.PlaySound` ให้) ทุกเสียงใน Config ผูกครบแล้ว ยกเว้น `dash` (ปิดไว้) ข้อควรระวัง: `fish_escape`/`tide_alert` จับจากข้อความ Notify ถ้าแก้ถ้อยคำในเซิร์ฟเวอร์ต้องแก้ที่นี่ด้วย (ทางที่ดีกว่า: ให้เซิร์ฟเวอร์ยิง `PlaySound` ตรง)

### 3.1 ความหน่วงของเสียง
เสียงสร้างใหม่ทุกครั้งจะเริ่มช้า ~0.2-0.3 วิ ตอนนี้ `SoundController` เก็บ Sound ของ SFX/UI ที่โหลดแล้ว (templates, parked ใน ReplicatedStorage) แล้ว Clone มาเล่น Sound ที่ไม่ได้อยู่ใน Parent จะไม่รายงาน `IsLoaded` ถ้าเสียงหน่วงอีกให้เช็กตรงนี้ก่อน

### 4. เสียงจากฝั่งเซิร์ฟเวอร์
`Remotes.Event("PlaySound"):FireClient(player, "catch_rare")` (ใส่ตำแหน่ง Vector3 เป็น arg ที่ 3 ถ้าต้องการเสียง 3D) client ตรวจ id เอง ถ้าไม่มีใน Config จะ warn

### 4.1 ตัวอย่างโค้ด
```lua
local SoundController = require(script.Parent.SoundController)
SoundController.Play("ui_confirm")
SoundController.PlayAt("splash", bobberPart)           -- 3D ติดกับ Part
SoundController.PushMusic("TideEvent", "bgm_tide", 10)  -- ต้องมี bgm_tide ใน Config (Bus = "Music")
SoundController.PopMusic("TideEvent")
```

### 5. หน้า Settings (ทำแล้ว 2026-11-24: สไลเดอร์ Music / Sound effects ในหน้า "Settings & Credits")
ตอนนี้ปุ่มเมนู Settings ยังเป็น Credits (MainMenuController) เมื่อทำหน้า Settings ให้เพิ่ม slider 2 ตัว แล้วเรียก
`Remotes.Func("SetSetting"):InvokeServer("MusicVolume", 0..1)` และ `("SFXVolume", 0..1)` ค่าจะซิงก์กลับผ่าน DataSync และ SoundController ปรับ bus ให้เอง (ตอนลากสไลเดอร์อยากได้ผลทันทีให้เรียก `SoundController.SetBusVolume` ควบคู่ แล้วค่อยส่ง SetSetting ตอนปล่อย) ตามกติกา Figma first ให้ออกแบบหน้านี้ใน Figma ก่อน

## ข้อจำกัด / ความเสี่ยง
- ยังไม่ได้ทดสอบเล่นจริง เพราะยังไม่มีไฟล์เสียง ควรเริ่มจากใส่ `ui_click` กับ `bgm_lake` แล้วฟังใน Studio
- Mute ตอนหน้าต่างเกมไม่โฟกัส: ไม่ได้ทำ (Roblox จัดการเอง)
- ไม่มีระบบ ducking (ลด BGM ตอนมี SFX/dialogue) ถ้าต้องการให้ทำใน SoundController โดยปรับ `groups.Music.Volume` ชั่วคราว หรือใช้ `SoundGroup` + `DuckingEffect` (Roblox มี `CompressorSoundEffect` sidechain)
- เซฟเก่า: ค่า MusicVolume/SFXVolume ถูกเติมอัตโนมัติ (reconcile) ไม่ต้อง migrate
- ลิขสิทธิ์: เสียงที่ใช้ต้องบันทึกลง `Config/Credits` ถ้า license ต้องการ
