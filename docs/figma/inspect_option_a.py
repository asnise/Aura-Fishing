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

# Inspect Option A Day 1 reward (3794:1674 or similar)
tree = call("get_roblox_tree", {"nodeId": "3794:1656", "maxDepth": 8})
def dump(n, depth=0):
    indent = "  " * depth
    box = f"({n.get('x')}, {n.get('y')}) {n.get('width')}x{n.get('height')}"
    print(f"{indent}{n.get('name')} [{n.get('id')}] {box} pos={n.get('layoutPositioning')}")
    for c in n.get("children", []):
        dump(c, depth + 1)

dump(tree["root"])
