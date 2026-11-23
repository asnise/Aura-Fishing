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

# In Option A, B, C, D, E:
# Find every 'Claimed stamp' and place it right inside the 'Item icon well' or centered over it!
d = call("get_node_info", {"nodeId": "3794:1650"})

# In fact, let's look at the component 3794:1654:
# If 3794:1654 is an instance inside 'Reward icon and status',
# let's see its parent's layout and its local position.
def find_stamps(n, path=""):
    for c in n.get("children", []):
        curr_path = f"{path} > {c.get('name')}"
        if c.get("name") == "Claimed stamp" and c.get("type") == "INSTANCE":
            print(c["id"], curr_path, "local x:", c.get("x"), "local y:", c.get("y"), "box:", c.get("absoluteBoundingBox"))
        find_stamps(c, curr_path)

find_stamps(d)
