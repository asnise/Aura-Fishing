# Celestial Leviathan - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "CelestialLeviathan"
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

### Layer 1: Celestial Aurora Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 140, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.5), (0.6, 1.0), (1.0, 0.25) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.6), (0.4, 0.15), (0.8, 0.45), (1.0, 1.0) })`
- **Rate:** 60
- **Speed:** `NumberRange.new(2.8, 4.2)`
- **RotSpeed:** `NumberRange.new(-60, 60)`
- **Lifetime:** `NumberRange.new(1.3, 1.8)`
- **Acceleration:** `Vector3.new(0, 1.8, 0)`
- **LightEmission:** 1.0
- **LightInfluence:** 0.1

### Layer 2: Constellation Ground Pond (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(210, 190, 255))`
- **Size:** `NumberSequence.new({ (0.0, 1.3), (1.0, 3.6) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.2), (0.7, 0.5), (1.0, 1.0) })`
- **Rate:** 2.2
- **RotSpeed:** `NumberRange.new(10, 25)`
- **Lifetime:** `NumberRange.new(1.4, 1.8)`
- **LightEmission:** 0.9

### Layer 3: Astral Stardust & Glints (`05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 140, 255))`
- **Size:** `NumberSequence.new({ (0.0, 0.18), (0.5, 0.32), (1.0, 0.05) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.0), (0.7, 0.2), (1.0, 1.0) })`
- **Rate:** 24
- **Speed:** `NumberRange.new(1.0, 2.2)`
- **Lifetime:** `NumberRange.new(1.2, 1.7)`
- **LightEmission:** 1.0

### Ambient Lighting: PointLight
- **Color:** `Color3.fromRGB(220, 200, 255)`
- **Brightness:** 2.0
- **Range:** 13
