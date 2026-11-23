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

# Check all children in each Option
for opt_id in ["3794:1656", "3794:1753", "3794:1850", "3794:1945", "3794:2060", "3796:2955", "3796:3061"]:
    tree = call("get_roblox_tree", {"nodeId": opt_id, "maxDepth": 4})
    r = tree["root"]
    print(f"\n=== {r.get('name')} ({opt_id}) pos: ({r.get('x')}, {r.get('y')}) size: {r.get('width')}x{r.get('height')} ===")
    def walk(node, indent=0):
        name = node.get("name", "")
        box = f"({node.get('x')}, {node.get('y')}) {node.get('width')}x{node.get('height')}"
        pos_mode = node.get("layoutPositioning", "")
        print("  " * indent + f"{name} {box} {pos_mode}")
        for ch in node.get("children", []):
            walk(ch, indent + 1)
    walk(r)
