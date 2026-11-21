"""Empty slot options without the centre "+" (user, 2026-11-18). 6 options, each shown in a mini Inventory grid
(72px slots, same as 18 FINAL) with filled slots, empty slots and the "Get more" cell that opens the Shop.

Run:  python -I docs/figma/empty_slots.py docs/figma/out
Send: python -I docs/figma/send_blocks.py docs/figma/out/25_empty_slots_ops.json
Then: python -I tools/art/figma_images.py --root <section id>
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))


def _load(name, file):
    s = importlib.util.spec_from_file_location(name, os.path.join(_here, file))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


f = _load("inventory_final", "inventory_final.py")
m, es = f.m, f.es
v, text, BORDER, SOFT, PAGE_ID = m.v, m.text, m.BORDER, m.SOFT, m.PAGE_ID
img, ftxt, item_slot, board = m.img, m.ftxt, m.item_slot, es.board
S = 72          # slot size
R = 18          # slot radius (item_slot: 20 * 72/88)
SAND, TRACK, PANEL = "F3E9D8", "E6DCCB", "FFF8EC"

FILLED = [("fish/PebbleMinnow", "Common", 23), ("fish/BubbleCarp", "Common", 41), ("fish/PearlClam", "Uncommon", 6),
          ("fish/DewdropKoi", "Rare", 2), ("fish/CrystalGuppy", "Epic", 1)]


def svg_node(name, w, h, body, **kw):
    d = {"type": "SVG", "name": name, "w": w, "h": h, "svg": f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg">{body}</svg>'}
    d.update(kw)
    return d


def base(name, fill=SAND, stroke=True, kids=(), **kw):
    d = {"name": name, "w": S, "h": S, "radius": R, "clip": True, "fill": {"hex": fill} if isinstance(fill, str) else fill, "children": list(kids)}
    if stroke:
        d.update(BORDER)
    d.update(kw)
    return {"name": name, "w": S, "h": S, "clip": False, "children": [dict(d, name="Slot", x=0, y=0)]}


# ---------------------------------------------------------------- empty styles
FISH_PATH = "M8 36c8-12 21-17 35-11l11-9v40l-11-9C29 53 16 48 8 36z"


def e1_recessed(i):
    """1 · Recessed: darker sunken tile, inner shadow at the top, nothing inside."""
    return base("Empty", fill="EADFCB", stroke=False, effects=[{"inner": True, "color": "3D4B5C", "a": 0.14, "y": 3, "blur": 6}])


def e2_dashed(i):
    """2 · Dashed: no fill, soft dashed outline."""
    rect = svg_node("Dashes", S, S, f'<rect x="1.5" y="1.5" width="{S - 3}" height="{S - 3}" rx="{R - 1}" fill="none" stroke="#D6C8B0" stroke-width="2.5" stroke-dasharray="7 6"/>', x=0, y=0)
    return base("Empty", fill={"hex": SAND, "opacity": 0.35}, stroke=False, kids=[rect])


def e3_silhouette(i):
    """3 · Silhouette: faint shape of what goes in this tab (fish here, rod in Rods ...)."""
    fish = svg_node("Silhouette", 48, 48, f'<path d="{FISH_PATH}" transform="scale(0.78) translate(2 -4)" fill="#3D4B5C"/>', x=12, y=14, opacity=0.07)
    return base("Empty", kids=[fish])


def e4_number(i):
    """4 · Numbered: slot number faint in the top-left corner (helps count free space)."""
    return base("Empty", kids=[ftxt(str(i), 13, "C9BBA3", name="Index", x=9, y=6)])


def e5_dot(i):
    """5 · Bubble dots: three tiny water bubbles, very quiet, fits the lake theme."""
    dots = svg_node("Bubbles", 28, 28, '<circle cx="8" cy="19" r="4" fill="#D9CDB8"/><circle cx="18" cy="11" r="3" fill="#D9CDB8"/><circle cx="21" cy="21" r="2" fill="#D9CDB8"/>', x=22, y=22)
    return base("Empty", kids=[dots])


def e6_glass(i):
    """6 · Glass: white tile at low opacity with a soft highlight, like a clear jar waiting to be filled."""
    shine = svg_node("Shine", S, S, f'<path d="M10 14c0-4 3-6 7-6h20" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.9"/>', x=0, y=0)
    return base("Empty", fill={"grad": ["FFFFFF", "EFE6D6"], "angle": 90}, kids=[shine],
                effects=[{"inner": True, "color": "3D4B5C", "a": 0.06, "y": -2, "blur": 4}])


# ---------------------------------------------------------------- "Get more" cells (open the Shop on that tab)
def gm_shop_label(style):
    kids = [img("ui/icons/shop", 34, x=(S - 34) // 2, y=10), dict(text("Shop", "Caption", "cozy/subtext", name="Label"), x=0, y=46, w=S, align="CENTER")]
    if style == "pill":
        return base("Btn Get More", fill=PANEL, kids=kids)
    return base("Btn Get More", fill=SAND, kids=kids)


def gm_arrow():
    arrow = svg_node("Arrow", 26, 26, '<path d="M8 4l10 9-10 9" stroke="#E08A6E" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>', x=23, y=14)
    return base("Btn Get More", fill={"hex": "FF9E80", "opacity": 0.14}, stroke=False,
                kids=[arrow, dict(text("More", "Caption", "cozy/coral-lip", name="Label"), x=0, y=46, w=S, align="CENTER")])


OPTIONS = [
    ("1", "Recessed", "Sunken darker tile, nothing inside. Cleanest; empty space reads as 'holes'.", e1_recessed, lambda: gm_shop_label("sand")),
    ("2", "Dashed", "Dashed outline on a very light tile. Classic 'drop here' look.", e2_dashed, lambda: gm_shop_label("pill")),
    ("3", "Silhouette", "Faint shape of the tab's item (fish / rod / orb ...). Tells you what goes there.", e3_silhouette, lambda: gm_shop_label("sand")),
    ("4", "Numbered", "Slot number in the corner. Easy to see how much room is left.", e4_number, gm_arrow),
    ("5", "Bubbles", "Three tiny bubbles. Quiet and on-theme (lake).", e5_dot, gm_arrow),
    ("6", "Glass", "Soft white glass tile with a highlight. Feels like an empty jar.", e6_glass, lambda: gm_shop_label("pill")),
]


def mini_grid(fn, gm):
    cells = []
    for i, (k, r, n) in enumerate(FILLED):
        cells.append(item_slot(k, r, n, size=S, name=k.split("/")[-1]))
    for i in range(len(FILLED) + 1, 14):
        cells.append(fn(i))
    cells.append(gm())
    rows = [cells[i:i + 7] for i in range(0, len(cells), 7)]
    return {"name": "Grid", "layout": "V", "gap": 10, "pad": 14, "radius": 20, "fill": v("cozy/panel"), **BORDER, "children": [
        {"name": f"Row {i + 1}", "layout": "H", "gap": 8, "children": r} for i, r in enumerate(rows)]}


def option_board(n, name, desc, fn, gm):
    big = {"name": "Zoom", "layout": "H", "gap": 16, "cross": "CENTER", "children": [
        dict(fn(6), name="Empty x1"), dict(gm(), name="Get More x1"),
        text("empty  |  get more (opens Shop)", "Caption", "cozy/subtext", name="Legend")]}
    return board(f"{n} · {name}", desc, [mini_grid(fn, gm), big], w=680)


def build():
    kids = []
    for i, o in enumerate(OPTIONS):
        kids.append(dict(option_board(*o), x=60 + (i % 3) * 740, y=180 + (i // 3) * 520))
    sec = {"type": "SECTION", "name": "18 · Empty Slot options", "fill": "F3E9D8", "x": 27200, "y": 9900, "children": [
        text("18 · Empty Slot — 6 options (no centre +)", "Display", name="Title", x=60, y=40),
        text("Mini Inventory grids at real size (72px). Last cell = Get More (opens the Shop on that tab), redesigned too so it is not a + either.",
             "Body", "cozy/subtext", name="Sub", x=60, y=100, w=2200)] + kids}
    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "25_empty_slots_ops.json")
    with open(p, "w", encoding="utf-8") as fh:
        json.dump(build(), fh, ensure_ascii=False, indent=1)
    print("wrote", p)
