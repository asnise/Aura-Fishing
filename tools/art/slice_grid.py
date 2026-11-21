"""Slice a generated 3x3 sprite sheet into 9 named PNGs.

Usage:
  python -I tools/art/slice_grid.py <sheet_id> <image.png> [--keep-bg] [--size 512] [--tol 28]

  sheet_id  : id from tools/art/sheets.json, e.g. 03_fish_shallow
  image.png : the generated 1:1 image (any size)

Output: assets/art/<folder>/<name>.png (transparent background, trimmed, centred on a square canvas)
        plus assets/art/<sheet_id>_contact.png (labelled preview of what went where).

How it works: finds the white gutters automatically (falls back to equal thirds), crops each cell,
removes the white background by flood-filling from the cell border (so white parts *inside* the
object stay), trims, pads and resizes to --size.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHEETS = os.path.join(ROOT, "tools", "art", "sheets.json")
OUT = os.path.join(ROOT, "assets", "art")


def is_bg(px, tol):
    r, g, b = px[:3]
    return r >= 255 - tol and g >= 255 - tol and b >= 255 - tol


def find_cuts(img, axis, tol):
    """Return the 2 inner cut positions along axis (0 = x, 1 = y) by locating white gutter bands."""
    w, h = img.size
    n = w if axis == 0 else h
    other = h if axis == 0 else w
    step = max(1, other // 200)
    px = img.load()
    white = []
    for i in range(n):
        ok = True
        for j in range(0, other, step):
            p = px[i, j] if axis == 0 else px[j, i]
            if not is_bg(p, tol):
                ok = False
                break
        white.append(ok)
    cuts = []
    for target in (n / 3, 2 * n / 3):
        lo, hi = int(target - n * 0.12), int(target + n * 0.12)
        best, best_len, i = None, 0, lo
        while i < hi:
            if white[i]:
                j = i
                while j < hi and white[j]:
                    j += 1
                if j - i > best_len:
                    best, best_len = (i + j) // 2, j - i
                i = j
            else:
                i += 1
        cuts.append(best if best is not None else int(target))
    return cuts


def remove_bg(cell, tol):
    cell = cell.convert("RGBA")
    w, h = cell.size
    mask = Image.new("L", (w, h), 0)
    src = cell.load()
    m = mask.load()
    stack = [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]
    while stack:
        x, y = stack.pop()
        if m[x, y] or not is_bg(src[x, y], tol):
            continue
        m[x, y] = 255
        if x > 0:
            stack.append((x - 1, y))
        if x < w - 1:
            stack.append((x + 1, y))
        if y > 0:
            stack.append((x, y - 1))
        if y < h - 1:
            stack.append((x, y + 1))
    cell.putalpha(mask.point(lambda v: 0 if v else 255))
    return cell


def square(img, size, pad_ratio=0.08):
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    w, h = img.size
    side = int(max(w, h) * (1 + pad_ratio * 2)) or 1
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return canvas.resize((size, size), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet_id")
    ap.add_argument("image")
    ap.add_argument("--keep-bg", action="store_true")
    ap.add_argument("--size", type=int, default=512)
    ap.add_argument("--tol", type=int, default=28)
    ap.add_argument("--out", default=OUT, help="output root (default assets/art)")
    a = ap.parse_args()
    out_root = a.out

    sheets = {s["id"]: s for s in json.load(open(SHEETS, encoding="utf-8"))["sheets"]}
    if a.sheet_id not in sheets:
        sys.exit(f"unknown sheet '{a.sheet_id}'. Known: {', '.join(sheets)}")
    sheet = sheets[a.sheet_id]
    img = Image.open(a.image).convert("RGB")
    W, H = img.size
    xs = [0] + find_cuts(img, 0, a.tol) + [W]
    ys = [0] + find_cuts(img, 1, a.tol) + [H]

    out_dir = os.path.join(out_root, sheet["folder"])
    os.makedirs(out_dir, exist_ok=True)
    thumbs = []
    for idx, (name, _desc) in enumerate(sheet["items"]):
        r, c = divmod(idx, 3)
        box = (xs[c], ys[r], xs[c + 1], ys[r + 1])
        inset = int(min(box[2] - box[0], box[3] - box[1]) * 0.015)
        cell = img.crop((box[0] + inset, box[1] + inset, box[2] - inset, box[3] - inset))
        cell = cell.convert("RGBA") if a.keep_bg else remove_bg(cell, a.tol)
        final = square(cell, a.size)
        path = os.path.join(out_dir, name + ".png")
        final.save(path)
        thumbs.append((name, final))
        print(f"cell {idx + 1} (row {r + 1}, col {c + 1}) -> {path}")

    # contact sheet for checking the mapping
    t = 220
    sheet_img = Image.new("RGBA", (t * 3, (t + 28) * 3), (255, 248, 236, 255))
    d = ImageDraw.Draw(sheet_img)
    font = ImageFont.load_default()
    for idx, (name, im) in enumerate(thumbs):
        r, c = divmod(idx, 3)
        x, y = c * t, r * (t + 28)
        sheet_img.paste(im.resize((t - 20, t - 20)), (x + 10, y + 10), im.resize((t - 20, t - 20)))
        d.text((x + 10, y + t - 4), f"{idx + 1}. {name}", fill=(61, 75, 92), font=font)
    contact = os.path.join(out_root, f"{a.sheet_id}_contact.png")
    sheet_img.save(contact)
    print("contact sheet ->", contact)


if __name__ == "__main__":
    main()
