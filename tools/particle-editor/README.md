# Aura Particle Editor

เครื่องมือในเครื่องสำหรับแก้ไฟล์เอฟเฟกต์ JSON แล้วดูผลบนหุ่นอ้างอิง ใช้ Node.js กับ TypeScript และใช้หน้าพรีวิวร่วมกันทุกโปรเจกต์

## เปิดใช้งานบน Windows

ดับเบิลคลิก **AuraParticleEditor.exe** ใน `build/aura-particle-editor/` ตัวเปิดใช้ Node.js 22 ที่ติดตั้งไว้และไฟล์ในโฟลเดอร์ `app` ข้าง EXE จากนั้นเปิด editor เป็นหน้าต่างเบราว์เซอร์

เมื่อแก้ซอร์ส ให้รันจากโฟลเดอร์รากของ Aura Fishing

~~~powershell
npm.cmd --prefix tools/particle-editor run exe
npm.cmd --prefix tools/particle-editor test
~~~

โหมดพัฒนาที่แสดง URL ในเทอร์มินัล

~~~powershell
npm.cmd --prefix tools/particle-editor run build
npm.cmd --prefix tools/particle-editor run start
~~~

คำสั่ง build ใช้ TypeScript ใน `node_modules` ของเครื่องมือหรือของ Figma plugin ในโปรเจกต์

## แก้เอฟเฟกต์

1. กด **Open** เลือก JSON หรือใช้ **New** เริ่มโปรเจกต์ว่าง
2. เลือกเลเยอร์เดิมหรือเพิ่ม **Sprite**, **Emitter** หรือ **Ribbon** ใน Layers จากนั้นเปิดแท็บ **Sheet** กด **Change sheet** เพื่อเลือกไฟล์ภาพ หรือใช้ช่อง **Texture** เลือกภาพที่นำเข้าแล้ว การเปลี่ยนภาพใช้ค่าจำนวนช่อง กรอบตัด และ FPS ของเลเยอร์ที่เลือก
3. ปรับตำแหน่ง ขนาด สี การผสมแสง ความเร็ว และช่วงเฟดใน Properties ใช้ Sheet กำหนดกรอบตัด จำนวนช่อง ช่วงเฟรม และวิธีเล่น Flipbook
4. ลากหัวอ่านเวลาหรือกด Play เพื่อตรวจจังหวะของหลายเลเยอร์ ใช้ Tier เพื่อตรวจเลเยอร์ตามระดับ
5. ใช้ **Save** บันทึกกลับไฟล์เดิม หรือ **Save As** ทำสำเนาที่เก็บพาธอ้างอิงภาพไว้

โปรเจกต์ตัวอย่างใช้ชีตจากเกม [Tidal Bloom](../../assets/vfx/aura/TidalBloom/project.json) [Moonlit Ripple](../../assets/vfx/aura/MoonlitRipple/project.json) [Nebula Koi](../../assets/vfx/aura/NebulaKoi/project.json)

ถ้าจะเพิ่ม Core จากตัวอย่าง ให้เลือก **Fixed core plume** แล้วกด **Duplicate** ก่อนเปลี่ยนชีตในสำเนา ตั้ง **Columns** และ **Rows** ให้ตรงกับภาพ เช่น 4 x 4 สำหรับชีต 16 เฟรม

## นำเอฟเฟกต์เข้า Roblox Studio

ใช้ Local Plugin **Aura Particle Importer** จาก `build/aura-particle-editor/AuraParticleImporter.rbxm` คัดลอกไฟล์ลง `%LOCALAPPDATA%\Roblox\Plugins` แล้วเปิด Studio ใหม่ สร้างไฟล์ปลั๊กอินจากซอร์สได้ด้วย `npm.cmd --prefix tools/particle-editor run studio`

1. เปิดเพลส Aura Fishing ในโหมด Edit แล้วเชื่อม Rojo ให้ตัวเล่นเอฟเฟกต์ใน `src/client` โหลดเข้าเพลส เปิดปลั๊กอินจาก **Plugins > Aura Fishing > Aura Importer**
2. กด **Open project + PNGs** เปิดโฟลเดอร์ของออร่า (เช่น `assets/vfx/aura/TidalBloom`) กด Ctrl+A เลือก `project.json` กับ PNG ทั้งหมดพร้อมกัน ปลั๊กอินจับคู่ภาพตามชื่อไฟล์ อัปโหลดภาพ (ไปที่เจ้าของเพลส หรือบัญชี Studio ถ้าเพลสยังไม่ได้เซฟบนคลาวด์) แล้วสร้าง `ReplicatedStorage.AuraVFX.<AuraId>` ให้ในคลิกเดียว ช่อง **Aura ID** ตั้งจากชื่อโปรเจกต์ ให้ตรงกับ ID ใน `Config.Auras` เช่น `TidalBloom`, `MoonlitRipple` หรือ `NebulaKoi` (แก้ได้ก่อนกด Open ไม่ได้ ให้แก้แล้วกด **Import aura** ซ้ำ)
3. ถ้ามีภาพที่หาไม่เจอหรือชื่อซ้ำ แถวภาพจะค้างให้กด **Choose PNG** หรือ **Use ID** ที่แถวนั้น แล้วกด **Import aura**
4. สวมออร่านั้นใน Play เพื่อตรวจผล นำเข้า ID เดิมซ้ำเพื่ออัปเดตโมเดล และใช้ Undo ใน Studio ย้อนการนำเข้าได้ ภาพที่เคยอัปโหลดแล้วใช้ ID เดิมจากแคช ไม่อัปโหลดซ้ำ [Roblox AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService#CreateAssetAsync) PNG กว้างและสูงไม่เกิน 1024 px

ตัวเล่นในเกมใช้ชั้น Sprite, Emitter และ Ribbon จาก JSON พร้อมกรอบตัด ช่วงเฟรม จังหวะและการเฟด หากเลือก Normalize frames ตัวนำเข้าจะวัดขอบภาพจากพิกเซล เลเยอร์ที่อ่านภาพไม่ได้จะใช้ขนาดเต็มช่องจนกว่าจะนำเข้าใหม่ ภาพอัปโหลดอาจต้องรอ Roblox อนุมัติก่อนแสดงในเกม ส่วนแสงผสมของ Sprite ในเกมขึ้นกับการเรนเดอร์ของ Roblox

รุ่นโปรเจกต์และลำดับงานแก้ต่ออยู่ใน `project.json` ส่วน Aura Model เก็บค่าที่ตัวเล่นในเกมใช้และ Asset ID ของภาพ

## สร้างหรือแก้โปรเจกต์ด้วย AI

โครงสร้างอ้างอิงอยู่ใน [project.schema.json](project.schema.json) `assets` ระบุ ID พาธ และวิธีอ่าน Alpha ส่วน `layers` อ้างภาพด้วย `assetId` และเก็บค่าเวลา ตำแหน่ง และเลเยอร์ไว้ในไฟล์เดียว

- พาธภาพสัมพันธ์กับโฟลเดอร์ของ JSON พาธแบบเต็มใช้กับไฟล์ที่อยู่คนละไดรฟ์ได้
- ใช้ `matte: "luma"` กับชีตขาวบนดำ และ `matte: "rgba"` กับภาพที่มี Alpha ของตัวเอง
- `sheet.first` และ `sheet.last` นับจาก 0 เรียงซ้ายไปขวาและบนลงล่าง โดยรวมเฟรมสุดท้ายด้วย `crop`, `margin` และ `gap` ใช้หน่วยพิกเซล
- ตำแหน่งกับขนาดในฉากใช้หน่วย stud เวลาใช้วินาที และมุมของเลเยอร์ใช้หน่วยองศา
- Editor เฝ้าดูไฟล์ที่เปิดอยู่ เมื่อเซฟ JSON จากเครื่องมืออื่นจะแสดงการเปลี่ยนแปลงให้อัตโนมัติ ถ้ามีงานค้างใน Inspector ให้เลือกโหลดไฟล์ล่าสุดหรือเก็บงานเป็นสำเนา

ตัวอย่างคำสั่งจากโฟลเดอร์รากของโปรเจกต์

~~~powershell
npm.cmd --prefix tools/particle-editor run project -- new "assets/vfx/aura/MyAura/project.json" --name "My Aura"
npm.cmd --prefix tools/particle-editor run project -- add "assets/vfx/aura/MyAura/project.json" sprite --name Core --texture "assets/vfx/aura/MyAura/01_core.png" --columns 4 --rows 4 --fps 14
npm.cmd --prefix tools/particle-editor run project -- duplicate "assets/vfx/aura/MyAura/project.json" "layer-id"
npm.cmd --prefix tools/particle-editor run project -- validate "assets/vfx/aura/MyAura/project.json"
~~~

ให้สร้างโฟลเดอร์ `MyAura` และเตรียมไฟล์ภาพก่อนใช้ตัวอย่างนี้ คำสั่ง `add` และ `duplicate` คืน ID ของเลเยอร์ในรูป JSON

## ส่วนประกอบของซอร์ส

| ส่วน | หน้าที่ |
| --- | --- |
| [Model](src/model.ts) | ค่าเริ่มต้น รูปแบบข้อมูล และการตรวจ JSON |
| [Renderer](src/render) | การตัดชีต ฉากพรีวิว กล้อง และการวาดเลเยอร์ |
| [UI](src/ui) | Layers, Inspector, Texture sheet และ Timeline |
| [Server](src/server) | เปิดและเซฟไฟล์ แก้พาธภาพ และเฝ้าดูการแก้จากภายนอก |
| [Windows launcher](pack) | สร้าง `AuraParticleEditor.exe` และเปิด editor จาก Windows |

## เพิ่มออร่าตัวใหม่ (ขั้นตอนสั้น)

1. ทำโปรเจกต์ใน Particle Editor เก็บ `project.json` กับ PNG ทุกใบไว้ในโฟลเดอร์เดียวกัน เช่น `assets/vfx/aura/MyAura/`
2. สร้างภาพพร้อมอัปโหลดแล้วใช้คำสั่งนี้ ภาพจะอยู่ใน `MyAura/export/`

~~~powershell
python -I tools/particle-editor/scripts/luma_export.py assets/vfx/aura/MyAura/project.json
~~~

3. อัปโหลดทุกไฟล์ใน `export/` (Asset Manager > Bulk Import หรือให้ Claude อัปโหลดผ่าน Studio MCP) แล้วจด Asset ID ของแต่ละไฟล์
4. ในปลั๊กอิน กด **Open project + PNGs** เลือก `project.json` กับ PNG ในโฟลเดอร์ออร่า ตรงแถวภาพใส่ ID ในช่อง **Use ID** ให้ครบ แล้วกด **Import aura**
5. ไฟล์ที่ลงท้าย `_beam.png` คือภาพของเลเยอร์ ribbon (หมุน 90 องศา เพราะ Beam ของ Roblox ใช้ภาพแนวตั้ง) ให้ใส่ ID ของไฟล์นี้ที่แถวภาพนั้น ตัวเล่นในเกมใช้ Beam กับภาพชนิดนี้ ส่วน ribbon ที่ใช้ flipbook หรือ crop จะใช้แผ่นบางแทน
6. ออร่าต้องมีชื่อเดียวกับ ID ใน `Config.Auras` แล้วสวมใน Play เพื่อตรวจ
