# Aura Fishing QA

เว็บ static สำหรับทีม QA (ตรวจงาน, วิธีทดสอบ, แจ้ง Ticket) deploy บน GitHub Pages ข้อมูลแบ่งเป็น 2 ส่วน:

| ส่วน | อยู่ที่ | ใครแก้ | ใช้โควตา |
|---|---|---|---|
| งาน, วิธีทดสอบ, ระบบเกม, ประวัติ | `qa/data/qadata.json` (สร้างจาก `docs/TASKS.md`) | Agent | ไม่ใช้ (ไฟล์ใน repo) |
| ผลตรวจ + Ticket + ข้อเสนอ/ไอเดีย | Firestore `qa/state`, `qa/tickets`, `qa/ideas` | ทีม QA และ agent | อ่าน 3 ครั้ง/การเปิดหน้า (แคช 5 นาที) เขียน 1 ครั้ง/การกด |

ไม่มี listener แบบ realtime และไม่มี polling จึงอยู่ในโควตาฟรีของ Firebase (Spark: อ่าน 50,000 / เขียน 20,000 ต่อวัน) สบาย ๆ

## Agent ทำอะไรทุกครั้งที่แก้งาน
1. แก้ `docs/TASKS.md` ตามเดิม (เช็กลิสต์ภาพรวม, หัวข้องานพร้อม `- ทดสอบ:` เป็นข้อ ๆ, บรรทัดใน "บันทึกการอัปเดต")
2. `node qa/tools/build.mjs` สร้าง `qa/data/qadata.json` ใหม่ แล้ว commit ไปกับงาน
   - เผยแพร่เว็บ: `git subtree push --prefix qa origin gh-pages` (ไม่ใช้ GitHub Actions)
3. `node qa/tools/pull.mjs` ดูงานที่ QA ตีว่าไม่ผ่านและ Ticket ที่ยังเปิด
4. แก้บั๊กแล้วแจ้ง: `node qa/tools/fix.mjs T-XXXX "แก้อะไรไป"` (เขียน `qa/data/fixes.json` ให้ QA เห็นว่า "dev แก้แล้ว รอตรวจซ้ำ")

งานที่เปลี่ยนสถานะ/โน้ต/ขั้นตอนทดสอบหลัง QA ตรวจ หน้าเว็บจะติดป้าย "แก้หลังตรวจ" ให้ตรวจซ้ำเอง (เทียบค่า `rev` ใน qadata.json) ไม่ต้องเขียนอะไรลง Firestore

## ข้อเสนอ / ไอเดีย (ฟอรัม)
หน้า "ข้อเสนอ / ไอเดีย" ใช้โพสต์สิ่งที่อยากเพิ่มหรือเปลี่ยน แล้วให้ทีมโหวต (เห็นด้วย/ไม่เห็นด้วย) คอมเมนต์ และเปลี่ยนสถานะ เสนอใหม่ > กำลังคุย > เอา / ไม่เอา > ทำแล้ว แต่ละโพสต์มีหัวข้อ หมวด รายละเอียด และบันทึกเวลาทุกอย่าง (โพสต์, แก้ไขล่าสุด, ความเห็น, ประวัติการแก้ไข/เปลี่ยนสถานะพร้อมชื่อผู้ทำ)

Agent:
- `node qa/tools/pull.mjs` พิมพ์สรุป: ไอเดียที่รอเคาะ (พร้อมคะแนนโหวตและความเห็นล่าสุด) และที่อนุมัติแล้วแต่ยังไม่ได้ทำ
- โพสต์สรุป/รายงานขึ้นฟอรัม: `node qa/tools/post.mjs --title "หัวข้อ" --category system --body "รายละเอียด"` (หรือ `--body-file report.md`)
- ตอบในโพสต์: `node qa/tools/post.mjs --comment I-XXXX --body "ทำแล้วใน ..."`
- ต้องมีบัญชีของ agent (ตั้งครั้งเดียว): Authentication > Sign-in method > เปิด **Email/Password** > Users > Add user (เช่น `agent@yourdomain`) แล้ว **ปิด sign-ups** (Settings > User actions) ใส่อีเมลนี้ใน `qa/firestore.rules` แล้ว Publish และสร้างไฟล์ `qa/.agent.env` (ถูก gitignore) ที่มี `QA_AGENT_EMAIL=...` กับ `QA_AGENT_PASSWORD=...`

**ถ้าเคย Publish rules ไปแล้ว ต้อง Publish ใหม่** ให้มี `ideas` (ไม่งั้นหน้าไอเดียว่างและโพสต์ไม่ได้)

## ตั้งค่าครั้งแรก (ทำครั้งเดียว)
1. [Firebase console](https://console.firebase.google.com) > Add project (ปิด Analytics ได้) > Build > **Firestore Database** > Create (production mode)
2. Build > **Authentication** > Sign-in method > เปิด **Google**
3. Firestore > Rules > วางเนื้อหา `qa/firestore.rules` แก้อีเมลทีม QA ในรายการ `request.auth.token.email in [...]` แล้ว Publish
4. Project settings > Your apps > Web (`</>`) > คัดลอก config ใส่ `qa/config.json` (`apiKey`, `authDomain`, `projectId`, `appId` ค่าเหล่านี้เป็นค่าสาธารณะ ใส่ใน repo ได้)
5. Authentication > Settings > Authorized domains > เพิ่ม `<user>.github.io`
6. `git subtree push --prefix qa origin gh-pages` แล้วไป GitHub repo > Settings > Pages > Source: **Deploy from a branch** > Branch `gh-pages` / `/ (root)` เว็บอยู่ที่ `https://<user>.github.io/<repo>/`

ถ้ายังไม่ตั้ง `config.json` เว็บทำงานในโหมดทดลอง เก็บผลในเบราว์เซอร์ตัวเอง (ไว้ลอง UI)

## ทดลองในเครื่อง
```
cd qa
python -m http.server 8766
```
เปิด http://localhost:8766

## ข้อจำกัดที่ควรรู้
- ทุกคนที่รู้ลิงก์ **อ่าน** ผลตรวจและ Ticket ได้ (ต้องเปิด read เพื่อให้ agent ดึงผ่าน `pull.mjs` ได้โดยไม่ต้องมีรหัส) แต่เขียนได้เฉพาะอีเมลใน rules (ถ้า Firebase project ใช้ร่วมกับแอปอื่น ให้เพิ่มเฉพาะบล็อก `match /qa/{doc}` แทนการวางทับทั้งไฟล์)
- Firestore เก็บผลตรวจทั้งหมดใน 1 เอกสาร และ Ticket ทั้งหมดใน 1 เอกสาร (จำกัด 1 MB ต่อเอกสาร พอสำหรับประมาณหลายพันรายการ) ถ้า Ticket เยอะมากให้ย้ายตัวที่ปิดแล้วไปเก็บ
- GitHub Pages ของ repo แบบ private ต้องใช้แผนเสียเงิน (repo public ใช้ฟรี)
