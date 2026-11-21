"""Seamless diagonal stripe (hatch) patterns for empty areas, progress-bar tracks and empty Item Slots.

    python -I tools/art/make_patterns.py          -> assets/ui-global/pattern_stripes*.png + preview

White on transparent, so in Roblox they are tinted with ImageColor3 and tiled:
    ImageLabel.ScaleType = Tile, TileSize = UDim2.fromOffset(64, 64)   (New.Stripes does this)
45 degree stripes repeat every PERIOD px along x and y; the tile (64) is a multiple of the period, so the
edges join without a seam. Drawn at 8x and downsampled for anti-aliased edges.
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "ui-global")
TILE = 64
SS = 8  # supersampling

# name -> (period px, stripe thickness px measured across the stripe)
PATTERNS = {
    "pattern_stripes": (16, 5),  # default: empty slots / empty list areas
    "pattern_stripes_fine": (8, 2.5),  # small things: progress-bar tracks (empty part behind the fill), thin bars
}


def stripes(period, thickness):
    n = TILE * SS
    img = Image.new("L", (n * 3, n * 3), 0)  # draw 3x3 tiles, keep the centre -> no edge artefacts
    d = ImageDraw.Draw(img)
    p = period * SS
    w = thickness * SS * 2 ** 0.5  # horizontal width of a 45 degree band with this perpendicular thickness
    for k in range(-3 * n, 6 * n, p):
        # band between lines x + y = k and x + y = k + w
        d.polygon([(k, 0), (k + w, 0), (k + w - 3 * n, 3 * n), (k - 3 * n, 3 * n)], fill=255)
    alpha = img.crop((n, n, 2 * n, 2 * n)).resize((TILE, TILE), Image.LANCZOS)
    out = Image.new("RGBA", (TILE, TILE), (255, 255, 255, 0))
    out.putalpha(alpha)
    return out


def preview(tiles):
    """Usage sheet on the Cozy Lake palette: empty Item Slot, progress bar, empty list area."""
    cream, sand, track, sub, mint, gold = (255, 248, 236), (243, 233, 216), (230, 220, 203), (122, 138, 153), (127, 211, 176), (242, 181, 68)
    W, H = 760, 300
    im = Image.new("RGB", (W, H), cream)
    d = ImageDraw.Draw(im)

    def tinted(name, color, alpha, size):
        t = tiles[name]
        layer = Image.new("RGBA", size, color + (0,))
        for y in range(0, size[1], TILE):
            for x in range(0, size[0], TILE):
                layer.alpha_composite(t, (x, y))
        r, g, b, a = layer.split()
        a = a.point(lambda v: int(v * alpha))
        solid = Image.new("RGB", size, color)
        return solid, a

    def paste_pattern(box, radius, name, color, alpha, base):
        x0, y0, x1, y1 = box
        size = (x1 - x0, y1 - y0)
        mask = Image.new("L", size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius, fill=255)
        im.paste(base, box, mask) if isinstance(base, Image.Image) else d.rounded_rectangle(box, radius, fill=base)
        solid, a = tinted(name, color, alpha, size)
        a = Image.fromarray(__import__("numpy").minimum(__import__("numpy").asarray(a), __import__("numpy").asarray(mask)))
        im.paste(solid, box[:2], a)

    # 1) empty Item Slot (sand tile + stripes + "+")
    for i in range(3):
        box = (30 + i * 104, 40, 30 + i * 104 + 88, 128)
        paste_pattern(box, 20, "pattern_stripes", track, 0.9, sand)
        d.rounded_rectangle(box, 20, outline=track, width=2)
        cx, cy = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
        d.line([cx - 10, cy, cx + 10, cy], fill=sub, width=4)
        d.line([cx, cy - 10, cx, cy + 10], fill=sub, width=4)
    d.text((30, 140), "Empty Item Slot  (pattern_stripes, tint Track)", fill=sub)

    # 2) progress bars: stripes on the TRACK (empty part), solid fill on top
    for j, (col, frac) in enumerate([(mint, 0.62), (gold, 0.35)]):
        y = 50 + j * 40
        paste_pattern((380, y, 730, y + 18), 9, "pattern_stripes_fine", sub, 0.1, track)
        fx = 380 + int(350 * frac)
        d.rounded_rectangle((380, y, fx, y + 18), 9, fill=col)
    d.text((380, 140), "Progress track  (pattern_stripes_fine, SubText 10% opacity on the track; fill stays solid)", fill=sub)

    # 3) empty list area
    paste_pattern((30, 170, 730, 270), 16, "pattern_stripes", track, 0.7, sand)
    d.text((300, 212), "Nothing here yet", fill=sub)
    d.text((30, 278), "Empty area  (pattern_stripes, tint Track 70%)", fill=sub)
    return im


if __name__ == "__main__":
    tiles = {}
    for name, (period, thick) in PATTERNS.items():
        t = stripes(period, thick)
        t.save(os.path.join(OUT, f"{name}.png"))
        tiles[name] = t
        print("wrote", os.path.join(OUT, f"{name}.png"))
    p = os.path.join(ROOT, "docs", "figma", "patterns_preview.png")
    preview(tiles).save(p)
    print("wrote", p)
