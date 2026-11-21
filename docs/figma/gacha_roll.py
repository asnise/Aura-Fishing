"""Roll animation / transition options for the new Gacha page (user, 2026-11-20).
The Gacha page stays a "shop front"; pressing ROLL opens a separate roll window that builds suspense, then the
reveal card. 4 storyboard options, 4 keyframes each (frames are 1280x720 scaled to 560x315). Existing art only:
gacha_bg_*, aura orbs (art/auras), aura illustrations (art/auras_Art), bobber, bite_alert, fx_glow, fx_sparkle.

Run:  python -I docs/figma/gacha_roll.py docs/figma/out
Send: python -I docs/figma/send_blocks.py docs/figma/out/34_gacha_roll_ops.json
Then: python -I tools/art/figma_images.py --root <section id> --size 512
      python -I docs/figma/gacha_redesign.py --bg <section id>
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


g = _load("gacha_redesign", "gacha_redesign.py")
m, es = g.m, g.es
text, t, ftxt, img, PAGE_ID = m.text, g.t, m.ftxt, m.img, m.PAGE_ID
RAR, GOLD, INK = g.RAR, g.GOLD, g.INK
KW, KH = 560, 315
LEG = RAR["Legendary"]


def ell(name, cx, cy, r, hexc, a=1.0, stroke=None):
    d = {"type": "ELLIPSE", "name": name, "w": r * 2, "h": r * 2, "x": cx - r, "y": cy - r, "fill": {"hex": hexc, "opacity": a}}
    if stroke:
        d.update(stroke=stroke, strokeW=2)
    return d


def rays(cx, cy, r, hexc, n=12, a=0.5):
    import math
    lines = "".join(f'<path d="M{cx} {cy}L{cx + r * math.cos(i * 2 * math.pi / n):.1f} {cy + r * math.sin(i * 2 * math.pi / n):.1f}" stroke="#{hexc}" stroke-opacity="{a}" stroke-width="10" stroke-linecap="round"/>' for i in range(n))
    return {"type": "SVG", "name": "Rays", "w": KW, "h": KH, "x": 0, "y": 0, "svg": f'<svg width="{KW}" height="{KH}" viewBox="0 0 {KW} {KH}" xmlns="http://www.w3.org/2000/svg">{lines}</svg>'}


def frame(bg, dim, kids, tint="0B1226"):
    base = [{"type": "RECT", "name": "Bg " + bg, "w": KW, "h": KH, "x": 0, "y": 0, "fill": {"hex": "1B2440"}},
            {"type": "RECT", "name": "Dim", "w": KW, "h": KH, "x": 0, "y": 0, "fill": {"hex": tint, "opacity": dim}}]
    return {"name": "Frame", "w": KW, "h": KH, "radius": 16, "clip": True, "children": base + kids}


def key(label, time, desc, fr):
    return {"name": "Key " + label, "layout": "V", "gap": 6, "w": KW, "children": [
        {"name": "Head", "layout": "H", "gap": 8, "cross": "CENTER", "children": [
            {"name": "Time", "layout": "H", "pad": [3, 10, 4, 10], "radius": 999, "fill": {"hex": INK}, "children": [t(time, "Caption", "FFFFFF", name="T")]},
            text(label, "Heading", name="Label")]},
        fr, text(desc, "Small", "cozy/subtext", name="Desc", w=KW)]}


def small_btn(label, hexc, lip, w):
    return {"name": "Btn " + label, "layout": "H", "w": w, "h": 26, "radius": 9, "main": "CENTER", "cross": "CENTER",
            "fill": {"hex": hexc}, "stroke": {"hex": lip}, "strokeSides": {"b": 3}, "children": [ftxt(label, 11, "FFFFFF", name="L")]}


def reveal_card(aura="AbyssalShadow", name="Abyssal Shadow", rarity="Legendary", new=True):
    """Shared last keyframe: result card over a rarity-coloured burst (illustration when the aura has one)."""
    col = RAR[rarity]
    k = [rays(KW / 2, 120, 260, col, 14, 0.35)] + [ell(f"Glow {i}", KW / 2, 120, r, col, a) for i, (r, a) in enumerate([(120, 0.18), (90, 0.25), (60, 0.35)])]
    art = img(("auras_Art/" if aura in g.ART else "auras/") + aura, 190, x=KW / 2 - 95, y=22)
    card = {"name": "Card", "layout": "V", "gap": 5, "pad": [8, 14, 10, 14], "w": 300, "x": KW / 2 - 150, "y": 196, "radius": 16, "cross": "CENTER",
            "fill": {"hex": "FFF8EC", "opacity": 0.96}, "children": [
                {"name": "Row", "layout": "H", "gap": 6, "cross": "CENTER", "children": [
                    {"name": "Pill", "layout": "H", "pad": [2, 8, 3, 8], "radius": 999, "fill": {"hex": col}, "children": [t(rarity.upper(), "Caption", "FFFFFF", name="R")]},
                    ftxt(name, 18, INK, name="N")] + ([{"name": "New", "layout": "H", "pad": [2, 7, 3, 7], "radius": 999, "fill": {"hex": "FF9E80"}, "children": [t("NEW!", "Caption", "FFFFFF", name="N")]}] if new else [])},
                t("1 in 5,000  |  +50% Luck  |  +3% Void-Touched", "Caption", "7A8A99", name="Stats"),
                {"name": "Buttons", "layout": "H", "gap": 6, "children": [small_btn("EQUIP", "7FD3B0", "4FB58C", 80), small_btn("ROLL AGAIN", "B79CF2", "8C6FD6", 100), small_btn("CLOSE", "C9BBA3", "9AA5B1", 70)]}]}
    return k + [art, card]


def orb(key_, size, cx, cy, **kw):
    return img("auras/" + key_, size, x=cx - size / 2, y=cy - size / 2, **kw)


# ---------------------------------------------------------------- 1 Altar Charge
def c1():
    a = frame("ui/gacha_bg_cosmic", 0.55, [ell("Altar", KW / 2, 250, 110, "B79CF2", 0.25), ell("Altar Top", KW / 2, 248, 80, "FFFFFF", 0.18),
                                            orb("UnknownAura", 110, KW / 2, 170), ell("Shadow", KW / 2, 240, 40, "000000", 0.25)])
    b = frame("ui/gacha_bg_cosmic", 0.65, [ell(f"Ring {i}", KW / 2, 160, r, "FFFFFF", 0, stroke={"hex": c, "opacity": 0.8}) for i, (r, c) in enumerate([(70, "FFFFFF"), (100, "B79CF2"), (130, "F2A93B")])]
               + [orb("UnknownAura", 120, KW / 2, 160), img("auras/fx_sparkle", 70, x=130, y=60), img("auras/fx_sparkle", 50, x=380, y=200), img("auras/fx_sparkle", 40, x=360, y=50)])
    c = frame("ui/gacha_bg_cosmic", 0.4, [rays(KW / 2, 160, 330, LEG, 16, 0.55), img("auras/fx_glow", 300, x=KW / 2 - 150, y=10),
                                          ell("Flash", KW / 2, 160, 80, "FFFFFF", 0.85), ftxt("!", 46, "FFFFFF", name="Bang", x=KW / 2 - 8, y=128, textStroke=LEG, textStrokeW=3)])
    d = frame("ui/gacha_bg_cosmic", 0.55, reveal_card())
    return [key("Drop on the altar", "0.0s", "ROLL dims the shop and drops a mystery orb onto the altar.", a),
            key("Charge", "0.6s", "Rings pulse; their colour climbs white -> lilac -> gold toward the real rarity (the tease).", b),
            key("Burst", "1.6s", "Orb cracks: flash + rays in the rarity colour. Legendary+ holds 0.5s and shakes.", c),
            key("Reveal", "2.2s", "Result card. Tap anywhere during 0-1.6s to skip straight here.", d)]


# ---------------------------------------------------------------- 2 Reel Slot v2
def reel_window(kids, glow=None):
    w = {"name": "Reel", "w": 150, "h": 250, "x": KW / 2 - 75, "y": 32, "radius": 26, "clip": True, "fill": {"hex": "FFFFFF", "opacity": 0.85},
         "stroke": {"hex": glow or GOLD}, "strokeW": 4, "children": kids + [{"type": "RECT", "name": "Centre", "w": 150, "h": 3, "x": 0, "y": 124, "fill": {"hex": "FFFFFF", "opacity": 0.8}}]}
    return w


def c2():
    blur = [orb(k_, 70, 75, 30 + i * 95, opacity=0.55) for i, k_ in enumerate(["SparklingDew", "NeonWave", "SolarFlare"])] + [
        {"type": "RECT", "name": f"Streak {i}", "w": 6, "h": 200, "x": 40 + i * 30, "y": 25, "fill": {"hex": "FFFFFF", "opacity": 0.5}} for i in range(3)]
    a = frame("ui/gacha_bg_celestial", 0.2, [reel_window(blur)], tint="E5DBFA")
    b = frame("ui/gacha_bg_celestial", 0.2, [reel_window([orb("DragonEmperor", 74, 75, 32), orb("AbyssalShadow", 80, 75, 125), orb("SolarFlare", 74, 75, 218)]),
                                             t("near miss!", "Small", "F2668B", name="Hint", x=372, y=40)], tint="E5DBFA")
    c = frame("ui/gacha_bg_celestial", 0.3, [rays(KW / 2, 157, 300, LEG, 14, 0.45), reel_window([orb("AbyssalShadow", 96, 75, 125)], LEG)]
              + [{"type": "RECT", "name": f"Confetti {i}", "w": 8, "h": 14, "x": 60 + i * 47, "y": 20 + (i * 37) % 260, "radius": 2,
                  "fill": {"hex": ["F2B544", "FF9E80", "7FD3B0", "9AD4F5", "B79CF2"][i % 5]}} for i in range(10)], tint="E5DBFA")
    d = frame("ui/gacha_bg_celestial", 0.35, reveal_card(), tint="E5DBFA")
    return [key("Spin", "0.0s", "Today's reel, cleaner: glass window, motion streaks, no cabinet.", a),
            key("Slow + near miss", "1.2s", "Slows down; a rarer orb passes the line first (Dragon Emperor) to tease.", b),
            key("Lock", "2.0s", "Locks on the result: frame turns the rarity colour, rays + confetti.", c),
            key("Reveal", "2.6s", "Same reveal card as option 1.", d)]


# ---------------------------------------------------------------- 3 Deep Cast (fishing)
def water(kids, glow=None):
    w = [{"type": "RECT", "name": "Water", "w": KW, "h": 140, "x": 0, "y": 175, "fill": {"grad": ["9AD4F5", "3A7FB8"], "angle": 90}, "opacity": 0.9}]
    if glow:
        w += [ell("Under Glow", KW / 2, 230, 90, glow, 0.45), ell("Under Glow 2", KW / 2, 230, 55, glow, 0.6)]
    w += [ell(f"Ripple {i}", KW / 2, 190, 30 + i * 22, "FFFFFF", 0, stroke={"hex": "FFFFFF", "opacity": 0.6 - i * 0.15}) for i in range(3)]
    return w + kids


def c3():
    a = frame("ui/gacha_bg_cozy", 0.15, water([img("ui/status/bobber", 60, x=KW / 2 - 30, y=150)]), tint="FFF8EC")
    b = frame("ui/gacha_bg_cozy", 0.15, water([img("ui/status/bobber", 60, x=KW / 2 - 30, y=160), img("ui/status/bite_alert", 70, x=KW / 2 + 10, y=80)], glow=LEG), tint="FFF8EC")
    drops = [ell(f"Drop {i}", 200 + i * 40, 120 + (i % 3) * 30, 6, "FFFFFF", 0.85) for i in range(5)]
    c = frame("ui/gacha_bg_cozy", 0.2, water([rays(KW / 2, 150, 280, LEG, 12, 0.35), orb("AbyssalShadow", 140, KW / 2, 140)] + drops, glow=LEG), tint="FFF8EC")
    d = frame("ui/gacha_bg_cozy", 0.35, reveal_card(), tint="0B1226")
    return [key("Cast", "0.0s", "On-theme: the line lands, the bobber floats in the shop's pond.", a),
            key("Bite!", "0.9s", "\"!\" pops; the water glows the rarity colour from below (the tease).", b),
            key("Splash up", "1.6s", "The aura bursts out of the water with drops + rays.", c),
            key("Reveal", "2.2s", "Same reveal card. x10 = ten bobbers in a row, rarest bites last.", d)]


# ---------------------------------------------------------------- 4 Tide Cards (x10)
def card_back(x, y, rim=None, flipped=None, w=58, h=84):
    if flipped:
        return {"name": "Card " + flipped, "w": w, "h": h, "x": x, "y": y, "radius": 10, "fill": {"hex": "FFF8EC"}, "stroke": {"hex": rim or "E6DCCB"}, "strokeW": 3,
                "children": [img("auras/" + flipped, 46, x=6, y=18)]}
    return {"name": "Card Back", "w": w, "h": h, "x": x, "y": y, "radius": 10, "fill": {"grad": ["8C6FD6", "1B2440"], "angle": 90},
            "stroke": {"hex": rim or "FFFFFF", "opacity": 1 if rim else 0.5}, "strokeW": 3 if rim else 1.5,
            "effects": [{"color": rim, "a": 0.9, "blur": 12, "spread": 1}] if rim else [], "children": [img("ui/status/star_token", 24, x=17, y=30, opacity=0.6)]}


def c4():
    xs = [50 + i * 47 for i in range(10)]
    a = frame("ui/gacha_bg_cosmic", 0.55, [card_back(x, 200 - abs(i - 4.5) * 8) for i, x in enumerate(xs)])
    rims = ["9AA5B1", "9AA5B1", "5CC98A", "9AA5B1", "5AA9F0", "9AA5B1", "B07CF0", "9AA5B1", "5CC98A", LEG]
    b = frame("ui/gacha_bg_cosmic", 0.55, [card_back(30 + i * 52, 116, rims[i]) for i in range(10)])
    flips = ["SparklingDew", "SparklingDew", "NeonWave", "SparklingDew", "TidalBloom", "SparklingDew", "SolarFlare", "SparklingDew", "NeonWave"]
    c = frame("ui/gacha_bg_cosmic", 0.55, [card_back(30 + i * 52, 116, rims[i], flips[i]) for i in range(9)] + [
        rays(30 + 9 * 52 + 29, 158, 160, LEG, 12, 0.45), card_back(30 + 9 * 52, 104, LEG, None, 62, 100)])
    d = frame("ui/gacha_bg_cosmic", 0.55, reveal_card())
    return [key("Deal", "0.0s", "x10: ten cards fan in face down (x1 = one card in the middle).", a),
            key("Rims glow", "0.7s", "Card rims light up in their rarity colours: you see what's coming, not which aura.", b),
            key("Flip", "1.4s", "Cards flip left to right; the rarest stays down, glowing, until tapped.", c),
            key("Reveal", "2.4s", "Tapping it opens the reveal card, then the x10 summary.", d)]


OPTIONS = [("1", "Altar Charge", "Mystery orb charges on an altar, colour tease, burst. Simple and dramatic; works for x1 and x10 (best of 10).", c1),
           ("2", "Reel Slot v2", "Today's reel made cleaner: glass window, near-miss tease, rarity lock. Least new work (AuraReel exists).", c2),
           ("3", "Deep Cast", "Fishing theme: cast, bite \"!\", the water glows the rarity colour, the aura splashes out. Most on-brand.", c3),
           ("4", "Tide Cards", "Card dealing: rarity-coloured rims tease, rarest flips last. Best for x10 (ten at once).", c4)]


def build():
    rows = []
    for i, (n, name, desc, fn) in enumerate(OPTIONS):
        rows.append({"name": f"Option {n}", "layout": "V", "gap": 10, "x": 60, "y": 200 + i * 520, "children": [
            text(f"{n} · {name}", "Title", name="Title"), text(desc, "Small", "cozy/subtext", name="Desc", w=2300),
            {"name": "Keys", "layout": "H", "gap": 24, "children": fn()}]})
    sec = {"type": "SECTION", "name": "Gacha Roll Animation — 4 options", "fill": "F3E9D8", "x": 33000, "y": 6200, "children": [
        text("Gacha Roll Animation — 4 options (pick one)", "Display", name="Title", x=60, y=40),
        text("The Gacha page stays a shop front; ROLL opens this roll window on top (the page is hidden behind it), then the reveal card. "
             "Tap = skip to the reveal. Higher rarity = longer build-up. Same reveal card for every option.", "Body", "cozy/subtext", name="Sub", x=60, y=100, w=2300)] + rows}
    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "34_gacha_roll_ops.json")
    with open(p, "w", encoding="utf-8") as fh:
        json.dump(build(), fh, ensure_ascii=False, indent=1)
    print("wrote", p)
