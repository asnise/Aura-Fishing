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

tree = call("get_roblox_tree", {"nodeId": "3794:1650", "maxDepth": 2})
r = tree["root"]
print("Section pos:", r["x"], r["y"], r["width"], r["height"])
for c in r.get("children", []):
    print(f"{c.get('name'):<30} | id: {c.get('id'):<10} | x={c.get('x')} y={c.get('y')} w={c.get('width')} h={c.get('height')} | {c.get('layoutPositioning')}")
    for sub in c.get("children", []):
        print(f"   ↳ {sub.get('name'):<26} | id: {sub.get('id'):<10} | x={sub.get('x')} y={sub.get('y')} w={sub.get('width')} h={sub.get('height')}")
