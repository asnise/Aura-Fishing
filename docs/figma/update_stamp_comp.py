import json
import os
import subprocess
import tempfile

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

# 1. Patch 3794:1654: resize to 36x36, set fill & stroke to green, cornerRadius 999
patch = {
    "patches": [
        {
            "id": "3794:1654",
            "stroke": "70DE43",
            "strokeW": 3.5,
            "fill": {"hex": "70DE43", "opacity": 0.15},
            "radius": 999
        },
        {
            "id": "3794:1655",
            "remove": True
        }
    ]
}
call("patch_nodes", patch)

# 2. Add vector checkmark inside 3794:1654
check_svg = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 10l4 4 8-8" stroke="#70DE43" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>'
call("build_tree", {
    "parentId": "3794:1654",
    "tree": {
        "type": "SVG",
        "name": "CheckIcon",
        "svg": check_svg,
        "w": 20,
        "h": 20,
        "x": 8,
        "y": 8
    }
})

# Resize 3794:1654 to 36x36
# Using resize_node command
call("resize_node", {"nodeId": "3794:1654", "width": 36, "height": 36})
print("Claimed stamp component updated to green checkmark circle!")
