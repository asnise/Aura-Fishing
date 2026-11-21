"""E1 · Gacha page — Neon Tide (opened from hub). Limited-banner VARIANT of the G1 · Aura Altar page (gacha_page.py).

Same window (860x640 at x 160, y 66), same component instances at the same positions as G1 (Reel Machine 40,96 · Rates 340,96 ·
Pity 40,486 · Roll Bar 340,486). Event-only differences: Btn Back + lilac title ribbon + timer pill in the header, lilac->sky
window tint, Rates overrides (x2 RATE UP pills, doubled odds, featured Abyssal Shadow row with gold ring), featured orb in the
reel middle, and a compact Milestones row under the Pity bar (View opens the "E1b · Milestones popup" frame next to it).

Run:   python -I docs/figma/event_banner.py docs/figma/out            (writes out/22_event_banner.json)
Send:  python -I docs/figma/event_banner.py docs/figma/out --send     (build_tree + instance patches + image fills)
Re-running replaces the section by name (an older "E1 · Event — Aura Banner" section is renamed first); placed 200px right
of "Aura Gacha — Reel Slot (FINAL)" (3492:20547, x 8900..11940, y 7400).
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
g = _load("gacha", "gacha_page.py")
img, text, v, BORDER, SOFT, ftxt, btn, tag, small_pill, chip, screen, PAGE_ID, W, H = (
    m.img, m.text, m.v, m.BORDER, m.SOFT, m.ftxt, m.btn, m.tag, m.small_pill, m.chip, m.screen, m.PAGE_ID, m.W, m.H)
RAR = m.RARITY_HEX

ROOT = os.path.dirname(os.path.dirname(_here))
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")
CHANNEL = "aura-fishing"

# Existing components (section "Gacha · Components (edit here)" 3492:20548) — same ones G1 instances
MACHINE_COMP = "3492:20553"   # Gacha / Reel Machine
RATES_COMP = "3492:20616"     # Gacha / Rates
PITY_COMP = "3492:20563"      # Gacha / Pity
ROLLBAR_COMP = "3492:20571"   # Gacha / Roll Bar
SECTION_NAME = "E1 · Gacha page — Neon Tide (opened from hub)"
SEC_X, SEC_Y = 8900 + 3040 + 200, 7400

# Banner data
PULLS, GOAL = 37, 400
PITY_LEFT = 63
RATE_UP = {"Neon Wave": "1/50", "Abyssal Shadow": "1/2,500"}   # x2 odds on this banner
FEATURED = "Abyssal Shadow"
MILESTONES = [  # pulls, image, count text, rarity, state
    (10, "ui/status/gem", "+20", "Common", "claimed"),
    (30, "ui/status/gem", "+50", "Uncommon", "claimable"),
    (50, "equipment/Shrimp", "x10", "Rare", "locked"),
    (100, "ui/status/treasure_chest", "x2", "Epic", "locked"),
    (200, "ui/status/gem", "+150", "Epic", "locked"),
    (400, "auras/AbyssalShadow", "x1", "Legendary", "locked"),
]

# geometry — identical to G1 (gacha_page.altar_window)
WIN_X, WIN_Y, WIN_W, WIN_H = 160, 66, 860, 640
MACH_X, MACH_Y = 40, 96
RATES_X, RATES_Y, RATES_W = 340, 96, 480
PITY_X, PITY_Y, PITY_W, PITY_H = 40, 486, 260, 63
ROLL_X, ROLL_Y = 340, 486
ROW_X0, ROW_Y0, ROW_W, ROW_H, ROW_STEP = 18, 50, 444, 56, 64      # Rates rows inside the instance
ROW_IDX = {"Sparkling Dew": 0, "Neon Wave": 1, "Solar Flare": 2, "Abyssal Shadow": 3, "Dragon Emperor": 4}
MSR_Y = PITY_Y + PITY_H + 8        # compact milestones row under the Pity bar
# milestones popup (E1b)
MS_W = 3 * 104 + 2 * 24
TILE, CELL_W, CELL_H = 80, 104, 100
RIBBON_W = 250

TICK = '<svg width="14" height="14" viewBox="0 0 14 14" xmlns="http://www.w3.org/2000/svg"><path d="M2.5 7.5l3 3 6-7" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>'
INFO = ('<svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg"><circle cx="8" cy="8" r="8" fill="#6BB3DE"/>'
        '<rect x="7" y="7" width="2" height="5" rx="1" fill="#FFFFFF"/><circle cx="8" cy="4.6" r="1.2" fill="#FFFFFF"/></svg>')


# ---------------------------------------------------------------- banner card pieces
def ribbon(title, w=330, h=52, face="B79CF2", lip="8C6FD6", size=26, dots=True):
    def shape(y0, col):
        return (f'<path d="M0 {y0} H{w} L{w - 16} {y0 + 23} L{w} {y0 + 46} H0 L16 {y0 + 23} Z" fill="#{col}"/>')
    dot = (f'<circle cx="34" cy="23" r="4" fill="#FFFFFF" fill-opacity="0.8"/><circle cx="{w - 34}" cy="23" r="4" fill="#FFFFFF" fill-opacity="0.8"/>'
           if dots else "")
    svg = f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg">{shape(6, lip)}{shape(0, face)}{dot}</svg>'
    return {"name": "Title Ribbon", "w": w, "h": h, "clip": False, "children": [
        {"type": "SVG", "name": "Ribbon Shape", "w": w, "h": h, "x": 0, "y": 0, "svg": svg},
        {"name": "Label Row", "layout": "H", "w": w, "h": 46, "x": 0, "y": 0, "main": "CENTER", "cross": "CENTER", "children": [
            ftxt(title, size, "FFFFFF", name="Title", textStroke="8C6FD6")]}]}


def timer_pill(t):
    return {"name": "Timer", "layout": "H", "gap": 6, "pad": [6, 14, 6, 10], "radius": 999, "cross": "CENTER", "fill": "FFFFFF", **BORDER, "children": [
        img("ui/status/auto_timer", 22), ftxt(t, 16, "E07A5C", name="Value")]}


def lock_badge(x, y):
    return {"name": "Lock", "w": 22, "h": 22, "x": x, "y": y, "radius": 999, "fill": "FFFFFF", **BORDER, "layout": "H", "main": "CENTER", "cross": "CENTER",
            "children": [m.fa_lock(11, color="7A8A99", opacity=1)]}


def milestone_cell(pulls, path, count, rarity, state, x, y):
    col = RAR[rarity]
    tx = (CELL_W - TILE) // 2
    pic = 54
    tile_kids = [img(path, pic, x=(TILE - pic) // 2, y=5), m.corner_svg(col, 26),
                 {"name": "Count Row", "layout": "H", "w": TILE, "x": 0, "y": TILE - 22, "main": "MAX", "pad": [0, 7, 0, 0],
                  "children": [ftxt(count, 14, "3D4B5C", name="Count")]}]
    effects = [{"color": "3D4B5C", "a": 0.08, "y": 4, "blur": 10}]
    fill = "FFFFFF"
    label_col = "7A8A99"
    extra = []
    if state == "claimed":
        fill = "D2F0E2"
        label_col = "4FAF8A"
        extra.append({"name": "Check", "w": 24, "h": 24, "x": tx + TILE - 18, "y": -6, "radius": 999, "fill": v("cozy/mint"), "stroke": "FFFFFF", "strokeW": 2,
                      "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [{"type": "SVG", "w": 14, "h": 14, "name": "Tick", "svg": TICK}]})
    elif state == "claimable":
        effects = effects + [{"color": "FF9E80", "a": 1, "spread": 3, "blur": 0}, {"color": "FF9E80", "a": 0.55, "spread": 2, "blur": 16}]
        label_col = "E07A5C"
        extra.append({"name": "Btn Claim", "layout": "H", "pad": [2, 10, 4, 10], "radius": 999, "x": tx + TILE // 2 - 30, "y": -11, "w": 60, "main": "CENTER",
                      "fill": v("cozy/coral"), "stroke": v("cozy/coral-lip"), "strokeSides": {"b": 3}, "children": [ftxt("CLAIM", 13, "FFFFFF", name="Label")]})
    else:  # locked
        extra.append(lock_badge(tx + TILE - 16, -6))
        if rarity == "Legendary":
            effects = [{"color": RAR["Legendary"], "a": 0.6, "spread": 1, "blur": 16}]
            label_col = "C98B1E"
    slot = {"name": "Tile", "w": TILE, "h": TILE, "x": tx, "y": 0, "radius": 18, "clip": True, "fill": fill, **BORDER, "effects": effects,
            "children": tile_kids}
    if state == "locked":
        slot["opacity"] = 0.6 if rarity != "Legendary" else 0.8
    label = {"name": "Pulls Label", "layout": "H", "w": CELL_W, "x": 0, "y": TILE + 4, "main": "CENTER", "children": [
        ftxt(f"{pulls} pulls" if state != "claimed" else "Claimed", 14, label_col, name="Value")]}
    return {"name": f"Milestone {pulls} ({state})", "w": CELL_W, "h": CELL_H, "x": x, "y": y, "clip": False, "children": [slot, label] + extra}


def progress_bar(w, h=10, name="Bar"):
    fill_w = max(h + 4, round(w * PULLS / GOAL))
    return {"name": name, "w": w, "h": h, "radius": 999, "fill": v("cozy/track"), "clip": True, "children": [
        {"type": "RECT", "name": "Fill", "w": fill_w, "h": h, "x": 0, "y": 0, "radius": 999, "fill": {"grad": ["B79CF2", "8C6FD6"]}}]}


def milestones_grid():
    gx = (MS_W - 3 * CELL_W) // 2
    cells = [milestone_cell(p, path, cnt, r, st, (i % 3) * (CELL_W + gx), (i // 3) * (CELL_H + 12) + 12)
             for i, (p, path, cnt, r, st) in enumerate(MILESTONES)]
    return {"name": "Grid", "w": MS_W, "h": 2 * CELL_H + 24, "clip": False, "children": cells}


def milestones_popup():
    """E1b — opened by the View pill of the compact Milestones row (reuses the 3x2 milestone cells)."""
    return {"name": "Milestones Popup", "layout": "V", "gap": 12, "pad": 20, "w": MS_W + 40, "radius": 28, "fill": {"grad": ["FBF7EF", "EFE6F8"], "angle": 90},
            **BORDER, "effects": SOFT, "clip": False, "children": [
                {"name": "Header", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                    {"name": "Title", "layout": "V", "gap": 0, "children": [
                        text("Pull milestones", "Title", name="Title"), text("REWARDS AT TOTAL BANNER PULLS", "Caption", "cozy/subtext", name="Hint")]},
                    btn("Danger", "X", "Btn Close")]},
                milestones_grid(),
                {"name": "Progress", "layout": "V", "gap": 6, "fillW": True, "children": [
                    {"name": "Row", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                        text("Banner pulls", "Small", "cozy/subtext", name="Label"), ftxt(f"{PULLS} / {GOAL}", 16, "8C6FD6", name="Value")]},
                    progress_bar(MS_W, 14)]}]}


def milestones_row():
    """Compact milestones strip under the Pity bar (same panel style/width as Pity)."""
    w = PITY_W
    view = {"name": "Btn View", "layout": "H", "pad": [3, 12, 4, 12], "radius": 999, "fill": v("cozy/sky"), "stroke": v("cozy/sky-lip"), "strokeSides": {"b": 3},
            "clip": False, "children": [text("View", "Caption", "cozy/on-accent", name="Label"),
                                        {"name": "Claim Dot", "w": 18, "h": 18, "radius": 999, "fill": v("cozy/coral"), "stroke": "FFFFFF", "strokeW": 2,
                                         "absolute": True, "x": 44, "y": -9, "layout": "H", "main": "CENTER", "cross": "CENTER",
                                         "children": [ftxt("1", 11, "FFFFFF", name="Count")]}]}
    return {"name": "Milestones", "layout": "V", "gap": 5, "pad": [8, 12, 10, 12], "w": w, "x": PITY_X, "y": MSR_Y, "radius": 18, "fill": v("cozy/panel"), **BORDER,
            "clip": False, "children": [
                {"name": "Row", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "clip": False, "children": [
                    {"name": "Left", "layout": "H", "gap": 6, "cross": "CENTER", "children": [
                        text("Milestones", "Small", "cozy/subtext", name="Label"), ftxt(f"{PULLS}/{GOAL}", 16, "8C6FD6", name="Value")]},
                    view]},
                progress_bar(w - 24)]}


def header():
    return {"name": "Header", "layout": "H", "w": WIN_W - 48, "x": 24, "y": 20, "main": "SPACE_BETWEEN", "cross": "CENTER", "clip": False, "children": [
        {"name": "Title", "layout": "H", "gap": 10, "cross": "CENTER", "clip": False, "children": [
            btn("Ghost", "‹", "Btn Back"), img("ui/icons/auras", 44), ribbon("Neon Tide Banner", w=RIBBON_W, size=23, dots=False)]},
        {"name": "Right", "layout": "H", "gap": 10, "cross": "CENTER", "children": [
            timer_pill("13d 05h left"), chip("Gems", "320"), btn("Danger", "X", "Btn Close")]}]}


def row_y(name):
    return RATES_Y + ROW_Y0 + ROW_IDX[name] * ROW_STEP


def rate_up_pill(name):
    """'x2 RATE UP' coral pill laid over the right side of a Rates row (left of the OWNED column)."""
    return {"name": "Rate Up " + name, "layout": "H", "gap": 4, "pad": [3, 10, 3, 8], "radius": 999, "cross": "CENTER", "x": RATES_X + 300,
            "y": row_y(name) + (ROW_H - 22) // 2, "fill": v("cozy/coral"), "stroke": v("cozy/coral-lip"), "strokeSides": {"b": 2},
            "children": [ftxt("x2", 14, "FFFFFF", name="Value"), text("RATE UP", "Caption", "cozy/on-accent", name="Label")]}


def featured_overlay():
    y = row_y(FEATURED)
    ring = {"type": "RECT", "name": "Featured Ring", "w": ROW_W + 6, "h": ROW_H + 6, "x": RATES_X + ROW_X0 - 3, "y": y - 3, "radius": 17,
            "stroke": RAR["Legendary"], "strokeW": 3, "effects": [{"color": RAR["Legendary"], "a": 0.55, "blur": 14}]}
    pill = dict(small_pill("FEATURED", "cozy/gold-lip", "Featured Pill"), x=RATES_X + ROW_X0 + 14, y=y - 11)
    return [ring, pill]


def gacha_window():
    ins = [
        {"type": "INSTANCE", "ref": MACHINE_COMP, "name": "Reel Machine", "x": MACH_X, "y": MACH_Y},
        {"type": "INSTANCE", "ref": RATES_COMP, "name": "Rates", "x": RATES_X, "y": RATES_Y},
        {"type": "INSTANCE", "ref": PITY_COMP, "name": "Pity", "x": PITY_X, "y": PITY_Y, "texts": {"Value": f"{PITY_LEFT} rolls"}},
        {"type": "INSTANCE", "ref": ROLLBAR_COMP, "name": "Roll Bar", "x": ROLL_X, "y": ROLL_Y},
    ]
    return {"name": "Neon Tide Altar", "w": WIN_W, "h": WIN_H, "x": WIN_X, "y": WIN_Y, "radius": 32, "fill": {"grad": ["F3ECFC", "DDEFFA"], "angle": 90}, **BORDER,
            "effects": SOFT, "clip": True, "children": [
                g.rays(700, "9C86E8", 16, 0.13, x=-120, y=-110),
                g.rays(520, "6BB3DE", 12, 0.10, x=WIN_W - 300, y=WIN_H - 300),
                header()] + ins + [rate_up_pill("Neon Wave"), rate_up_pill(FEATURED)] + featured_overlay() + [milestones_row()]}


NOTE = ("Limited-banner VARIANT of G1 · Aura Altar — same window, same Reel Machine / Rates / Pity / Roll Bar instances at the same positions. "
        "Opened by OPEN on the Neon Tide card in the E0 Events hub; Btn Back returns to the hub, X closes everything. Differences: lilac title ribbon + "
        "countdown pill, lilac->sky tint, Neon Wave and Abyssal Shadow at x2 odds (1/50, 1/2,500) with RATE UP pills, featured Abyssal Shadow revealed "
        "(gold ring + FEATURED) and centred in the reel, own Mythic pity counter, compact Milestones row (37/400, red dot = claimable) whose View pill opens "
        "E1b. Rolls use the same G2-G6 reel/reveal flow and prices (ROLL x1 = 5, x10 = 45).")
FRAME_NAME = "Gacha Page - Neon Tide"
POPUP_FRAME = "E1b · Milestones popup"
OLD_SECTION_NAMES = ["E1 · Event — Aura Banner"]


def build():
    fr = screen(FRAME_NAME, [g.dim(0.35), gacha_window()])
    fr.update({"x": 60, "y": 110})
    px = 60 + W + 80
    popup = {"name": POPUP_FRAME, "w": MS_W + 120, "h": 520, "x": px, "y": 110, "radius": 24, "fill": {"hex": "1A2140", "opacity": 0.55}, "children": [
        dict(milestones_popup(), x=40, y=40)]}
    sec = {"type": "SECTION", "name": SECTION_NAME, "fill": "FBF7EF", "w": px + MS_W + 120 + 60, "h": H + 260, "x": SEC_X, "y": SEC_Y, "children": [
        text(SECTION_NAME, "Display", name="Title", x=60, y=30), fr, popup,
        text("E1b · Milestones popup (View)", "Heading", "cozy/subtext", name="Popup Label", x=px, y=80),
        text(NOTE, "Body", "cozy/subtext", name="Note", w=W, x=60, y=110 + H + 30)]}
    return {"pageId": PAGE_ID, "replaceName": SECTION_NAME, "tree": sec}


# ---------------------------------------------------------------- send + post patches
def call(cmd, params, timeout=300, tries=3):
    for i in range(tries):
        try:
            return _call(cmd, params, timeout)
        except SystemExit:
            if i == tries - 1:
                raise


def _call(cmd, params, timeout):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(params, f)
    try:
        r = subprocess.run(["node", RUN, f"--channel={CHANNEL}", cmd, f.name, f"--timeout={timeout}"], capture_output=True, text=True, encoding="utf-8")
    finally:
        os.unlink(f.name)
    if r.returncode != 0:
        raise SystemExit(f"{cmd} failed: {r.stderr.strip() or r.stdout.strip()}")
    return json.loads(r.stdout)


def find(node, pred, out=None):
    out = [] if out is None else out
    if pred(node):
        out.append(node)
    for c in node.get("children") or []:
        find(c, pred, out)
    return out


def rename_old_sections(old_names, new_name):
    """Older runs used another section name: rename it so build_tree's replaceName swaps it in place (no duplicates)."""
    doc = call("get_document_info", {})
    for ch in doc.get("children", []):
        if ch["name"] in old_names:
            call("rename_node", {"nodeId": ch["id"], "name": new_name})


def _b64(path, size=256):
    fi = _load("figma_images", os.path.join("..", "..", "tools", "art", "figma_images.py"))
    return fi.b64(path, size)


def send(spec):
    rename_old_sections(OLD_SECTION_NAMES, SECTION_NAME)
    res = call("build_tree", spec)
    root = res["rootId"]
    print("section", root)
    r = subprocess.run([sys.executable, "-I", os.path.join(ROOT, "tools", "art", "figma_images.py"), "--channel", CHANNEL, "--root", root],
                       capture_output=True, text=True, encoding="utf-8")
    print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else r.stderr)
    tree = call("get_node_info", {"nodeId": root})
    frame = find(tree, lambda n: n["name"] == FRAME_NAME)[0]
    # instance overrides (same components as G1, event data on top)
    mach = find(frame, lambda n: n["name"] == "Reel Machine" and n["type"] == "INSTANCE")[0]
    orbs = find(mach, lambda n: n["name"].startswith("Img auras/"))
    call("set_image_fill", {"nodeId": orbs[1]["id"], "imageBase64": _b64("auras/AbyssalShadow"), "scaleMode": "FIT"})
    rates = find(frame, lambda n: n["name"] == "Rates" and n["type"] == "INSTANCE")[0]
    for name, odds in RATE_UP.items():
        row = find(rates, lambda n: n["name"] == "Rate " + name)[0]
        ch = find(row, lambda n: n["name"] == "Chance" and n["type"] == "TEXT")[0]
        call("set_text_content", {"nodeId": ch["id"], "text": odds})
        call("patch_nodes", {"patches": [{"id": ch["id"], "fill": "E07A5C"}]})
    row = find(rates, lambda n: n["name"] == "Rate " + FEATURED)[0]
    nm = find(row, lambda n: n["name"] == "Name" and n["type"] == "TEXT")[0]
    call("set_text_content", {"nodeId": nm["id"], "text": FEATURED})
    call("patch_nodes", {"patches": [{"id": nm["id"], "fill": "3D4B5C"}]})
    orb = find(row, lambda n: n["name"].startswith("Img auras/"))[0]
    call("set_image_fill", {"nodeId": orb["id"], "imageBase64": _b64("auras/AbyssalShadow"), "scaleMode": "FIT"})
    popup = find(tree, lambda n: n["name"] == POPUP_FRAME)[0]
    print("frame", frame["id"], "popup", popup["id"])
    return root, frame["id"]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else os.path.join(_here, "out")
    spec = build()
    path = os.path.join(out, "22_event_banner.json")
    json.dump(spec, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("written", path)
    if "--send" in sys.argv:
        send(spec)
