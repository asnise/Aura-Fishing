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

for opt_id, name in [
    ("3794:1656", "Option A"),
    ("3794:1753", "Option B"),
    ("3794:1850", "Option C"),
    ("3794:1945", "Option D"),
    ("3794:2060", "Option E"),
    ("3796:2955", "Option F"),
    ("3796:3061", "After claiming"),
]:
    tree = call("get_roblox_tree", {"nodeId": opt_id, "maxDepth": 6})
    print(f"\n--- {name} ({opt_id}) ---")
    def find_claimed_and_cards(n):
        nm = n.get("name", "")
        if "Day 1" in nm or "Day 2" in nm or "Day 3" in nm:
            print(f"Card: {nm:<30} id: {n.get('id'):<12} box: ({n.get('x')}, {n.get('y')}) {n.get('width')}x{n.get('height')}")
            for c in n.get("children", []):
                print(f"   child: {c.get('name'):<25} id: {c.get('id'):<12} box: ({c.get('x')}, {c.get('y')}) {c.get('width')}x{c.get('height')}")
        for c in n.get("children", []):
            find_claimed_and_cards(c)
    find_claimed_and_cards(tree["root"])
