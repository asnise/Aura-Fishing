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
print("Keys:", tree.keys())
print("Name:", tree.get("name"))
print("Type:", tree.get("type"))
print("Has children:", "children" in tree)
if "children" in tree:
    print("Num children:", len(tree["children"]))
    for c in tree["children"]:
        print(c.get("name"), c.get("x"), c.get("y"), c.get("w"), c.get("h"), c.get("layoutPositioning"))
