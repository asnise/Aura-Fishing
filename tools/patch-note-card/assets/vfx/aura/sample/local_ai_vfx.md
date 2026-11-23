# คู่มือขั้นตอนการนำภาพ VFX เข้า Local AI เพื่อประกอบใช้งานจริง

คู่มือนี้อธิบายวิธีใช้ไฟล์ `aura_vfx_pipeline.md` ร่วมกับเครื่องมือ Local AI Coding Agent (เช่น **Cline, Roo Code, Cursor, Claude Code, Windsurf, Aider** ที่ต่อกับ Model Local ผ่าน Ollama / LM Studio หรือ API) เพื่อแปลงภาพ Flipbook ดิบให้กลายเป็นเอฟเฟกต์ Aura พร้อมใช้ในเกม

---

## Step 0: (ทางเลือก) ปรับคุณภาพภาพด้วย ComfyUI Local ก่อนเริ่ม
*ข้ามขั้นตอนนี้ได้ถ้าภาพที่เจนมาชัดและเฟรมครบแล้ว*
- **กรณีภาพแตก/ความละเอียดต่ำ:** ใช้ ComfyUI รัน Upscaler (เช่น `4x-UltraSharp` หรือ `RealESRGAN`) แล้วค่อยย่อลงเป็น `1024x1024` หรือ `2048x2048`
- **กรณีอยากให้แอนิเมชันลื่นขึ้น:** ถ้าเจนเป็นวิดีโอสั้นๆ แทน Grid ให้ใช้ Node **RIFE VFI** ใน ComfyUI แทรกเฟรมก่อน แล้วค่อย Export เป็น Sprite Sheet 4x4

---

## Step 1: จัดเตรียมโครงสร้างโฟลเดอร์

สร้างโฟลเดอร์โปรเจกต์ แล้วนำภาพที่เจนมาเปลี่ยนชื่อและวางให้ตรงตามโครงสร้างนี้ (ไม่จำเป็นต้องมีครบทั้ง 6 ไฟล์ มีเท่าไหนก็วางเท่านั้นได้):

```text
my_aura_vfx/
├── aura_vfx_pipeline.md          <-- ไฟล์สเปกสำหรับให้ AI อ่าน
└── raw_ai_images/
    ├── 01_core_wisps_4x4.png     <-- เปลวไฟ/ควัน (4x4)
    ├── 02_ground_burst_4x4.png   <-- แฉกพลังงานบนพื้น (4x4)
    ├── 03_orbital_arc_4x4.png    <-- วงโค้งพลังงาน แบบ Flipbook (หรือใช้แบบ Strip ด้านล่าง)
    ├── 03_orbital_strip.png      <-- วงโค้งพลังงาน แบบ Strip ยาว (ถ้ามี)
    ├── 04_star_flares_4x4.png    <-- แสงแฟลร์ 4 แฉก (4x4)
    └── 05_sparks_atlas_2x2.png   <-- สะเก็ด/เม็ดแสง/เศษเหลี่ยม (2x2)
```

---

## Step 2: ตั้งค่า Engine ในไฟล์สเปก

เปิดไฟล์ `aura_vfx_pipeline.md` แล้วแก้ตรงหัวข้อ **`0. Project Configuration`** ให้ตรงกับเกมเอนจินที่คุณใช้ เช่น:
```yaml
TARGET_ENGINE: "Unity URP"   # เปลี่ยนเป็น "Godot 4", "Unreal Engine 5", หรือ "Three.js" ได้
```

---

## Step 3: สั่งงาน Local AI ทีละเฟส (สำคัญมาก!)

> **ทริคสำคัญสำหรับ Local AI:** อย่าสั่งให้ AI ทำทีเดียวทั้ง 3 เฟสในคำสั่งเดียว เพราะภาพจาก AI มักจะมีเฟรมเบี้ยวหรือพื้นหลังเทาปนอยู่ ควรสั่งทำ **Phase 1 ให้ภาพสะอาดและเช็ก GIF ก่อน** แล้วค่อยไปทำ Shader และประกอบ Particle ครับ

### เฟสที่ 1: ล้างพื้นหลัง + ตัด Grid + แก้เฟรมสั่น (Python)
เปิด Local AI Agent ในโฟลเดอร์ `my_aura_vfx/` แล้วก๊อปปี้คำสั่งนี้ไปวาง:

```text
Read aura_vfx_pipeline.md carefully.
Execute ONLY Phase 1 right now:
1. Create scripts/process_vfx_assets.py using Pillow and numpy.
2. Run the script on all images currently inside ./raw_ai_images/.
3. Output the cleaned RGBA textures to ./processed_vfx/textures/ and animated preview GIFs to ./processed_vfx/previews/.
4. Show me a summary of each processed file and any warnings.
```

**สิ่งที่คุณต้องทำหลัง AI รันเสร็จ (Visual QA):**
เปิดดูไฟล์ `.gif` ในโฟลเดอร์ `processed_vfx/previews/`
- **ถ้าเห็นกรอบสี่เหลี่ยมจางๆ หรือพื้นหลังไม่ดำสนิท:** พิมพ์บอก AI ว่า
  > *"ไฟล์ `01_core_wisps_4x4.png` ยังมีฝุ่นพื้นหลังติดอยู่ ช่วยปรับ `black_cut` เป็น `0.12` แล้วรันใหม่"*
- **ถ้าเฟรมกระโดด/สั่น หรือมีเฟรมเสีย (เช่น เฟรมที่ 16 เพี้ยน):** พิมพ์บอก AI ว่า
  > *"ใน `04_star_flares_4x4.png` เฟรมที่ 15-16 ภาพเสีย ช่วยข้าม 2 เฟรมนั้นหรือปรับ `border_crop` เป็น `0.05` แล้วรันใหม่"*

---

### เฟสที่ 2: ให้ AI เขียน Shader ย้อมสี HDR และทำ Dissolve
เมื่อเช็ก GIF แล้วภาพสวยและนิ่งดี ให้ส่งคำสั่งนี้ต่อ:

```text
Phase 1 looks good. Now execute Phase 2 from aura_vfx_pipeline.md.
Generate the Stylized Aura VFX Shader for my TARGET_ENGINE.
Ensure it supports:
- Flipbook frame interpolation (smooth blending between frames)
- Both Alpha Blend (for dark silhouette) and Additive (for HDR glow) modes
- 3-stop color gradient mapping from luminance (Outer -> Mid -> Core)
- Vertex color alpha erosion/dissolve
Explain briefly where to place the shader file in my project.
```

---

### เฟสที่ 3: ให้ AI สร้างสคริปต์/Prefab ประกอบเป็น Aura 3 ระดับ
เมื่อได้ Shader แล้ว ส่งคำสั่งสุดท้ายเพื่อให้ AI ประกอบ Layer ทั้งหมดตามตาราง Sorting Order:

```text
Now execute Phase 3 from aura_vfx_pipeline.md.
Generate the setup script / scene / prefab builder for my TARGET_ENGINE that assembles Aura_Tier1, Aura_Tier2, and Aura_Tier3 using the processed textures from ./processed_vfx/textures/ and the shader from Phase 2.
Follow the exact Sort Order, Blend Modes, and Color Palette (Dark Indigo/Black silhouette + Arcane Blue #2E7BFF + White HDR Core + Magenta #FF4FD8 accents) defined in Section 4.
```

---

## Step 4: จูนแสงสุดท้ายใน Engine ให้เหมือนวิดีโอตัวอย่าง

หลังจากนำเข้า Engine เรียบร้อยแล้ว สิ่งที่ทำให้ Aura ดูพุ่งและคมเหมือนสไตล์อนิเมะคือ **Post-Processing Bloom**:
1. เปิด **Bloom** ใน Volume / WorldEnvironment ของโปรเจกต์
2. ตั้งค่า **Bloom Threshold** ไว้ที่ประมาณ `1.0 – 1.2` (เพื่อให้เฉพาะส่วน Core สีขาว/ฟ้าที่มีค่า HDR Intensity `> 1.5` เรืองแสงออกมา ส่วนเงาสีดำด้านหลังจะยังคงคมชัดไม่ฟุ้ง)
3. ตั้งค่า **Bloom Intensity** ประมาณ `0.4 – 0.8` และใช้ **ACES Tonemapping** เพื่อให้สีฟ้าสว่างจัดไล่เฉดเข้าหาแกนสีขาวได้อย่างเป็นธรรมชาติ