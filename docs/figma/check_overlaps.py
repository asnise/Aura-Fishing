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
        r = subprocess.run(["node", RUN, f"--channel={channel}", cmd, f.name], capture_output=True, text=True, encoding="utf-8")
    finally:
        os.unlink(f.name)
    if r.returncode != 0:
        raise SystemExit(f"{cmd} failed: {r.stderr.strip() or r.stdout.strip()}")
    return json.loads(r.stdout)

# Get all children of 3794:1650
res = call("get_node_info", {"nodeId": "3794:1650"})
children = res.get("children", [])

boxes = []
for c in children:
    bb = c.get("absoluteBoundingBox", {})
    boxes.append({
        "id": c.get("id"),
        "name": c.get("name"),
        "x1": bb.get("x", 0),
        "y1": bb.get("y", 0),
        "x2": bb.get("x", 0) + bb.get("width", 0),
        "y2": bb.get("y", 0) + bb.get("height", 0),
        "w": bb.get("width", 0),
        "h": bb.get("height", 0),
    })

print("Checking overlaps among direct children of 3794:1650:")
for i in range(len(boxes)):
    for j in range(i + 1, len(boxes)):
        b1 = boxes[i]
        b2 = boxes[j]
        # Check intersection
        ix1 = max(b1["x1"], b2["x1"])
        iy1 = max(b1["y1"], b2["y1"])
        ix2 = min(b1["x2"], b2["x2"])
        iy2 = min(b1["y2"], b2["y2"])
        if ix1 < ix2 and iy1 < iy2:
            print(f"OVERLAP: '{b1['name']}' ({b1['id']}) and '{b2['name']}' ({b2['id']}) overlap by ({ix2-ix1:.1f} x {iy2-iy1:.1f})")
