"""Apply a list of targeted ops to Figma through the fork plugin.
Usage: python -I docs/figma/apply_patch.py <ops.json> [--channel aura-fishing]
ops: [{"replaceId": id, "tree": {...}} | {"parentId": id, "tree": {...}} | {"remove": [ids]}]
Prints the root id of every node it built (feed them to tools/art/figma_images.py --root).
"""
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")
channel = sys.argv[sys.argv.index("--channel") + 1] if "--channel" in sys.argv else "aura-fishing"


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


for op in json.load(open(sys.argv[1], encoding="utf-8")):
    if "remove" in op:
        call("patch_nodes", {"patches": [{"id": i, "remove": True} for i in op["remove"]]})
        print("removed", ",".join(op["remove"]))
    else:
        res = call("build_tree", {k: op[k] for k in ("replaceId", "parentId", "replaceName", "pageId", "tree") if k in op})
        print("built", res["rootId"])
