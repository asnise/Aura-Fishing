# Aura Fishing — 7 BGM Master Prompts & Sound Guide

รวม Master Prompt และเอกสารกำกับทำนองเพลงประกอบ (BGM) ทั้ง 7 เพลงสำหรับเกม **Aura Fishing**
แบ่งเป็น:
- สบายๆ / Cozy & Lofi: 3 เพลง (ทะเลสาบ, อควาเรียม, และคาเฟ่จิบกาแฟยามสาย)
- สนุกสนาน / มันส์ & ตื่นเต้น: 2 เพลง (อีเวนต์น้ำเรืองแสงและสู้ปลาแรร์)
- สไตล์เฉพาะตามเพลงอ้างอิง: 2 เพลง (Persona 5 & FFXIV Arcadion Style)

---

## ตารางสรุปภาพรวม 7 บทเพลง (BGM Matrix)

| เพลง | หมวดหมู่ / สไตล์ | จังหวะ (BPM) | ฟีลลิ่ง / จุดเด่น | จุดที่นำไปใช้ในเกม | Key ใน Config/Sounds.luau | ลิงก์เอกสารแยก |
|---|---|---|---|---|---|---|
| **1. Cozy Lake Breeze** | Cozy / Lofi | 84 BPM | กีตาร์โปร่ง + คาลิมบา ผ่อนคลาย อบอุ่น ฟังสบายริมทะเลสาบ | เพลงหลักของเกม (Default BGM) | `bgm_lake` | [อ่านฉบับเต็ม](file:///d:/Roblox%20Project/Aura%20Fishing/docs/bgm/01_cozy_lake_breeze.md) |
| **2. Starlight Aquarium** | Cozy / Lofi | 76 BPM | Lofi Chillhop + เปียโน Rhodes + เสียงน้ำและประกายดาว | หน้าต่าง Aquarium / กลางคืน / ปล่อยตัวละคร Idle | `bgm_aquarium` | [อ่านฉบับเต็ม](file:///d:/Roblox%20Project/Aura%20Fishing/docs/bgm/02_starlight_aquarium.md) |
| **3. Naga Tide Rush** | สนุก / ตื่นเต้น | 122 BPM | Tropical House + Chiptune กรูฟเต้นดึ๋งๆ สดใส ติดหูมาก | อีเวนต์ Naga Tide / แข่งตกปลาประจำชั่วโมง | `bgm_tide` | [อ่านฉบับเต็ม](file:///d:/Roblox%20Project/Aura%20Fishing/docs/bgm/03_naga_tide_rush.md) |
| **4. Mythic Reel Clash** | สนุก / ตื่นเต้น | 136 BPM | Funk Rock + Slap Bass + บราสเร่งเร้า มันส์หยด ลุ้นระทึก | ตกปลาบอส / ปลาระดับ Mythic-Secret / รอกไฟลุก | `bgm_battle` | [อ่านฉบับเต็ม](file:///d:/Roblox%20Project/Aura%20Fishing/docs/bgm/04_mythic_reel_clash.md) |
| **5. Abyssal Desperado** | Persona 5 Style (Rivers in the Desert) | 128 BPM | Acid Jazz Funk Rock + สตริงส์ออร์เคสตราทะยานสูง เท่ อลังการ มีสไตล์ ดุดัน | บอสทะเลลึก (Leviathan / Naga King Awakened) / ทัวร์นาเมนต์ชิงแชมป์ | `bgm_boss_abyss` | [อ่านฉบับเต็ม](file:///d:/Roblox%20Project/Aura%20Fishing/docs/bgm/05_abyssal_desperado.md) |
| **6. Honey Buzz Fever** | FFXIV M2 Style (Honey B. Lovely) | 172 BPM | Kawaii Anime Pop-Punk + Dance Rock ไฮเปอร์แอคทีฟ กรูฟ 4-on-the-floor ซ่าบ้าพลัง ติดหูสุดขีด | โหมด Fever / Multi-Cast Blitz / ฝูงปลาสีรุ้ง Rainbow Swarm | `bgm_frenzy_fever` | [อ่านฉบับเต็ม](file:///d:/Roblox%20Project/Aura%20Fishing/docs/bgm/06_honey_buzz_fever.md) |
| **7. Boardwalk Cafe Lofi** | Cozy Coffee Shop / Lofi Jazz | 80 BPM | เปียโน Felt อบอุ่น + กีตาร์โปร่งเกาช้าๆ + ผิวปากสบายใจ เสียงแก้วกาแฟและคลื่นริมสะพาน | โซนคาเฟ่ริมน้ำ / ตกปลาสายๆ ชิลล์ๆ ไม่ต้องคิดอะไร | `bgm_cafe` | [อ่านฉบับเต็ม](file:///d:/Roblox%20Project/Aura%20Fishing/docs/bgm/07_boardwalk_cafe_lofi.md) |

---

## สรุป Master Prompt สำหรับคัดลอกไปใช้ทันที (Quick Copy-Paste)

### 1. Cozy Lake Breeze (เพลงริมทะเลสาบ - กลางวัน สบายๆ)
- **สไตล์ / Tags:** `Cozy Fantasy Folk, Acoustic Lofi, Fingerstyle Guitar, Kalimba, Gentle Lake Ambient`
- **Master Prompt:**
```text
Cozy acoustic fantasy, lo-fi lakeside folk, peaceful video game village theme, warm fingerstyle nylon guitar, gentle wooden kalimba melody, soft glockenspiel accents, acoustic upright bass, light shaker percussion, subtle water ripples atmosphere, relaxed tempo 84 bpm, nostalgic, wholesome, pastoral, sunny lake boardwalk, clean studio mix, seamless loopable instrumental, no vocals
```

---

### 2. Starlight Aquarium (เพลงตู้ปลาสะสมไข่มุก - โลไฟยามค่ำคืน)
- **สไตล์ / Tags:** `Lofi Chillhop, Underwater Jazz, Rhodes Piano, Sub Bass, Dreamy Ambient`
- **Master Prompt:**
```text
Cozy lofi chillhop, underwater fantasy aquarium theme, nostalgic night fishing ambient, vintage dusty Rhodes electric piano chords, tape saturation, gentle muted jazz flute melody, warm sub bass groove, relaxed rimshot drums with vinyl crackle, celestial chime glissando, water droplet textures, tempo 76 bpm, dreamy, ethereal, peaceful, healing video game music, loopable clean instrumental, no vocals
```

---

### 3. Naga Tide Rush (เพลงอีเวนต์คลื่นนาคราชเรืองแสง - สนุก สดใส คึกคัก)
- **สไตล์ / Tags:** `Tropical House, Chiptune Pop, Slap Bass, Marimba Lead, High Energy Game Music`
- **Master Prompt:**
```text
Upbeat tropical house, energetic fantasy video game event theme, vibrant arcade fishing rush, catchy marimba lead, bouncy pluck synths, funky slap bass groove, bright pop brass stabs, sparkling 8-bit chiptune arpeggios, punchy four-on-the-floor kick, cheerful, sunny, festive, high-energy joyful melody, tempo 122 bpm, Nintendo vibe, clean punchy mix, loopable instrumental, no vocals
```

---

### 4. Mythic Reel Clash (เพลงสู้ปลาในตำนาน / รอกไฟลุก - มันส์ เร้าใจ อะดรีนาลีนพุ่ง)
- **สไตล์ / Tags:** `Funk Rock, Arcade Boss Battle, Slap Bass, Brass Section, Fast Driving Beat`
- **Master Prompt:**
```text
High-energy funk rock, epic anime video game boss battle, dynamic fishing duel showdown, aggressive slap bass solos, driving overdriven rhythm guitar riffs, blazing brass horn stabs, funky clavinet, fast driving drum breakbeats, tension strings, tempo 136 bpm, intense, thrilling, heroic, fun, Japanese arcade fusion, punchy dynamic master, loopable instrumental, no vocals
```

---

### 5. Abyssal Desperado (สไตล์ Persona 5: "Rivers in the Desert")
- **สไตล์ / Tags:** `Acid Jazz Funk Rock, Symphonic Strings, Slap Bass, Persona 5 Battle, Cinematic Heroic`
- **Master Prompt:**
```text
Acid jazz funk rock, dramatic symphonic anime boss battle, Persona 5 style, heroic confrontation, soaring staccato orchestral strings, heavy groovy slap bassline, tight funk wah-wah electric guitar, driving rock drums at 128 bpm, passionate solo violin melody, retro organ swells, tense, stylish, cinematic, epic gaming climax, punchy studio master, loopable instrumental, no vocals
```

---

### 6. Honey Buzz Fever (สไตล์ FFXIV Arcadion M2: "Back to the Drawing Board")
- **สไตล์ / Tags:** `Kawaii Anime Pop Punk, Electro Dance Rock, J-Pop Idol Battle, High BPM 172, Hyperactive`
- **Master Prompt:**
```text
Kawaii anime pop punk, hyperactive electro dance rock, J-pop idol battle theme, FFXIV Honey B Lovely style, bright bubbly lead synths, fast distorted punk power chords, relentless four-on-the-floor dance drums at 172 bpm, punchy slap bass, sparkling chiptune arpeggios, chaotic, playful, frantic, high-octane addictive melody, sweet yet aggressive energy, clean punchy mix, loopable instrumental, no vocals
```

---

### 7. Boardwalk Cafe Lofi (สไตล์จิบกาแฟคาเฟ่ริมน้ำ เดินเล่นตกปลาสายๆ ไม่ต้องคิดอะไร)
- **สไตล์ / Tags:** `Cozy Coffee Shop Lofi, Boardwalk Cafe Jazzhop, Felt Piano, Carefree Whistle, Mindful Relaxation`
- **Master Prompt:**
```text
Cozy coffee shop lofi beats, relaxed sunny morning fishing, seaside boardwalk cafe jazzhop, warm felt upright piano chords, lazy fingerstyle acoustic guitar, gentle carefree whistle melody, deep acoustic upright bass, soft brushed drums with wooden rimshot, vinyl crackle, subtle ceramic coffee cup ambient, relaxed tempo 80 bpm, peaceful, wholesome, mindful, healing video game background, seamless loopable instrumental, no vocals
```

---

## ขั้นตอนการนำไป Generate และอัปโหลดเข้าเกม Roblox

1. **เลือกเครื่องมือสร้างเสียง:**
   - **Suno AI (แนะนำ v3.5 หรือ v4):** ให้ทำนองและเมโลดี้ที่ติดหูมาก (อย่าลืมเปิดปุ่ม `Instrumental: On`)
   - **Udio:** คุณภาพเสียงและเนื้อเสียงดนตรีสมจริงมาก
2. **การดาวน์โหลดและแต่ง Loop:**
   - นำไฟล์ `.mp3` หรือ `.wav` ที่ได้เข้าโปรแกรมตัดต่อเสียง (เช่น Audacity)
   - ตัดหัว-ท้ายเพลงให้ต่อกันสนิท (Seamless Loop) หรือใส่ Fade สั้นๆ 0.1 วินาที
3. **การอัปโหลดเข้า Roblox:**
   - ไปที่ Roblox Creator Hub -> Creations -> Audio หรือใน Roblox Studio: Asset Manager -> Audio
   - เมื่ออัปโหลดเสร็จ ให้คัดลอก Asset ID (เช่น `rbxassetid://1234567890`)
4. **ใส่ Asset ID ในโปรเจกต์:**
   - เปิดไฟล์ `src/shared/Config/Sounds.luau`
   - ใส่ ID แทน `PLACEHOLDER` ในคีย์เพลงที่ต้องการ (เช่น `bgm_cafe`, `bgm_lake`, `bgm_aquarium`)
