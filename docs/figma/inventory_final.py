"""18 · Inventory (Bookmark Tabs) FINAL + 17 · Character v2  (user, 2026-11-18).

User picked Inventory option 2 "Bookmark Tabs" (18A) and asked for it smaller. Item Card = option A (Classic)
with every action button at a FIXED height of 48 (label + cost on one line, never two lines).
Bags: upgrade ladder, the last tier Bottomless Bag is Robux only (= Infinite Bag pass, 349 R$).
Character (17) is rebuilt for the new item model: no Bag slot (bag is an upgrade), Aura slot added,
owned items open the same Item Card (popover) instead of the old fixed detail strip.

Run:  python -I docs/figma/inventory_final.py docs/figma/out
Send: python -I docs/figma/send_blocks.py docs/figma/out/24_inventory_final_ops.json   (section shell first, then one block per call)
Then: python -I tools/art/figma_images.py --root <section id>
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


d = _load("item_detail", "item_detail.py")
m, es = d.m, d.es
v, text, BORDER, SOFT, PAGE_ID = m.v, m.text, m.BORDER, m.SOFT, m.PAGE_ID
btn, img, ftxt, item_slot, tag = m.btn, m.img, m.ftxt, m.item_slot, m.tag
lip_btn, info_pill, vec, board = es.lip_btn, es.info_pill, es.vec, es.board
W, H, SAFE_TOP = m.W, m.H, m.SAFE_TOP
RAR = m.RARITY_HEX

# ---------------------------------------------------------------- sizes (smaller than option 2)
CARD_W = 280
d.CARD_W = CARD_W           # item_detail card builders read the module global at call time
WIN_W, WIN_H = 600, 480
SLOT, GAP, ROW_GAP, COLS = 72, 8, 10, 7
BTN_H = 48                  # every action button: fixed 48 high
X0, Y0 = (W - WIN_W) // 2, 120
GX = X0 + 20
GY = Y0 + 20 + 44 + 12 + 28 + 12 + 6
TAB_W, TAB_H, TAB_STEP = 50, 42, 48   # tabs stick out 42px (selected 50px) so the whole icon shows


# ---------------------------------------------------------------- 48px buttons (override item_detail.act / icon_btn)
def act48(label, style="mint", key=None, value=None, w=None, disabled=False):
    c = "9AA5B1" if disabled else "FFFFFF"
    kids = [ftxt(label, 16, c, name="Label")]
    if key:
        kids += [{"name": "Divider", "w": 2, "h": 20, "radius": 1, "fill": {"hex": "FFFFFF", "opacity": 0.45}},
                 es.cost(key, value, c, size=18, fs=15)]
    b = lip_btn("Btn " + label.title(), kids, style, w, pad=(0, 12, 5, 12), disabled=disabled)
    b.update(h=BTN_H, main="CENTER", cross="CENTER", gap=8)
    if key and (w or 0) < 150:   # inside a card: buttons with a cost hug their content, plain ones fill the rest
        b.pop("w", None)
    elif not w:
        b["fillW"] = True
    return b


def modifiers30(n=3):
    sockets = [{"name": f"Socket {i + 1}", "w": 30, "h": 30, "radius": 999, "fill": v("cozy/sand"), "stroke": v("cozy/track"), "strokeW": 2,
                "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [m.fa_lock(12, opacity=0.45)]} for i in range(n)]
    return {"name": "Modifiers", "layout": "H", "gap": 6, "fillW": True, "cross": "CENTER", "children": [
        text("Modifiers", "Small", "cozy/subtext", name="Label"), *sockets, {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        info_pill("Soon", "cozy/subtext", "cozy/sand")]}


d.modifiers = modifiers30


def icon48(name, kind, style="sky"):
    b = lip_btn("Btn " + name, [vec(kind, "FFFFFF", 22)], style, w=BTN_H, pad=(0, 0, 5, 0))
    b.update(h=BTN_H, main="CENTER", cross="CENTER")
    return b


def robux48(price, label=None, w=None):
    kids = ([ftxt(label, 16, "FFFFFF", name="Label"), {"name": "Divider", "w": 2, "h": 20, "radius": 1, "fill": {"hex": "FFFFFF", "opacity": 0.45}}] if label else [])
    kids += [vec("icon_robux", "FFFFFF", 18), ftxt(str(price), 16, "FFFFFF", name="Price")]
    b = lip_btn("Btn Buy Robux", kids, "mint", w, pad=(0, 14, 5, 14))
    b.update(h=BTN_H, main="CENTER", cross="CENTER", gap=8)
    if not w:
        b["fillW"] = True
    return b


d.act, d.icon_btn = act48, icon48


# ---------------------------------------------------------------- empty slot = option 5 "Bubbles" (user, 2026-11-18), Get More = "More" arrow
def empty_slot(size=72, name="Empty"):
    k = size / 72
    dots = {"type": "SVG", "name": "Bubbles", "w": round(28 * k), "h": round(28 * k), "x": round(22 * k), "y": round(22 * k),
            "svg": f'<svg width="{round(28 * k)}" height="{round(28 * k)}" viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg">'
                   '<circle cx="8" cy="19" r="4" fill="#D9CDB8"/><circle cx="18" cy="11" r="3" fill="#D9CDB8"/><circle cx="21" cy="21" r="2" fill="#D9CDB8"/></svg>'}
    tile = {"name": "Slot", "w": size, "h": size, "x": 0, "y": 0, "radius": round(size / 4), "clip": True, "fill": v("cozy/sand"), **BORDER, "children": [dots]}
    return {"name": name, "w": size, "h": size, "clip": False, "children": [tile]}


def get_more(size=72):
    k = size / 72
    arrow = {"type": "SVG", "name": "Arrow", "w": round(26 * k), "h": round(26 * k), "x": round(23 * k), "y": round(14 * k),
             "svg": f'<svg width="{round(26 * k)}" height="{round(26 * k)}" viewBox="0 0 26 26" xmlns="http://www.w3.org/2000/svg">'
                    '<path d="M8 4l10 9-10 9" stroke="#E08A6E" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>'}
    tile = {"name": "Slot", "w": size, "h": size, "x": 0, "y": 0, "radius": round(size / 4), "clip": True, "fill": {"hex": "FF9E80", "opacity": 0.14},
            "children": [arrow, dict(text("More", "Caption", "cozy/coral-lip", name="Label"), x=0, y=round(46 * k), w=size, align="CENTER")]}
    return {"name": "Btn Get More", "w": size, "h": size, "clip": False, "children": [tile]}


# ---------------------------------------------------------------- inventory window
TABS = d.TABS


def bookmarks(active):
    out = []
    for i, (k, lab) in enumerate(TABS):
        on = k == active
        w = TAB_W + 8 if on else TAB_W
        t = {"name": "Tab " + lab, "w": w, "h": TAB_H, "x": X0 - w + 8, "y": Y0 + 54 + i * TAB_STEP, "radius": 12,
             "fill": v("cozy/panel") if on else v("cozy/sand"), **BORDER, "layout": "H", "pad": [0, 0, 0, 7], "cross": "CENTER",
             "children": [img("ui/tabs/" + k, 32)]}
        if k == "fish" and not on:
            t["children"].append(dict(m.small_pill("3", "cozy/danger", "Dot"), absolute=True, x=-8, y=-6))
        out.append(t)
    return out


def cap_pill(used="18", mx="30", upgrade=True):
    kids = [img("ui/icons/bag", 20), ftxt(used, 16, "3D4B5C", name="Used"), ftxt("/ " + mx, 16, "9AA5B1", name="Max")]
    if upgrade:
        b = lip_btn("Btn Upgrade Bag", [vec("icon_arrow_up", "FFFFFF", 12), ftxt("UPGRADE", 12, "FFFFFF", name="Label")], "gold", pad=(3, 9, 6, 9))
        kids.append(b)
    return {"name": "Capacity", "layout": "H", "gap": 6, "pad": [3, 3, 3, 10], "radius": 999, "cross": "CENTER", "fill": v("cozy/sand"), "children": kids}


def slot(key, rarity, count=None, state=None, mut=None, name=None, ring=False, permanent=True):
    s = item_slot(key, rarity, count or 1, size=SLOT, state=state, mut=mut, name=name or (key.split("/")[-1] if key else "Empty"))
    if permanent and key:
        s["children"][0]["children"] = [c for c in s["children"][0]["children"] if c.get("name") != "Count Row"]
    if ring:
        s["children"][0]["stroke"], s["children"][0]["strokeW"] = v("cozy/sky-lip"), 3
    return s


def grid(cells, rows=4):
    rr = [cells[i:i + COLS] for i in range(0, len(cells), COLS)]
    return {"name": "Grid [scroll]", "layout": "V", "gap": ROW_GAP, "pad": [6, 0, 0, 0], "w": COLS * SLOT + (COLS - 1) * GAP,
            "h": rows * SLOT + (rows - 1) * ROW_GAP + 6, "clip": False, "children": [
                {"name": f"Row {i + 1}", "layout": "H", "gap": GAP, "clip": False, "children": r} for i, r in enumerate(rr)]}


def window(tab_label, count, cells, footer=None, rows=4, cap=("18", "30", True)):
    header = {"name": "Header", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        text("Inventory", "Title", name="Title"), cap_pill(*cap), {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, btn("Danger", "X", "Btn Close")]}
    sub = {"name": "Sub Header", "layout": "H", "gap": 8, "h": 28, "fillW": True, "cross": "CENTER", "children": [
        text(tab_label, "Heading", name="Category"), info_pill(count), {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        {"name": "Btn Sort", "layout": "H", "gap": 4, "pad": [4, 10, 4, 10], "radius": 999, "fill": v("cozy/sand"), "cross": "CENTER", "children": [
            text("Sort: Rarity", "Caption", "cozy/text", name="Label")]}]}
    kids = [header, sub, grid(cells, rows)] + ([footer] if footer else [])
    return {"name": "Window Inventory", "layout": "V", "pad": 20, "gap": 12, "w": WIN_W, "h": WIN_H, "x": X0, "y": Y0, "radius": 24, "clip": False,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": kids}


def pos(col, row):
    return GX + col * (SLOT + GAP), GY + row * (SLOT + ROW_GAP)


def card_at(fn, col, row, side="left"):
    sx, sy = pos(col, row)
    if side == "left":   # nub on the card's left = card sits right of the slot
        return fn(nub_side="left", nub_y=SLOT // 2 - 10 + 6, x=sx + SLOT + 12, y=sy - 6)
    return fn(nub_side="right", nub_y=SLOT // 2 - 10 + 6, x=sx - CARD_W - 12, y=sy - 6)


def nub_fix(c, side):
    """item_detail.nub() positions the right nub at its CARD_W; recompute with ours."""
    for k in c["children"]:
        if k.get("name") == "Nub right":
            k["x"] = CARD_W - 2
    return c


def screen(name, kids, active):
    return m.screen(name, bookmarks(active) + kids, dim=True)


# ---------------------------------------------------------------- screens
def s_rods():
    cells = [slot("equipment/DriftwoodRod", "Common"), slot("equipment/BambooRod", "Uncommon"), slot("equipment/CoralRod", "Rare", state="selected"),
             slot("equipment/MoonsilverRod", "Epic", ring=True), slot("equipment/SweetheartRod", "Rare", state="new"),
             get_more(SLOT)]
    c = card_at(d.c_rod_owned, 3, 0)
    return screen("Inventory · Rods", [window("Rods", "5 owned", cells), c], "rods")


FISH = [("PebbleMinnow", "Common", 23, None, None, 0), ("BubbleCarp", "Common", 41, None, "ring", 3), ("PearlClam", "Uncommon", 6, None, None, 0),
        ("DewdropKoi", "Rare", 2, None, None, 0), ("CrystalGuppy", "Epic", 1, None, "new", 0), ("ReedPerch", "Common", 12, None, None, 0),
        ("LilyTrout", "Uncommon", 4, None, None, 0), ("CoralSeahorse", "Legendary", 1, None, None, 0), ("MoonJelly", "Rare", 1, "fish/mut_glowing", None, 0),
        ("NagaHatchling", "Mythic", 1, None, None, 0), ("TideSnapper", "Uncommon", 3, None, None, 0), ("SilverRay", "Rare", 2, None, None, 0)]


def s_fish():
    cells = []
    for k, r, n, mu, st, hot in FISH:
        s = slot("fish/" + k, r, n, state=None if st == "ring" else st, mut=mu, ring=st == "ring", permanent=False)
        if hot:
            s["children"].append(dict(es.hot_badge(hot), x=-6, y=SLOT - 22))
        cells.append(s)
    cells += [empty_slot(SLOT) for _ in range(2)]
    foot = {"name": "Footer", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        text("Total 12.4k", "Small", "cozy/subtext", name="Total"), {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        act48("SELL ALL", "gold", "ui/status/coin", "12.4k", w=190)]}
    c = card_at(d.c_fish, 1, 0)
    return screen("Inventory · Fish", [window("Fish", "12 stacks", cells, foot, rows=3), c], "fish")


def s_auras():
    cells = [slot("auras/" + k, r, state=st, ring=(k == "DragonEmperor")) for k, r, st in d.AURAS]
    foot = {"name": "Footer", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        text("8 / 19 found", "Small", "cozy/subtext", name="Found"), {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        act48("ROLL AURA", "sky", "ui/status/gem", "10", w=190)]}
    c = nub_fix(card_at(d.c_not_owned_aura, 6, 0, side="right"), "right")
    return screen("Inventory · Auras", [window("Auras", "8 owned", cells, foot, rows=3), c], "auras")


BAGS = [("StarterPouch", "6"), ("WovenBasket", "10"), ("Crate", "15"), ("Coolbox", "20"), ("Hold", "30"), ("BottomlessBag", None)]


def ladder(cur):
    steps = []
    for i, (k, cap) in enumerate(BAGS):
        st = "done" if i < cur else ("now" if i == cur else ("next" if i == cur + 1 else "later"))
        pic = {"name": "Pic", "w": 58, "h": 58, "radius": 16, "fill": "FFFFFF" if st in ("now", "next") else v("cozy/sand"), **BORDER,
               "opacity": 0.5 if st == "later" else 1, "layout": "H", "main": "CENTER", "cross": "CENTER", "clip": False,
               **({"effects": [{"color": "FF9E80", "a": 1, "spread": 3, "blur": 0}]} if st == "now" else {}),
               "children": [img("equipment/" + k, 48)]}
        if k == "BottomlessBag":
            pic["children"].append(dict({"name": "Robux Tag", "layout": "H", "pad": [2, 5, 2, 5], "radius": 999, "fill": v("cozy/mint"),
                                         "children": [vec("icon_robux", "FFFFFF", 12)]}, absolute=True, x=40, y=-6))
        steps.append({"name": "Tier " + k, "layout": "V", "gap": 4, "cross": "CENTER", "w": 64, "children": [
            pic, ftxt(cap, 15, "3D4B5C" if st != "later" else "9AA5B1", name="Slots") if cap else vec("icon_infinity", "9AA5B1", 18)]})
    return {"name": "Ladder", "layout": "H", "gap": 6, "cross": "CENTER", "children": steps}


def bag_modal(robux=False):
    if robux:
        frm, to, cur = "30 slots", "Unlimited", 4
        msg = "The last bag is Robux only. Bottomless Bag = Infinite Bag pass: never fill your bag again."
        foot = [btn("Ghost", "Cancel", "Btn Cancel", fillW=True), robux48(349, "GET", w=200)]
    else:
        frm, to, cur = "20 slots", "30 slots", 3
        msg = "Bags are upgrades: each one replaces the last, you never go back to a smaller bag."
        foot = [btn("Ghost", "Cancel", "Btn Cancel", fillW=True), act48("UPGRADE", "gold", "ui/status/coin", "250k", w=200)]
    nxt = BAGS[cur + 1][0]
    body = [img("equipment/" + nxt, 84), text("Upgrade Bag", "Title", name="Title", align="CENTER", w=460),
            {"name": "Change", "layout": "H", "gap": 10, "cross": "CENTER", "children": [
                ftxt(frm, 22, "3D4B5C", name="From"), text("→", "Title", "cozy/subtext", name="Arrow"), ftxt(to, 22, "4FB58C", name="To")]},
            ladder(cur), text(msg, "Small", "cozy/subtext", name="Message", align="CENTER", w=460)]
    return es.modal("Modal Bag Upgrade" + (" Robux" if robux else ""), body, foot, w=520, x=(W - 520) // 2, y=120)


def s_bag(robux=False):
    return m.screen("Bag Upgrade" + (" · Robux" if robux else ""), [m.stats_card(), bag_modal(robux)], dim=True)


# ---------------------------------------------------------------- Character v2
CW, CH = 720, 520
CX, CY = (W - CW) // 2, 110
LEFT_W = 232
C_SLOT = 72


def equip_slot(label, key, rarity, count=None):
    s = item_slot(key, rarity, count or 1, size=52, name="Slot")
    if not count:
        s["children"][0]["children"] = [c for c in s["children"][0]["children"] if c.get("name") != "Count Row"]
    return {"name": "Equip " + label, "layout": "V", "gap": 3, "cross": "CENTER", "children": [s, text(label.upper(), "Caption", "cozy/subtext", name="Label")]}


def avatar():
    kids = es.eh.player(LEFT_W // 2, 80, vip=True)
    kids[0].update(w=60, h=117, x=LEFT_W // 2 - 30)
    for c, (w, h, x, y) in zip(kids[0]["children"], [(41, 41, 9, 0), (49, 55, 5, 41), (38, 25, 11, 92)]):
        c.update(w=w, h=h, x=x, y=y)
    kids[1]["y"] = 26
    return {"name": "Avatar (ViewportFrame)", "w": LEFT_W, "h": 216, "radius": 18, "clip": True,
            "fill": {"grad": ["DDF5EE", "A8DCD8"], "angle": 90}, **BORDER, "children": [
                {"type": "ELLIPSE", "name": "Stand", "w": 140, "h": 26, "x": LEFT_W // 2 - 70, "y": 180, "fill": v("cozy/mint", 0.45)}] + kids
                + [dict(text("drag to spin", "Caption", "cozy/subtext", name="Hint"), x=LEFT_W // 2 - 36, y=196)]}


def stat_line(label, value):
    return {"name": "Stat " + label, "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "children": [
        text(label, "Small", "cozy/subtext", name="Label"), text(value, "Small", "cozy/text", name="Value")]}


C_TABS = [("rods", "Rods"), ("lines", "Lines"), ("baits", "Baits"), ("auras", "Auras")]
OWNED = [("equipment/DriftwoodRod", "Common", None), ("equipment/BambooRod", "Uncommon", None), ("equipment/CoralRod", "Rare", "selected"),
         ("equipment/MoonsilverRod", "Epic", "ring"), ("equipment/SweetheartRod", "Rare", "new")]


def char_window():
    left = {"name": "Loadout", "layout": "V", "gap": 10, "w": LEFT_W, "children": [
        avatar(),
        {"name": "Equipped", "layout": "H", "gap": 0, "main": "SPACE_BETWEEN", "fillW": True, "children": [
            equip_slot("Rod", "equipment/CoralRod", "Rare"), equip_slot("Line", "equipment/NylonLine", "Rare"),
            equip_slot("Bait", "equipment/Worm", "Bait", 23), equip_slot("Aura", "auras/SolarFlare", "Epic")]},
        {"name": "Totals", "layout": "V", "gap": 1, "pad": [8, 12, 8, 12], "radius": 14, "fill": v("cozy/sand"), "fillW": True, "children": [
            stat_line("Luck", "+60%"), stat_line("Reel Power", "+30%"), stat_line("Max Depth", "150m")]}]}
    tabs = {"name": "Tabs", "layout": "H", "gap": 6, "children": []}
    for k, lab in C_TABS:
        on = k == "rods"
        tabs["children"].append({"name": "Tab " + lab, "layout": "H", "gap": 6, "pad": [5, 12, 5, 6], "radius": 999, "cross": "CENTER",
                                 "fill": v("cozy/coral") if on else v("cozy/sand"), **({} if on else BORDER), "children": [
                                     img("ui/tabs/" + k, 24, fill={"hex": "E5DBFA", "opacity": 0.6}),
                                     text(lab, "Heading", "cozy/on-accent" if on else "cozy/subtext", name="Label")]})
    cells = []
    for key, r, st in OWNED:
        s = item_slot(key, r, 1, size=C_SLOT, state=None if st == "ring" else st, name=key.split("/")[-1])
        s["children"][0]["children"] = [c for c in s["children"][0]["children"] if c.get("name") != "Count Row"]
        if st == "ring":
            s["children"][0]["stroke"], s["children"][0]["strokeW"] = v("cozy/sky-lip"), 3
        cells.append(s)
    cells.append(get_more(C_SLOT))
    cols = 5
    rows = [cells[i:i + cols] for i in range(0, len(cells), cols)]
    right = {"name": "Items", "layout": "V", "gap": 12, "fillW": True, "clip": False, "children": [
        tabs, {"name": "Grid [scroll]", "layout": "V", "gap": 10, "pad": [6, 0, 0, 0], "h": 3 * C_SLOT + 2 * 10 + 6, "clip": False, "children": [
            {"name": f"Row {i + 1}", "layout": "H", "gap": 8, "clip": False, "children": r} for i, r in enumerate(rows)]},
        text("Tap an item to see it. Coral tick = equipped.", "Caption", "cozy/subtext", name="Hint")]}
    header = {"name": "Header", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        text("Character", "Title", name="Title"), cap_pill(upgrade=False), {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, btn("Danger", "X", "Btn Close")]}
    body = {"name": "Body", "layout": "H", "gap": 20, "fillW": True, "clip": False, "children": [left, right]}
    return {"name": "Window Character", "layout": "V", "pad": 20, "gap": 12, "w": CW, "h": CH, "x": CX, "y": CY, "radius": 24, "clip": False,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [header, body]}


def char_slot_pos(col, row):
    x = CX + 20 + LEFT_W + 20 + col * (C_SLOT + 8)
    y = CY + 20 + 44 + 12 + 34 + 12 + 6 + row * (C_SLOT + 10)
    return x, y


def s_character():
    sx, sy = char_slot_pos(3, 0)
    c = d.c_rod_owned(nub_side="left", nub_y=C_SLOT // 2 - 4, x=sx + C_SLOT + 12, y=sy - 6)
    return m.screen("Character", [char_window(), c], dim=True)


def s_character_equipped():
    """Tapping an equipped slot on the left opens the card to the right of it (EQUIPPED + ENHANCE)."""
    x = CX + 20
    y = CY + 20 + 44 + 12 + 216 + 10          # top of the equipped Rod slot
    top = 290                                  # card clamped inside the screen; nub still points at the slot centre
    c = d.c_rod_equipped(nub_side="left", nub_y=y + 26 - 10 - top, x=x + 52 + 12, y=top)
    return m.screen("Character · equipped slot", [char_window(), c], dim=True)


# ---------------------------------------------------------------- boards
def kinds_board():
    owned = [d.c_rod_owned(nub_side=None), d.c_rod_equipped(nub_side=None), d.c_line(nub_side=None), d.c_aura(nub_side=None),
             d.c_fish(nub_side=None), d.c_bait(nub_side=None), d.c_treasure(nub_side=None), d.c_material(nub_side=None)]
    no = [d.c_not_owned_rod(nub_side=None), d.c_not_owned_aura(nub_side=None)]
    w = 4 * CARD_W + 3 * 16
    return board("Item Card A · every kind (buttons fixed 48 high)", "Label and cost share one line inside the 48px button; icon buttons are 48x48. "
                 "Owned = Actions; not owned = Get from only.", [
                     {"name": "Owned", "layout": "H", "wrap": True, "gap": 16, "rowGap": 16, "w": w, "children": owned},
                     text("Not owned", "Heading", name="Sub"),
                     {"name": "Not owned", "layout": "H", "gap": 16, "children": no}], w=w + 48)


SPEC = ("Sizes\n"
        "  Inventory window 600x480 (was 760x610), radius 24, pad 20. Slots 72, gap 8 / 10, 7 columns, 4 rows (3 with a footer).\n"
        "  Bookmark tabs 50x42 (selected 58x42, panel colour, merges with the window), 48px apart, stick out 42px on the left, icon 32.\n"
        "  Item Card 280 wide, pad 16, nub 12x20. Action buttons: height 48 fixed, label + divider + cost on one line; icon buttons 48x48.\n"
        "\n"
        "Tabs: All, Fish, Rods, Lines, Auras, Baits, Treasure, Materials. Red dot = new items in that tab. Empty slot = 3 small bubbles on sand (option 5), Get More = coral More arrow tile.\n"
        "  Footer only where it has a job:\n"
        "  Fish / All = SELL ALL, Auras = ROLL AURA, Treasure = OPEN ALL, others no footer (grid gets the 4th row).\n"
        "\n"
        "Bags: ladder Starter Pouch 6, Woven Basket 10, Fish Crate 15, Ice Coolbox 20, Ship's Hold 30 (coins), Bottomless Bag = unlimited, Robux only "
        "(the Infinite Bag pass, 349 R$). Capacity pill hides UPGRADE once the bag is Bottomless.\n"
        "\n"
        "Character v2: no Bag slot any more (bag is an upgrade, shown as the capacity pill). Equipped row = Rod, Line, Bait, Aura. "
        "Right side = owned items of the tab; tapping any slot (owned grid or equipped row) opens the same Item Card.")


def build():
    sx, sy = 27200, 6600
    blocks = [("18 F1 · Rods tab (owned rod)", s_rods()), ("18 F2 · Fish tab (SELL ALL footer)", s_fish()), ("18 F3 · Auras tab (not owned, card flips left)", s_auras()),
              ("18 F4 · Bag Upgrade (coins)", s_bag(False)), ("18 F5 · Bag Upgrade (last tier, Robux only)", s_bag(True))]
    kids = []
    for i, (t, scr) in enumerate(blocks):
        kids.append(es.screen_block(t, scr, 60 + (i % 3) * 1400, 200 + (i // 3) * 900))
    kids.append(dict(board("Spec", None, [text(SPEC, "Body", name="Spec", w=1180)], w=1228), x=2860, y=1100))
    kids.append(dict(kinds_board(), x=60, y=2040))
    sec18 = {"type": "SECTION", "name": "18 · Inventory (Bookmark Tabs) — FINAL", "fill": "F3E9D8", "x": sx, "y": sy, "children": [
        text("18 · Inventory (Bookmark Tabs) — FINAL", "Display", name="Title", x=60, y=40),
        text("Picked option 2, made smaller (600x480). Item Card A with 48px buttons. Bottomless Bag = Robux only.", "Body", "cozy/subtext", name="Sub", x=60, y=100, w=4000)] + kids}

    ckids = [es.screen_block("17 · Character v2 — owned rod opened from the grid", s_character(), 60, 160),
             es.screen_block("17 · Character v2 — equipped slot opened", s_character_equipped(), 60, 960)]
    sec17 = {"type": "SECTION", "name": "17 · Character (equipment swap)", "fill": "F3E9D8", "x": 14400, "y": 1800, "children": [
        text("17 · Character v2 — Rod / Line / Bait / Aura (no Bag)", "Display", name="Title", x=60, y=40),
        text("Matches Inventory 18 FINAL: smaller window (720x520), tab chips with the new tab icons, tap any item = Item Card A (48px buttons).",
             "Body", "cozy/subtext", name="Sub", x=60, y=100, w=2600)] + ckids}
    return [{"pageId": PAGE_ID, "replaceName": sec18["name"], "tree": sec18}, {"pageId": PAGE_ID, "replaceName": sec17["name"], "tree": sec17}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "24_inventory_final_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
