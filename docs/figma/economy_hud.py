"""Economy UI step 1 (docs/HANDOFF_ECONOMY_UI.md §1 + Catch Result streak), revision 2 (user, 2026-11-17):
  - Hot Streak = small tag on the CAST button's top-right corner (not a separate badge)
  - Pearls = one more chip in the currency row
  - Boosts = round icons with a 360° countdown ring + short time (1D / 23h / 45m / 30s, never 00:00:00)
  - VIP = name tag over the character's head only
  - no "next purchase" widget
New section "Economy · 1 HUD + Streak" (right of everything). Nothing existing is touched; once approved
the pieces get patched into 01 · HUD / 04 · Catch Result.

New art (ui/status/pearl, hot_streak, ui/icons/vip) is not generated yet: those slots are tinted
placeholders named "Img <key>", so tools/art/figma_images.py fills them once assets/art/<key>.png exists.
Numbers use the x10 economy: k / M from 10,000 (12.4k, 950k, 1.2M).

Run:  python -I docs/figma/economy_hud.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/20_economy_hud_ops.json
Then: python -I tools/art/figma_images.py --root <built id>
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


m = _load("menus", "cozy_menus_spec.py")
mt = _load("tiles", "menu_tiles.py")
ro = _load("reel", "reel_options.py")
v, text, BORDER, SOFT, PAGE_ID = m.v, m.text, m.BORDER, m.SOFT, m.PAGE_ID
btn, chip, tag, img, ftxt, small_pill = m.btn, m.chip, m.tag, m.img, m.ftxt, m.small_pill
SAFE_TOP = m.SAFE_TOP

STREAK_STEP = 5      # % per streak stack (x7 = +35%)
STREAK_MAX = 10      # x10 = +50% MAX
OUTLINE = {"textStroke": "3D4B5C"}
CORAL_GRAD = {"grad": ["FFB199", "FF7A59"], "angle": 90}
BLAZE_GRAD = {"grad": ["FFD45C", "FF7A59"], "angle": 90}
FLAME_SVG = ('<svg width="14" height="14" viewBox="0 0 14 14" xmlns="http://www.w3.org/2000/svg">'
             '<path d="M7 1c.6 2.2 3.6 3.6 3.6 7A3.6 3.6 0 0 1 3.4 8c0-1.6.8-2.6 1.6-3.3C5 6 5.6 6.6 6.3 6.6 6.3 4.6 6 2.6 7 1z" fill="#FFFFFF"/></svg>')


def ph(key, w, h=None, tint="E5DBFA", round_=True, **kw):
    """Image slot with a visible tint until the art lands."""
    return img(key, w, h, fill={"hex": tint}, radius=999 if round_ else 10, **kw)


def flame(size=14):
    return {"type": "SVG", "svg": FLAME_SVG.replace('width="14" height="14"', f'width="{size}" height="{size}"'), "w": size, "h": size, "name": "Icon flame"}


def short_time(sec):
    """Boost label: biggest unit only. 1D+ -> 'ND', 1h+ -> 'Nh', 1m+ -> 'Nm', else 'Ns'."""
    for unit, size in (("D", 86400), ("h", 3600), ("m", 60)):
        if sec >= size:
            return f"{sec // size}{unit}"
    return f"{sec}s"


# ---------------------------------------------------------------- HUD pieces
def side_menu():
    """Same as 01 HUD today (menu_tiles.py): outlined labels, Menu = StarterPouch."""
    return {"name": "Menu", "layout": "V", "gap": 10, "x": 16, "y": 292, "children": [mt.tile(*t) for t in mt.TILES.values()]}


def pearl_chip(value="1,250", rate="+0.025/s"):
    """Same look as the Coins/Gems chip + a mint idle-rate caption (the value ticks up live)."""
    return {"name": "Pearls", "layout": "H", "gap": 6, "pad": [6, 14, 6, 8], "cross": "CENTER", "radius": 999,
            "fill": v("cozy/panel"), **BORDER, "children": [
                ph("ui/status/pearl", 24, tint="E8E2F7"),
                text(value, "Number", name="Value"),
                text(rate, "Caption", "cozy/mint-lip", name="Rate")]}


BOOSTS = {  # icon art, ring colour, icon tint while the art is missing
    "Coins": ("ui/shop/boost_coins", "F2B544", None),
    "Pearls": ("ui/shop/boost_pearls", "B79CF2", None),
}
RING = 48


def boost_ring(kind="Coins", sec=3600, total=7200, mult="2x"):
    """48px disc: track ring + coloured arc of the time left (drains clockwise), icon in the middle,
    multiplier tag top-right, short time under it."""
    key, col, tint = BOOSTS[kind]
    left = max(0.0, min(1.0, sec / total))
    r = RING / 2 - 3

    def seg(a1, c):  # SVG arcs near 360° degenerate: split at 180°
        return [(r, 0, min(a1, 180), c, 5)] + ([(r, 180, a1, c, 5)] if a1 > 180 else [])
    arcs = seg(360, "DDD0BA")
    if left > 0:
        arcs += seg(max(1, 360 * left), col)
    icon = ph(key, 28, tint=tint) if tint else img(key, 28)
    icon.update(x=(RING - 28) / 2, y=(RING - 28) / 2)
    return {"name": "Boost " + kind, "w": RING, "h": RING + 12, "clip": False, "children": [
        {"type": "ELLIPSE", "name": "Disc", "w": RING, "h": RING, "x": 0, "y": 0, "fill": v("cozy/panel")},
        dict(ro.svg_arcs(RING, arcs, "Ring"), x=0, y=0),
        icon,
        {"name": "Mult", "layout": "H", "pad": [1, 5, 1, 5], "radius": 999, "x": RING - 20, "y": -4, "fill": {"hex": col},
         "stroke": "FFFFFF", "strokeW": 2, "children": [ftxt(mult, 11, "FFFFFF", name="Value")]},
        ftxt(short_time(sec), 14, "FFFFFF", name="Time", textStrokeW=2.5, align="CENTER", w=RING, x=0, y=RING - 6, **OUTLINE)]}


def stats(boosts=(("Coins", 5400, 7200), ("Pearls", 86400 + 3600, 172800))):
    kids = [
        {"name": "Level Row", "layout": "H", "gap": 10, "cross": "CENTER", "pad": [0, 5, 0, 5], "children": [
            ftxt("Lv.12", 30, "FFFFFF", name="Level", textStrokeW=3, **OUTLINE),
            ftxt("340 / 900 XP", 16, "FFFFFF", name="XP Text", textStrokeW=2.5, **OUTLINE)]},
        {"name": "Currencies", "layout": "H", "gap": 6, "pad": [0, 0, 0, 5], "children": [
            chip("Coins", "12.4k", "Coins"), chip("Gems", "320", "Gems"), pearl_chip()]},
    ]
    if boosts:
        kids.append({"name": "Boosts", "layout": "H", "gap": 10, "pad": [4, 0, 0, 7], "children": [boost_ring(k, s, t) for k, s, t in boosts]})
    return {"name": "Stats", "layout": "V", "gap": 6, "x": 16, "y": SAFE_TOP, "children": kids}


def streak_tag(n=7):
    """Small tag on the CAST button's top-right corner. Warm 1-4, hot 5-9, blaze 10 (glow). x0 = LOST (grey, fades)."""
    fx = None
    if n <= 0:
        fill, label = {"hex": "B8C2CC"}, "LOST"
    elif n < 5:
        fill, label = {"hex": "F2B544"}, f"x{n}"
    elif n < STREAK_MAX:
        fill, label = CORAL_GRAD, f"x{n}"
    else:
        fill, label = BLAZE_GRAD, f"x{n}"
        fx = [{"color": "FF7A59", "a": 0.6, "blur": 10, "spread": 1}]
    d = {"name": "Streak", "layout": "H", "gap": 2, "pad": [2, 7, 2, 5], "cross": "CENTER", "radius": 999,
         "fill": fill, "stroke": "FFFFFF", "strokeW": 2, "children": [flame(12), ftxt(label, 13, "FFFFFF", name="Count")]}
    if fx:
        d["effects"] = fx
    return d


def cast_with_streak(n=7, name="Cast"):
    """CAST button + streak tag pinned to its top-right corner (overhangs the edge)."""
    kids = [dict(btn("Primary", "CAST", "Btn Cast"), x=0, y=10)]
    if n is not None:
        kids.append(dict(streak_tag(n), x=78 if n < 10 and n > 0 else 70, y=0))
    return {"name": name, "w": 115, "h": 67, "clip": False, "children": kids}


def player(x, y, vip=True):
    """Fake character on the island with the BillboardGui name tag over the head."""
    name_c = "F2B544" if vip else "FFFFFF"
    row = [ftxt("PipFisher", 20, name_c, name="Name", textStrokeW=3, **OUTLINE)]
    if vip:
        row.insert(0, ph("ui/icons/vip", 22, tint="F2B544", round_=False))
    tag_ = {"name": "Name Tag " + ("VIP" if vip else "Normal"), "layout": "V", "gap": 0, "cross": "CENTER", "w": 180, "x": x - 90, "y": y - 56,
            "children": [{"name": "Name Row", "layout": "H", "gap": 4, "cross": "CENTER", "children": row},
                         ftxt("Lv.42", 13, "FFFFFF", name="Level", textStrokeW=2, **OUTLINE)]}
    body = {"name": "Character [skip]", "w": 44, "h": 86, "x": x - 22, "y": y, "children": [
        {"type": "ELLIPSE", "name": "Head", "w": 30, "h": 30, "x": 7, "y": 0, "fill": {"hex": "FFD9B3"}, "stroke": {"hex": "3D4B5C", "opacity": 0.25}, "strokeW": 1.5},
        {"type": "RECT", "name": "Body", "w": 36, "h": 40, "x": 4, "y": 30, "radius": 10, "fill": {"hex": "6BB3DE"}},
        {"type": "RECT", "name": "Legs", "w": 28, "h": 18, "x": 8, "y": 68, "radius": 6, "fill": {"hex": "3D4B5C", "opacity": 0.7}}]}
    return [body, tag_]


def hud_screen():
    cast = {"name": "Cast Row", "layout": "H", "w": m.W, "x": 0, "y": 600, "gap": 10, "main": "CENTER", "cross": "MAX",
            "children": [cast_with_streak(7), m.depth_button()]}
    return m.screen("HUD · Economy", [*player(640, 330), stats(), side_menu(), m.actions(), cast])


# ---------------------------------------------------------------- Catch Result
def streak_pill(n=7):
    return {"name": "Streak", "layout": "H", "gap": 4, "pad": [3, 10, 3, 7], "cross": "CENTER", "radius": 999, "fill": CORAL_GRAD,
            "children": [flame(14), text(f"x{n} +{n * STREAK_STEP}%", "Caption", "cozy/on-accent", name="Label")]}


def hot_pill(mult=3):
    return {"name": "Hot", "layout": "H", "gap": 4, "pad": [3, 10, 3, 10], "cross": "CENTER", "radius": 999, "fill": BLAZE_GRAD,
            "children": [text(f"HOT x{mult}", "Caption", "cozy/on-accent", name="Label")]}


def catch_card():
    return {"name": "Catch Card", "layout": "V", "gap": 8, "pad": 22, "w": 400, "radius": 24, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
            "children": [
                {"name": "Tags", "layout": "H", "gap": 6, "cross": "CENTER", "children": [
                    tag("Rare"), small_pill("NEW!", "cozy/coral", "New"), streak_pill(7), hot_pill(3), img("fish/mut_glowing", 30)]},
                img("fish/GlowEel", 356, 150),
                text("Glowing Glow Eel", "Display", "cozy/rarity/rare", name="FishName"),
                text("Rare  •  4.2 kg  •  Manual  •  PERFECT", "Small", "cozy/subtext", name="Meta"),
                {"type": "RECT", "name": "Divider", "h": 2, "w": 300, "fill": v("cozy/track"), "fillW": True},
                {"name": "Rewards", "layout": "H", "gap": 10, "children": [chip("Coins", "+14.0k", "Coins"), chip("Gems", "+1", "Gems")]},
                text("Glowing x1.8  •  Manual x1.5  •  Perfect +0.25  •  Streak +35%  •  Hot x3", "Caption", "cozy/subtext", name="Breakdown", w=356)]}


# ---------------------------------------------------------------- section
def board(title, desc, children, w=760):
    stage = {"name": "Stage", "layout": "H", "gap": 24, "pad": 24, "cross": "CENTER", "radius": 18, "fillW": True,
             "fill": {"grad": ["DDF5EE", "A8DCD8"], "angle": 90}, "children": children}
    return {"name": title, "layout": "V", "gap": 10, "pad": 24, "w": w, "radius": 24, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
            "children": [text(title, "Title", name="Title"), text(desc, "Small", "cozy/subtext", name="Desc", w=w - 48), stage]}


def build():
    right = [
        board("Hot Streak · tag on CAST", f"Small tag pinned to CAST's top-right corner. +{STREAK_STEP}% coins per stack, MAX x{STREAK_MAX}. "
              "Warm 1-4 (gold), hot 5-9 (coral), x10 blaze (glow). Auto catches do not change it; a line snap or missed hook shows LOST "
              "for ~1.5 s, then it fades. Hidden at x0. The % shows on the Catch Result card.",
              [cast_with_streak(2, "x2"), cast_with_streak(7, "x7"), cast_with_streak(10, "x10"), cast_with_streak(0, "Lost")]),
        board("Boosts · countdown rings", "One ring per active boost, under the currencies. The coloured arc is the time left and drains clockwise. "
              "Time shows only its biggest unit: 1D+ → 1D, 2D · 1h+ → 23h, 1h · 1m+ → 45m, 20m · under 1m → 30s. Gone at 0.",
              [boost_ring("Coins", 2 * 86400, 2 * 86400), boost_ring("Coins", 23 * 3600, 2 * 86400), boost_ring("Pearls", 3600 + 1200, 7200),
               boost_ring("Pearls", 20 * 60, 7200), boost_ring("Coins", 30, 7200)]),
        board("VIP · over the head", "BillboardGui on the character only. VIP: gold name + crown (ui/icons/vip). Others keep the white name.",
              [{"name": "VIP", "w": 200, "h": 150, "children": player(100, 60, True)},
               {"name": "Normal", "w": 200, "h": 150, "children": player(100, 60, False)}]),
    ]
    rcol = {"name": "Parts", "layout": "V", "gap": 30, "x": 60 + 1280 + 60, "y": 150, "children": right}
    catch = {"name": "04 · Catch Result (economy)", "layout": "V", "gap": 10, "pad": 24, "w": 520, "radius": 24, "x": 60, "y": 150 + 720 + 60,
             "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                 text("04 · Catch Result (economy)", "Title", name="Title"),
                 text("Tags row adds the streak pill with its % and HOT xN (Hot fish of the hour). Numbers are x10 now, so rewards use k / M.",
                      "Small", "cozy/subtext", name="Desc", w=472),
                 catch_card()]}
    numbers = {"name": "Number format", "layout": "V", "gap": 8, "pad": 24, "w": 600, "radius": 24, "x": 640, "y": 150 + 720 + 60,
               "fill": v("cozy/panel"), **BORDER, "children": [
                   text("Number format (x10 economy)", "Title", name="Title"),
                   text("Below 10,000: full with commas  →  8,450\n10,000 and up: one decimal + k  →  12.4k · 950k\n1,000,000 and up: + M  →  1.2M · 15M\n"
                        "Every coin/pearl/price field must fit 6 characters (e.g. 999.9k).", "Body", name="Rules", w=552)]}
    hud = {"name": "HUD Frame", "layout": "V", "gap": 12, "x": 60, "y": 110, "children": [text("01 · HUD (economy)", "Title", name="Title"), hud_screen()]}
    sec = {"type": "SECTION", "name": "Economy · 1 HUD + Streak (C12/C14/C19)", "fill": "F3E9D8", "x": 14400, "y": 0, "children": [
        text("Economy UI · 1 — HUD + Streak", "Display", name="Title", x=60, y=40), hud, rcol, catch, numbers]}
    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "20_economy_hud_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
