"""Push sliced art into Figma image slots.

Every Figma layer named "Img <path>" under the given root nodes gets assets/art/<path>.png as an
image fill (FIT). Extra fixed targets can be given as  --set <nodeName>=<path>  (matched by exact layer
name under the roots, e.g. for component icons).

Usage:
  python -I tools/art/figma_images.py --channel aura-fishing --root 3489:5927 [--root ...] [--size 256]
         [--set "Type=Coins/Icon=ui/status/coin"]

Needs: relay on :3055 + fork plugin "Figma -> Roblox (Aura Fishing)" connected to the channel.
"""
import argparse
import base64
import io
import re
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")
os.environ.setdefault("FIGMA_AGENT", "py:figma_images")  # caller name in the relay usage counter
ART = os.path.join(ROOT, "assets", "art")


def call(channel, command, params, timeout=120):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(params, f)
        pf = f.name
    try:
        r = subprocess.run(["node", RUN, f"--channel={channel}", command, pf, f"--timeout={timeout}"],
                           capture_output=True, text=True, encoding="utf-8")
    finally:
        os.unlink(pf)
    if r.returncode != 0:
        raise RuntimeError(f"{command} failed: {r.stderr.strip() or r.stdout.strip()}")
    return json.loads(r.stdout)


_cache = {}


def b64(path, size):
    if path not in _cache:
        src = os.path.join(ART, *path.split("/")) + ".png"
        im = Image.open(src).convert("RGBA")
        im.thumbnail((size, size), Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, "PNG", optimize=True)
        _cache[path] = base64.b64encode(buf.getvalue()).decode()
    return _cache[path]


def walk(node, parent_name, out, img_override=None):
    # An ancestor named "... {img:auras/SolarFlare}" overrides the image of every "Img ..." layer below it
    # (used for component instances, whose child layer names cannot be renamed).
    m = re.search(r"\{img:([^}]+)\}", node["name"])
    if m:
        img_override = m.group(1)
    out.append((node, parent_name, img_override))
    for c in node.get("children") or []:
        walk(c, node["name"], out, img_override)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--channel", default="aura-fishing")
    ap.add_argument("--root", action="append", required=True)
    ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--set", action="append", default=[], help="ParentName/LayerName=path")
    a = ap.parse_args()

    fixed = {}
    for s in a.set:
        k, path = s.split("=", 1) if s.count("=") == 1 else s.rsplit("=", 1)
        fixed[k] = path

    done, missing = 0, []
    for root_id in a.root:
        tree = call(a.channel, "get_roblox_tree", {"nodeId": root_id, "maxDepth": 80}, 180)["root"]
        nodes = []
        walk(tree, "", nodes)
        for n, parent, override in nodes:
            path = None
            if n["name"].startswith("Img "):
                path = override or n["name"][4:].strip()
            elif f"{parent}/{n['name']}" in fixed:
                path = fixed[f"{parent}/{n['name']}"]
            if not path:
                continue
            if not os.path.exists(os.path.join(ART, *path.split("/")) + ".png"):
                missing.append(path)
                continue
            call(a.channel, "set_image_fill", {"nodeId": n["id"], "imageBase64": b64(path, a.size), "scaleMode": "FIT"})
            done += 1
            print(f"  {n['id']:>12}  {path}")
    print(f"filled {done} slots" + (f", missing art: {sorted(set(missing))}" if missing else ""))


if __name__ == "__main__":
    main()
