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

# Option B Day 1 reward (3794:1773) and Day 2 reward (3794:1784)
for nid in ["3794:1773", "3794:1784"]:
    info = call("get_node_info", {"nodeId": nid})
    print(f"Option B card {nid}:", info.get("name"), info.get("absoluteBoundingBox"))
    for c in info.get("children", []):
        print(f"   child: {c.get('name')} [{c.get('id')}] {c.get('absoluteBoundingBox')}")
        for sub in c.get("children", []):
            print(f"      sub: {sub.get('name')} [{sub.get('id')}] {sub.get('absoluteBoundingBox')}")
