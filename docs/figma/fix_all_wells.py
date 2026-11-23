import json
import os
import subprocess
import tempfile
import base64

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")
channel = "aura-fishing"

def call(cmd, params):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(params, f)
    try:
        r = subprocess.run(["node", RUN, f"--channel={channel}", cmd, f.name, "--timeout=300"], capture_output=True, text=True, encoding="utf-8")
    finally:
        os.unlink(f.name)
    if r.returncode != 0:
        raise SystemExit(f"{cmd} failed: {r.stderr.strip() or r.stdout.strip()}")
    return json.loads(r.stdout)

def check_badge_svg(size=36, color="#70DE43"):
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" fill="none" xmlns="http://www.w3.org/2000/svg">'
        f'<circle cx="{size/2}" cy="{size/2}" r="{size/2 - 2}" fill="{color}" fill-opacity="0.2" stroke="{color}" stroke-width="3.5"/>'
        f'<path d="M{size*0.27:.1f} {size*0.50:.1f} l{size*0.17:.1f} {size*0.17:.1f} l{size*0.30:.1f} -{size*0.30:.1f}" '
        f'stroke="{color}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>'
        f'</svg>'
    )

# 1. Remove the old misplaced Claimed stamp instances
old_stamps = [
    "3794:1682", "3794:1693",  # Option A
    "3794:1780", "3794:1791",  # Option B
    "3794:1889", "3794:1900",  # Option C
    "3794:1973", "3794:1984",  # Option D
    "3794:2166", "3794:2177",  # Option E
]
call("patch_nodes", {"patches": [{"id": s, "remove": True} for s in old_stamps]})

# 2. Add centered green checkmark badge inside each claimed Item icon well
wells = [
    ("3794:1678", 52), ("3794:1689", 52),  # Option A
    ("3794:1776", 52), ("3794:1787", 52),  # Option B
    ("3794:1885", 48), ("3794:1896", 48),  # Option C
    ("3794:1969", 48), ("3794:1980", 48),  # Option D
    ("3794:2162", 48), ("3794:2173", 48),  # Option E
]

for wid, size in wells:
    badge_size = size - 16
    offset = 8
    svg = check_badge_svg(badge_size, "#70DE43")
    call("build_tree", {
        "parentId": wid,
        "tree": {
            "type": "SVG",
            "name": "ClaimedCheckBadge",
            "svg": svg,
            "w": badge_size,
            "h": badge_size,
            "x": offset,
            "y": offset,
            "absolute": True
        }
    })

print("All wells updated with centered green checkmark badges!")

# 3. Export Option A to verify
f = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
json.dump({"nodeId": "3794:1656", "format": "PNG", "scale": 2}, f)
f.close()
r = subprocess.run(["node", RUN, f"--channel={channel}", "export_node_as_image", f.name], capture_output=True, text=True)
d = json.loads(r.stdout)
raw = base64.b64decode(d['imageData'])
out_path = os.path.join(ROOT, "docs", "figma", "shots", "option_a_fixed.png")
with open(out_path, "wb") as img_f:
    img_f.write(raw)
print("Saved Option A fixed preview to:", out_path)
