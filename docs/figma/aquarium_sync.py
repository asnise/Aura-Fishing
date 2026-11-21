"""Sync Figma "Economy · 2 Aquarium" (3569:40689) with the game (2026-11-20):
- tank cards have no Btn Remove: tapping a card opens Modal.Confirm "Return to Bag" (EconomyController OnSelect)
- Btn Expand = 118x59 gold, coin 18 + price 17 only (AquariumScreen.createLocked)
- "Screen C14/C18 · Inventory: put in tank + hot fish" removed (not in the game); its slot now shows the Return to Bag modal

Run:  python -I docs/figma/aquarium_sync.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/27_aquarium_sync_ops.json
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
v, text, ftxt, btn, img, BORDER, SOFT, screen = m.v, m.text, m.ftxt, m.btn, m.img, m.BORDER, m.SOFT, m.screen

SECTION = "3569:40689"
REMOVE = ["3569:40738", "3569:40753", "3569:40767", "3569:40781", "3569:40796", "3569:40840"]
EXPAND = {"3569:40807": "5,000", "3569:40817": "20k"}


def expand_btn(price):
    return {"name": "Btn Expand", "x": 22, "y": 112, "w": 118, "h": 59, "radius": 16, "fill": v("cozy/gold"), "stroke": v("cozy/gold-lip"), "strokeW": 1,
            "strokeSides": {"b": 4}, "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [
                {"name": "Cost", "layout": "H", "gap": 4, "cross": "CENTER", "children": [img("ui/status/coin", 18), ftxt(price, 17, "FFFFFF")]}]}


def return_modal():
    modal = {"name": "Modal", "layout": "V", "w": 600, "x": 340, "y": 170, "radius": 36, "clip": True, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
             "children": [
                 {"name": "Body", "layout": "V", "gap": 10, "pad": [44, 48, 36, 48], "fillW": True, "cross": "CENTER", "children": [
                     img("fish/GlowEel", 96),
                     text("Glow Eel", "Title", name="Title", align="CENTER", w=500),
                     text("Pearl income: +0.045/s\nDo you want to return this fish to your bag?", "Body", "cozy/subtext", name="Message", align="CENTER", w=500)]},
                 {"name": "Footer", "layout": "H", "gap": 20, "pad": [18, 40, 22, 40], "fillW": True, "main": "CENTER", "fill": v("cozy/sand"), "children": [
                     btn("Ghost", "Keep in Tank", "Btn Cancel", fillW=True), btn("Primary", "Return to Bag", "Btn Confirm", fillW=True)]}]}
    s = screen("Return to Bag", [modal], dim=True)
    return {"name": "Screen C14 · Tap a tank fish -> Return to Bag", "layout": "V", "gap": 12, "x": 1400, "y": 160, "children": [
        text("C14 · Tap a tank fish -> Return to Bag (Modal.Confirm)", "Title", name="Title"), s]}


OPS = [{"remove": REMOVE}] + [{"replaceId": k, "tree": expand_btn(p)} for k, p in EXPAND.items()] + [{"parentId": SECTION, "tree": return_modal()}]

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "27_aquarium_sync_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(OPS, f, ensure_ascii=False, indent=1)
    print("wrote", p)
