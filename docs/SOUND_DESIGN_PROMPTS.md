# Aura Fishing — Sound Design & AI Audio Prompts Guide

แนวทางการ Generate เสียงและดนตรีประกอบเกม Aura Fishing ด้วย AI (เช่น Suno, Udio, ElevenLabs, Stable Audio, AudioCraft)
โดยออกแบบให้อัดรวมเป็น Sound Reel ความยาว 30–60 วินาทีต่อ 1 ไฟล์ เพื่อประหยัดเวลา/โควตา แล้วนำมาตัดแยกคลิปเสียง (Split / Trim) ทีเดียว

---

## สรุปภาพรวมไฟล์ที่จะ Generate (ทั้งหมด 4 ไฟล์)

1. **File 1 (BGM): Cozy Lake Fishing Theme**
   - ความยาว: 1:30 – 2:00 นาที (Loop ได้)
   - แนวเพลง: Cozy fantasy, Acoustic guitar, Kalimba, Gentle seaside ambient

2. **File 2 (SFX Reel 1): Fishing & Minigame Pack**
   - ความยาว: ~45–60 วินาที
   - รวม 6 เสียงหลัก: เหวี่ยงเบ็ด, ทุ่นตกน้ำ, ปลากินเบ็ด (!), รอกหมุนสู้ปลา, ดึงปลาขึ้นจากน้ำ, ได้ปลาทั่วไป

3. **File 3 (SFX Reel 2): Gacha & Dopamine Jackpot Pack**
   - ความยาว: ~60 วินาที
   - รวม 6 เสียงลุ้น/ฟิน: สล็อตหมุน, Riser ลุ้นเกือบโดน, เปิดได้ Legendary/Mythic ชนะใหญ่, Star Up ดาวขึ้น, Ka-ching เงิน/เพชร, เปิดกล่องสมบัติ

4. **File 4 (SFX Reel 3): UI & Cozy Interaction Pack**
   - ความยาว: ~30–40 วินาที
   - รวม 5 เสียงอินเตอร์เฟซ: กดปุ่มไม้นุ่มๆ, หน้าต่างเด้งเปิด/ปิด, เก็บไข่มุกฟองสบู่, ขายปลาหมดกระเป๋า

---

## 1. File 1 (BGM): Cozy Lake Fishing Theme

### แนวคิด & อารมณ์
- อารมณ์แบบ Animal Crossing, Genshin Impact (Fontaine Port), Slime Rancher
- ผ่อนคลาย อบอุ่น ฟังสบายได้เรื่อยๆ ไม่น่าเบื่อ ไม่มีท่อนดรอปหนักๆ ให้เสียสมาธิตกปลา
- จังหวะช้าปานกลาง (85 BPM) เครื่องดนตรีโปร่ง กีตาร์โปร่ง คาลิมบา และเสียงคลื่นเบาๆ

### Prompt แนะนำ (สำหรับ Suno / Udio)

```text
[Style: Cozy acoustic fantasy, lo-fi seaside folk, peaceful video game town theme, warm fingerstyle acoustic guitar, gentle kalimba, soft bamboo flute melody, light percussion, calm ambient water ripples, relaxed tempo 85 bpm, nostalgic, wholesome, pastoral, clean instrumental mix, loopable, no vocals]
```

#### Suno / Udio Settings:
- **Instrumental:** On (ไม่มีเสียงร้อง)
- **Title:** Aura Fishing - Cozy Lake Boardwalk
- **Style Tags:** `Acoustic, Fingerstyle Guitar, Kalimba, Cozy Fantasy, Wholesome, Game Soundtrack`

---

## 2. File 2 (SFX Reel 1): Fishing & Minigame Pack (รวมใน 1 ไฟล์)

ให้ AI Generate เป็นเสียง SFX ต่อเนื่อง โดยแต่ละเสียงห่างกัน 3-5 วินาที เพื่อให้มองเห็นคลื่นเสียงใน Audacity / CapCut ชัดเจนและตัดง่าย

### Prompt แนะนำ (สำหรับ Stable Audio / ElevenLabs Sound Effects)

```text
A sequence of 6 distinct video game fishing sound effects separated by pauses:
1. Quick smooth fishing rod swing whoosh followed by high-speed line zipping out
2. Soft water plop and gentle ripple splash of a bobber landing
3. Cute crisp bubble pop with an alert chime ding for fish bite
4. Fast rhythmic mechanical fishing reel clicking and ratchet tension ticking
5. Heavy water splash and wet fish flopping onto a wooden dock
6. Cheerful ascending 3-note glockenspiel chord for a successful catch
Clean foley, game audio, studio quality, punchy, cute, satisfying, no background music
```

### ไทม์ไลน์เสียงในไฟล์ (นำไปตัดแยก)
- **0:00 – 0:04:** `sfx_rod_cast` — เสียงเหวี่ยงเบ็ด ฟึ่บ + สายเบ็ดหมุนพุ่งออกไป
- **0:07 – 0:11:** `sfx_water_plop` — เสียงทุ่นตกกระทบผิวน้ำ จ๋อม เบาๆ
- **0:14 – 0:18:** `sfx_fish_bite` — เสียงปลาฮุบเบ็ด ป๊อป + กริ๊ง แจ้งเตือนตกใจแบบน่ารัก
- **0:21 – 0:27:** `sfx_reel_ticks` — เสียงหมุนรอก ดังกริ๊กๆๆๆ ถี่ๆ รัวๆ มีแรงต้าน
- **0:30 – 0:35:** `sfx_catch_pull` — เสียงกระชากปลาพ้นผิวน้ำ ซ่าา + ตัวปลาดิ้นดุ๊กดิ๊ก
- **0:38 – 0:43:** `sfx_catch_success` — เสียงคอร์ดสดใส 3 โน้ต แสดงความยินดีที่ตกได้

---

## 3. File 3 (SFX Reel 2): Gacha & Dopamine Jackpot Pack (เสียงลุ้นฟิน)

เสียงหมวดนี้เน้น Dopamine Trigger: มีเสียง build-up ความตื่นเต้น และเสียงระเบิดความสุขตอนเปิดได้ของแรร์

### Prompt แนะนำ (สำหรับ Stable Audio / ElevenLabs Sound Effects)

```text
A sequence of 6 high-dopamine gacha and reward sound effects separated by pauses:
1. Rapid magical slot machine ticking and orb spinning clicks, gradually slowing down
2. Low suspenseful heartbeat riser with shimmering celestial pitch sweep building tension
3. Grand jackpot reveal fanfare: sparkling golden harp glissando into an ethereal crystal boom and triumphant angelic bell chime
4. Shimmering star upgrade sound: sparkling magic dust with ascending golden power-up chime
5. Satisfying casino coin cascade and bright Ka-ching cash register bell with tumbling gold coins
6. Antique wooden treasure chest squeak opening followed by radiant magical burst
Satisfying ASMR game audio, punchy low end, bright sparkly high end, crisp transients, no background music
```

### ไทม์ไลน์เสียงในไฟล์ (นำไปตัดแยก)
- **0:00 – 0:06:** `sfx_gacha_spin` — เสียงหมุนตู้สล็อต ลูกแก้วออร่าวิ่ง กริ๊กๆๆๆ ชะลอช้าลง
- **0:09 – 0:15:** `sfx_near_miss_riser` — เสียงหัวใจเต้น ตึกตัก + คลื่นเวทมนตร์กวาดขึ้น ลุ้นเกือบได้ตัวเทพ
- **0:18 – 0:27:** `sfx_jackpot_legendary` — เสียงแจ็กพอต ฮาร์ปประกายทอง + เสียงระเบิดเวทมนตร์นุ่มลึก + ระฆังชัยชนะ (ฟินขั้นสุด)
- **0:30 – 0:35:** `sfx_star_up` — เสียงอัปเกรดดาวออร่า ละอองดาวระยิบระยับ + คอร์ดดาวทอง 5 ดาว
- **0:38 – 0:44:** `sfx_kaching_coins` — เสียง Ka-ching กริ๊งเงินสดใส + เหรียญทองและเพชรร่วงระนาว
- **0:47 – 0:53:** `sfx_chest_open` — เสียงเปิดหีบสมบัติไม้โบราณ เอี๊ยด + แสงเวทพุ่งสว่างวาบ

---

## 4. File 4 (SFX Reel 3): UI & Cozy Interaction Pack

### Prompt แนะนำ

```text
A sequence of 5 cute cozy UI sound effects separated by pauses:
1. Soft rounded wooden button tap click
2. Gentle bouncy pop whoosh for menu window opening
3. Subtle soft suction swoosh for window closing
4. Cute wet pearl bubble pickup ding with water resonance
5. Bright fast register bell chime for selling inventory
Minimalist, clean UI foley, satisfying haptic feel, ASMR game sound design
```

### ไทม์ไลน์เสียงในไฟล์ (นำไปตัดแยก)
- **0:00 – 0:03:** `sfx_ui_button` — เสียงคลิกปุ่มไม้นุ่มๆ ไม่แสบหู
- **0:06 – 0:09:** `sfx_ui_window_open` — เสียงเปิดหน้าต่าง ป๊อปดึ๋งนุ่มนวล
- **0:12 – 0:15:** `sfx_ui_window_close` — เสียงปิดหน้าต่าง วู้บเบาๆ
- **0:18 – 0:22:** `sfx_pearl_pickup` — เสียงเก็บไข่มุก ปิ๊งฟองสบู่สะท้อนเสียงน้ำ
- **0:25 – 0:30:** `sfx_sell_all` — เสียงขายปลาเหมาข้อง กริ๊งกระดิ่งคิดเงิน

---

## ขั้นตอนการนำไฟล์ไปใช้งานใน Roblox Studio

1. **Generate ไฟล์:** นำ Prompt แต่ละหมวดไปใส่ใน AI Audio Tool (Suno / ElevenLabs / Stable Audio)
2. **ตัดแยกคลิป (Split):**
   - นำไฟล์เข้าโปรแกรมฟรี เช่น Audacity, CapCut, หรือ Online Audio Cutter
   - ซูมดูคลื่นเสียง ตัดแต่ละเสียงเซฟเป็น `.mp3` หรือ `.ogg` ตามชื่อข้างต้น
3. **อัปโหลดเข้า Roblox:**
   - ใน Roblox Creator Dashboard -> Creations -> Audio หรือใน Roblox Studio Asset Manager -> Audio
   - นำ `rbxassetid://...` ที่ได้มาลงในตารางเสียง (เช่น `Config/AudioAssets.luau`)
4. **เล่นเสียงในโค้ด:**
   - เรียกผ่าน SoundService หรือ Sound Controller ที่รองรับการ Play SFX และ BGM แบบวนลูป
