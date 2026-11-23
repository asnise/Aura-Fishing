# Serpent of the Void - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "SerpentOfTheVoid"
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

### Layer 1: Planar Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 120, 220), Color3.fromRGB(90, 220, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.45), (0.6, 0.9), (1.0, 0.2) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.6), (0.4, 0.15), (0.8, 0.45), (1.0, 1.0) })`
- **Rate:** 42
- **Speed:** `NumberRange.new(1.8, 2.5)`
- **RotSpeed:** `NumberRange.new(-90, 90)`
- **Lifetime:** `NumberRange.new(1.2, 1.6)`
- **Acceleration:** `Vector3.new(0, 1.3, 0)`
- **LightEmission:** 1.0
- **LightInfluence:** 0.15

### Layer 2: Void Caustic Ground Disk (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(90, 220, 255))`
- **Size:** `NumberSequence.new({ (0.0, 1.1), (1.0, 3.2) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.5), (1.0, 1.0) })`
- **Rate:** 2.0
- **Lifetime:** `NumberRange.new(1.3, 1.7)`
- **LightEmission:** 0.85

### Layer 3: Planar Shards & Scales (`05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 120, 220), Color3.fromRGB(90, 220, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.15), (0.5, 0.28), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.05), (0.7, 0.25), (1.0, 1.0) })`
- **Rate:** 18
- **Speed:** `NumberRange.new(1.0, 1.8)`
- **Lifetime:** `NumberRange.new(0.9, 1.4)`
- **LightEmission:** 1.0

### Ambient Lighting: PointLight
- **Color:** `Color3.fromRGB(150, 180, 255)`
- **Brightness:** 1.6
- **Range:** 12
