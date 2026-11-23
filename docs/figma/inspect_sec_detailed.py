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

# Check Section 3794:1650 and all direct children
sec = call("get_node_info", {"nodeId": "3794:1650"})
print("Section 3794:1650:")
print("  Box:", sec.get("absoluteBoundingBox"))
children = sec.get("children", [])
print(f"Total direct children: {len(children)}")
for c in children:
    print(f"  ID: {c.get('id'):<12} | Name: {c.get('name'):<35} | Box: {c.get('absoluteBoundingBox')}")
