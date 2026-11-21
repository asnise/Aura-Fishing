"""Fish Hotspots (C26): bubbling patches on the water near anglers; a manual cast that lands inside = luck bonus.
- 01 · HUD "Cast Charge [state: holding]" (3688:57113): a hotspot on the water (gold ring + bubbles) with the
  aim marker turning gold when it is over one.
- 10 · Notifications Toast Stack (3492:17248): "Face the water" toast becomes the C25 miss text, plus the hotspot toasts.
- Catch card meta gets a gold "HOTSPOT" badge (same badge row as PERFECT, built in code by HUD.ShowCatch).

Run:  python -I docs/figma/hotspot.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/26_hotspot_ops.json
Game: server/Services/HotspotService.luau (world parts), FishingController (gold aim), HUDController.ShowCatch.
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
v, text, ftxt, pill = m.v, m.text, m.ftxt, m.pill

CAST_CHARGE = "3688:57113"
TOAST_STACK = "3492:17248"
TOAST_FACE_WATER = "3492:17259"


def bubble(x, y, s):
    return {"type": "ELLIPSE", "name": "Bubble", "x": x, "y": y, "w": s, "h": s, "fill": "FFFFFF", "opacity": 0.8}


def hotspot():
    # world mock: sits on the water, right of the normal aim marker
    return {"name": "Hotspot (world, server part)", "x": 760, "y": 540, "w": 120, "h": 70, "children": [
        {"type": "ELLIPSE", "name": "Ring", "x": 0, "y": 30, "w": 120, "h": 40, "fill": v("cozy/gold"), "opacity": 0.35, "stroke": v("cozy/gold"), "strokeW": 3},
        {"type": "ELLIPSE", "name": "Aim Marker Hotspot (gold)", "x": 30, "y": 40, "w": 60, "h": 20, "fill": v("cozy/gold"), "opacity": 0.6, "stroke": "FFFFFF", "strokeW": 3},
        bubble(28, 14, 10), bubble(56, 0, 14), bubble(84, 18, 8), bubble(44, 24, 7), bubble(70, 26, 9),
        ftxt("HOTSPOT", 14, "FFFFFF", name="Label (when aimed)", x=28, y=-22, textStroke="3D4B5C", textStrokeW=2)]}


OPS = [
    {"parentId": CAST_CHARGE, "tree": hotspot()},
    {"replaceId": TOAST_FACE_WATER, "tree": pill("Cast into the water!", "Body", "cozy/danger-lip", name="Toast Miss Water")},
    {"parentId": TOAST_STACK, "tree": pill("HOTSPOT!  +50% luck on this cast", "Body", "cozy/gold-lip", name="Toast Hotspot")},
]

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "26_hotspot_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(OPS, f, ensure_ascii=False, indent=1)
    print("wrote", p)


# Part 2 (catch card): gold "HOTSPOT" badge after PERFECT in 04 · Catch Result card Meta row (3492:21797),
# same style as PERFECT (game: HUD.ShowCatch meta badges, T.Gold for both).
CATCH_META = "3492:21797"
CARD_OPS = [{"parentId": CATCH_META, "tree": {"name": "Badge", "layout": "H", "pad": [3, 10, 4, 10], "radius": 999, "fill": v("cozy/gold"),
             "children": [text("HOTSPOT", "Caption", "cozy/on-accent", name="Label")]}}]

if __name__ == "__main__":
    with open(os.path.join(out, "26_hotspot_card_ops.json"), "w", encoding="utf-8") as f:
        json.dump(CARD_OPS, f, ensure_ascii=False, indent=1)
    print("wrote 26_hotspot_card_ops.json  (send: apply_patch.py docs/figma/out/26_hotspot_card_ops.json)")
