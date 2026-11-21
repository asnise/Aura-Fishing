"""HUD side-menu tiles (Figma 01 · HUD, frame "Menu" 3492:16683): 64x64 cream tile with a 50px icon and the
label UNDER the tile as outlined text (white Fredoka One + slate outline, like the HUD Lv./XP).
"Menu" uses the equipment/StarterPouch art. Replaces only the 4 "Btn …" nodes, in place.

Run:  python -I docs/figma/menu_tiles.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/16_menu_tiles_ops.json
Then: python -I tools/art/figma_images.py --root 3492:16683
Game: UI/Screens/Components.luau Make.MenuTile (same layout).
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
img, v, BORDER, ftxt = m.img, m.v, m.BORDER, m.ftxt

# node id -> (label, icon art key, tile fill)
TILES = {
    "3492:16684": ("Shop", "ui/icons/shop", "cozy/panel"),
    "3492:16688": ("Auras", "ui/icons/auras", "cozy/panel"),
    "3492:16692": ("Fishdex", "ui/icons/fishdex", "cozy/panel"),
    "3520:22575": ("Menu", "equipment/StarterPouch", None),  # sky tint like the game (#D3ECFA)
}


def tile(label, icon, fill):
    return {"name": "Btn " + label, "layout": "V", "gap": 2, "w": 80, "h": 88, "cross": "CENTER", "children": [
        {"name": "Tile", "w": 64, "h": 64, "radius": 20, "fill": v(fill) if fill else "D3ECFA", **BORDER, "layout": "H", "main": "CENTER", "cross": "CENTER",
         "children": [img(icon, 50)]},
        ftxt(label, 14, "FFFFFF", name="Label", textStroke="3D4B5C", textStrokeW=2)]}


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "16_menu_tiles_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump([{"replaceId": k, "tree": tile(*t)} for k, t in TILES.items()], f, ensure_ascii=False, indent=1)
    print("wrote", p)
