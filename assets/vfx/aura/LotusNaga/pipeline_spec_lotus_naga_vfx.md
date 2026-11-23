# Lotus Naga - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "LotusNaga"
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

### Layer 1: Sacred Jade Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(60, 200, 130), Color3.fromRGB(255, 150, 200))`
- **Size:** `NumberSequence.new({ (0.0, 0.4), (0.6, 0.8), (1.0, 0.2) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.6), (0.4, 0.15), (0.8, 0.45), (1.0, 1.0) })`
- **Rate:** 38
- **Speed:** `NumberRange.new(1.3, 1.9)`
- **RotSpeed:** `NumberRange.new(-60, 60)`
- **Lifetime:** `NumberRange.new(1.3, 1.7)`
- **Acceleration:** `Vector3.new(0, 1.1, 0)`
- **LightEmission:** 0.9
- **LightInfluence:** 0.2

### Layer 2: Lotus Blessing Ground Disk (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(60, 200, 130))`
- **Size:** `NumberSequence.new({ (0.0, 1.0), (1.0, 3.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.5), (1.0, 1.0) })`
- **Rate:** 1.8
- **Lifetime:** `NumberRange.new(1.3, 1.7)`
- **LightEmission:** 0.8

### Layer 3: Lotus Petals & Gold Motes (`05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 150, 200), Color3.fromRGB(255, 215, 80))`
- **Size:** `NumberSequence.new({ (0.0, 0.15), (0.5, 0.28), (1.0, 0.05) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.05), (0.7, 0.2), (1.0, 1.0) })`
- **Rate:** 16
- **Speed:** `NumberRange.new(0.8, 1.5)`
- **Lifetime:** `NumberRange.new(1.1, 1.6)`
- **LightEmission:** 0.95

### Ambient Lighting: PointLight
- **Color:** `Color3.fromRGB(90, 220, 150)`
- **Brightness:** 1.5
- **Range:** 11
