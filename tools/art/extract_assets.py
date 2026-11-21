"""Extract game-ready UI assets from Figma + build the asset/component catalog.

  python -I tools/art/extract_assets.py [--channel aura-fishing] [--no-build]

1. Builds/refreshes the Figma section "Global Assets (export)" (page Out Space): every vector shape the UI needs,
   drawn ONCE in WHITE (so Roblox can tint it with ImageColor3) — duplicates in different colours/sizes collapse to one asset.
2. Exports each one to assets/ui-global/<id>.png.
3. Scans the real Figma screens/components and records which assets (global vectors + art PNGs) each one uses,
   plus every component / component set with its node id and variants.
4. Writes assets/catalog.json, docs/ASSET_CATALOG.md and src/shared/Config/UIAssets.luau (asset ids to fill after upload).
"""
import base64
import json
import math
import os
import subprocess
import sys
import tempfile
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")
os.environ.setdefault("FIGMA_AGENT", "py:extract_assets")  # caller name in the relay usage counter
ART = os.path.join(ROOT, "assets", "art")
OUT_GLOBAL = os.path.join(ROOT, "assets", "ui-global")
PAGE_ID = "3465:14993"
CHANNEL = sys.argv[sys.argv.index("--channel") + 1] if "--channel" in sys.argv else "aura-fishing"

# Figma roots that hold REAL game UI (not exploration boards)
SCAN_ROOTS = {
    "Components board": "3487:4280",
    "Game Menus (Cozy Lake)": "3492:16631",
    "Aura Gacha — Reel Slot (FINAL)": None,  # filled from /tmp-free lookup below
}


def call(cmd, params, timeout=300):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(params, f)
    try:
        r = subprocess.run(["node", RUN, f"--channel={CHANNEL}", cmd, f.name, f"--timeout={timeout}"], capture_output=True, text=True, encoding="utf-8")
    finally:
        os.unlink(f.name)
    if r.returncode != 0:
        raise SystemExit(f"{cmd} failed: {r.stderr.strip() or r.stdout.strip()}")
    return json.loads(r.stdout)


# ------------------------------------------------------------------ global vector assets (white)
def svg(w, h, body):
    return f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg">{body}</svg>'


FA_LOCK = "M400 224h-24v-72C376 68.2 307.8 0 224 0S72 68.2 72 152v72H48c-26.5 0-48 21.5-48 48v192c0 26.5 21.5 48 48 48h352c26.5 0 48-21.5 48-48V272c0-26.5-21.5-48-48-48zm-104 0H152v-72c0-39.7 32.3-72 72-72s72 32.3 72 72v72z"


def rays_svg(size=512, n=16):
    c = size / 2
    body = ""
    for i in range(n):
        a0 = 2 * math.pi * i / n
        a1 = a0 + math.pi / n * 0.55
        body += f'<path d="M{c:.0f} {c:.0f} L{c + c * math.cos(a0):.0f} {c + c * math.sin(a0):.0f} L{c + c * math.cos(a1):.0f} {c + c * math.sin(a1):.0f}Z" fill="#FFFFFF"/>'
    return svg(size, size, body)


def wave_svg(w=728, h=52, step=52):
    d = f"M0 {h * 0.46:.0f} " + " ".join(f"Q{x + step / 2:.0f} {0 if i % 2 == 0 else h * 0.85:.0f} {x + step:.0f} {h * 0.46:.0f}" for i, x in enumerate(range(0, w, step)))
    return svg(w, h, f'<path d="{d} V{h} H0 Z" fill="#FFFFFF"/>')


GLOBAL = [
    # id, w, h, svg, tint (True = white, colour in code), usage note
    ("icon_lock", 112, 128, f'<svg width="112" height="128" viewBox="0 0 448 512" xmlns="http://www.w3.org/2000/svg"><path d="{FA_LOCK}" fill="#FFFFFF"/></svg>', True,
     "Locked state (Item Slot, gacha). react-icons/fa FaLock, Font Awesome Free CC BY 4.0 — credit required."),
    ("icon_check", 128, 128, svg(128, 128, '<path d="M24 68l28 28 52-60" stroke="#FFFFFF" stroke-width="18" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'), True,
     "Selected badge (Item Slot), checkboxes (Cast popup Auto depth, gacha options)."),
    ("icon_close", 128, 128, svg(128, 128, '<path d="M32 32l64 64M96 32 32 96" stroke="#FFFFFF" stroke-width="20" stroke-linecap="round"/>'), True,
     "Close buttons (windows, Main Menu side tab, Dialogue). Buttons may also use the text glyph 'X'."),
    ("icon_plus", 128, 128, svg(128, 128, '<rect x="54" y="18" width="20" height="92" rx="10" fill="#FFFFFF"/><rect x="18" y="54" width="92" height="20" rx="10" fill="#FFFFFF"/>'), True,
     "Empty Item Slot '+', currency '+' buttons (HUD Stats C)."),
    ("icon_chevron_left", 128, 128, svg(128, 128, '<path d="M80 24 40 64l40 40" stroke="#FFFFFF" stroke-width="20" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'), True,
     "Pager previous (Shop / Auras / Fishdex)."),
    ("icon_chevron_right", 128, 128, svg(128, 128, '<path d="M48 24l40 40-40 40" stroke="#FFFFFF" stroke-width="20" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'), True,
     "Pager next; gacha near-miss marker."),
    ("shape_rarity_corner", 64, 64, svg(64, 64, '<path d="M0 0H64L0 64Z" fill="#FFFFFF"/>'), True,
     "Item Slot top-left rarity corner (tint = rarity colour). Clip with the slot's UICorner."),
    ("shape_wave_edge", 728, 52, wave_svg(), True,
     "Main Menu header wavy bottom edge (tint = panel colour #FFF8EC). ScaleType Tile or Stretch horizontally."),
    ("fx_rays", 512, 512, rays_svg(), True,
     "Gacha lock/reveal light rays, rotating (tint = rarity colour, ImageTransparency 0.6-0.8)."),
    ("icon_moon", 64, 64, svg(64, 64, '<path d="M42 8a26 26 0 1 0 14 44A22 22 0 0 1 42 8z" fill="#FFFFFF"/>'), True, "Main Menu day-phase row (night/dusk)."),
    ("icon_dawn", 72, 64, svg(72, 64, '<path d="M14 50a22 22 0 0 1 44 0z" fill="#FFFFFF"/><rect x="4" y="50" width="64" height="8" rx="4" fill="#FFFFFF"/><rect x="32" y="4" width="8" height="14" rx="4" fill="#FFFFFF"/>'
                                     '<rect x="8" y="22" width="8" height="14" rx="4" fill="#FFFFFF" transform="rotate(-45 12 29)"/><rect x="56" y="22" width="8" height="14" rx="4" fill="#FFFFFF" transform="rotate(45 60 29)"/>'), True,
     "Main Menu day-phase row (dawn)."),
    ("icon_day", 64, 64, svg(64, 64, '<circle cx="32" cy="32" r="16" fill="#FFFFFF"/><circle cx="32" cy="32" r="28" stroke="#FFFFFF" stroke-width="5" fill="none"/>'), True,
     "Main Menu day-phase row (current = day)."),
    ("icon_chat", 128, 128, svg(128, 128, '<path d="M20 30a14 14 0 0 1 14-14h60a14 14 0 0 1 14 14v40a14 14 0 0 1-14 14H56l-24 22V84h0a14 14 0 0 1-12-14z" fill="#FFFFFF"/>'), True,
     "Dialogue choice 'Just chatting'."),
    ("icon_fish", 128, 128, svg(128, 128, '<path d="M12 64c16-24 44-34 74-22l24-18v80l-24-18C56 98 28 88 12 64z" fill="#FFFFFF"/>'), True,
     "Dialogue choice 'Sell All Fish', generic fish glyph (tint)."),
    ("icon_sun", 128, 128, svg(128, 128, "".join(f'<rect x="58" y="4" width="12" height="24" rx="6" fill="#FFD45C" transform="rotate({a} 64 64)"/>' for a in range(0, 360, 45))
                                + '<circle cx="64" cy="64" r="30" fill="#FFC93D"/><circle cx="54" cy="54" r="10" fill="#FFE59A"/>'), False,
     "Main Menu weather (sunny). Full colour — do not tint."),
]

# Figma layer name (or parent/name) -> global asset id (used to map usages found while scanning)
NAME_TO_GLOBAL = {
    "Icon FaLock": "icon_lock", "Tick": "icon_check", "Rarity Corner": "shape_rarity_corner", "Wave": "shape_wave_edge", "Rays": "fx_rays",
    "Weather Sun": "icon_sun", "Phase Night": "icon_moon", "Phase Dusk": "icon_moon", "Phase Dawn": "icon_dawn", "Arrow": "icon_chevron_right",
    "Btn Close/Icon": "icon_close", "Icon x": "icon_close", "Phase Day (now)/Icon": "icon_day", "Btn Add/Plus": "icon_plus", "Plus": "icon_plus",
    "Btn Page Prev": "icon_chevron_left", "Btn Page Next": "icon_chevron_right", "Icon chat": "icon_chat", "Icon fish": "icon_fish",
}
# Image-filled vector layers inside chips -> art keys (parent instance/variant name / layer)
NAME_TO_ART = {"Coins/Icon": "ui/status/coin", "Type=Coins/Icon": "ui/status/coin", "Gems/Icon": "ui/status/gem", "Type=Gems/Icon": "ui/status/gem",
               "Bag/Icon": "ui/icons/bag", "Type=Bag/Icon": "ui/icons/bag", "Level/Icon": "ui/status/xp_star", "Type=Level/Icon": "ui/status/xp_star",
               "Value/Icon": "ui/status/coin"}
# Drawn by code (Frames / dots), no image asset needed
CODE_DRAWN = {"Ring Track": "Ring Reel ring (FishingController, 72 dots)", "Progress Donut": "Ring Reel progress (48 dots)",
              "XP Ring": "HUD Stats style B only (not used)"}


def build_global_section():
    tiles = []
    for aid, w, h, code, tint, note in GLOBAL:
        tiles.append({"name": "Tile " + aid, "layout": "V", "gap": 8, "pad": 14, "w": 200, "cross": "CENTER", "radius": 18, "fill": "3D4B5C", "children": [
            {"name": "asset:" + aid, "w": w, "h": h, "children": [{"type": "SVG", "name": "Vector", "svg": code, "w": w, "h": h, "x": 0, "y": 0}]},
            {"type": "TEXT", "name": "Id", "text": aid, "textStyle": "Aura Fishing/Caption", "color": "FFFFFF", "w": 172, "align": "CENTER"}]})
    sec = {"type": "SECTION", "name": "Global Assets (export)", "fill": "F3E9D8", "x": 8900, "y": 10600, "children": [
        {"type": "TEXT", "name": "Title", "text": "Global Assets — white & tintable (one file per shape). Export: tools/art/extract_assets.py",
         "textStyle": "Aura Fishing/Display", "color": "3D4B5C", "x": 60, "y": 40},
        {"name": "Grid", "layout": "H", "wrap": True, "gap": 20, "rowGap": 20, "w": 1500, "x": 60, "y": 130, "children": tiles}]}
    res = call("build_tree", {"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}, 300)
    return res["rootId"]


def export_globals(section_id):
    os.makedirs(OUT_GLOBAL, exist_ok=True)
    tree = call("get_roblox_tree", {"nodeId": section_id, "maxDepth": 10}, 120)["root"]
    found = {}

    def walk(n):
        if n["name"].startswith("asset:"):
            found[n["name"][6:]] = n["id"]
        for c in n.get("children") or []:
            walk(c)
    walk(tree)
    files = {}
    for aid, *_ in GLOBAL:
        img = call("export_node_as_image", {"nodeId": found[aid], "format": "PNG", "scale": 1}, 120)
        path = os.path.join(OUT_GLOBAL, aid + ".png")
        open(path, "wb").write(base64.b64decode(img["imageData"]))
        files[aid] = {"file": os.path.relpath(path, ROOT).replace("\\", "/"), "figma": found[aid]}
    return files


# ------------------------------------------------------------------ scan usage
def scan(root_name, root_id, usage_art, usage_global, components, unmapped):
    tree = call("get_roblox_tree", {"nodeId": root_id, "maxDepth": 80}, 300)["root"]

    def screen_of(path):
        # nearest "NN · Title" section or a component name for readable usage
        for p in reversed(path):
            if " · " in p or p.startswith("G") and " · " in p:
                return p
        return path[-1] if path else root_name

    def walk(n, path, override):
        name = n["name"]
        import re
        mo = re.search(r"\{img:([^}]+)\}", name)
        if mo:
            override = mo.group(1)
        if "[skip]" in name:
            return  # design-only placeholders (fake 3D world, CoreGui guide)
        where = f"{root_name} › {screen_of(path + [name])}"
        if name.startswith("Img "):
            usage_art[override or name[4:].strip()].add(where)
        key2 = f"{path[-1] if path else ''}/{name}"
        gid = NAME_TO_GLOBAL.get(key2) or NAME_TO_GLOBAL.get(name)
        if gid:
            usage_global[gid].add(where)
        elif key2 in NAME_TO_ART:
            usage_art[NAME_TO_ART[key2]].add(where)
        elif name in CODE_DRAWN:
            pass
        elif n.get("rasterize") and not name.startswith("Img ") and not name.startswith("asset:"):
            unmapped[name].add(where)
        if n["type"] in ("COMPONENT", "COMPONENT_SET") and not n["id"].startswith("I"):
            parent_is_set = path and path[-1] == "__SET__"
            if n["type"] == "COMPONENT_SET":
                components[n["id"]] = {"name": name, "type": "COMPONENT_SET", "variants": [c["name"] for c in n.get("children") or []], "board": root_name}
            elif not parent_is_set:
                components[n["id"]] = {"name": name, "type": "COMPONENT", "variants": [], "board": root_name}
        for c in n.get("children") or []:
            walk(c, path + (["__SET__"] if n["type"] == "COMPONENT_SET" else [name]), override)
    walk(tree, [], None)


# ------------------------------------------------------------------ outputs
def art_index():
    sheets = json.load(open(os.path.join(ROOT, "tools", "art", "sheets.json"), encoding="utf-8"))["sheets"]
    out = {}
    for s in sheets:
        for name, desc in s["items"]:
            out[f"{s['folder']}/{name}"] = {"file": f"assets/art/{s['folder']}/{name}.png", "sheet": s["id"], "desc": desc}
    return out


def main():
    gacha_root = None
    hint = os.path.join(ROOT, "docs", "figma", "out", "ids.json")
    ids = json.load(open(hint, encoding="utf-8")) if os.path.exists(hint) else {}
    roots = dict(SCAN_ROOTS)
    roots["Aura Gacha — Reel Slot (FINAL)"] = ids.get("gacha_final")
    roots = {k: v for k, v in roots.items() if v}

    sec = ids.get("global_assets") if "--no-build" in sys.argv else build_global_section()
    globals_files = export_globals(sec)

    usage_art, usage_global, components, unmapped = defaultdict(set), defaultdict(set), {}, defaultdict(set)
    for name, rid in roots.items():
        scan(name, rid, usage_art, usage_global, components, unmapped)

    arts = art_index()
    catalog = {"generated": "2026-11-16", "figma_file": "givb0hmQYmmaOy7p7DGtb2", "figma_page": PAGE_ID, "global_assets_section": sec,
               "rules": {"global": "one file per shape, exported white, tint in code with ImageColor3; art PNGs are unique per item",
                         "rbxassetid": "fill after uploading (Studio > Asset Manager > Bulk Import), then run tools/art/sync_ui_assets.py"},
               "global": {}, "art": {}, "components": components, "code_drawn": CODE_DRAWN, "unmapped_vectors": {k: sorted(v) for k, v in unmapped.items()}}
    for aid, w, h, code, tint, note in GLOBAL:
        catalog["global"][aid] = {**globals_files[aid], "size": [w, h], "tintable": tint, "note": note, "rbxassetid": None,
                                  "used_by": sorted(usage_global.get(aid, []))}
    for key, info in sorted(arts.items()):
        used = sorted(usage_art.get(key, []))
        catalog["art"][key] = {**info, "size": [512, 512], "rbxassetid": None, "used_by": used, "global": len(used) > 1}
    # keep previously filled asset ids
    cat_path = os.path.join(ROOT, "assets", "catalog.json")
    if os.path.exists(cat_path):
        old = json.load(open(cat_path, encoding="utf-8"))
        for grp in ("global", "art"):
            for k, v in old.get(grp, {}).items():
                if k in catalog[grp] and v.get("rbxassetid"):
                    catalog[grp][k]["rbxassetid"] = v["rbxassetid"]
    json.dump(catalog, open(cat_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    write_markdown(catalog)
    write_luau(catalog)
    print(f"global {len(catalog['global'])} | art {len(catalog['art'])} | components {len(components)} | unmapped vectors {len(unmapped)}")


def write_markdown(c):
    L = ["# Aura Fishing — UI Asset Catalog", "",
         "> Generated by `tools/art/extract_assets.py` from Figma (file `givb0hmQYmmaOy7p7DGtb2`, page *Out Space*). Machine-readable: `assets/catalog.json`.",
         "> In code use `Shared.Config.UIAssets` (generated) — never hard-code `rbxassetid://` in controllers.", "",
         "## 1. Global assets (white, tint with `ImageColor3`) — `assets/ui-global/`", "",
         "| id | file | size | tint | Figma node | used by | note |", "|---|---|---|---|---|---|---|"]
    for k, v in c["global"].items():
        L.append(f"| `{k}` | `{v['file']}` | {v['size'][0]}×{v['size'][1]} | {'yes' if v['tintable'] else 'no (full colour)'} | `{v['figma']}` | "
                 f"{len(v['used_by'])} place(s) | {v['note']} |")
    L += ["", "## 2. Art (full-colour PNG, 512×512, transparent) — `assets/art/`", "",
          "`global` = used in more than one screen/component → upload once, reference everywhere.", "",
          "| key | used by | global |", "|---|---|---|"]
    for k, v in c["art"].items():
        L.append(f"| `{k}` | {', '.join(v['used_by'][:4]) + (' …' if len(v['used_by']) > 4 else '') or '— (library only)'} | {'✓' if v['global'] else ''} |")
    L += ["", "## 3. Figma components (rebuild these as Roblox templates / `UI/New` helpers)", "",
          "| node id | name | type | variants | board |", "|---|---|---|---|---|"]
    for nid, v in sorted(c["components"].items(), key=lambda x: x[1]["name"]):
        vs = ", ".join(v["variants"][:6]) + (f" … (+{len(v['variants']) - 6})" if len(v["variants"]) > 6 else "")
        L.append(f"| `{nid}` | {v['name']} | {v['type']} | {vs} | {v['board']} |")
    if c["unmapped_vectors"]:
        L += ["", "## 4. Vectors not mapped to a global asset (review)", ""]
        for k, v in c["unmapped_vectors"].items():
            L.append(f"- `{k}` — {', '.join(v[:3])}")
    open(os.path.join(ROOT, "docs", "ASSET_CATALOG.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")


def write_luau(c):
    def entry(k, v):
        return f'\t\t["{k}"] = "{v["rbxassetid"] or "rbxassetid://0"}",'
    L = ["--!nonstrict", "-- GENERATED by tools/art/extract_assets.py / sync_ui_assets.py — do not edit by hand.",
         "-- Image ids for UI. \"rbxassetid://0\" = not uploaded yet (upload, fill assets/catalog.json, re-run sync).",
         "-- Global = white shapes: tint with ImageColor3. Art keys = \"<folder>/<Name>\" (e.g. \"fish/BubbleCarp\", \"auras/NeonWave\").", "",
         "local UIAssets = {", "\tGlobal = {"]
    L += [entry(k, v) for k, v in c["global"].items()]
    L += ["\t},", "\tArt = {"]
    L += [entry(k, v) for k, v in c["art"].items()]
    L += ["\t},", "}", "",
          "function UIAssets.GetArt(key: string): string", "\treturn UIAssets.Art[key] or \"\"", "end", "",
          "function UIAssets.IsUploaded(id: string?): boolean", "\treturn id ~= nil and id ~= \"\" and id ~= \"rbxassetid://0\"", "end", "",
          "return UIAssets"]
    open(os.path.join(ROOT, "src", "shared", "Config", "UIAssets.luau"), "w", encoding="utf-8").write("\n".join(L) + "\n")


if __name__ == "__main__":
    main()
