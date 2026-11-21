"""Compact, readable dump of a Figma node (via the fork plugin) for hand-building a screen in Roblox.

    python -I tools/ui/figma_dump.py <nodeId> [--png out.png] [--all]

One line per visible node: name [type] x,y (relative to the root) WxH fill stroke radius, text + font + size.
"[skip]" layers (fake world, Roblox CoreGui guide) are hidden unless --all.
"""
import json
import io
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")


def call(cmd, params, extra=()):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(params, f)
    try:
        r = subprocess.run(["node", RUN, "--channel=aura-fishing", cmd, f.name, *extra], capture_output=True, text=True, encoding="utf-8")
    finally:
        os.unlink(f.name)
    if r.returncode != 0:
        raise SystemExit(f"{cmd} failed: {r.stderr.strip() or r.stdout.strip()}")
    return r.stdout


def hx(fills):
    out = []
    for f in fills or []:
        if f.get("type") == "SOLID":
            c = f["color"]
            a = c.get("a", 1)
            out.append("#%02X%02X%02X" % (c["r"], c["g"], c["b"]) + ("" if a >= 0.99 else "@%.2f" % a))
        else:
            out.append(f.get("type", "?"))
    return ",".join(out)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        sys.exit(2)
    node = args[0]
    show_all = "--all" in sys.argv
    root = json.loads(call("get_roblox_tree", {"nodeId": node, "depth": 14}))["root"]
    if "--png" in sys.argv:
        out = sys.argv[sys.argv.index("--png") + 1]
        call("export_node_as_image", {"nodeId": node, "format": "PNG", "scale": 1}, [f"--png={out}"])
        print("png:", out)
    ox, oy = root["x"], root["y"]

    def walk(n, ind):
        if not n.get("visible", True) or (not show_all and "[skip]" in n["name"]):
            return
        s = f"{'  ' * ind}{n['name']} [{n['type']}] {round(n['x'] - ox)},{round(n['y'] - oy)} {round(n['width'])}x{round(n['height'])}"
        if n.get("fills"):
            s += " fill=" + hx(n["fills"])
        if n.get("strokes") and n.get("strokeWeight"):
            s += f" stroke={hx(n['strokes'])}/{n['strokeWeight']}"
        if n.get("cornerRadius"):
            s += f" r={n['cornerRadius']}"
        if n.get("opacity", 1) < 1:
            s += f" op={n['opacity']:.2f}"
        if n.get("effects"):
            s += " fx=" + ",".join(f"{e.get('type')}(r{e.get('radius')} y{(e.get('offset') or {}).get('y')} a{round(e['color']['a'], 2) if e.get('color') else ''})" for e in n["effects"])
        if n["type"] == "TEXT":
            t = n.get("text", {})
            s += f" text={t.get('characters', '')!r} {t.get('fontFamily', '')} {t.get('fontStyle', '')} {t.get('fontSize', '')} {t.get('alignH', '')}"
        lay = n.get("layout")
        if lay and lay.get("mode") not in (None, "NONE"):
            s += f" layout={lay['mode']} gap={lay.get('itemSpacing')} pad={lay.get('paddingTop')},{lay.get('paddingRight')},{lay.get('paddingBottom')},{lay.get('paddingLeft')}"
        print(s)
        for c in n.get("children", []):
            walk(c, ind + 1)

    walk(root, 0)


if __name__ == "__main__":
    main()
