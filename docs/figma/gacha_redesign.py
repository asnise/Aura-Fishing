"""Gacha (Aura Summon) redesign v2 — 2 candidates (A, D; B and C removed 2026-11-20) from the user's gacha-game references (2026-11-19).
Only existing project art: assets/art/ui/gacha_bg_{cosmic,celestial,cozy}.png, aura orbs, status icons.
Real data: Config/AuraBanners (Altar + Neon Tide event, 5 Gems / pull, x10 = 45 Gems with Rare+ guaranteed,
Legendary pity 100, Mythic hard pity 300, Neon Tide rate-up NeonWave + AbyssalShadow x2, milestones).

  A Banner Rail      left banner cards + hero orb + glass info + big x1 / x10  (ref: 出会い / 救出 screens)
  B Editorial Codex  light editorial layout, text tabs, aura list, huge numbers, key-hint footer (ref: Rosa Zelas / missions)
  C Poster Strips    dark poster, 5 rarity strips with orbs, gold ornaments (ref: Cage of Shadows)
  D Glass Card       pill tabs + lavender glass card + pity note + orb bursting out of the card (ref: 救出)

Run:  python -I docs/figma/gacha_redesign.py docs/figma/out
Send: python -I docs/figma/send_blocks.py docs/figma/out/28_gacha_redesign_ops.json
Then: python -I tools/art/figma_images.py --root <section id>   (orbs / icons)
      python -I docs/figma/gacha_redesign.py --bg <section id>   (full-bleed backgrounds, FILL)
"""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile

_here = os.path.dirname(os.path.abspath(__file__))


def _load(name, file):
    s = importlib.util.spec_from_file_location(name, os.path.join(_here, file))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


m = _load("menus", "cozy_menus_spec.py")
es = _load("economy_screens", "economy_screens.py")
v, text, BORDER, SOFT, PAGE_ID = m.v, m.text, m.BORDER, m.SOFT, m.PAGE_ID
img, ftxt = m.img, m.ftxt
vec, stars = es.vec, es.stars
W, H = 1280, 720
RAR = m.RARITY_HEX
GOLD, CREAM, INK = "F2B544", "FFF8EC", "3D4B5C"


# ---------------------------------------------------------------- primitives
def t(s, style, hexc, **kw):
    d = {"type": "TEXT", "text": s, "textStyle": "Aura Fishing/" + style, "color": hexc}
    d.update(kw)
    return d


def bg(key, dim=0.0, tint="0B1226"):
    kids = [{"type": "RECT", "name": "Bg " + key, "w": W, "h": H, "x": 0, "y": 0, "fill": {"hex": "1B2440"}}]
    if dim:
        kids.append({"type": "RECT", "name": "Dim", "w": W, "h": H, "x": 0, "y": 0, "fill": {"hex": tint, "opacity": dim}})
    return kids


def glow(cx, cy, r, hexc, steps=4, a=0.18):
    out = []
    for i in range(steps):
        rr = r * (1 - i * 0.18)
        out.append({"type": "ELLIPSE", "name": f"Glow {i}", "w": rr * 2, "h": rr * 2, "x": cx - rr, "y": cy - rr, "fill": {"hex": hexc, "opacity": a}})
    return out


def orb(key, size, x, y, **kw):
    """Round orb icon (assets/art/auras, every aura has one). Small UI only."""
    return img("auras/" + key, size, x=x, y=y, **kw)


ART = {"AbyssalShadow", "CelestialLeviathan", "DragonEmperor", "LotusNaga", "NebulaKoi", "SerpentOfTheVoid"}


def art(key, size, x, y, **kw):
    """Big illustration (assets/art/auras_Art, only the 6 auras in ART). A different set from the orbs: never swap one for the other."""
    assert key in ART, key
    return img("auras_Art/" + key, size, x=x, y=y, **kw)


def thumb(key, size, x, y, **kw):
    return art(key, size, x, y, **kw) if key in ART else orb(key, size, x, y, **kw)


def glass(name, w, kids, dark=True, pad=18, gap=10, radius=22, **kw):
    d = {"name": name, "layout": "V", "w": w, "pad": pad, "gap": gap, "radius": radius,
         "fill": {"hex": "0E1630", "opacity": 0.62} if dark else {"hex": "FFFFFF", "opacity": 0.82},
         "stroke": {"hex": "FFFFFF", "opacity": 0.22 if dark else 0.9}, "strokeW": 1.5, "effects": SOFT, "children": kids}
    d.update(kw)
    return d


def pill(label, fill, fg="FFFFFF", icon=None, pad=(4, 12, 5, 12)):
    kids = ([icon] if icon else []) + [t(label, "Caption", fg, name="Label")]
    return {"name": "Pill " + label, "layout": "H", "gap": 5, "pad": list(pad), "radius": 999, "cross": "CENTER", "fill": fill, "children": kids}


def currency(key, value, dark=True):
    return {"name": "Cur " + key.split("/")[-1], "layout": "H", "gap": 8, "pad": [5, 16, 5, 6], "radius": 999, "cross": "CENTER",
            "fill": {"hex": "0E1630", "opacity": 0.55} if dark else {"hex": "FFFFFF", "opacity": 0.85},
            "stroke": {"hex": "FFFFFF", "opacity": 0.25 if dark else 1}, "strokeW": 1.5, "children": [
                img(key, 26), ftxt(value, 17, "FFFFFF" if dark else INK, name="Value")]}  # no "+": tapping the chip opens Top Up


def topbar(title, dark=True):
    back = {"name": "Btn Back", "w": 56, "h": 40, "radius": 14, "fill": {"hex": "0E1630", "opacity": 0.55} if dark else {"hex": "FFFFFF", "opacity": 0.85},
            "stroke": {"hex": "FFFFFF", "opacity": 0.3 if dark else 1}, "strokeW": 1.5, "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [
                {"type": "SVG", "name": "Arrow", "w": 22, "h": 22, "svg": '<svg width="22" height="22" viewBox="0 0 22 22" xmlns="http://www.w3.org/2000/svg">'
                 f'<path d="M14 4 7 11l7 7" stroke="#{"FFFFFF" if dark else INK}" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>'}]}
    return {"name": "Top Bar", "layout": "H", "gap": 12, "w": W - 32, "x": 16, "y": 70, "cross": "CENTER", "children": [
        back, ftxt(title, 26, "FFFFFF" if dark else INK, name="Title", **({"textStroke": INK, "textStrokeW": 2} if dark else {})),
        {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        currency("ui/status/gem", "1,240", dark), currency("ui/status/star_token", "12", dark)]}


def roll_btn(label, cost, style="gold", w=230, h=64, sub=None):
    """Game-standard flat lip button (Gem purple x1 / Gold x10, 5px darker lip, radius 18), price made loud:
    label left, then a price pill in the lip colour with a 26px Gem and a 20px number. x10 carries a RARE+ tag
    on its top-right corner so the price pill stays clean."""
    ten = "10" in label
    tone = "gold" if ten else "gem"
    price = {"name": "Price", "layout": "H", "gap": 4, "pad": [3, 12, 3, 4], "radius": 999, "cross": "CENTER", "fill": v("cozy/" + tone + "-lip"),
             "children": [img("ui/status/gem", 26), ftxt(str(cost), 20, "FFFFFF", name="Value")]}
    kids = [ftxt(label.replace("Roll", "ROLL"), 20, "FFFFFF", name="Label"), {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, price]
    if ten:
        kids.append(dict(m.small_pill("RARE+", "cozy/coral", "Guarantee"), absolute=True, x=w - 62, y=-10))
    b = es.lip_btn("Btn " + label, kids, tone, w, pad=(0, 8, 5, 18))
    b.update(h=60, radius=18, cross="CENTER", gap=8, clip=False)
    return b


def pity_bar(label, cur, total, w, hexc, dark=True):
    frac = cur / total
    return {"name": "Pity " + label, "layout": "V", "gap": 4, "w": w, "children": [
        {"name": "Row", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "children": [
            t(label, "Caption", "FFFFFF" if dark else "7A8A99", name="Label"), ftxt(f"{cur} / {total}", 14, "FFFFFF" if dark else INK, name="Value")]},
        {"name": "Track", "w": w, "h": 8, "radius": 999, "fill": {"hex": "FFFFFF" if dark else "E6DCCB", "opacity": 0.22 if dark else 1}, "children": [
            {"name": "Fill", "w": max(8, round(w * frac)), "h": 8, "x": 0, "y": 0, "radius": 999, "fill": {"grad": [hexc, "FFFFFF"], "angle": 0}}]}]}


def screen(name, kids):
    return {"name": name, "w": W, "h": H, "clip": True, "children": kids + [m.roblox_overlay()]}


# ---------------------------------------------------------------- pay-with toggle (user, 2026-11-20): roll with Gems or Star Tokens
def currency_toggle(x, y, on="Gems", dark=True):
    """Segmented toggle above the roll buttons. Selected = coral like every other selected tab; other = clear.
    Added as a new node only (the screens around it are hand-edited)."""
    seg = lambda label, key: {"name": "Opt " + label, "layout": "H", "gap": 5, "w": 86, "h": 28, "radius": 999, "main": "CENTER", "cross": "CENTER",
                              "fill": {"hex": "FF9E80"} if label == on else {"hex": "FFFFFF", "opacity": 0},
                              "children": [img(key, 20), ftxt(label, 14, "FFFFFF" if (label == on or dark) else INK, name="Label")]}
    return {"name": "Toggle Pay With", "layout": "H", "gap": 0, "pad": 3, "radius": 999, "x": x, "y": y,
            "fill": {"hex": "0E1630", "opacity": 0.6} if dark else {"hex": "FFFFFF", "opacity": 0.9},
            "stroke": {"hex": "FFFFFF", "opacity": 0.3 if dark else 1}, "strokeW": 1.5, "children": [
                seg("Gems", "ui/status/gem"), seg("Tokens", "ui/status/star_token")]}


# ---------------------------------------------------------------- A · Banner Rail
BANNERS = [("NeonTide", "Neon Tide", "EVENT", "11d left", "AbyssalShadow", "9C7BE6"),
           ("Altar", "Aura Altar", "STANDARD", "Always", "CelestialLeviathan", "6BB3DE"),
           ("Starter", "Starter Wish", "ONCE", "10 pulls", "SolarFlare", "F2B544")]


def banner_card(key, name, kind, time, orb_key, hexc, on=False):
    return {"name": "Banner " + name, "w": 232, "h": 92, "radius": 18, "clip": True,
            "fill": {"grad": [hexc, "1B2440"], "angle": 0}, "stroke": {"hex": "FFFFFF", "opacity": 1 if on else 0.25}, "strokeW": 3 if on else 1.5,
            "effects": [{"color": hexc, "a": 0.8, "blur": 18, "spread": 1}] if on else [], "opacity": 1 if on else 0.82, "children": [
                orb(orb_key, 110, 128, -8),
                dict(pill(kind, {"hex": "FFFFFF", "opacity": 0.92}, hexc if hexc != GOLD else "B8862A"), x=12, y=12),
                ftxt(name, 20, "FFFFFF", name="Name", x=12, y=40, textStroke=INK, textStrokeW=2),
                dict(t(time, "Caption", "FFFFFF", name="Time"), x=12, y=66)]}


def concept_a():
    kids = bg("ui/gacha_bg_cosmic", 0.35)
    kids += glow(880, 360, 250, "B79CF2", 4, 0.13) + [art("AbyssalShadow", 500, 630, 100)]
    rail = {"name": "Banner Rail", "layout": "V", "gap": 12, "x": 16, "y": 130, "children": [
        banner_card(*b, on=i == 0) for i, b in enumerate(BANNERS)] + [
        {"name": "Btn History", "layout": "H", "gap": 6, "pad": [8, 16, 8, 16], "radius": 999, "fill": {"hex": "0E1630", "opacity": 0.6},
         "stroke": {"hex": "FFFFFF", "opacity": 0.25}, "strokeW": 1.5, "children": [t("History Log", "Small", "FFFFFF", name="Label")]}]}
    feat = lambda k, r: {"name": "Feat " + k, "layout": "V", "gap": 4, "cross": "CENTER", "children": [
        {"name": "Tile", "w": 64, "h": 64, "radius": 16, "fill": {"hex": "FFFFFF", "opacity": 0.92}, "layout": "H", "main": "CENTER", "cross": "CENTER",
         "children": [img("auras/" + k, 56)]}, pill(r.upper(), {"hex": RAR[r]})]}
    info = glass("Banner Info", 330, [
        pill("RATE UP x2", {"hex": "9C7BE6"}),
        ftxt("Neon Tide", 34, "FFFFFF", name="Title", textStroke=INK, textStrokeW=2),
        stars(5, 16),
        t("Abyssal Shadow and Neon Wave are twice as likely. Every x10 has a Rare or better.", "Small", "DCE3F0", name="Desc", w=294),
        {"name": "Featured", "layout": "H", "gap": 12, "children": [feat("AbyssalShadow", "Legendary"), feat("NeonWave", "Uncommon")]},
        t("Ends Nov 30  |  11d 6h", "Caption", "B7C2D6", name="Time")], x=270, y=130)
    note = {"name": "Pity Note", "layout": "H", "gap": 10, "pad": [10, 18, 10, 14], "radius": 999, "x": 270, "y": 560, "cross": "CENTER",
            "fill": {"hex": "0E1630", "opacity": 0.65}, "stroke": {"hex": "B79CF2", "opacity": 0.8}, "strokeW": 1.5, "children": [
                img("ui/status/star_token", 22), t("62 more pulls to a guaranteed", "Small", "FFFFFF", name="A"), t("Legendary", "Small", "F2A93B", name="B")]}
    name_tag = {"name": "Hero Name", "layout": "V", "gap": 2, "x": 720, "y": 508, "children": [
        pill("LEGENDARY", {"hex": RAR["Legendary"]}), ftxt("Abyssal Shadow", 30, "FFFFFF", name="Name", textStroke=INK, textStrokeW=2),
        t("1 in 5,000  |  +50% Luck  |  +3% Void-Touched", "Small", "DCE3F0", name="Stats")]}
    ctas = {"name": "Roll Buttons", "layout": "H", "gap": 14, "x": 760, "y": 622, "clip": False, "children": [
        roll_btn("Roll x1", 5, "lav", w=200), roll_btn("Roll x10", 45, "gold", w=240, sub="Rare+ guaranteed")]}
    rates = {"name": "Btn Rates", "layout": "H", "gap": 6, "pad": [7, 14, 7, 10], "radius": 999, "x": 1150, "y": 130, "cross": "CENTER",
             "fill": {"hex": "0E1630", "opacity": 0.6}, "stroke": {"hex": "FFFFFF", "opacity": 0.25}, "strokeW": 1.5,
             "children": [vec("icon_info", "FFFFFF", 16), t("Rates", "Small", "FFFFFF", name="Label")]}
    return screen("A · Banner Rail", kids + [topbar("Aura Summon"), rail, info, note, name_tag, ctas, rates])


# ---------------------------------------------------------------- B · Editorial Codex
LINEUP = [("SparklingDew", "Sparkling Dew", "Common"), ("NeonWave", "Neon Wave", "Uncommon"), ("TidalBloom", "Tidal Bloom", "Rare"),
          ("SolarFlare", "Solar Flare", "Epic"), ("AbyssalShadow", "Abyssal Shadow", "Legendary"), ("DragonEmperor", "Dragon Emperor", "Mythic"),
          ("SerpentOfTheVoid", "Serpent of the Void", "Mythic")]


def concept_b():
    kids = bg("ui/gacha_bg_cozy", 0.82, "FFF8EC")
    kids += [art("DragonEmperor", 260, 560, 60, opacity=0.14)]
    kids += glow(640, 380, 240, "B79CF2", 3, 0.12) + [art("AbyssalShadow", 470, 400, 140)]
    tabs = {"name": "Tabs", "layout": "H", "gap": 0, "x": 40, "y": 76, "radius": 12, "fill": "FFFFFF", **BORDER, "children": []}
    for i, lab in enumerate(["ALTAR", "NEON TIDE", "HISTORY", "RATES"]):
        on = lab == "NEON TIDE"
        tabs["children"].append({"name": "Tab " + lab, "layout": "H", "pad": [8, 18, 8, 18], "radius": 10, "fill": {"hex": INK} if on else {"hex": "FFFFFF", "opacity": 0},
                                 "children": [ftxt(lab, 15, "FFFFFF" if on else "7A8A99", name="Label")]})
    sub = {"name": "Sub Tabs", "layout": "H", "gap": 18, "x": 44, "y": 124, "children": [
        t(s, "Caption", INK if s == "LEGENDARY+" else "9AA5B1", name=s) for s in ["ALL", "COMMON", "RARE", "EPIC", "LEGENDARY+"]]}
    lst = {"name": "Aura List", "layout": "V", "gap": 8, "x": 44, "y": 170, "children": []}
    for k, n, r in LINEUP:
        on = k == "AbyssalShadow"
        lst["children"].append({"name": "Row " + n, "layout": "H", "gap": 8, "cross": "CENTER", "children": (
            [{"name": "Mark", "w": 4, "h": 22, "radius": 2, "fill": {"hex": INK}}] if on else []) + [
            img("auras/" + k, 26 if on else 22, opacity=1 if on else 0.6), ftxt(n, 22 if on else 19, INK if on else "9AA5B1", name="Name")] + (
            [pill("RATE UP", {"hex": "9C7BE6"})] if k in ("NeonWave", "AbyssalShadow") else [])})
    bio = {"name": "Lore", "layout": "V", "gap": 6, "w": 360, "x": 40, "y": 470, "children": [
        {"name": "Head", "layout": "H", "fillW": True, "pad": [4, 10, 4, 10], "radius": 6, "fill": {"hex": "E6DCCB"}, "main": "MAX",
         "children": [t("Lore", "Caption", "7A8A99", name="L")]},
        t("A shadow that swims under the Neon Tide. Anglers who catch its glow pull up Void-Touched fish for days.", "Small", INK, name="Body", w=350)]}
    right = {"name": "Detail", "layout": "V", "gap": 10, "w": 380, "x": 880, "y": 130, "children": [
        ftxt("Abyssal Shadow", 40, INK, name="Name"),
        {"name": "Big", "layout": "H", "gap": 14, "cross": "CENTER", "children": [
            {"name": "Rarity", "layout": "V", "gap": 0, "children": [t("RARITY", "Caption", "9AA5B1", name="L"), ftxt("1/5,000", 46, INK, name="V")]},
            {"name": "Side", "layout": "V", "gap": 4, "children": [pill("LEGENDARY", {"hex": RAR["Legendary"]}), stars(3, 14)]}]},
        pity_bar("Legendary pity", 38, 100, 300, "F2A93B", dark=False),
        pity_bar("Mythic pity", 38, 300, 300, "F2668B", dark=False),
        {"name": "Status Head", "layout": "H", "w": 380, "pad": [4, 10, 4, 10], "radius": 6, "fill": {"hex": "E6DCCB"}, "children": [t("Bonus", "Caption", "7A8A99", name="L")]},
        {"name": "Stats", "layout": "H", "wrap": True, "gap": 8, "rowGap": 8, "w": 380, "children": [
            {"name": "S " + a, "layout": "H", "w": 180, "pad": [8, 12, 8, 12], "radius": 10, "fill": {"hex": INK}, "main": "SPACE_BETWEEN",
             "children": [t(a, "Small", "FFFFFF", name="K"), ftxt(b, 17, "FFFFFF", name="V")]} for a, b in [("Luck", "+50%"), ("Auto Mult", "+0.2"), ("Void-Touched", "+3%"), ("Stars", "3 / 5")]]},
        {"name": "Rolls", "layout": "H", "gap": 10, "children": [roll_btn("Roll x1", 5, "sky", w=170, h=56), roll_btn("Roll x10", 45, "gold", w=200, h=56)]}]}
    foot = {"name": "Key Bar", "w": W, "h": 36, "x": 0, "y": H - 36, "fill": {"hex": "1B2233"}, "layout": "H", "pad": [0, 24, 0, 24], "cross": "CENTER", "gap": 18, "children": [
        t("Neon Tide  |  rate-up Abyssal Shadow, Neon Wave  |  ends Nov 30", "Small", "FFFFFF", name="Hint"), {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        t("BACK  [B]", "Caption", "FFFFFF", name="K1"), t("ROLL x1  [R]", "Caption", "FFFFFF", name="K2"), t("ROLL x10  [T]", "Caption", "FFFFFF", name="K3")]}
    top = topbar("Aura Codex", dark=False)
    top["y"] = 70
    top["children"] = [c for c in top["children"] if c.get("name") not in ("Btn Back", "Title")]
    top["x"], top["w"] = 760, 504
    return screen("B · Editorial Codex", kids + [tabs, sub, lst, bio, right, top, foot])


# ---------------------------------------------------------------- C · Poster Strips
STRIPS = [("NeonWave", "Uncommon", "Neon Wave"), ("SolarFlare", "Epic", "Solar Flare"), ("AbyssalShadow", "Legendary", "Abyssal Shadow"),
          ("DragonEmperor", "Mythic", "Dragon Emperor"), ("SerpentOfTheVoid", "Mythic", "Serpent of the Void")]


def ornament_line(w, x, y):
    return {"type": "SVG", "name": "Ornament", "w": w, "h": 14, "x": x, "y": y, "svg":
            f'<svg width="{w}" height="14" viewBox="0 0 {w} 14" xmlns="http://www.w3.org/2000/svg"><path d="M0 7H{w / 2 - 14}M{w / 2 + 14} 7H{w}" stroke="#{GOLD}" stroke-width="1.5"/>'
            f'<path d="M{w / 2} 1l6 6-6 6-6-6z" fill="none" stroke="#{GOLD}" stroke-width="1.5"/><circle cx="{w / 2}" cy="7" r="2" fill="#{GOLD}"/></svg>'}


def concept_c():
    kids = [{"type": "RECT", "name": "Ink", "w": W, "h": H, "x": 0, "y": 0, "fill": {"hex": "171A22"}}]
    kids += [{"type": "RECT", "name": "Bg ui/gacha_bg_cosmic", "w": W, "h": H, "x": 0, "y": 0, "fill": {"hex": "1B2440"}, "opacity": 0.22}]
    for i in range(9):  # hanging gold drops
        x = 140 + i * 125
        kids.append({"type": "SVG", "name": f"Drop {i}", "w": 10, "h": 60, "x": x, "y": 58, "svg":
                     f'<svg width="10" height="60" viewBox="0 0 10 60" xmlns="http://www.w3.org/2000/svg"><path d="M5 0V{30 + (i % 3) * 8}" stroke="#{GOLD}" stroke-width="1" stroke-dasharray="2 3"/>'
                     f'<path d="M5 {32 + (i % 3) * 8}c3 5 4 8 0 12-4-4-3-7 0-12z" fill="#{GOLD}"/></svg>'})
    sw, gap = 168, 10
    x0 = (W - (5 * sw + 4 * gap)) // 2
    for i, (k, r, n) in enumerate(STRIPS):
        col = RAR[r]
        big = k == "AbyssalShadow"
        kids.append({"name": "Strip " + n, "w": sw, "h": 380, "x": x0 + i * (sw + gap), "y": 128 - (14 if big else 0), "radius": 6, "clip": True,
                     "fill": {"grad": [col, "171A22"], "angle": 90}, "stroke": {"hex": GOLD, "opacity": 1 if big else 0.55}, "strokeW": 2 if big else 1, "children": [
                         {"type": "SVG", "name": "Diamonds", "w": sw, "h": 380, "x": 0, "y": 0, "opacity": 0.18, "svg":
                          f'<svg width="{sw}" height="380" viewBox="0 0 {sw} 380" xmlns="http://www.w3.org/2000/svg"><defs><pattern id="d{i}" width="28" height="28" patternUnits="userSpaceOnUse">'
                          '<path d="M14 0 28 14 14 28 0 14z" fill="none" stroke="#FFFFFF" stroke-width="1"/></pattern></defs>'
                          f'<rect width="{sw}" height="380" fill="url(#d{i})"/></svg>'},
                         orb(k, 190, (sw - 190) // 2, 70),
                         ftxt(n, 16, "FFFFFF", name="Name", x=0, y=330, w=sw, align="CENTER", textStroke="171A22", textStrokeW=2),
                         dict(pill(r.upper(), {"hex": "171A22", "opacity": 0.6}, col), x=(sw - 96) // 2, y=354)]})
    kids += [ornament_line(760, 260, 524),
             ftxt("NEON TIDE", 64, "F7E3B5", name="Title", x=0, y=536, w=W, align="CENTER", textStroke="8A6A2A", textStrokeW=2),
             t("-  RATE UP: ABYSSAL SHADOW  &  NEON WAVE  -", "Small", GOLD, name="Sub", x=0, y=612, w=W, align="CENTER"),
             {"name": "Bottom", "layout": "H", "gap": 18, "x": 180, "y": 640, "cross": "CENTER", "children": [
                 pity_bar("Legendary in", 38, 100, 220, GOLD), roll_btn("Roll x1", 5, "coral", w=190, h=58), roll_btn("Roll x10", 45, "gold", w=220, h=58, sub="Rare+ guaranteed"),
                 t("Ends Nov 30", "Caption", "B7A27A", name="Ends")]}]
    top = topbar("Aura Summon")
    return screen("C · Poster Strips", kids + [top])


# ---------------------------------------------------------------- D · Glass Card
def tab_pill(name, orb_key, on=False):
    return {"name": "Tab " + name, "w": 168, "h": 52, "radius": 999, "clip": True, "fill": {"grad": ["FFFFFF", "E5DBFA"], "angle": 0} if on else {"hex": "FFFFFF", "opacity": 0.7},
            "stroke": {"hex": "9C7BE6" if on else "FFFFFF", "opacity": 1}, "strokeW": 2.5 if on else 1.5, "children": [
                thumb(orb_key, 72, 98, -10), t(name, "Small", "4A3A7A" if on else "7A8A99", name="Label", x=16, y=16)]}


def concept_d():
    kids = bg("ui/gacha_bg_celestial", 0.12, "E5DBFA")
    kids += [{"type": "RECT", "name": "Floor", "w": W, "h": 120, "x": 0, "y": 600, "fill": {"grad": ["FFFFFF", "E5DBFA"], "angle": 90}, "opacity": 0.75}]
    tabs = {"name": "Banner Rail", "layout": "V", "gap": 12, "x": 16, "y": 130, "children": [banner_card(*b, on=k == 0) for k, b in enumerate(BANNERS)]}
    kids += glow(990, 330, 220, "FFFFFF", 3, 0.25) + [art("AbyssalShadow", 480, 760, 90)]
    card = {"name": "Info Card", "layout": "V", "gap": 10, "pad": [5, 10, 5, 10], "w": 450, "x": 264, "y": 130, "radius": 26, "clip": False,
            "fill": {"hex": "FFFFFF", "opacity": 0.86}, "stroke": {"hex": "FFFFFF"}, "strokeW": 2, "effects": SOFT, "children": [
                {"name": "Ribbon", "layout": "H", "pad": [5, 14, 6, 14], "radius": 999, "fill": {"grad": ["B79CF2", "8C6FD6"], "angle": 0},
                 "children": [t("Event Banner  |  Rate Up", "Caption", "FFFFFF", name="L")]},
                {"name": "Pad", "layout": "V", "gap": 8, "pad": [2, 0, 0, 0], "fillW": True, "children": [
                    ftxt("Abyssal Shadow Surge", 30, "4A3A7A", name="Title"),
                    stars(5, 18),
                    {"name": "Timer", "layout": "H", "gap": 6, "cross": "CENTER", "children": [vec("icon_timer", "8C6FD6", 16), t("11d 6h left", "Small", "8C6FD6", name="T")]},
                    t("Abyssal Shadow and Neon Wave are 2x more likely. Every x10 guarantees a Rare or better.", "Small", INK, name="Desc", w=400),
                    {"name": "Featured", "layout": "H", "gap": 10, "children": [
                        {"name": "F " + k, "w": 70, "h": 70, "radius": 16, "fill": {"grad": [RAR[r], "FFFFFF"], "angle": 90}, "stroke": {"hex": "FFFFFF"}, "strokeW": 2,
                         "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [img("auras/" + k, 60)]} for k, r in [("AbyssalShadow", "Legendary"), ("NeonWave", "Uncommon")]]},
                    {"name": "Pity Note", "layout": "H", "gap": 8, "pad": [10, 14, 10, 14], "radius": 14, "fillW": True, "cross": "CENTER",
                     "fill": {"grad": ["E5DBFA", "FFFFFF"], "angle": 0}, "children": [
                         img("ui/status/star_token", 22), t("62 more pulls and a Legendary is guaranteed", "Small", "4A3A7A", name="T")]}]}]}
    name_plate = {"name": "Name Plate", "layout": "H", "gap": 10, "pad": [8, 18, 8, 12], "radius": 999, "x": 820, "y": 520, "cross": "CENTER",
                  "fill": {"hex": "1B2233", "opacity": 0.88}, "children": [pill("LEGENDARY", {"hex": RAR["Legendary"]}), ftxt("Abyssal Shadow", 20, "FFFFFF", name="N"), stars(3, 12)]}
    left_btns = {"name": "Small Buttons", "layout": "H", "gap": 10, "x": 16, "y": 640, "children": [
        {"name": "Btn " + s, "layout": "H", "gap": 6, "pad": [9, 16, 9, 12], "radius": 999, "cross": "CENTER", "fill": {"hex": "FFFFFF", "opacity": 0.9},
         "stroke": {"hex": "E6DCCB"}, "strokeW": 1.5, "children": [img(k, 20), t(s, "Small", INK, name="L")]}
        for s, k in [("Shop", "ui/icons/shop"), ("Rates", "ui/status/xp_star"), ("History", "ui/icons/quests")]]}
    ctas = {"name": "Roll Buttons", "layout": "H", "gap": 14, "x": 790, "y": 632, "clip": False, "children": [
        roll_btn("Roll x1", 5, "lav", w=200, h=60), roll_btn("Roll x10", 45, "gold", w=250, h=60, sub="Rare+ guaranteed")]}
    return screen("D · Glass Card", kids + [topbar("Aura Summon"), tabs, card, name_plate, left_btns, ctas])


# ---------------------------------------------------------------- E1 parts for D (user, 2026-11-20): Mythic pity, Milestones, Skip / Auto
def _box(name, x, y, w, kids):
    return {"name": name, "layout": "V", "gap": 6, "pad": [9, 12, 10, 12], "w": w, "x": x, "y": y, "radius": 16,
            "fill": {"hex": "FFFFFF", "opacity": 0.9}, "stroke": {"hex": "E6DCCB"}, "strokeW": 1.5, "children": kids}


def _bar(w, frac, grad):
    return {"name": "Bar", "w": w, "h": 8, "radius": 999, "fill": {"hex": "E6DCCB"}, "clip": True, "children": [
        {"name": "Fill", "w": max(8, round(w * frac)), "h": 8, "x": 0, "y": 0, "radius": 999, "fill": {"grad": grad, "angle": 0}}]}


def _check(label, on=False):
    box = {"name": "Box", "w": 26, "h": 26, "radius": 8, "fill": {"hex": "7FD3B0"} if on else {"hex": "FFFFFF"},
           "stroke": {"hex": "4FB58C" if on else "E6DCCB"}, "strokeW": 2}
    return {"name": "Check " + label, "layout": "H", "gap": 8, "cross": "CENTER", "children": [box, t(label, "Small", INK, name="Label")]}


def e1_parts():
    w = 219
    pity = _box("Pity Mythic", 264, 456, w, [
        {"name": "Row", "layout": "H", "w": w - 24, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
            t("Mythic guaranteed in", "Caption", "7A8A99", name="Label"), ftxt("262 rolls", 14, RAR["Mythic"], name="Value")]},
        _bar(w - 24, 38 / 300, ["F2A93B", "F2668B"])])
    ms = _box("Milestones", 264 + w + 12, 456, w, [
        {"name": "Row", "layout": "H", "w": w - 24, "gap": 6, "cross": "CENTER", "children": [
            t("Milestones", "Small", "7A8A99", name="Label"), ftxt("37/400", 15, "8C6FD6", name="Value"), {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
            {"name": "Btn View", "layout": "H", "pad": [3, 10, 4, 10], "radius": 999, "fill": {"hex": "6BB3DE"}, "clip": False, "children": [
                t("View", "Caption", "FFFFFF", name="Label"),
                dict({"name": "Dot", "w": 14, "h": 14, "radius": 999, "fill": {"hex": "F07A7A"}, "stroke": {"hex": "FFFFFF"}, "strokeW": 1.5,
                      "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [ftxt("1", 9, "FFFFFF", name="N")]}, absolute=True, x=40, y=-7)]}]},
        _bar(w - 24, 37 / 400, ["B79CF2", "8C6FD6"])])
    opts = {"name": "Options", "layout": "H", "gap": 18, "pad": [6, 14, 6, 8], "radius": 999, "x": 264, "y": 524, "cross": "CENTER",
            "fill": {"hex": "FFFFFF", "opacity": 0.9}, "stroke": {"hex": "E6DCCB"}, "strokeW": 1.5,
            "children": [_check("Skip animation"), _check("Auto-roll until Epic+")]}
    return [pity, ms, opts]


CONCEPTS = [("A", "Banner Rail", "Left banner cards with orb thumbnails, glass info card, aura illustration on the right, big x1 / x10 (ref: 出会い / 救出).", concept_a),
            ("D", "Glass Card", "A-style banner cards (orbs), lavender glass card with pity note, aura illustration on the right (ref: 救出).", concept_d)]


def build():
    kids = []
    for i, (k, n, desc, fn) in enumerate(CONCEPTS):
        x, y = 60 + (i % 2) * 1380, 200 + (i // 2) * 860
        kids.append({"name": f"Concept {k}", "layout": "V", "gap": 8, "x": x, "y": y, "children": [
            text(f"{k} · {n}", "Title", name="Title"), text(desc, "Small", "cozy/subtext", name="Desc", w=1280), fn()]})
    sec = {"type": "SECTION", "name": "Gacha Redesign v2 — A / D", "fill": "F3E9D8", "x": 33000, "y": 2400, "children": [
        text("Gacha Redesign v2 — Aura Summon candidates A Banner Rail / D Glass Card", "Display", name="Title", x=60, y=40),
        text("1280x720. Small icons = aura orbs (art/auras); heroes and decoration = aura illustrations (art/auras_Art, 6 auras). Backgrounds gacha_bg_cosmic / cozy / celestial. "
             "Real numbers: 5 Gems a pull, x10 = 45 with Rare+ guaranteed, Legendary pity 100, Mythic 300, Neon Tide rate-up.",
             "Body", "cozy/subtext", name="Sub", x=60, y=100, w=2600)] + kids}
    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


# ---------------------------------------------------------------- background fill (FILL, 1280px)
def fill_backgrounds(root):
    import base64, io
    from PIL import Image
    root_dir = os.path.dirname(os.path.dirname(_here))
    run = os.path.join(root_dir, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")

    def call(cmd, params):
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
            json.dump(params, f)
        r = subprocess.run(["node", run, "--channel=aura-fishing", cmd, f.name, "--timeout=200"], capture_output=True, text=True, encoding="utf-8")
        os.unlink(f.name)
        if r.returncode:
            raise SystemExit(r.stderr or r.stdout)
        return json.loads(r.stdout)

    tree = call("get_node_info", {"nodeId": root})
    hits = []

    def walk(n):
        if n.get("name", "").startswith("Bg "):
            hits.append((n["id"], n["name"][3:]))
        for c in n.get("children", []):
            walk(c)
    walk(tree)
    cache = {}
    for nid, key in hits:
        if key not in cache:
            im = Image.open(os.path.join(root_dir, "assets", "art", key + ".png")).convert("RGB")
            im.thumbnail((1280, 1280))
            buf = io.BytesIO()
            im.save(buf, "JPEG", quality=86)
            cache[key] = base64.b64encode(buf.getvalue()).decode()
        call("set_image_fill", {"nodeId": nid, "imageBase64": cache[key], "scaleMode": "FILL"})
        print("bg", nid, key)


if __name__ == "__main__":
    if "--bg" in sys.argv:
        fill_backgrounds(sys.argv[sys.argv.index("--bg") + 1])
        sys.exit(0)
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "28_gacha_redesign_ops.json")
    with open(p, "w", encoding="utf-8") as fh:
        json.dump(build(), fh, ensure_ascii=False, indent=1)
    print("wrote", p)
