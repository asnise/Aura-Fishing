"""Cast rework (C25) on Figma 01 · HUD (frame "HUD" 3492:16667):
- Cast Row (CAST + DEPTH popup button) removed: no button in the middle of the screen any more.
- Actions gets a Depth stepper ([-] DEPTH 80m [+]) above AUTO; the whole stack moves up for the mobile cast button.
- "Btn Cast Mobile": round CAST button left of the Roblox jump button (touch devices only; PC = click / E).
- "Cast Charge [state]": what shows while the cast is held: power bar next to the character with the gold
  Perfect zone, the aim marker on the water, and the "PERFECT!" pop.

Run:  python -I docs/figma/cast_rework.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/25_cast_rework_ops.json  (sent 2026-11-20)
      python -I docs/figma/apply_patch.py docs/figma/out/25_cast_rework_part2_ops.json  (notes, 02 states, 15/16 titles)
Game: UI/Screens/HUD.luau (DepthStepper, CastMobile, CastCharge) + FishingController.
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
v, text, ftxt, btn, chip, BORDER, W, H = m.v, m.text, m.ftxt, m.btn, m.chip, m.BORDER, m.W, m.H

HUD = "3492:16667"
CAST_ROW = "3492:16704"
ACTIONS = "3492:16696"


def step_btn(label, name):
    return {"name": name, "w": 40, "h": 40, "radius": 12, "fill": v("cozy/sand"), **BORDER, "strokeSides": {"b": 4},
            "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [ftxt(label, 26, "3D4B5C", name="Label")]}


def depth_stepper(value="80m"):
    return {"name": "Depth Stepper", "layout": "H", "w": 200, "h": 57, "pad": [0, 8, 0, 8], "main": "SPACE_BETWEEN", "cross": "CENTER",
            "radius": 16, "fill": v("cozy/panel"), **BORDER, "children": [
                step_btn("-", "Btn Minus"),
                {"name": "Readout", "layout": "V", "gap": 0, "cross": "CENTER", "children": [
                    text("DEPTH", "Caption", "cozy/subtext", name="Label"), ftxt(value, 22, "3D4B5C", name="Value")]},
                step_btn("+", "Btn Plus")]}


def actions():
    # 40 + 57 + 57 + 57 + 3 gaps = 241 tall; ends at y 531, above the mobile cast button (554)
    return {"name": "Actions", "layout": "V", "gap": 10, "w": 200, "x": W - 216, "y": 290, "children": [
        chip("Bag", "18 / 50", "Bag"),
        depth_stepper(),
        btn("Ghost", "AUTO: OFF", "Btn Auto", fillW=True),
        btn("Gold", "SELL ALL", "Btn Sell", fillW=True)]}


def cast_mobile():
    # left of the Roblox jump button (W-160, H-170, 96x96), same bottom line
    return {"name": "Btn Cast Mobile", "x": W - 160 - 12 - 88, "y": H - 166, "w": 88, "h": 88, "radius": 999,
            "fill": v("cozy/coral"), "stroke": v("cozy/coral-lip"), "strokeW": 2, "strokeSides": {"b": 5},
            "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [ftxt("CAST", 20, "FFFFFF", name="Label")]}


def cast_charge():
    bar_h = 170
    zone_top, zone_h = 0.10, 0.12  # Perfect zone: 78-90% power (bar fills upwards)
    return {"name": "Cast Charge [state: holding]", "x": 0, "y": 0, "w": W, "h": H, "children": [
        {"name": "Power Bar", "x": 700, "y": 230, "w": 26, "h": bar_h, "radius": 13, "fill": v("cozy/panel"), **BORDER, "clip": True, "children": [
            {"type": "RECT", "name": "Fill", "x": 0, "y": int(bar_h * 0.3), "w": 26, "h": int(bar_h * 0.7), "fill": v("cozy/coral")},
            {"type": "RECT", "name": "Perfect Zone", "x": 0, "y": int(bar_h * zone_top), "w": 26, "h": int(bar_h * zone_h), "fill": v("cozy/gold"), "opacity": 0.85},
            {"type": "RECT", "name": "Needle", "x": 0, "y": int(bar_h * 0.3) - 2, "w": 26, "h": 4, "fill": "FFFFFF"}]},
        {"type": "ELLIPSE", "name": "Aim Marker", "x": 610, "y": 520, "w": 70, "h": 26, "fill": "FFFFFF", "opacity": 0.25,
         "stroke": "FFFFFF", "strokeW": 3},
        {"type": "ELLIPSE", "name": "Aim Marker Miss (grey, not water)", "x": 470, "y": 455, "w": 56, "h": 20, "fill": "9AA5B1", "opacity": 0.35,
         "stroke": "9AA5B1", "strokeW": 3},
        ftxt("PERFECT!", 30, "F2B544", name="Perfect Pop", x=660, y=186, textStroke="3D4B5C", textStrokeW=3)]}


def round_cast(label, fill, lip, color="FFFFFF"):
    return {"name": "Btn Cast Mobile", "w": 88, "h": 88, "radius": 999, "fill": v(fill), "stroke": v(lip), "strokeW": 2, "strokeSides": {"b": 5},
            "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [ftxt(label, 18 if len(label) > 5 else 20, color, name="Label")]}


# Part 2: notes + 02 HUD States + the outdated Cast Popup sections (titles only; sections are kept)
NOTE_01 = ("Main fishing screen. Top-left stats, left menu, bottom-right bag / DEPTH stepper / auto / sell. No CAST in the middle (C25): "
           "PC clicks the world, touch uses the round CAST button left of jump. Hold = power bar + aim marker, gold zone = PERFECT. Code: HUDController + FishingController.")
NOTE_02 = "Round CAST button (touch) per fishing phase; PC shows the same text in the status pill only. Code: FishingController FishingState."
PART2 = [
    {"replaceId": "3492:16723", "tree": text(NOTE_01, "Body", "cozy/subtext", name="Note", w=W, x=60, y=860)},
    {"replaceId": "3492:16762", "tree": text(NOTE_02, "Body", "cozy/subtext", name="Note", w=W, x=60, y=500)},
    {"replaceId": "3492:16734", "tree": round_cast("CAST", "cozy/coral", "cozy/coral-lip")},
    {"replaceId": "3492:16740", "tree": round_cast("REEL IN", "cozy/sand", "cozy/track", "3D4B5C")},
    {"replaceId": "3492:16745", "tree": round_cast("HOOK!", "cozy/gold", "cozy/gold-lip")},
    {"replaceId": "3492:16751", "tree": round_cast("AUTO", "cozy/sand", "cozy/track", "3D4B5C")},
    {"replaceId": "3492:17646", "tree": text("15 · Cast Popup (removed in C25)", "Display", name="Title", x=60, y=30)},
    {"replaceId": "3492:17741", "tree": text("16 · Cast Popup · Auto depth (removed in C25)", "Display", name="Title", x=60, y=30)},
]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "25_cast_rework_part2_ops.json"), "w", encoding="utf-8") as f:
        json.dump(PART2, f, ensure_ascii=False, indent=1)
    p = os.path.join(out, "25_cast_rework_ops.json")
    ops = [
        {"remove": [CAST_ROW]},
        {"replaceId": ACTIONS, "tree": actions()},
        {"parentId": HUD, "tree": cast_mobile()},
        {"parentId": HUD, "tree": cast_charge()},
    ]
    with open(p, "w", encoding="utf-8") as f:
        json.dump(ops, f, ensure_ascii=False, indent=1)
    print("wrote", p)
