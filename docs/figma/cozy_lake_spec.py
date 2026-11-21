"""Generates the Figma build specs for the Cozy Lake style guide.

Run:  python -I docs/figma/cozy_lake_spec.py docs/figma/out
Then send each JSON through the fork plugin (see docs/SETUP.md, step 5):
  node "Figma For Roblox/cursor-talk-to-figma-mcp/scripts/figma-run.mjs" --channel=<ch> upsert_variables out/1_variables.json
  ... upsert_text_styles out/2_text_styles.json
  ... build_tree out/3_components.json
  ... build_tree out/4_style_guide.json
Colours must stay in sync with src/client/UI/New.luau (New.Theme) and docs/UI_STYLE.md.
"""
import json
import os
import sys

PAGE_ID = "3465:14993"  # "Out Space"

C = {
    "cozy/scene": "BFE8E0", "cozy/scene-deep": "A8DCD8", "cozy/panel": "FFF8EC", "cozy/sand": "F3E9D8",
    "cozy/track": "E6DCCB", "cozy/text": "3D4B5C", "cozy/subtext": "7A8A99", "cozy/on-accent": "FFFFFF",
    "cozy/coral": "FF9E80", "cozy/coral-lip": "E07A5C", "cozy/sky": "9AD4F5", "cozy/sky-lip": "6BB3DE",
    "cozy/mint": "7FD3B0", "cozy/mint-lip": "4FAF8A", "cozy/gold": "F2B544", "cozy/gold-lip": "C98B1E",
    "cozy/gem": "B79CF2", "cozy/gem-lip": "8C6FD6", "cozy/danger": "F27A7A", "cozy/danger-lip": "CC5454",
}
RARITY = [("Common", "9AA5B1"), ("Uncommon", "5CC98A"), ("Rare", "5AA9F0"), ("Epic", "B07CF0"), ("Legendary", "F2A93B"), ("Mythic", "F2668B")]
for n, h in RARITY:
    C["cozy/rarity/" + n.lower()] = h

FILL = ["FRAME_FILL", "SHAPE_FILL"]
TEXT = ["TEXT_FILL"]


def scopes(name):
    if name in ("cozy/text", "cozy/subtext", "cozy/on-accent"):
        return TEXT
    if name.endswith("-lip") or name == "cozy/track":
        return FILL + ["STROKE_COLOR"]
    if name.startswith("cozy/rarity") or name in ("cozy/gold", "cozy/gem", "cozy/coral", "cozy/mint", "cozy/sky", "cozy/danger"):
        return FILL + TEXT + ["STROKE_COLOR"]
    return FILL


variables = {"collections": [
    {"name": "Aura Fishing · Cozy Lake", "mode": "Default",
     "vars": [{"name": k, "type": "COLOR", "value": v, "scopes": scopes(k)} for k, v in C.items()]},
    {"name": "Aura Fishing · Size", "mode": "Default", "vars": [
        {"name": "cozy/radius/window", "type": "FLOAT", "value": 24, "scopes": ["CORNER_RADIUS"]},
        {"name": "cozy/radius/card", "type": "FLOAT", "value": 18, "scopes": ["CORNER_RADIUS"]},
        {"name": "cozy/radius/button", "type": "FLOAT", "value": 16, "scopes": ["CORNER_RADIUS"]},
        {"name": "cozy/space/xs", "type": "FLOAT", "value": 4, "scopes": ["GAP"]},
        {"name": "cozy/space/sm", "type": "FLOAT", "value": 8, "scopes": ["GAP"]},
        {"name": "cozy/space/md", "type": "FLOAT", "value": 12, "scopes": ["GAP"]},
        {"name": "cozy/space/lg", "type": "FLOAT", "value": 20, "scopes": ["GAP"]},
        {"name": "cozy/space/xl", "type": "FLOAT", "value": 32, "scopes": ["GAP"]},
    ]},
]}

FRED = ("Fredoka One", "Regular")
text_styles = {"styles": [
    {"name": "Aura Fishing/Display", "family": FRED[0], "style": FRED[1], "size": 40, "lineHeight": 110},
    {"name": "Aura Fishing/Title", "family": FRED[0], "style": FRED[1], "size": 26, "lineHeight": 115},
    {"name": "Aura Fishing/Heading", "family": FRED[0], "style": FRED[1], "size": 20, "lineHeight": 120},
    {"name": "Aura Fishing/Number", "family": FRED[0], "style": FRED[1], "size": 20, "lineHeight": 110},
    {"name": "Aura Fishing/Button", "family": FRED[0], "style": FRED[1], "size": 22, "lineHeight": 110},
    {"name": "Aura Fishing/Body", "family": "Nunito", "style": "Bold", "size": 16, "lineHeight": 135},
    {"name": "Aura Fishing/Small", "family": "Nunito", "style": "Bold", "size": 14, "lineHeight": 135},
    {"name": "Aura Fishing/Caption", "family": "Nunito", "style": "ExtraBold", "size": 12, "lineHeight": 120, "letterSpacing": 6},
]}


def v(name, opacity=None):
    # Translucent fills use raw hex: binding a variable drops paint opacity in the plugin API.
    if opacity is not None:
        return {"hex": C[name], "opacity": opacity}
    return {"var": name}


def text(t, style, color="cozy/text", **kw):
    d = {"type": "TEXT", "text": t, "textStyle": "Aura Fishing/" + style, "color": v(color)}
    d.update(kw)
    return d


# Component ids in the Figma file (built 2026-11-16). Used instead of in-plugin refs.
IDS = {"button": "3487:4298", "chip": "3487:4313", "tag": "3487:4328", "progress": "3487:4331", "catch": "3487:4333", "row": "3487:4339"}


def resolve_refs(node):
    if isinstance(node, dict):
        if node.get("type") == "INSTANCE" and node.get("ref") in IDS:
            node["ref"] = IDS[node["ref"]]
        for c in node.get("children", []):
            resolve_refs(c)
    return node


SOFT_SHADOW = [{"color": "3D4B5C", "a": 0.10, "y": 6, "blur": 18}]

# ---------------------------------------------------------------- components
BUTTONS = [("Primary", "cozy/coral", "cozy/coral-lip", "cozy/on-accent"),
           ("Secondary", "cozy/sky", "cozy/sky-lip", "cozy/on-accent"),
           ("Success", "cozy/mint", "cozy/mint-lip", "cozy/on-accent"),
           ("Gold", "cozy/gold", "cozy/gold-lip", "cozy/on-accent"),
           ("Gem", "cozy/gem", "cozy/gem-lip", "cozy/on-accent"),
           ("Ghost", "cozy/sand", "cozy/track", "cozy/text"),
           ("Danger", "cozy/danger", "cozy/danger-lip", "cozy/on-accent")]


def button_comp(style, face, lip, fg):
    return {"type": "COMPONENT", "name": f"Style={style}", "layout": "H", "pad": [12, 28, 16, 28],
            "main": "CENTER", "cross": "CENTER", "radiusVar": "cozy/radius/button",
            "fill": v(face), "stroke": v(lip), "strokeSides": {"b": 5}, "strokeAlign": "INSIDE",
            "children": [text("BUTTON", "Button", fg, name="Label")]}


CHIPS = [("Coins", "cozy/gold", "12,450"), ("Gems", "cozy/gem", "320"), ("Level", "cozy/mint", "Lv. 12"), ("Bag", "cozy/sky", "18 / 50")]


def chip_comp(kind, dot, val):
    return {"type": "COMPONENT", "name": f"Type={kind}", "layout": "H", "pad": [6, 16, 6, 8], "gap": 8, "cross": "CENTER",
            "radius": 999, "fill": v("cozy/panel"), "stroke": v("cozy/track"), "strokeW": 2,
            "children": [{"type": "ELLIPSE", "name": "Icon", "w": 24, "h": 24, "fill": v(dot)},
                         text(val, "Number", name="Value")]}


def tag_comp(name, _hex):
    return {"type": "COMPONENT", "name": f"Rarity={name}", "layout": "H", "pad": [3, 10, 3, 10], "radius": 999,
            "fill": v("cozy/rarity/" + name.lower()),
            "children": [text(name.upper(), "Caption", "cozy/on-accent", name="Label")]}


components = {"pageId": PAGE_ID, "replaceName": "Aura Fishing — Components", "tree": {
    "name": "Aura Fishing — Components", "layout": "V", "pad": 48, "gap": 36, "fill": "F7F1E6", "radius": 32, "y": 1300, "x": 200,
    "children": [
        text("Components", "Display"),
        text("Button", "Heading", "cozy/subtext"),
        {"type": "VARIANTS", "key": "button", "name": "Button", "layout": "H", "gap": 16, "pad": 16, "setRadius": 16,
         "description": "Cozy Lake button. Soft 5px lip at the bottom. Export name prefix 'Btn' for Roblox. Borders everywhere use cozy/track only.",
         "children": [button_comp(*b) for b in BUTTONS]},
        text("Chip", "Heading", "cozy/subtext"),
        {"type": "VARIANTS", "key": "chip", "name": "Chip", "layout": "H", "gap": 16, "pad": 16, "setRadius": 16,
         "children": [chip_comp(*c) for c in CHIPS]},
        text("Rarity Tag", "Heading", "cozy/subtext"),
        {"type": "VARIANTS", "key": "tag", "name": "Rarity Tag", "layout": "H", "gap": 12, "pad": 16, "setRadius": 16,
         "children": [tag_comp(*r) for r in RARITY]},
        text("Progress Bar / Catch Card / Window Row", "Heading", "cozy/subtext"),
        {"layout": "H", "gap": 24, "cross": "MIN", "name": "Row", "children": [
            {"type": "COMPONENT", "key": "progress", "name": "Progress Bar", "w": 260, "h": 12, "radius": 6, "fill": v("cozy/track"),
             "children": [{"type": "RECT", "name": "Fill", "w": 170, "h": 12, "radius": 6, "fill": v("cozy/mint"), "x": 0, "y": 0}]},
            {"type": "COMPONENT", "key": "catch", "name": "Catch Card", "layout": "V", "pad": 16, "gap": 6, "w": 300,
             "radius": 18, "fill": v("cozy/panel"), "stroke": v("cozy/track"), "strokeW": 2, "effects": SOFT_SHADOW,
             "children": [
                 {"type": "INSTANCE", "ref": "tag", "variant": "Rarity=Rare", "name": "Rarity"},
                 text("Glow Eel", "Title", name="Fish"),
                 text("4.2 kg  •  Glowing  •  Manual", "Small", "cozy/subtext", name="Meta"),
                 text("Worth 260 coins", "Number", "cozy/gold-lip", name="Value"),
             ]},
            {"type": "COMPONENT", "key": "row", "name": "Shop Row", "layout": "H", "pad": 12, "gap": 12, "w": 460, "cross": "CENTER",
             "radiusVar": "cozy/radius/button", "fill": v("cozy/sand"), "children": [
                 {"layout": "V", "gap": 2, "name": "Text", "fillW": True, "children": [
                     text("Coral Rod", "Heading", name="Title"),
                     text("+15% Luck, +0.30 Reel Power  |  2,500 Coins", "Small", "cozy/subtext", name="Sub"),
                 ]},
                 {"type": "INSTANCE", "ref": "button", "variant": "Style=Gold", "name": "Action", "texts": {"Label": "Buy"}},
             ]},
        ]},
    ]}}

# ---------------------------------------------------------------- style guide


def swatch(name):
    return {"layout": "V", "gap": 6, "pad": 10, "w": 176, "radius": 16, "fill": "FFFFFF", "stroke": v("cozy/track"), "strokeW": 2,
            "name": "Swatch " + name, "children": [
                {"type": "RECT", "name": "Color", "w": 156, "h": 72, "radius": 12, "fill": v(name), "fillW": True},
                text(name.replace("cozy/", ""), "Small", name="Name"),
                text("#" + C[name], "Caption", "cozy/subtext", name="Hex"),
            ]}


def section(title, sub, children):
    return {"layout": "V", "gap": 20, "name": "Section " + title, "fillW": True, "children": [
        {"layout": "V", "gap": 4, "name": "Head", "children": [text(title, "Title"), text(sub, "Body", "cozy/subtext", w=1100)]},
        *children]}


TYPE_ROWS = [("Display", "Aura Fishing", "Fredoka One 40 — screen titles"), ("Title", "Glow Eel", "Fredoka One 26 — window & card titles"),
             ("Heading", "Coral Rod", "Fredoka One 20 — row titles"), ("Number", "12,450", "Fredoka One 20 — currency, stats"),
             ("Button", "CAST", "Fredoka One 22 — buttons"), ("Body", "Hold to reel the fish in!", "Nunito Bold 16 — body text"),
             ("Small", "+15% Luck, +0.30 Reel Power", "Nunito Bold 14 — secondary text"), ("Caption", "LEGENDARY", "Nunito ExtraBold 12 — tags, labels")]


def hud_sample():
    return {"name": "Sample — Fishing HUD (1280×720)", "w": 1280, "h": 720, "radius": 28, "clip": True,
            "fill": {"grad": ["DDF5EE", "A8DCD8"], "angle": 90}, "children": [
                # top-left stats card
                {"name": "Stats", "layout": "V", "gap": 10, "pad": 16, "w": 280, "radius": 18, "fill": v("cozy/panel"),
                 "stroke": v("cozy/track"), "strokeW": 2, "x": 24, "y": 24, "children": [
                     text("Lv. 12   (340 / 900 XP)", "Heading", name="Level"),
                     {"type": "INSTANCE", "ref": "progress", "name": "XP", "fillW": True},
                     {"layout": "H", "gap": 8, "name": "Chips", "children": [
                         {"type": "INSTANCE", "ref": "chip", "variant": "Type=Coins"},
                         {"type": "INSTANCE", "ref": "chip", "variant": "Type=Gems"}]},
                     text("Aura: Neon Wave  (+15% Luck)", "Small", "cozy/subtext", name="Aura"),
                 ]},
                # notification pill
                {"name": "Toast", "layout": "H", "pad": [8, 18, 8, 18], "radius": 999, "fill": v("cozy/panel"), "stroke": v("cozy/track"),
                 "strokeW": 2, "x": 470, "y": 24, "children": [text("You rolled Neon Wave (1/100)!", "Body", "cozy/rarity/rare")]},
                # catch card
                {"type": "INSTANCE", "ref": "catch", "name": "Catch Card", "x": 490, "y": 90},
                # bite indicator
                {"name": "Bite", "layout": "H", "pad": [4, 28, 4, 28], "radius": 999, "fill": v("cozy/panel"), "stroke": v("cozy/track"),
                 "strokeW": 2, "x": 608, "y": 520, "children": [text("!", "Display", "cozy/rarity/rare")]},
                # cast
                {"type": "INSTANCE", "ref": "button", "variant": "Style=Primary", "name": "CAST", "x": 555, "y": 610, "texts": {"Label": "HOOK!"}},
                # depth panel
                {"name": "Depth", "layout": "V", "gap": 8, "pad": 16, "w": 280, "radius": 18, "fill": v("cozy/panel"), "stroke": v("cozy/track"),
                 "strokeW": 2, "x": 24, "y": 560, "children": [
                     text("Depth 80m / 150m", "Heading"),
                     text("Mid Water  •  9 species here", "Small", "cozy/subtext"),
                     {"name": "Slider", "w": 248, "h": 14, "radius": 7, "fill": v("cozy/track"), "children": [
                         {"type": "RECT", "w": 132, "h": 14, "radius": 7, "fill": v("cozy/sky"), "x": 0, "y": 0}]},
                 ]},
                # right menu
                {"name": "Menu", "layout": "V", "gap": 10, "w": 150, "x": 1106, "y": 210, "children": [
                    {"type": "INSTANCE", "ref": "button", "variant": "Style=Ghost", "texts": {"Label": "Shop"}, "fillW": True},
                    {"type": "INSTANCE", "ref": "button", "variant": "Style=Ghost", "texts": {"Label": "Auras"}, "fillW": True},
                    {"type": "INSTANCE", "ref": "button", "variant": "Style=Ghost", "texts": {"Label": "Fishdex"}, "fillW": True}]},
                # bottom right
                {"name": "Actions", "layout": "V", "gap": 10, "w": 190, "x": 1066, "y": 520, "children": [
                    {"type": "INSTANCE", "ref": "chip", "variant": "Type=Bag"},
                    {"type": "INSTANCE", "ref": "button", "variant": "Style=Success", "texts": {"Label": "AUTO: ON"}, "fillW": True},
                    {"type": "INSTANCE", "ref": "button", "variant": "Style=Gold", "texts": {"Label": "SELL ALL"}, "fillW": True}]},
                # reel minigame
                {"name": "Reel Minigame", "layout": "V", "gap": 10, "pad": 14, "w": 170, "radius": 24, "fill": v("cozy/panel"),
                 "stroke": v("cozy/track"), "strokeW": 2, "x": 820, "y": 150, "children": [
                     text("Epic fish!", "Heading", "cozy/rarity/epic", align="CENTER", w=142),
                     {"name": "Body", "layout": "H", "gap": 14, "main": "CENTER", "fillW": True, "children": [
                         {"name": "Water", "w": 64, "h": 300, "radius": 14, "fill": v("cozy/sky"), "clip": True, "children": [
                             {"type": "RECT", "name": "Catch Bar", "w": 64, "h": 80, "radius": 12, "fill": v("cozy/mint", 0.9), "x": 0, "y": 150},
                             {"type": "TEXT", "name": "Fish", "text": "><>", "textStyle": "Aura Fishing/Heading", "color": v("cozy/rarity/epic"), "x": 14, "y": 178}]},
                         {"name": "Progress", "w": 18, "h": 300, "radius": 9, "fill": v("cozy/track"), "children": [
                             {"type": "RECT", "w": 18, "h": 190, "radius": 9, "fill": v("cozy/gold"), "x": 0, "y": 110}]},
                     ]},
                     text("Hold to reel", "Caption", "cozy/subtext", align="CENTER", w=142),
                 ]},
            ]}


guide = {"pageId": PAGE_ID, "replaceName": "Aura Fishing — Cozy Lake Style Guide", "tree": {
    "name": "Aura Fishing — Cozy Lake Style Guide", "layout": "V", "pad": 64, "gap": 56, "w": 1440, "radius": 32,
    "fill": "FBF7EF", "x": 2200, "y": 0, "children": [
        {"layout": "V", "gap": 8, "name": "Cover", "children": [
            text("Aura Fishing — Cozy Lake", "Display"),
            text("Soft pastels, cream cards, no hard outlines, rounded and friendly. Rarity colours stay saturated so rare catches still pop. "
                 "Source of truth in code: src/client/UI/New.luau (New.Theme) • docs/UI_STYLE.md", "Body", "cozy/subtext", w=1200)]},
        section("Colours", "Surfaces, text and accents. Every accent has a darker 'lip' used for the soft 3D edge on buttons.", [
            {"layout": "H", "wrap": True, "gap": 16, "rowGap": 16, "w": 1312, "name": "Swatches",
             "children": [swatch(k) for k in C if not k.startswith("cozy/rarity")]}]),
        section("Rarity", "Used for tags, catch-card borders, the bite '!' and minigame frames.", [
            {"layout": "H", "wrap": True, "gap": 16, "rowGap": 16, "w": 1312, "name": "Rarity Swatches",
             "children": [swatch("cozy/rarity/" + n.lower()) for n, _ in RARITY]}]),
        section("Typography", "Fredoka One for display, numbers and buttons; Nunito for body. Both exist in Roblox.", [
            {"layout": "V", "gap": 14, "name": "Type Scale", "children": [
                {"layout": "H", "gap": 24, "cross": "CENTER", "name": "Type " + s, "children": [
                    text(sample, s, w=520), text(desc, "Small", "cozy/subtext")]} for s, sample, desc in TYPE_ROWS]}]),
        section("Components", "Instances of the Components board. Name buttons 'Btn …' in screens so FigmaRoblox exports them as buttons.", [
            {"layout": "H", "wrap": True, "gap": 16, "rowGap": 16, "w": 1312, "name": "Buttons", "children": [
                {"type": "INSTANCE", "ref": "button", "variant": "Style=" + b[0], "texts": {"Label": b[0].upper()}} for b in BUTTONS]},
            {"layout": "H", "gap": 16, "name": "Chips & Tags", "cross": "CENTER", "children": [
                *[{"type": "INSTANCE", "ref": "chip", "variant": "Type=" + c[0]} for c in CHIPS],
                *[{"type": "INSTANCE", "ref": "tag", "variant": "Rarity=" + r[0]} for r in RARITY]]},
            {"layout": "H", "gap": 24, "name": "Cards", "children": [
                {"type": "INSTANCE", "ref": "catch"},
                {"name": "Window", "layout": "V", "gap": 12, "pad": 20, "w": 520, "radiusVar": "cozy/radius/window",
                 "fill": v("cozy/panel"), "stroke": v("cozy/track"), "strokeW": 2, "effects": SOFT_SHADOW, "children": [
                     {"layout": "H", "name": "Header", "fillW": True, "cross": "CENTER", "main": "SPACE_BETWEEN", "children": [
                         text("Shop", "Title"),
                         {"type": "INSTANCE", "ref": "button", "variant": "Style=Danger", "texts": {"Label": "X"}}]},
                     {"type": "INSTANCE", "ref": "row", "fillW": True},
                     {"type": "INSTANCE", "ref": "row", "fillW": True, "texts": {"Title": "Moonsilver Rod", "Sub": "+35% Luck, +0.50 Reel Power  |  15,000 Coins"}},
                 ]}]},
        ]),
        section("Sample screen", "How the pieces sit over the 3D world. Panels keep a 2px sand edge so they separate from the scene.", [hud_sample()]),
    ]}}

def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    resolve_refs(guide["tree"])
    for name, data in [("1_variables", variables), ("2_text_styles", text_styles), ("3_components", components), ("4_style_guide", guide)]:
        with open(os.path.join(out, name + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
    print("specs written to", out)


if __name__ == "__main__":
    main()
