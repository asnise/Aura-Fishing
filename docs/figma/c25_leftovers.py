"""C25 leftovers outside 01/02 HUD (audit 2026-11-20): no centre CAST / DEPTH anywhere, depth stepper in Actions,
4th "Menu" side tile, Hot Streak tag at bottom centre.
- 00 Safe Areas: remove zone "CAST + DEPTH BTN"
- 03 Reel Minigame: remove Cast Row (REELING)
- 04 Catch Result: remove Cast Row, Actions = 01 HUD actions (with Depth Stepper), add Menu tile
- Economy 1 HUD: Cast Row keeps only the streak tag (bottom centre), Actions with Depth Stepper; parts title renamed

Run:  python -I docs/figma/c25_leftovers.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/33_c25_leftovers_ops.json
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))


def load(name):
    s = importlib.util.spec_from_file_location(name, os.path.join(_here, name + ".py"))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


cast = load("cast_rework")
tiles = load("menu_tiles")

OPS = [
    {"remove": ["3492:16647", "3492:16798", "3492:16865", "3539:27541", "3539:27547"]},
    {"replaceId": "3492:16857", "tree": cast.actions()},
    {"replaceId": "3539:27531", "tree": cast.actions()},
    {"parentId": "3492:16844", "tree": tiles.tile("Menu", "equipment/StarterPouch", None)},
]
RENAMES = [
    {"id": "3539:27564", "name": "Hot Streak · tag (bottom centre since C25, was on CAST)"},
    {"id": "3539:27540", "name": "Streak (bottom centre)"},
]

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "33_c25_leftovers_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(OPS, f, ensure_ascii=False, indent=1)
    with open(os.path.join(out, "33_renames.json"), "w", encoding="utf-8") as f:
        json.dump({"patches": RENAMES}, f, ensure_ascii=False)
    print("wrote", p)
