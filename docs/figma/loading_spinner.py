"""Loading spinner (2026-11-20): anything that waits for data spins on that object / menu (New.Spinner in game).
Ring = 2D arc with a fading tail, turns every 0.9 s. Shown in the Store section (3546:36700) free slot:
- Store content while the save data is not here yet (48px coral)
- Robux Buy button until Roblox returns the real price (24px white, price hidden)
- Image slot still downloading: skeleton block + grey spinner (40% of the slot)

Run:  python -I docs/figma/loading_spinner.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/31_loading_spinner_ops.json
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
v, text, BORDER = m.v, m.text, m.BORDER


def spinner(size, color, thick, name="Spinner"):
    r = (size - thick) / 2
    c = size / 2
    # 270 deg arc from the top, clockwise: the fading tail in game is a gradient; here a solid arc + faint track
    svg = (f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" xmlns="http://www.w3.org/2000/svg">'
           f'<circle cx="{c}" cy="{c}" r="{r}" fill="none" stroke="#{color}" stroke-opacity="0.15" stroke-width="{thick}"/>'
           f'<path d="M {c} {c - r} A {r} {r} 0 1 1 {c - r} {c}" fill="none" stroke="#{color}" stroke-width="{thick}" stroke-linecap="round"/></svg>')
    return {"type": "SVG", "svg": svg, "w": size, "h": size, "name": name}


def card(title, body):
    return {"name": title, "layout": "V", "gap": 10, "pad": 16, "w": 250, "h": 300, "radius": 20, "fill": v("cozy/panel"), **BORDER, "cross": "CENTER", "children": [
        text(title, "Heading", name="Title"), {"name": "Sample", "layout": "V", "main": "CENTER", "cross": "CENTER", "w": 218, "h": 200, "children": body}]}


def frame():
    store = card("Store content loading", [spinner(48, "FF9E80", 5)])
    buy = card("Buy button: price loading", [{"name": "Btn Buy", "w": 84, "h": 46, "radius": 16, "fill": v("cozy/mint"), "stroke": v("cozy/mint-lip"), "strokeW": 1,
                                             "strokeSides": {"b": 4}, "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [spinner(24, "FFFFFF", 3)]}])
    img = card("Image still downloading", [{"name": "Skeleton", "w": 96, "h": 96, "radius": 16, "fill": v("cozy/sand"), "layout": "H", "main": "CENTER", "cross": "CENTER",
                                           "children": [spinner(38, "7A8A99", 3)]}])
    return {"name": "Loading states (spinner)", "x": 1860, "y": 960, "layout": "V", "gap": 12, "children": [
        text("Loading spinner - New.Spinner", "Title", name="Title"),
        {"name": "Row", "layout": "H", "gap": 16, "children": [store, buy, img]},
        text("Ring turns every 0.9 s with a fading tail. Shown only while waiting; removed when the data arrives. No dark overlay behind the Store.", "Body", "cozy/subtext", name="Note", w=790)]}


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "31_loading_spinner_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump([{"parentId": "3546:36700", "tree": frame()}], f, ensure_ascii=False, indent=1)
    print("wrote", p)
