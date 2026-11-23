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

# Get node 3794:1650
d = call("get_node_info", {"nodeId": "3794:1650"})

moves = []
def check_reward_group(n):
    # Find groups that contain both 'Item icon well' and 'Claimed stamp'
    children = n.get("children", [])
    well = None
    stamp = None
    for c in children:
        if "icon well" in c.get("name", "").lower():
            well = c
        elif "claimed stamp" in c.get("name", "").lower() and c.get("type") == "INSTANCE":
            stamp = c
    if well and stamp:
        wb = well["absoluteBoundingBox"]
        sb = stamp["absoluteBoundingBox"]
        # In parent relative coords:
        # stamp dx = wb['x'] + (wb['width'] - sb['width'])/2 - sb['x']
        # stamp dy = wb['y'] + (wb['height'] - sb['height'])/2 - sb['y']
        target_x = wb["x"] + (wb["width"] - 36) / 2
        target_y = wb["y"] + (wb["height"] - 36) / 2
        moves.append((stamp["id"], target_x, target_y))
    for c in children:
        check_reward_group(c)

check_reward_group(d)
print("Found stamps to center:", moves)

for sid, tx, ty in moves:
    call("move_node", {"nodeId": sid, "x": tx, "y": ty})

print("All stamps centered successfully!")
