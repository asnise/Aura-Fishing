"""Compare a Figma export with a Studio capture of the same screen.

  python -I tools/ui/compare.py <figma.png> <studio.png> <out_prefix> [--tile=40]

Studio is resized to the Figma size (Figma frames are exported at scale 1). Writes:
  <out_prefix>_side.png  Figma | Studio | diff heatmap (red = different)
  <out_prefix>_top.png   Figma | Studio crops of the worst tiles, stacked
Prints the mean difference and the worst tiles (x, y in Figma px) so they can be fixed one by one.
"""
import sys

import numpy as np
from PIL import Image, ImageDraw

args = [a for a in sys.argv[1:] if not a.startswith("--")]
if len(args) != 3:
    print(__doc__)
    sys.exit(2)
tile = int(next((a.split("=")[1] for a in sys.argv if a.startswith("--tile=")), 40))
figma_path, studio_path, prefix = args

fig = Image.open(figma_path).convert("RGB")
stu = Image.open(studio_path).convert("RGB").resize(fig.size, Image.LANCZOS)
a = np.asarray(fig).astype(np.int16)
b = np.asarray(stu).astype(np.int16)


# Align: Figma exports include effect bounds (shadows) that may be asymmetric, so find the shift of the
# Studio image (+-24 px) that best matches, on a downscaled grey copy for speed.
def best_shift(a, b, r=24):
    ga, gb = a.mean(axis=2), b.mean(axis=2)
    best = (1e9, 0, 0)
    for dy in range(-r, r + 1, 2):
        for dx in range(-r, r + 1, 2):
            sa = ga[max(0, dy) : ga.shape[0] + min(0, dy), max(0, dx) : ga.shape[1] + min(0, dx)]
            sb = gb[max(0, -dy) : gb.shape[0] + min(0, -dy), max(0, -dx) : gb.shape[1] + min(0, -dx)]
            e = np.abs(sa[::3, ::3] - sb[::3, ::3]).mean()
            if e < best[0]:
                best = (e, dx, dy)
    return best[1], best[2]


dx, dy = best_shift(a, b)
b = np.roll(b, (dy, dx), axis=(0, 1))
stu = Image.fromarray(b.astype(np.uint8))
diff = np.abs(a - b).max(axis=2)  # 0..255 per pixel

W, H = fig.size
heat = np.zeros((H, W, 3), np.uint8)
heat[..., 0] = np.clip(diff * 3, 0, 255)
heat[..., 1] = np.asarray(fig.convert("L")) // 4
heat[..., 2] = heat[..., 1]
side = Image.new("RGB", (W * 3 + 20, H), (255, 255, 255))
side.paste(fig, (0, 0))
side.paste(stu, (W + 10, 0))
side.paste(Image.fromarray(heat), (W * 2 + 20, 0))

tiles = []
for y in range(0, H, tile):
    for x in range(0, W, tile):
        t = diff[y : y + tile, x : x + tile]
        tiles.append((float((t > 40).mean()), x, y))
tiles.sort(reverse=True)
worst = [t for t in tiles if t[0] > 0.08][:8]

d = ImageDraw.Draw(side)
for score, x, y in worst:
    for ox in (0, W + 10):
        d.rectangle([ox + x, y, ox + x + tile - 1, y + tile - 1], outline=(255, 0, 255), width=2)
side.save(f"{prefix}_side.png")

if worst:
    pad = tile // 2
    rows = []
    for score, x, y in worst:
        box = (max(0, x - pad), max(0, y - pad), min(W, x + tile + pad), min(H, y + tile + pad))
        f, s = fig.crop(box), stu.crop(box)
        r = Image.new("RGB", (f.width * 2 + 6, f.height), (255, 0, 255))
        r.paste(f, (0, 0))
        r.paste(s, (f.width + 6, 0))
        rows.append(r.resize((r.width * 2, r.height * 2), Image.NEAREST))
    top = Image.new("RGB", (max(r.width for r in rows), sum(r.height + 6 for r in rows)), (255, 255, 255))
    yy = 0
    for r in rows:
        top.paste(r, (0, yy))
        yy += r.height + 6
    top.save(f"{prefix}_top.png")

print(f"shift studio by dx={dx} dy={dy}")
print(f"size {W}x{H}  mean diff {diff.mean():.1f}/255  pixels >40: {(diff > 40).mean() * 100:.1f}%")
for score, x, y in worst:
    print(f"  tile x={x} y={y}  {score * 100:.0f}% different")
print(f"wrote {prefix}_side.png" + (f", {prefix}_top.png" if worst else ""))
