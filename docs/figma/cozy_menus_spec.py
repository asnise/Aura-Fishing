"""Every in-game menu/screen of Aura Fishing in the Cozy Lake style, one Figma Section each.

Run:  python -I docs/figma/cozy_menus_spec.py docs/figma/out
Send: node "Figma For Roblox/cursor-talk-to-figma-mcp/scripts/figma-run.mjs" --channel=<ch> build_tree docs/figma/out/5_menus.json
Layer names follow FigmaRoblox export rules: buttons start with "Btn", the fake 3D world is "World [skip]".
All borders = cozy/track (2px). Rarity shows via tags / text colour only.
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("cozy_lake_spec", os.path.join(_here, "cozy_lake_spec.py"))
base = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(base)

v, text, IDS, PAGE_ID, SOFT = base.v, base.text, base.IDS, base.PAGE_ID, base.SOFT_SHADOW
W, H = 1280, 720
BORDER = {"stroke": v("cozy/track"), "strokeW": 2}


# ---------------------------------------------------------------- primitives
def btn(style, label, name, **kw):
    d = {"type": "INSTANCE", "ref": IDS["button"], "variant": "Style=" + style, "texts": {"Label": label}, "name": name}
    d.update(kw)
    return d


def chip(kind, value, name=None, **kw):
    d = {"type": "INSTANCE", "ref": IDS["chip"], "variant": "Type=" + kind, "texts": {"Value": value}, "name": name or kind}
    d.update(kw)
    return d


def tag(rarity, **kw):
    d = {"type": "INSTANCE", "ref": IDS["tag"], "variant": "Rarity=" + rarity, "name": "Tag " + rarity}
    d.update(kw)
    return d


def progress(name="Progress", **kw):
    d = {"type": "INSTANCE", "ref": IDS["progress"], "name": name}
    d.update(kw)
    return d


def pill(label, style="Body", color="cozy/text", name="Toast", **kw):
    d = {"name": name, "layout": "H", "pad": [8, 20, 8, 20], "radius": 999, "fill": v("cozy/panel"), **BORDER,
         "children": [text(label, style, color, name="Label")]}
    d.update(kw)
    return d


def small_pill(label, fill, name):
    return {"name": name, "layout": "H", "pad": [3, 10, 3, 10], "radius": 999, "fill": v(fill),
            "children": [text(label, "Caption", "cozy/on-accent", name="Label")]}


def panel(name, w, children, **kw):
    d = {"name": name, "layout": "V", "pad": 16, "gap": 10, "w": w, "radius": 18, "fill": v("cozy/panel"), **BORDER, "children": children}
    d.update(kw)
    return d


WIN_W, WIN_H = 760, 610   # every list window (Shop tabs, Auras) is exactly this size — never content-sized
ROW_H = 80                  # every list row is exactly this tall


def window(title, w, x, y, body, h=None):
    return {"name": "Window " + title, "layout": "V", "pad": 20, "gap": 14, "w": w, **({"h": h} if h else {}), "x": x, "y": y, "radius": 24,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                {"name": "Header", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                    text(title, "Title", name="Title"), btn("Danger", "X", "Btn Close")]},
                *body]}


def row(title, sub, actions, title_color="cozy/text", fill="cozy/sand", name=None, picture=None):
    pic = [img(picture, 56)] if picture else []
    return {"name": name or ("Row " + title), "layout": "H", "pad": 12, "gap": 12, "cross": "CENTER", "radius": 16, "h": ROW_H,
            "fill": v(fill), "fillW": True, "children": pic + [
                {"name": "Text", "layout": "V", "gap": 2, "fillW": True, "children": [
                    text(title, "Heading", title_color, name="Title"), text(sub, "Small", "cozy/subtext", name="Sub")]},
                *actions]}


def center_row(name, y, children, gap=12):
    """Full-width transparent row used to centre things horizontally."""
    return {"name": name, "layout": "H", "w": W, "x": 0, "y": y, "gap": gap, "main": "CENTER", "cross": "CENTER", "children": children}


def world(dim=False):
    kids = [
        {"type": "RECT", "name": "Water", "w": W, "h": 300, "x": 0, "y": 420, "fill": v("cozy/sky", 0.35)},
        {"type": "ELLIPSE", "name": "Island", "w": 560, "h": 130, "x": 360, "y": 370, "fill": v("cozy/mint", 0.55)},
        {"type": "ELLIPSE", "name": "Island Top", "w": 360, "h": 70, "x": 460, "y": 372, "fill": v("cozy/mint-lip", 0.35)},
    ]
    if dim:
        kids.append({"type": "RECT", "name": "Dim", "w": W, "h": H, "x": 0, "y": 0, "fill": v("cozy/text", 0.28)})
    return {"name": "World [skip]", "w": W, "h": H, "x": 0, "y": 0, "fill": {"grad": ["DDF5EE", "A8DCD8"], "angle": 90}, "children": kids}


# Roblox built-in UI (CoreGui) in a 1280x720 frame. Our HUD must stay out of these zones.
TOPBAR = 58      # GuiService.TopbarInset height; code uses IgnoreGuiInset=false so in-game y=0 starts here
SAFE_TOP = 70    # first free y for our UI in Figma (= 12px below the top bar)
HUD_STATS_SET = "3491:14275"   # component set "HUD Stats"
HUD_STATS_STYLE = "E Minimal Floating"


def roblox_overlay(h=H):
    g = lambda a: {"hex": "3D4B5C", "opacity": a}
    lab = lambda t, x, y: dict(text(t, "Caption", "cozy/subtext", name="Label"), x=x, y=y)
    kids = [
        {"type": "RECT", "name": "Top Bar", "w": W, "h": TOPBAR, "x": 0, "y": 0, "fill": g(0.07)},
        {"type": "RECT", "name": "Roblox Menu Btn", "w": 44, "h": 44, "x": 12, "y": 7, "radius": 12, "fill": g(0.28)},
        {"type": "RECT", "name": "Chat Btn", "w": 44, "h": 44, "x": 64, "y": 7, "radius": 12, "fill": g(0.28)},
        lab("ROBLOX TOP BAR (58px)  —  keep clear", 124, 22),
        {"type": "RECT", "name": "Chat Window (when open)", "w": 380, "h": 210, "x": 8, "y": 64, "radius": 12, "fill": g(0.04), "stroke": g(0.25), "strokeW": 1.5},
        lab("CHAT WINDOW (desktop, when open)", 20, 248),
        {"type": "RECT", "name": "Leaderboard", "w": 236, "h": 170, "x": W - 248, "y": 64, "radius": 12, "fill": g(0.06), "stroke": g(0.25), "strokeW": 1.5},
        lab("LEADERBOARD (leaderstats)", W - 236, 210),
    ]
    if h >= H:
        kids += [
            {"type": "ELLIPSE", "name": "Mobile Thumbstick", "w": 150, "h": 150, "x": 50, "y": h - 210, "fill": g(0.07), "stroke": g(0.25), "strokeW": 1.5},
            lab("MOBILE THUMBSTICK", 62, h - 52),
            {"type": "ELLIPSE", "name": "Mobile Jump", "w": 96, "h": 96, "x": W - 160, "y": h - 170, "fill": g(0.07), "stroke": g(0.25), "strokeW": 1.5},
            lab("MOBILE JUMP", W - 158, h - 60),
        ]
    return {"name": "[skip] Roblox CoreGui (guide)", "w": W, "h": h, "x": 0, "y": 0, "children": kids}


def screen(name, children, dim=False, h=H):
    return {"name": name, "w": W, "h": h, "radius": 0, "clip": True, "children": [world(dim)] + children + [roblox_overlay(h)]}


# ---------------------------------------------------------------- shared HUD pieces
def stats_card():
    # instance of the "HUD Stats" component set: change the style there once, every screen follows
    return {"type": "INSTANCE", "ref": HUD_STATS_SET, "variant": "Style=" + HUD_STATS_STYLE, "name": "Stats", "x": 16, "y": SAFE_TOP}


def depth_button(value="AUTO"):
    """Small button next to CAST showing the current depth; opens the Cast popup."""
    return {"name": "Btn Depth", "layout": "V", "gap": 0, "pad": [6, 14, 9, 14], "cross": "CENTER", "radius": 16, "fill": v("cozy/panel"), **BORDER,
            "strokeSides": {"b": 4}, "children": [text("DEPTH", "Caption", "cozy/subtext", name="Label"), ftxt(value, 18, "3D4B5C", name="Value")]}


def cast_row(cast_style="Primary", cast_label="CAST", depth="AUTO"):
    return center_row("Cast Row", 610, [btn(cast_style, cast_label, "Btn Cast"), depth_button(depth)], gap=10)


CHECK_SVG = '<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg"><path d="M3.5 9.5l3.5 3.5 7.5-8.5" stroke="#FFFFFF" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>'


def checkbox(on):
    kids = [{"type": "SVG", "svg": CHECK_SVG, "w": 18, "h": 18, "name": "Tick"}] if on else []
    return {"name": "Checkbox", "w": 30, "h": 30, "radius": 9, "layout": "H", "main": "CENTER", "cross": "CENTER",
            "fill": v("cozy/mint") if on else v("cozy/panel"), "stroke": v("cozy/mint-lip") if on else v("cozy/track"), "strokeW": 2, "children": kids}


def cast_popup(auto=False):
    W_ = 470
    max_d, cur = 150, 80
    knob_x = round(cur / max_d * (W_ - 28))
    bands = [("Shallow", 0, 50, "D3ECFA"), ("Mid", 50, 150, "9AD4F5")]
    track = {"name": "Slider", "w": W_ - 28, "h": 18, "radius": 999, "clip": True, "fill": v("cozy/track"), "children": [
        {"type": "RECT", "name": "Band " + n, "w": round((b1 - b0) / max_d * (W_ - 28)), "h": 18, "x": round(b0 / max_d * (W_ - 28)), "y": 0, "fill": c}
        for n, b0, b1, c in bands]}
    slider = {"name": "Slider Holder", "w": W_ - 28, "h": 34, "children": [dict(track, x=0, y=8),
        {"name": "Knob", "w": 30, "h": 30, "x": max(0, knob_x - 15), "y": 2, "radius": 999, "fill": "FFFFFF", "stroke": v("cozy/sky-lip"), "strokeW": 3,
         "effects": [{"color": "3D4B5C", "a": 0.18, "y": 2, "blur": 4}]}]}
    scale = {"name": "Scale", "layout": "H", "w": W_ - 28, "main": "SPACE_BETWEEN", "children": [
        text("0m", "Caption", "cozy/subtext", name="Min"), text("Shallow  |  Mid Water", "Caption", "cozy/subtext", name="Zones"),
        text(f"{max_d}m (line)", "Caption", "cozy/subtext", name="Max")]}
    presets = {"name": "Presets", "layout": "H", "gap": 8, "w": W_ - 28, "children": [
        btn("Ghost", "Shallow 20m", "Btn Preset Shallow", fillW=True), btn("Primary", "Mid 80m", "Btn Preset Mid", fillW=True),
        btn("Ghost", f"Max {max_d}m", "Btn Preset Max", fillW=True)]}
    manual = {"name": "Manual Depth", "layout": "V", "gap": 10, "cross": "CENTER", "w": W_ - 28, "opacity": 0.35 if auto else 1, "children": [
        {"name": "Readout", "layout": "H", "gap": 10, "cross": "CENTER", "children": [
            ftxt(f"{cur}m", 44, "3D4B5C", name="Depth"),
            {"name": "Zone", "layout": "H", "pad": [3, 10, 3, 10], "radius": 999, "fill": v("cozy/sky"), "children": [text("MID WATER", "Caption", "cozy/on-accent", name="Label")]}]},
        slider, scale, presets,
        text("9 species live here  •  4 discovered", "Small", "cozy/subtext", name="Species")]}
    auto_row = {"name": "Auto Toggle", "layout": "H", "gap": 12, "pad": 12, "cross": "CENTER", "radius": 16, "w": W_ - 28,
                "fill": "E3F6EE" if auto else v("cozy/sand"), "children": [
                    checkbox(auto),
                    {"name": "Text", "layout": "V", "gap": 0, "children": [
                        text("Auto depth", "Heading", name="Title"),
                        text("Random depth your line can reach, every cast. CAST won't ask again.", "Small", "cozy/subtext", name="Sub", w=W_ - 100)]}]}
    return {"name": "Cast Popup", "layout": "V", "gap": 14, "pad": 14, "w": W_, "x": (W - W_) // 2, "y": 96 if not auto else 250, "radius": 28,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                {"name": "Header", "layout": "H", "w": W_ - 28, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                    {"name": "Title", "layout": "H", "gap": 8, "cross": "CENTER", "children": [img("ui/status/bobber", 34), text("Cast", "Title", name="Title")]},
                    btn("Danger", "X", "Btn Close")]},
                auto_row] + ([] if auto else [manual]) + [
                btn("Primary", "CAST!", "Btn Cast Confirm", fillW=True)]}


def s_cast_popup():
    return screen("Cast Popup", [stats_card(), side_menu(), actions(), cast_popup(False), cast_row(depth="80m")])


def s_cast_popup_auto():
    return screen("Cast Popup Auto", [stats_card(), side_menu(), actions(), cast_popup(True), cast_row(depth="AUTO")])


def side_menu():
    """Left column under Stats (top-right = leaderboard, bottom corners = mobile controls)."""
    def b(label):
        return {"name": "Btn " + label, "layout": "V", "gap": 2, "w": 72, "cross": "CENTER", "children": [
            {"name": "Tile", "w": 64, "h": 64, "radius": 20, "fill": v("cozy/panel"), **BORDER, "layout": "H", "main": "CENTER", "cross": "CENTER",
             "children": [img("ui/icons/" + label.lower(), 50)]},
            text(label, "Caption", "cozy/text", name="Label", align="CENTER", w=72)]}
    return {"name": "Menu", "layout": "V", "gap": 10, "x": 16, "y": 292, "children": [b("Shop"), b("Auras"), b("Fishdex")]}


def actions(auto_on=False):
    """Right side, above the mobile jump button and below the leaderboard."""
    return {"name": "Actions", "layout": "V", "gap": 10, "w": 200, "x": W - 216, "y": 330, "children": [
        chip("Bag", "18 / 50", "Bag"),
        btn("Success" if auto_on else "Ghost", "AUTO: ON" if auto_on else "AUTO: OFF", "Btn Auto", fillW=True),
        btn("Gold", "SELL ALL", "Btn Sell", fillW=True)]}


def hud_base(cast_style="Primary", cast_label="CAST", auto_on=False):
    return [stats_card(), side_menu(), actions(auto_on), cast_row(cast_style, cast_label)]


# ---------------------------------------------------------------- screens
def s_hud():
    return screen("HUD", hud_base())


def s_states():
    def col(caption, status, cast_style, cast_label):
        kids = [text(caption, "Caption", "cozy/subtext", name="Caption")]
        if status:
            kids.append(status)
        kids.append(btn(cast_style, cast_label, "Btn Cast"))
        return {"name": "State " + caption, "layout": "V", "gap": 14, "cross": "CENTER", "w": 250, "children": kids}
    return screen("HUD States", [
        center_row("States", 70, [
            col("IDLE", None, "Primary", "CAST"),
            col("WAITING", pill("Waiting...  (30m)", "Heading", "cozy/subtext", name="Status"), "Ghost", "REEL IN"),
            col("BITE", img("ui/status/bite_alert", 72), "Gold", "HOOK!"),
            col("AUTO", pill("Auto fishing...", "Heading", "cozy/mint-lip", name="Status"), "Ghost", "AUTO"),
        ], gap=40)], h=360)


def s_reel():
    # Chosen design lives in reel_options.ring_reel (Option C "Ring Reel").
    spec = importlib.util.spec_from_file_location("reel_options", os.path.join(_here, "reel_options.py"))
    ro = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ro)
    return screen("Reel Minigame", [stats_card(), ro.ring_reel(x=430, y=110), center_row("Cast Row", 616, [btn("Ghost", "REELING", "Btn Cast")])])


def s_catch():
    card = {"name": "Catch Card", "layout": "V", "gap": 8, "pad": 22, "w": 400, "x": 440, "y": 130, "radius": 24,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                {"name": "Tags", "layout": "H", "gap": 8, "cross": "CENTER", "children": [tag("Rare"), small_pill("NEW!", "cozy/coral", "New"), img("fish/mut_glowing", 30)]},
                img("fish/GlowEel", 356, 150),
                text("Glowing Glow Eel", "Display", "cozy/rarity/rare", name="Fish"),
                text("Rare  •  4.2 kg  •  Manual  •  PERFECT", "Small", "cozy/subtext", name="Meta"),
                {"type": "RECT", "name": "Divider", "h": 2, "w": 300, "fill": v("cozy/track"), "fillW": True},
                {"name": "Rewards", "layout": "H", "gap": 10, "children": [chip("Coins", "+468", "Value"), chip("Gems", "+1", "Gems")]},
                text("Glowing x1.8  •  Manual x1.5  •  Perfect +0.25", "Caption", "cozy/subtext", name="Breakdown")]}
    return screen("Catch Result", [center_row("Toasts", SAFE_TOP, [pill("LEVEL UP!  +5 gems", "Heading", "cozy/gem-lip")]), card] + hud_base("Primary", "CAST")[1:4])


def paged_list(rows, per_page):
    pages = max(1, (len(rows) + per_page - 1) // per_page)
    lst = {"name": f"List (max {per_page})", "layout": "V", "gap": 10, "fillW": True, "h": per_page * ROW_H + (per_page - 1) * 10, "children": rows[:per_page]}
    pager = {"name": "Pager", "layout": "H", "gap": 10, "cross": "CENTER", "children": [
        btn("Ghost", "<", "Btn Page Prev"), ftxt(f"1 / {pages}", 18, "7A8A99", name="Page"), btn("Ghost", ">", "Btn Page Next")]} if pages > 1 else {"name": "Spacer", "w": 1, "h": 1}
    return lst, pager


def shop_window(tab, rows):
    tabs = {"name": "Tabs", "layout": "H", "gap": 8, "fillW": True, "children": [
        btn("Primary" if t == tab else "Ghost", t, "Btn Tab " + t, fillW=True) for t in ["Bags", "Baits", "Lines", "Rods"]]}
    lst, pager = paged_list(rows, 4)
    foot = {"name": "Footer", "layout": "H", "gap": 10, "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
        pager, {"name": "Wallet", "layout": "H", "gap": 10, "children": [chip("Coins", "12,450"), chip("Gems", "320")]}]}
    return window("Shop", WIN_W, (W - WIN_W) // 2, SAFE_TOP, [tabs, lst, foot], h=WIN_H)


def s_shop_rods():
    rows = [
        row("Driftwood Rod", "Starter rod", [btn("Success", "Equipped", "Btn Action")], picture="equipment/DriftwoodRod"),
        row("Bamboo Rod", "+3% Catch Bar, +0.15 Reel Power, +5% Luck", [btn("Secondary", "Equip", "Btn Action")], picture="equipment/BambooRod"),
        row("Coral Rod", "+5% Catch Bar, +0.30 Reel Power, +15% Resilience, +15% Luck  |  2,500 Coins", [btn("Gold", "Buy", "Btn Action")], picture="equipment/CoralRod"),
        row("Moonsilver Rod", "+35% Luck, +0.50 Reel Power, +10% Fish Stability  |  15,000 Coins", [btn("Ghost", "Lv. 10", "Btn Action")], "cozy/subtext", picture="equipment/MoonsilverRod"),
        row("Naga Scale Rod", "+75% Luck, +0.80 Reel Power, +2% Mutation  |  90,000 Coins", [btn("Ghost", "Lv. 25", "Btn Action")], "cozy/subtext", picture="equipment/NagaScaleRod"),
    ]
    return screen("Shop - Rods", [shop_window("Rods", rows)], dim=True)


def s_shop_baits():
    rows = [
        row("Worm  x14  (equipped)", "+10% Luck  |  10 for 20 Coins", [btn("Gold", "Buy x10", "Btn Buy")], "cozy/mint-lip", picture="equipment/Worm"),
        row("Shrimp  x0", "+30% Luck, +10% Bite Speed  |  10 for 150 Coins", [btn("Gold", "Buy x10", "Btn Buy")], picture="equipment/Shrimp"),
        row("Glow Grub  x3", "+75% Luck, +1% Mutation  |  10 for 900 Coins", [btn("Secondary", "Use", "Btn Use"), btn("Gold", "Buy x10", "Btn Buy")], picture="equipment/GlowGrub"),
    ]
    return screen("Shop - Baits", [shop_window("Baits", rows)], dim=True)


def s_auras():
    top = {"name": "Top", "layout": "H", "gap": 12, "fillW": True, "children": [
        btn("Gem", "ROLL AURA  (5 Gems)", "Btn Roll", fillW=True), btn("Ghost", "Low FX: OFF", "Btn LowFX")]}
    current = {"name": "Equipped", "layout": "H", "gap": 14, "pad": 14, "cross": "CENTER", "radius": 18, "fill": v("cozy/sand"), "fillW": True, "children": [
        img("auras/NeonWave", 56),
        {"name": "Text", "layout": "V", "gap": 2, "fillW": True, "children": [
            {"name": "Line", "layout": "H", "gap": 8, "cross": "CENTER", "children": [text("Neon Wave", "Title", "cozy/rarity/rare", name="Name"), tag("Rare")]},
            text("Equipped  •  +15% Luck, +2% Catch Bar, +3% Glowing", "Small", "cozy/subtext", name="Stats")]}]}
    rows = [
        row("Sparkling Dew  (1/10)  x3", "+5% Luck", [btn("Secondary", "Equip", "Btn Equip")], "cozy/rarity/common", picture="auras/SparklingDew"),
        row("Neon Wave  (1/100)  x1", "+15% Luck, +2% Catch Bar, +3% Glowing", [btn("Success", "Unequip", "Btn Equip")], "cozy/rarity/rare", picture="auras/NeonWave"),
        row("???  (1/750)", "Epic", [], "cozy/subtext", picture="auras/UnknownAura"),
        row("???  (1/5,000)", "Legendary", [], "cozy/subtext", picture="auras/UnknownAura"),
        row("???  (1/50,000)", "Mythic", [], "cozy/subtext", picture="auras/UnknownAura"),
    ]
    return screen("Auras", [auras_window(top, current, rows)], dim=True)


def auras_window(top, current, rows):
    lst, pager = paged_list(rows, 3)
    foot = {"name": "Footer", "layout": "H", "gap": 10, "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
        pager, {"name": "Wallet", "layout": "H", "gap": 10, "children": [chip("Gems", "320")]}]}
    return window("Auras", WIN_W, (W - WIN_W) // 2, SAFE_TOP, [top, current, lst, foot], h=WIN_H)


def s_roll():
    modal = {"name": "Roll Result", "layout": "V", "gap": 12, "pad": 28, "w": 420, "x": 430, "y": 120, "cross": "CENTER", "radius": 28,
             "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [
                 text("YOU ROLLED", "Caption", "cozy/subtext", name="Caption"),
                 img("auras/NeonWave", 150),
                 text("Neon Wave", "Display", "cozy/rarity/rare", name="Name", align="CENTER", w=360),
                 {"name": "Tags", "layout": "H", "gap": 8, "cross": "CENTER", "children": [tag("Rare"), text("1 in 100", "Number", "cozy/subtext", name="Chance")]},
                 text("+15% Luck  •  +2% Catch Bar  •  +3% Glowing", "Small", "cozy/subtext", name="Stats", align="CENTER", w=360),
                 {"name": "Buttons", "layout": "H", "gap": 12, "children": [btn("Primary", "EQUIP", "Btn Equip"), btn("Ghost", "KEEP", "Btn Keep")]}]}
    return screen("Aura Roll Result", [modal], dim=True)


FISH = [("Pebble Minnow", "Common", "0-40m", 23, "0.38", "PebbleMinnow"), ("Bubble Carp", "Common", "0-50m", 41, "2.71", "BubbleCarp"),
        ("Reed Perch", "Common", "5-60m", 12, "1.20", "ReedPerch"), ("Sunscale Sardine", "Common", "0-30m", 30, "0.29", "SunscaleSardine"),
        ("Pearl Clam", "Uncommon", "10-50m", 6, "0.66", "PearlClam"), ("Lily Trout", "Uncommon", "0-45m", 4, "3.10", "LilyTrout"),
        ("Dewdrop Koi", "Rare", "0-35m", 1, "4.80", "DewdropKoi"), (None, "Epic", "0-50m", 0, None, "MysteryFish"),
        (None, "Common", "40-140m", 0, None, "MysteryFish"), (None, "Legendary", "50-150m", 0, None, "MysteryFish")]


def s_fishdex():
    def card(f):
        name, rarity, depth, count, best, key = f
        known = name is not None
        return {"name": "Card " + (name or "Unknown"), "layout": "V", "gap": 2, "pad": 10, "w": 160, "radius": 16,
                "fill": v("cozy/panel" if known else "cozy/sand"), **BORDER, "children": [
                    img("fish/" + key, 140, 62, opacity=1 if known else 0.45),
                    tag(rarity), text(name or "???", "Heading", "cozy/text" if known else "cozy/subtext", name="Name"),
                    text(depth, "Caption", "cozy/subtext", name="Depth"),
                    text(f"x{count}  •  best {best} kg" if known else "Not caught yet", "Small", "cozy/subtext", name="Stats")]}
    summary = {"name": "Summary", "layout": "H", "gap": 14, "cross": "CENTER", "fillW": True, "children": [
        text("Discovered 7 / 20", "Heading", name="Count"), progress("Progress", fillW=True)]}
    grid = {"name": "Grid", "layout": "H", "wrap": True, "gap": 12, "rowGap": 12, "fillW": True, "children": [card(f) for f in FISH]}
    return screen("Fishdex", [window("Fishdex", 920, 104, SAFE_TOP, [summary, grid])], dim=True)


def s_toasts():
    return screen("Notifications", [{"name": "Toast Stack", "layout": "V", "gap": 10, "w": W, "x": 0, "y": SAFE_TOP, "cross": "CENTER", "children": [
        pill("Sold 18 fish for 2,340 coins!", "Body", "cozy/gold-lip", name="Toast Sold"),
        pill("You rolled Neon Wave (1/100)!", "Body", "cozy/rarity/rare", name="Toast Roll"),
        pill("LEVEL UP!  +5 gems", "Body", "cozy/gem-lip", name="Toast Level"),
        pill("Your bag is full! Sell your fish at the Merchant.", "Body", "cozy/danger-lip", name="Toast Bag Full"),
        pill("The line snapped!", "Body", "cozy/danger-lip", name="Toast Snap"),
        pill("Face the water to cast!", "Body", "cozy/text", name="Toast Face Water"),
        pill("It got away... click faster when you see '!'", "Body", "cozy/subtext", name="Toast Escaped"),
        pill("Nothing lives at 400m here. Try another depth.", "Body", "cozy/subtext", name="Toast Empty Depth")]}])


# ---------------------------------------------------------------- icons (simple original SVGs)
def svg(body, size=48, vb=48):
    return f'<svg width="{size}" height="{size}" viewBox="0 0 {vb} {vb}" fill="none" xmlns="http://www.w3.org/2000/svg">{body}</svg>'


def icon(kind, color="FFFFFF", size=40, name=None):
    c = "#" + color
    bodies = {
        "fish": f'<path d="M5 24c6-9 16-13 27-8l9-7v30l-9-7C21 37 11 33 5 24z" fill="{c}"/><circle cx="15" cy="22" r="2.6" fill="#3D4B5C"/>',
        "bag": f'<path d="M16 16v-3a8 8 0 0 1 16 0v3" stroke="{c}" stroke-width="4" stroke-linecap="round"/><rect x="8" y="16" width="32" height="26" rx="8" fill="{c}"/>',
        "shop": f'<path d="M7 18 11 8h26l4 10z" fill="{c}"/><rect x="10" y="20" width="28" height="20" rx="4" fill="{c}"/><rect x="20" y="28" width="8" height="12" rx="2" fill="#FFF8EC"/>',
        "star": f'<path d="M24 5l5.6 12 13 1.4-9.8 8.8 2.8 12.8L24 33.5 12.4 40l2.8-12.8-9.8-8.8 13-1.4z" fill="{c}"/>',
        "book": f'<rect x="9" y="7" width="30" height="34" rx="5" fill="{c}"/><rect x="15" y="14" width="18" height="4" rx="2" fill="#FFF8EC"/><rect x="15" y="22" width="12" height="4" rx="2" fill="#FFF8EC"/>',
        "gear": f'<circle cx="24" cy="24" r="14" fill="{c}"/><circle cx="24" cy="24" r="6" fill="#FFF8EC"/><rect x="21" y="4" width="6" height="8" rx="2" fill="{c}"/><rect x="21" y="36" width="6" height="8" rx="2" fill="{c}"/><rect x="4" y="21" width="8" height="6" rx="2" fill="{c}"/><rect x="36" y="21" width="8" height="6" rx="2" fill="{c}"/>',
        "chat": f'<path d="M8 12a6 6 0 0 1 6-6h20a6 6 0 0 1 6 6v14a6 6 0 0 1-6 6H20l-8 7v-7h0a6 6 0 0 1-4-6z" fill="{c}"/><rect x="15" y="14" width="18" height="3.5" rx="1.7" fill="#FFF8EC"/><rect x="15" y="21" width="12" height="3.5" rx="1.7" fill="#FFF8EC"/>',
        "trophy": f'<path d="M14 8h20v10a10 10 0 0 1-20 0z" fill="{c}"/><rect x="21" y="27" width="6" height="8" fill="{c}"/><rect x="14" y="35" width="20" height="6" rx="3" fill="{c}"/>',
        "loop": f'<path d="M36 18a13 13 0 1 0 2 11" stroke="{c}" stroke-width="5" stroke-linecap="round"/><path d="M38 8v11H27z" fill="{c}"/>',
        "hook": f'<path d="M26 6v24a8 8 0 1 1-16 0" stroke="{c}" stroke-width="5" stroke-linecap="round"/><path d="M10 30l-4-6h8z" fill="{c}"/>',
        "gift": f'<rect x="8" y="18" width="32" height="22" rx="4" fill="{c}"/><rect x="6" y="12" width="36" height="9" rx="3" fill="{c}"/><rect x="21" y="12" width="6" height="28" fill="#FFF8EC"/>',
        "people": f'<circle cx="17" cy="16" r="7" fill="{c}"/><circle cx="33" cy="18" r="6" fill="{c}"/><path d="M5 38a12 12 0 0 1 24 0z" fill="{c}"/><path d="M25 38a10 10 0 0 1 18 0z" fill="{c}"/>',
        "x": f'<path d="M15 15l18 18M33 15 15 33" stroke="{c}" stroke-width="6" stroke-linecap="round"/>',
    }
    return {"type": "SVG", "svg": svg(bodies[kind]), "w": size, "h": size, "name": name or ("Icon " + kind)}


def img(path, w, h=None, **kw):
    """Image slot. tools/art/figma_images.py fills every node named 'Img <path>' with assets/art/<path>.png."""
    d = {"type": "RECT", "name": "Img " + path, "w": w, "h": h or w}
    d.update(kw)
    return d


RARITY_HEX = {"Common": "9AA5B1", "Uncommon": "5CC98A", "Rare": "5AA9F0", "Epic": "B07CF0", "Legendary": "F2A93B", "Mythic": "F2668B", "Bait": "F2B544"}


def ftxt(t, size, color, name="Value", **kw):
    d = {"type": "TEXT", "text": t, "font": {"family": "Fredoka One", "style": "Regular"}, "size": size, "color": color, "name": name}
    d.update(kw)
    return d


def corner_svg(col, size):
    return {"type": "SVG", "name": "Rarity Corner", "w": size, "h": size, "x": 0, "y": 0,
            "svg": f'<svg width="{size}" height="{size}" viewBox="0 0 34 34" xmlns="http://www.w3.org/2000/svg"><path d="M0 0H34L0 34Z" fill="#{col}"/></svg>'}



FA_LOCK_PATH = "M400 224h-24v-72C376 68.2 307.8 0 224 0S72 68.2 72 152v72H48c-26.5 0-48 21.5-48 48v192c0 26.5 21.5 48 48 48h352c26.5 0 48-21.5 48-48V272c0-26.5-21.5-48-48-48zm-104 0H152v-72c0-39.7 32.3-72 72-72s72 32.3 72 72v72z"  # react-icons/fa FaLock (Font Awesome 5 Free Solid, CC BY 4.0)


def fa_lock(h, color="3D4B5C", x=0, y=0, opacity=0.85):
    w = round(h * 448 / 512)
    return {"type": "SVG", "name": "Icon FaLock", "w": w, "h": h, "x": x, "y": y, "opacity": opacity,
            "svg": f'<svg width="{w}" height="{h}" viewBox="0 0 448 512" xmlns="http://www.w3.org/2000/svg"><path d="{FA_LOCK_PATH}" fill="#{color}"/></svg>'}


def item_slot(path, rarity="Common", count=1, size=88, state=None, mut=None, name="Item Slot", component=False):
    """Inventory slot — Option F 'Corner Ribbon' (chosen 2026-11-16). Always square (1:1).
    state: None | "selected" | "new" | "empty" | "locked"."""
    k = size / 88
    col = RARITY_HEX.get(rarity, "9AA5B1")
    has = path is not None and state != "empty"
    inner = []
    if has:
        pic = round(68 * k)
        inner += [img(path, pic, x=round((size - pic) / 2), y=round(6 * k)), corner_svg(col, round(30 * k)),
                  {"name": "Count Row", "layout": "H", "w": size, "x": 0, "y": size - round(24 * k), "main": "MAX", "pad": [0, round(8 * k), 0, 0],
                   "children": [ftxt(f"x{count}", round(15 * k), "3D4B5C")]}]
    effects = [{"color": "3D4B5C", "a": 0.08, "y": 4, "blur": 10}] if has else []
    if state == "selected":
        effects = effects + [{"color": "FF9E80", "a": 1, "spread": 3, "blur": 0}]
    slot = {"name": "Slot", "w": size, "h": size, "x": 0, "y": 0, "radius": round(20 * k), "clip": True, "fill": "FFFFFF" if has else "F3E9D8",
            **BORDER, "effects": effects, "children": inner}
    if state == "locked":
        slot["opacity"] = 0.7
    kids = [slot]
    if state == "selected":
        kids.append({"name": "Check", "w": 24, "h": 24, "x": size - 18, "y": -6, "radius": 999, "fill": v("cozy/coral"), "stroke": "FFFFFF", "strokeW": 2,
                     "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [
                         {"type": "SVG", "w": 14, "h": 14, "name": "Tick",
                          "svg": '<svg width="14" height="14" viewBox="0 0 14 14" xmlns="http://www.w3.org/2000/svg"><path d="M2.5 7.5l3 3 6-7" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>'}]})
    if state == "new":
        kids.append(dict(small_pill("NEW", "cozy/coral", "New Badge"), x=-6, y=-8))
    if state == "locked":
        lh = round(34 * k)
        kids.append(fa_lock(lh, x=round((size - lh * 448 / 512) / 2), y=round((size - lh) / 2)))
    if state == "empty":
        kids.append(ftxt("+", round(30 * k), "C9BBA3", name="Plus", x=round(36 * k), y=round(24 * k)))
    if mut and has:
        kids.append(img(mut, round(26 * k), x=round(6 * k), y=size - round(26 * k) - round(6 * k)))  # bottom-left: top-right = Selected tick
    return {"type": "COMPONENT" if component else "FRAME", "name": name, "w": size, "h": size, "clip": False, "children": kids}


def round_close(x, y):
    return {"name": "Btn Close", "w": 64, "h": 64, "x": x, "y": y, "radius": 999, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
            "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [icon("x", "7A8A99", 30)]}


# ---------------------------------------------------------------- new screens from references
def s_dialogue():
    box = {"name": "Dialogue Box", "w": 900, "h": 190, "x": 190, "y": 500, "radius": 40, "fill": v("cozy/panel", 0.96), **BORDER, "effects": SOFT,
           "layout": "V", "pad": [52, 60, 30, 60], "children": [
               text("Back again? The lake has been generous today... want me to take that catch off your hands?", "Title", "cozy/subtext", name="Line", w=760)]}
    name_tag = {"name": "Speaker", "layout": "H", "pad": [6, 22, 8, 22], "radius": 999, "x": 250, "y": 478, "fill": v("cozy/mint"),
                "children": [text("Old Marlin", "Title", "cozy/on-accent", name="Name")]}
    choice = lambda label, ic, y, name: {"name": name, "layout": "H", "gap": 18, "pad": [12, 40, 14, 22], "w": 340, "x": 900, "y": y, "cross": "CENTER",
                                         "radius": 999, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
                                         "children": [icon(ic, "3D4B5C", 34), text(label, "Title", name="Label")]}
    return screen("Dialogue", [box, name_tag, choice("Sell All Fish", "fish", 290, "Btn Choice Sell"), choice("Just chatting", "chat", 370, "Btn Choice Chat"),
                               round_close(1050, 466)])


TILE_TINTS = {"sky": "D3ECFA", "pink": "FBD8E2", "sand": "F3E3C8", "mint": "D2F0E2", "lilac": "E5DBFA", "peach": "FFDCCF", "butter": "FBEAB8"}


def hub_tile(label, tint, badge=None, dot=False):
    circle = {"name": "Circle", "w": 86, "h": 86, "x": 11, "y": 6, "radius": 999, "fill": TILE_TINTS[tint], "layout": "H", "main": "CENTER",
              "cross": "CENTER", "stroke": "FFFFFF", "strokeW": 4, "effects": [{"color": "3D4B5C", "a": 0.10, "y": 3, "blur": 6}],
              "children": [img("ui/icons/" + label.lower(), 64)]}
    holder = {"name": "Holder", "w": 108, "h": 96, "children": [circle]}
    if dot:
        holder["children"].append({"type": "ELLIPSE", "name": "Dot", "w": 16, "h": 16, "x": 84, "y": 6, "fill": v("cozy/danger"), "stroke": "FFFFFF", "strokeW": 3})
    if badge:
        holder["children"].append(dict(small_pill(badge, "cozy/danger", "Badge"), x=24, y=0))
    return {"name": "Btn " + label, "layout": "V", "gap": 2, "w": 108, "cross": "CENTER",
            "children": [holder, text(label, "Small", "cozy/text", name="Label", align="CENTER", w=108)]}


SUN_SVG = ('<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">'
           + "".join(f'<rect x="29" y="2" width="6" height="12" rx="3" fill="#FFD45C" transform="rotate({a} 32 32)"/>' for a in range(0, 360, 45))
           + '<circle cx="32" cy="32" r="15" fill="#FFC93D"/><circle cx="27" cy="27" r="5" fill="#FFE59A"/></svg>')
MOON = '<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg"><path d="M12 2a7 7 0 1 0 4 12A6 6 0 0 1 12 2z" fill="#FFFFFF"/></svg>'
DAWN = ('<svg width="20" height="18" viewBox="0 0 20 18" xmlns="http://www.w3.org/2000/svg"><path d="M4 14a6 6 0 0 1 12 0z" fill="#FFFFFF"/>'
        '<rect x="1" y="14" width="18" height="2.4" rx="1.2" fill="#FFFFFF"/><rect x="9" y="1" width="2.4" height="4" rx="1.2" fill="#FFFFFF"/>'
        '<rect x="2" y="6" width="2.4" height="4" rx="1.2" fill="#FFFFFF" transform="rotate(-45 3 8)"/><rect x="16" y="6" width="2.4" height="4" rx="1.2" fill="#FFFFFF" transform="rotate(45 17 8)"/></svg>')
DAY = '<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg"><circle cx="9" cy="9" r="5" fill="#6BB3DE"/><circle cx="9" cy="9" r="8" stroke="#6BB3DE" stroke-width="1.6" fill="none"/></svg>'
WAVE = ('<svg width="364" height="26" viewBox="0 0 364 26" xmlns="http://www.w3.org/2000/svg"><path d="M0 12 '
        + " ".join(f"Q{x + 13} {0 if i % 2 == 0 else 22} {x + 26} 12" for i, x in enumerate(range(0, 364, 26)))
        + ' V26 H0 Z" fill="#FFF8EC"/></svg>')
X_SVG = '<svg width="30" height="30" viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg"><path d="M8 8l14 14M22 8 8 22" stroke="#7A8A99" stroke-width="5" stroke-linecap="round"/></svg>'


def hub_panel(x=560, y=64):
    def svgnode(code, w, h, name, **kw):
        d = {"type": "SVG", "svg": code, "w": w, "h": h, "name": name}
        d.update(kw)
        return d

    phases = {"name": "Day Phase", "layout": "H", "gap": 8, "cross": "CENTER", "x": 138, "y": 96, "children": [
        svgnode(MOON, 16, 16, "Phase Night"), svgnode(DAWN, 18, 16, "Phase Dawn"),
        {"name": "Phase Day (now)", "layout": "H", "pad": [3, 10, 3, 10], "radius": 999, "fill": "FFFFFF", "children": [svgnode(DAY, 16, 16, "Icon")]},
        svgnode(MOON, 16, 16, "Phase Dusk", opacity=0.75)]}
    bubbles = [{"type": "ELLIPSE", "name": "Bubble", "w": d, "h": d, "x": bx, "y": by, "fill": {"hex": "FFFFFF", "opacity": 0.35}}
               for d, bx, by in [(10, 118, 18), (6, 250, 14), (14, 330, 110), (8, 22, 124), (5, 300, 84)]]
    avatar = {"name": "Avatar", "w": 84, "h": 84, "x": 22, "y": 28, "radius": 999, "fill": "FFF8EC", "clip": True, "stroke": "FFFFFF", "strokeW": 4,
              "children": [img("npc/Pip_happy", 100, x=-8, y=-2)]}
    avatar_dot = {"type": "ELLIPSE", "name": "Avatar Dot", "w": 16, "h": 16, "x": 90, "y": 30, "fill": v("cozy/danger"), "stroke": "FFFFFF", "strokeW": 3}
    clock = {"type": "TEXT", "name": "Clock", "text": "16:07", "font": {"family": "Fredoka One", "style": "Regular"}, "size": 58,
             "color": "FFFFFF", "x": 130, "y": 22}
    header = {"name": "Header", "w": 364, "h": 160, "x": 0, "y": 0, "fill": {"grad": ["A9DCF7", "7FC3EE"], "angle": 90},
              "children": bubbles + [avatar, avatar_dot, clock, phases, svgnode(SUN_SVG, 66, 66, "Weather Sun", x=278, y=26),
                                     svgnode(WAVE, 364, 26, "Wave", x=0, y=140)]}
    grid = {"name": "Grid", "layout": "H", "wrap": True, "gap": 4, "rowGap": 14, "w": 336, "x": 14, "y": 178, "main": "CENTER", "children": [
        hub_tile("Shop", "peach", badge="SALE"), hub_tile("Auras", "lilac", dot=True), hub_tile("Fishdex", "sky"),
        hub_tile("Bag", "butter"), hub_tile("Quests", "mint", dot=True), hub_tile("Rebirth", "pink", badge="Lv.100"),
        hub_tile("Events", "peach"), hub_tile("Friends", "sky"), hub_tile("Settings", "sand")]}
    phone = {"name": "Phone", "w": 364, "h": 584, "x": 14, "y": 14, "radius": 36, "clip": True, "fill": v("cozy/panel"), "children": [header, grid]}
    glass = {"name": "Glass Frame", "w": 392, "h": 612, "x": 0, "y": 0, "radius": 48, "fill": {"hex": "FFFFFF", "opacity": 0.55},
             "stroke": "FFFFFF", "strokeW": 1.5, "effects": [{"color": "3D4B5C", "a": 0.16, "y": 10, "blur": 30}], "children": [phone]}
    close_tab = {"name": "Btn Close", "w": 66, "h": 74, "x": 362, "y": 104, "radius": 20, "fill": {"hex": "FFFFFF", "opacity": 0.6},
                 "stroke": "FFFFFF", "strokeW": 1.5, "layout": "H", "pad": [0, 0, 0, 22], "main": "CENTER", "cross": "CENTER",
                 "children": [svgnode(X_SVG, 26, 26, "Icon")]}
    return {"name": "Main Menu", "w": 440, "h": 614, "x": x, "y": y, "children": [close_tab, glass]}


def s_hub():
    return screen("Main Menu", hud_base()[:1] + [hub_panel()])


INV = [("fish/PebbleMinnow", "Common", 23, None, "selected"), ("fish/BubbleCarp", "Common", 41, None, None), ("fish/PearlClam", "Uncommon", 6, None, None),
       ("fish/DewdropKoi", "Rare", 2, None, None), ("fish/CrystalGuppy", "Epic", 1, None, "new"), ("fish/ReedPerch", "Common", 12, None, None),
       ("fish/LilyTrout", "Uncommon", 4, None, None), ("fish/CoralSeahorse", "Legendary", 1, None, None), ("fish/MoonJelly", "Rare", 1, "fish/mut_glowing", None),
       ("fish/NagaHatchling", "Mythic", 1, None, None), ("equipment/Worm", "Bait", 14, None, None), ("equipment/GlowGrub", "Bait", 3, None, None),
       ("ui/status/treasure_chest", "Epic", 2, None, None), (None, "Common", 0, None, "empty"), (None, "Common", 0, None, "empty")]


def inventory_drawer():
    title = {"name": "Title Row", "layout": "H", "gap": 10, "fillW": True, "cross": "CENTER", "children": [
        img("ui/icons/bag", 40), text("Inventory", "Title", name="Title"),
        {"name": "Capacity", "layout": "H", "gap": 4, "pad": [4, 12, 4, 12], "radius": 999, "cross": "CENTER", "fill": v("cozy/sand"), "children": [
            ftxt("18", 18, "3D4B5C", name="Used"), ftxt("/ 50", 18, "9AA5B1", name="Max")]},
        {"name": "Spacer", "w": 1, "h": 1, "fillW": True}, btn("Danger", "X", "Btn Close")]}
    head = {"name": "Currencies", "layout": "H", "gap": 8, "fillW": True, "cross": "CENTER", "children": [chip("Coins", "387,790"), chip("Gems", "381")]}
    tabs = {"name": "Tabs", "layout": "H", "gap": 8, "fillW": True, "children": [
        btn("Primary" if t == "All" else "Ghost", t, "Btn Tab " + t, fillW=True) for t in ["All", "Fish", "Bait", "Treasure"]]}
    grid = {"name": "Grid", "layout": "H", "wrap": True, "gap": 10, "rowGap": 12, "w": 460, "pad": [8, 0, 4, 0], "children": [
        item_slot(p, r, n, size=84, state=st, mut=mu, name="Item " + (p.split("/")[-1] if p else "Empty")) for p, r, n, mu, st in INV]}
    foot = {"name": "Footer", "layout": "H", "gap": 10, "fillW": True, "children": [
        btn("Ghost", "Sort: Value", "Btn Sort", fillW=True), btn("Gold", "SELL ALL", "Btn Sell", fillW=True)]}
    return {"name": "Inventory", "layout": "V", "gap": 14, "pad": 20, "w": 500, "x": 516, "y": SAFE_TOP - 6, "radius": 32,
            "fill": v("cozy/panel"), **BORDER, "effects": SOFT, "children": [title, head, tabs, grid, foot]}


def s_inventory():
    return screen("Inventory", [stats_card(), inventory_drawer()])


def s_modal():
    modal = {"name": "Modal", "layout": "V", "w": 600, "x": 340, "y": 170, "radius": 36, "clip": True, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
             "children": [
                 {"name": "Body", "layout": "V", "gap": 10, "pad": [44, 48, 36, 48], "fillW": True, "cross": "CENTER", "children": [
                     img("ui/status/sell_bag", 96),
                     text("Sell all 18 fish?", "Title", name="Title", align="CENTER", w=500),
                     text("You'll get 2,340 coins. Fish with mutations are included.", "Body", "cozy/subtext", name="Message", align="CENTER", w=500)]},
                 {"name": "Footer", "layout": "H", "gap": 20, "pad": [18, 40, 22, 40], "fillW": True, "main": "CENTER", "fill": v("cozy/sand"), "children": [
                     btn("Ghost", "Cancel", "Btn Cancel", fillW=True), btn("Success", "Confirm", "Btn Confirm", fillW=True)]}]}
    return screen("Modal", [modal], dim=True)


def s_safe():
    zones = [("OUR STATS", 16, SAFE_TOP, 290, 150, "cozy/mint"), ("OUR MENU", 16, 292, 80, 240, "cozy/mint"),
             ("TOASTS", 440, SAFE_TOP, 400, 40, "cozy/sky"), ("ACTIONS", W - 216, 330, 200, 160, "cozy/mint"),
             ("CAST + DEPTH BTN", 450, 600, 380, 100, "cozy/coral"), ("MINIGAME / POPUPS", 430, 120, 420, 380, "cozy/gem")]
    kids = []
    for label, x, y, w, h, col in zones:
        kids.append({"name": "Zone " + label, "w": w, "h": h, "x": x, "y": y, "radius": 14, "fill": v(col, 0.35), "stroke": v("cozy/track"), "strokeW": 2,
                     "layout": "H", "main": "CENTER", "cross": "CENTER", "children": [text(label, "Caption", "cozy/text", name="Label")]})
    return screen("Safe Areas", kids)


SCREENS = [
    (s_safe, "00 · Roblox Safe Areas", "Grey = Roblox CoreGui (top bar 58px, chat window, leaderboard, mobile thumbstick + jump). Coloured = where our HUD lives. "
     "Every screen has a toggleable '[skip] Roblox CoreGui (guide)' layer on top; it is never exported. "
     "CoreGui draws ABOVE our UI, so close buttons must never sit under the leaderboard."),
    (s_hud, "01 · HUD", "Main fishing screen. Top-left stats, right menu, bottom-left depth selector, bottom-right bag/auto/sell, CAST centred. Code: HUDController."),
    (s_states, "02 · HUD States", "CAST button + status pill for each fishing phase (Idle / Waiting / Bite / Auto). Code: FishingController FishingState."),
    (s_reel, "03 · Reel Minigame", "Hold to lift the mint catch bar over the fish; gold bar fills while inside. Code: FishingController.runMinigame."),
    (s_catch, "04 · Catch Result", "Popup after a successful catch, plus level-up toast. Code: HUDController.ShowCatch."),
    (s_shop_rods, "05 · Shop — Rods", "Permanent items: Equipped / Equip / Buy / level-locked. Same layout for Bags and Lines tabs. Code: MenuController.buildShop."),
    (s_shop_baits, "06 · Shop — Baits", "Consumables: stack count, Use + Buy x10. Code: MenuController.buildShop."),
    (s_auras, "07 · Auras", "Roll button, Low FX toggle, equipped aura, owned/unknown list. Code: MenuController.buildAuras."),
    (s_roll, "08 · Aura Roll Result", "NEW screen (not in code yet): reveal after rolling instead of only a toast."),
    (s_fishdex, "09 · Fishdex", "Collection grid sorted by depth; unknown fish show ??? on sand cards. Code: MenuController.buildFishdex."),
    (s_toasts, "10 · Notifications", "All toast messages the server/client send, as cream pills. Code: HUDController.Notify."),
    (s_dialogue, "11 · Dialogue", "NEW: NPC talk box at the bottom with a mint name tag, close button on the box corner (clear of the mobile jump button) and speech-bubble choices. No portrait (the NPC stands in the 3D world)."),
    (s_hub, "12 · Main Menu", "NEW: phone-style hub opened from the HUD. Icon tiles with red dots / badges for new stuff; locked features show a badge."),
    (s_inventory, "13 · Inventory", "NEW: right-side drawer. Currency header, category tabs, capacity bar, item grid (count + rarity bar), Sort / Sell All."),
    (s_modal, "14 · Modal", "NEW: confirm dialog with a sand button band. Use for Sell All, Rebirth, rare-item sell warnings. Cancel = Ghost, Confirm = Success."),
    (s_cast_popup, "15 · Cast Popup", "NEW: pressing CAST opens this (unless Auto depth is on). Big depth readout, zone-coloured slider (max = line), presets, species count. "
     "The small DEPTH button next to CAST reopens it any time. Code: FishingController + UI/CastPopup."),
    (s_cast_popup_auto, "16 · Cast Popup — Auto depth", "Auto depth ticked: manual controls hide, CAST casts immediately with a random reachable depth each time. "
     "The DEPTH button shows AUTO; tap it to switch back to manual."),
]


def item_slot_group():
    samples = {"Common": "fish/PebbleMinnow", "Uncommon": "fish/PearlClam", "Rare": "fish/DewdropKoi", "Epic": "fish/CrystalGuppy",
               "Legendary": "fish/CoralSeahorse", "Mythic": "fish/NagaHatchling", "Bait": "equipment/Worm"}
    comps = [item_slot(p, r, 1, name=f"Rarity={r}, State=Normal", component=True) for r, p in samples.items()]
    comps += [item_slot("fish/DewdropKoi", "Rare", 2, state=st, name=f"Rarity=Rare, State={st.title()}", component=True) for st in ["selected", "new", "locked"]]
    comps += [item_slot(None, "Common", 0, state="empty", name="Rarity=None, State=Empty", component=True)]
    return {"name": "Item Slot Group", "layout": "V", "gap": 12, "children": [
        text("Item Slot (Inventory, 1:1)", "Heading", "cozy/subtext", name="Item Slot Label"),
        {"type": "VARIANTS", "name": "Item Slot", "layout": "H", "gap": 28, "pad": 24, "setRadius": 16,
         "description": "Inventory item slot, Option F 'Corner Ribbon' without star. Square 1:1. Rarity = corner colour; count bottom-right. "
                        "Swap the image fill of the 'Img …' layer per item.", "children": comps}]}


def art_library():
    sheets = json.load(open(os.path.join(_here, "..", "..", "tools", "art", "sheets.json"), encoding="utf-8"))["sheets"]
    rows = []
    for s in sheets:
        tiles = [{"name": "Tile " + n, "layout": "V", "gap": 6, "pad": 10, "w": 150, "cross": "CENTER", "radius": 16, "fill": "FFFFFF", **BORDER,
                  "children": [img(s["folder"] + "/" + n, 128), text(n, "Caption", "cozy/subtext", name="Name", align="CENTER", w=130)]}
                 for n, _ in s["items"]]
        rows.append({"name": s["id"], "layout": "V", "gap": 10, "children": [
            text(s["id"] + "  —  " + s["title"], "Heading", name="Title"),
            {"name": "Tiles", "layout": "H", "gap": 12, "children": tiles}]})
    return {"type": "SECTION", "name": "Aura Fishing — Art Library", "fill": "FBF7EF", "x": 7100, "y": 0, "children": [
        text("Art Library (assets/art, 3x3 AI sheets sliced)", "Display", name="Title", x=60, y=40),
        {"name": "Sheets", "layout": "V", "gap": 28, "x": 60, "y": 120, "children": rows}]}


def build():
    sections = []
    x0, y, col = 80, 80, 0
    row_h = 0
    for fn, title, note in SCREENS:
        frame = fn()
        fh = frame["h"]
        frame.update({"x": 60, "y": 110})
        sec = {"type": "SECTION", "name": title, "fill": "FBF7EF", "w": W + 120, "h": fh + 230, "x": x0 + col * (W + 200), "y": y, "children": [
            text(title, "Display", name="Title", x=60, y=30),
            frame,
            text(note, "Body", "cozy/subtext", name="Note", w=W, x=60, y=110 + fh + 30)]}
        sections.append(sec)
        row_h = max(row_h, fh + 230)
        col += 1
        if col == 2:
            col, y, row_h = 0, y + row_h + 120, 0
    outer = {"type": "SECTION", "name": "Aura Fishing — Game Menus (Cozy Lake)", "fill": "F3E9D8", "x": 3900, "y": 0, "pad": 80, "children": sections}
    return {"pageId": PAGE_ID, "replaceName": outer["name"], "tree": outer}


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "5_menus.json"), "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    if "--inv-parent" in sys.argv:
        parent = sys.argv[sys.argv.index("--inv-parent") + 1]
        with open(os.path.join(out, "9_inventory_patch.json"), "w", encoding="utf-8") as f:
            json.dump({"parentId": parent, "replaceName": "Inventory", "tree": inventory_drawer()}, f, ensure_ascii=False, indent=1)
    if "--components-parent" in sys.argv:
        parent = sys.argv[sys.argv.index("--components-parent") + 1]
        with open(os.path.join(out, "10_item_slot_component.json"), "w", encoding="utf-8") as f:
            json.dump({"parentId": parent, "replaceName": "Item Slot Group", "tree": item_slot_group()}, f, ensure_ascii=False, indent=1)
    if "--windows" in sys.argv:
        # parents: 05 Shop Rods, 06 Shop Baits, 07 Auras screen frames (ids passed after the flag)
        i = sys.argv.index("--windows")
        p05, p06, p07 = sys.argv[i + 1:i + 4]
        for key, parent, sc in [("05", p05, s_shop_rods()), ("06", p06, s_shop_baits()), ("07", p07, s_auras())]:
            win = [c for c in sc["children"] if c["name"].startswith("Window")][0]
            with open(os.path.join(out, f"18_window_{key}.json"), "w", encoding="utf-8") as f:
                json.dump({"parentId": parent, "replaceName": win["name"], "tree": win}, f, ensure_ascii=False, indent=1)
    if "--hub-parent" in sys.argv:
        parent = sys.argv[sys.argv.index("--hub-parent") + 1]
        with open(os.path.join(out, "7_main_menu_patch.json"), "w", encoding="utf-8") as f:
            json.dump({"parentId": parent, "replaceName": "Main Menu", "tree": hub_panel()}, f, ensure_ascii=False, indent=1)
    with open(os.path.join(out, "6_art_library.json"), "w", encoding="utf-8") as f:
        json.dump({"pageId": PAGE_ID, "replaceName": "Aura Fishing — Art Library", "tree": art_library()}, f, ensure_ascii=False, indent=1)
    print("written", os.path.join(out, "5_menus.json"))
