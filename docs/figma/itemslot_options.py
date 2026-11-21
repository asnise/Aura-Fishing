"""6 ItemSlot design options for the Inventory (one Figma Section, page Out Space).

Run:  python -I docs/figma/itemslot_options.py docs/figma/out
Send: figma-run.mjs --channel=aura-fishing build_tree docs/figma/out/8_itemslot_options.json
Then: python -I tools/art/figma_images.py --root <rootId>
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
img, text, v, BORDER, small_pill, PAGE_ID, C = m.img, m.text, m.v, m.BORDER, m.small_pill, m.PAGE_ID, m.base.C

RAR = {"Common": "9AA5B1", "Uncommon": "5CC98A", "Rare": "5AA9F0", "Epic": "B07CF0", "Legendary": "F2A93B", "Mythic": "F2668B", "Bait": "F2B544"}


def mix(hex_, amount):
    """Blend colour with white (amount 0..1 of white)."""
    r, g, b = (int(hex_[i:i + 2], 16) for i in (0, 2, 4))
    f = lambda c: round(c + (255 - c) * amount)
    return f"{f(r):02X}{f(g):02X}{f(b):02X}"


def darker(hex_, amount=0.22):
    r, g, b = (int(hex_[i:i + 2], 16) for i in (0, 2, 4))
    f = lambda c: round(c * (1 - amount))
    return f"{f(r):02X}{f(g):02X}{f(b):02X}"


def ftxt(t, size, color, name="Count", **kw):
    d = {"type": "TEXT", "text": t, "font": {"family": "Fredoka One", "style": "Regular"}, "size": size, "color": color, "name": name}
    d.update(kw)
    return d


ITEMS = [("fish/PebbleMinnow", "Common", 23, None), ("fish/BubbleCarp", "Common", 41, None), ("fish/PearlClam", "Uncommon", 6, None),
         ("fish/DewdropKoi", "Rare", 2, None), ("fish/CrystalGuppy", "Epic", 1, None), ("fish/CoralSeahorse", "Legendary", 1, None),
         ("fish/NagaHatchling", "Mythic", 1, None), ("fish/MoonJelly", "Rare", 1, "fish/mut_glowing"), ("equipment/Worm", "Bait", 14, None),
         ("ui/status/treasure_chest", "Epic", 2, None)]
S = 88  # slot size


def right_row(y, child, w=S, pad=6):
    return {"name": "Count Row", "layout": "H", "w": w, "x": 0, "y": y, "main": "MAX", "pad": [0, pad, 0, 0], "children": [child]}


def count_pill(n, fill="FFFFFF", fg="3D4B5C", opacity=0.92):
    return {"name": "Count", "layout": "H", "pad": [1, 7, 2, 7], "radius": 999, "fill": {"hex": fill, "opacity": opacity},
            "children": [ftxt(f"x{n}", 14, fg, name="Value")]}


# ------------------------------------------------------------------ six styles
def slot_a(item):  # Rarity Glow
    path, rar, n, mut = item or (None, "Common", 0, None)
    col = RAR[rar]
    kids = []
    if path:
        kids += [img(path, 64, x=12, y=8),
                 {"type": "ELLIPSE", "name": "Rarity Gem", "w": 12, "h": 12, "x": 8, "y": 8, "fill": col, "stroke": "FFFFFF", "strokeW": 2},
                 right_row(62, count_pill(n))]
    return {"name": "Slot", "w": S, "h": S, "radius": 18, "clip": True, "fill": {"grad": ["FFFFFF", mix(col, 0.55) if path else "F3E9D8"], "angle": 90},
            **BORDER, "children": kids}


def slot_b(item):  # Pastel Ribbon
    path, rar, n, mut = item or (None, "Common", 0, None)
    col = RAR[rar]
    kids = []
    if path:
        kids += [img(path, 60, x=14, y=4),
                 {"name": "Ribbon", "layout": "H", "w": S, "h": 22, "x": 0, "y": S - 22, "main": "CENTER", "cross": "CENTER", "fill": col,
                  "children": [ftxt(f"x{n}", 14, "FFFFFF", name="Value")]}]
    return {"name": "Slot", "w": S, "h": S, "radius": 16, "clip": True, "fill": mix(col, 0.78) if path else "F3E9D8", **BORDER, "children": kids}


def slot_c(item):  # Bubble
    path, rar, n, mut = item or (None, "Common", 0, None)
    col = RAR[rar]
    circle = {"name": "Bubble", "w": 80, "h": 80, "x": 4, "y": 2, "radius": 999, "fill": mix(col, 0.7) if path else "F3E9D8",
              "stroke": "FFFFFF", "strokeW": 4, "effects": [{"color": "3D4B5C", "a": 0.12, "y": 3, "blur": 6}], "clip": True,
              "children": [img(path, 56, x=12, y=10)] if path else []}
    kids = [circle]
    if path:
        kids.append(right_row(64, {"name": "Count", "layout": "H", "pad": [1, 8, 2, 8], "radius": 999, "fill": col, "stroke": "FFFFFF", "strokeW": 2,
                                   "children": [ftxt(f"x{n}", 13, "FFFFFF", name="Value")]}, pad=0))
    return {"name": "Slot", "w": S, "h": S, "children": kids}


def slot_d(item):  # Card + Name
    path, rar, n, mut = item or (None, "Common", 0, None)
    col = RAR[rar]
    label = path.split("/")[-1] if path else "Empty"
    for a, b in [("PebbleMinnow", "Minnow"), ("BubbleCarp", "Carp"), ("PearlClam", "Clam"), ("DewdropKoi", "Koi"), ("CrystalGuppy", "Guppy"),
                 ("CoralSeahorse", "Seahorse"), ("NagaHatchling", "Naga"), ("MoonJelly", "Jelly"), ("treasure_chest", "Chest")]:
        label = label.replace(a, b)
    kids = [{"type": "RECT", "name": "Rarity Stripe", "w": S, "h": 6, "x": 0, "y": 0, "fill": col if path else "E6DCCB"}]
    if path:
        kids += [img(path, 58, x=15, y=12),
                 text(label, "Caption", "cozy/text", name="Name", align="CENTER", w=S - 8, x=4, y=74),
                 right_row(10, count_pill(n, "3D4B5C", "FFFFFF", 0.75), pad=4)]
    return {"name": "Slot", "w": S, "h": 96, "radius": 14, "clip": True, "fill": v("cozy/panel"), **BORDER, "children": kids}


def slot_e(item):  # Soft Lip
    path, rar, n, mut = item or (None, "Common", 0, None)
    col = RAR[rar]
    kids = []
    if path:
        kids += [img(path, 62, x=13, y=6),
                 right_row(58, ftxt(f"{n}", 18, "FFFFFF", name="Value", textStroke="3D4B5C", textStrokeW=3), pad=8)]
    return {"name": "Slot", "w": S, "h": S, "radius": 18, "clip": True, "fill": mix(col, 0.82) if path else "F3E9D8",
            "stroke": col if path else "E6DCCB", "strokeSides": {"b": 6}, "strokeAlign": "INSIDE", "children": kids}


CORNER = lambda col: ('<svg width="34" height="34" viewBox="0 0 34 34" xmlns="http://www.w3.org/2000/svg">'
                      f'<path d="M0 0H34L0 34Z" fill="#{col}"/></svg>')


def slot_f(item):  # Corner Ribbon
    path, rar, n, mut = item or (None, "Common", 0, None)
    col = RAR[rar]
    kids = []
    if path:
        kids += [img(path, 68, x=10, y=6),
                 {"type": "SVG", "svg": CORNER(col), "w": 34, "h": 34, "x": 0, "y": 0, "name": "Rarity Corner"},
                 right_row(64, ftxt(f"x{n}", 15, "3D4B5C", name="Value"), pad=8)]
    return {"name": "Slot", "w": S, "h": S, "radius": 20, "clip": True, "fill": "FFFFFF" if path else "F3E9D8", **BORDER,
            "effects": [{"color": "3D4B5C", "a": 0.08, "y": 4, "blur": 10}] if path else [], "children": kids}


STYLES = [
    ("A", "Rarity Glow", "White tile fading into the rarity colour at the bottom, small rarity gem, count in a white pill. Clean and readable.", slot_a),
    ("B", "Pastel Ribbon", "Whole tile tinted by rarity with a solid rarity ribbon at the bottom carrying the count. Rarity reads instantly.", slot_b),
    ("C", "Bubble", "Round bubble like the Main Menu icons, rarity-coloured count badge. Softest, most 'cozy' look.", slot_c),
    ("D", "Card + Name", "Small card with rarity stripe on top and the item name under the picture. Best when players don't know the items yet.", slot_d),
    ("E", "Soft Lip", "Tinted tile with a thick rarity-coloured bottom lip (same idea as the buttons) and a bold game-style number.", slot_e),
    ("F", "Corner Ribbon  (CHOSEN)", "Bright white tile with a plain rarity corner (no star). Biggest item picture, minimal colour. Square 1:1.", slot_f),
]


def holder(slot_fn, item, state=None, mut=None):
    slot = dict(slot_fn(item), x=6, y=10)
    kids = [slot]
    h = max(slot.get("h", S) + 14, 104)
    if state == "selected":
        slot["effects"] = (slot.get("effects") or []) + [{"color": "FF9E80", "a": 1, "spread": 3, "blur": 0}]
        kids.append({"name": "Check", "w": 24, "h": 24, "x": 76, "y": 2, "radius": 999, "fill": v("cozy/coral"), "stroke": "FFFFFF", "strokeW": 2,
                     "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [
                         {"type": "SVG", "svg": '<svg width="14" height="14" viewBox="0 0 14 14" xmlns="http://www.w3.org/2000/svg"><path d="M2.5 7.5l3 3 6-7" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>',
                          "w": 14, "h": 14, "name": "Tick"}]})
    if state == "new":
        kids.append(dict(small_pill("NEW", "cozy/coral", "New Badge"), x=0, y=2))
    if state == "locked":
        kids.append(m.fa_lock(34, x=6 + round((S - 34 * 448 / 512) / 2), y=10 + round((S - 34) / 2)))
        slot["opacity"] = 0.7
    if state == "empty":
        kids.append(ftxt("+", 30, "C9BBA3", name="Plus", x=41, y=34))
    if item and item[3]:
        kids.append(img(item[3], 26, x=72, y=4))
    return {"name": "Holder", "w": 100, "h": h, "children": kids}


def option(key, title, desc, fn):
    grid = {"name": "Items", "layout": "H", "wrap": True, "gap": 10, "rowGap": 8, "w": 552, "children": [holder(fn, it) for it in ITEMS]}
    rare = ITEMS[3]
    states = {"name": "States", "layout": "H", "gap": 10, "children": [
        {"name": "State " + lab, "layout": "V", "gap": 2, "cross": "CENTER", "children": [
            holder(fn, it, st), text(lab, "Caption", "cozy/subtext", name="Caption")]}
        for lab, it, st in [("NORMAL", rare, None), ("SELECTED", rare, "selected"), ("NEW", ITEMS[6], "new"), ("EMPTY", None, "empty"), ("LOCKED", ITEMS[5], "locked")]]}
    return {"name": f"Option {key} — {title}", "layout": "V", "gap": 14, "pad": 24, "w": 600, "radius": 24, "fill": v("cozy/panel"), **BORDER,
            "effects": m.SOFT, "children": [
                text(f"{key}. {title}", "Title", name="Title"),
                text(desc, "Small", "cozy/subtext", name="Desc", w=552),
                grid,
                {"type": "RECT", "name": "Divider", "w": 552, "h": 2, "fill": v("cozy/track")},
                text("STATES", "Caption", "cozy/subtext", name="States Label"),
                states]}


def build():
    cards = []
    for i, (k, t, d, fn) in enumerate(STYLES):
        col, row = i % 3, i // 3
        cards.append(dict(option(k, t, d, fn), x=60 + col * 660, y=150 + row * 720))
    sec = {"type": "SECTION", "name": "Inventory · ItemSlot Options", "fill": "F3E9D8", "x": 8900, "y": 0, "children": [
        text("Inventory · ItemSlot — 6 options", "Display", name="Title", x=60, y=40),
        text("Same 10 items (Common → Mythic, mutation, bait, treasure) and the same 5 states in every option. Pick one (or mix two).",
             "Body", "cozy/subtext", name="Sub", x=60, y=96, w=1800)] + cards}
    return {"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    with open(os.path.join(out, "8_itemslot_options.json"), "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("written")
