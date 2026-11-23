# BGM 05: Abyssal Desperado (ศึกตัดสินใต้สมุทรลึก)

เอกสารกำกับและ Master Prompt สำหรับสร้างเพลงพื้นหลังเกม Aura Fishing ด้วย AI (Suno, Udio, Stable Audio)

---

## 1. ข้อมูลเพลง (Track Info)

- อ้างอิงสไตล์ (Reference Track): "Rivers in the Desert" (Persona 5 OST / Shoji Meguro)
- รหัสในเกม (Config Key): `bgm_boss_abyss`
- ชื่อเพลง: Abyssal Desperado
- บทบาทในเกม: เพลงศึกตัดสินบอสตกปลาใต้สมุทรลึก (Abyssal Leviathan / Naga King Awakened), การประจันหน้ากับปลาระดับ Secret ความยากระดับสูงสุด, หรือรอบชิงชนะเลิศทัวร์นาเมนต์ตกปลา
- บรรยากาศ (Mood & Vibe): มีสไตล์ เท่ ดุดัน อลังการ เปี่ยมด้วยความหวังและการต่อสู้อันดุเดือด (Dramatic, Stylish, Heroic, Suspenseful) ดนตรีแนว Acid Jazz Funk Rock ผสม Symphonic Strings ที่ไพเราะและกระตุ้นอะดรีนาลีนขั้นสุด
- ความเร็ว (Tempo): 128 BPM
- คีย์เพลง (Musical Key): E Minor / G Major
- การวนลูป (Looping): กรูฟแน่นต่อเนื่อง พร้อมท่อนระเบิดอารมณ์แบบ Cinematic Heroic Showdown

---

## 2. เครื่องดนตรีและการจัดวางเสียง (Instrumentation & Sound Palette)

- วงเครื่องสายออร์เคสตราดุดัน (Dramatic Orchestral Strings): ไวโอลินเล่นริฟฟ์ Staccato คมกริบ สลับกับโซโล่เชลโล่และไวโอลินท่อนฮุกที่ทะยานสูงบาดอารมณ์
- สแลปเบสฟังก์สไตล์ Persona (Heavy Slap & Funk Fingerstyle Bass): ไลน์เบสแน่น กระแทกกระทั้น ลื่นไหล มีกรูฟอันเป็นเอกลักษณ์
- กีตาร์ไฟฟ้าวาว-วาว และริฟฟ์โอเวอร์ไดรฟ์ (Wah-wah Funk Guitar & Driving Rock Power Chords): คอยกวาดคอร์ดตัดจังหวะสไตล์ Neo-Soul / Acid Jazz
- กลองชุดสไตล์ร็อกฟังก์ (Driving Rock Drums): ไฮแฮทละเอียด 16th notes, สแนร์กระแทกเฉียบคม, กระเดื่องสองชั้นเร่งจังหวะการหมุนรอก
- ออร์แกนเรโทรและซินธ์บิลด์อัพ (Vintage B3 Organ & Analog Synth Swells): เพิ่มมิติความลึกลับและความคลาสสิก
- บรรยากาศคลื่นน้ำวนและความตึงเครียด (Ocean Whirlpool & Line Tension FX)

---

## 3. ทำนองหลักที่ทำให้ติดหู (Catchy Elements)

- ท่อน Pre-Chorus: เสียงสตริงส์เล่นโน้ตรัวไต่ระดับความสูง (Ascending String Arpeggio) ควบคู่กับเสียงเบสดำดิ่ง สร้างความตื่นเต้นระทึกใจจนแทบหยุดหายใจ
- ท่อน Hook / Chorus: เมโลดี้เครื่องสายประสานเสียงกว้าง ทะยานขึ้นอย่างสง่างาม ทรงพลัง คล้ายท่อนฮุกของ Rivers in the Desert ที่ผู้เล่นจะได้ยินแล้วฮัมตามทันที ให้ความรู้สึกว่า "เราต้องดึงปลานี้ขึ้นมาให้ได้"

---

## 4. Master Prompt (สำหรับ AI Audio Generator)

### ช่อง Style / Genre Prompt (Suno v3.5 / Suno v4 / Udio)

```text
Acid jazz funk rock, dramatic symphonic anime boss battle, Persona 5 style, heroic confrontation, soaring staccato orchestral strings, heavy groovy slap bassline, tight funk wah-wah electric guitar, driving rock drums at 128 bpm, passionate solo violin melody, retro organ swells, tense, stylish, cinematic, epic gaming climax, punchy studio master, loopable instrumental, no vocals
```

### ช่อง Lyrics / Structure (สำหรับวางในกล่องเนื้อเพลงของ Suno / Udio)

```text
[Instrumental]

[Intro]
(Dramatic solo violin motif over silence, sudden explosion of groovy slap bass, wah-wah funk guitar and tight rock drums!)

[Verse 1]
(Relentless driving bass groove at 128 bpm, tight funk guitar skanks, staccato violin accents punctuating the rhythm)

[Pre-Chorus / Rising Tension]
(Ascending orchestral string sweeps building immense suspense, organ swells, dynamic drum fills climbing to maximum pressure)

[Chorus / Heroic Climax]
(Massive emotional payoff: soaring, passionate violin section carries an unforgettable heroic melody, slap bass going wild underneath, pure triumph and high-stakes duel!)

[Bridge / Instrumental Duel]
(Virtuoso funky bass solo trades rapid licks with a searing electric guitar and crying violin, cinematic and deeply stylish)

[Chorus / Grand Finale]
(Full symphonic rock orchestra returns with highest intensity, thunderous drums, soaring strings reaching the emotional peak)

[Outro]
(Punchy brass and string stab, falling back into the irresistible driving bass rhythm ready for seamless loop)
```

---

## 5. การตั้งค่าที่แนะนำในเครื่องมือ AI

- Suno AI:
  - Custom Mode: On
  - Instrumental: On
  - Style: ใส่ข้อความจากหัวข้อ 4 (ช่อง Style)
  - Title: Aura Fishing - Abyssal Desperado
- Udio:
  - Instrumental: On
  - Prompt Strength: 60%
  - Tags: `Acid Jazz, Funk Rock, Symphonic, Video Game Boss Theme, Strings, Slap Bass`
- Negative Prompt (สิ่งที่ไม่ต้องการ):
  - `muffled sound, low energy, acoustic folk, relaxing lofi, slow tempo, death metal screaming, autotune vocals, generic trap beat`

---

## 6. การนำไปใช้ในโค้ดเกม (Roblox Luau)

ไฟล์ `src/shared/Config/Sounds.luau`:
```lua
bgm_boss_abyss = {
    Id = "rbxassetid://<ASSET_ID>",
    Bus = "Music",
    Volume = 0.85,
    Loop = true,
},
```
เรียกเล่นเมื่อเข้าสู่การสู้กับบอสทะเลลึก:
```lua
SoundController.PushMusic("AbyssalBoss", "bgm_boss_abyss", 25) -- Priority สูงสุดระดับ Boss Showdown
-- เมื่อจบการต่อสู้:
SoundController.PopMusic("AbyssalBoss")
```
