"""Generate C16 Enhance Popup with Attribute Comparison Table in Figma on page Out Space.
Recreates the exact user-uploaded design with Before/After/Gain columns and replaces the old arrow with clean chevron designs.
Run: python -I docs/figma/enhance_user_mockup.py docs/figma/out
Send: python -I docs/figma/send_blocks.py docs/figma/out/26_enhance_user_mockup_ops.json --channel aura-fishing
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
img, ftxt, btn = m.img, m.ftxt, m.btn

COL_X = 28400
SEC_Y = 3784

# Colors
C_PANEL = "FFF8EC"
C_SAND = "F3E9D8"
C_TRACK = "E6DCCB"
C_TEXT = "3D4B5C"
C_SUBTEXT = "7A8A99"
C_SKY = "6BB3DE"
C_MINT = "4FAF8A"
C_GOLD = "F2B544"
C_GOLD_LIP = "C98B1E"

# Table column background tints from user screenshot
BG_BEFORE = "F0F8FD"
BG_BEFORE_CELL = "F6FBFE"
BG_AFTER = "F0FAF5"
BG_AFTER_CELL = "F4FBF7"
DIVIDER_COLOR = "E6DCCB"
ROW_DIVIDER = "F0EAE1"


def chevron_separator(style="clean"):
    """Arrow replacement: strictly no old arrow unicode, using clean chevron options."""
    if style == "clean":
        return ftxt(">", 18, C_SUBTEXT, name="Chevron >", align="CENTER")
    elif style == "circle":
        return {
            "name": "Circle Chevron >",
            "w": 22,
            "h": 22,
            "radius": 999,
            "fill": v("cozy/sand"),
            "stroke": v("cozy/track"),
            "strokeW": 1.5,
            "layout": "H",
            "main": "CENTER",
            "cross": "CENTER",
            "children": [ftxt(">", 13, C_TEXT, name="Symbol")],
        }
    elif style == "double":
        return ftxt(">>", 15, C_MINT, name="Double Chevron >>", align="CENTER")
    elif style == "pill":
        return {
            "name": "Pill Chevron >",
            "layout": "H",
            "pad": [2, 6, 2, 6],
            "radius": 999,
            "fill": v("cozy/track"),
            "children": [ftxt(">", 12, C_TEXT, name="Symbol")],
        }
    return ftxt(">", 18, C_SUBTEXT, name="Chevron >")


def header_row(chevron_style="clean"):
    # Left: Equipment Icon Frame
    pic_box = {
        "name": "Picture Box",
        "w": 92,
        "h": 92,
        "radius": 22,
        "fill": "FFFFFF",
        **BORDER,
        "layout": "H",
        "main": "CENTER",
        "cross": "CENTER",
        "children": [img("equipment/CoralRod", 80)],
    }

    # Right: Info Stack
    preview_tag = {
        "name": "Tag Enchant Preview",
        "layout": "H",
        "gap": 4,
        "pad": [3, 10, 3, 10],
        "radius": 999,
        "fill": {"hex": "EAF8F2", "opacity": 1.0},
        "cross": "CENTER",
        "children": [
            ftxt("✦", 10, C_MINT, name="StarIcon"),
            ftxt("Enchant Preview", 12, "2E7D5B", name="Label"),
        ],
    }

    level_row = {
        "name": "Level Row",
        "layout": "H",
        "gap": 8,
        "cross": "CENTER",
        "children": [
            ftxt("Level", 14, C_SUBTEXT, name="LevelLabel"),
            {
                "name": "Pill Before",
                "layout": "H",
                "pad": [2, 10, 2, 10],
                "radius": 999,
                "fill": v("cozy/sky-lip"),
                "children": [ftxt("+3", 13, "FFFFFF", name="Text")],
            },
            chevron_separator(chevron_style),
            {
                "name": "Pill After",
                "layout": "H",
                "pad": [2, 10, 2, 10],
                "radius": 999,
                "fill": v("cozy/mint-lip"),
                "children": [ftxt("+4", 13, "FFFFFF", name="Text")],
            },
        ],
    }

    info_stack = {
        "name": "Info Stack",
        "layout": "V",
        "gap": 4,
        "children": [
            preview_tag,
            text("Enhance Coral Rod", "Title", name="Title"),
            level_row,
        ],
    }

    return {
        "name": "Header Row",
        "layout": "H",
        "gap": 16,
        "fillW": True,
        "cross": "CENTER",
        "children": [pic_box, info_stack],
    }


def table_component():
    w_attr = 130
    w_before = 84
    w_after = 84
    w_gain = 134

    # 1. Table Header
    th_attr = {
        "name": "TH Attribute",
        "w": w_attr,
        "h": 44,
        "pad": [0, 14, 0, 14],
        "layout": "H",
        "cross": "CENTER",
        "children": [ftxt("Attribute", 13, C_SUBTEXT, name="Label")],
    }
    th_before = {
        "name": "TH Before",
        "w": w_before,
        "h": 44,
        "fill": {"hex": BG_BEFORE, "opacity": 1.0},
        "layout": "V",
        "gap": 0,
        "main": "CENTER",
        "cross": "CENTER",
        "children": [
            ftxt("Before", 12, C_SKY, name="Label"),
            ftxt("+3", 11, C_SKY, name="Lv"),
        ],
    }
    th_after = {
        "name": "TH After",
        "w": w_after,
        "h": 44,
        "fill": {"hex": BG_AFTER, "opacity": 1.0},
        "layout": "V",
        "gap": 0,
        "main": "CENTER",
        "cross": "CENTER",
        "children": [
            ftxt("After", 12, C_MINT, name="Label"),
            ftxt("+4", 11, C_MINT, name="Lv"),
        ],
    }
    th_gain = {
        "name": "TH Gain",
        "w": w_gain,
        "h": 44,
        "pad": [0, 14, 0, 14],
        "layout": "H",
        "main": "MAX",
        "cross": "CENTER",
        "children": [ftxt("Gain", 13, C_SUBTEXT, name="Label")],
    }

    def v_div(h=44):
        return {"type": "RECT", "name": "V_Divider", "w": 1, "h": h, "fill": DIVIDER_COLOR}

    t_head = {
        "name": "Table Head Row",
        "layout": "H",
        "fillW": True,
        "h": 44,
        "children": [th_attr, v_div(44), th_before, v_div(44), th_after, v_div(44), th_gain],
    }

    # 2. Data Rows
    def data_row(attr_name, before_val, after_val, gain_val, is_last=False):
        c_attr = {
            "name": "Cell Attribute",
            "w": w_attr,
            "h": 48,
            "pad": [0, 14, 0, 14],
            "layout": "H",
            "cross": "CENTER",
            "children": [ftxt(attr_name, 15, C_TEXT, name="Text")],
        }
        c_before = {
            "name": "Cell Before",
            "w": w_before,
            "h": 48,
            "fill": {"hex": BG_BEFORE_CELL, "opacity": 1.0},
            "layout": "H",
            "main": "CENTER",
            "cross": "CENTER",
            "children": [ftxt(before_val, 15, C_TEXT, name="Text")],
        }
        c_after = {
            "name": "Cell After",
            "w": w_after,
            "h": 48,
            "fill": {"hex": BG_AFTER_CELL, "opacity": 1.0},
            "layout": "H",
            "main": "CENTER",
            "cross": "CENTER",
            "children": [ftxt(after_val, 15, C_MINT, name="Text")],
        }
        gain_badge = {
            "name": "Gain Badge",
            "layout": "H",
            "pad": [3, 9, 3, 9],
            "radius": 999,
            "fill": v("cozy/mint-lip"),
            "children": [ftxt(gain_val, 12, "FFFFFF", name="Value")],
        }
        c_gain = {
            "name": "Cell Gain",
            "w": w_gain,
            "h": 48,
            "pad": [0, 14, 0, 14],
            "layout": "H",
            "main": "MAX",
            "cross": "CENTER",
            "children": [gain_badge],
        }

        row_content = {
            "name": "Row " + attr_name,
            "layout": "H",
            "fillW": True,
            "h": 48,
            "children": [c_attr, v_div(48), c_before, v_div(48), c_after, v_div(48), c_gain],
        }
        if is_last:
            return [row_content]
        h_div = {"type": "RECT", "name": "H_Divider", "w": 436, "h": 1, "fill": ROW_DIVIDER}
        return [row_content, h_div]

    h_head_div = {"type": "RECT", "name": "H_Head_Divider", "w": 436, "h": 1, "fill": DIVIDER_COLOR}

    row_luck = data_row("Luck", "+17%", "+18%", "+1%")
    row_reel = data_row("Reel Power", "+0.34", "+0.35", "+0.01")
    row_bar = data_row("Catch Bar", "+5.6%", "+5.8%", "+0.2%", is_last=True)

    return {
        "name": "Attribute Comparison Table",
        "layout": "V",
        "w": 436,
        "radius": 18,
        "clip": True,
        "fill": "FFFFFF",
        **BORDER,
        "children": [t_head, h_head_div] + row_luck + row_reel + row_bar,
    }


def make_user_modal(chevron_style="clean"):
    head = header_row(chevron_style)
    tbl = table_component()

    body = [head, tbl]

    footer = [
        btn("Ghost", "Cancel", "Btn Cancel", fillW=True),
        es.price_btn("1.4k", style="gold"),
    ]

    return es.modal("Enhance Popup", body, footer, w=500, x=390, y=75)


def make_chevron_comparison_board():
    def row(title, style, desc):
        sample_level = {
            "name": "Sample " + title,
            "layout": "H",
            "gap": 8,
            "cross": "CENTER",
            "children": [
                ftxt("Level", 14, C_SUBTEXT),
                {
                    "name": "Pill Before",
                    "layout": "H",
                    "pad": [2, 10, 2, 10],
                    "radius": 999,
                    "fill": v("cozy/sky-lip"),
                    "children": [ftxt("+3", 13, "FFFFFF")],
                },
                chevron_separator(style),
                {
                    "name": "Pill After",
                    "layout": "H",
                    "pad": [2, 10, 2, 10],
                    "radius": 999,
                    "fill": v("cozy/mint-lip"),
                    "children": [ftxt("+4", 13, "FFFFFF")],
                },
            ],
        }
        return {
            "name": "Option " + title,
            "layout": "V",
            "gap": 6,
            "pad": 12,
            "radius": 12,
            "fill": v("cozy/sand"),
            "fillW": True,
            "children": [
                text(title, "Heading", name="Title"),
                sample_level,
                text(desc, "Small", "cozy/subtext", name="Desc"),
            ],
        }

    options = [
        row("Style 1: Clean Minimal Chevron >", "clean", "Simplest and most readable. Matches Roblox font typography without extra clutter."),
        row("Style 2: Circular Badge Chevron >", "circle", "Tactile token feel. Encloses the chevron in a 22px sand-colored pill button."),
        row("Style 3: Double Chevron >>", "double", "Dynamic fast-forward feel in mint green, emphasizing rapid progression."),
        row("Style 4: Pill Separator Chevron >", "pill", "Subtle rounded pill connector between the two level pills."),
    ]

    return es.board(
        "Arrow / Chevron Design Variations (Pick One)",
        "The old unicode arrow (→) has been replaced. Here are 4 clean chevron variations for the Level transition row:",
        options,
        w=680,
    )


def make_spec_board():
    specs = [
        text("1. Layout: 500px Cozy Lake Modal with cream background (#FFF8EC), 36px radius, and 2px track border.", "Small", "cozy/text"),
        text("2. Header: Coral Rod square card (92px), Enchant Preview mint chip, Fredoka One title, and Level transition row.", "Small", "cozy/text"),
        text("3. Table Grid: 4 columns with Before (+3) in subtle Sky Blue (#F0F8FD) and After (+4) in subtle Mint (#F0FAF5).", "Small", "cozy/text"),
        text("4. Gain Column: High-contrast Mint Green pill badges (+1%, +0.01, +0.2%) for immediate reward readability.", "Small", "cozy/text"),
        text("5. Footer: Sand-colored footer (#F3E9D8) with Cancel ghost button and 1.4k Gold lip coin button.", "Small", "cozy/text"),
        text("6. Strict Compliance: Zero checkmarks, zero bullets, and zero emojis used.", "Small", "cozy/text"),
    ]
    return es.board(
        "Screen C16 · UI Specification & Features",
        "Exact design specifications matching the user mockup for Roblox implementation:",
        specs,
        w=620,
    )


def build():
    scr_1 = es.screen_block(
        "C16 · Enhance Popup (Style 1: Clean Chevron >)",
        m.screen("Screen C16 Clean Chevron", [make_user_modal("clean")], dim=True),
        60,
        180,
    )
    scr_2 = es.screen_block(
        "C16 · Enhance Popup (Style 2: Circle Badge >)",
        m.screen("Screen C16 Circle Badge", [make_user_modal("circle")], dim=True),
        1400,
        180,
    )

    b_chevrons = make_chevron_comparison_board()
    b_spec = make_spec_board()

    b_chevrons.update(x=60, y=980)
    b_spec.update(x=780, y=980)

    sec = {
        "type": "SECTION",
        "name": "C16 · Enhance Progression Table — 3 Design Layouts (Pick One)",
        "fill": "FBF7EF",
        "x": COL_X,
        "y": SEC_Y,
        "w": 2800,
        "h": 1420,
        "children": [
            text(
                "C16 · Enhance Popup — Attribute Comparison Table (User Mockup)",
                "Display",
                name="Title",
                x=60,
                y=40,
            ),
            text(
                "Exact implementation of the user's mockup with Before / After / Gain table grid, column-specific tints, and clean chevron (>) separator. No checkmarks, bullets, or emojis.",
                "Body",
                "cozy/subtext",
                name="Sub",
                x=60,
                y=96,
                w=2200,
            ),
            scr_1,
            scr_2,
            b_chevrons,
            b_spec,
        ],
    }

    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(_here, "out")
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "26_enhance_user_mockup_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
