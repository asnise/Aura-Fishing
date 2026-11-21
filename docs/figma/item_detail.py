"""18 · Item Detail Card + Inventory v2 (user request 2026-11-18).

Item Detail Card = one popover for every item kind (fish, rod, line, aura, bait, treasure, material).
Code calls ItemDetail.Show(itemId, anchor) with any GuiObject (inventory slot, Character slot, Shop picture,
Fishdex card, catch card ...). The card opens next to the anchor (right side, flips to the left when there is
no room) with a small nub pointing at it. Owned -> "Actions" container with that kind's buttons.
Not owned -> no Actions, only a "Get from" info line.

Inventory v2: same 760x610 window as Shop / Auras. Category tabs move from the top row to an icon rail on the
left (art ui/tabs/*, prompts in sheet 17). Rods / Lines / Auras become inventory items. Bags are no longer
items: capacity is an upgrade ladder (UPGRADE next to the capacity pill), you never go back to a smaller bag.

Run:  python -I docs/figma/item_detail.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/23_item_detail_ops.json
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
es = _load("economy_screens", "economy_screens.py")
v, text, BORDER, SOFT, PAGE_ID = m.v, m.text, m.BORDER, m.SOFT, m.PAGE_ID
btn, tag, img, ftxt, item_slot = m.btn, m.tag, m.img, m.ftxt, m.item_slot
WIN_W, WIN_H, SAFE_TOP, W, H = m.WIN_W, m.WIN_H, m.SAFE_TOP, m.W, m.H
RAR = m.RARITY_HEX
lip_btn, two_line_btn, info_pill, vec, stars, board = es.lip_btn, es.two_line_btn, es.info_pill, es.vec, es.stars, es.board

SEC_X, SEC_Y = 14400, 3000
CARD_W = 300
WX = (W - WIN_W) // 2            # 260
RAIL_W, SLOT, GAP = 64, 80, 10
GRID_X = WX + 20 + RAIL_W + 16   # 360: first slot column (screen coords)
GRID_Y = SAFE_TOP + 20 + 44 + 14 + 32 + 12 + 8   # 200: first slot row
PANEL_HEX, TRACK_HEX = "FFF8EC", "E6DCCB"

TABS = [("all", "All"), ("fish", "Fish"), ("rods", "Rods"), ("lines", "Lines"), ("auras", "Auras"),
        ("baits", "Baits"), ("treasure", "Treasure"), ("materials", "Materials")]


# ================================================================ small parts
def badge(t, fill=None, fg=None):
    return {"name": "Badge " + t, "layout": "H", "pad": [3, 10, 4, 10], "radius": 999, "fill": fill or v("cozy/sand"),
            "children": [text(t, "Caption", fg or ("cozy/on-accent" if fill else "cozy/text"), name="Label")]}


def stat_badges(stats):
    """stats: list of (label, highlight). Highlighted (Auto Wait) = gold, always first (Format.Stat + StatDefs.Highlight)."""
    items = sorted(stats, key=lambda s: not s[1])
    return {"name": "Stats", "layout": "H", "wrap": True, "gap": 6, "rowGap": 6, "w": CARD_W - 32, "children": [
        badge(t, v("cozy/gold") if hi else None) for t, hi in items]}


def nub(side="left", y=34):
    """Little triangle that points at the anchor. side = which edge of the card it sits on."""
    path = "M12 0 L0 10 L12 20" if side == "left" else "M0 0 L12 10 L0 20"
    fillp = path + " Z"
    svg = (f'<svg width="12" height="20" viewBox="0 0 12 20" xmlns="http://www.w3.org/2000/svg">'
           f'<path d="{fillp}" fill="#{PANEL_HEX}"/><path d="{path}" stroke="#{TRACK_HEX}" stroke-width="2" fill="none" stroke-linejoin="round"/></svg>')
    return {"type": "SVG", "name": "Nub " + side, "svg": svg, "w": 12, "h": 20, "absolute": True,
            "x": -10 if side == "left" else CARD_W - 2, "y": y}


def picture(key, rarity, locked=False, size=72):
    col = RAR.get(rarity, "9AA5B1")
    p = round(size * 0.83)
    o = (size - p) // 2
    kids = [img(key, p, x=o, y=o, **({"opacity": 0.35} if locked else {})), m.corner_svg(col, round(size / 3))]
    if locked:
        lh = round(size * 0.36)
        kids.append(m.fa_lock(lh, x=round((size - lh * 448 / 512) / 2), y=(size - lh) // 2))
    return {"name": "Picture", "w": size, "h": size, "radius": round(size / 4), "clip": True, "fill": "FFFFFF", **BORDER, "children": kids}


def lighten(hexs, t=0.75):
    r, g, b = (int(hexs[i:i + 2], 16) for i in (0, 2, 4))
    return "".join(f"{round(c + (255 - c) * t):02X}" for c in (r, g, b))


def actions(buttons):
    return {"name": "Actions", "layout": "V", "gap": 8, "pad": [12, 0, 0, 0], "fillW": True, "stroke": v("cozy/track"), "strokeSides": {"t": 2},
            "children": [{"name": "Buttons", "layout": "H", "gap": 8, "fillW": True, "children": buttons}]}


def act(label, style="mint", key=None, value=None, w=None, disabled=False):
    """Lip button: one line, or label + cost when key/value given. fillW unless w given."""
    if key:
        b = two_line_btn(label, key, value, style, w=w or 120, disabled=disabled)
    else:
        b = lip_btn("Btn " + label.title(), [ftxt(label, 16, "9AA5B1" if disabled else "FFFFFF", name="Label")], style, w, disabled=disabled)
    if not w:
        b["fillW"] = True
        b.pop("w", None)
    return b


def icon_btn(name, kind, style="sky"):
    return lip_btn("Btn " + name, [vec(kind, "FFFFFF", 22)], style, w=52, pad=(8, 8, 11, 8))


def modifiers(n=3):
    """Rods only (future): empty modifier sockets, locked until the Modifier system ships."""
    sockets = [{"name": f"Socket {i + 1}", "w": 36, "h": 36, "radius": 999, "fill": v("cozy/sand"), "stroke": v("cozy/track"), "strokeW": 2,
                "dashes": [4, 3], "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [m.fa_lock(14, opacity=0.45)]} for i in range(n)]
    return {"name": "Modifiers", "layout": "H", "gap": 8, "fillW": True, "cross": "CENTER", "children": [
        text("Modifiers", "Small", "cozy/subtext", name="Label"), *sockets,
        {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, info_pill("Soon", "cozy/subtext", "cozy/sand")]}


def source_line(label, key=None):
    """Not owned: where to get it. Info only, never a button."""
    kids = ([img(key, 18)] if key else []) + [text(label, "Small", "cozy/subtext", name="Label")]
    return {"name": "Get From", "layout": "H", "gap": 6, "pad": [10, 0, 0, 0], "fillW": True, "cross": "CENTER",
            "stroke": v("cozy/track"), "strokeSides": {"t": 2}, "children": [text("Get from", "Caption", "cozy/subtext", name="Title"), *kids]}


def card(name, key, title, rarity, kind, stats, desc=None, pills=(), extra=(), action=None, source=None, n_stars=None,
         locked=False, nub_side="left", nub_y=34, x=None, y=None):
    head_info = [text(title, "Heading", "cozy/rarity/" + rarity.lower() if rarity != "Bait" else "cozy/gold-lip", name="Name"),
                 {"name": "Tags", "layout": "H", "gap": 6, "cross": "CENTER", "children": [
                     tag(rarity) if rarity != "Bait" else badge("Bait", v("cozy/gold")), badge(kind)]}]
    if n_stars is not None:
        head_info.append(stars(n_stars, 14))
    kids = [{"name": "Head", "layout": "H", "gap": 12, "fillW": True, "cross": "CENTER", "children": [
        picture(key, rarity, locked), {"name": "Info", "layout": "V", "gap": 4, "fillW": True, "children": head_info}]}]
    if stats:
        kids.append(stat_badges(stats))
    if desc:
        kids.append(text(desc, "Small", "cozy/subtext", name="Desc", w=CARD_W - 32))
    if pills:
        kids.append({"name": "Meta", "layout": "H", "gap": 6, "wrap": True, "rowGap": 6, "w": CARD_W - 32, "children": list(pills)})
    kids += list(extra)
    if action:
        kids.append(actions(action))
    elif source:
        kids.append(source)
    d = {"name": "Item Card · " + name, "layout": "V", "gap": 10, "pad": 16, "w": CARD_W, "radius": 22, "clip": False,
         "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": kids + ([nub(nub_side, nub_y)] if nub_side else [])}
    if x is not None:
        d["x"], d["y"] = x, y
    return d


EQUIPPED = info_pill("Equipped", "cozy/on-accent", "cozy/mint")


# ================================================================ card per kind (owned / not owned)
def c_rod_owned(**kw):
    return card("Rod (owned)", "equipment/MoonsilverRod", "Moonsilver Rod", "Epic", "Rod",
                [("+35% Luck", False), ("+50% Reel Power", False), ("+8% Catch Bar", False), ("-10% Auto Wait", True)],
                "Forged from moonlight. Steady in deep water.", pills=[info_pill("+2", "cozy/gem-lip", "cozy/panel", img("ui/status/enhance", 16))],
                extra=[modifiers()], action=[act("EQUIP", "mint"), act("ENHANCE", "gold", "ui/status/enhance", "4", w=118)], **kw)


def c_rod_equipped(**kw):
    return card("Rod (equipped)", "equipment/CoralRod", "Coral Rod", "Rare", "Rod",
                [("+15% Luck", False), ("+30% Reel Power", False), ("+5% Catch Bar", False), ("+15% Resilience", False)],
                pills=[EQUIPPED], extra=[modifiers()], action=[act("EQUIPPED", "mint", disabled=True), act("ENHANCE", "gold", "ui/status/enhance", "2", w=118)], **kw)


def c_line(**kw):
    return card("Line (owned)", "equipment/NylonLine", "Nylon Line", "Rare", "Line", [("150m depth", False), ("+5% Resilience", False)],
                action=[act("EQUIP", "mint"), act("ENHANCE", "gold", "ui/status/enhance", "2", w=118)], **kw)


def c_aura(**kw):
    return card("Aura (owned)", "auras/SolarFlare", "Solar Flare", "Epic", "Aura", [("+35% Luck", False), ("+10% Sun-Forged", False)],
                n_stars=2, pills=[info_pill("1 / 750", "cozy/subtext", "cozy/sand")],
                action=[act("EQUIP", "mint"), act("STAR UP", "sky", "ui/status/star_token", "3", w=118)], **kw)


def c_fish(**kw):
    return card("Fish (owned)", "fish/BubbleCarp", "Bubble Carp", "Common", "Fish", [],
                pills=[info_pill("x41", "cozy/text", "cozy/sand"), info_pill("2.7 kg", "cozy/subtext", "cozy/sand"),
                       info_pill("HOT x3", "cozy/on-accent", "cozy/danger", es.eh.flame(12))],
                action=[act("SELL", "gold", "ui/status/coin", "1.2k", w=None), act("TANK", "sky"), icon_btn("Lock", "icon_lock", "coral")], **kw)


def c_bait(**kw):
    return card("Bait (owned)", "equipment/Shrimp", "Shrimp", "Bait", "Bait", [("+30% Luck", False), ("+10% Bite Speed", False)],
                "1 used per catch.", pills=[info_pill("x40", "cozy/text", "cozy/sand")], action=[act("EQUIP", "mint")], **kw)


def c_treasure(**kw):
    return card("Treasure (owned)", "ui/status/treasure_chest", "Tide Chest", "Epic", "Treasure", [],
                "Coins, gems or a material inside.", pills=[info_pill("x2", "cozy/text", "cozy/sand")],
                action=[act("OPEN", "coral"), act("OPEN ALL", "coral")], **kw)


def c_material(**kw):
    return card("Material (owned)", "materials/enhance_stone", "Enhance Stone", "Rare", "Material", [],
                "Used to Enhance rods and lines.", pills=[info_pill("x4", "cozy/text", "cozy/sand")], action=[act("GO TO ENHANCE", "sky")], **kw)


def c_not_owned_rod(**kw):
    return card("Rod (not owned)", "equipment/NagaScaleRod", "Naga Scale Rod", "Legendary", "Rod",
                [("+60% Luck", False), ("+80% Reel Power", False), ("-20% Auto Wait", True)],
                source=source_line("Shop  ·  Lv.20  ·  450,000", "ui/status/coin"), **kw)


def c_not_owned_aura(**kw):
    return card("Aura (not owned)", "auras/DragonEmperor", "Dragon Emperor", "Mythic", "Aura", [("+100% Luck", False), ("+30% Stability", False), ("+25% Golden", False)],
                pills=[info_pill("1 / 50,000", "cozy/subtext", "cozy/sand")], locked=True,
                source=source_line("Aura Altar roll", "ui/icons/auras"), **kw)


# ================================================================ Inventory v2
def rail(active="rods", hover=None):
    tiles = []
    for key, label in TABS:
        on = key == active
        t = {"name": "Tab " + label, "w": 48, "h": 48, "radius": 14, "clip": False, "fill": "FFFFFF" if on else v("cozy/sand"),
             "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [img("ui/tabs/" + key, 36, fill={"hex": "E5DBFA", "opacity": 0.6})]}
        if on:
            t["effects"] = [{"color": "FF9E80", "a": 1, "spread": 3, "blur": 0}]
        else:
            t.update(BORDER)
        if key == "fish":
            t["children"].append(dict(m.small_pill("3", "cozy/danger", "Dot"), absolute=True, x=32, y=-6))
        if key == hover:
            t["children"].append({"name": "Tooltip", "absolute": True, "x": 58, "y": 8, "layout": "H", "pad": [5, 12, 6, 12], "radius": 999,
                                  "fill": v("cozy/text"), "children": [text(label, "Caption", "cozy/on-accent", name="Label")]})
        tiles.append(t)
    return {"name": "Tab Rail", "layout": "V", "gap": 8, "pad": 8, "w": RAIL_W, "radius": 18, "fill": v("cozy/sand", 0.6), "cross": "CENTER",
            "clip": False, "children": tiles}


def grid(cells):
    rows = [cells[i:i + 7] for i in range(0, len(cells), 7)]
    return {"name": "Grid [scroll]", "layout": "V", "gap": 12, "pad": [8, 0, 0, 0], "h": 372, "w": 7 * SLOT + 6 * GAP, "clip": False, "children": [
        {"name": f"Row {i + 1}", "layout": "H", "gap": GAP, "clip": False, "children": r} for i, r in enumerate(rows)]}


def slot(key, rarity, count=None, state=None, mut=None, name=None, ring=False):
    s = item_slot(key, rarity, count or 1, size=SLOT, state=state, mut=mut, name=name or (key.split("/")[-1] if key else "Empty"))
    if not count:
        s["children"][0]["children"] = [c for c in s["children"][0]["children"] if c.get("name") != "Count Row"]
    if ring:  # opened in the Item Card
        s["children"][0]["stroke"], s["children"][0]["strokeW"] = v("cozy/sky-lip"), 3
    return s


def inventory_window(tab_label, count_label, cells, active, hover=None, footer=None):
    cap = {"name": "Capacity", "layout": "H", "gap": 8, "pad": [4, 4, 4, 12], "radius": 999, "cross": "CENTER", "fill": v("cozy/sand"), "children": [
        img("ui/icons/bag", 22), ftxt("18", 18, "3D4B5C", name="Used"), ftxt("/ 30", 18, "9AA5B1", name="Max"),
        lip_btn("Btn Upgrade Bag", [vec("icon_arrow_up", "FFFFFF", 14), ftxt("UPGRADE", 13, "FFFFFF", name="Label")], "gold", pad=(4, 10, 7, 10))]}
    header = {"name": "Header", "layout": "H", "gap": 12, "fillW": True, "cross": "CENTER", "children": [
        text("Inventory", "Title", name="Title"), cap, {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, btn("Danger", "X", "Btn Close")]}
    sub = {"name": "Sub Header", "layout": "H", "gap": 10, "h": 32, "fillW": True, "cross": "CENTER", "children": [
        text(tab_label, "Heading", name="Category"), info_pill(count_label), {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        btn("Ghost", "Sort: Rarity", "Btn Sort")]}
    right = {"name": "Content", "layout": "V", "gap": 12, "fillW": True, "clip": False, "children": [sub, grid(cells)] + ([footer] if footer else [])}
    body = {"name": "Body", "layout": "H", "gap": 16, "fillW": True, "clip": False, "children": [rail(active, hover), right]}
    return {"name": "Window Inventory", "layout": "V", "pad": 20, "gap": 14, "w": WIN_W, "h": WIN_H, "x": WX, "y": SAFE_TOP, "radius": 24, "clip": False,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [header, body]}


def slot_pos(col, row):
    return GRID_X + col * (SLOT + GAP), GRID_Y + row * (SLOT + 12)


def screen_rods():
    cells = [slot("equipment/DriftwoodRod", "Common"), slot("equipment/BambooRod", "Uncommon"), slot("equipment/CoralRod", "Rare", state="selected"),
             slot("equipment/MoonsilverRod", "Epic", ring=True), slot("equipment/SweetheartRod", "Rare", state="new"),
             dict(slot(None, "Common", state="empty", name="Get More"), name="Btn Get More")]
    sx, sy = slot_pos(3, 0)
    c = c_rod_owned(nub_side="left", nub_y=30, x=sx + SLOT + 14, y=sy - 6)
    return m.screen("Inventory · Rods", [m.stats_card(), inventory_window("Rods", "5 owned", cells, "rods"), c], dim=True)


AURAS = [("SparklingDew", "Common", "selected"), ("NeonWave", "Uncommon", None), ("SolarFlare", "Epic", None), ("TidalBloom", "Rare", "new"),
         ("CoralHeart", "Rare", None), ("AbyssalShadow", "Legendary", "locked"), ("DragonEmperor", "Mythic", "locked"),
         ("MoonlitRipple", "Uncommon", None), ("KelpWhisper", "Common", None), ("StormCurrent", "Epic", "locked"), ("FrostPearl", "Rare", "locked"),
         ("SerpentOfTheVoid", "Mythic", "locked"), ("NebulaKoi", "Legendary", "locked"), ("CelestialLeviathan", "Mythic", "locked")]


def screen_auras():
    cells = [slot("auras/" + k, r, state=st, ring=(k == "DragonEmperor")) for k, r, st in AURAS]
    sx, sy = slot_pos(6, 0)
    c = c_not_owned_aura(nub_side="right", nub_y=30, x=sx - CARD_W - 14, y=sy - 6)
    foot = {"name": "Footer", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        text("8 / 19 found", "Small", "cozy/subtext", name="Found"), {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        lip_btn("Btn Roll", [img("ui/icons/auras", 22), ftxt("ROLL AURA", 16, "FFFFFF", name="Label")], "sky")]}
    win = inventory_window("Auras", "8 owned", cells, "auras", hover="treasure", footer=foot)
    return m.screen("Inventory · Auras", [m.stats_card(), win, c], dim=True)


BAGS = [("StarterPouch", 6), ("WovenBasket", 10), ("Crate", 15), ("Coolbox", 20), ("Hold", 30), ("BottomlessBag", 50)]


def bag_modal():
    cur = 4
    steps = []
    for i, (k, cap) in enumerate(BAGS):
        state = "done" if i < cur else ("now" if i == cur else ("next" if i == cur + 1 else "later"))
        tile = {"name": "Tier " + k, "layout": "V", "gap": 4, "cross": "CENTER", "w": 72, "children": [
            {"name": "Pic", "w": 64, "h": 64, "radius": 16, "fill": "FFFFFF" if state in ("now", "next") else v("cozy/sand"), **BORDER,
             "opacity": 0.5 if state == "later" else 1, "layout": "H", "main": "CENTER", "cross": "CENTER",
             **({"effects": [{"color": "FF9E80", "a": 1, "spread": 3, "blur": 0}]} if state == "now" else {}),
             "children": [img("equipment/" + k, 52)]},
            ftxt(str(cap), 15, "3D4B5C" if state != "later" else "9AA5B1", name="Slots")]}
        steps.append(tile)
    body = [img("ui/tabs/bag_upgrade", 88, fill={"hex": "E5DBFA", "opacity": 0.6}),
            text("Upgrade Bag", "Title", name="Title", align="CENTER", w=520),
            {"name": "Change", "layout": "H", "gap": 10, "cross": "CENTER", "children": [
                ftxt("30 slots", 26, "3D4B5C", name="From"), text("→", "Title", "cozy/subtext", name="Arrow"), ftxt("50 slots", 26, "4FB58C", name="To")]},
            {"name": "Ladder", "layout": "H", "gap": 6, "cross": "CENTER", "children": steps},
            text("Bags are upgrades now: each one replaces the last, you never go back to a smaller bag.", "Small", "cozy/subtext", name="Message", align="CENTER", w=520)]
    foot = [btn("Ghost", "Cancel", "Btn Cancel", fillW=True), act("UPGRADE", "gold", "ui/status/coin", "1.2M", w=200)]
    return es.modal("Modal Bag Upgrade", body, foot, w=600, x=340, y=110)


def screen_bag():
    return m.screen("Bag Upgrade", [m.stats_card(), bag_modal()], dim=True)


# ================================================================ notes boards
def variants_board():
    owned = [c_rod_owned(nub_side=None), c_rod_equipped(nub_side=None), c_line(nub_side=None), c_aura(nub_side=None),
             c_fish(nub_side=None), c_bait(nub_side=None), c_treasure(nub_side=None), c_material(nub_side=None)]
    not_owned = [c_not_owned_rod(nub_side=None), c_not_owned_aura(nub_side=None)]
    col = lambda title, cards: {"name": title, "layout": "V", "gap": 10, "children": [text(title, "Heading", name="Title"),
                                                                                      {"name": "Cards", "layout": "H", "wrap": True, "gap": 16, "rowGap": 16, "w": 4 * CARD_W + 3 * 16, "children": cards}]}
    return board("Item Card · every kind", "Same card for every item. Owned = Actions container (buttons per kind). Not owned = no Actions, only \"Get from\". "
                 "Gold badge = highlighted stat (Auto Wait) and always first. Rods get Modifier sockets (locked, Soon).",
                 [col("Owned", owned), col("Not owned", not_owned)], w=4 * CARD_W + 3 * 16 + 48)


API = (
    "ItemDetail.Show(itemId, anchor, opts?)\n"
    "  itemId  \"<Kind>/<Id>\" e.g. \"Rods/CoralRod\", \"Auras/SolarFlare\", \"Fish/BubbleCarp\", \"Fish/BubbleCarp@Glowing\" (stack with mutation)\n"
    "  anchor  any GuiObject: inventory slot, Character slot, Shop picture, Fishdex card, catch card\n"
    "  opts    { owner = Player? (default LocalPlayer; another player = view only), side = \"auto\" | \"right\" | \"left\" }\n"
    "ItemDetail.Hide()  |  ItemDetail.IsOpen(itemId)\n"
    "\n"
    "Placement\n"
    "  1. Right of the anchor, 14px gap, top aligned to anchor top - 6.\n"
    "  2. Not enough room on the right -> left side, nub moves to the card's right edge.\n"
    "  3. Clamp Y inside the safe area (below Roblox top bar, above bottom HUD); nub follows the anchor centre.\n"
    "  4. Follows the anchor while the grid scrolls; anchor scrolled out of view -> card closes.\n"
    "\n"
    "Close: click outside, click the same slot again, Esc / B, window closes, item gone (sold / used up).\n"
    "Open another slot = card moves (no second card).\n"
    "\n"
    "Owner check: ItemDetail asks Inventory.Owns(profile, itemId) -> count. 0 = not owned = hide Actions, show Get From.\n"
    "Actions per kind live in one table (ItemActions[Kind] = { {Id, Label, Style, Cost?, Visible(item, profile), Enabled(...)} }), "
    "each button fires a remote (EquipItem, EnhanceItem, SellStack, PutInTank, OpenTreasure, StarUpAura, ToggleLock).\n"
    "Modifiers: Rods carry Modifiers = {} in the save now (empty), sockets show locked until the system ships."
)

RULES = (
    "Inventory v2\n"
    "  Same 760x610 window as Shop / Auras. Tabs move to an icon rail on the left (48px tiles, art ui/tabs/*). "
    "Selected = white tile + coral ring. Hover / long press = dark tooltip with the name. Red dot = new items in that tab.\n"
    "  Tabs: All, Fish, Rods, Lines, Auras, Baits, Treasure, Materials.\n"
    "  Rods / Lines: owned items only, coral tick = equipped, \"+\" cell opens the Shop on that tab.\n"
    "  Auras: the whole collection; not owned = locked silhouette (still opens the card, no Actions). "
    "Footer has ROLL AURA, so the Auras window can be retired: the HUD Auras button opens Inventory on this tab.\n"
    "  Fish / All: footer keeps SELL ALL; Treasure: OPEN ALL.\n"
    "\n"
    "Bags -> upgrade\n"
    "  Bags are not items any more. Capacity pill shows used / max + UPGRADE. "
    "Bag Upgrade modal shows the ladder (6 tiers) and the next one; buying replaces the bag. "
    "Save: profile.BagTier (number) instead of owned bags; old saves -> highest owned bag."
)


def notes_board():
    return board("How it works", None, [text(RULES, "Body", name="Rules", w=900), text("API (client)", "Heading", name="Sub"),
                                        text(API, "Small", "cozy/text", name="Api", w=900)], w=948)


def icons_board():
    cells = [es.art_cell("ui/tabs", k) for k, _ in TABS] + [es.art_cell("ui/tabs", "bag_upgrade")]
    mast = [es.art_cell("ui/mastery", k) for k in ("luck", "catch_bar", "reel_power", "auto_wait")]
    return board("New art needed (sheets 17 + 18 in ART_PROMPTS.md)", "Slots fill from assets/art once sliced. Mastery cards still use white vectors for these 4.",
                 [{"name": "Tabs", "layout": "H", "wrap": True, "gap": 8, "rowGap": 8, "w": 900, "children": cells},
                  {"name": "Mastery", "layout": "H", "gap": 8, "children": mast}], w=948)


# ================================================================ 8 card style options (same data, different look)
ROD = dict(key="equipment/MoonsilverRod", title="Moonsilver Rod", rarity="Epic", kind="Rod",
           stats=[("+35% Luck", False), ("+50% Reel Power", False), ("+8% Catch Bar", False), ("-10% Auto Wait", True)],
           table=[("Luck", "+15%", "+35%", 1), ("Reel Power", "+30%", "+50%", 1), ("Catch Bar", "+5%", "+8%", 1),
                  ("Resilience", "+15%", "+30%", 1), ("Auto Wait", "0%", "-10%", 1)],
           desc="Forged from moonlight. Steady in deep water.", plus=2, owned=True)
AURA_NO = dict(key="auras/DragonEmperor", title="Dragon Emperor", rarity="Mythic", kind="Aura",
               stats=[("+100% Luck", False), ("+30% Stability", False), ("+25% Golden", False)],
               table=[("Luck", "+35%", "+100%", 1), ("Stability", "0%", "+30%", 1), ("Golden", "0%", "+25%", 1)],
               desc="1 in 50,000 rolls.", plus=0, owned=False, source=("Aura Altar roll", "ui/icons/auras"))


def _actions(d, compact=False):
    if not d["owned"]:
        return None
    if compact:
        return [icon_img_btn("Equip", "mint", check=True), icon_img_btn("Enhance", "gold", "ui/status/enhance"), icon_img_btn("Lock", "coral", vec_kind="icon_lock")]
    return [act("EQUIP", "mint"), act("ENHANCE", "gold", "ui/status/enhance", "4", w=118)]


def icon_img_btn(name, style, key=None, check=False, vec_kind=None):
    if check:
        kid = {"type": "SVG", "svg": m.CHECK_SVG.replace('width="18" height="18"', 'width="22" height="22"'), "w": 22, "h": 22, "name": "Icon"}
    elif vec_kind:
        kid = vec(vec_kind, "FFFFFF", 22)
    else:
        kid = img(key, 24)
    return lip_btn("Btn " + name, [kid], style, w=52, pad=(8, 8, 11, 8))


def _src(d):
    lab, key = d["source"]
    return source_line(lab, key)


def style_a(d, **kw):
    """A · Classic: picture left, badges, Actions under a divider."""
    return card("A " + d["title"], d["key"], d["title"], d["rarity"], d["kind"], d["stats"], d["desc"],
                pills=[info_pill(f"+{d['plus']}", "cozy/gem-lip", "cozy/panel", img("ui/status/enhance", 16))] if d["plus"] else [],
                extra=[modifiers()] if d["kind"] == "Rod" and d["owned"] else [], action=_actions(d),
                source=None if d["owned"] else _src(d), locked=not d["owned"], **kw)


def _shell(name, kids, w=CARD_W, pad=16, gap=10, fill=None, radius=22, nub_side=None, clip=False, extra=None):
    c = {"name": "Item Card · " + name, "layout": "V", "gap": gap, "pad": pad, "w": w, "radius": radius, "clip": clip,
         "fill": fill or v("cozy/panel"), **BORDER, "effects": SOFT, "children": kids}
    if nub_side:
        n = nub(nub_side, 34)
        if nub_side == "right":
            n["x"] = w - 2
        c["children"].append(n)
    if extra:
        c.update(extra)
    return c


def _tail(d, compact=False):
    a = _actions(d, compact)
    if a:
        return [actions(a)]
    return [_src(d)]


def style_b(d, nub_side=None):
    """B · Hero: big picture on a rarity-tinted stage, everything centred."""
    col = RAR[d["rarity"]]
    stage = {"name": "Stage", "w": CARD_W - 32, "h": 150, "radius": 18, "clip": True, "fill": {"grad": [lighten(col, 0.85), lighten(col, 0.55)], "angle": 90},
             "children": [img(d["key"], 124, x=(CARD_W - 32 - 124) // 2, y=13, **({"opacity": 0.35} if not d["owned"] else {})),
                          dict(tag(d["rarity"]), x=10, y=10), dict(badge(d["kind"]), x=CARD_W - 32 - 56, y=10)]
             + ([m.fa_lock(40, x=(CARD_W - 32 - 35) // 2, y=55)] if not d["owned"] else [])}
    kids = [stage, text(d["title"], "Title", "cozy/rarity/" + d["rarity"].lower(), name="Name", align="CENTER", w=CARD_W - 32),
            dict(stat_badges(d["stats"]), main="CENTER"), text(d["desc"], "Small", "cozy/subtext", name="Desc", align="CENTER", w=CARD_W - 32)]
    return _shell("B Hero " + d["title"], kids + _tail(d), nub_side=nub_side, extra={"cross": "CENTER"})


def style_c(d, nub_side=None):
    """C · Rarity header: coloured band with the name, picture overlapping the band."""
    col = RAR[d["rarity"]]
    band = {"name": "Band", "layout": "V", "gap": 2, "pad": [14, 16, 14, 16], "fillW": True, "h": 70, "fill": {"hex": col}, "children": [
        text(d["title"], "Heading", "cozy/on-accent", name="Name"), text(d["rarity"].upper() + "  ·  " + d["kind"].upper(), "Caption", "cozy/on-accent", name="Kind")]}
    pic = dict(picture(d["key"], d["rarity"], not d["owned"], 76), absolute=True, x=CARD_W - 92, y=30)
    body = {"name": "Body", "layout": "V", "gap": 10, "pad": [16, 16, 16, 16], "fillW": True, "children": [
        {"name": "Room", "w": 1, "h": 26}, stat_badges(d["stats"]), text(d["desc"], "Small", "cozy/subtext", name="Desc", w=CARD_W - 32)]
        + ([modifiers()] if d["kind"] == "Rod" and d["owned"] else []) + _tail(d)}
    return _shell("C Band " + d["title"], [band, body, pic], pad=0, gap=0, nub_side=nub_side, clip=False)


def stat_line(label, value, hi=False):
    return {"name": "Line " + label, "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "children": [
        text(label, "Small", "cozy/subtext", name="Label"), text(value, "Small", "cozy/gold-lip" if hi else "cozy/text", name="Value")]}


def style_d(d, nub_side=None):
    """D · Compact tooltip: 240 wide, list of stats, icon-only actions."""
    w = 240
    head = {"name": "Head", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        picture(d["key"], d["rarity"], not d["owned"], 48), {"name": "Info", "layout": "V", "gap": 0, "fillW": True, "children": [
            text(d["title"], "Heading", "cozy/rarity/" + d["rarity"].lower(), name="Name"), text(d["rarity"] + " " + d["kind"], "Caption", "cozy/subtext", name="Kind")]}]}
    lines = [stat_line(t[0], t[2], t[0] == "Auto Wait") for t in d["table"]]
    tail = ([{"name": "Actions", "layout": "H", "gap": 8, "pad": [10, 0, 0, 0], "fillW": True, "main": "CENTER", "stroke": v("cozy/track"), "strokeSides": {"t": 2},
              "children": _actions(d, True)}] if d["owned"] else [text("Get from: " + d["source"][0], "Caption", "cozy/subtext", name="Get From")])
    c = _shell("D Compact " + d["title"], [head, {"name": "Stats", "layout": "V", "gap": 2, "fillW": True, "children": lines}] + tail, w=w, pad=12, gap=8)
    if nub_side:
        n = nub(nub_side, 20)
        n["x"] = -10 if nub_side == "left" else w - 2
        c["children"].append(n)
    return c


def style_e(d, nub_side=None):
    """E · Compare table: this item vs the equipped one (mint = better)."""
    w = 320
    head = {"name": "Head", "layout": "H", "gap": 12, "fillW": True, "cross": "CENTER", "children": [
        picture(d["key"], d["rarity"], not d["owned"], 64), {"name": "Info", "layout": "V", "gap": 4, "fillW": True, "children": [
            text(d["title"], "Heading", "cozy/rarity/" + d["rarity"].lower(), name="Name"),
            {"name": "Tags", "layout": "H", "gap": 6, "children": [tag(d["rarity"]), badge(d["kind"])]}]}]}
    hdr = {"name": "Table Head", "layout": "H", "fillW": True, "children": [
        text("Stat", "Caption", "cozy/subtext", name="C1", w=110), text("Equipped", "Caption", "cozy/subtext", name="C2", w=80), text("This", "Caption", "cozy/subtext", name="C3")]}
    rows = [{"name": "Row " + a, "layout": "H", "fillW": True, "pad": [5, 8, 5, 8], "radius": 10, "fill": v("cozy/sand") if i % 2 == 0 else {"hex": "FFFFFF", "opacity": 0},
             "cross": "CENTER", "children": [text(a, "Small", "cozy/text", name="Stat", w=102), text(b, "Small", "cozy/subtext", name="Old", w=80),
                                              text(("▲ " if up > 0 else "▼ ") + c, "Small", "cozy/mint-lip" if up > 0 else "cozy/danger-lip", name="New")]}
            for i, (a, b, c, up) in enumerate(d["table"])]
    c = _shell("E Compare " + d["title"], [head, hdr, {"name": "Table", "layout": "V", "gap": 0, "fillW": True, "children": rows}] + _tail(d), w=w)
    if nub_side:
        n = nub(nub_side, 30)
        n["x"] = -10 if nub_side == "left" else w - 2
        c["children"].append(n)
    return c


def style_f(d, nub_side=None):
    """F · Trading card: tall framed card, actions float underneath as a separate pill."""
    col = RAR[d["rarity"]]
    w = 250
    frame = {"name": "Card", "layout": "V", "gap": 8, "pad": 10, "w": w, "radius": 22, "fill": {"grad": [lighten(col, 0.25), col], "angle": 90},
             "stroke": "FFFFFF", "strokeW": 4, "effects": SOFT, "cross": "CENTER", "clip": False, "children": [
                 {"name": "Title Bar", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                     ftxt(d["title"], 18, "FFFFFF", name="Name", textStroke="3D4B5C"), stars(3 if d["owned"] else 0, 12)]},
                 {"name": "Window", "w": w - 20, "h": 150, "radius": 14, "fill": "FFFFFF", "clip": True, "children": [
                     img(d["key"], 130, x=(w - 20 - 130) // 2, y=10, **({"opacity": 0.35} if not d["owned"] else {}))]
                     + ([m.fa_lock(40, x=(w - 20 - 35) // 2, y=55)] if not d["owned"] else [])},
                 {"name": "Kind", "layout": "H", "pad": [3, 12, 4, 12], "radius": 999, "fill": "FFFFFF", "children": [
                     text(d["rarity"].upper() + " " + d["kind"].upper(), "Caption", "cozy/text", name="Label")]},
                 {"name": "Stats Box", "layout": "V", "gap": 2, "pad": [8, 12, 8, 12], "fillW": True, "radius": 14, "fill": {"hex": "FFFFFF", "opacity": 0.92},
                  "children": [stat_line(t[0], t[2], t[0] == "Auto Wait") for t in d["table"][:4]]}]}
    under = ({"name": "Actions Pill", "layout": "H", "gap": 8, "pad": 8, "radius": 20, "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": _actions(d, True)}
             if d["owned"] else info_pill("Get from: " + d["source"][0], "cozy/subtext", "cozy/panel"))
    c = {"name": "Item Card · F Trading " + d["title"], "layout": "V", "gap": 10, "cross": "CENTER", "clip": False, "children": [frame, under]}
    if nub_side:
        n = nub(nub_side, 34)
        n["x"] = -10 if nub_side == "left" else w - 2
        c["children"].append(n)
    return c


def style_g(d, nub_side=None):
    """G · Wide split: tinted picture panel on the left, info + actions on the right (440 wide)."""
    col = RAR[d["rarity"]]
    w = 440
    left = {"name": "Picture Panel", "layout": "V", "gap": 8, "pad": 12, "w": 150, "fillH": True, "cross": "CENTER", "main": "CENTER",
            "fill": {"grad": [lighten(col, 0.8), lighten(col, 0.5)], "angle": 90}, "children": [
                img(d["key"], 110, **({"opacity": 0.35} if not d["owned"] else {})), tag(d["rarity"])]}
    right = {"name": "Info", "layout": "V", "gap": 8, "pad": 14, "fillW": True, "children": [
        text(d["title"], "Heading", "cozy/rarity/" + d["rarity"].lower(), name="Name"), text(d["kind"] + "  ·  " + d["desc"], "Caption", "cozy/subtext", name="Desc", w=250),
        dict(stat_badges(d["stats"]), w=258)] + ([modifiers(2)] if d["kind"] == "Rod" and d["owned"] else []) + _tail(d)}
    c = {"name": "Item Card · G Split " + d["title"], "layout": "H", "w": w, "radius": 22, "clip": True, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
         "children": [left, right]}
    if nub_side:
        c["clip"] = False
        n = nub(nub_side, 34)
        n["x"] = -10 if nub_side == "left" else w - 2
        c["children"].append(n)
    return c


def round_action(label, style, kid):
    return {"name": "Btn " + label.title(), "layout": "V", "gap": 4, "cross": "CENTER", "children": [
        {"name": "Circle", "w": 54, "h": 54, "radius": 999, "fill": v("cozy/" + style), "stroke": v("cozy/" + style + "-lip"), "strokeSides": {"b": 4},
         "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [kid]},
        text(label, "Caption", "cozy/text", name="Label")]}


def style_h(d, nub_side=None):
    """H · Bubble: soft rarity-tinted bubble, big round action buttons with labels."""
    col = RAR[d["rarity"]]
    head = {"name": "Head", "layout": "H", "gap": 12, "fillW": True, "cross": "CENTER", "children": [
        {"name": "Orb", "w": 84, "h": 84, "radius": 999, "fill": "FFFFFF", "stroke": {"hex": col}, "strokeW": 3, "layout": "H", "main": "CENTER", "cross": "CENTER",
         "children": [img(d["key"], 66, **({"opacity": 0.35} if not d["owned"] else {}))]},
        {"name": "Info", "layout": "V", "gap": 4, "fillW": True, "children": [
            text(d["title"], "Heading", "cozy/rarity/" + d["rarity"].lower(), name="Name"),
            {"name": "Tags", "layout": "H", "gap": 6, "children": [tag(d["rarity"]), badge(d["kind"])]}]}]}
    kids = [head, stat_badges(d["stats"])]
    if d["owned"]:
        kids.append({"name": "Actions", "layout": "H", "gap": 18, "fillW": True, "main": "CENTER", "children": [
            round_action("Equip", "mint", {"type": "SVG", "svg": m.CHECK_SVG.replace('width="18" height="18"', 'width="26" height="26"'), "w": 26, "h": 26, "name": "Icon"}),
            round_action("Enhance", "gold", img("ui/status/enhance", 28)), round_action("Lock", "coral", vec("icon_lock", "FFFFFF", 24))]})
    else:
        kids.append(info_pill("Get from: " + d["source"][0], "cozy/subtext", "cozy/panel"))
    c = _shell("H Bubble " + d["title"], kids, radius=34, fill={"grad": ["FFFFFF", lighten(col, 0.82)], "angle": 90})
    if nub_side:
        n = nub(nub_side, 34)
        n["x"] = -10 if nub_side == "left" else CARD_W - 2
        c["children"].append(n)
    return c


CARD_OPTIONS = [
    ("A", "Classic", "Picture left, stat badges, Actions under a divider. Tidy, fits every kind.", style_a),
    ("B", "Hero", "Big picture on a rarity stage, centred text. Most showy, tallest.", style_b),
    ("C", "Rarity Band", "Coloured band with the name, picture overlaps it. Rarity reads instantly.", style_c),
    ("D", "Compact Tooltip", "240 wide, stat list, icon buttons. Best for busy screens / mobile.", style_d),
    ("E", "Compare Table", "Stat table vs the equipped item, arrows up/down. Best for gear choices.", style_e),
    ("F", "Trading Card", "Collectible card, actions float underneath. Fits auras/fish collection feel.", style_f),
    ("G", "Wide Split", "440 wide, picture panel left, info right. Room for modifiers later.", style_g),
    ("H", "Bubble", "Soft round bubble, big round labelled buttons. Friendliest for kids.", style_h),
]


def card_option_board(letter, name, desc, fn):
    try:
        own = fn(ROD, nub_side=None)
    except TypeError:
        own = fn(ROD)
    no = fn(AURA_NO, nub_side=None)
    return board(f"{letter} · {name}", desc, [
        {"name": "Owned", "layout": "V", "gap": 6, "children": [text("Owned (Actions)", "Caption", "cozy/subtext", name="Label"), own]},
        {"name": "Not owned", "layout": "V", "gap": 6, "children": [text("Not owned (no Actions)", "Caption", "cozy/subtext", name="Label"), no]}],
        w=1000 if letter == "G" else 760, layout="H", gap=24)


# ================================================================ 6 inventory options
def rods_cells(n_cols=7, size=SLOT):
    keys = [("DriftwoodRod", "Common", None), ("BambooRod", "Uncommon", None), ("CoralRod", "Rare", "selected"), ("MoonsilverRod", "Epic", "ring"),
            ("SweetheartRod", "Rare", "new")]
    cells = []
    for k, r, st in keys:
        s = item_slot("equipment/" + k, r, 1, size=size, state=None if st == "ring" else st, name=k)
        s["children"][0]["children"] = [c for c in s["children"][0]["children"] if c.get("name") != "Count Row"]
        if st == "ring":
            s["children"][0]["stroke"], s["children"][0]["strokeW"] = v("cozy/sky-lip"), 3
        cells.append(s)
    cells.append(dict(item_slot(None, size=size, state="empty", name="Get More"), name="Btn Get More"))
    return cells


def grid_rows(cells, cols, size, gap, rows_h=None, name="Grid [scroll]"):
    rows = [cells[i:i + cols] for i in range(0, len(cells), cols)]
    d = {"name": name, "layout": "V", "gap": 12, "pad": [8, 0, 0, 0], "w": cols * size + (cols - 1) * gap, "clip": False, "children": [
        {"name": f"Row {i + 1}", "layout": "H", "gap": gap, "clip": False, "children": r} for i, r in enumerate(rows)]}
    if rows_h:
        d["h"] = rows_h
    return d


def cap_pill():
    return {"name": "Capacity", "layout": "H", "gap": 8, "pad": [4, 4, 4, 12], "radius": 999, "cross": "CENTER", "fill": v("cozy/sand"), "children": [
        img("ui/icons/bag", 22), ftxt("18", 18, "3D4B5C", name="Used"), ftxt("/ 30", 18, "9AA5B1", name="Max"),
        lip_btn("Btn Upgrade Bag", [vec("icon_arrow_up", "FFFFFF", 14), ftxt("UPGRADE", 13, "FFFFFF", name="Label")], "gold", pad=(4, 10, 7, 10))]}


def header_row(title="Inventory"):
    return {"name": "Header", "layout": "H", "gap": 12, "fillW": True, "cross": "CENTER", "children": [
        text(title, "Title", name="Title"), cap_pill(), {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, btn("Danger", "X", "Btn Close")]}


def sub_row(label="Rods", count="5 owned"):
    return {"name": "Sub Header", "layout": "H", "gap": 10, "h": 32, "fillW": True, "cross": "CENTER", "children": [
        text(label, "Heading", name="Category"), info_pill(count), {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, btn("Ghost", "Sort: Rarity", "Btn Sort")]}


def tab_tile(key, label, on, size=48, icon=36, labelled=False, tile_w=None):
    kids = [img("ui/tabs/" + key, icon, fill={"hex": "E5DBFA", "opacity": 0.6})]
    if labelled:
        kids.append(text(label, "Caption", "cozy/coral-lip" if on else "cozy/subtext", name="Label"))
    t = {"name": "Tab " + label, "w": tile_w or size, "h": size + (16 if labelled else 0), "radius": 14, "clip": False, "fill": "FFFFFF" if on else v("cozy/sand"),
         "layout": "V", "gap": 2, "main": "CENTER", "cross": "CENTER", "children": kids}
    if on:
        t["effects"] = [{"color": "FF9E80", "a": 1, "spread": 3, "blur": 0}]
    else:
        t.update(BORDER)
    return t


def win(name, w, h, x, y, kids, radius=24):
    return {"name": "Window " + name, "layout": "V", "pad": 20, "gap": 14, "w": w, "h": h, "x": x, "y": y, "radius": radius, "clip": False,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": kids}


def inv_1():
    """1 · Rail inside (window 760, rail left, 7 columns)."""
    sx, sy = slot_pos(3, 0)
    cells = rods_cells()
    w = inventory_window("Rods", "5 owned", cells, "rods", hover="lines")
    return [w, style_a(ROD, nub_side="left", nub_y=30, x=sx + SLOT + 14, y=sy - 6)]


def inv_2():
    """2 · Bookmarks: tabs stick out of the window's left edge like book tabs, grid gets 8 columns."""
    x0 = WX
    tabs = []
    for i, (k, lab) in enumerate(TABS):
        on = k == "rods"
        tabs.append({"name": "Tab " + lab, "w": 64 if on else 56, "h": 50, "x": x0 - (52 if on else 44), "y": SAFE_TOP + 70 + i * 56, "radius": 14,
                     "fill": v("cozy/panel") if on else v("cozy/sand"), **BORDER, "layout": "H", "pad": [0, 0, 0, 8], "cross": "CENTER",
                     "children": [img("ui/tabs/" + k, 34, fill={"hex": "E5DBFA", "opacity": 0.6})]})
    gx = x0 + 20
    gy = SAFE_TOP + 20 + 44 + 14 + 32 + 12 + 8
    w = win("Inventory", WIN_W, WIN_H, x0, SAFE_TOP, [header_row(), sub_row(), grid_rows(rods_cells(), 8, SLOT, GAP, 372)])
    sx = gx + 3 * (SLOT + GAP)
    return tabs + [w, style_a(ROD, nub_side="left", nub_y=30, x=sx + SLOT + 14, y=gy - 6)]


def inv_3():
    """3 · Docked detail: rail + grid + fixed detail panel on the right (no popover inside Inventory)."""
    ww = 900
    x0 = (W - ww) // 2
    detail = style_a(ROD)
    detail.update(name="Detail Panel (docked Item Card)", fill=v("cozy/sand"), effects=[])
    detail.pop("stroke", None)
    body = {"name": "Body", "layout": "H", "gap": 16, "fillW": True, "clip": False, "children": [
        rail("rods"), {"name": "Content", "layout": "V", "gap": 12, "w": 5 * SLOT + 4 * GAP, "children": [sub_row(), grid_rows(rods_cells(), 5, SLOT, GAP)]}, detail]}
    return [win("Inventory", ww, WIN_H, x0, SAFE_TOP, [header_row(), body])]


def inv_4():
    """4 · Right drawer: tall drawer docked to the screen edge, rail on its left, card pops out to the left."""
    dw = 560
    x0 = W - 16 - dw
    body = {"name": "Body", "layout": "H", "gap": 16, "fillW": True, "clip": False, "children": [
        rail("rods"), {"name": "Content", "layout": "V", "gap": 12, "fillW": True, "children": [sub_row(), grid_rows(rods_cells(), 5, SLOT, GAP)]}]}
    d = win("Inventory Drawer", dw, 620, x0, SAFE_TOP - 6, [header_row(), body], radius=32)
    gx = x0 + 20 + RAIL_W + 16
    gy = SAFE_TOP - 6 + 20 + 44 + 14 + 32 + 12 + 8
    sx, sy = gx + 3 * (SLOT + GAP), gy
    return [m.stats_card(), d, style_a(ROD, nub_side="right", x=sx - CARD_W - 14, y=sy - 6)]


def inv_5():
    """5 · Labelled rail + filters: icon + name under each tab, search box and rarity chips above the grid."""
    rail5 = {"name": "Tab Rail", "layout": "V", "gap": 6, "pad": 6, "w": 84, "radius": 18, "fill": v("cozy/sand", 0.6), "cross": "CENTER", "children": [
        tab_tile(k, lab, k == "rods", size=42, icon=30, labelled=True, tile_w=72) for k, lab in TABS]}
    search = {"name": "Search", "layout": "H", "gap": 8, "pad": [6, 12, 6, 12], "w": 200, "radius": 999, "fill": "FFFFFF", **BORDER, "cross": "CENTER", "children": [
        {"type": "SVG", "name": "Icon Search", "w": 16, "h": 16,
         "svg": '<svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg"><circle cx="7" cy="7" r="5" stroke="#9AA5B1" stroke-width="2.2" fill="none"/><path d="M11 11l3.5 3.5" stroke="#9AA5B1" stroke-width="2.2" stroke-linecap="round"/></svg>'},
        text("Search", "Small", "cozy/subtext", name="Placeholder")]}
    chips = [{"name": "Filter " + r, "w": 26, "h": 26, "radius": 999, "fill": {"hex": RAR[r]}, "stroke": "FFFFFF" if r != "Rare" else "3D4B5C", "strokeW": 2 if r != "Rare" else 3}
             for r in ("Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic")]
    filt = {"name": "Filters", "layout": "H", "gap": 8, "h": 32, "fillW": True, "cross": "CENTER", "children": [search, {"name": "Spacer", "w": 1, "h": 1, "fillW": True}] + chips}
    content = {"name": "Content", "layout": "V", "gap": 12, "fillW": True, "clip": False, "children": [sub_row(), filt, grid_rows(rods_cells(), 7, SLOT, GAP)]}
    body = {"name": "Body", "layout": "H", "gap": 14, "fillW": True, "clip": False, "children": [rail5, content]}
    gx = WX + 20 + 84 + 14
    gy = SAFE_TOP + 20 + 44 + 14 + 32 + 12 + 32 + 12 + 8
    sx = gx + 3 * (SLOT + GAP)
    return [win("Inventory", WIN_W, WIN_H, WX, SAFE_TOP, [header_row(), body]), style_a(ROD, nub_side="left", nub_y=30, x=sx + SLOT + 14, y=gy - 6)]


def inv_6():
    """6 · Backpack bar: wide low window above the HUD bottom, 2-column rail, 10 columns; compact card pops above."""
    ww, hh = 1000, 300
    x0, y0 = (W - ww) // 2, H - hh - 24
    s6, g6 = 76, 8
    rail6 = {"name": "Tab Rail", "layout": "H", "wrap": True, "gap": 6, "rowGap": 6, "pad": 6, "w": 98, "radius": 16, "fill": v("cozy/sand", 0.6), "children": [
        tab_tile(k, lab, k == "rods", size=40, icon=30) for k, lab in TABS]}
    cells = rods_cells(size=s6) + [item_slot(None, size=s6, state="empty", name="Empty") for _ in range(4)]
    content = {"name": "Content", "layout": "V", "gap": 8, "fillW": True, "clip": False, "children": [grid_rows(cells, 10, s6, g6)]}
    head = {"name": "Header", "layout": "H", "gap": 12, "fillW": True, "cross": "CENTER", "children": [
        text("Backpack", "Heading", name="Title"), cap_pill(), text("Rods  ·  5 owned", "Small", "cozy/subtext", name="Category"),
        {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, btn("Ghost", "Sort: Rarity", "Btn Sort"), btn("Danger", "X", "Btn Close")]}
    body = {"name": "Body", "layout": "H", "gap": 16, "fillW": True, "clip": False, "children": [rail6, content]}
    w = win("Backpack", ww, hh, x0, y0, [head, body], radius=28)
    gx = x0 + 20 + 98 + 16
    gy = y0 + 20 + 40 + 14 + 8
    sx = gx + 3 * (s6 + g6)
    c = style_d(ROD)
    down = {"type": "SVG", "name": "Nub down", "w": 20, "h": 12,
            "svg": f'<svg width="20" height="12" viewBox="0 0 20 12" xmlns="http://www.w3.org/2000/svg"><path d="M0 0 L10 12 L20 0 Z" fill="#{PANEL_HEX}"/><path d="M0 0 L10 12 L20 0" stroke="#{TRACK_HEX}" stroke-width="2" fill="none"/></svg>'}
    pop = {"name": "Popover", "layout": "V", "gap": 0, "cross": "CENTER", "x": sx + s6 // 2 - 120, "y": gy - 12 - 300, "clip": False, "children": [c, down]}
    return [m.stats_card(), w, pop]


INV_OPTIONS = [
    ("1", "Rail Inside", "Standard 760x610 window, 48px icon rail inside on the left, 7 columns. Card pops beside the slot.", inv_1),
    ("2", "Bookmark Tabs", "Tabs stick out of the window edge like book tabs, so the grid keeps the full width (8 columns).", inv_2),
    ("3", "Docked Detail", "Wider window: rail + grid + a fixed detail panel. No popover inside Inventory (popover still used elsewhere).", inv_3),
    ("4", "Right Drawer", "Drawer docked to the right edge (world stays visible), rail on its left, card pops out to the left.", inv_4),
    ("5", "Labelled + Filters", "Rail with names under each icon, search box and rarity filter dots above the grid.", inv_5),
    ("6", "Backpack Bar", "Wide low bar above the bottom HUD, 2-column rail, 10 columns. Uses the compact card, pops above.", inv_6),
]


def build():
    ax, ay = 27200, 0
    blocks = []
    for i, (n, name, desc, fn) in enumerate(INV_OPTIONS):
        x, y = 60 + (i % 3) * 1400, 200 + (i // 3) * 960
        scr = m.screen(f"Inventory {n}", fn(), dim=n != "4" and n != "6")
        blocks.append({"name": f"Option {n}", "layout": "V", "gap": 8, "x": x, "y": y, "children": [
            text(f"{n} · {name}", "Title", name="Title"), text(desc, "Small", "cozy/subtext", name="Desc", w=1280), scr]})
    y3 = 200 + 2 * 960
    bag = es.screen_block("Bag Upgrade (bags are upgrades, not items)", screen_bag(), 60, y3)
    notes = dict(notes_board(), x=1460, y=y3)
    icons = dict(icons_board(), x=2500, y=y3)
    sec_a = {"type": "SECTION", "name": "18A · Inventory v2 — 6 options", "fill": "F3E9D8", "x": ax, "y": ay, "children": [
        text("18A · Inventory v2 — 6 options (pick one)", "Display", name="Title", x=60, y=40),
        text("Tabs move to the side as icons (art ui/tabs/*). Rods / Lines / Auras become items. Bags become an upgrade (capacity pill + UPGRADE). "
             "All 6 show the Rods tab with Moonsilver Rod opened in the Item Card.", "Body", "cozy/subtext", name="Sub", x=60, y=100, w=4000)] + blocks + [bag, notes, icons]}

    by = 3400
    cards = []
    x, y, row_h = 60, 200, 0
    for i, opt in enumerate(CARD_OPTIONS):
        b = card_option_board(*opt)
        bw = 1000 if opt[0] == "G" else 760
        if x + bw > 4200:
            x, y = 60, y + 820
        cards.append(dict(b, x=x, y=y))
        x += bw + 60
    kinds = dict(variants_board(), x=60, y=y + 900)
    sec_b = {"type": "SECTION", "name": "18B · Item Detail Card — 8 options", "fill": "F3E9D8", "x": ax, "y": by, "children": [
        text("18B · Item Detail Card — 8 options (pick one)", "Display", name="Title", x=60, y=40),
        text("ItemDetail.Show(itemId, anchor). Each option shows the same owned rod (Actions) and a not-owned aura (no Actions, only Get from). "
             "Bottom board: what every item kind shows, drawn in option A.", "Body", "cozy/subtext", name="Sub", x=60, y=100, w=4000)] + cards + [kinds]}
    return [{"pageId": PAGE_ID, "replaceName": sec_a["name"], "tree": sec_a}, {"pageId": PAGE_ID, "replaceName": sec_b["name"], "tree": sec_b}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "23_item_detail_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
