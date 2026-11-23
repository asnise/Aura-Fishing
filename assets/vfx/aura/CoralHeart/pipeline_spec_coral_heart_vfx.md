# Coral Heart - VFX Pipeline & Engine Specification

---

## 1. การประมวลผล Texture (Phase 1 Parameters)

```yaml
ASSET_NAME: "CoralHeart"
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

### Layer 1: Coral Pulse Mist (`01_core`)
- **Parent:** `Attachment` (Position: `0, -1.5, 0` ใน `HumanoidRootPart`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 150, 160), Color3.fromRGB(255, 100, 130))`
- **Size:** `NumberSequence.new({ (0.0, 0.25), (0.6, 0.45), (1.0, 0.1) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.7), (0.4, 0.2), (0.8, 0.4), (1.0, 1.0) })`
- **Rate:** 12
- **Speed:** `NumberRange.new(1.0, 1.4)`
- **Lifetime:** `NumberRange.new(1.0, 1.4)`
- **Acceleration:** `Vector3.new(0, 0.8, 0)`
- **LightEmission:** 0.8
- **LightInfluence:** 0.3

### Layer 2: Reef Ground Heartbeat (`02_ground`)
- **Orientation:** `FacingCameraUp`
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 100, 130))`
- **Size:** `NumberSequence.new({ (0.0, 0.8), (1.0, 2.3) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.3), (0.7, 0.6), (1.0, 1.0) })`
- **Rate:** 1.3
- **Lifetime:** `NumberRange.new(1.2, 1.6)`
- **LightEmission:** 0.6

### Layer 3: Polyp Embers (`05_sparks`)
- **Color:** `ColorSequence.new(Color3.fromRGB(255, 200, 210), Color3.fromRGB(255, 100, 130))`
- **Size:** `NumberSequence.new({ (0.0, 0.12), (0.5, 0.2), (1.0, 0.0) })`
- **Transparency:** `NumberSequence.new({ (0.0, 0.1), (0.8, 0.3), (1.0, 1.0) })`
- **Rate:** 9
- **Speed:** `NumberRange.new(0.6, 1.0)`
- **Lifetime:** `NumberRange.new(1.0, 1.5)`
- **LightEmission:** 0.9
