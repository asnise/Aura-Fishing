"""HUD Stats (top-left player card) — 6 options as ONE component set, preview board, and screen swaps.

Step 1: python -I docs/figma/hud_stats.py docs/figma/out component
        build_tree out/13_hud_stats_component.json  -> note refs.hudstats (component set id)
Step 2: python -I docs/figma/hud_stats.py docs/figma/out board <setId> [variantName]
        build_tree out/14_hud_stats_board.json, and out/15_swap_*.json (one per screen)
Then:   python -I tools/art/figma_images.py --root <componentGroupId> --root <boardId>
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
img, text, v, BORDER, SOFT, ftxt, chip, progress, small_pill, PAGE_ID = (m.img, m.text, m.v, m.BORDER, m.SOFT, m.ftxt, m.chip, m.progress,
                                                                         m.small_pill, m.PAGE_ID)

COMPONENTS_BOARD = "3487:4280"
SCREENS = {"HUD": "3491:7693", "Reel": "3491:7771", "MainMenu": "3491:8201", "Inventory": "3491:8287"}


def arc(size, r, a0, a1, color, w):
    rad = lambda a: math.radians(a - 90)
    x0, y0 = size / 2 + r * math.cos(rad(a0)), size / 2 + r * math.sin(rad(a0))
    x1, y1 = size / 2 + r * math.cos(rad(a1)), size / 2 + r * math.sin(rad(a1))
    large = 1 if (a1 - a0) > 180 else 0
    return f'<path d="M{x0:.1f} {y0:.1f} A{r} {r} 0 {large} 1 {x1:.1f} {y1:.1f}" stroke="#{color}" stroke-width="{w}" stroke-linecap="round" fill="none"/>'


def svg(size, body, name):
    return {"type": "SVG", "name": name, "w": size, "h": size,
            "svg": f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" xmlns="http://www.w3.org/2000/svg">{body}</svg>'}


def mini_bar(w, h, frac, track=None, fill="7FD3B0", name="XP Bar"):
    return {"name": name, "w": w, "h": h, "radius": 999, "clip": True, "fill": track or v("cozy/track"), "children": [
        {"type": "RECT", "name": "Fill", "w": round(w * frac), "h": h, "x": 0, "y": 0, "radius": 999, "fill": fill}]}


def plus_btn(color):
    return {"name": "Btn Add", "w": 22, "h": 22, "radius": 999, "fill": color, "layout": "H", "main": "CENTER", "cross": "CENTER",
            "children": [ftxt("+", 16, "FFFFFF", name="Plus")]}


def avatar(size, ring="FFFFFF"):
    return {"name": "Avatar", "w": size, "h": size, "radius": 999, "clip": True, "fill": v("cozy/sky"), "stroke": ring, "strokeW": 3,
            "children": [img("npc/Pip_happy", round(size * 1.2), x=-round(size * 0.1), y=-round(size * 0.02))]}


XP = 340 / 900


def comp(name, body):
    body.update({"type": "COMPONENT", "name": "Style=" + name})
    return body


def var_a():  # Classic Card (polished current)
    return comp("A Classic Card", {"layout": "V", "gap": 8, "pad": 14, "w": 270, "radius": 18, "fill": v("cozy/panel"), **BORDER, "children": [
        {"name": "Top", "layout": "H", "gap": 10, "cross": "CENTER", "children": [avatar(40),
            {"name": "Level", "layout": "V", "gap": 0, "children": [text("Lv. 12", "Heading", name="Level"), text("340 / 900 XP", "Caption", "cozy/subtext", name="XP Text")]}]},
        mini_bar(242, 10, XP),
        {"name": "Currencies", "layout": "H", "gap": 8, "children": [chip("Coins", "12,450"), chip("Gems", "320")]}]})


def var_b():  # Level Badge + pills
    ring = svg(84, arc(84, 38, 0, 359.9, "FFFFFF", 8) + arc(84, 38, 0, 360 * XP, "7FD3B0", 8), "XP Ring")
    badge = {"name": "Level Badge", "w": 84, "h": 84, "children": [dict(ring, x=0, y=0),
        {"name": "Coin", "w": 60, "h": 60, "x": 12, "y": 12, "radius": 999, "fill": {"grad": ["FFD45C", "F2B544"], "angle": 90}, "stroke": "FFFFFF", "strokeW": 3,
         "layout": "V", "main": "CENTER", "cross": "CENTER", "children": [text("LV", "Caption", "cozy/on-accent", name="LV"), ftxt("12", 26, "FFFFFF", name="Level")]}]}
    aura = {"name": "Aura", "layout": "H", "gap": 6, "pad": [3, 10, 3, 4], "radius": 999, "cross": "CENTER", "fill": v("cozy/panel"), **BORDER,
            "children": [img("auras/NeonWave", 22), text("+15% Luck", "Small", "cozy/rarity/rare", name="Luck")]}
    return comp("B Level Badge", {"layout": "H", "gap": 10, "cross": "CENTER", "children": [badge,
        {"name": "Pills", "layout": "V", "gap": 6, "children": [chip("Coins", "12,450"), chip("Gems", "320"), aura]}]})


def var_c():  # Top Bar Strip
    div = lambda: {"type": "RECT", "name": "Divider", "w": 2, "h": 26, "fill": v("cozy/track")}
    lvl = {"name": "Level", "layout": "H", "gap": 8, "cross": "CENTER", "children": [
        {"name": "Coin", "w": 34, "h": 34, "radius": 999, "fill": {"grad": ["FFD45C", "F2B544"], "angle": 90}, "layout": "H", "main": "CENTER", "cross": "CENTER",
         "children": [ftxt("12", 16, "FFFFFF", name="Level")]},
        {"name": "XP", "layout": "V", "gap": 3, "children": [text("LEVEL", "Caption", "cozy/subtext", name="Label"), mini_bar(90, 8, XP)]}]}
    cur = lambda icon, val, col: {"name": "Currency", "layout": "H", "gap": 6, "cross": "CENTER", "children": [img(icon, 26), ftxt(val, 18, "3D4B5C"), plus_btn(col)]}
    return comp("C Top Bar Strip", {"layout": "H", "gap": 12, "pad": [6, 14, 6, 8], "cross": "CENTER", "radius": 999, "fill": v("cozy/panel"), **BORDER, "children": [
        lvl, div(), cur("ui/status/coin", "12,450", "F2B544"), div(), cur("ui/status/gem", "320", "B79CF2"), div(),
        {"name": "Aura", "layout": "H", "gap": 4, "cross": "CENTER", "children": [img("auras/NeonWave", 28), text("+15%", "Small", "cozy/rarity/rare", name="Luck")]}]})


def var_d():  # Avatar Card
    av = {"name": "Avatar Holder", "w": 80, "h": 88, "children": [dict(avatar(74, "FFFFFF"), x=3, y=0),
        {"name": "Level Row", "layout": "H", "w": 80, "x": 0, "y": 64, "main": "CENTER", "children": [
            {"name": "Level Pill", "layout": "H", "pad": [2, 10, 3, 10], "radius": 999, "fill": {"grad": ["FFD45C", "F2B544"], "angle": 90}, "stroke": "FFFFFF", "strokeW": 2,
             "children": [ftxt("Lv.12", 14, "FFFFFF", name="Level")]}]}]}
    info = {"name": "Info", "layout": "V", "gap": 5, "children": [
        text("AuraAngler", "Heading", name="Player Name"),
        {"name": "XP Row", "layout": "H", "gap": 6, "cross": "CENTER", "children": [mini_bar(120, 8, XP), text("340/900", "Caption", "cozy/subtext", name="XP Text")]},
        {"name": "Currencies", "layout": "H", "gap": 6, "children": [chip("Coins", "12,450"), chip("Gems", "320")]}]}
    return comp("D Avatar Card", {"layout": "H", "gap": 12, "pad": [10, 14, 10, 10], "cross": "CENTER", "radius": 24, "fill": v("cozy/panel"), **BORDER,
                                  "children": [av, info]})


def var_e():  # Minimal Floating (chosen): no panel, no aura, XP as N / N text
    return comp("E Minimal Floating", {"layout": "V", "gap": 6, "children": [
        {"name": "Level Row", "layout": "H", "gap": 10, "cross": "CENTER", "children": [
            ftxt("Lv.12", 30, "FFFFFF", name="Level", textStroke="3D4B5C", textStrokeW=3),
            ftxt("340 / 900 XP", 16, "FFFFFF", name="XP Text", textStroke="3D4B5C", textStrokeW=2.5)]},
        {"name": "Currencies", "layout": "H", "gap": 6, "cross": "CENTER", "children": [chip("Coins", "12,450"), chip("Gems", "320")]}]})


def var_f():  # Aura Spotlight
    aura = {"name": "Aura", "layout": "V", "gap": 2, "cross": "CENTER", "children": [img("auras/NeonWave", 64), small_pill("+15% LUCK", "cozy/rarity/rare", "Luck")]}
    info = {"name": "Info", "layout": "V", "gap": 6, "children": [
        {"name": "Level Row", "layout": "H", "gap": 8, "cross": "CENTER", "children": [text("Lv. 12", "Heading", name="Level"), text("340 / 900 XP", "Caption", "cozy/subtext", name="XP Text")]},
        mini_bar(200, 10, XP),
        {"name": "Currencies", "layout": "H", "gap": 6, "children": [chip("Coins", "12,450"), chip("Gems", "320")]}]}
    return comp("F Aura Spotlight", {"layout": "H", "gap": 12, "pad": 12, "cross": "CENTER", "radius": 22, "fill": v("cozy/panel"), **BORDER, "children": [aura, info]})


VARIANTS = [var_a, var_b, var_c, var_d, var_e, var_f]
DESC = {
    "A Classic Card": "Current card, tidied: small avatar, level + XP, coins and gems. Safe default.",
    "B Level Badge": "Gold level coin with a circular XP ring, currency pills stacked beside it, aura luck pill. No background card.",
    "C Top Bar Strip": "One slim pill across the top: level, coins (+), gems (+), aura. Thinnest; '+' opens the shop.",
    "D Avatar Card": "Player avatar with a level pill, player name, XP and currencies. Most personal (like the Main Menu header).",
    "E Minimal Floating": "CHOSEN. No panel: outlined level + XP as text (340 / 900 XP), coin and gem chips. No aura. Shows the most of the world.",
    "F Aura Spotlight": "Big equipped-aura orb with its luck bonus next to level + currencies. Pushes the game's core USP.",
}


def component_group():
    return {"parentId": COMPONENTS_BOARD, "replaceName": "HUD Stats Group", "tree": {"name": "HUD Stats Group", "layout": "V", "gap": 12, "children": [
        text("HUD Stats (top-left player card) — 6 styles", "Heading", "cozy/subtext", name="HUD Stats Label"),
        {"type": "VARIANTS", "key": "hudstats", "name": "HUD Stats", "layout": "H", "gap": 28, "pad": 24, "setRadius": 16, "setFill": "BFE8E0",
         "description": "Top-left HUD player card. Property Style = A..F. Every screen uses an instance, so edit here once.",
         "children": [f() for f in VARIANTS]}]}}


def board(set_id):
    cards = []
    for i, f in enumerate(VARIANTS):
        name = f()["name"].split("=", 1)[1]
        scene = {"name": "Scene", "w": 552, "h": 230, "radius": 16, "clip": True, "fill": {"grad": ["DDF5EE", "A8DCD8"], "angle": 90}, "children": [
            {"name": "World [skip]", "w": 552, "h": 230, "x": 0, "y": 0, "children": [
                {"type": "RECT", "name": "Water", "w": 552, "h": 90, "x": 0, "y": 140, "fill": {"hex": "9AD4F5", "opacity": 0.35}}]},
            {"type": "INSTANCE", "ref": set_id, "variant": "Style=" + name, "name": "Stats", "x": 16, "y": 16}]}
        cards.append({"name": "Option " + name, "layout": "V", "gap": 12, "pad": 24, "w": 600, "radius": 24, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
                      "x": 60 + (i % 3) * 660, "y": 150 + (i // 3) * 470,
                      "children": [text(name, "Title", name="Title"), text(DESC[name], "Small", "cozy/subtext", name="Desc", w=552), scene]})
    sec = {"type": "SECTION", "name": "HUD Stats · 6 options", "fill": "F3E9D8", "x": 8900, "y": 3300, "children": [
        text("HUD Stats — 6 options (one component set)", "Display", name="Title", x=60, y=40),
        text("All screens (HUD, Reel, Main Menu, Inventory) now use an instance of 'HUD Stats'. Pick a Style and every screen updates.",
             "Body", "cozy/subtext", name="Sub", x=60, y=96, w=1800)] + cards}
    return {"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}


def swaps(set_id, variant):
    return {k: {"parentId": sid, "replaceName": "Stats", "tree": {"type": "INSTANCE", "ref": set_id, "variant": "Style=" + variant, "name": "Stats", "x": 24, "y": 24}}
            for k, sid in SCREENS.items()}


if __name__ == "__main__":
    out, mode = sys.argv[1], sys.argv[2]
    if mode == "component":
        json.dump(component_group(), open(os.path.join(out, "13_hud_stats_component.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    else:
        set_id = sys.argv[3]
        variant = sys.argv[4] if len(sys.argv) > 4 else "A Classic Card"
        json.dump(board(set_id), open(os.path.join(out, "14_hud_stats_board.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        for k, d in swaps(set_id, variant).items():
            json.dump(d, open(os.path.join(out, f"15_swap_{k}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("written", mode)
