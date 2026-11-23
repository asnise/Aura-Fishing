# Storm Current - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "StormCurrent"
DEFAULT_ATLAS_SIZE: 1024
BLACK_CUT: 0.05
WHITE_CUT: 0.95
BORDER_CROP: 0.03
ANCHOR_MODE_CORE: "bottom_center"
ANCHOR_MODE_GROUND: "center"
TARGET_FPS: 18
```

---

## 2. พารามิเตอร์ Roblox Studio ParticleEmitter (Phase 2 & 3)

### Layer 1: Swirling Vortex Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(150, 220, 255), Color3.fromRGB(80, 160, 240))`
- **Size:** `NumberSequence.new({ (0.0, 0.3), (0.6, 0.5), (1.0, 0.1) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.5), (0.4, 0.2), (0.8, 0.45), (1.0, 1.0) })`
- **Rate:** 24
- **Speed:** `NumberRange.new(2.5, 3.5)`
- **RotSpeed:** `NumberRange.new(-180, 180)`
- **Lifetime:** `NumberRange.new(0.6, 0.9)`
- **Acceleration:** `Vector3.new(0, 1.5, 0)`
- **LightEmission:** 1.0
- **LightInfluence:** 0.2

### Layer 2: Ground Swirling Vortex (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(150, 220, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.9), (1.0, 2.7) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.5), (1.0, 1.0) })`
- **Rate:** 2.2
- **RotSpeed:** `NumberRange.new(90, 140)`
- **Lifetime:** `NumberRange.new(0.8, 1.1)`
- **LightEmission:** 0.8

### Layer 3: Static Gold Sparks (`04_flares`, `05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 255, 200), Color3.fromRGB(255, 220, 90))`
- **Size:** `NumberSequence.new({ (0.0, 0.1), (0.5, 0.2), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.0), (0.7, 0.2), (1.0, 1.0) })`
- **Rate:** 12
- **Speed:** `NumberRange.new(1.0, 2.0)`
- **Lifetime:** `NumberRange.new(0.4, 0.7)`
- **LightEmission:** 1.0

### Ambient Lighting: PointLight
- **Color:** `Color3.fromRGB(150, 220, 255)`
- **Brightness:** 1.4
- **Range:** 10
