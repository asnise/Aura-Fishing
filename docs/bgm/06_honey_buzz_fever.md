# BGM 06: Honey Buzz Fever (มหกรรมตกปลาฟีเวอร์แดนซ์)

เอกสารกำกับและ Master Prompt สำหรับสร้างเพลงพื้นหลังเกม Aura Fishing ด้วย AI (Suno, Udio, Stable Audio)

---

## 1. ข้อมูลเพลง (Track Info)

- อ้างอิงสไตล์ (Reference Track): "Back to the Drawing Board" (FFXIV Arcadion M2 / Honey B. Lovely Theme - Masayoshi Soken)
- รหัสในเกม (Config Key): `bgm_frenzy_fever`
- ชื่อเพลง: Honey Buzz Fever
- บทบาทในเกม: เพลงประจำโหมด Fever / Multi-Cast Blitz (ตกปลาหลายสายพร้อมกัน), อีเวนต์ Rainbow Fish Swarm (ฝูงปลาสีรุ้งแตกตัว), หรือมินิเกมลุ้นโบนัสความเร็วสูงที่มีเวลาจำกัด
- บรรยากาศ (Mood & Vibe): สดใส ซ่า ซน บ้าพลัง คลั่งรัก น่ารักแต่ดุเดือดสุดขีด (Kawaii Anime Pop-Punk, Electro-Dance Rock, Frantic, Hyperactive, Playful yet Chaotic) จังหวะแดนซ์สะบัด เต้นไม่หยุด ติดหูระดับล้างสมอง สไตล์ J-Pop Idol Punk ผสมเสียงสังเคราะห์ยุคใหม่
- ความเร็ว (Tempo): 172 BPM (เร็วมาก วิ่งพล่านด้วยจังหวะ 4-on-the-Floor Dance-Rock)
- คีย์เพลง (Musical Key): F# Major / Eb Minor (สดใส หวานเจี๊ยบ แต่เต็มไปด้วยลูกกัดของกีตาร์พังก์)
- การวนลูป (Looping): กรูฟแดนซ์รัวเร็วต่อเนื่อง เติมพลังบวกและความไฮป์ให้ผู้เล่นกดปุ่มรัวๆ ไม่ยั้ง

---

## 2. เครื่องดนตรีและการจัดวางเสียง (Instrumentation & Sound Palette)

- ซินธ์ลีดบับเบิ้ลกัม (Chirpy Bubblegum Lead Synths & Arpeggios): เสียงสังเคราะห์กระโดดดึ๋งๆ โน้ตหวานใส มีความน่ารักสไตล์ไอดอล
- กีตาร์ไฟฟ้าป๊อปพังก์ (Distorted Pop-Punk Rhythm Guitars): สับคอร์ดรวดเร็ว เสียงแตกสะใจ ให้ความหนักแน่นแบบวงร็อก
- กลองชุดสไตล์แดนซ์ร็อก (Hyper Four-on-the-Floor Dance Drums): กระเดื่องตอกทุกจังหวะที่ 172 BPM พร้อมสแนร์เปิดไฮแฮทแดนซ์กระจาย
- สแลปเบสและซับเบสเด้งดึ๋ง (Punchy Slap Bass & Bouncy Synth Bass): เดินไลน์เบสสอดรับกับกระเดื่อง เพิ่มความหนึบให้กรูฟ
- บราสซินธ์และระฆังของเล่น (Bright Synth Brass, Toy Bells & Laser Sweeps): เสียงหยอดเอฟเฟกต์วิบวับสไตล์เกมอาร์เคดญี่ปุ่น
- เสียงระเบิดฟองสบู่และประกายออร่า (Bubble Pop & Rainbow Sparkle FX)

---

## 3. ทำนองหลักที่ทำให้ติดหู (Catchy Elements)

- เมโลดี้ท่อนฮุกที่หวานแหววแต่เร็วทะลุมิติแบบไอดอลสาวอนิเมะ (Catchy Idol Chorus Melody) เล่นสลับกับริฟฟ์กีตาร์พังก์หนักแน่น เป็นคู่ตัดกันที่ติดหูและชวนให้ฮัมตามไม่หยุด
- ท่อนเบรกสั้นๆ กึ่งกวนโอ๊ย (Playful Stutter Stop) ดนตรีหยุดกระทันหัน 1 จังหวะก่อนจะระเบิดกลับเข้ามาด้วยเสียงบราสซินธ์และกลองชุดที่เร็วกว่าเดิม กระตุ้นความตื่นตัวของผู้เล่นขั้นสูงสุด

---

## 4. Master Prompt (สำหรับ AI Audio Generator)

### ช่อง Style / Genre Prompt (Suno v3.5 / Suno v4 / Udio)

```text
Kawaii anime pop punk, hyperactive electro dance rock, J-pop idol battle theme, FFXIV Honey B Lovely style, bright bubbly lead synths, fast distorted punk power chords, relentless four-on-the-floor dance drums at 172 bpm, punchy slap bass, sparkling chiptune arpeggios, chaotic, playful, frantic, high-octane addictive melody, sweet yet aggressive energy, clean punchy mix, loopable instrumental, no vocals
```

### ช่อง Lyrics / Structure (สำหรับวางในกล่องเนื้อเพลงของ Suno / Udio)

```text
[Instrumental]

[Intro]
(Cute chirpy synth melody starts with a bright arcade bell, sudden drop into fast 172 bpm four-on-the-floor drums and distorted punk guitars!)

[Verse 1]
(Relentless high-speed energy: driving dance-rock kick, bright bouncy synth plucks dancing over heavy punk guitar rhythms)

[Pre-Chorus / Sweet Chaos]
(Ascending synth sweeps, rapid snare rolls building, playful laser sparkles and stuttering beat creating hyper tension!)

[Chorus / Idol Climax Hook]
(Explosive hyperactive dance-rock payoff! Incredibly catchy, sugary sweet lead melody blasted through bright synth brass and soaring guitars, pure joyous chaos!)

[Bridge / Funky Dance Break]
(Beat shifts to an irresistible bouncy slap bass groove with playful toy chimes, before heavy guitars slam back in)

[Chorus / Maximum Fever]
(All instruments hit peak frenzy: dazzling sparkling arpeggios, roaring punk chords, hyper dance beat firing at full power!)

[Outro]
(Cute synth flutter note with a sharp snare crack, cleanly resetting back to the infectious 172 bpm dance loop)
```

---

## 5. การตั้งค่าที่แนะนำในเครื่องมือ AI

- Suno AI:
  - Custom Mode: On
  - Instrumental: On
  - Style: ใส่ข้อความจากหัวข้อ 4 (ช่อง Style)
  - Title: Aura Fishing - Honey Buzz Fever
- Udio:
  - Instrumental: On
  - Prompt Strength: 60%
  - Tags: `J-Pop, Pop Punk, Electro Rock, Anime, Video Game Boss, High BPM, Dance`
- Negative Prompt (สิ่งที่ไม่ต้องการ):
  - `slow tempo, acoustic ballad, melancholic piano, relaxing lofi, dark horror ambience, muddy bass, acoustic folk, autotune vocals, growling`

---

## 6. การนำไปใช้ในโค้ดเกม (Roblox Luau)

ไฟล์ `src/shared/Config/Sounds.luau`:
```lua
bgm_frenzy_fever = {
    Id = "rbxassetid://<ASSET_ID>",
    Bus = "Music",
    Volume = 0.8,
    Loop = true,
},
```
เรียกเล่นเมื่อเข้าสู่โหมด Fever หรือช่วงกิจกรรมโบนัสความเร็วสูง:
```lua
SoundController.PushMusic("FrenzyFever", "bgm_frenzy_fever", 15) -- Priority สูงช่วงโหมดฟีเวอร์
-- เมื่อหมดเวลาโหมดฟีเวอร์:
SoundController.PopMusic("FrenzyFever")
```
