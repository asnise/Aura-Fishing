"""6 redesign options for the Reel Minigame (Figma Section on page Out Space).

Run:  python -I docs/figma/reel_options.py docs/figma/out
Send: figma-run.mjs --channel=aura-fishing build_tree docs/figma/out/11_reel_options.json
Then: python -I tools/art/figma_images.py --root <rootId>
"""
import importlib.util
import json
import math
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
img, text, v, BORDER, tag, btn, SOFT, ftxt, PAGE_ID = m.img, m.text, m.v, m.BORDER, m.tag, m.btn, m.SOFT, m.ftxt, m.PAGE_ID

SW, SH = 552, 440  # scene size


def scene(children):
    world = [{"type": "RECT", "name": "Water", "w": SW, "h": 200, "x": 0, "y": 240, "fill": {"hex": "9AD4F5", "opacity": 0.35}},
             {"type": "ELLIPSE", "name": "Island", "w": 300, "h": 80, "x": -60, "y": 205, "fill": {"hex": "7FD3B0", "opacity": 0.5}}]
    return {"name": "Scene", "w": SW, "h": SH, "radius": 18, "clip": True, "fill": {"grad": ["DDF5EE", "A8DCD8"], "angle": 90},
            "children": [{"name": "World [skip]", "w": SW, "h": SH, "x": 0, "y": 0, "children": world}] + children}


def bubbles(w, h, n=5):
    pts = [(0.2, 0.15, 10), (0.7, 0.3, 7), (0.35, 0.55, 12), (0.75, 0.75, 8), (0.25, 0.88, 6)][:n]
    return [{"type": "ELLIPSE", "name": "Bubble", "w": d, "h": d, "x": round(px * w), "y": round(py * h), "fill": {"hex": "FFFFFF", "opacity": 0.5}} for px, py, d in pts]


def arc_path(cx, cy, r, a0, a1):
    rad = lambda a: math.radians(a - 90)
    x0, y0 = cx + r * math.cos(rad(a0)), cy + r * math.sin(rad(a0))
    x1, y1 = cx + r * math.cos(rad(a1)), cy + r * math.sin(rad(a1))
    large = 1 if (a1 - a0) % 360 > 180 else 0
    return f"M{x0:.1f} {y0:.1f} A{r} {r} 0 {large} 1 {x1:.1f} {y1:.1f}"


def svg_arcs(size, arcs, name):
    body = "".join(f'<path d="{arc_path(size / 2, size / 2, r, a0, a1)}" stroke="#{c}" stroke-width="{w}" stroke-linecap="round" fill="none"/>'
                   for r, a0, a1, c, w in arcs)
    return {"type": "SVG", "name": name, "w": size, "h": size,
            "svg": f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" xmlns="http://www.w3.org/2000/svg">{body}</svg>'}


def catch_bar(w, h, y, x=0, name="Catch Bar"):
    return {"name": name, "w": w, "h": h, "x": x, "y": y, "radius": 999, "fill": {"hex": "7FD3B0", "opacity": 0.85}, "stroke": "FFFFFF", "strokeW": 3}


# ------------------------------------------------------------------ A. Glass Tube
def opt_a():
    tube = {"name": "Water Tube", "w": 72, "h": 300, "radius": 999, "clip": True, "fill": {"grad": ["CFEFFF", "7FC3EE"], "angle": 90},
            "stroke": "FFFFFF", "strokeW": 3, "children": bubbles(72, 300) + [catch_bar(72, 84, 150), img("fish/EmberTuna", 54, x=9, y=165)]}
    prog = {"name": "Progress Column", "layout": "V", "gap": 6, "cross": "CENTER", "children": [
        img("ui/status/xp_star", 28),
        {"name": "Progress", "w": 22, "h": 266, "radius": 999, "fill": v("cozy/track"), "clip": True, "children": [
            {"type": "RECT", "name": "Fill", "w": 22, "h": 176, "x": 0, "y": 90, "radius": 999, "fill": {"grad": ["FFD45C", "F2B544"], "angle": 90}}]}]}
    panel = {"name": "Reel Minigame", "layout": "V", "gap": 10, "pad": 16, "cross": "CENTER", "x": 166, "y": 14, "radius": 32,
             "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                 {"name": "Header", "layout": "H", "gap": 8, "cross": "CENTER", "children": [tag("Epic"), text("???", "Heading", name="Fish Name")]},
                 {"name": "Body", "layout": "H", "gap": 14, "children": [tube, prog]},
                 text("HOLD TO REEL", "Caption", "cozy/subtext", name="Hint")]}
    return scene([panel])


# ------------------------------------------------------------------ B. Horizontal River
def opt_b():
    track = {"name": "River", "w": 452, "h": 60, "radius": 999, "clip": True, "fill": {"grad": ["CFEFFF", "9AD4F5"]},
             "stroke": "FFFFFF", "strokeW": 3, "children": [{"type": "ELLIPSE", "name": "Bubble", "w": 8, "h": 8, "x": x, "y": y, "fill": {"hex": "FFFFFF", "opacity": 0.6}}
                                                         for x, y in [(40, 14), (120, 38), (330, 18), (400, 40)]]
             + [catch_bar(120, 60, 0, x=170), img("fish/EmberTuna", 50, x=205, y=5)]}
    prog = {"name": "Progress", "w": 452, "h": 12, "radius": 999, "fill": v("cozy/track"), "clip": True, "children": [
        {"type": "RECT", "name": "Fill", "w": 300, "h": 12, "x": 0, "y": 0, "radius": 999, "fill": {"grad": ["FFD45C", "F2B544"]}}]}
    panel = {"name": "Reel Minigame", "layout": "V", "gap": 10, "pad": 16, "x": 34, "y": 268, "radius": 28,
             "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                 {"name": "Header", "layout": "H", "gap": 8, "cross": "CENTER", "w": 452, "children": [
                     tag("Rare"), text("Something big is biting!", "Small", "cozy/subtext", name="Hint")]},
                 track, prog]}
    return scene([panel])


# ------------------------------------------------------------------ C. Ring Reel
def opt_c():
    size = 300
    ring = svg_arcs(size, [(122, 0, 359.9, "CFEFFF", 30), (122, 40, 115, "7FD3B0", 30)], "Ring Track")
    centre = svg_arcs(150, [(56, 0, 359.9, "E6DCCB", 16), (56, 0, 234, "F2B544", 16)], "Progress Donut")
    a = math.radians(78 - 90)
    fx, fy = 150 + 122 * math.cos(a) - 24, 150 + 122 * math.sin(a) - 24
    panel = {"name": "Reel Minigame", "w": size, "h": size, "x": 126, "y": 22, "radius": 999, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
             "children": [dict(ring, x=0, y=0), img("fish/EmberTuna", 48, x=round(fx), y=round(fy)),
                          dict(centre, x=75, y=75),
                          dict(ftxt("65%", 30, "3D4B5C", name="Percent"), x=118, y=126),
                          dict(text("REEL!", "Caption", "cozy/subtext", name="Hint"), x=130, y=162)]}
    foot = {"name": "Footer", "layout": "H", "gap": 8, "cross": "CENTER", "w": SW, "x": 0, "y": 338, "main": "CENTER", "children": [
        tag("Legendary"), text("Keep the green arc on the fish", "Small", "cozy/subtext", name="Hint")]}
    return scene([panel, foot])


def ring_reel(name="Reel Minigame", x=0, y=0, size=300, rarity="Legendary"):
    """Chosen design (Option C). Wrapper with the ring panel + hint row; used by the HUD screen too."""
    k = size / 300
    r = round(122 * k)
    ring = svg_arcs(size, [(r, 0, 359.9, "CFEFFF", round(30 * k)), (r, 40, 115, "7FD3B0", round(30 * k))], "Ring Track")
    cs = round(150 * k)
    centre = svg_arcs(cs, [(round(56 * k), 0, 359.9, "E6DCCB", round(16 * k)), (round(56 * k), 0, 234, "F2B544", round(16 * k))], "Progress Donut")
    a = math.radians(78 - 90)
    fs = round(48 * k)
    fx, fy = size / 2 + r * math.cos(a) - fs / 2, size / 2 + r * math.sin(a) - fs / 2
    panel = {"name": "Ring", "w": size, "h": size, "x": 60, "y": 0, "radius": 999, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
             "children": [dict(ring, x=0, y=0), img("fish/EmberTuna", fs, x=round(fx), y=round(fy)), dict(centre, x=(size - cs) // 2, y=(size - cs) // 2),
                          {"name": "Centre Text", "layout": "V", "cross": "CENTER", "w": size, "x": 0, "y": round(size / 2 - 26 * k), "children": [
                              ftxt("65%", round(30 * k), "3D4B5C", name="Percent"), text("REEL!", "Caption", "cozy/subtext", name="Hint")]}]}
    foot = {"name": "Footer", "layout": "H", "w": size + 120, "x": 0, "y": size + 14, "main": "CENTER", "children": [
        {"name": "Hint Pill", "layout": "H", "gap": 8, "cross": "CENTER", "pad": [5, 14, 5, 6], "radius": 999, "fill": v("cozy/panel"), **BORDER,
         "children": [tag(rarity), text("Hold to spin the green arc onto the fish", "Small", "cozy/subtext", name="Hint")]}]}
    return {"name": name, "w": size + 120, "h": size + 50, "x": x, "y": y, "children": [panel, foot]}


# ------------------------------------------------------------------ D. Pond Card
def opt_d():
    water = {"name": "Water", "w": 130, "h": 286, "radius": 18, "clip": True, "fill": {"grad": ["BEE6FA", "4C8FC7"], "angle": 90},
             "children": [img("fish/deco_bubbles", 44, x=80, y=10), img("fish/deco_seaweed", 70, x=-6, y=220), img("fish/deco_seaweed", 54, x=88, y=236),
                          {"name": "Catch Bar", "w": 130, "h": 84, "x": 0, "y": 118, "radius": 16, "fill": {"hex": "7FD3B0", "opacity": 0.8}, "stroke": "FFFFFF", "strokeW": 3},
                          img("fish/EmberTuna", 58, x=36, y=131)]}
    meter = {"name": "Line Meter", "layout": "V", "gap": 6, "cross": "CENTER", "children": [
        text("REEL", "Caption", "cozy/subtext", name="Label"),
        {"name": "Progress", "w": 26, "h": 254, "radius": 999, "fill": v("cozy/track"), "clip": True, "children": [
            {"type": "RECT", "name": "Fill", "w": 26, "h": 160, "x": 0, "y": 94, "radius": 999, "fill": {"grad": ["FFD45C", "F2B544"], "angle": 90}},
            img("ui/status/bobber", 26, x=0, y=82)]}]}
    chip = lambda t, fill, fg: {"name": "Tension " + t, "layout": "H", "pad": [3, 10, 3, 10], "radius": 999, "fill": fill, "children": [text(t, "Caption", fg, name="Label")]}
    panel = {"name": "Reel Minigame", "layout": "V", "gap": 10, "pad": 16, "x": 116, "y": 10, "radius": 26, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
             "children": [
                 {"name": "Header", "layout": "H", "gap": 8, "cross": "CENTER", "children": [
                     tag("Rare"), {"name": "Depth", "layout": "H", "pad": [3, 10, 3, 10], "radius": 999, "fill": v("cozy/sky"),
                                   "children": [text("120m", "Caption", "cozy/on-accent", name="Label")]}, text("0:12", "Heading", "cozy/subtext", name="Timer")]},
                 {"name": "Body", "layout": "H", "gap": 14, "children": [water, meter]},
                 {"name": "Tension", "layout": "H", "gap": 6, "children": [chip("LOOSE", "F3E9D8", "cozy/subtext"), chip("GOOD", "7FD3B0", "cozy/on-accent"),
                                                                         chip("SNAP!", "FBE0DD", "cozy/danger-lip")]}]}
    return scene([panel])


# ------------------------------------------------------------------ E. Bobber Meter
def opt_e():
    donut = svg_arcs(96, [(40, 0, 359.9, "E6DCCB", 10), (40, 0, 252, "F2B544", 10)], "Progress Donut")
    bobber = {"name": "Catch Bar (Bobber)", "w": 64, "h": 78, "x": 0, "y": 100, "radius": 999, "stroke": "FFFFFF", "strokeW": 3,
              "fill": {"grad": ["FF9E80", "FF9E80", "FFF8EC", "FFF8EC"], "angle": 90}}
    track = {"name": "Water", "w": 64, "h": 236, "radius": 999, "clip": True, "fill": {"grad": ["CFEFFF", "7FC3EE"], "angle": 90},
             "children": bubbles(64, 236, 4) + [bobber, img("fish/EmberTuna", 46, x=9, y=116)]}
    panel = {"name": "Reel Minigame", "layout": "V", "gap": 10, "pad": [14, 14, 18, 14], "cross": "CENTER", "x": 210, "y": 18, "radius": 999,
             "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                 {"name": "Progress Badge", "w": 96, "h": 96, "children": [dict(donut, x=0, y=0), img("fish/MysteryFish", 46, x=25, y=25)]},
                 track, text("HOLD", "Caption", "cozy/subtext", name="Hint")]}
    return scene([panel])


# ------------------------------------------------------------------ F. Minimal HUD
def opt_f():
    track = {"name": "Track", "w": 42, "h": 300, "x": 330, "y": 50, "radius": 999, "clip": True, "fill": {"hex": "FFFFFF", "opacity": 0.55},
             "stroke": "FFFFFF", "strokeW": 2, "effects": [{"color": "B07CF0", "a": 0.55, "blur": 22}],
             "children": [catch_bar(42, 76, 140), img("fish/EmberTuna", 34, x=4, y=160)]}
    pips = {"name": "Progress Pips", "layout": "V", "gap": 8, "x": 300, "y": 96, "children": [
        {"type": "ELLIPSE", "name": "Pip", "w": 14, "h": 14, "fill": v("cozy/track") if i < 3 else {"grad": ["FFD45C", "F2B544"], "angle": 90},
         "stroke": "FFFFFF", "strokeW": 2} for i in range(10)]}
    rar = dict(tag("Epic"), x=322, y=18)
    hold = dict(btn("Primary", "HOLD", "Btn Hold"), x=420, y=368)
    bob = img("ui/status/bobber", 34, x=150, y=300)
    return scene([bob, track, pips, rar, hold])


OPTIONS = [
    ("A", "Glass Tube", "Current layout, polished: rounded glass tube with bubbles, capsule catch bar, star-capped gold progress. No code change beyond visuals.", opt_a),
    ("B", "Horizontal River", "Wide bar near the bottom of the screen — thumbs on mobile, doesn't cover the character. Code: swap the minigame axis (Y → X).", opt_b),
    ("C", "Ring Reel  (CHOSEN)", "Fish swims around a ring; keep the green arc on it. Progress donut in the middle. Most unique. Code: position → angle (new controller).", opt_c),
    ("D", "Pond Card", "Water gets darker with depth, seaweed + bubbles, bobber rides the progress, live tension chips and timer. Code: visuals + tension label.", opt_d),
    ("E", "Bobber Meter", "Compact pill: the catch bar is a coral/cream bobber, progress is a donut around the mystery fish. Small footprint. Code: visuals only.", opt_e),
    ("F", "Minimal HUD", "No panel: frosted track floating in the world with a rarity glow, 10 progress pips, big HOLD button for mobile. Code: visuals + touch button.", opt_f),
]


def card(key, title, desc, fn):
    return {"name": f"Option {key} — {title}", "layout": "V", "gap": 12, "pad": 24, "w": 600, "radius": 24, "fill": v("cozy/panel"), **BORDER,
            "effects": SOFT, "children": [text(f"{key}. {title}", "Title", name="Title"), text(desc, "Small", "cozy/subtext", name="Desc", w=552), fn()]}


def build():
    cards = [dict(card(*o), x=60 + (i % 3) * 660, y=150 + (i // 3) * 680) for i, o in enumerate(OPTIONS)]
    sec = {"type": "SECTION", "name": "Reel Minigame · 6 options", "fill": "F3E9D8", "x": 8900, "y": 1700, "children": [
        text("Reel Minigame — 6 redesign options", "Display", name="Title", x=60, y=40),
        text("Same moment in every option: an Epic/Rare fish is hooked, catch bar overlaps the fish, progress ~65%. Pick one (or mix).",
             "Body", "cozy/subtext", name="Sub", x=60, y=96, w=1800)] + cards}
    return {"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    with open(os.path.join(out, "12_reel_screen_patch.json"), "w", encoding="utf-8") as f:
        json.dump({"parentId": sys.argv[2] if len(sys.argv) > 2 else "3491:7771", "replaceName": "Reel Minigame",
                   "tree": ring_reel(x=430, y=110)}, f, ensure_ascii=False, indent=1)
    with open(os.path.join(out, "11_reel_options.json"), "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("written")
