"""Aura Gacha page — Reel Slot (chosen concept B) as full 1280x720 screens, matching src/client/UI/AuraReel.luau.

Run:  python -I docs/figma/gacha_page.py docs/figma/out
Send: figma-run.mjs --channel=aura-fishing build_tree docs/figma/out/17_gacha_page.json
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
img, text, v, BORDER, SOFT, ftxt, btn, tag, small_pill, chip, screen, PAGE_ID, W, H, SAFE_TOP = (
    m.img, m.text, m.v, m.BORDER, m.SOFT, m.ftxt, m.btn, m.tag, m.small_pill, m.chip, m.screen, m.PAGE_ID, m.W, m.H, m.SAFE_TOP)

RAR = {"Common": "9AA5B1", "Rare": "5AA9F0", "Epic": "B07CF0", "Legendary": "F2A93B", "Mythic": "F2668B"}
AURAS = [("SparklingDew", "Sparkling Dew", "Common", 10, 3), ("NeonWave", "Neon Wave", "Rare", 100, 1), ("SolarFlare", "Solar Flare", "Epic", 750, 0),
         ("AbyssalShadow", "Abyssal Shadow", "Legendary", 5000, 0), ("DragonEmperor", "Dragon Emperor", "Mythic", 50000, 0)]
ITEM, RW, RH = 96, 180, 288  # reel item / window (same numbers as AuraReel.luau)


def rays(size, color, n=12, opacity=0.3, **kw):
    c = size / 2
    body = ""
    for i in range(n):
        a0 = 2 * math.pi * i / n
        a1 = a0 + math.pi / n * 0.55
        body += f'<path d="M{c:.0f} {c:.0f} L{c + c * math.cos(a0):.0f} {c + c * math.sin(a0):.0f} L{c + c * math.cos(a1):.0f} {c + c * math.sin(a1):.0f}Z" fill="#{color}" fill-opacity="{opacity}"/>'
    d = {"type": "SVG", "name": "Rays", "w": size, "h": size, "svg": f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" xmlns="http://www.w3.org/2000/svg">{body}</svg>'}
    d.update(kw)
    return d


def outline(t, size, color="FFFFFF", **kw):
    return ftxt(t, size, color, name="Title", textStroke="3D4B5C", textStrokeW=3, **kw)


def dim(a=0.62):
    return {"type": "RECT", "name": "Dim", "w": W, "h": H, "x": 0, "y": 0, "fill": {"hex": "1A2140", "opacity": a}}


def reel(orbs, x, y, stroke="F2B544", faded=False, glow_col=None, offset=0):
    """orbs: list of aura ids top->bottom (3 visible). offset shifts the strip (px) for 'in-between' frames."""
    kids = [img("auras/" + a, 74, x=(RW - 74) // 2, y=i * ITEM + (ITEM - 74) // 2 + offset, opacity=0.45 if faded else 1) for i, a in enumerate(orbs)]
    kids.append({"type": "RECT", "name": "Centre Line", "w": RW, "h": 4, "x": 0, "y": RH // 2 - 2, "fill": {"hex": "FFFFFF", "opacity": 0.7}})
    d = {"name": "Reel Window", "w": RW, "h": RH, "x": x, "y": y, "radius": 28, "clip": True, "fill": v("cozy/panel"), "stroke": stroke, "strokeW": 5, "children": kids}
    if glow_col:
        d["effects"] = [{"color": glow_col, "a": 0.8, "blur": 30}]
    return d


def machine(x, y, orbs, stroke="F2B544", faded=False, glow_col=None, offset=0):
    """Reel window inside a cream cabinet."""
    return {"name": "Reel Machine", "w": 260, "h": 380, "x": x, "y": y, "children": [
        {"name": "Cabinet", "w": 260, "h": 360, "x": 0, "y": 10, "radius": 40, "fill": {"grad": ["FFF8EC", "F3E3C8"], "angle": 90}, **BORDER, "effects": SOFT, "children": [
            reel(orbs, 40, 36, stroke, faded, glow_col, offset),
            {"name": "Base Light", "w": 180, "h": 10, "x": 40, "y": 336, "radius": 999, "fill": stroke}]}]}


def rates_panel(x, y, w=480):
    rows = []
    for aid, name, r, chance, owned in AURAS:
        known = owned > 0
        rows.append({"name": "Rate " + name, "layout": "H", "gap": 10, "pad": [6, 10, 6, 6], "radius": 14, "cross": "CENTER", "fillW": True,
                     "fill": v("cozy/sand"), "children": [
                         img("auras/" + (aid if known else "UnknownAura"), 40),
                         {"name": "Text", "layout": "V", "gap": 0, "fillW": True, "children": [
                             text(name if known else "???", "Heading", "cozy/text" if known else "cozy/subtext", name="Name"),
                             {"name": "Meta", "layout": "H", "gap": 6, "cross": "CENTER", "children": [tag(r), text(f"1/{chance:,}", "Caption", "cozy/subtext", name="Chance")]}]},
                         ftxt(f"x{owned}" if owned else "-", 16, "3D4B5C" if owned else "9AA5B1", name="Owned")]})
    return {"name": "Rates", "layout": "V", "gap": 8, "pad": 16, "w": w, "x": x, "y": y, "radius": 24, "fill": v("cozy/panel"), **BORDER, "children": [
        {"name": "Head", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
            text("Drop rates", "Heading", name="Title"), text("OWNED", "Caption", "cozy/subtext", name="Owned Label")]}] + rows}


def pity(x, y, w=260):
    return {"name": "Pity", "layout": "V", "gap": 6, "pad": 12, "w": w, "x": x, "y": y, "radius": 18, "fill": v("cozy/panel"), **BORDER, "children": [
        {"name": "Row", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
            text("Mythic guaranteed in", "Small", "cozy/subtext", name="Label"), ftxt("53 rolls", 16, "F2668B", name="Value")]},
        {"name": "Bar", "w": w - 24, "h": 10, "radius": 999, "fill": v("cozy/track"), "clip": True, "children": [
            {"type": "RECT", "name": "Fill", "w": round((w - 24) * 37 / 90), "h": 10, "x": 0, "y": 0, "radius": 999, "fill": {"grad": ["F2A93B", "F2668B"]}}]}]}


def roll_bar(x, y, w=480):
    return {"name": "Roll Bar", "layout": "V", "gap": 10, "x": x, "y": y, "w": w, "children": [
        {"name": "Buttons", "layout": "H", "gap": 10, "fillW": True, "children": [
            {"name": "Btn Roll 1", "layout": "V", "gap": 0, "pad": [8, 12, 12, 12], "cross": "CENTER", "radius": 18, "fill": v("cozy/gem"), "stroke": v("cozy/gem-lip"),
             "strokeSides": {"b": 5}, "fillW": True, "children": [ftxt("ROLL x1", 20, "FFFFFF", name="Label"),
                                                                {"name": "Cost", "layout": "H", "gap": 4, "cross": "CENTER", "children": [img("ui/status/gem", 18), ftxt("5", 14, "FFFFFF", name="Value")]}]},
            {"name": "Btn Roll 10", "layout": "V", "gap": 0, "pad": [8, 12, 12, 12], "cross": "CENTER", "radius": 18, "fill": v("cozy/gold"), "stroke": v("cozy/gold-lip"),
             "strokeSides": {"b": 5}, "fillW": True, "children": [ftxt("ROLL x10", 20, "FFFFFF", name="Label"),
                                                                {"name": "Cost", "layout": "H", "gap": 4, "cross": "CENTER", "children": [img("ui/status/gem", 18), ftxt("45", 14, "FFFFFF", name="Value"),
                                                                                                                                          small_pill("-10%", "cozy/coral", "Discount")]}]}]},
        {"name": "Options", "layout": "V", "gap": 6, "children": [
            {"name": "Skip", "layout": "H", "gap": 8, "cross": "CENTER", "children": [m.checkbox(False), text("Skip animation", "Small", "cozy/text", name="Label")]},
            {"name": "Auto Roll", "layout": "H", "gap": 8, "cross": "CENTER", "children": [m.checkbox(False), text("Auto-roll until Epic+", "Small", "cozy/text", name="Label")]}]}]}


def comp(spec, name, key):
    d = dict(spec)
    d.pop("x", None)
    d.pop("y", None)
    d.update({"type": "COMPONENT", "name": name, "key": key})
    return d


def inst(key, x, y, name=None, texts=None):
    d = {"type": "INSTANCE", "ref": key, "x": x, "y": y}
    if name:
        d["name"] = name
    if texts:
        d["texts"] = texts
    return d


def components_section():
    items = [
        ("Reel Machine", comp(machine(0, 0, ["SparklingDew", "UnknownAura", "NeonWave"]), "Gacha / Reel Machine", "g_machine")),
        ("Pity", comp(pity(0, 0), "Gacha / Pity", "g_pity")),
        ("Roll Bar", comp(roll_bar(0, 0), "Gacha / Roll Bar", "g_roll")),
        ("Reveal Card", comp(reveal_card(0, 0), "Gacha / Reveal Card", "g_reveal")),
        ("Rates", comp(rates_panel(0, 0), "Gacha / Rates", "g_rates")),
    ]
    cols = []
    for label, c in items:
        cols.append({"name": "Slot " + label, "layout": "V", "gap": 10, "children": [text(label, "Heading", "cozy/subtext", name="Label"), c]})
    return {"type": "SECTION", "name": "Gacha · Components (edit here)", "fill": "FBF7EF", "x": 80, "y": 80, "children": [
        text("Gacha · Components (edit here — every screen uses instances)", "Display", name="Title", x=60, y=30),
        {"name": "Row", "layout": "H", "gap": 48, "x": 60, "y": 110, "children": cols}]}


def altar_window():
    return {"name": "Aura Altar", "w": 860, "h": 640, "x": 160, "y": 66, "radius": 32, "fill": {"grad": ["FBF7EF", "EFE6F8"], "angle": 90}, **BORDER, "effects": SOFT,
            "clip": True, "children": [
                rays(700, "B79CF2", 16, 0.12, x=-120, y=-110),
                {"name": "Header", "layout": "H", "w": 812, "x": 24, "y": 20, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                    {"name": "Title", "layout": "H", "gap": 10, "cross": "CENTER", "children": [img("ui/icons/auras", 44), text("Aura Altar", "Display", name="Title")]},
                    {"name": "Right", "layout": "H", "gap": 10, "cross": "CENTER", "children": [chip("Gems", "320"), btn("Danger", "X", "Btn Close")]}]},
                inst("g_machine", 40, 96, "Reel Machine"),
                inst("g_rates", 340, 96, "Rates"),
                inst("g_pity", 40, 486, "Pity"),
                inst("g_roll", 340, 486, "Roll Bar")]}


def s_altar():
    return screen("Gacha - Altar", [dim(0.35), altar_window()])


def overlay_screen(name, kids, a=0.62):
    return screen(name, [dim(a)] + kids)


def hint(t, color="FFFFFF", y=548):
    return {"name": "Hint Row", "layout": "H", "w": W, "x": 0, "y": y, "main": "CENTER", "children": [outline(t, 28, color)]}


def s_spin():
    streaks = [{"type": "RECT", "name": "Speed Line", "w": 5, "h": 70, "x": x, "y": 220, "radius": 3, "fill": {"hex": "FFFFFF", "opacity": 0.5}} for x in [480, 500, 780, 800]]
    return overlay_screen("Gacha - Spinning", streaks + [machine(510, 120, ["NeonWave", "SolarFlare", "SparklingDew", "AbyssalShadow"], faded=True, offset=-40),
                                                         hint("SPINNING!"), text("tap anywhere to skip", "Caption", "cozy/on-accent", name="Skip Hint", x=578, y=590)])


def s_close():
    glow = {"type": "ELLIPSE", "name": "Glow", "w": 300, "h": 300, "x": 490, "y": 140, "fill": {"hex": RAR["Legendary"], "opacity": 0.35},
            "effects": [{"color": RAR["Legendary"], "a": 0.8, "blur": 90}]}
    arrow = {"type": "SVG", "name": "Arrow", "w": 24, "h": 24, "x": 512, "y": 308,
             "svg": '<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M2 2L22 12L2 22Z" fill="#FFFFFF"/></svg>'}
    return overlay_screen("Gacha - So Close", [glow, machine(510, 120, ["SparklingDew", "DragonEmperor", "SolarFlare"], stroke=RAR["Epic"], offset=40), arrow,
                                               hint("so close...", "FFD9A0")])


def s_lock():
    conf_cols = ["FF9E80", "7FD3B0", "9AD4F5", "F2B544", "B79CF2"]
    conf = [{"type": "RECT", "name": "Confetti", "w": 9, "h": 14, "x": x, "y": y, "radius": 2, "fill": conf_cols[i % 5]} for i, (x, y) in enumerate(
        [(420, 140), (470, 470), (860, 160), (820, 460), (640, 90), (380, 300), (900, 300), (560, 520), (720, 530), (450, 220), (840, 240)])]
    flash = {"type": "RECT", "name": "Flash", "w": W, "h": H, "x": 0, "y": 0, "fill": {"hex": "FFFFFF", "opacity": 0.25}}
    return overlay_screen("Gacha - Lock", [rays(760, RAR["Epic"], 12, 0.28, x=260, y=-80), flash, machine(510, 120, [None or "SparklingDew", "SolarFlare", "NeonWave"],
                                                                                                       stroke=RAR["Epic"], glow_col=RAR["Epic"])] + conf + [hint("EPIC!", "D9B8FF")])


def reveal_card(x=450, y=110):
    return {"name": "Reveal Card", "layout": "V", "gap": 10, "pad": 22, "w": 380, "x": x, "y": y, "radius": 28, "cross": "CENTER", "fill": v("cozy/panel"), **BORDER,
            "effects": SOFT, "children": [
                text("YOU ROLLED", "Caption", "cozy/subtext", name="Caption"),
                {"name": "Orb", "w": 150, "h": 150, "clip": False, "children": [img("auras/SolarFlare", 140, x=5, y=5),
                                                         dict(small_pill("NEW!", "cozy/coral", "New Badge"), x=104, y=4)]},
                ftxt("Solar Flare", 34, "B07CF0", name="Name"),
                {"name": "Tags", "layout": "H", "gap": 8, "cross": "CENTER", "children": [tag("Epic"), small_pill("1/750", "cozy/subtext", "Chance")]},
                text("+35% Luck  •  +10% Sun-Forged", "Small", "cozy/subtext", name="Stats"),
                {"name": "Buttons", "layout": "H", "gap": 8, "w": 336, "children": [btn("Primary", "EQUIP", "Btn Equip", fillW=True), btn("Gem", "ROLL AGAIN", "Btn Roll Again", fillW=True)]},
                btn("Ghost", "CLOSE", "Btn Close", fillW=True)]}


def s_reveal():
    return overlay_screen("Gacha - Reveal", [rays(760, RAR["Epic"], 12, 0.22, x=260, y=-60), inst("g_reveal", 450, 110, "Reveal Card")])


def s_x10():
    rs = [("SparklingDew", "Common"), ("NeonWave", "Rare"), ("SparklingDew", "Common"), ("SparklingDew", "Common"), ("SolarFlare", "Epic"),
          ("SparklingDew", "Common"), ("NeonWave", "Rare"), ("SparklingDew", "Common"), ("AbyssalShadow", "Legendary"), ("SparklingDew", "Common")]
    cells = []
    for i, (a, r) in enumerate(rs):
        best = r == "Legendary"
        cells.append({"name": "Result " + a, "layout": "V", "gap": 4, "pad": 10, "w": 120, "cross": "CENTER", "radius": 20, "fill": "FFFFFF", **BORDER, "clip": False,
                      "effects": [{"color": RAR[r], "a": 0.9, "blur": 22}] if best else [], "children": [
                          img("auras/" + a, 72), tag(r)] + ([dict(small_pill("NEW!", "cozy/coral", "New Badge"), absolute=True, x=66, y=-8)] if r in ("Epic", "Legendary") else [])})
    panel = {"name": "x10 Summary", "layout": "V", "gap": 16, "pad": 24, "w": 760, "x": 260, "y": 80, "radius": 28, "cross": "CENTER", "fill": v("cozy/panel"), **BORDER,
             "effects": SOFT, "children": [
                 {"name": "Head", "layout": "H", "w": 712, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                     text("x10 Results", "Title", name="Title"), {"name": "Best", "layout": "H", "gap": 6, "cross": "CENTER", "children": [
                         text("Best:", "Small", "cozy/subtext", name="Label"), tag("Legendary"), text("Abyssal Shadow", "Heading", "cozy/rarity/legendary", name="Name")]}]},
                 {"name": "Grid", "layout": "H", "wrap": True, "gap": 12, "rowGap": 12, "w": 712, "main": "CENTER", "clip": False, "children": cells},
                 {"name": "Buttons", "layout": "H", "gap": 10, "children": [btn("Primary", "EQUIP BEST", "Btn Equip Best"), btn("Gold", "ROLL x10 AGAIN", "Btn Roll 10"),
                                                                            btn("Ghost", "CLOSE", "Btn Close")]}]}
    return overlay_screen("Gacha - x10 Summary", [rays(800, RAR["Legendary"], 14, 0.18, x=240, y=-100), panel])


SCREENS = [
    (s_altar, "G1 · Aura Altar", "Gacha page (opened from the Auras menu or the altar in the world). Reel machine with a fishing-rod lever, drop rates with owned counts "
     "(unknown auras = ???), Mythic pity, ROLL x1 / x10 (-10%), Skip animation, Auto-roll until Epic+. Right edge stays clear of the leaderboard."),
    (s_spin, "G2 · Spinning", "Screen dims, the reel spins fast with faded copies + speed lines; frame pops per orb. 'tap anywhere to skip'. Code: AuraReel spin tween (Quint out)."),
    (s_close, "G3 · So close...", "Last 30% of the spin: frame tints to the rolled rarity, the rarest aura above the result drifts past the centre line first (arrow)."),
    (s_lock, "G4 · Lock", "Snaps onto the result: white flash, rotating rays + confetti in rarity colour, 'EPIC!'. Legendary+: shake + 0.25s pause first."),
    (s_reveal, "G5 · Reveal", "Card pops in (Back easing): orb, name, rarity, chance, NEW!, stats, EQUIP / ROLL AGAIN / CLOSE."),
    (s_x10, "G6 · x10 Summary (next)", "Planned: x10 roll = 10 quick reels then this grid; best result glows; EQUIP BEST / ROLL x10 AGAIN. Not in code yet."),
]


def build():
    secs = [components_section()]
    for i, (fn, title, note) in enumerate(SCREENS):
        fr = fn()
        fr.update({"x": 60, "y": 110})
        secs.append({"type": "SECTION", "name": title, "fill": "FBF7EF", "w": W + 120, "h": H + 230, "x": 80 + (i % 2) * (W + 200), "y": 820 + (i // 2) * (H + 350),
                     "children": [text(title, "Display", name="Title", x=60, y=30), fr, text(note, "Body", "cozy/subtext", name="Note", w=W, x=60, y=110 + H + 30)]})
    outer = {"type": "SECTION", "name": "Aura Gacha — Reel Slot (FINAL)", "fill": "F3E9D8", "x": 8900, "y": 7400, "pad": 80, "children": secs}
    return {"pageId": PAGE_ID, "replaceName": outer["name"], "tree": outer}  # components first, so instances can reference them


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    json.dump(build(), open(os.path.join(out, "17_gacha_page.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("written")
