# Dragon Emperor - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "DragonEmperor"
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

### Layer 1: Sovereign Vapor Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0))`
- **Size:** `NumberSequence.new({ (0.0, 0.45), (0.6, 0.8), (1.0, 0.2) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.6), (0.4, 0.15), (0.8, 0.45), (1.0, 1.0) })`
- **Rate:** 50
- **Speed:** `NumberRange.new(2.5, 4.0)`
- **RotSpeed:** `NumberRange.new(-90, 90)`
- **Lifetime:** `NumberRange.new(1.1, 1.5)`
- **Acceleration:** `Vector3.new(0, 1.6, 0)`
- **LightEmission:** 1.0
- **LightInfluence:** 0.1

### Layer 2: Dragon Crest Ground Disk (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 215, 0))`
- **Size:** `NumberSequence.new({ (0.0, 1.2), (1.0, 3.4) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.5), (1.0, 1.0) })`
- **Rate:** 2.2
- **Lifetime:** `NumberRange.new(1.2, 1.6)`
- **LightEmission:** 0.9

### Layer 3: Dragon Scales & Golden Embers (`05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 255, 200), Color3.fromRGB(255, 180, 0))`
- **Size:** `NumberSequence.new({ (0.0, 0.15), (0.5, 0.3), (1.0, 0.05) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.05), (0.7, 0.2), (1.0, 1.0) })`
- **Rate:** 20
- **Speed:** `NumberRange.new(1.0, 2.0)`
- **Lifetime:** `NumberRange.new(1.0, 1.5)`
- **LightEmission:** 1.0

### Ambient Lighting: PointLight
- **Color:** `Color3.fromRGB(255, 215, 50)`
- **Brightness:** 1.8
- **Range:** 12
