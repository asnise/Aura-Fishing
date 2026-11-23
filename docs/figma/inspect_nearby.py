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

# Check all top-level frames on the page and their positions
doc = call("get_document_info", {})
page_children = doc.get("children", [])

for c in page_children:
    info = call("get_node_info", {"nodeId": c.get("id")})
    bb = info.get("absoluteBoundingBox", {})
    if bb:
        x = bb.get("x", 0)
        y = bb.get("y", 0)
        w = bb.get("width", 0)
        h = bb.get("height", 0)
        if 2000 <= x <= 7000 and 4000 <= y <= 9000:
            print(f"Top-level: '{c.get('name')}' [{c.get('id')}] box: ({x}, {y}) {w}x{h}")
