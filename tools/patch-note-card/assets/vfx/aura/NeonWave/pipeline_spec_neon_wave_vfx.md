# Neon Wave - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "NeonWave"
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

### Layer 1: Bio-Wave Core Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 90, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.3), (0.6, 0.5), (1.0, 0.1) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.6), (0.4, 0.15), (0.8, 0.45), (1.0, 1.0) })`
- **Rate:** 18
- **Speed:** `NumberRange.new(1.5, 2.2)`
- **Lifetime:** `NumberRange.new(0.8, 1.2)`
- **Acceleration:** `Vector3.new(0, 1.2, 0)`
- **LightEmission:** 1.0
- **LightInfluence:** 0.2

### Layer 2: Bio-Tide Ground Crest (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(0, 200, 255))`
- **Size:** `NumberSequence.new({ (0.0, 1.0), (1.0, 2.8) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.5), (1.0, 1.0) })`
- **Rate:** 2.0
- **Lifetime:** `NumberRange.new(1.0, 1.4)`
- **LightEmission:** 0.9

### Layer 3: Glowing Plankton Motes (`05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(220, 250, 255), Color3.fromRGB(0, 200, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.15), (0.5, 0.25), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.05), (0.8, 0.2), (1.0, 1.0) })`
- **Rate:** 14
- **Speed:** `NumberRange.new(0.8, 1.5)`
- **Lifetime:** `NumberRange.new(0.8, 1.2)`
- **LightEmission:** 1.0

### Ambient Lighting: PointLight
- **Color:** `Color3.fromRGB(0, 200, 255)`
- **Brightness:** 1.5
- **Range:** 10
