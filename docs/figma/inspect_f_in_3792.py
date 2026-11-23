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

# Find Option F in 3792:1019
tree = call("get_roblox_tree", {"nodeId": "3792:1019", "maxDepth": 4})
def find_f(n):
    if "F." in n.get("name", ""):
        print("Found:", n.get("name"), n.get("id"), n.get("width"), n.get("height"))
        for c in n.get("children", []):
            print("  child:", c.get("name"), c.get("id"), c.get("width"), c.get("height"))
    for c in n.get("children", []):
        find_f(c)

find_f(tree["root"])
