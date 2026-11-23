# Solar Flare - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "SolarFlare"
DEFAULT_ATLAS_SIZE: 1024
BLACK_CUT: 0.05
WHITE_CUT: 0.95
BORDER_CROP: 0.03
ANCHOR_MODE_CORE: "bottom_center"
ANCHOR_MODE_GROUND: "center"
TARGET_FPS: 16
```

---

## 2. พารามิเตอร์ Roblox Studio ParticleEmitter (Phase 2 & 3)

### Layer 1: Solar Vapor Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 80, 0))`
- **Size:** `NumberSequence.new({ (0.0, 0.4), (0.6, 0.65), (1.0, 0.15) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.6), (0.4, 0.15), (0.8, 0.45), (1.0, 1.0) })`
- **Rate:** 30
- **Speed:** `NumberRange.new(2.2, 3.2)`
- **RotSpeed:** `NumberRange.new(-90, 90)`
- **Lifetime:** `NumberRange.new(0.7, 1.0)`
- **Acceleration:** `Vector3.new(0, 1.8, 0)`
- **LightEmission:** 1.0
- **LightInfluence:** 0.15

### Layer 2: Sunburst Ground Halo (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 220, 80))`
- **Size:** `NumberSequence.new({ (0.0, 1.0), (1.0, 2.9) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.5), (1.0, 1.0) })`
- **Rate:** 2.0
- **Lifetime:** `NumberRange.new(1.0, 1.4)`
- **LightEmission:** 0.9

### Layer 3: Golden Water Diamonds (`04_flares`, `05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 255, 220), Color3.fromRGB(255, 180, 50))`
- **Size:** `NumberSequence.new({ (0.0, 0.15), (0.5, 0.28), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.05), (0.7, 0.2), (1.0, 1.0) })`
- **Rate:** 16
- **Speed:** `NumberRange.new(1.0, 1.8)`
- **Lifetime:** `NumberRange.new(0.6, 1.0)`
- **LightEmission:** 1.0

### Ambient Lighting: PointLight
- **Color:** `Color3.fromRGB(255, 200, 70)`
- **Brightness:** 1.6
- **Range:** 11
