# Sparkling Dew - VFX Pipeline & Engine Specification

เอกสารกำหนดพารามิเตอร์ทางเทคนิคสำหรับ AI Agent นำภาพไปตัดต่อและสร้าง Particle ใน Roblox Studio

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "SparklingDew"
DEFAULT_ATLAS_SIZE: 1024
BLACK_CUT: 0.05
WHITE_CUT: 0.95
BORDER_CROP: 0.03
ANCHOR_MODE_CORE: "bottom_center"
ANCHOR_MODE_GROUND: "center"
TARGET_FPS: 14
```

---

## 2. พารามิเตอร์ Roblox Studio ParticleEmitter (Phase 2 & 3)

### Layer 1: Core Dew Plumes (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(180, 240, 255), Color3.fromRGB(220, 250, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.35), (1.0, 0.1) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.8), (0.3, 0.2), (0.8, 0.4), (1.0, 1.0) })`
- **Rate:** 8
- **Speed:** `NumberRange.new(0.8, 1.2)`
- **Lifetime:** `NumberRange.new(1.0, 1.4)`
- **Acceleration:** `Vector3.new(0, 0.8, 0)`
- **LightEmission:** 0.8
- **LightInfluence:** 0.3

### Layer 2: Ground Ripple (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(180, 240, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.8), (1.0, 2.2) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.4), (0.7, 0.7), (1.0, 1.0) })`
- **Rate:** 1.5
- **Speed:** `NumberRange.new(0, 0)`
- **Lifetime:** `NumberRange.new(1.2, 1.6)`
- **LightEmission:** 0.6

### Layer 3: Dew Droplets & Glints (`04_flares`, `05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 240, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.08), (0.5, 0.18), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.1), (0.8, 0.3), (1.0, 1.0) })`
- **Rate:** 6
- **Speed:** `NumberRange.new(0.4, 0.8)`
- **SpreadAngle:** `Vector2.new(180, 180)`
- **Lifetime:** `NumberRange.new(0.8, 1.2)`
- **LightEmission:** 0.9
