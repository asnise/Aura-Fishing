# VFX Production Pipeline Specification: Stylized Dark-Arcane Aura

> **Instructions for AI Agent:** Read this specification completely before writing code. Execute **one Phase at a time** as requested by the user. Do not skip verification steps.

---

## 0. Project Configuration (User Editable)

```yaml
TARGET_ENGINE: "Unity URP" # Options: "Unity URP" | "Godot 4" | "Unreal Engine 5" | "Three.js"
INPUT_DIR: "./raw_ai_images"
OUTPUT_DIR: "./processed_vfx"
SCRIPTS_DIR: "./scripts"
DEFAULT_ATLAS_SIZE: 1024   # Power-of-two (1024 or 2048 for 4x4 flipbooks, 512 for 2x2 static)
TARGET_FPS: 18             # Default playback speed for 4x4 flipbooks
```

---

## 1. Input Asset Inventory

Expect monochrome (white-on-black) AI-generated PNGs inside `INPUT_DIR`. If any file is missing, log a warning and process all available files without crashing.

| Filename | Type | Grid | Anchor Mode | Role |
| :--- | :--- | :--- | :--- | :--- |
| `01_core_wisps_4x4.png` | Flipbook | 4x4 (16 frames) | `bottom_center` | Rising dark silhouette smoke & blue energy flames |
| `02_ground_burst_4x4.png` | Flipbook | 4x4 (16 frames) | `center` | Top-down radial spiky shockwave on ground |
| `03_orbital_arc_4x4.png` | Flipbook | 4x4 (16 frames) | `center` | Sweeping crescent slash arc (Tier 3 option A) |
| `03_orbital_strip.png` | Tileable Strip | 1x1 (Seamless X) | `none` | Panning slash trail for 3D ring mesh (Tier 3 option B) |
| `04_star_flares_4x4.png` | Flipbook | 4x4 (16 frames) | `center` | Expanding/contracting 4-point anime star glints |
| `05_sparks_atlas_2x2.png` | Static Atlas | 2x2 (4 sprites) | `center` | Orbs, needle streaks, diamond shards, droplets |

---

## 2. Phase 1: Automated Image Cleaning & Repacking (Python)

Create `scripts/process_vfx_assets.py` using `Pillow` and `numpy` (avoid heavy dependencies unless already installed). Support CLI flags so parameters can be tuned per asset.

### Required Processing Steps

1. **Grayscale Conversion & Black-Point Clamping (De-noising):**
   * Convert input to float32 grayscale luminance $L \in [0.0, 1.0]$.
   * Remove AI dark-background artifacts (e.g., gray compression noise) using a configurable levels remap:
     * Pixels where $L \le \text{black\_cut}$ (default `0.07`) become strictly `0.0`.
     * Pixels where $L \ge \text{white\_cut}$ (default `0.95`) become `1.0`.
     * Apply subtle contrast/gamma curve (`gamma`, default `1.0`) to keep sharp cel-shaded silhouettes.

2. **Grid Slicing & Border Safety Margin:**
   * Divide grid evenly by `(rows, cols)`.
   * Apply a small inward crop margin (`border_crop`, default `0.03` = 3% per side) or zero-out outer edges to remove accidental AI grid lines or bleed from neighboring frames.

3. **Anti-Jitter Stabilization (Smart Re-centering):**
   * For each sliced frame, compute the bounding box of active pixels ($L > 0.05$).
   * Support optional `skip_frames` list (e.g., if frame 15 is corrupted) and resample/duplicate cleanly if needed.
   * Repack each frame onto a clean cell canvas with safety padding (`cell_padding_ratio = 0.08`) using the asset's `Anchor Mode`:
     * `center`: Align frame's bounding-box center (or luminance-weighted centroid) to cell center.
     * `bottom_center`: Align horizontally to center, and anchor the bottom of the flame base consistently near `y = 0.88 * cell_height` so rising flames do not jump vertically.
   * Maintain consistent uniform scaling across all 16 frames of a flipbook based on the maximum bounding dimension across the sequence (preventing sudden size popping).

4. **Seamless Horizontal Blending (Only for `03_orbital_strip.png`):**
   * Resize to Power-of-Two strip (e.g., `1024x256`).
   * Enforce horizontal seamless tiling by cross-fading the outer 8% left/right edges cleanly, and fade top/bottom 4% edges to `0.0` so UV clamping never produces hard lines.

5. **Game-Ready RGBA Export:**
   * Pack output PNG as RGBA where `R = G = B = cleaned_luma` and `A = cleaned_luma`.
   * *Shader Note:* Storing cleaned luminance in both RGB and Alpha ensures easy visual inspection while allowing the shader to read `.r` for Color Gradient Mapping and `.a` for Opacity/Dissolve without double-premultiplication artifacts.
   * Save cleaned textures to `OUTPUT_DIR/textures/`.

6. **Visual QA Outputs & Manifest:**
   * Generate looping animated `.gif` previews (at `TARGET_FPS`) for every flipbook into `OUTPUT_DIR/previews/` on a pure black background so the user can visually verify frame alignment and smoothness.
   * Generate a contact-sheet debug overlay (optional `--debug-grid`) showing cell boundaries.
   * Export `OUTPUT_DIR/vfx_manifest.json` containing final texture paths, resolutions, rows/cols, and anchor metadata.

---

## 3. Phase 2: Real-Time Stylized Aura Shader

Generate a single master VFX shader tailored to `TARGET_ENGINE` (e.g., `StylizedAuraVFX.shader` for Unity URP, `stylized_aura_vfx.gdshader` for Godot 4, or custom `ShaderMaterial` for Three.js).

### Required Shader Features

1. **Dual Blend Mode Support:**
   * Support switching between **Alpha Blend** (`SrcAlpha OneMinusSrcAlpha`, ZWrite Off) for dark under-layer silhouettes and **Additive** (`SrcAlpha One`, ZWrite Off) for glowing HDR energy.
   * Cull Off (double-sided) for 3D orbital meshes.

2. **Smooth Flipbook Interpolation:**
   * Support `_Rows`, `_Cols`, and `_Frame` (or Particle Custom Data / Vertex UV2).
   * Sample frame $N$ and frame $N+1$ and blend via `lerp` using `frac(frame)` to achieve smooth motion even at 16 frames.

3. **UV Panning Mode (Toggleable):**
   * Allow scrolling UVs over time (`_ScrollSpeed.xy`) for `03_orbital_strip.png`.

4. **3-Stop Stylized Color Ramp (Dual-Tint + HDR Core):**
   * Use raw sampled luminance `luma = tex.r` (do **not** premultiply by alpha before gradient lookup).
   * Map `luma` through 3 configurable color stops:
     * **Outer Color (`_ColorOuter`):** Low luma ($0.0 \to 0.35$) — e.g., Dark Indigo `#150830` or Deep Black `#05050A`.
     * **Mid Color (`_ColorMid`):** Mid luma ($0.35 \to 0.75$) — e.g., Arcane Blue `#2E7BFF` with HDR multiplier (`_EmissionIntensity`).
     * **Core Color (`_ColorCore`):** High luma ($0.75 \to 1.0$) — e.g., Pure White `#FFFFFF` with high HDR boost for Bloom.
   * Multiply final color by Vertex Color RGB (enables per-particle Pink/Magenta `#FF4FD8` accent variation).

5. **Erosion / Alpha Cutoff:**
   * Drive stylized cel-shaded dissolve using Vertex Color Alpha:
     `alpha = smoothstep(_DissolveThreshold, _DissolveThreshold + _EdgeSoftness, luma) * vertexColor.a`
   * Keep `_EdgeSoftness` low (`0.05–0.15`) to preserve crisp anime brushwork edges.

---

## 4. Phase 3: 3-Tier Aura Assembly Blueprint

Generate an engine-native setup script / prefab builder / scene file that constructs **3 Aura Presets** (`Aura_Tier1`, `Aura_Tier2`, `Aura_Tier3`) matching the visual hierarchy below.

### Layer Architecture & Render Order

| Sort Order | Layer Name | Texture | Blend Mode | Color Palette (Hex / HDR) | Transform & Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0` | `Ground_Dark` | `02_ground_burst` | Alpha Blend | `#05050A` (Intensity `1.0`) | Horizontal billboard on floor, random Y-rot, slightly larger scale (`1.15x`) |
| `1` | `Ground_Energy` | `02_ground_burst` | Additive | `#2E7BFF` -> `#FFFFFF` (`3.5`) | Horizontal billboard on floor, random Y-rot, scale `1.0x` |
| `2` | `Core_DarkWisps` | `01_core_wisps` | Alpha Blend | `#070612` (Intensity `1.0`) | Vertical/Camera billboard, bottom pivot, scale `1.15x` (creates dark outline silhouette) |
| `3` | `Core_BlueFlames` | `01_core_wisps` | Additive | `#2E7BFF` -> `#A8E6FF` (`4.0`) | Vertical/Camera billboard, bottom pivot, scale `1.0x`, fast flipbook (`18–22 fps`) |
| `4` | `Core_SoftGlow` | `05_sparks` (Frame 0 Orb) | Additive | `#4D8CFF` -> `#FFFFFF` (`5.0`) | Center billboard, gentle pulse scale (`0.9x–1.1x`), drives Bloom core |
| `5` | `Star_Flares` | `04_star_flares` | Additive | `#80D4FF` -> `#FFFFFF` (`6.0`) | Random offset near core, random rotation, quick burst lifetime (`0.25–0.45s`) |
| `6` | `Sparks_Needles` | `05_sparks` (Frame 1) | Additive | `#2E7BFF` & `#FF4FD8` (`4.5`) | Stretched billboard shooting radially outward, drag slowdown |
| `7` | `Shards_Flakes` | `05_sparks` (Frame 2, 3) | Additive | `#C45EFF` & `#FF4FD8` (`3.5`) | Angular shards drifting outward/upward with gentle spin |
| `8` | `Orbital_Arcs` *(Tier 3)* | `03_orbital_arc` or `strip` | Additive | `#1E6BFF` -> `#FFFFFF` (`4.5`) | 2–3 tilted rings/arcs rotating on opposing XYZ axes around the core |

### Tier Progression Rules
* **Tier 1 (Low):** Layers `0–5` active. Moderate emission rate, compact radius.
* **Tier 2 (Medium):** Adds Layers `6–7` (Sparks & Shards with Magenta `#FF4FD8` accent), +30% scale, faster flame speed.
* **Tier 3 (Max / Full Surge):** Adds Layer `8` (2–3 Orbital Crescent Arcs spinning around the aura), +50% core HDR intensity, stronger Bloom trigger.

---

## 5. Verification Checklist (Definition of Done)

Before reporting completion of each phase, verify:
- [ ] **Phase 1:** All output textures are Power-of-Two, pure black background (`RGB = 0, A = 0`), no visible square box edges, and `.gif` previews play without severe frame jumping.
- [ ] **Phase 2:** Shader compiles with zero warnings/errors in `TARGET_ENGINE` and supports both Alpha Blend (dark wisps) and Additive (glowing flames) from the same monochrome texture.
- [ ] **Phase 3:** All 3 Tiers render with dark silhouettes clearly visible behind bright HDR cores (requires Post-Processing Bloom enabled with Threshold `~1.0–1.2`).