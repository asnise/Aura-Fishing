# Frost Pearl - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "FrostPearl"
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

### Layer 1: Glacial Vapor Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(235, 250, 255), Color3.fromRGB(160, 210, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.35), (0.6, 0.55), (1.0, 0.15) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.7), (0.4, 0.25), (0.8, 0.5), (1.0, 1.0) })`
- **Rate:** 26
- **Speed:** `NumberRange.new(1.0, 1.4)`
- **Lifetime:** `NumberRange.new(1.3, 1.7)`
- **Acceleration:** `Vector3.new(0, 0.7, 0)`
- **LightEmission:** 1.0
- **LightInfluence:** 0.2

### Layer 2: Frost Lattice Ground Ring (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(200, 240, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.9), (1.0, 2.7) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.55), (1.0, 1.0) })`
- **Rate:** 1.6
- **Lifetime:** `NumberRange.new(1.4, 1.8)`
- **LightEmission:** 0.8

### Layer 3: Pearl Crystals & Flakes (`05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 230, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.12), (0.6, 0.25), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.05), (0.7, 0.25), (1.0, 1.0) })`
- **Rate:** 14
- **Speed:** `NumberRange.new(0.6, 1.2)`
- **RotSpeed:** `NumberRange.new(-30, 30)`
- **Lifetime:** `NumberRange.new(1.2, 1.8)`
- **LightEmission:** 1.0

### Ambient Lighting: PointLight
- **Color:** `Color3.fromRGB(200, 235, 255)`
- **Brightness:** 1.3
- **Range:** 10
