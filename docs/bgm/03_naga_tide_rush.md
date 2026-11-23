# BGM 03: Naga Tide Rush (คลื่นนาคราชเรืองแสง / มหกรรมตกปลาน้ำเดือด)

เอกสารกำกับและ Master Prompt สำหรับสร้างเพลงพื้นหลังเกม Aura Fishing ด้วย AI (Suno, Udio, Stable Audio)

---

## 1. ข้อมูลเพลง (Track Info)

- รหัสในเกม (Config Key): `bgm_tide`
- ชื่อเพลง: Naga Tide Rush
- บทบาทในเกม: เพลงประจำอีเวนต์พิเศษ Naga Tide (ปรากฏการณ์ผืนน้ำเรืองแสงทุกๆ :00 และ :30), อีเวนต์แข่งตกปลาประจำชั่วโมง, หรือช่วงเวลา Golden Hour ที่ผู้เล่นมารวมตัวตกปลาพร้อมกัน
- บรรยากาศ (Mood & Vibe): สนุกสนาน คึกคัก เบิกบาน สดใส ชวนโยกหัวตาม จังหวะกรูฟกระโดดเด้งดึ๋ง สไตล์ Tropical House ผสม Future Pop และ Chiptune Arcade สไตล์ดนตรีแบบ Mario Kart (Dolphin Shoals / Koopa Cape) x Kirby x Splatoon Pop
- ความเร็ว (Tempo): 122 BPM (จังหวะชวนเต้น Four-on-the-floor กระฉับกระเฉง)
- คีย์เพลง (Musical Key): D Major / A Major (สดใส สว่างวาบ เต็มไปด้วยพลังบวก)
- การวนลูป (Looping): วนลูปได้กระชับ และมีท่อน Drop ที่กระตุ้นความกระตือรือร้นให้ผู้เล่นเร่งเหวี่ยงเบ็ด

---

## 2. เครื่องดนตรีและการจัดวางเสียง (Instrumentation & Sound Palette)

- ซินธ์ปลั๊กเด้งดึ๋ง (Bouncy Pluck Synth & Mallet): หัวเสียงคมชัด โน้ตกระเด้งกระดอนเหมือนหยดน้ำเต้นระบำ
- มาริมบาและสเปเชียลเพอร์คัชชัน (Tropical Marimba & Steel Tongue Drum): ให้บรรยากาศเกาะทะเลแฟนตาซีที่สนุกสนาน
- สแลปเบสกรูฟหนึบ (Funky Slap Bass / Future Bass Saw): เบสเดินจังหวะกระแทกกระทั้น ชวนขยับขา
- จังหวะกลองแน่นกระชับ (Punchy 4-on-the-Floor Dance Kick): สแนร์สว่างใส, แคลป (Clap) พร้อมไฮแฮทเปิดปิดเป็นระเบียบ
- บราสฮอร์นสดใส (Bright Pop Brass Stabs): เติมเต็มพลังงานให้ท่อนฮุกระเบิดความมันส์
- ซาวด์อาร์เพจจิโอ 8-bit (Sparkling 8-Bit Chiptune Arps): เพิ่มเสน่ห์ความเป็นเกมอาร์เคดสุดน่ารัก

---

## 3. ทำนองหลักที่ทำให้ติดหู (Catchy Elements)

- เมโลดี้ท่อน Drop เป็นไลน์มาริมบาสลับกับบราสสั้นๆ ที่มีจังหวะ Syncopation ขัดขาแต่ลงตัว เป็นท่อนฮุกที่ฟังรอบเดียวก็จำได้และอยากฮัมตาม
- เสียงบิลด์อัพสั้นๆ สลับเสียงน้ำกระจาย (Water Splash riser) ก่อนตัดเข้าท่อนฮุก ให้ความรู้สึกเหมือนฝูงปลาแรร์กระโดดเหนือน้ำพร้อมกัน

---

## 4. Master Prompt (สำหรับ AI Audio Generator)

### ช่อง Style / Genre Prompt (Suno v3.5 / Suno v4 / Udio)

```text
Upbeat tropical house, energetic fantasy video game event theme, vibrant arcade fishing rush, catchy marimba lead, bouncy pluck synths, funky slap bass groove, bright pop brass stabs, sparkling 8-bit chiptune arpeggios, punchy four-on-the-floor kick, cheerful, sunny, festive, high-energy joyful melody, tempo 122 bpm, Nintendo vibe, clean punchy mix, loopable instrumental, no vocals
```

### ช่อง Lyrics / Structure (สำหรับวางในกล่องเนื้อเพลงของ Suno / Udio)

```text
[Instrumental]

[Intro]
(Fast marimba riff starts, bouncy pluck synths layer in, rising snare roll with sparkling water splash FX)

[Build-up]
(Funky slap bass kicks in, 8-bit arpeggios spinning upward, climbing tension and high excitement)

[Drop / Hook]
(Explosive high-energy groove: punchy 4-on-the-floor dance drums, infectious catchy marimba and bright brass melody, playful and extremely energetic!)

[Verse]
(Tropical percussion takes center stage, bouncy bassline carries the forward momentum, sweet synth counter-melodies)

[Build-up]
(Bright brass accents build, syncopated claps, energetic riser building up to the main climax)

[Drop / Climax]
(Full festival power: soaring brass stabs, jumping plucks, triumphant celebration groove, pure gaming dopamine)

[Outro]
(Energetic synth pulse smoothly resolves into the opening loop motif, ready for seamless looping)
```

---

## 5. การตั้งค่าที่แนะนำในเครื่องมือ AI

- Suno AI:
  - Custom Mode: On
  - Instrumental: On
  - Style: ใส่ข้อความจากหัวข้อ 4 (ช่อง Style)
  - Title: Aura Fishing - Naga Tide Rush
- Udio:
  - Instrumental: On
  - Prompt Strength: 55%
  - Tags: `Tropical House, Video Game Music, Upbeat, Marimba, Funky, Brass, Joyful`
- Negative Prompt (สิ่งที่ไม่ต้องการ):
  - `slow tempo, depressing mood, sad piano, acoustic guitar ballad, heavy metal scream, mumble rap, muddy bass, speech, distorted noise`

---

## 6. การนำไปใช้ในโค้ดเกม (Roblox Luau)

ไฟล์ `src/shared/Config/Sounds.luau`:
```lua
bgm_tide = {
    Id = "rbxassetid://<ASSET_ID>",
    Bus = "Music",
    Volume = 0.8,
    Loop = true,
},
```
เรียกเล่นเมื่ออีเวนต์ Naga Tide เริ่มต้นใน `TideEventController`:
```lua
SoundController.PushMusic("NagaTide", "bgm_tide", 10) -- Priority สูงกว่าเพลงปกติ
-- เมื่อหมดเวลาอีเวนต์:
SoundController.PopMusic("NagaTide")
```
