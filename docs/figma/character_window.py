"""Character window (new, user request 2026-11-17): swap owned equipment without going through the Shop.
Same 760x610 window as Shop / Auras. Left: avatar preview (ViewportFrame) + the 5 equipped slots
(Rod, Line, Bag, Bait, Aura) + total stats. Right: category tabs, grid of OWNED items (equipped one has
the coral tick), detail card comparing the selected item with the equipped one + EQUIP.
Opened from the Main Menu hub (new "Character" tile) and key C. Data = Config/Equipment + profile.Owned/Equipped.

Run:  python -I docs/figma/character_window.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/21_character_ops.json
Then: python -I tools/art/figma_images.py --root <built id>
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))


def _load(name, file):
    s = importlib.util.spec_from_file_location(name, os.path.join(_here, file))
    mod = importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod


m = _load("menus", "cozy_menus_spec.py")
eh = _load("economy_hud", "economy_hud.py")
v, text, BORDER, SOFT, PAGE_ID = m.v, m.text, m.BORDER, m.SOFT, m.PAGE_ID
btn, img, ftxt, item_slot = m.btn, m.img, m.ftxt, m.item_slot
WIN_W, WIN_H = m.WIN_W, m.WIN_H

LEFT_W, RIGHT_W = 250, 450   # 760 - 2*20 pad - 20 gap

# owned items per tab (sample profile): (art key, rarity, equipped, count)
OWNED = {
    "Rods": [("DriftwoodRod", "Common"), ("BambooRod", "Uncommon"), ("CoralRod", "Rare"), ("MoonsilverRod", "Epic")],
    "Lines": [("CottonLine", "Common"), ("HempLine", "Uncommon"), ("NylonLine", "Rare")],
    "Bags": [("StarterPouch", "Common"), ("WovenBasket", "Uncommon"), ("Crate", "Rare")],
    "Baits": [("Worm", "Common"), ("Shrimp", "Uncommon")],
}


def tab(label, active=False):
    return {"name": "Tab " + label, "layout": "H", "pad": [7, 14, 7, 14], "radius": 999,
            "fill": v("cozy/coral") if active else v("cozy/sand"), **({} if active else BORDER),
            "children": [text(label, "Heading", "cozy/on-accent" if active else "cozy/subtext", name="Label")]}


def equip_slot(label, key, rarity="Common", count=None):
    s = item_slot(key, rarity, count or 1, size=56, name="Slot")
    if not count:  # hide the x1 counter on permanent items
        s["children"][0]["children"] = [c for c in s["children"][0]["children"] if c.get("name") != "Count Row"]
    return {"name": "Equip " + label, "layout": "V", "gap": 4, "cross": "CENTER", "children": [s, text(label.upper(), "Caption", "cozy/subtext", name="Label")]}


def avatar():
    kids = eh.player(LEFT_W // 2, 96, vip=True)
    kids[0].update(w=66, h=129, x=LEFT_W // 2 - 33)   # bigger figure
    for c, (w, h, x, y) in zip(kids[0]["children"], [(45, 45, 10, 0), (54, 60, 6, 45), (42, 27, 12, 102)]):
        c.update(w=w, h=h, x=x, y=y)
    kids[1]["y"] = 40
    kids.append(dict(text("drag to spin", "Caption", "cozy/subtext", name="Hint"), x=LEFT_W // 2 - 38, y=236))
    return {"name": "Avatar (ViewportFrame)", "w": LEFT_W, "h": 256, "radius": 18, "clip": True,
            "fill": {"grad": ["DDF5EE", "A8DCD8"], "angle": 90}, **BORDER, "children": [
                {"type": "ELLIPSE", "name": "Stand", "w": 150, "h": 30, "x": LEFT_W // 2 - 75, "y": 214, "fill": v("cozy/mint", 0.45)}] + kids}


def stat_line(label, value, color="cozy/text"):
    return {"name": "Stat " + label, "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "children": [
        text(label, "Small", "cozy/subtext", name="Label"), text(value, "Small", color, name="Value")]}


def left_col():
    return {"name": "Loadout", "layout": "V", "gap": 12, "w": LEFT_W, "children": [
        avatar(),
        {"name": "Equipped", "layout": "H", "gap": 8, "main": "CENTER", "fillW": True, "children": [
            equip_slot("Rod", "equipment/CoralRod", "Rare"), equip_slot("Line", "equipment/NylonLine", "Rare"),
            equip_slot("Bag", "equipment/Crate", "Rare"), equip_slot("Bait", "equipment/Worm", "Common", 23)]},
        {"name": "Totals", "layout": "V", "gap": 2, "pad": [10, 14, 10, 14], "radius": 16, "fill": v("cozy/sand"), "fillW": True, "children": [
            stat_line("Luck", "+25%"), stat_line("Reel Power", "+30%"), stat_line("Max Depth", "150m"), stat_line("Bag", "15 slots")]}]}


def grid(cat="Rods", equipped="CoralRod", selected="MoonsilverRod"):
    cells = []
    for key, rar in OWNED[cat]:
        st = "selected" if key == equipped else None
        s = item_slot("equipment/" + key, rar, 1, size=96, state=st, name=key)
        slot = s["children"][0]
        slot["children"] = [c for c in slot["children"] if c.get("name") != "Count Row"]
        if key == selected:
            slot["stroke"], slot["strokeW"] = v("cozy/sky-lip"), 3
        cells.append(s)
    cells.append(dict(item_slot(None, size=96, state="empty", name="Get More"), name="Btn Get More"))
    rows = [cells[i:i + 4] for i in range(0, len(cells), 4)]
    return {"name": "Grid", "layout": "V", "gap": 12, "pad": [6, 0, 0, 0], "h": 222, "children": [
        {"name": f"Row {i + 1}", "layout": "H", "gap": 12, "children": r} for i, r in enumerate(rows)]}


def compare(label, a, b, new=False):
    up = {"name": "To", "layout": "H", "gap": 4, "cross": "CENTER", "children": [
        text("→", "Small", "cozy/subtext", name="Arrow"), text(b, "Small", "cozy/mint-lip", name="Value")]}
    return {"name": "Cmp " + label, "layout": "H", "gap": 8, "fillW": True, "cross": "CENTER", "children": [
        text(label, "Small", "cozy/subtext", name="Label", w=78), text("—" if new else a, "Small", "cozy/text", name="From"), up]}


def detail():
    return {"name": "Detail", "layout": "H", "gap": 12, "pad": 12, "radius": 18, "fill": v("cozy/sand"), "fillW": True, "cross": "CENTER", "children": [
        {"name": "Picture", "w": 64, "h": 64, "radius": 16, "fill": "FFFFFF", **BORDER, "layout": "H", "main": "CENTER", "cross": "CENTER",
         "children": [img("equipment/MoonsilverRod", 56)]},
        {"name": "Info", "layout": "V", "gap": 3, "fillW": True, "children": [
            {"name": "Title Row", "layout": "H", "gap": 8, "cross": "CENTER", "children": [
                text("Moonsilver Rod", "Heading", "cozy/rarity/epic", name="Title")]},
            compare("Luck", "+15%", "+35%"), compare("Reel Power", "+30%", "+50%"), compare("Auto Speed", "", "+10%", new=True)]},
        btn("Success", "EQUIP", "Btn Equip")]}


def window(x=260, y=70):
    body = {"name": "Body", "layout": "H", "gap": 20, "fillW": True, "children": [
        left_col(),
        {"name": "Items", "layout": "V", "gap": 12, "w": RIGHT_W, "children": [
            {"name": "Tabs", "layout": "H", "gap": 8, "children": [tab("Rods", True), tab("Lines"), tab("Bags"), tab("Baits")]},
            grid(), detail()]}]}
    return m.window("Character", WIN_W, x, y, [body], h=WIN_H)


def states():
    """Detail card for the equipped item and for a bait stack."""
    eq = detail()
    eq["name"] = "Detail · Equipped"
    eq["children"][0]["children"] = [img("equipment/CoralRod", 56)]
    info = eq["children"][1]
    info["children"][0]["children"] = [text("Coral Rod", "Heading", "cozy/rarity/rare", name="Title")]
    info["children"][1:] = [text("Luck +15%  •  Reel Power +30%  •  Catch Bar +5%  •  Resilience +15%", "Small", "cozy/subtext", name="Stats", w=200)]
    eq["children"][2] = btn("Ghost", "EQUIPPED", "Btn Equip")
    bait = detail()
    bait["name"] = "Detail · Bait"
    bait["children"][0]["children"] = [img("equipment/Shrimp", 56)]
    info = bait["children"][1]
    info["children"][0]["children"] = [text("Shrimp  x40", "Heading", "cozy/rarity/uncommon", name="Title")]
    info["children"][1:] = [compare("Luck", "+10%", "+30%"), compare("Bite Speed", "", "+10%", new=True),
                            text("1 used per catch", "Caption", "cozy/subtext", name="Note")]
    for d in (eq, bait):
        d["w"] = RIGHT_W
        d.pop("fillW", None)
    return [eq, bait]


def hub_tile():
    """New Main Menu hub tile: player headshot (falls back to the Pip art) like the hub avatar."""
    t = m.hub_tile("Character", "sky")
    return t


def build():
    scr = m.screen("Character", [window()], dim=True)
    frame = {"name": "Screen", "layout": "V", "gap": 12, "x": 60, "y": 110, "children": [text("17 · Character", "Title", name="Title"), scr]}
    notes = {"name": "Notes", "layout": "V", "gap": 16, "pad": 24, "w": 520, "radius": 24, "x": 1400, "y": 150,
             "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                 text("How it works", "Title", name="Title"),
                 text("• Open: Main Menu hub tile \"Character\", key C, or tap a slot on the HUD later.\n"
                      "• Left: avatar preview (ViewportFrame, drag to spin) wearing the current rod; tap an equipped slot to jump to its tab.\n"
                      "• Right: only OWNED items. Coral tick = equipped, blue border = selected. Last cell \"+\" opens the Shop on that tab.\n"
                      "• Detail compares the selected item with the equipped one (name in rarity colour, mint = better). EQUIP swaps instantly; equipped item shows EQUIPPED.\n"
                      "• Baits show the stack count; the bait slot can also be emptied (UNEQUIP).\n"
                      "• Aura stays in the Auras window (its own equip flow).", "Body", name="Rules", w=472),
                 text("Detail states", "Heading", name="Sub"),
                 *states()]}
    sec = {"type": "SECTION", "name": "17 · Character (equipment swap)", "fill": "F3E9D8", "x": 14400, "y": 1800, "children": [
        text("17 · Character — swap equipment", "Display", name="Title", x=60, y=40), frame, notes]}
    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "21_character_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
