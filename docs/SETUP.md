# Aura Fishing — วิธี Setup และพัฒนาต่อด้วย Claude

## สิ่งที่ติดตั้งไว้ให้แล้ว
| เครื่องมือ | ที่อยู่ | ใช้ทำอะไร |
|---|---|---|
| Rojo 7.7.1 | `D:\tools\rojo\rojo.exe` | sync โค้ดจากโฟลเดอร์ `src/` เข้า Roblox Studio |
| ปลั๊กอิน Rojo ใน Studio | `%LOCALAPPDATA%\Roblox\Plugins\RojoManagedPlugin.rbxm` | ปุ่ม Rojo ใน Studio |
| luau-lsp + Roblox type defs | scoop + `D:\tools\luau-defs\` | ให้ Claude ตรวจ error โค้ดได้เองก่อนส่งเข้า Studio |
| Roblox Studio MCP | `.mcp.json` ในโฟลเดอร์โปรเจกต์ | ให้ Claude สั่งงาน/อ่าน Studio ได้โดยตรง |

---

## ขั้นที่ 1 — ลองเล่นเลย (เร็วสุด)
1. ดับเบิลคลิก `build\AuraFishing.rbxlx` (ถ้ายังไม่มีไฟล์ ให้รัน `scripts\build.bat` ก่อน)
2. Studio จะเปิดขึ้นมา แล้วกด **Play** (F5)
3. เดินไปที่ขอบเกาะหรือท่าเรือ หันหน้าไปทางน้ำ แล้วกด **CAST** หรือคลิกที่จอ
4. พอขึ้น **"!"** ให้กด **HOOK!** ทันที จากนั้นกดค้างเพื่อให้แถบเขียวทับตัวปลาไว้
5. ขายปลาได้ที่ **Fish Merchant** (กล่องสีเหลือง) หรือกดปุ่ม **SELL ALL**
6. สุ่มออร่าได้ที่ **Aura Altar** (วงกลมสีม่วง) หรือที่เมนู **Auras** มี Gems ให้ตอนเริ่ม 15 (สุ่มได้ 3 ครั้ง)

> ถ้าอยากให้เซฟข้อมูลตอนทดสอบใน Studio: ต้อง Publish เกมก่อน แล้วไปที่ **Game Settings → Security → เปิด "Enable Studio Access to API Services"**
> ถ้าไม่เปิด เกมก็ยังเล่นได้ปกติ แค่จะไม่เซฟข้อมูล

## ขั้นที่ 2 — เชื่อม Rojo แบบ Live Sync (ใช้ตอนพัฒนา)
1. เปิด Studio แล้วเปิดไฟล์ `build\AuraFishing.rbxlx` (หรือจะเปิดเพลสที่ Publish ไว้แล้วก็ได้)
2. ดับเบิลคลิก `scripts\serve.bat` แล้วปล่อยหน้าต่างดำเปิดทิ้งไว้
3. ใน Studio ไปที่แท็บ **Plugins → Rojo → Connect** (ค่าเริ่มต้นคือ localhost:34872)
4. ตั้งแต่นี้ Claude แก้ไฟล์ใน `src/` เมื่อไหร่ Studio จะอัปเดตตามให้ทันที

## ขั้นที่ 3 — เปิด Studio MCP ให้ Claude เข้าไปสั่งงานใน Studio ได้
ส่วนนี้ต้องกดเองใน Studio (ผมกดแทนไม่ได้):
1. เปิด Roblox Studio
2. เปิดหน้าต่าง **Assistant** (แท็บ View หรือไอคอน Assistant มุมขวาบน) → กดไอคอน **⋯ / Settings**
3. เปิดตัวเลือก **"Enable Studio as MCP server"** (บางเวอร์ชันชื่อ "MCP Server")
4. ใน Claude Code app ให้เปิด session ใหม่ แล้วเลือกโฟลเดอร์ `D:\Roblox Project\Aura Fishing`
5. ครั้งแรกจะมีหน้าต่างถามว่าจะใช้ MCP server **Roblox_Studio** จาก `.mcp.json` ไหม ให้กด **Allow / Approve**
6. ทดสอบโดยพิมพ์บอก Claude ว่า *"ดู Explorer ใน Studio หน่อย"* ถ้าตอบได้แปลว่าเชื่อมสำเร็จ

> ถ้าเชื่อมไม่ได้: ให้ปิดแล้วเปิด Studio ใหม่ เช็กว่าเปิด Studio ไว้อยู่ แล้วเริ่ม Claude session ใหม่
> MCP ตัวนี้ใช้ไฟล์ `C:\Users\User\AppData\Local\Roblox\mcp.bat` ที่ Studio ติดตั้งมาให้

## ขั้นที่ 4 — พัฒนาต่อกับ Claude
เปิด session ในโฟลเดอร์โปรเจกต์ แล้ว Claude จะอ่าน `CLAUDE.md` ให้เองอัตโนมัติ ตัวอย่างคำสั่งที่พิมพ์บอกได้เลย:
- "เพิ่มปลาใหม่ 5 ตัวโซน 150–300m ธีมเรืองแสง"
- "ทำระบบ Rebirth ตาม GDD ข้อ 7.2"
- "ทำบอสพญานาคแบบ Co-op ตาม GDD ข้อ 6"
- "เพิ่ม Gamepass VIP +15% Luck"
- "ปรับ UI ให้เล่นบนมือถือสะดวกขึ้น"

Claude จะแก้โค้ด ตรวจ error ด้วย luau-lsp แล้ว build ให้ ส่วนการเทสต์จริงจะทำผ่าน Studio (Rojo หรือ MCP)

## เพิ่ม Content เอง (ไม่ต้องเขียนโค้ด)
ทุกอย่างอยู่ที่ `src/shared/Config/` แค่เพิ่มบรรทัดใหม่ตามรูปแบบเดิม:
- ปลา → `Fish.luau`
- คันเบ็ด / สายเอ็น / กระเป๋า / เหยื่อ → `Equipment.luau`
- ออร่า → `Auras.luau`
- การกลายพันธุ์ → `Mutations.luau`
- ค่าสมดุลเกม (ตัวคูณ 1.5x, เวลารอปลากิน ฯลฯ) → `GameConfig.luau`

ถ้าพิมพ์ผิด (เช่น ใส่ Rarity ที่ไม่มีอยู่จริง) หน้าต่าง Output ใน Studio จะบอกชัดเจนว่าผิดที่บรรทัดไหน

---

## ขั้นที่ 5 — Figma → Roblox UI (FigmaRoblox MCP)
ดัดแปลงมาจาก `cursor-talk-to-figma-mcp` เพิ่มคำสั่งแปลงดีไซน์ใน Figma เป็นโค้ด UI แบบ Luau ใช้ใน Roblox ได้เลย (ปิดระบบส่ง Analytics ของต้นฉบับไปแล้ว)

**ทำครั้งเดียว:**
1. เปิด **Figma Desktop** (ต้องเป็นแอป ใช้บนเว็บเบราว์เซอร์ไม่ได้)
2. ไปที่เมนู **Plugins → Development → Import plugin from manifest…**
3. เลือกไฟล์ `Figma For Roblox\cursor-talk-to-figma-mcp\src\cursor_mcp_plugin\manifest.json`

**ทุกครั้งที่จะใช้:**
1. ดับเบิลคลิก `scripts\figma-relay.bat` แล้วเปิดหน้าต่างค้างไว้
2. ใน Figma ไปที่ **Plugins → Development → Figma to Roblox MCP (Aura Fishing)** แล้วกด **Connect**
3. หน้าต่างปลั๊กอินจะแสดง **ชื่อ Channel** ให้คัดลอกมาบอก Claude
4. ใน Figma คลิกขวาที่ Frame ที่ต้องการ → **Copy link to selection** แล้วส่งลิงก์ให้ Claude
5. Claude จะ export ออกมาเป็นไฟล์ `src/client/UI/Generated/<ชื่อ>.luau` พร้อมรูปภาพใน `assets/ui/<ชื่อ>/`

**ตั้งชื่อ Layer ใน Figma เพื่อบอกวิธีแปลง:**
| ใส่ในชื่อ Layer | ผลใน Roblox |
|---|---|
| `[btn]` หรือขึ้นต้นด้วย `Btn` / `Button` | กลายเป็นปุ่ม (TextButton / ImageButton) |
| `[img]` | แปลงทั้งก้อนเป็นรูปภาพเดียว (เหมาะกับไอคอนหรือของตกแต่งที่ซับซ้อน) |
| `[skip]` | ไม่ export layer นี้ |
| `[scroll]` | กลายเป็น ScrollingFrame |

**ข้อควรรู้:**
- ใช้ **Auto Layout** ได้ จะถูกแปลงเป็น UIListLayout และ UIPadding ให้
- เงา (Drop Shadow) กับ Blur แปลงให้ไม่ได้ ถ้าต้องการให้ตั้งเป็น `[img]` แทน
- ฟอนต์จะถูกแปลงเป็นฟอนต์ที่ Roblox มี เช่น Fredoka One, Gotham, Montserrat, Roboto, Luckiest Guy ฯลฯ ถ้าเป็นฟอนต์ที่ Roblox ไม่มี (เช่น Inter) จะถูกแทนด้วย Builder Sans
- **รูปภาพต้องอัปโหลดขึ้น Roblox เอง:** ใน Studio ไปที่ **Asset Manager → Bulk Import** แล้วเลือกโฟลเดอร์ `assets/ui/<ชื่อ>/` จากนั้นส่ง ID ที่ได้ให้ Claude ใส่ในตาราง `Images` ของไฟล์ที่ export มา
- export ซ้ำได้ตลอด ไฟล์จะถูกเขียนทับ แต่ asset ID ที่ใส่ไว้แล้วจะไม่หาย
