# Kelp Whisper - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "KelpWhisper"
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

### Layer 1: Kelp Current & Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(110, 210, 120), Color3.fromRGB(40, 140, 80))`
- **Size:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.4), (1.0, 0.15) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.8), (0.4, 0.3), (0.8, 0.5), (1.0, 1.0) })`
- **Rate:** 12
- **Speed:** `NumberRange.new(0.9, 1.3)`
- **Lifetime:** `NumberRange.new(1.2, 1.6)`
- **Acceleration:** `Vector3.new(0, 0.7, 0)`
- **LightEmission:** 0.6
- **LightInfluence:** 0.4

### Layer 2: Ground Caustic (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(110, 210, 120))`
- **Size:** `NumberSequence.new({ (0.0, 1.0), (1.0, 2.5) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.4), (0.6, 0.6), (1.0, 1.0) })`
- **Rate:** 1.5
- **Lifetime:** `NumberRange.new(1.4, 1.8)`
- **LightEmission:** 0.5

### Layer 3: Oxygen Bubbles & Bio Spores (`05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(200, 255, 210), Color3.fromRGB(110, 210, 120))`
- **Size:** `NumberSequence.new({ (0.0, 0.1), (0.6, 0.22), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.8, 0.3), (1.0, 1.0) })`
- **Rate:** 8
- **Speed:** `NumberRange.new(0.6, 1.0)`
- **Lifetime:** `NumberRange.new(1.0, 1.5)`
- **LightEmission:** 0.7
