# Abyssal Shadow - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "AbyssalShadow"
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

### Layer 1: Abyssal Plumes Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(110, 40, 170), Color3.fromRGB(10, 0, 20))`
- **Size:** `NumberSequence.new({ (0.0, 0.4), (0.7, 1.0), (1.0, 0.2) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.5), (0.4, 0.1), (0.8, 0.4), (1.0, 1.0) })`
- **Rate:** 35
- **Speed:** `NumberRange.new(1.2, 1.8)`
- **RotSpeed:** `NumberRange.new(-45, 45)`
- **Lifetime:** `NumberRange.new(1.4, 1.8)`
- **Acceleration:** `Vector3.new(0, 0.9, 0)`
- **LightEmission:** 0.3 (คงความมืดแบบ Dark Silhouette ตามสเปก)
- **LightInfluence:** 0.6

### Layer 2: Deep Trench Pool Disk (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(80, 20, 120))`
- **Size:** `NumberSequence.new({ (0.0, 1.2), (1.0, 3.2) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.15), (0.7, 0.45), (1.0, 1.0) })`
- **Rate:** 2.0
- **Lifetime:** `NumberRange.new(1.4, 1.8)`
- **LightEmission:** 0.2

### Layer 3: Bio-Amethyst Spores (`04_flares`, `05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(200, 130, 255), Color3.fromRGB(110, 40, 170))`
- **Size:** `NumberSequence.new({ (0.0, 0.12), (0.5, 0.22), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.05), (0.7, 0.25), (1.0, 1.0) })`
- **Rate:** 12
- **Speed:** `NumberRange.new(0.6, 1.2)`
- **Lifetime:** `NumberRange.new(1.0, 1.5)`
- **LightEmission:** 0.8
