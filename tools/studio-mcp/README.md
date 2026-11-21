# Studio Bridge (MCP ของเราเอง สำหรับ Roblox Studio)

MCP server (Node/TypeScript) + Studio plugin (Luau) ให้ Claude Code สั่งงาน Roblox Studio ของโปรเจกต์ Aura Fishing ได้
และแก้/เพิ่มคำสั่งเองได้อิสระ (ต่างจาก `Roblox_Studio` ซึ่งเป็น MCP ทางการของ Roblox)

```
Claude Code ──stdio──> dist/server.js ──HTTP 127.0.0.1:3060──<── plugin ใน Studio (long-poll)
```

Plugin เปิด socket เองไม่ได้ เลยใช้วิธี "ถามซ้ำ": plugin เรียก `GET /poll` (ค้างไว้สูงสุด 15 วิ) ได้คำสั่งไปทำ
แล้วส่งผลกลับด้วย `POST /result` ทุกคำสั่งมี id + timeout (ค่าเริ่มต้น 30 วิ)

## ติดตั้ง (ทำครั้งเดียว)

1. Build server (ต้องมี Node 18+ และ bun):
   ```bash
   cd "D:\Roblox Project\Aura Fishing\tools\studio-mcp"
   ```
   ```bash
   bun install
   ```
   ```bash
   npm run build
   ```
2. ติดตั้ง plugin ลง Studio (ใช้ Rojo build เป็น `%LOCALAPPDATA%\Roblox\Plugins\AuraStudioBridge.rbxm`):
   ```bash
   install-plugin.bat
   ```
3. `.mcp.json` ของโปรเจกต์มี entry `StudioBridge` แล้ว → เปิด Claude Code ใหม่ในโฟลเดอร์โปรเจกต์ แล้วกดอนุญาต MCP server "StudioBridge"

## สิ่งที่ต้องกดใน Studio (ครั้งแรก)

1. **ปิดแล้วเปิด Studio ใหม่** (Studio ไม่โหลด plugin ไฟล์ใหม่ระหว่างเปิดอยู่) แล้วเปิดเพลส Aura Fishing
2. ถ้ามีหน้าต่างถามสิทธิ์ของ plugin **"AuraStudioBridge" ขอส่ง HTTP ไปที่ `127.0.0.1`** → กด **Allow**
   - ถ้าเผลอกด Deny: แท็บ **Plugins → Manage Plugins** → หา *AuraStudioBridge* → กดไอคอนแก้สิทธิ์ (รูปดินสอ/Permissions)
     → เปิด **HTTP Requests: 127.0.0.1** ให้เป็น Allowed
   - ไม่ต้องเปิด *Game Settings → Security → Allow HTTP Requests* (อันนั้นสำหรับเกม ไม่เกี่ยวกับ plugin)
3. ที่แท็บ **Plugins** จะมีแถบเครื่องมือ **Studio Bridge** ปุ่ม **Bridge** → กดเพื่อเปิดหน้าต่างสถานะ
   - 🟢 `Connected 127.0.0.1:3060` = พร้อมใช้
   - 🟡 `Waiting for MCP server…` = Studio พร้อมแล้ว แต่ยังไม่มี server (ยังไม่ได้เปิด Claude Code / ยังไม่ได้ build)
   - 🔴 `HTTP to localhost not allowed` = ยังไม่ได้ให้สิทธิ์ตามข้อ 2
   - ปุ่ม **Turn off / Turn on** หยุด/เริ่มเชื่อมต่อ (จำค่าไว้ข้ามรอบ), ช่อง **Port** เปลี่ยนพอร์ตได้ (ต้องตรงกับ `--port=` ใน `.mcp.json`)
   - ด้านล่างเป็น log คำสั่งล่าสุด (OK / ERR)

Plugin ทำงานเฉพาะโหมดแก้ไข (Edit) เท่านั้น ระหว่างกด Play จะไม่รับคำสั่งจากตัวที่อยู่ในเกม

## เครื่องมือ (tools)

| Tool | ทำอะไร |
|---|---|
| `studio_status` | Studio ต่ออยู่ไหม, เพลสไหน |
| `get_tree(path?, depth?, maxNodes?, classFilter?)` | ดูโครงสร้าง instance |
| `find_instances(path?, name?, className?)` | ค้นหาตามชื่อ/คลาส |
| `get_properties(path, properties?)` | อ่าน property + attribute + tag |
| `set_properties(path, props, attributes?, removeAttributes?, addTags?, removeTags?)` | ตั้งค่า (Ctrl+Z ได้) |
| `create_instance(className, parent, props?)` | สร้าง instance (Ctrl+Z ได้) |
| `delete_instance(path)` | ลบ (Ctrl+Z ได้) |
| `get_script_source(path, startLine?, endLine?)` / `set_script_source(path, source, force?)` | อ่าน/เขียนโค้ดสคริปต์ที่ *ไม่ได้* sync จาก Rojo |
| `run_luau(code, timeoutSec?)` | รันโค้ด Luau ในโหมดแก้ไข ได้ค่า `return`, output (print/warn/error) และ error |
| `get_selection` / `set_selection(paths)` | อ่าน/เลือก instance ใน Explorer |
| `mount_ui_module(modulePath, screenGuiName?, solo?)` | พรีวิว UI ที่ export จาก Figma ใน Studio โดยไม่ต้องกด Play |
| `unmount_ui_module(screenGuiName?)` | ลบพรีวิว |

**Path** เขียนแบบจุดจาก DataModel เช่น `Workspace.Map.Dock`, `StarterGui.HUD` (ขึ้นต้น `game.` ได้) ถ้าชื่อมีจุดให้ส่งเป็น array `["Workspace","My.Part"]`

**ค่าแบบ Roblox** ส่งเป็น JSON: `{"Vector3":[x,y,z]}`, `{"UDim2":[xs,xo,ys,yo]}`, `{"Color3":[r,g,b]}` หรือ `"#RRGGBB"`,
enum เป็น `"Center"` หรือ `"Enum.TextXAlignment.Center"`, instance เป็น path string, Font เป็น `"GothamSSm"` หรือ
`{"Font":{"Family":"rbxasset://fonts/families/GothamSSm.json","Weight":"Bold"}}` ถ้า property มีชนิดชัดอยู่แล้ว ส่ง array/string ธรรมดาได้เลย

### เรื่อง Rojo
`ReplicatedStorage.Shared`, `ServerScriptService.Server`, `StarterPlayer.StarterPlayerScripts.Client` ถูก Rojo sync จาก `src/`
- `set_script_source` จะ **ปฏิเสธ** สคริปต์ในนี้ (ให้แก้ไฟล์ใน `src/` แทน) ยกเว้นส่ง `force: true` (Rojo จะเขียนทับอยู่ดี)
- `set_properties`/`create_instance` ในนี้ทำได้แต่จะมี `warning` บอกว่าโดน sync ทับ

### พรีวิว UI จาก Figma
`mount_ui_module("ShopMenu")` หาโมดูลใน `StarterPlayer.StarterPlayerScripts.Client.UI.Generated` (แล้วค่อย `ReplicatedStorage.Shared`)
`require` สำเนาใหม่ทุกครั้ง (ได้โค้ดล่าสุดหลัง Rojo sync) แล้วเรียก `build(screenGui)` ใส่ ScreenGui ชื่อ `FigmaPreview` ใน StarterGui
(ล้างของเก่าก่อน) จะเห็นใน viewport ทันที `solo: true` ซ่อน ScreenGui อื่นชั่วคราว `unmount_ui_module` ลบและคืนค่า
อย่าลืม unmount ก่อน publish (ScreenGui นี้ถูกเซฟลงเพลสถ้ากด Save)

## ทดสอบโดยไม่ผ่าน Claude (เหมือน figma-run.mjs)

```bash
node dist/server.js --http-only
```
แล้วอีกหน้าต่าง:
```bash
node scripts/studio-run.mjs --status
```
```bash
node scripts/studio-run.mjs get_tree "{\"path\":\"Workspace\",\"depth\":1}"
```
```bash
node scripts/studio-run.mjs run_luau "{\"code\":\"return #workspace:GetChildren()\"}"
```
(ถ้า Claude Code เปิด StudioBridge อยู่แล้ว server นั้นถือพอร์ต 3060 อยู่ ใช้ `studio-run.mjs` ได้เลยไม่ต้องเปิด `--http-only`)

ถ้ามีหลายหน้าต่าง Claude Code เปิด MCP นี้พร้อมกัน ตัวแรกถือพอร์ต ตัวอื่นส่งคำสั่งผ่าน `POST /command` ของตัวแรก
และถ้าตัวแรกปิด ตัวถัดไปจะยึดพอร์ตแทนอัตโนมัติ

## พัฒนาต่อ

- เพิ่มคำสั่ง: เขียน handler ใน `plugin/src/Commands.luau` (`Commands.my_cmd = function(params, ctx) ... end`)
  แล้วเพิ่ม `server.tool("my_cmd", ...)` ใน `src/server.ts` → `npm run build` + `install-plugin.bat` (+ restart Studio ถ้าไฟล์ plugin ไม่รีโหลดเอง)
- ตรวจ type ของ plugin:
  ```bash
  cd plugin && D:\tools\rojo\rojo.exe sourcemap default.project.json -o sourcemap.json && luau-lsp analyze --definitions=D:/tools/luau-defs/globalTypes.d.luau --sourcemap=sourcemap.json src
  ```
- ทดสอบ server: `bun test test/` และ `npm run typecheck`
- รายชื่อ property ของแต่ละคลาส (`dist/classes.json`) สร้างจาก `D:/tools/luau-defs/globalTypes.d.luau` ตอน `npm run build`

### ความปลอดภัย
Server ฟังเฉพาะ `127.0.0.1` และทุก request ต้องมี header `X-Studio-Bridge: 1` และต้องไม่มี `Origin`
(เว็บในเบราว์เซอร์จึงสั่ง Studio ไม่ได้) แต่โปรแกรมอื่นในเครื่องเดียวกันสั่งได้ — `run_luau` รันโค้ดด้วยสิทธิ์ plugin

## แมพ Starter Bay (สร้างผ่าน bridge)

`maps/StarterBay.luau` สร้าง `Workspace.Map` + terrain ใน Studio (ไม่ต้องกด Play) พอมี `Workspace.Map` แล้ว
`WorldBuilder` ฝั่ง server จะไม่สร้างแมพเทาๆ ตอนเริ่มเกมอีก รันซ้ำได้ (ลบของเก่าแล้วสร้างใหม่, Ctrl+Z ย้อนได้ทั้งก้อน)

```bash
node scripts/run-file.mjs maps/StarterBay.luau
```
```bash
node scripts/run-file.mjs maps/verify.luau
```

`verify.luau` เช็กสิ่งที่โค้ดเกมต้องการ: `Merchant`+`SellPrompt`, `AuraAltar`+`RollPrompt`, SpawnLocation 1 อัน,
โยนเบ็ดจากปลายท่าเรือ/ชายหาดแล้วตกน้ำใน FishingZone `StarterBay` (ระยะ 14 studs เหมือน `GameConfig.CastDistance`)

ของในแมพ: เกาะกลาง (หญ้าสูง y=6, หาดทราย, ทางเดิน), ท่าเรือ East/West/South (มี `FishingSpots`), แผงพ่อค้า, แท่นออร่า,
ไฟถนน, ต้นไม้/หิน/ดอกไม้ และ `Map.FutureSlots` = จุดจองไว้สำหรับระบบที่ยังไม่ทำ (attribute `System`):
Shop, Quests, Rebirth, Leaderboards, Travel (เรือไปเกาะถัดไป), Boss (สนามบอสกลางทะเล + ทุ่นรอบ)
ทำระบบไหนเสร็จก็หาจุดด้วย `attribute System` แล้ววางของจริงแทน placeholder

**ระวัง:** Studio ตอนนี้เปิด `build/AuraFishing.rbxlx` ซึ่งเป็นไฟล์ที่ `scripts\build.bat` เขียนทับ —
ถ้า build ใหม่ แมพ+terrain ที่เซฟไว้ในไฟล์นั้นหาย (สร้างใหม่ได้ด้วยคำสั่งข้างบน) แนะนำ File → Save As เป็นไฟล์เพลสแยก
แล้วใช้ `scripts\serve.bat` + Rojo Connect เพื่อ sync โค้ดแทนการ build

## แคปภาพ UI ใน Studio (`capture_ui`)

ถ่ายภาพ GUI ที่วาดอยู่ใน viewport โหมดแก้ไข (ต้อง **หยุด Play ก่อน**) เพื่อเทียบกับภาพ export จาก Figma
```bash
node scripts/capture.mjs StarterGui.Menus.Shop shots/shop.png --padding=8
```
ตัวเลือก: `--padding=<GUI units>`, `--no-isolate` (ไม่ซ่อน UI อื่น), `--background=#BFE8E0` (พื้นหลังสีเรียบแทนฉาก 3D),
`--method=print|screen` (ค่าเริ่มต้น auto)

ทำงานยังไง: plugin เปิด target + บรรพบุรุษให้มองเห็น ซ่อน sibling/ScreenGui อื่น (isolate) แล้ววางสี่เหลี่ยม #FF00FF 32×32
ที่มุมซ้ายบนของ viewport (ใน CoreGui) → Node จับภาพหน้าต่าง Studio ด้วย PrintWindow (ไม่ต้องดึง Studio มาข้างหน้า)
หาจุดม่วงเพื่อรู้ตำแหน่ง viewport และ scale (DPI) → ซ่อนจุดม่วง ถ่ายอีกรอบ → crop ตามกรอบ target → คืนค่าทุกอย่าง
(ทั้งหมดอยู่ใน ChangeHistory recording ที่ถูก cancel จึงไม่มีอะไรค้างใน Ctrl+Z, และคืนค่าเองภายใน 30 วิ ถ้า Node ล้ม)

ผลลัพธ์บอก `scale` = จำนวน pixel บนจอต่อ 1 GUI unit (Windows display scaling) ถ้าไม่ใช่ 1 ให้หารก่อนเทียบกับ Figma 1x
GUI ต้องอยู่ใต้ StarterGui (โมดูลที่ generate ให้ mount_ui_module ก่อน)
