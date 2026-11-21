"""Reel Minigame — layout variants of "Option A · Glass Tube" (node 3491:11473) to pick from.
Art stays the current Pond Card art (blue water gradient, mint catch bar + white rim, MysteryFish,
bubbles, gold REEL fill, bobber); only the layout changes. New section, nothing else is touched.

Run:  python -I docs/figma/reel_tube_variants.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/13_reel_tube_variants_ops.json
Then: python -I tools/art/figma_images.py --root <built id>
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("reel", os.path.join(_here, "reel_options.py"))
r = importlib.util.module_from_spec(_s)
_s.loader.exec_module(r)
img, text, v, BORDER, tag, SOFT, PAGE_ID = r.img, r.text, r.v, r.BORDER, r.tag, r.SOFT, r.PAGE_ID
scene, bubbles, svg_arcs, SW, SH = r.scene, r.bubbles, r.svg_arcs, r.SW, r.SH

WATER = {"grad": ["BEE6FA", "4C8FC7"], "angle": 90}  # current Pond Card water
GOLD = {"grad": ["FFD45C", "F2B544"], "angle": 90}
PROGRESS = 0.6  # sample: 60% reeled


def tube(x, y, h=300, w=25, stroke=None, name="Water Tube"):
    return {"name": name, "w": w, "h": h, "x": x, "y": y, "radius": 10, "clip": True, "fill": WATER,
            "stroke": stroke or v("cozy/track"), "strokeW": 3, "children": bubbles(w, h)}


def bar(x, y, w=31, h=84):
    return {"name": "Catch Bar", "w": w, "h": h, "x": x, "y": y, "radius": 9, "fill": {"hex": "7FD3B0", "opacity": 0.85}, "stroke": "FFFFFF", "strokeW": 3}


def fish(x, y, s=39):
    return img("fish/MysteryFish", s, x=x, y=y)


def column(x, y, h=300, w=7, name="Progress"):
    fh = round(h * PROGRESS)
    return {"name": name, "w": w, "h": h, "x": x, "y": y, "radius": 999, "fill": v("cozy/track"), "clip": True,
            "children": [{"type": "RECT", "name": "Fill", "w": w, "h": fh, "x": 0, "y": h - fh, "radius": 999, "fill": GOLD}]}


def header(x, y, w):
    return {"name": "Header", "layout": "H", "gap": 8, "cross": "CENTER", "x": x, "y": y, "w": w,
            "children": [tag("Epic"), text("0:12", "Heading", "cozy/subtext", name="Timer")]}


def hint(y, w, label="HOLD TO REEL"):
    return {"name": "Hint", "layout": "H", "main": "CENTER", "x": 0, "y": y, "w": w,
            "children": [text(label, "Caption", "cozy/subtext", name="Label")]}


def card(w, h, children, name="Reel Minigame"):
    return {"name": name, "w": w, "h": h, "x": (SW - w) // 2, "y": (SH - h) // 2, "radius": 20,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": children}


def tube_set(tx, ty, h=300):
    """Tube + catch bar (3px overhang) + mystery fish on the bar, sample positions like Figma A."""
    by = ty + round(h * 0.5)
    return [tube(tx, ty, h), bar(tx - 3, by), fish(tx - 7, by + 22)]


# A1 — Option A layout as is (thin progress column at the right)
def a1():
    w, h = 133, 394
    bob_y = 52 + round(300 * (1 - PROGRESS)) - 10
    return scene([card(w, h, [header(18, 18, 97)] + tube_set(31, 52) + [column(102, 52), img("ui/status/bobber", 20, x=96, y=bob_y),
                                                                       hint(362, w)])])


# A2 — Twin tubes: progress is a second glass tube of the same size, bobber floats on the gold  (CHOSEN 2026-11-17)
def a2_card(x=None, y=None):
    w, h = 140, 394
    fh = round(300 * PROGRESS)
    gold_tube = {"name": "Reel Tube", "w": 25, "h": 300, "x": 86, "y": 52, "radius": 10, "clip": True, "fill": v("cozy/track"),
                 "stroke": v("cozy/track"), "strokeW": 3,
                 "children": [{"type": "RECT", "name": "Fill", "w": 25, "h": fh, "x": 0, "y": 300 - fh, "fill": GOLD}]}
    c = card(w, h, [header(18, 18, 104)] + tube_set(30, 52) + [gold_tube, img("ui/status/bobber", 24, x=86, y=52 + 300 - fh - 12), hint(362, w)])
    if x is not None:
        c["x"], c["y"] = x, y
    return c


def a2():
    return scene([a2_card()])


# A3 — Floating: no card; header pill on top, white-rimmed tube with soft shadow, hint pill below
def a3():
    cx = SW // 2
    pill = {"name": "Header", "layout": "H", "gap": 8, "pad": [6, 12, 6, 8], "cross": "CENTER", "radius": 999, "x": cx - 52, "y": 34,
            "fill": v("cozy/panel"), **BORDER, "children": [tag("Epic"), text("0:12", "Heading", "cozy/subtext", name="Timer")]}
    t = tube(cx - 13, 82, stroke="FFFFFF")
    t["effects"] = SOFT
    by = 82 + 150
    fh = round(300 * PROGRESS)
    hint_pill = {"name": "Hint", "layout": "H", "pad": [6, 14, 6, 14], "radius": 999, "x": cx - 58, "y": 396, "fill": v("cozy/panel"), **BORDER,
                 "children": [text("HOLD TO REEL", "Caption", "cozy/subtext", name="Label")]}
    return scene([pill, t, bar(cx - 16, by), fish(cx - 20, by + 22),
                  dict(column(cx + 28, 82), effects=SOFT), img("ui/status/bobber", 20, x=cx + 22, y=82 + 300 - fh - 10), hint_pill])


# A4 — Reel donut: progress is a gold ring around the bobber above the tube (no side column)
def a4():
    w, h = 133, 420
    ring = svg_arcs(64, [(26, 0, 359.9, "E6DCCB", 7), (26, 0, 360 * PROGRESS, "F2B544", 7)], "Reel Ring")
    return scene([card(w, h, [header(18, 18, 97), dict(ring, x=34, y=48), img("ui/status/bobber", 28, x=52, y=66)]
                       + tube_set(54, 124, 260) + [hint(394, w)])])


# A5 — Top bar: progress is a short horizontal bar under the header, tube centred below
def a5():
    w, h = 133, 410
    fw = round(97 * PROGRESS)
    hbar = {"name": "Progress", "w": 97, "h": 8, "x": 18, "y": 52, "radius": 999, "fill": v("cozy/track"), "clip": True,
            "children": [{"type": "RECT", "name": "Fill", "w": fw, "h": 8, "x": 0, "y": 0, "radius": 999, "fill": {"grad": ["FFD45C", "F2B544"]}}]}
    return scene([card(w, h, [header(18, 18, 97), hbar, img("ui/status/bobber", 20, x=18 + fw - 10, y=46)] + tube_set(54, 72, 300)
                       + [hint(380, w)])])


VARIANTS = [
    ("A1", "Option A as is", "Thin gold column at the right with the bobber riding it.", a1),
    ("A2", "Twin tubes  (CHOSEN)", "Progress is a second glass tube the same size as the water; bobber floats on the gold.", a2),
    ("A3", "Floating", "No card: header pill on top, white-rim tube with soft shadow, hint pill below. Lightest on screen.", a3),
    ("A4", "Reel donut", "Progress is a gold ring around the bobber above the tube; no side column.", a4),
    ("A5", "Top bar", "Short gold bar under the header; tube centred alone below.", a5),
]


def panel(key, title, desc, fn):
    return {"name": f"Variant {key} — {title}", "layout": "V", "gap": 12, "pad": 24, "w": 600, "radius": 24, "fill": v("cozy/panel"), **BORDER,
            "effects": SOFT, "children": [text(f"{key}. {title}", "Title", name="Title"), text(desc, "Small", "cozy/subtext", name="Desc", w=552), fn()]}


def build():
    cards = [dict(panel(*o), x=60 + (i % 3) * 660, y=150 + (i // 3) * 660) for i, o in enumerate(VARIANTS)]
    sec = {"type": "SECTION", "name": "Reel Minigame · Glass Tube variants (pick one)", "fill": "F3E9D8", "x": 11200, "y": 1700, "children": [
        text("Reel Minigame — Glass Tube variants", "Display", name="Title", x=60, y=40),
        text("Base: Option A (Glass Tube). Same art as the game today (water, mint catch bar, mystery fish, gold + bobber); only the layout differs. Pick one.",
             "Body", "cozy/subtext", name="Sub", x=60, y=96, w=1800)] + cards}
    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "13_reel_tube_variants_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
    # 03 · Reel Minigame screen: replace only its "Reel Minigame" frame (3493:22389) with A2, centred (x 570 on 1280)
    p2 = os.path.join(out, "14_reel_screen_a2_ops.json")
    with open(p2, "w", encoding="utf-8") as f:
        json.dump([{"replaceId": "3493:22389", "tree": a2_card(570, 110)}], f, ensure_ascii=False, indent=1)
    print("wrote", p2)
