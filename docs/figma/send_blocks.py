"""Send big build_tree ops in pieces: each SECTION shell (its TEXT children) first, then one call per other child.
Usage: python -I docs/figma/send_blocks.py <ops.json> [--channel aura-fishing]
(One huge build_tree times out / fails in the plugin; ~150 nodes per call is safe.)
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
    tree = op["tree"]
    head = [k for k in tree.get("children", []) if k.get("type") == "TEXT"]
    rest = [k for k in tree.get("children", []) if k.get("type") != "TEXT"]
    params = {k: op[k] for k in ("replaceId", "parentId", "replaceName", "pageId") if k in op}
    sid = call("build_tree", dict(params, tree=dict(tree, children=head)))["rootId"]
    print("section", sid, tree.get("name"), flush=True)
    for k in rest:
        r = call("build_tree", {"parentId": sid, "tree": k})
        print("  built", r["rootId"], k.get("name"), flush=True)
