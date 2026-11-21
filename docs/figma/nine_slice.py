"""Section "Roblox 9-slice (export)" on page Out Space: shape + shadow tiles that Roblox draws as
9-slice images (ImageLabel ScaleType = Slice) behind the matching UI (UICorner cannot draw shadows).

Each tile = white rounded rect (same radius as the UI it sits under) with the exact Figma shadow.
Exported PNG = shape + shadow bounds; Roblox places it behind the panel, grown by the shadow margin.

Run:  python -I docs/figma/nine_slice.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/11_nine_slice_ops.json
Export: python -I tools/art/export_nine_slice.py   (writes assets/ui-global/slice_*.png + catalog)
"""
import json
import os
import sys

PAGE_ID = "3465:14993"  # Out Space
SIZE = 120  # tile shape size (px); corners stay crisp because SliceCenter excludes them

# name -> (corner radius, shadow) ; shadow matches the Figma node it belongs to
SLICES = {
    "slice_shadow_window": (24, {"color": "3D4B5C", "a": 0.10, "y": 6, "blur": 18}),  # list windows (Shop/Auras/Fishdex)
    "slice_shadow_modal": (36, {"color": "3D4B5C", "a": 0.10, "y": 6, "blur": 18}),  # 14 Modal
    "slice_shadow_glass": (48, {"color": "3D4B5C", "a": 0.16, "y": 10, "blur": 30}),  # 12 Main Menu glass frame
}


def build():
    tiles = []
    x = 0
    for name, (radius, shadow) in SLICES.items():
        tiles.append({"name": f"Slice {name}", "w": SIZE, "h": SIZE, "x": x, "y": 0, "radius": radius, "fill": "FFFFFF", "effects": [shadow]})
        x += SIZE + 120
    note = {"type": "TEXT", "name": "Note", "x": 0, "y": SIZE + 60, "w": x,
            "text": "Roblox 9-slice tiles: white shape + exact shadow. Exported by tools/art/export_nine_slice.py -> assets/ui-global/slice_*.png. Edit radius/shadow here, then re-export.",
            "style": "Body"}
    return {"type": "SECTION", "name": "Roblox 9-slice (export)", "fill": "F3E9D8", "x": 8900, "y": 12900, "pad": 80, "children": tiles}


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "11_nine_slice_ops.json"), "w", encoding="utf-8") as f:
        json.dump([{"pageId": PAGE_ID, "replaceName": "Roblox 9-slice (export)", "tree": build()}], f, ensure_ascii=False, indent=1)
    print("wrote", os.path.join(out, "11_nine_slice_ops.json"))
