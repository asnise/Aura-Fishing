# BGM 01: Cozy Lake Breeze (สายลมทะเลสาบ)

เอกสารกำกับและ Master Prompt สำหรับสร้างเพลงพื้นหลังเกม Aura Fishing ด้วย AI (Suno, Udio, Stable Audio)

---

## 1. ข้อมูลเพลง (Track Info)

- รหัสในเกม (Config Key): `bgm_lake`
- ชื่อเพลง: Cozy Lake Breeze
- บทบาทในเกม: เพลงพื้นหลังหลัก (Default Track) ประจำแผนที่ทะเลสาบและสะพานไม้ (Cozy Lake Boardwalk)
- บรรยากาศ (Mood & Vibe): ผ่อนคลาย อบอุ่น ฟังสบาย ไม่น่าเบื่อ เพลิดเพลินกับการเหวี่ยงเบ็ด มีประกายคลื่นเบาๆ สไตล์ Animal Crossing x Genshin Impact (Fontaine Port) x Studio Ghibli
- ความเร็ว (Tempo): 84 BPM
- คีย์เพลง (Musical Key): C Major / G Major (คอร์ดโปร่ง สดใส อ่อนโยน)
- การวนลูป (Looping): ต้องสามารถวนซ้ำไร้รอยต่อ (Seamless Loop) ได้อย่างราบรื่น

---

## 2. เครื่องดนตรีและการจัดวางเสียง (Instrumentation & Sound Palette)

- กีตาร์โปร่งสายไนลอน (Fingerstyle Nylon Acoustic Guitar): เล่นคอร์ดและกรูฟหลักที่นุ่มนวล
- คาลิมบาไม้ (Wooden Kalimba / Thumb Piano): โน้ตประกายน้ำระยิบระยับเป็นเมโลดี้หลัก
- เปียโนไฟฟ้า / ทอยเปียโน (Warm Toy Piano / Glockenspiel): เติมเต็มความน่ารักสไตล์แฟนตาซี
- อัพไรท์เบส (Acoustic Upright Bass): เสียงทุ้มนุ่มลึก อุ้มจังหวะด้านล่างให้ผ่อนคลาย
- เพอร์คัชชันเบาๆ (Soft Percussion): Shaker, Finger Snap, Woodblock นุ่มๆ
- เสียงธรรมชาติประกอบ (Atmosphere): เสียงน้ำกระเพื่อมเบาๆ (Gentle Water Ripples) และสายลมอ่อนๆ

---

## 3. ทำนองหลักที่ทำให้ติดหู (Catchy Elements)

- ช่วง Hook เป็นทำนองคาลิมบาสลับกับกีตาร์โปร่งที่ใช้โน้ตขั้นคู่สั้นๆ จำง่าย โน้ตกระโดดขึ้นลงน่ารักเหมือนตัวปลาดิ้นในน้ำ
- ไม่มีเสียงดรอปหรือจังหวะกระแทกแรง ให้ผู้เล่นสามารถฟังวนซ้ำได้นานเป็นชั่วโมงโดยไม่รู้สึกล้าหู

---

## 4. Master Prompt (สำหรับ AI Audio Generator)

### ช่อง Style / Genre Prompt (Suno v3.5 / Suno v4 / Udio)

```text
Cozy acoustic fantasy, lo-fi lakeside folk, peaceful video game village theme, warm fingerstyle nylon guitar, gentle wooden kalimba melody, soft glockenspiel accents, acoustic upright bass, light shaker percussion, subtle water ripples atmosphere, relaxed tempo 84 bpm, nostalgic, wholesome, pastoral, sunny lake boardwalk, clean studio mix, seamless loopable instrumental, no vocals
```

### ช่อง Lyrics / Structure (สำหรับวางในกล่องเนื้อเพลงของ Suno / Udio)

```text
[Instrumental]

[Intro]
(Gentle water ripples, warm acoustic guitar fingerpicking pattern, soft shaker enters)

[Verse 1]
(Kalimba leads with a cute catchy pastoral melody, soft acoustic bass providing a warm groove, light woodblock accents)

[Chorus]
(Uplifting and memorable main hook: glockenspiel and kalimba duet with warm guitar strumming, wholesome and comforting fantasy vibes)

[Bridge]
(Acoustic guitar takes a melodic solo with soft ambient chimes, spacious and breezy feel)

[Chorus]
(Full cozy arrangement returns with main memorable theme, cheerful yet deeply calming)

[Outro]
(Gentle guitar picking slowly loops back into the opening motif, smooth water ripple fade)
```

---

## 5. การตั้งค่าที่แนะนำในเครื่องมือ AI

- Suno AI:
  - Custom Mode: On
  - Instrumental: On
  - Style: ใส่ข้อความจากหัวข้อ 4 (ช่อง Style)
  - Title: Aura Fishing - Cozy Lake Breeze
- Udio:
  - Instrumental: On
  - Prompt Strength: 50%
  - Quality: Ultra / High
- Negative Prompt (สิ่งที่ไม่ต้องการ):
  - `heavy drums, distorted bass, aggressive synth, loud brass, vocals, speech, dark mood, sad minor chords, fast tempo`

---

## 6. การนำไปใช้ในโค้ดเกม (Roblox Luau)

ไฟล์ `src/shared/Config/Sounds.luau`:
```lua
bgm_lake = {
    Id = "rbxassetid://<ASSET_ID>",
    Bus = "Music",
    Volume = 0.7,
    Loop = true,
},
```
เรียกเล่นอัตโนมัติเป็น Default Track หรือผ่าน `SoundController.PushMusic("Map", "bgm_lake", 1)`
