# BGM 04: Mythic Reel Clash (ศึกรอกสะท้าน / ดวลปลาในตำนาน)

เอกสารกำกับและ Master Prompt สำหรับสร้างเพลงพื้นหลังเกม Aura Fishing ด้วย AI (Suno, Udio, Stable Audio)

---

## 1. ข้อมูลเพลง (Track Info)

- รหัสในเกม (Config Key): `bgm_battle` (หรือ `bgm_reel_clash`)
- ชื่อเพลง: Mythic Reel Clash
- บทบาทในเกม: เพลงตอนติดปลาบอส / ปลาระดับ Mythic หรือ Secret, ช่วงมินิเกม Ring Reel ที่รอกหมุนสปีดไฟลุก, หรือช่วงเปิดตู้การันตี Pity ออร่าขั้นสูงสุด
- บรรยากาศ (Mood & Vibe): ตื่นเต้น เร้าใจ มันส์หยด อะดรีนาลีนสูบฉีด แต่ยังคงความสนุกสนานแบบเกม ไม่เครียดหรือน่ากลัว สไตล์ Funk Rock x Japanese Arcade Battle ผสมผสานสไตล์ดนตรีแบบ Persona 5 x Dave the Diver (Boss Fight) x Sonic Mania
- ความเร็ว (Tempo): 136 BPM (เร็ว ดุดัน ขับเคลื่อนจังหวะไปข้างหน้าอย่างรวดเร็ว)
- คีย์เพลง (Musical Key): D Minor / F Major (ลุ้นระทึก ทรงพลัง แต่มีท่อนคอร์ดสว่างสดใส)
- การวนลูป (Looping): กรูฟต่อเนื่องเพื่อกระตุ้นให้ผู้เล่นจับจังหวะกดรอกในมินิเกมได้อย่างแม่นยำ

---

## 2. เครื่องดนตรีและการจัดวางเสียง (Instrumentation & Sound Palette)

- สแลปเบสไฟลุก (Aggressive Slap & Pop Funk Bass): ไลน์เบสกระโดดและสแลปสะบัด ชวนโยกตามทุกจังหวะ
- กีตาร์ไฟฟ้าฟังก์ (Funky Overdriven Rhythm Guitar): คอร์ดกวาด 16th notes คมกริบสไตล์ฟังก์ร็อก
- กลองชุดความเร็วสูง (High-Octane Driving Drums): ไฮแฮทวิ่งรัวๆ, สแนร์กระแทกเฉียบคม, กระเดื่องสองจังหวะ
- คลาวิเน็ตและออร์แกน (Funky Clavinet & Hammond Organ): เพิ่มความดิบและความเท่สไตล์คลาสสิกอาร์เคด
- เครื่องเป่าทองเหลืองดุดัน (Punchy Brass Section): ทรัมเป็ตและทรอมโบนยิงโน้ตกระหน่ำในท่อนลุ้นระทึก
- เสียงสายเอ็นและเครื่องยนต์สังเคราะห์ (Mechanical Tension Riser FX): เสียงสะท้อนความตึงของสายเบ็ด

---

## 3. ทำนองหลักที่ทำให้ติดหู (Catchy Elements)

- กรูฟเบสและริฟฟ์กีตาร์ที่วิ่งสลับฟันปลาคู่กับเสียงเครื่องเป่าแบบ Call-and-Response (ถาม-ตอบ) ทำให้ผู้เล่นจดจำท่อนฮุกได้ทันทีตั้งแต่โน้ตแรก
- จังหวะเบรกสั้นๆ 1 ห้องก่อนสแนร์ระเบิดเข้าท่อนโซโล่ ให้ความรู้สึกเหมือนวินาทีที่ปลากระโดดพ้นน้ำแล้วสายเบ็ดเกือบขาด

---

## 4. Master Prompt (สำหรับ AI Audio Generator)

### ช่อง Style / Genre Prompt (Suno v3.5 / Suno v4 / Udio)

```text
High-energy funk rock, epic anime video game boss battle, dynamic fishing duel showdown, aggressive slap bass solos, driving overdriven rhythm guitar riffs, blazing brass horn stabs, funky clavinet, fast driving drum breakbeats, tension strings, tempo 136 bpm, intense, thrilling, heroic, fun, Japanese arcade fusion, punchy dynamic master, loopable instrumental, no vocals
```

### ช่อง Lyrics / Structure (สำหรับวางในกล่องเนื้อเพลงของ Suno / Udio)

```text
[Instrumental]

[Intro]
(Fast high-tension drum fill, screaming funk brass hit, rapid slap bassline kicks in with an overdriven guitar riff!)

[Verse 1]
(Tight rhythm section: driving drums at 136 bpm, funky rhythm guitar skanks, tense pulsating bassline matching the reel speed)

[Pre-Chorus / Tension]
(Dramatic brass horn stabs rising in pitch, strings tremolo building intense suspense, sudden drum stutter pause...)

[Chorus / Showdown Hook]
(Explosive funk battle climax! Triumphant blazing horn section leads the catchy main melody, blistering slap bass acrobatics, ultimate hype dopamine rush)

[Bridge / Reel Solo]
(Groovy clavinet and guitar trade rapid funky licks, relentless drumming keeping player adrenaline at peak level)

[Chorus / Climax]
(All instruments hit maximum intensity: soaring heroic horns, thunderous drums, brilliant funk rock showdown theme)

[Outro]
(Punchy brass stab with a tight drum roll, seamlessly resetting back to the driving intro beat for loop)
```

---

## 5. การตั้งค่าที่แนะนำในเครื่องมือ AI

- Suno AI:
  - Custom Mode: On
  - Instrumental: On
  - Style: ใส่ข้อความจากหัวข้อ 4 (ช่อง Style)
  - Title: Aura Fishing - Mythic Reel Clash
- Udio:
  - Instrumental: On
  - Prompt Strength: 60%
  - Tags: `Funk Rock, Video Game Boss Theme, Brass Section, Slap Bass, Fast Tempo, Arcade`
- Negative Prompt (สิ่งที่ไม่ต้องการ):
  - `slow ballad, sleepy music, lo-fi chill, acoustic folk, ambient drone, muffled mix, vocals, growling, autotune singing`

---

## 6. การนำไปใช้ในโค้ดเกม (Roblox Luau)

ไฟล์ `src/shared/Config/Sounds.luau`:
```lua
bgm_battle = {
    Id = "rbxassetid://<ASSET_ID>",
    Bus = "Music",
    Volume = 0.85,
    Loop = true,
},
```
เรียกเล่นตอนปลาระดับ Mythic/Secret ติดเบ็ดใน `FishingController`:
```lua
SoundController.PushMusic("BossFish", "bgm_battle", 20) -- Priority สูงสุด ชนะเพลงทุกอัน
-- เมื่อตกสำเร็จหรือปลาหลุด:
SoundController.PopMusic("BossFish")
```
