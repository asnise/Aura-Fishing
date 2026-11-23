"""Convert a project's textures into ready-to-upload PNGs (luma sheets become white + transparent, as the Studio
plugin would). Textures used only by single-frame ribbon layers are also rotated 90 degrees and saved as
<name>_beam.png: Roblox Beams map the image with u across the width, so the game needs the rotated copy. Usage: python -I tools/particle-editor/scripts/luma_export.py <project.json>
Output: <project folder>/export/<file>.png, same file names as the project's assets."""
import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

project = os.path.abspath(sys.argv[1])
folder = os.path.dirname(project)
out = os.path.join(folder, "export")
os.makedirs(out, exist_ok=True)
data = json.load(open(project, encoding="utf-8"))


def beam_only(asset_id):
    layers = [l for l in data["layers"] if l.get("assetId") == asset_id and l.get("visible", True)]
    return bool(layers) and all(
        l["kind"] == "ribbon" and l["sheet"].get("columns", 1) == 1 and l["sheet"].get("rows", 1) == 1
        and not l["sheet"].get("crop") for l in layers)


for asset in data["assets"]:
    src = os.path.normpath(os.path.join(folder, asset["path"]))
    dst = os.path.join(out, os.path.basename(src))
    if beam_only(asset["id"]):
        dst = dst[:-4] + "_beam.png"
    if asset.get("matte", "luma") == "luma":
        px = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32)
        lum = (0.2126 * px[..., 0] + 0.7152 * px[..., 1] + 0.0722 * px[..., 2]) / 255
        alpha = np.rint(px[..., 3] * lum).astype(np.uint8)
        rgba = np.dstack([np.full(alpha.shape + (3,), 255, np.uint8), alpha])
        image = Image.fromarray(rgba, "RGBA")
    else:
        image = Image.open(src).convert("RGBA")
    if beam_only(asset["id"]):
        image = image.transpose(Image.Transpose.ROTATE_90)
    image.save(dst)
    print(asset["id"], "->", dst)
