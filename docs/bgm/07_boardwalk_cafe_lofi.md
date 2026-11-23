# BGM 07: Boardwalk Cafe Lofi (กาแฟยามสาย ริมสายน้ำ)

เอกสารกำกับและ Master Prompt สำหรับสร้างเพลงพื้นหลังเกม Aura Fishing ด้วย AI (Suno, Udio, Stable Audio)

---

## 1. ข้อมูลเพลง (Track Info)

- รหัสในเกม (Config Key): `bgm_cafe` (หรือ `bgm_morning_chill`)
- ชื่อเพลง: Boardwalk Cafe Lofi (กาแฟยามสาย ริมสายน้ำ)
- บทบาทในเกม: เพลงสำหรับช่วงเวลาเดินเล่นชิลล์ๆ ในโซนร้านค้า/คาเฟ่ริมสะพานไม้ (Boardwalk Cafe), การเปิดเกมมาตกปลาพักผ่อนช่วงสายๆ แดดอุ่นๆ ลมพัดเอื่อยๆ ปล่อยใจว่างเปล่า ไม่ต้องคิดอะไร
- บรรยากาศ (Mood & Vibe): สบายตา สบายใจ อบอุ่น เรียบง่าย ปลอดโปร่ง (Carefree, Laid-back, Sunny Morning, Cozy Coffee Shop) ดนตรีแนว Coffee Shop Lofi Chillhop ผสม Acoustic Jazzhop จังหวะกรูฟหลวมๆ ขี้เกียจๆ ชวนให้จิบเครื่องดื่มอุ่นๆ แล้วเหวี่ยงเบ็ดทิ้งไว้
- ความเร็ว (Tempo): 80 BPM (สวิงช้ากำลังดี เดินสบายไม่เร่งรีบ)
- คีย์เพลง (Musical Key): F Major / Bb Major (คอร์ดเมเจอร์อบอุ่น ละมุน แสงแดดยามสาย)
- การวนลูป (Looping): วนลูปต่อเนื่องไร้รอยต่อ กลมกลืนไปกับเสียงบรรยากาศริมน้ำ

---

## 2. เครื่องดนตรีและการจัดวางเสียง (Instrumentation & Sound Palette)

- เปียโนอัพไรท์ไม้อบอุ่น (Warm Felt Upright Piano / Mellow Rhodes): เล่นคอร์ดแจ๊ส 7th และ 9th ที่ให้ความรู้สึกผ่อนคลาย ปลอบประโลมหัวใจ
- กีตาร์โปร่งสายเอ็น (Lazy Fingerstyle Acoustic Guitar): เล่นเกาคอร์ดสบายๆ แทรกสลับกับเสียงเปียโน
- ดับเบิลเบสไม้นุ่มลึก (Acoustic Upright Double Bass): ให้เสียงเบสทุ้มต่ำอุ้มจังหวะหลวมๆ มีความเป็นแจ๊สคาเฟ่
- กลองโลไฟสวิงขี้เกียจ (Lazy Lofi Drum Beat): เสียง Rimshot ไม้เคาะนุ่มๆ, กระเดื่องทุ้มอุ่น, แปรงปัดสแนร์ (Jazz Brushes) และเชกเกอร์เบาๆ
- ทำนองผิวปากหรือเมโลดิก้าเบาๆ (Gentle Whistle / Soft Melodica / Flute): เล่นเมโลดี้หลักสั้นๆ ติดหู เหมือนคนกำลังเดินผิวปากชมวิว
- เสียงบรรยากาศคาเฟ่และธรรมชาติ (Coffee Shop & Boardwalk Ambience): เสียงแผ่นเสียงไวนิลอุ่นๆ (Tape Warble & Vinyl Static), เสียงแก้วเซรามิกกระทบเบาๆ (Subtle Coffee Cup Clinks), และเสียงน้ำกระทบเสาสะพานไม้

---

## 3. ทำนองหลักที่ทำให้ติดหู (Catchy Elements)

- ทำนองผิวปากผสมเปียโน Felt ที่เล่นเพียง 4-5 โน้ตวนลูปซ้ำๆ อย่างเป็นธรรมชาติ จำง่าย ฮัมตามได้ทันที ให้ความรู้สึกเหมือนคนไม่มีเรื่องให้ต้องเครียดในชีวิต
- จังหวะกลองที่มี Swing หน่วงหลังนิดๆ (Laid-back Beat) ทำให้หัวโยกตามช้าๆ โดยไม่รู้ตัว เหมาะกับการปล่อยตัวละครตกปลาไปทำงานไป

---

## 4. Master Prompt (สำหรับ AI Audio Generator)

### ช่อง Style / Genre Prompt (Suno v3.5 / Suno v4 / Udio)

```text
Cozy coffee shop lofi beats, relaxed sunny morning fishing, seaside boardwalk cafe jazzhop, warm felt upright piano chords, lazy fingerstyle acoustic guitar, gentle carefree whistle melody, deep acoustic upright bass, soft brushed drums with wooden rimshot, vinyl crackle, subtle ceramic coffee cup ambient, relaxed tempo 80 bpm, peaceful, wholesome, mindful, healing video game background, seamless loopable instrumental, no vocals
```

### ช่อง Lyrics / Structure (สำหรับวางในกล่องเนื้อเพลงของ Suno / Udio)

```text
[Instrumental]

[Intro]
(Soft vinyl warmth, distant gentle wooden dock water ripples, warm felt piano plays a sweet lazy chord progression)

[Verse 1]
(Relaxed jazz-brushed lofi drums enter with a gentle swinging rimshot, warm acoustic upright bass glides beneath the chords)

[Chorus / Coffee Hook]
(Carefree and catchy: a soft cheerful whistle and gentle acoustic guitar play a sweet, unforgettable morning melody, pure relaxation)

[Bridge / Sunlight Reflections]
(Melodica and mellow Rhodes piano trade delicate notes, ceramic cup clink texture, peaceful and slow-paced breathing room)

[Chorus / Full Cafe Vibe]
(The memorable morning whistle returns with rich acoustic bass and warm felt piano, ultimate brain-off cozy gaming atmosphere)

[Outro]
(Drums soften into smooth brushing, acoustic guitar strums final warm chord, vinyl crackle loops back into the opening bar)
```

---

## 5. การตั้งค่าที่แนะนำในเครื่องมือ AI

- Suno AI:
  - Custom Mode: On
  - Instrumental: On
  - Style: ใส่ข้อความจากหัวข้อ 4 (ช่อง Style)
  - Title: Aura Fishing - Boardwalk Cafe Lofi
- Udio:
  - Instrumental: On
  - Prompt Strength: 50%
  - Tags: `Lofi, Chillhop, Coffee Shop, Acoustic, Jazz, Piano, Relaxing, Video Game`
- Negative Prompt (สิ่งที่ไม่ต้องการ):
  - `heavy drums, aggressive bass, fast tempo, loud horns, synthesizer arpeggios, distorted electric guitar, rap vocals, singing, stressful mood, dark minor chords`

---

## 6. การนำไปใช้ในโค้ดเกม (Roblox Luau)

ไฟล์ `src/shared/Config/Sounds.luau`:
```lua
bgm_cafe = {
    Id = "rbxassetid://<ASSET_ID>",
    Bus = "Music",
    Volume = 0.65,
    Loop = true,
},
```
เรียกเล่นเมื่อผู้เล่นเดินเข้าสู่โซนคาเฟ่/ร้านค้า หรือเลือกสลับเป็นเพลงตกปลาโหมดผ่อนคลาย:
```lua
SoundController.PushMusic("CafeZone", "bgm_cafe", 3)
-- เมื่อออกจากโซน:
SoundController.PopMusic("CafeZone")
```
