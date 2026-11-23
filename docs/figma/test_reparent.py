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

# Test creating a frame inside 3794:1650
res = call("build_tree", {
    "parentId": "3794:1650",
    "tree": {
        "name": "TestRow",
        "layout": "H",
        "gap": 40,
        "w": 1800,
        "children": []
    }
})
row_id = res["rootId"]
print("Created TestRow:", row_id)

# Now test set_parent to move Option A (3794:1656) into TestRow
res2 = call("set_parent", {"nodeId": "3794:1656", "parentId": row_id})
print("Moved Option A into TestRow:", res2)

# Check tree
tree = call("get_roblox_tree", {"nodeId": row_id, "maxDepth": 2})
print("TestRow tree children:", [c.get("name") for c in tree["root"].get("children", [])])
print("Option A layoutPositioning inside TestRow:", tree["root"]["children"][0].get("layoutPositioning"))

# Clean up: move Option A back to 3794:1650, delete TestRow
call("set_parent", {"nodeId": "3794:1656", "parentId": "3794:1650"})
call("delete_node", {"nodeId": row_id})
print("Cleaned up test!")
