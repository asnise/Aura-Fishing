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

res = call("get_node_info", {"nodeId": "3794:1650"})
print("Section Name:", res.get("name"))
print("Section Bounding Box:", res.get("absoluteBoundingBox"))
print("Section Children:")
for c in res.get("children", []):
    bb = c.get("absoluteBoundingBox", {})
    print(f"  ID: {c.get('id'):<12} | Name: {c.get('name'):<40} | Pos: ({bb.get('x',0):.1f}, {bb.get('y',0):.1f}) | Size: {bb.get('width',0):.1f} x {bb.get('height',0):.1f}")
