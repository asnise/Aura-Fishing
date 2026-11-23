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

tree = call("get_roblox_tree", {"nodeId": "3794:1650", "maxDepth": 8})
print("Searching for all Claimed nodes, overlays, check badges in 3794:1650:")
def find_nodes(n, path=""):
    name = n.get("name", "")
    current_path = f"{path} > {name}" if path else name
    if "claim" in name.lower() or "check" in name.lower() or "badge" in name.lower() or "overlay" in name.lower():
        print(f"Node: '{name}' [{n.get('id')}] at ({n.get('x')}, {n.get('y')}) size {n.get('width')}x{n.get('height')} | path: {current_path}")
    for c in n.get("children", []):
        find_nodes(c, current_path)

find_nodes(tree["root"])
