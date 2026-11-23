# BGM 02: Starlight Aquarium (อควาเรียมใต้แสงดาว)

เอกสารกำกับและ Master Prompt สำหรับสร้างเพลงพื้นหลังเกม Aura Fishing ด้วย AI (Suno, Udio, Stable Audio)

---

## 1. ข้อมูลเพลง (Track Info)

- รหัสในเกม (Config Key): `bgm_aquarium` (หรือ `bgm_night`)
- ชื่อเพลง: Starlight Aquarium
- บทบาทในเกม: เพลงสำหรับหน้าต่าง Aquarium (ตู้ปลาสะสมที่ผลิตไข่มุกตามเวลา), ช่วงกลางคืน, หรือช่วงยืนดูตู้ปลาเพลินๆ
- บรรยากาศ (Mood & Vibe): Lofi Chillhop นุ่มละมุน ลึกลับน่าค้นหาแบบแฟนตาซี ประกายแสงดาวสะท้อนผิวน้ำ เสียงหยดน้ำและฟองสบู่ ช่วยให้จิตใจสงบ ชวนเคลิ้ม ฟังสบายตอนปล่อยตัวละคร Idle
- ความเร็ว (Tempo): 76 BPM
- คีย์เพลง (Musical Key): Eb Major / F Major 7th (คอร์ดแจ๊สเมโลดี้ ลอยละล่อง อ่อนโยน)
- การวนลูป (Looping): วนลูปได้อย่างต่อเนื่อง ให้ความรู้สึกเหมือนเสียงดนตรีไม่มีวันสิ้นสุด

---

## 2. เครื่องดนตรีและการจัดวางเสียง (Instrumentation & Sound Palette)

- เปียโนไฟฟ้าเรโทร (Vintage Rhodes / Wurlitzer Electric Piano): เล่นคอร์ด Major 7th นุ่มๆ มีเนื้อเสียงแบบแผ่นเสียงไวนิล (Tape Saturation / Vinyl Crackle)
- เบสสังเคราะห์นุ่มลึก (Warm Sub Bass / Muted Bass): ให้ฐานเสียงที่อบอุ่นเหมือนอยู่ใต้น้ำ
- กรูฟกลองโลไฟ (Chillhop Dusty Drum Beat): เสียง Rimshot ไม้กระทบเบาๆ, Kick นุ่มๆ, Closed Hi-hat หลวมๆ (Swing feel)
- ฟลุตแจ๊สและทรัมเป็ตติดมิวท์ (Muted Jazz Flute / Soft Saxophone): เมโลดี้บางเบาล่องลอยในบรรยากาศ
- ระฆังลมและชิล์ม (Wind Chimes / Celeste / Water Drops): โน้ตประกายระยิบระยับเหมือนไข่มุกและแสงดาว
- บรรยากาศแอมเบียนต์ (Ambient Bed): เสียงน้ำกระเพื่อมใต้บ่อปลาและฟองสบู่เบาๆ

---

## 3. ทำนองหลักที่ทำให้ติดหู (Catchy Elements)

- ริฟฟ์เปียโน Rhodes 4 คอร์ดวนลูปแบบ Neo-Soul / Lofi ที่ให้ความรู้สึกคุ้นเคยตั้งแต่ได้ยินครั้งแรก
- สอดแทรกเสียงประกายคริสตัล (Celeste / Glockenspiel) ในจังหวะยก คล้ายเสียงหยดน้ำและไข่มุกเด้งหลุดออกมา ชวนให้กดดูปลาว่ายน้ำไปเรื่อยๆ

---

## 4. Master Prompt (สำหรับ AI Audio Generator)

### ช่อง Style / Genre Prompt (Suno v3.5 / Suno v4 / Udio)

```text
Cozy lofi chillhop, underwater fantasy aquarium theme, nostalgic night fishing ambient, vintage dusty Rhodes electric piano chords, tape saturation, gentle muted jazz flute melody, warm sub bass groove, relaxed rimshot drums with vinyl crackle, celestial chime glissando, water droplet textures, tempo 76 bpm, dreamy, ethereal, peaceful, healing video game music, loopable clean instrumental, no vocals
```

### ช่อง Lyrics / Structure (สำหรับวางในกล่องเนื้อเพลงของ Suno / Udio)

```text
[Instrumental]

[Intro]
(Soft vinyl crackle, gentle underwater ambient hum, warm vintage Rhodes chords playing a lazy four-chord loop)

[Verse 1]
(Relaxed chillhop drums enter with a soft rimshot groove, warm sub bassline glides smoothly beneath the Rhodes piano)

[Chorus]
(Catchy melodic hook: soft jazz flute and glowing celeste play an enchanting dreamy melody, sparkles of chime dust)

[Bridge]
(Drums filter down slightly, underwater sensation with Rhodes vibrato and gentle water drop percussion, tranquil and floating)

[Chorus]
(Full lofi beat returns, delicate glockenspiel accents harmonizing with the Rhodes, ultimate cozy and soothing vibe)

[Outro]
(Beat gently strips back leaving Rhodes chords, subtle vinyl static and soft water ripple ambience for seamless loop)
```

---

## 5. การตั้งค่าที่แนะนำในเครื่องมือ AI

- Suno AI:
  - Custom Mode: On
  - Instrumental: On
  - Style: ใส่ข้อความจากหัวข้อ 4 (ช่อง Style)
  - Title: Aura Fishing - Starlight Aquarium Lofi
- Udio:
  - Instrumental: On
  - Prompt Strength: 55%
  - Tags: `Lofi, Chillhop, Rhodes, Ambient, Video Game Soundtrack, Relaxing`
- Negative Prompt (สิ่งที่ไม่ต้องการ):
  - `harsh treble, heavy distortion, trap 808 hi-hat rolls, electric guitar solos, brass stabs, aggressive drums, vocals, rap, shouting`

---

## 6. การนำไปใช้ในโค้ดเกม (Roblox Luau)

ไฟล์ `src/shared/Config/Sounds.luau`:
```lua
bgm_aquarium = {
    Id = "rbxassetid://<ASSET_ID>",
    Bus = "Music",
    Volume = 0.65,
    Loop = true,
},
```
เรียกเล่นตอนเปิดหน้าต่าง Aquarium:
```lua
SoundController.PushMusic("Aquarium", "bgm_aquarium", 5)
-- เมื่อปิดหน้าต่าง:
SoundController.PopMusic("Aquarium")
```
