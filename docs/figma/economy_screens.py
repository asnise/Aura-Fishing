"""Economy UI steps 0 + 2–7 (docs/HANDOFF_ECONOMY_UI.md): every remaining screen / part, one Figma section each,
stacked in a column at x 17000 (step 1 HUD + Streak lives in economy_hud.py, Character in character_window.py).

  0 Icons        new art (sheets 10–16) + global vector icons (white, tintable)
  2 Aquarium     Aquarium window, add-fish picker, offline popup (+ capped), Inventory: put in aquarium + hot badge  (C14, C18)
  3 Mastery      7 upgrade tracks paid with Pearls  (C15)
  4 Enhance      Shop rows with +N / ENHANCE / k-M prices, Enhance popup  (C16)
  5 Auras+Gacha  stars 1-5 + Star Token, two pity rows, x10 Rare+, Rates popup, duplicate token, G6 summary  (C17)
  6 Store        Robux store (Passes / Gems / Boosts / Packs) + Starter Pack offer  (C6, C19)
  7 Hot fish+Hub Sell All with hot bonus, Merchant HOT FISH board, Main Menu hub with new tiles  (C18, C14, C15, C6)

Nothing existing is touched. Robux prices are final (user, 2026-11-17).

Run:  python -I docs/figma/economy_screens.py docs/figma/out [keys...]   (keys: icons aquarium mastery enhance auras store hot)
Send: python -I docs/figma/apply_patch.py docs/figma/out/22_economy_<key>_ops.json
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
btn, chip, tag, img, ftxt, small_pill, item_slot = m.btn, m.chip, m.tag, m.img, m.ftxt, m.small_pill, m.item_slot
W, H, SAFE_TOP, WIN_W, WIN_H = m.W, m.H, m.SAFE_TOP, m.WIN_W, m.WIN_H
RAR = m.RARITY_HEX
OUTLINE = {"textStroke": "3D4B5C"}
COL_X = 17000
WX, WY = (W - WIN_W) // 2, SAFE_TOP


# ================================================================ shared bits
def svgn(body, size, name, vb=48, **kw):
    d = {"type": "SVG", "svg": f'<svg width="{size}" height="{size}" viewBox="0 0 {vb} {vb}" fill="none" xmlns="http://www.w3.org/2000/svg">{body}</svg>',
         "w": size, "h": size, "name": name}
    d.update(kw)
    return d


def vec(kind, color="FFFFFF", size=40):
    """Global vector icons (§5): white by default so code can tint them."""
    c = "#" + color
    bodies = {
        "icon_star": f'<path d="M24 4l6 12.6 13.8 1.6-10.2 9.4 2.8 13.6L24 34.4 11.6 41.2l2.8-13.6L4.2 18.2 18 16.6z" fill="{c}"/>',
        "icon_star_empty": f'<path d="M24 6.5l5.3 11.1 12.1 1.4-9 8.3 2.5 12L24 33.2l-10.9 6.1 2.5-12-9-8.3 12.1-1.4z" stroke="{c}" stroke-width="4" stroke-linejoin="round"/>',
        "icon_arrow_up": f'<path d="M24 6 40 24H30v18H18V24H8z" fill="{c}" stroke="{c}" stroke-width="2" stroke-linejoin="round"/>',
        "icon_flame": f'<path d="M24 3c2 7.5 12.4 12.4 12.4 24A12.4 12.4 0 0 1 11.6 27c0-5.5 2.8-9 5.5-11.4 0 4.6 2 6.6 4.5 6.6 0-6.9-1-13.8 2.4-19.2z" fill="{c}"/>',
        "icon_infinity": f'<path d="M24 24c-4-5-7-8-11-8a8 8 0 0 0 0 16c4 0 7-3 11-8s7-8 11-8a8 8 0 0 1 0 16c-4 0-7-3-11-8z" stroke="{c}" stroke-width="5" stroke-linecap="round"/>',
        "icon_timer": f'<circle cx="24" cy="27" r="16" stroke="{c}" stroke-width="5"/><path d="M24 27V17" stroke="{c}" stroke-width="5" stroke-linecap="round"/>'
                      f'<rect x="18" y="3" width="12" height="5" rx="2.5" fill="{c}"/>',
        "icon_info": f'<circle cx="24" cy="24" r="19" fill="{c}"/><rect x="21" y="21" width="6" height="15" rx="3" fill="#3D4B5C"/><circle cx="24" cy="14.5" r="3.5" fill="#3D4B5C"/>',
        "icon_lock": f'<rect x="9" y="21" width="30" height="22" rx="6" fill="{c}"/><path d="M16 21v-5a8 8 0 0 1 16 0v5" stroke="{c}" stroke-width="5"/>',
        "icon_robux": f'<path fill="{c}" fill-rule="evenodd" d="M24 2 43 13v22L24 46 5 35V13zM18 18h12v12H18z"/>',
        "icon_clover": f'<circle cx="17" cy="17" r="8" fill="{c}"/><circle cx="31" cy="17" r="8" fill="{c}"/><circle cx="17" cy="31" r="8" fill="{c}"/><circle cx="31" cy="31" r="8" fill="{c}"/>'
                       f'<path d="M30 30l10 12" stroke="{c}" stroke-width="4" stroke-linecap="round"/>',
        "icon_bar": f'<rect x="19" y="4" width="10" height="40" rx="5" stroke="{c}" stroke-width="4"/><rect x="16" y="18" width="16" height="14" rx="5" fill="{c}"/>',
        "icon_reel": f'<circle cx="24" cy="24" r="16" stroke="{c}" stroke-width="5"/><circle cx="24" cy="24" r="5" fill="{c}"/><path d="M24 24 36 12" stroke="{c}" stroke-width="5" stroke-linecap="round"/>',
    }
    return svgn(bodies[kind], size, kind)


GLOBAL_ICONS = ["icon_star", "icon_star_empty", "icon_arrow_up", "icon_flame", "icon_infinity", "icon_timer", "icon_info",
                "icon_lock", "icon_robux", "icon_clover", "icon_bar", "icon_reel"]


def stars(n, size=16, total=5):
    return {"name": f"Stars {n}", "layout": "H", "gap": 2, "children": [
        vec("icon_star", "F2B544", size) if i < n else vec("icon_star", "E6DCCB", size) for i in range(total)]}


def cost(key, value, color="FFFFFF", size=16, fs=14):
    return {"name": "Cost", "layout": "H", "gap": 4, "cross": "CENTER", "children": [img(key, size), ftxt(value, fs, color, name="Value")]}


def lip_btn(name, children, style="mint", w=None, vertical=False, pad=(8, 14, 11, 14), disabled=False):
    fill, lip = (v("cozy/sand"), v("cozy/track")) if disabled else (v("cozy/" + style), v("cozy/" + style + "-lip"))
    d = {"name": name, "layout": "V" if vertical else "H", "gap": 2 if vertical else 6, "pad": list(pad), "radius": 16, "cross": "CENTER", "main": "CENTER",
         "fill": fill, "stroke": lip, "strokeSides": {"b": 5}, "children": children}
    if w:
        d["w"] = w
    return d


def two_line_btn(label, key, value, style="mint", w=118, disabled=False):
    c = "9AA5B1" if disabled else "FFFFFF"
    return lip_btn("Btn " + label.title(), [ftxt(label, 15, c, name="Label"), cost(key, value, c)], style, w, vertical=True, pad=(7, 10, 10, 10), disabled=disabled)


def robux_btn(price, w=None, name="Btn Buy"):
    return lip_btn(name, [vec("icon_robux", "FFFFFF", 18), ftxt(str(price), 18, "FFFFFF", name="Price")], "mint", w)


def board(title, desc, kids, w=None, layout="V", gap=14):
    d = {"name": title, "layout": "V", "gap": 10, "pad": 24, "radius": 24, "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
        text(title, "Title", name="Title")]}
    if desc:
        d["children"].append(text(desc, "Small", "cozy/subtext", name="Desc", w=(w or 600) - 48))
    if kids:
        d["children"].append({"name": "Body", "layout": layout, "gap": gap, "children": kids})
    if w:
        d["w"] = w
    return d


def screen_block(title, scr, x, y):
    return {"name": "Screen " + title, "layout": "V", "gap": 12, "x": x, "y": y, "children": [text(title, "Title", name="Title"), scr]}


def section(key, name, title, sub, kids, y):
    return {"type": "SECTION", "name": name, "fill": "F3E9D8", "x": COL_X, "y": y, "children": [
        text(title, "Display", name="Title", x=60, y=40), text(sub, "Body", "cozy/subtext", name="Sub", x=60, y=96, w=2200)] + kids}


def modal(name, body, footer, w=560, x=None, y=None):
    d = {"name": name, "layout": "V", "w": w, "radius": 36, "clip": True, "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
        {"name": "Body", "layout": "V", "gap": 10, "pad": [34, 40, 26, 40], "fillW": True, "cross": "CENTER", "children": body},
        {"name": "Footer", "layout": "H", "gap": 16, "pad": [16, 32, 20, 32], "fillW": True, "main": "CENTER", "fill": v("cozy/sand"), "children": footer}]}
    if x is not None:
        d["x"], d["y"] = x, y
    return d


def pearl_chip(value="1,250"):
    return chip_like("Pearls", "ui/status/pearl", value)


def chip_like(name, key, value):
    return {"name": name, "layout": "H", "gap": 8, "pad": [6, 16, 6, 8], "cross": "CENTER", "radius": 999, "fill": v("cozy/panel"), **BORDER,
            "children": [img(key, 24), text(value, "Number", name="Value")]}


def info_pill(label, color="cozy/subtext", fill="cozy/sand", icon=None):
    kids = ([icon] if icon else []) + [text(label, "Caption", color, name="Label")]
    return {"name": "Pill " + label, "layout": "H", "gap": 5, "pad": [5, 12, 5, 10], "radius": 999, "cross": "CENTER", "fill": v(fill), "children": kids}


def hot_badge(mult=3):
    return {"name": "Hot", "layout": "H", "gap": 2, "pad": [2, 7, 2, 5], "radius": 999, "cross": "CENTER", "fill": eh.BLAZE_GRAD, "stroke": "FFFFFF", "strokeW": 2,
            "children": [eh.flame(11), ftxt(f"x{mult}", 12, "FFFFFF", name="Value")]}


# ================================================================ 0 · Icons
ART = {
    "ui/status": ["pearl", "star_token", "hot_streak", "hot_price", "boost", "offline_reward", "enhance", "mastery_up", "pearl_pile"],
    "ui/icons": ["aquarium", "mastery", "store", "vip", "infinite_bag", "auto_pro", "extra_cast", "starter_pack", "daily_login"],
    "ui/shop": ["gems_s", "gems_m", "gems_l", "coins_s", "coins_m", "coins_l", "boost_coins", "boost_pearls", "starter_bundle"],
    "materials": ["abyss_scale", "glow_ink", "coral_shard", "naga_scale", "void_essence", "enhance_stone", "moon_pearl", "kelp_fiber", "star_shard"],
    "fish": ["GloomSprat", "InkletSquid", "PearlNautilus", "FrostRay", "LanternJellyfish", "BoneCarp", "StarlightEel", "AbyssLeviathan", "VoidKoi"],
    "auras": ["TidalBloom", "CoralHeart", "MoonlitRipple", "KelpWhisper", "StormCurrent", "FrostPearl", "NebulaKoi", "LotusNaga", "CelestialLeviathan"],
    "equipment": ["SweetheartRod", "AbyssRod", "CelestialRod", "AbyssLine", "StarLine", "BottomlessBag", "PearlBait", "SquidBait", "StormBait"],
}


def art_cell(folder, name):
    return {"name": "Art " + name, "layout": "V", "gap": 4, "w": 104, "cross": "CENTER", "children": [
        {"name": "Tile", "w": 88, "h": 88, "radius": 18, "fill": "FFFFFF", **BORDER, "layout": "H", "main": "CENTER", "cross": "CENTER",
         "children": [img(f"{folder}/{name}", 76)]},
        text(name, "Caption", "cozy/subtext", name="Key", align="CENTER", w=104)]}


def s_icons():
    rows = [board(f"{folder}/", None, [{"name": "Row", "layout": "H", "gap": 8, "children": [art_cell(folder, n) for n in names]}], layout="V")
            for folder, names in ART.items()]
    art = {"name": "Art", "layout": "V", "gap": 20, "x": 60, "y": 160, "children": rows}
    def vcell(k):
        return {"name": "Vec " + k, "layout": "V", "gap": 6, "w": 112, "cross": "CENTER", "children": [
            {"name": "Tile", "w": 64, "h": 64, "radius": 18, "fill": v("cozy/text"), "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [vec(k, "FFFFFF", 40)]},
            {"name": "Tinted", "layout": "H", "gap": 6, "children": [vec(k, c, 22) for c in ("F2B544", "FF9E80", "7FD3B0", "B79CF2")]},
            text(k, "Caption", "cozy/subtext", name="Key", align="CENTER", w=112)]}
    vecs = board("Global vector icons (§5)", "White SVG so code tints them (ImageColor3). Export from here as 64px PNG for Roblox.",
                 [{"name": "Row 1", "layout": "H", "gap": 10, "children": [vcell(k) for k in GLOBAL_ICONS[:6]]},
                  {"name": "Row 2", "layout": "H", "gap": 10, "children": [vcell(k) for k in GLOBAL_ICONS[6:]]}], w=800)
    vecs.update(x=1100, y=160)
    return [art, vecs]


# ================================================================ 2 · Aquarium + offline + inventory
TANK = [("GlowEel", "Rare", "fish/mut_glowing", "+0.045/s"), ("DewdropKoi", "Rare", None, "+0.025/s"), ("CrystalGuppy", "Epic", None, "+0.067/s"),
        ("PearlClam", "Uncommon", None, "+0.008/s"), ("CoralSeahorse", "Legendary", None, "+0.20/s")]


def tank_card(fish=None, rarity="Common", mut=None, rate=None, state=None, price=None):
    W_, H_ = 162, 176
    if state == "empty":
        kids = [ftxt("+", 44, "C9BBA3", name="Plus", x=66, y=44), text("Add fish", "Small", "cozy/subtext", name="Label", align="CENTER", w=W_, x=0, y=108)]
        return {"name": "Btn Tank Empty", "w": W_, "h": H_, "radius": 18, "fill": v("cozy/sand"), **BORDER, "children": kids}
    if state == "locked":
        kids = [dict(vec("icon_lock", "B5A88F", 34), x=64, y=40),
                text("Expand", "Small", "cozy/subtext", name="Label", align="CENTER", w=W_, x=0, y=86),
                dict(two_line_btn("EXPAND", "ui/status/coin", price, "gold", w=118), x=22, y=112)]
        return {"name": "Btn Tank Locked", "w": W_, "h": H_, "radius": 18, "fill": v("cozy/sand"), **BORDER, "opacity": 1, "children": kids}
    col = RAR[rarity]
    kids = [
        {"type": "RECT", "name": "Water", "w": W_, "h": 118, "x": 0, "y": 0, "fill": {"grad": ["D3ECFA", "A9DCF7"], "angle": 90}},
        {"type": "ELLIPSE", "name": "Bubble", "w": 10, "h": 10, "x": 18, "y": 22, "fill": {"hex": "FFFFFF", "opacity": 0.6}},
        {"type": "ELLIPSE", "name": "Bubble", "w": 6, "h": 6, "x": 30, "y": 42, "fill": {"hex": "FFFFFF", "opacity": 0.6}},
        img("fish/" + fish, 96, x=33, y=12),
        dict(m.corner_svg(col, 32)),
        text("".join(" " + ch if ch.isupper() else ch for ch in fish).strip(), "Heading", "cozy/text",
             name="FishName", x=12, y=124),
        {"name": "Rate", "layout": "H", "gap": 4, "pad": [3, 8, 3, 5], "radius": 999, "cross": "CENTER", "x": 10, "y": 148, "fill": "FFFFFF",
         "children": [img("ui/status/pearl", 16), text(rate, "Caption", "cozy/mint-lip", name="Value")]},
        {"name": "Btn Remove", "w": 26, "h": 26, "x": 126, "y": 146, "radius": 999, "fill": "FFFFFF", **BORDER, "layout": "H", "main": "CENTER", "cross": "CENTER",
         "children": [svgn('<path d="M15 15l18 18M33 15 15 33" stroke="#7A8A99" stroke-width="6" stroke-linecap="round"/>', 12, "Icon x")]},
    ]
    if mut:
        kids.append(img(mut, 26, x=W_ - 32, y=6))
    return {"name": "Tank " + fish, "w": W_, "h": H_, "radius": 18, "clip": True, "fill": "FFFFFF", **BORDER, "children": kids}


def aquarium_window():
    head = {"name": "Head", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        pearl_chip("1,250.38"),
        info_pill("+0.34/s", "cozy/mint-lip", "cozy/panel"),
        info_pill("Offline cap 4h", icon=vec("icon_timer", "7A8A99", 14)),
        {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        text("Slots 6 / 20", "Small", "cozy/subtext", name="Slots"),
        {"name": "Btn Mastery", "layout": "H", "gap": 5, "pad": [5, 12, 5, 10], "radius": 999, "fill": v("cozy/sky"),
         "children": [dict(vec("icon_timer", "FFFFFF", 14), name="icon_timer"), text("MASTERY ›", "Caption", "cozy/on-accent", name="Label")]}]}
    cards = [tank_card(*t) for t in TANK] + [tank_card(state="empty"), tank_card(state="locked", price="5,000"), tank_card(state="locked", price="20k")]
    grid = {"name": "Grid", "layout": "V", "gap": 12, "children": [
        {"name": "Row 1", "layout": "H", "gap": 12, "children": cards[:4]}, {"name": "Row 2", "layout": "H", "gap": 12, "children": cards[4:]}]}
    foot = {"name": "Footer", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
        text("Fish here make Pearls, even while you're offline.", "Small", "cozy/subtext", name="Hint"), chip("Coins", "12.4k")]}
    return m.window("Aquarium", WIN_W, WX, WY, [head, grid, foot], h=WIN_H)


# ---- Put in Tank: own window, multi-select every fish stack, CONFIRM; stacks > 1 open a quantity slider modal
# (fish, rarity, owned, picked, rate/each, mutation)
PICK = [
    ("CoralSeahorse", "Legendary", 1, 1, "+0.20/s", None),
    ("CrystalGuppy", "Epic", 1, 0, "+0.067/s", None),
    ("MoonJelly", "Rare", 1, 0, "+0.045/s", "fish/mut_glowing"),
    ("DewdropKoi", "Rare", 2, 0, "+0.025/s", None),
    ("PearlClam", "Uncommon", 6, 2, "+0.008/s", None),
    ("BubbleCarp", "Common", 41, 1, "+0.003/s", None),
]
FREE = 6   # free tank slots in the sample


def nice(fish):
    return "".join(" " + ch if ch.isupper() else ch for ch in fish).strip()


def pick_cell(fish, rar, owned, picked, rate, mut, dim=False):
    """Fishdex-style 4:3 card (228 x 184) with matching dual badge rows."""
    pic_kids = [img("fish/" + fish, 96, 64)]
    if mut:
        pic_kids.append({"type": "FRAME", "name": "Mutation", "w": 24, "h": 24, "x": 6, "y": 6, "children": [img(mut, 24)]})
    pic = {
        "name": "Picture", "w": 204, "h": 70, "radius": 12, "fill": {"hex": "F4FAFD"},
        "layout": "H", "main": "CENTER", "cross": "CENTER", "children": pic_kids,
    }
    name_txt = text(nice(fish), "Heading", "cozy/text", name="Name")

    # Row 1 (Specs): Rarity Tag + Pearl Rate Pill
    rate_pill = {
        "name": "Rate", "layout": "H", "gap": 4, "pad": [3, 10, 4, 8], "radius": 999, "cross": "CENTER",
        "fill": v("cozy/sand"), "children": [img("ui/status/pearl", 14), text(rate, "Caption", "cozy/mint-lip", name="Value")],
    }
    row_specs = {
        "name": "Specs", "layout": "H", "gap": 6, "cross": "CENTER",
        "children": [tag(rar), rate_pill],
    }

    # Row 2 (Bag & Action): In Bag Badge + Selection Status Badge
    bag_badge = {
        "name": "Bag", "layout": "H", "gap": 0, "pad": [3, 10, 4, 10], "radius": 999, "cross": "CENTER",
        "fill": v("cozy/sand"), "children": [text(f"In Bag: x{owned}", "Caption", "cozy/text", name="Label")],
    }
    if picked:
        if owned > 1:
            action_badge = {
                "name": "Status", "layout": "H", "gap": 0, "pad": [3, 12, 4, 12], "radius": 999, "cross": "CENTER",
                "fill": v("cozy/coral"), "children": [ftxt(f"{picked} / {owned}", 12, "FFFFFF", name="Label")],
            }
        else:
            action_badge = {
                "name": "Status", "layout": "H", "gap": 0, "pad": [3, 12, 4, 12], "radius": 999, "cross": "CENTER",
                "fill": v("cozy/mint"), "children": [ftxt("SELECTED", 12, "FFFFFF", name="Label")],
            }
    else:
        action_badge = {
            "name": "Status", "layout": "H", "gap": 0, "pad": [3, 12, 4, 12], "radius": 999, "cross": "CENTER",
            "fill": "FFFFFF", "stroke": v("cozy/track"), "strokeW": 1.5,
            "children": [text("+ Select", "Caption", "cozy/subtext", name="Label")],
        }

    row_action = {
        "name": "Action Row", "layout": "H", "gap": 6, "cross": "CENTER",
        "children": [bag_badge, action_badge],
    }

    border_stroke = v("cozy/coral") if picked else v("cozy/track")
    border_w = 3 if picked else 2

    card = {
        "name": "Card " + fish, "layout": "V", "gap": 6, "pad": [12, 12, 12, 12],
        "w": 228, "h": 184, "radius": 18, "fill": v("cozy/panel"),
        "stroke": border_stroke, "strokeW": border_w,
        "children": [pic, name_txt, row_specs, row_action],
    }
    if dim:
        card["opacity"] = 0.45
    return card


def tank_picker_window():
    picked = [p for p in PICK if p[3]]
    n = sum(p[3] for p in picked)
    head = {"name": "Head", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        info_pill(f"{FREE - n}/{FREE}", "cozy/sky-lip", "cozy/sand", img("ui/icons/aquarium", 18)),
        info_pill("Sort: Best rate", icon=vec("icon_arrow_up", "7A8A99", 12)),
        {"name": "Spacer", "w": 1, "h": 1, "fillW": True},
        {"name": "Filters", "layout": "H", "gap": 6, "children": [
            {"name": "Tab " + t, "layout": "H", "pad": [6, 12, 6, 12], "radius": 999, "fill": v("cozy/coral") if t == "All" else v("cozy/sand"),
             "children": [text(t, "Heading", "cozy/on-accent" if t == "All" else "cozy/subtext", name="Label")]} for t in ("All", "Rare+", "Mutated")]}]}
    cells = [pick_cell(f, r, o, p, rate, mu) for f, r, o, p, rate, mu in PICK]
    grid = {"name": "Grid", "layout": "H", "wrap": True, "gap": 12, "rowGap": 10, "w": 716, "h": 380, "clip": True, "pad": [2, 0, 0, 0], "children": cells}
    thumbs = [dict(img("fish/" + f, 34), name="Img fish/" + f) for f, r, o, p, *_ in PICK if p]
    total_rate = "+0.22/s"
    bar = {"name": "Selection Bar", "layout": "H", "gap": 12, "pad": [10, 14, 10, 14], "radius": 18, "fillW": True, "cross": "CENTER",
           "fill": v("cozy/sand"), "children": [
               {"name": "Thumbs", "layout": "H", "gap": -8, "children": thumbs},
               {"name": "Text", "layout": "V", "gap": 1, "fillW": True, "children": [
                   text(f"{n} fish selected", "Heading", "cozy/text", name="Count"),
                   {"name": "Rate", "layout": "H", "gap": 4, "cross": "CENTER", "children": [
                       img("ui/status/pearl", 16), text(total_rate + " after confirm", "Caption", "cozy/mint-lip", name="Value")]}]},
               btn("Ghost", "Clear", "Btn Clear"), btn("Success", f"CONFIRM ({n})", "Btn Confirm")]}
    return m.window("Put in Tank", WIN_W, WX, WY, [head, grid, bar], h=WIN_H)


def slider(frac=0.66, w=300):
    fw = round(w * frac)
    return {"name": "Slider", "w": w, "h": 34, "children": [
        {"type": "RECT", "name": "Track", "w": w, "h": 14, "x": 0, "y": 10, "radius": 999, "fill": v("cozy/sand"), **BORDER},
        {"type": "RECT", "name": "Fill", "w": fw, "h": 14, "x": 0, "y": 10, "radius": 999, "fill": v("cozy/coral")},
        {"type": "ELLIPSE", "name": "Knob", "w": 32, "h": 32, "x": fw - 16, "y": 1, "fill": "FFFFFF", "stroke": v("cozy/coral"), "strokeW": 4,
         "effects": [{"color": "3D4B5C", "a": 0.15, "y": 2, "blur": 6}]}]}


def step_btn(label, name):
    return lip_btn(name, [ftxt(label, 24, "FFFFFF", name="Label")], "sky", w=48, pad=(4, 0, 7, 0))


def qty_chip(label, active=False):
    return {"name": "Quick " + label, "layout": "H", "pad": [6, 16, 6, 16], "radius": 999, "fill": v("cozy/coral") if active else v("cozy/sand"),
            "children": [text(label, "Heading", "cozy/on-accent" if active else "cozy/subtext", name="Label")]}


def qty_modal(x=None, y=None):
    pic = {"name": "Picture", "w": 104, "h": 104, "radius": 22, "fill": {"grad": ["D3ECFA", "A9DCF7"], "angle": 90}, **BORDER, "clip": True,
           "children": [img("fish/BubbleCarp", 88, x=8, y=8), m.corner_svg(RAR["Common"], 30)]}
    body = [pic,
            text("Bubble Carp", "Title", name="Title", align="CENTER", w=420),
            text("You have 41 | 3 free slots left", "Small", "cozy/subtext", name="Owned", align="CENTER", w=420),
            {"name": "Value", "layout": "H", "gap": 6, "cross": "CENTER", "children": [
                ftxt("2", 44, "3D4B5C", name="Amount"), ftxt("/ 3", 22, "9AA5B1", name="Max")]},
            {"name": "Slider Row", "layout": "H", "gap": 14, "cross": "CENTER", "children": [
                step_btn("-", "Btn Minus"), slider(0.66, 260), step_btn("+", "Btn Plus")]},
            {"name": "Quick", "layout": "H", "gap": 8, "children": [qty_chip("1"), qty_chip("Half"), qty_chip("MAX 3")]},
            {"name": "Gain", "layout": "H", "gap": 6, "cross": "CENTER", "children": [
                img("ui/status/pearl", 20), text("+0.007/s", "Heading", "cozy/mint-lip", name="Value")]}]
    foot = [btn("Ghost", "Cancel", "Btn Cancel", fillW=True), btn("Success", "CONFIRM", "Btn Confirm", fillW=True)]
    return modal("Quantity", body, foot, w=480, x=x, y=y)


def picker_screen():
    return m.screen("Put in Tank", [tank_picker_window()], dim=True)


def qty_screen():
    scr = m.screen("Put in Tank · quantity", [tank_picker_window()], dim=True)
    scr["children"].insert(-1, {"type": "RECT", "name": "Dim", "w": W, "h": H, "x": 0, "y": 0, "fill": {"hex": "3D4B5C", "opacity": 0.45}})
    scr["children"].insert(-1, qty_modal((W - 480) // 2, 70))
    return scr


def offline_popup(capped=False, x=None, y=None):
    body = [img("ui/status/offline_reward", 110),
            text("While you were away", "Title", name="Title", align="CENTER", w=460),
            text("Away 6h 12m | capped at 4h" if capped else "Away 3h 20m", "Body", "cozy/subtext", name="Away", align="CENTER", w=460),
            {"name": "Amount", "layout": "H", "gap": 8, "cross": "CENTER", "children": [img("ui/status/pearl", 40), ftxt("+2,450" if not capped else "+4,968", 40, "8C6FD6", name="Value")]}]
    if capped:
        body.append(info_pill("Cap full — raise it in Mastery or with VIP (12h)", "cozy/danger-lip", "cozy/sand", vec("icon_info", "F27A7A", 14)))
    foot = [btn("Success", "COLLECT", "Btn Collect", fillW=True),
            lip_btn("Btn Collect x2", [ftxt("x2", 20, "FFFFFF", name="Label"), img("ui/shop/boost_pearls", 24)], "gem")]
    return modal("Offline Reward" + (" · capped" if capped else ""), body, foot, w=520, x=x, y=y)


INV2 = [("fish/BubbleCarp", "Common", 41, None, "selected", 3), ("fish/PebbleMinnow", "Common", 23, None, None, 0), ("fish/PearlClam", "Uncommon", 6, None, None, 2),
        ("fish/DewdropKoi", "Rare", 2, None, None, 0), ("fish/CrystalGuppy", "Epic", 1, None, "new", 0), ("fish/ReedPerch", "Common", 12, None, None, 0),
        ("fish/MoonJelly", "Rare", 1, "fish/mut_glowing", None, 0), ("equipment/Worm", "Bait", 14, None, None, 0), ("materials/enhance_stone", "Rare", 4, None, None, 0),
        (None, "Common", 0, None, "empty", 0)]


def inventory_drawer():
    title = {"name": "Title Row", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        img("ui/icons/bag", 40), text("Inventory", "Title", name="Title"),
        {"name": "Capacity", "layout": "H", "gap": 4, "pad": [4, 12, 4, 12], "radius": 999, "cross": "CENTER", "fill": v("cozy/sand"), "children": [
            ftxt("18", 18, "3D4B5C", name="Used"), ftxt("/ 50", 18, "9AA5B1", name="Max")]},
        {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, btn("Danger", "X", "Btn Close")]}
    tabs = {"name": "Tabs", "layout": "H", "gap": 6, "fillW": True, "children": [
        {"name": "Tab " + t, "layout": "H", "pad": [7, 12, 7, 12], "radius": 999, "fill": v("cozy/coral") if t == "All" else v("cozy/sand"),
         "children": [text(t, "Heading", "cozy/on-accent" if t == "All" else "cozy/subtext", name="Label")]} for t in ["All", "Fish", "Bait", "Treasure", "Materials"]]}
    cells = []
    for p, r, n, mu, st, hot in INV2:
        s = item_slot(p, r, n, size=84, state=st, mut=mu, name="Item " + (p.split("/")[-1] if p else "Empty"))
        if hot:
            s["children"].append(dict(hot_badge(hot), x=-6, y=62))
        cells.append(s)
    grid = {"name": "Grid", "layout": "H", "wrap": True, "gap": 10, "rowGap": 12, "w": 460, "pad": [8, 0, 4, 0], "children": cells}
    action = {"name": "Selected", "layout": "H", "gap": 10, "pad": 10, "radius": 18, "fill": v("cozy/sand"), "fillW": True, "cross": "CENTER", "children": [
        img("fish/BubbleCarp", 48),
        {"name": "Text", "layout": "V", "gap": 2, "fillW": True, "children": [
            text("Bubble Carp  x41", "Heading", name="Name"),
            text("HOT x3 | 12m | 1.2k each", "Caption", "cozy/danger-lip", name="Info")]},
        lip_btn("Btn Aquarium", [img("ui/icons/aquarium", 24), ftxt("TANK", 16, "FFFFFF", name="Label")], "sky"),
        lip_btn("Btn Sell", [ftxt("SELL", 16, "FFFFFF", name="Label")], "gold")]}
    foot = {"name": "Footer", "layout": "H", "gap": 10, "fillW": True, "children": [btn("Ghost", "Sort: Value", "Btn Sort", fillW=True), btn("Gold", "SELL ALL", "Btn Sell All", fillW=True)]}
    return {"name": "Inventory", "layout": "V", "gap": 12, "pad": 20, "w": 500, "x": 516, "y": SAFE_TOP - 6, "radius": 32,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [title, tabs, grid, action, foot]}


def s_aquarium():
    y0 = 160
    a = screen_block("C14 · Aquarium", m.screen("Aquarium", [aquarium_window()], dim=True), 60, y0)
    b = screen_block("C14/C18 · Inventory: put in tank + hot fish", m.screen("Inventory", [eh.stats(boosts=()), inventory_drawer()]), 1400, y0)
    c = screen_block("C14 · Offline reward popup", m.screen("Offline", [offline_popup(False, 380, 120)], dim=True), 60, y0 + 800)
    side = {"name": "Parts", "layout": "H", "gap": 30, "x": 1400, "y": y0 + 840, "children": [offline_popup(True)]}
    d = screen_block("C14 · Put in Tank (multi-select)", picker_screen(), 2740, y0)
    e = screen_block("C14 · Quantity modal (stack > 1)", qty_screen(), 2740, y0 + 800)
    flow = board("Put in Tank · flow", None, [], w=1280)
    flow["children"].append(text("- Opens from Aquarium \"+ Add fish\" and from Inventory TANK (that stack pre-picked).\n"
                               "- Shows every fish stack in the bag, best rate first. Tap a single fish = toggle selection.\n"
                               "- Tap a stack > 1 = Quantity modal: slider, -/+, quick 1 / Half / MAX; max = min(owned, free slots left). "
                               "The cell then shows picked/owned (2/41). Setting 0 unpicks it.\n"
                               "- Bottom bar: thumbnails, count, Pearl rate after confirm, Clear, CONFIRM (n). One server call puts every picked fish in.\n"
                               "- If slots are full or selected > free, the confirm button disables and displays \"Full\" (no separate full screen needed).",
                               "Body", "cozy/subtext", name="Desc", w=1232))
    flow.update(x=4080, y=y0)
    notes = board("Data", "Server: { Slots, MaxSlots, NextSlotPrice, Fish = { {Uid, Id, Mutation, Weight, Rate} }, Rate, OfflineCapHours } (remove targets Uid). "
                  "Put in Tank sends PutInTank({ {Id, Mutation, Count} }) in one call, all-or-nothing: short on slots or fish = { ok = false, reason }, nothing added; client caps picks at free slots. "
                  "Rate per fish = rarity base (Common 0.2 … Mythic 40) × mutation. Slots start at 3; expand 5k → 20k → 80k → 300k → 1M. "
                  "Offline popup shows on join only when Pearls > 0. x2 button only when the player owns a 2x Pearls boost.", [], w=1280)
    notes.update(x=60, y=y0 + 1600)
    return [a, b, c, side, d, e, flow, notes]


# ================================================================ 3 · Mastery
TRACKS = [
    ("Luck", "icon_clover", "7FD3B0", 12, "+12%", "+13%", "407", True),
    ("Catch Bar", "icon_bar", "9AD4F5", 8, "+4%", "+4.5%", "210", True),
    ("Reel Power", "icon_reel", "FF9E80", 10, "+10%", "+11%", "330", True),
    ("Auto Wait", "icon_timer", "B79CF2", 5, "-5%", "-6%", "120", True),
    ("Pearl Rate", "img:ui/status/pearl", None, 15, "+15%", "+16%", "620", False),
    ("Offline Cap", "img:ui/status/offline_reward", None, 4, "4h", "4h 30m", "900", False),
    ("Sell Mult", "img:ui/status/sell_bag", None, 30, "+30%", "+31%", "2.1k", False),
]


def mastery_card(name, icon, tint, lv, cur, nxt, price, afford, maxed=False):
    pic = img(icon[4:], 46) if icon.startswith("img:") else vec(icon, "FFFFFF", 34)
    tile = {"name": "Icon", "w": 60, "h": 60, "radius": 16, "fill": {"hex": tint} if tint else "FFFFFF", **BORDER, "layout": "H", "main": "CENTER",
            "cross": "CENTER", "children": [pic]}
    eff = {"name": "Effect", "layout": "H", "gap": 4, "cross": "CENTER", "children": [
        text(cur, "Small", "cozy/text", name="From"), text("→", "Small", "cozy/subtext", name="Arrow"), text(nxt, "Small", "cozy/mint-lip", name="To")]}
    action = (lip_btn("Btn Max", [ftxt("MAX", 16, "9AA5B1", name="Label")], disabled=True, w=104) if maxed else
              two_line_btn("UPGRADE", "ui/status/pearl", price, "mint", w=104, disabled=not afford))
    return {"name": "Track " + name, "layout": "H", "gap": 12, "pad": 12, "w": 352, "h": 92, "radius": 18, "cross": "CENTER", "fill": v("cozy/sand"), "children": [
        tile, {"name": "Text", "layout": "V", "gap": 2, "fillW": True, "children": [
            text(name, "Heading", name="Name"),
            {"name": "Line", "layout": "H", "gap": 6, "cross": "CENTER", "children": [info_pill(f"Lv.{lv}", "cozy/gem-lip", "cozy/panel"), eff]}]}, action]}


def mastery_window():
    head = {"name": "Head", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        pearl_chip("1,250"), info_pill("Total Lv. 84", "cozy/gem-lip", "cozy/panel", img("ui/status/mastery_up", 18)),
        {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, text("Kept after Rebirth", "Small", "cozy/subtext", name="Note")]}
    cards = [mastery_card(*t) for t in TRACKS]
    rows = [{"name": f"Row {i // 2 + 1}", "layout": "H", "gap": 16, "children": cards[i:i + 2]} for i in range(0, len(cards), 2)]
    return m.window("Mastery", WIN_W, WX, WY, [head, {"name": "Tracks", "layout": "V", "gap": 12, "children": rows}], h=WIN_H)


def s_mastery():
    y0 = 160
    a = screen_block("C15 · Mastery", m.screen("Mastery", [mastery_window()], dim=True), 60, y0)
    states = board("Card states", "Mint = can afford | grey = not enough Pearls | MAX when a track has a cap (Offline Cap stops at 12h). Price x1.15 per level.",
                   [mastery_card(*TRACKS[0]), mastery_card(*TRACKS[4]), mastery_card("Offline Cap", "img:ui/status/offline_reward", None, 16, "12h", "12h", "-", False, maxed=True)],
                   w=420)
    states.update(x=1400, y=y0 + 40)
    data = board("Data", "Server: { Tracks = { {Id, Stat, Level, Current, Next, Price} }, Pearls } as numbers. Client formats with Format.Stat(Stat, value) like Shop / aura badges.",
                 [], w=420)
    data.update(x=1400, y=y0 + 560)
    return [a, states, data]


# ================================================================ 4 · Shop Enhance
def pic_with_level(key, plus=0):
    kids = [img(key, 56)]
    if plus:
        kids.append({"name": "Plus", "layout": "H", "pad": [1, 6, 1, 6], "radius": 999, "x": 30, "y": 38, "fill": v("cozy/sky-lip"), "stroke": "FFFFFF", "strokeW": 2,
                     "children": [ftxt(f"+{plus}", 13, "FFFFFF", name="Value")]})
    return {"name": "Picture", "w": 56, "h": 56, "children": kids}


def shop_row(key, title, sub, actions, plus=0, title_color="cozy/text", tags=()):
    return {"name": "Row " + title, "layout": "H", "pad": 12, "gap": 12, "cross": "CENTER", "radius": 16, "h": m.ROW_H, "fill": v("cozy/sand"), "fillW": True,
            "children": [pic_with_level("equipment/" + key, plus),
                         {"name": "Text", "layout": "V", "gap": 2, "fillW": True, "children": [
                             {"name": "Line", "layout": "H", "gap": 6, "cross": "CENTER", "children": [text(title, "Heading", title_color, name="Title"), *tags]},
                             text(sub, "Small", "cozy/subtext", name="Sub")]}, *actions]}


def price_btn(value, style="gold", key="ui/status/coin", disabled=False):
    c = "9AA5B1" if disabled else "FFFFFF"
    return lip_btn("Btn Buy", [img(key, 22), ftxt(value, 20, c, name="Price")], style, w=118, disabled=disabled)


def enhance_window():
    tabs = {"name": "Tabs", "layout": "H", "gap": 8, "fillW": True, "children": [
        btn("Primary" if t == "Rods" else "Ghost", t, "Btn Tab " + t, fillW=True) for t in ["Bags", "Baits", "Lines", "Rods"]]}
    owned = info_pill("OWNED", "cozy/mint-lip", "cozy/panel")
    rows = [
        shop_row("CoralRod", "Coral Rod", "+5.6% Catch Bar | +0.34 Reel | +17% Luck", [two_line_btn("ENHANCE", "ui/status/coin", "1.4k", "sky")], plus=3,
                 tags=[info_pill("EQUIPPED", "cozy/on-accent", "cozy/mint")]),
        shop_row("BambooRod", "Bamboo Rod", "+3% Catch Bar | +0.15 Reel | +5% Luck", [two_line_btn("ENHANCE", "ui/status/coin", "600", "sky")], tags=[owned]),
        shop_row("MoonsilverRod", "Moonsilver Rod", "+35% Luck | +0.50 Reel | +10% Stability", [price_btn("15k")], title_color="cozy/rarity/epic"),
        shop_row("NagaScaleRod", "Naga Scale Rod", "+75% Luck | +0.80 Reel | +2% Mutation", [lip_btn("Btn Locked", [vec("icon_lock", "9AA5B1", 18), ftxt("Lv.25", 18, "9AA5B1")], disabled=True, w=118)],
                 title_color="cozy/subtext", tags=[info_pill("900k")]),
    ]
    foot = {"name": "Footer", "layout": "H", "gap": 10, "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
        {"name": "Pager", "layout": "H", "gap": 10, "cross": "CENTER", "children": [btn("Ghost", "<", "Btn Page Prev"), ftxt("1 / 2", 18, "7A8A99", name="Page"), btn("Ghost", ">", "Btn Page Next")]},
        {"name": "Wallet", "layout": "H", "gap": 10, "children": [chip("Coins", "124.5k"), chip("Gems", "320")]}]}
    lst = {"name": "List (max 4)", "layout": "V", "gap": 10, "fillW": True, "children": rows}
    return m.window("Shop", WIN_W, WX, WY, [tabs, lst, foot], h=WIN_H)


def stat_cmp(label, a, b):
    return {"name": "Cmp " + label, "layout": "H", "gap": 8, "w": 380, "cross": "CENTER", "children": [
        text(label, "Body", "cozy/subtext", name="Label", w=130), text(a, "Body", "cozy/text", name="From"),
        text("→", "Body", "cozy/subtext", name="Arrow"), text(b, "Body", "cozy/mint-lip", name="To")]}


def enhance_popup(x=None, y=None, maxed=False):
    lv = {"name": "Levels", "layout": "H", "gap": 8, "cross": "CENTER", "children": [
        info_pill("+3", "cozy/on-accent", "cozy/sky-lip"), text("→", "Title", "cozy/subtext", name="Arrow"), info_pill("+4", "cozy/on-accent", "cozy/mint-lip")]}
    if maxed:
        lv = info_pill("+10  MAX", "cozy/on-accent", "cozy/gold")
    body = [
        {"name": "Picture", "w": 120, "h": 120, "radius": 24, "fill": "FFFFFF", **BORDER, "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [img("equipment/CoralRod", 100)]},
        text("Enhance Coral Rod", "Title", name="Title", align="CENTER", w=440), lv]
    if not maxed:
        body += [stat_cmp("Luck", "+17%", "+18%"), stat_cmp("Reel Power", "+0.34", "+0.35"), stat_cmp("Catch Bar", "+5.6%", "+5.8%"),
                 {"name": "Materials", "layout": "H", "gap": 8, "cross": "CENTER", "opacity": 0.55, "children": [
                     img("materials/enhance_stone", 28), text("x2  (phase 2: +6 and up)", "Caption", "cozy/subtext", name="Label")]}]
    else:
        body.append(text("This rod is fully enhanced.", "Body", "cozy/subtext", name="Max", align="CENTER", w=440))
    foot = [btn("Ghost", "Cancel", "Btn Cancel", fillW=True)] + ([] if maxed else [price_btn("1.4k")])
    return modal("Enhance" + (" · MAX" if maxed else ""), body, foot, w=500, x=x, y=y)


def s_enhance():
    y0 = 160
    a = screen_block("C16 · Shop with Enhance", m.screen("Shop - Enhance", [enhance_window()], dim=True), 60, y0)
    b = screen_block("C16 · Enhance popup", m.screen("Enhance", [enhance_popup(390, 66)], dim=True), 1400, y0)
    side = {"name": "Parts", "layout": "H", "gap": 30, "x": 60, "y": y0 + 800, "children": [
        enhance_popup(maxed=True),
        board("Rules", "Owned rods/lines show +N on the picture and an ENHANCE button (price = 10% of item × 1.5^level). Each level +4% to the item's stats, +1…+10. "
              "Buying an item shows the coin price on the button (k / M). Level-locked items: grey lock + Lv.N, price as a pill. "
              "Equip / unequip moved to the Character window.", [], w=520)]}
    return [a, b, side]


# ================================================================ 5 · Auras stars + gacha
def aura_row(key, name, rarity, n_stars, stats, action, chance):
    return {"name": "Row " + name, "layout": "H", "pad": 12, "gap": 12, "cross": "CENTER", "radius": 16, "h": m.ROW_H, "fill": v("cozy/sand"), "fillW": True, "children": [
        img("auras/" + key, 56),
        {"name": "Text", "layout": "V", "gap": 2, "fillW": True, "children": [
            {"name": "Line", "layout": "H", "gap": 8, "cross": "CENTER", "children": [
                text(name, "Heading", f"cozy/rarity/{rarity.lower()}", name="Title"), stars(n_stars), text(chance, "Caption", "cozy/subtext", name="Chance")]},
            text(stats, "Small", "cozy/subtext", name="Sub")]}, *action]}


def star_btn(tokens, afford=True):
    return two_line_btn("STAR UP", "ui/status/star_token", str(tokens), "gold", w=110, disabled=not afford)


def auras_window():
    top = {"name": "Top", "layout": "H", "gap": 12, "fillW": True, "cross": "CENTER", "children": [
        btn("Gem", "OPEN ALTAR", "Btn Altar", fillW=True), chip_like("Star Tokens", "ui/status/star_token", "7"), btn("Ghost", "Low FX: OFF", "Btn LowFX")]}
    rows = [
        aura_row("NeonWave", "Neon Wave", "Rare", 3, "+15% Luck x1.6 (Star 3) | equipped", [star_btn(3)], "9%"),
        aura_row("SparklingDew", "Sparkling Dew", "Common", 5, "+5% Luck x2.0 (Star 5)", [lip_btn("Btn Max", [ftxt("MAX", 16, "9AA5B1")], disabled=True, w=110)], "89.6%"),
        aura_row("SolarFlare", "Solar Flare", "Epic", 1, "+25% Luck | +3% Mutation", [star_btn(8, afford=False)], "1.2%"),
        aura_row("UnknownAura", "???", "Legendary", 0, "Not found yet", [], "0.18%"),
    ]
    lst = {"name": "List", "layout": "V", "gap": 10, "fillW": True, "children": rows}
    foot = {"name": "Footer", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
        text("Duplicate auras turn into Star Tokens. Each star = +20% stats. Cost per step: Config/AuraStars.", "Small", "cozy/subtext", name="Hint"), chip("Gems", "320")]}
    return m.window("Auras", WIN_W, WX, WY, [top, lst, foot], h=WIN_H)


def pity_rows(w=300):
    def r(label, left, done, total, grad, col):
        return {"name": "Pity " + label, "layout": "V", "gap": 4, "fillW": True, "children": [
            {"name": "Row", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                text(f"{label} in", "Small", "cozy/subtext", name="Label"), ftxt(f"{left} rolls", 16, col, name="Value")]},
            {"name": "Bar", "w": w - 24, "h": 10, "radius": 999, "fill": v("cozy/track"), "clip": True, "children": [
                {"type": "RECT", "name": "Fill", "w": round((w - 24) * done / total), "h": 10, "x": 0, "y": 0, "radius": 999, "fill": {"grad": grad}}]}]}
    return {"name": "Pity", "layout": "V", "gap": 10, "pad": 12, "w": w, "radius": 18, "fill": v("cozy/panel"), **BORDER, "children": [
        r("Legendary", 37, 63, 100, ["FFD45C", "F2A93B"], "F2A93B"), r("Mythic", 263, 37, 300, ["F2A93B", "F2668B"], "F2668B")]}


def roll_buttons(w=420):
    b1 = lip_btn("Btn Roll 1", [ftxt("ROLL x1", 20, "FFFFFF", name="Label"), cost("ui/status/gem", "5")], "gem", vertical=True)
    b10 = lip_btn("Btn Roll 10", [ftxt("ROLL x10", 20, "FFFFFF", name="Label"),
                                  {"name": "Cost Row", "layout": "H", "gap": 6, "cross": "CENTER", "children": [cost("ui/status/gem", "45"), small_pill("RARE+", "cozy/coral", "Guarantee")]}],
                  "gold", vertical=True)
    b1["fillW"] = b10["fillW"] = True
    rates = lip_btn("Btn Rates", [vec("icon_info", "7A8A99", 18), ftxt("Rates", 16, "3D4B5C", name="Label")], disabled=True)
    rates["fill"], rates["stroke"] = v("cozy/panel"), v("cozy/track")
    return {"name": "Roll Bar", "layout": "V", "gap": 8, "w": w, "children": [
        {"name": "Buttons", "layout": "H", "gap": 10, "fillW": True, "children": [b1, b10]},
        {"name": "Under", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
            text("x10 always has at least one Rare or better", "Caption", "cozy/subtext", name="Note"), rates]}]}


RATES = [("SparklingDew", "Sparkling Dew", "Common", "89.6%", 5), ("NeonWave", "Neon Wave", "Rare", "8.96%", 3), ("SolarFlare", "Solar Flare", "Epic", "1.20%", 1),
         ("AbyssalShadow", "Abyssal Shadow", "Legendary", "0.18%", 0), ("DragonEmperor", "Dragon Emperor", "Mythic", "0.018%", 0)]


def rates_popup(x=None, y=None):
    rows = []
    for key, name, r, pct, st in RATES:
        known = st > 0
        rows.append({"name": "Rate " + name, "layout": "H", "gap": 10, "pad": [6, 12, 6, 6], "radius": 14, "fill": v("cozy/sand"), "w": 460, "cross": "CENTER", "children": [
            img("auras/" + (key if known else "UnknownAura"), 40),
            {"name": "Text", "layout": "V", "gap": 0, "fillW": True, "children": [
                text(name if known else "???", "Heading", "cozy/text" if known else "cozy/subtext", name="Name"), tag(r)]},
            stars(st, 12) if known else text("—", "Small", "cozy/subtext", name="Stars"),
            ftxt(pct, 18, "3D4B5C", name="Chance", w=70, align="RIGHT")]})
    body = [text("Drop rates", "Title", name="Title", align="CENTER", w=460),
            text("Real chance per roll for this altar. Pity: Legendary every 100, Mythic at 300. x10 guarantees Rare+.", "Small", "cozy/subtext", name="Desc", align="CENTER", w=460)] + rows
    return modal("Rates", body, [btn("Primary", "OK", "Btn OK", fillW=True)], w=540, x=x, y=y)


def dup_card():
    return {"name": "Duplicate Reveal", "layout": "V", "gap": 8, "pad": 22, "w": 300, "cross": "CENTER", "radius": 24, "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
        img("auras/NeonWave", 110), text("Neon Wave", "Title", "cozy/rarity/rare", name="Name"),
        {"name": "Token", "layout": "H", "gap": 6, "pad": [6, 14, 6, 8], "radius": 999, "cross": "CENTER", "fill": {"hex": "FBEAB8"}, "stroke": v("cozy/gold"), "strokeW": 2,
         "children": [img("ui/status/star_token", 26), text("+1 Star Token", "Heading", "cozy/gold-lip", name="Label")]},
        text("Already owned → token for stars", "Caption", "cozy/subtext", name="Note")]}


def g6_summary():
    res = [("SparklingDew", "Common", "token"), ("NeonWave", "Rare", "token"), ("SparklingDew", "Common", "token"), ("TidalBloom", "Rare", "new"),
           ("SparklingDew", "Common", "token"), ("SolarFlare", "Epic", "best"), ("SparklingDew", "Common", "token"), ("SparklingDew", "Common", "token"),
           ("NeonWave", "Rare", "token"), ("SparklingDew", "Common", "token")]
    cells = []
    for key, r, st in res:
        badge = (small_pill("NEW!", "cozy/coral", "New") if st == "new" else
                 {"name": "Token", "layout": "H", "gap": 2, "pad": [1, 6, 1, 3], "radius": 999, "cross": "CENTER", "fill": {"hex": "FBEAB8"},
                  "children": [img("ui/status/star_token", 14), ftxt("+1", 12, "C98B1E")]} if st == "token" else small_pill("BEST", "cozy/gold", "Best"))
        c = {"name": "Card " + key, "layout": "V", "gap": 4, "pad": 8, "w": 120, "cross": "CENTER", "radius": 16, "fill": "FFFFFF",
             "stroke": {"hex": RAR[r]}, "strokeW": 3 if st == "best" else 2, "children": [img("auras/" + key, 64), tag(r), badge]}
        if st == "best":
            c["effects"] = [{"color": RAR[r], "a": 0.6, "blur": 16, "spread": 2}]
        cells.append(c)
    return {"name": "G6 x10 Summary", "layout": "V", "gap": 14, "pad": 24, "w": 700, "cross": "CENTER", "radius": 28, "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
        text("x10 RESULTS", "Title", name="Title"),
        {"name": "Row 1", "layout": "H", "gap": 10, "children": cells[:5]}, {"name": "Row 2", "layout": "H", "gap": 10, "children": cells[5:]},
        {"name": "Tokens", "layout": "H", "gap": 6, "cross": "CENTER", "children": [img("ui/status/star_token", 22), text("+8 Star Tokens from duplicates", "Heading", "cozy/gold-lip", name="Label")]},
        {"name": "Buttons", "layout": "H", "gap": 12, "children": [btn("Primary", "EQUIP BEST", "Btn Equip Best"), btn("Gold", "ROLL x10 AGAIN", "Btn Again")]}]}


def s_auras():
    y0 = 160
    a = screen_block("C17 · Auras with stars", m.screen("Auras", [auras_window()], dim=True), 60, y0)
    b = screen_block("C17 · Rates popup", m.screen("Rates", [rates_popup(370, 40)], dim=True), 1400, y0)
    altar = board("Altar parts (G1 / E1)", "Replace the old single pity bar with two rows; x10 shows RARE+; Rates button opens the popup. "
                  "Duplicate result = +1 Star Token instead of NEW!.",
                  [{"name": "Row", "layout": "H", "gap": 20, "children": [pity_rows(), roll_buttons()]}, dup_card()], w=820)
    altar.update(x=60, y=y0 + 800)
    g6 = screen_block("G6 · x10 Summary (tokens)", m.screen("G6", [dict(g6_summary(), x=290, y=90)], dim=True), 1400, y0 + 800)
    return [a, b, altar, g6]


# ================================================================ 6 · Store + Starter pack
def pass_card(key, name, lines, price=None, state=None):
    kids = [text(name, "Title", name="Name")] + [text(t, "Small", "cozy/subtext", name="Benefit") for t in lines]
    if state == "owned":
        act = info_pill("OWNED", "cozy/on-accent", "cozy/mint-lip")
    elif state == "soon":
        act = info_pill("COMING SOON", "cozy/subtext", "cozy/sand")
    else:
        act = robux_btn(price)
    kids.append(act)
    return {"name": "Pass " + name, "layout": "H", "gap": 14, "pad": 14, "w": 352, "h": 196, "radius": 20, "fill": v("cozy/sand"), "cross": "CENTER",
            "opacity": 0.75 if state == "soon" else 1, "children": [
                {"name": "Art", "w": 96, "h": 96, "radius": 20, "fill": "FFFFFF", **BORDER, "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [img(key, 84)]},
                {"name": "Text", "layout": "V", "gap": 6, "fillW": True, "children": kids}]}


def store_tabs(active):
    return {"name": "Tabs", "layout": "H", "gap": 8, "fillW": True, "children": [btn("Primary" if t == active else "Ghost", t, "Btn Tab " + t, fillW=True)
                                                                             for t in ["Passes", "Gems", "Boosts", "Packs"]]}


def store_window():
    cards = [pass_card("ui/icons/infinite_bag", "Infinite Bag", ["Your bag never fills up.", "Fish forever, sell when you like."], 349),
             pass_card("ui/icons/auto_pro", "Auto-Fish Pro", ["Auto wait -25%", "Auto rewards x1.25"], 249),
             pass_card("ui/icons/vip", "VIP", ["+15% Luck | gold name", "Offline Pearls up to 12h"], state="owned"),
             pass_card("ui/icons/extra_cast", "Extra Cast", ["Fish with two lines at once."], state="soon")]
    grid = {"name": "Grid", "layout": "V", "gap": 16, "children": [
        {"name": "Row 1", "layout": "H", "gap": 16, "children": cards[:2]}, {"name": "Row 2", "layout": "H", "gap": 16, "children": cards[2:]}]}
    return m.window("Store", WIN_W, WX, WY, [store_tabs("Passes"), grid], h=WIN_H)


def product(key, name, sub, price, best=None):
    kids = [img(key, 96), text(name, "Heading", name="Name", align="CENTER", w=180), text(sub, "Caption", "cozy/subtext", name="Sub", align="CENTER", w=180), robux_btn(price)]
    d = {"name": "Product " + name, "layout": "V", "gap": 6, "pad": 14, "w": 210, "cross": "CENTER", "radius": 20, "fill": v("cozy/sand"), "children": kids}
    if best:
        d["children"].insert(0, small_pill(best, "cozy/coral", "Badge"))
    return d


def store_tab_panels():
    gems = board("Gems tab", None, [{"name": "Row", "layout": "H", "gap": 12, "children": [
        product("ui/shop/gems_s", "25 Gems", "5 aura rolls", 25), product("ui/shop/gems_m", "110 Gems", "22 rolls | +11% bonus", 99, "POPULAR"),
        product("ui/shop/gems_l", "300 Gems", "60 rolls | +20% bonus", 249, "BEST VALUE")]},
        {"name": "Rates Link", "layout": "H", "gap": 8, "cross": "CENTER", "children": [vec("icon_info", "7A8A99", 18),
                                                                                      text("Gems are used for random aura rolls — tap to see drop rates", "Small", "cozy/sky-lip", name="Label")]}], w=720)
    boosts = board("Boosts tab", None, [{"name": "Row", "layout": "H", "gap": 12, "children": [
        product("ui/shop/boost_coins", "2x Coins", "2 hours | stacks time", 39), product("ui/shop/boost_pearls", "2x Pearls", "2 hours | works offline", 39)]}], w=480)
    packs = board("Packs tab", None, [{"name": "Row", "layout": "H", "gap": 12, "children": [
        product("ui/shop/starter_bundle", "Starter Pack", "one time only", 49, "x1"), product("ui/shop/coins_l", "Coin Chest", "coming later", "—")]}], w=480)
    return {"name": "Tabs", "layout": "H", "gap": 30, "children": [gems, boosts, packs]}


def starter_popup(x=None, y=None):
    items = [("ui/status/gem", "100 Gems"), ("equipment/Shrimp", "Shrimp bait x50"), ("equipment/SweetheartRod", "Sweetheart Rod (cosmetic + light stats)")]
    body = [small_pill("ONE-TIME OFFER", "cozy/coral", "Ribbon"), img("ui/shop/starter_bundle", 150), text("Starter Pack", "Display", name="Title", align="CENTER", w=460),
            {"name": "Items", "layout": "V", "gap": 6, "children": [
                {"name": "Item " + t, "layout": "H", "gap": 10, "pad": [6, 12, 6, 6], "radius": 14, "fill": v("cozy/sand"), "w": 400, "cross": "CENTER",
                 "children": [img(k, 36), text(t, "Body", name="Label")]} for k, t in items]}]
    return modal("Starter Pack", body, [btn("Ghost", "Later", "Btn Later", fillW=True), robux_btn(49, name="Btn Buy")], w=520, x=x, y=y)


def s_store():
    y0 = 160
    a = screen_block("C6 · Store (Passes tab)", m.screen("Store", [store_window()], dim=True), 60, y0)
    b = screen_block("C19 · Starter Pack offer", m.screen("Starter", [starter_popup(380, 20)], dim=True), 1400, y0)
    tabs = dict(store_tab_panels(), x=60, y=y0 + 800)
    notes = board("Rules", "Robux prices on mint buttons with the Robux mark. Final prices (user, 2026-11-17): Gems 25 / 99 / 249 R$ = 25 / 110 / 300 Gems (1 roll = 5 Gems), Starter Pack = 100 Gems + bait + rod, Boosts 39 each, Starter Pack 49, VIP 149, Auto-Fish Pro 249, Infinite Bag 349, Extra Cast ≤299 (waits on C4). Starter Pack shows once after the first purchase "
                  "or Lv.3, closes right away, no countdown. Store opens from the hub tile; a Rates link is required because Gems buy random rolls.", [], w=720)
    notes.update(x=60, y=y0 + 1260)
    return [a, b, tabs, notes]


# ================================================================ 7 · Hot fish + hub
def sell_modal():
    def line(label, value, color="3D4B5C", icon=None):
        return {"name": "Line " + label, "layout": "H", "w": 440, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
            {"name": "Left", "layout": "H", "gap": 6, "cross": "CENTER", "children": ([icon] if icon else []) + [text(label, "Body", "cozy/subtext", name="Label")]},
            ftxt(value, 20, color, name="Value")]}
    body = [img("ui/status/sell_bag", 96), text("Sell all 18 fish?", "Title", name="Title", align="CENTER", w=440),
            line("Fish value", "21,800"), line("Hot fish bonus", "+12,400", "E07A5C", hot_badge(3)),
            {"type": "RECT", "name": "Divider", "w": 440, "h": 2, "fill": v("cozy/track")},
            {"name": "Total", "layout": "H", "gap": 8, "cross": "CENTER", "children": [img("ui/status/coin", 36), ftxt("34,200", 40, "C98B1E", name="Value")]},
            text("The total counts up after Confirm.", "Caption", "cozy/subtext", name="Note")]
    return modal("Sell All · hot bonus", body, [btn("Ghost", "Cancel", "Btn Cancel", fillW=True), btn("Success", "Confirm", "Btn Confirm", fillW=True)], w=540, x=370, y=60)


def merchant_board():
    fish = [("fish/BubbleCarp", "Bubble Carp"), ("fish/PearlClam", "Pearl Clam")]
    cells = [{"name": "Hot " + n, "layout": "V", "gap": 4, "cross": "CENTER", "w": 130, "children": [
        {"name": "Pic", "w": 96, "h": 96, "children": [img(k, 96), dict(hot_badge(3), x=60, y=-4)]}, text(n, "Heading", name="Name", align="CENTER", w=130)]} for k, n in fish]
    return {"name": "Merchant HOT FISH board", "layout": "V", "gap": 10, "pad": 18, "w": 340, "cross": "CENTER", "radius": 24, "fill": v("cozy/panel"),
            "stroke": v("cozy/coral"), "strokeW": 4, "effects": SOFT, "children": [
                {"name": "Head", "layout": "H", "gap": 8, "pad": [6, 16, 6, 12], "radius": 999, "cross": "CENTER", "fill": eh.BLAZE_GRAD,
                 "children": [img("ui/status/hot_streak", 28), ftxt("HOT FISH", 24, "FFFFFF", name="Title", textStrokeW=2, textStroke="C2553A")]},
                {"name": "Fish", "layout": "H", "gap": 16, "children": cells},
                {"name": "Timer", "layout": "H", "gap": 6, "cross": "CENTER", "children": [vec("icon_timer", "7A8A99", 18), text("x3 price | 12m left", "Heading", "cozy/subtext", name="Label")]}]}


def small_hub_tile(label, tint, key=None, badge=None, dot=False, avatar=False):
    circle_kids = [img(key or "ui/icons/" + label.lower(), 50)]
    if avatar:
        circle_kids = [img("npc/Pip_happy", 74, x=-4, y=2)]
    circle = {"name": "Circle", "w": 66, "h": 66, "x": 7, "y": 6, "radius": 999, "fill": m.TILE_TINTS[tint], "stroke": "FFFFFF", "strokeW": 3, "clip": avatar,
              "effects": [{"color": "3D4B5C", "a": 0.10, "y": 3, "blur": 6}],
              **({} if avatar else {"layout": "H", "main": "CENTER", "cross": "CENTER"}), "children": circle_kids}
    holder = {"name": "Holder", "w": 80, "h": 74, "clip": False, "children": [circle]}
    if dot:
        holder["children"].append({"type": "ELLIPSE", "name": "Dot", "w": 14, "h": 14, "x": 62, "y": 4, "fill": v("cozy/danger"), "stroke": "FFFFFF", "strokeW": 3})
    if badge:
        holder["children"].append(dict(small_pill(badge, "cozy/danger", "Badge"), x=12, y=-4))
    return {"name": "Btn " + label, "layout": "V", "gap": 0, "w": 80, "cross": "CENTER", "children": [holder, text(label, "Caption", "cozy/text", name="Label", align="CENTER", w=80)]}


def hub_economy():
    hub = m.hub_panel()
    phone = hub["children"][1]["children"][0]
    tiles = [small_hub_tile("Shop", "peach", badge="SALE"), small_hub_tile("Auras", "lilac", dot=True), small_hub_tile("Fishdex", "sky"), small_hub_tile("Bag", "butter"),
             small_hub_tile("Character", "sky", avatar=True), small_hub_tile("Aquarium", "sky", dot=True), small_hub_tile("Mastery", "mint", dot=True), small_hub_tile("Store", "lilac"),
             small_hub_tile("Quests", "mint", dot=True), small_hub_tile("Rebirth", "pink", badge="Lv.50"), small_hub_tile("Events", "peach", key="ui/icons/daily_login"),
             small_hub_tile("Friends", "sky"), small_hub_tile("Settings", "sand")]
    phone["children"][1] = {"name": "Grid", "layout": "H", "wrap": True, "gap": 4, "rowGap": 8, "w": 336, "x": 14, "y": 176, "children": tiles}
    header = phone["children"][0]
    header["children"].append({"name": "VIP Badge", "layout": "H", "gap": 3, "pad": [2, 8, 2, 6], "radius": 999, "x": 30, "y": 104, "cross": "CENTER",
                               "fill": v("cozy/gold"), "stroke": "FFFFFF", "strokeW": 2,
                               "children": [img("ui/icons/vip", 16), ftxt("VIP", 13, "FFFFFF", name="Label")]})
    return hub


def daily_login_card():
    days = []
    for d in range(1, 8):
        claimed, today = d < 3, d == 3
        days.append({"name": f"Day {d}", "layout": "V", "gap": 2, "pad": 6, "w": 62, "cross": "CENTER", "radius": 14,
                     "fill": v("cozy/mint", 0.35) if claimed else ("FFFFFF" if today else v("cozy/sand")),
                     "stroke": v("cozy/gold") if today else v("cozy/track"), "strokeW": 3 if today else 2, "children": [
                         text(f"DAY {d}", "Caption", "cozy/subtext", name="Label"),
                         img("ui/status/gem" if d % 2 else "ui/status/coin", 28, opacity=0.5 if claimed else 1),
                         svgn('<path d="M10 25l9 9 19-21" stroke="#4FAF8A" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>', 16, "Tick")
                         if claimed else ftxt("+5" if d % 2 else "1k", 14, "3D4B5C", name="Value")]})
    return board("E0 · Daily Login card", "Uses ui/icons/daily_login. Today = gold border, claimed = mint + tick.",
                 [{"name": "Head", "layout": "H", "gap": 10, "cross": "CENTER", "children": [img("ui/icons/daily_login", 48), text("Daily Login | Day 3 / 7", "Title", name="Label")]},
                  {"name": "Days", "layout": "H", "gap": 6, "children": days}, btn("Success", "CLAIM", "Btn Claim")], w=560)


def s_hot():
    y0 = 160
    a = screen_block("C18 · Sell All with hot bonus", m.screen("Sell", [sell_modal()], dim=True), 60, y0)
    b = screen_block("12 · Main Menu hub (economy tiles)", m.screen("Hub", [eh.stats(boosts=()), dict(hub_economy(), x=560, y=64)]), 1400, y0)
    parts = {"name": "Parts", "layout": "H", "gap": 30, "x": 60, "y": y0 + 800, "children": [
        board("C18 · Merchant sign", "SurfaceGui next to MerchantStall. 1-2 hot fish of the hour, price multiplier, time left. Inventory stacks get the same HOT xN badge.",
              [merchant_board()], w=420),
        daily_login_card(),
        board("Hub changes", "New tiles: Character, Aquarium, Mastery, Store (13 tiles, 4 per row, smaller circles). Rebirth badge Lv.50. Events uses the daily login icon. "
              "VIP badge under the avatar when the pass is owned.", [], w=420)]}
    return [a, b, parts]


# ================================================================ build
SECTIONS = {
    "icons": ("Economy · 0 Icons (art + vectors)", "Economy UI · 0 — Icons", "All new art from ART_PROMPTS sheets 10–16 plus the global vector icons. Keys = assets/art/<folder>/<name>.png.", s_icons),
    "aquarium": ("Economy · 2 Aquarium (C14/C18)", "Economy UI · 2 — Aquarium, offline, inventory", "C14 idle fish tank -> Pearls, offline popup, bag actions; C18 hot fish badge.", s_aquarium),
    "mastery": ("Economy · 3 Mastery (C15)", "Economy UI · 3 — Mastery", "7 tracks paid with Pearls, never reset by Rebirth.", s_mastery),
    "enhance": ("Economy · 4 Enhance (C16)", "Economy UI · 4 — Shop Enhance", "Coins sink: +1…+10 on owned rods/lines, x10 economy prices.", s_enhance),
    "auras": ("Economy · 5 Auras + Gacha (C17)", "Economy UI · 5 — Aura stars + gacha", "Stars 1-5 from Star Tokens, two pity rows, x10 Rare+, real drop rates, G6 tokens.", s_auras),
    "store": ("Economy · 6 Store (C6/C19)", "Economy UI · 6 — Robux Store + Starter Pack", "Passes, Gems, Boosts, Packs. Rates link required.", s_store),
    "hot": ("Economy · 7 Hot fish + Hub (C18)", "Economy UI · 7 — Hot fish, hub, daily login", "Sell All bonus, Merchant sign, Main Menu with the new tiles.", s_hot),
}
ORDER = ["icons", "aquarium", "mastery", "enhance", "auras", "store", "hot"]
Y = {"icons": 0, "aquarium": 2000, "mastery": 4400, "enhance": 5800, "auras": 7900, "store": 10100, "hot": 12100}


def build(key):
    name, title, sub, fn = SECTIONS[key]
    return [{"pageId": PAGE_ID, "replaceName": name, "tree": section(key, name, title, sub, fn(), Y[key])}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    keys = sys.argv[2:] or ORDER
    os.makedirs(out, exist_ok=True)
    for k in keys:
        p = os.path.join(out, f"22_economy_{k}_ops.json")
        with open(p, "w", encoding="utf-8") as f:
            json.dump(build(k), f, ensure_ascii=False, indent=1)
        print("wrote", p)
