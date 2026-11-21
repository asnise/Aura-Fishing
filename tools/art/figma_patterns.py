"""Put the diagonal stripe patterns into Figma (same look as New.Stripes in game).

    python -I tools/art/figma_patterns.py [--channel aura-fishing]

Figma can't tint image fills, so each target gets a pre-coloured, opaque 64px tile
(background colour + stripes baked in) as a TILE image fill. Targets (node ids on page Out Space):
  Progress Bar component track  -> Track + SubText stripes (fine) at 10% opacity  (the Fill on top stays solid)
  Item Slot State=Empty "Slot"  -> Sand  + Track stripes (normal) at 90% opacity
Change a target's look here and in the matching New.Stripes call in code together.
"""
import base64
import io
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")
os.environ.setdefault("FIGMA_AGENT", "py:figma_patterns")  # caller name in the relay usage counter
channel = sys.argv[sys.argv.index("--channel") + 1] if "--channel" in sys.argv else "aura-fishing"

TRACK, SAND, SUBTEXT = (230, 220, 203), (243, 233, 216), (122, 138, 153)

# node id -> (pattern file, stripe colour, opacity, background colour, label)
TARGETS = {
    "3487:4331": ("pattern_stripes_fine", SUBTEXT, 0.10, TRACK, "Progress Bar track"),
    "3491:10581": ("pattern_stripes", TRACK, 0.90, SAND, "Item Slot Empty"),
}


def tile(pattern, color, opacity, bg):
    src = Image.open(os.path.join(ROOT, "assets", "ui-global", pattern + ".png")).convert("RGBA")
    a = src.split()[3].point(lambda v: int(v * opacity))
    out = Image.new("RGBA", src.size, bg + (255,))
    out.paste(Image.new("RGBA", src.size, color + (255,)), (0, 0), a)
    buf = io.BytesIO()
    out.convert("RGB").save(buf, "PNG")
    return base64.b64encode(buf.getvalue()).decode()


def call(cmd, params):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(params, f)
    try:
        r = subprocess.run(["node", RUN, f"--channel={channel}", cmd, f.name], capture_output=True, text=True, encoding="utf-8")
    finally:
        os.unlink(f.name)
    if r.returncode != 0:
        raise SystemExit(f"{cmd} failed: {r.stderr.strip() or r.stdout.strip()}")
    return r.stdout


for node, (pattern, color, opacity, bg, label) in TARGETS.items():
    call("set_image_fill", {"nodeId": node, "imageBase64": tile(pattern, color, opacity, bg), "scaleMode": "TILE"})
    print(f"filled {label} ({node}) with {pattern} {int(opacity * 100)}%")
