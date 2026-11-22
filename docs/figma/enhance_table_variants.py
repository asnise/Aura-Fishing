"""Generate 3 Enhance (+0 to +10) Progression Table UI Layout Variants in Figma on page Out Space.
Run: python -I docs/figma/enhance_table_variants.py docs/figma/out
Send: python -I docs/figma/send_blocks.py docs/figma/out/25_enhance_table_variants_ops.json --channel aura-fishing
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
img, ftxt, btn, chip = m.img, m.ftxt, m.btn, m.chip
vec, svgn = es.vec, es.svgn

COL_X = 28400
SEC_Y = 3784

PROGRESSION_DATA = [
    (0, "1.00x", "+15.0%", "+0.30", "+5.0%", "Base", "Base", "muted"),
    (1, "1.04x", "+15.6%", "+0.31", "+5.2%", "1.2k", "Done", "muted"),
    (2, "1.08x", "+16.2%", "+0.32", "+5.4%", "1.8k", "Done", "muted"),
    (3, "1.12x", "+16.9%", "+0.34", "+5.6%", "2.7k", "CURRENT", "current"),
    (4, "1.17x", "+17.5%", "+0.35", "+5.8%", "4.0k", "NEXT", "next"),
    (5, "1.22x", "+18.2%", "+0.36", "+6.1%", "6.1k", "Locked", "locked"),
    (6, "1.27x", "+19.0%", "+0.38", "+6.3%", "9.1k +2S", "Locked", "locked"),
    (7, "1.32x", "+19.7%", "+0.39", "+6.6%", "13.7k +3S", "Locked", "locked"),
    (8, "1.37x", "+20.5%", "+0.41", "+6.8%", "20.5k +4S", "Locked", "locked"),
    (9, "1.42x", "+21.3%", "+0.43", "+7.1%", "30.8k +5S", "Locked", "locked"),
    (10, "1.48x", "+22.2%", "+0.44", "+7.4%", "MAX", "PEAK", "max"),
]


def status_badge(label, kind):
    if kind == "current":
        return {
            "name": "Badge Current",
            "layout": "H",
            "pad": [2, 8, 2, 8],
            "radius": 999,
            "fill": v("cozy/sky-lip"),
            "children": [ftxt(label, 11, "FFFFFF", name="Text")],
        }
    elif kind == "next":
        return {
            "name": "Badge Next",
            "layout": "H",
            "pad": [2, 8, 2, 8],
            "radius": 999,
            "fill": v("cozy/mint-lip"),
            "children": [ftxt(label, 11, "FFFFFF", name="Text")],
        }
    elif kind == "max":
        return {
            "name": "Badge Max",
            "layout": "H",
            "pad": [2, 8, 2, 8],
            "radius": 999,
            "fill": v("cozy/gold"),
            "children": [ftxt(label, 11, "FFFFFF", name="Text")],
        }
    elif kind == "done":
        return {
            "name": "Badge Done",
            "layout": "H",
            "pad": [2, 6, 2, 6],
            "radius": 999,
            "fill": v("cozy/track"),
            "children": [ftxt(label, 11, "7A8A99", name="Text")],
        }
    else:
        return {
            "name": "Badge Locked",
            "layout": "H",
            "pad": [2, 6, 2, 6],
            "radius": 999,
            "fill": v("cozy/track"),
            "children": [ftxt(label, 11, "9AA5B1", name="Text")],
        }


def stat_cmp_row(label, val_from, val_to, diff_str=None):
    kids = [
        text(label, "Small", "cozy/subtext", name="Label", w=100),
        ftxt(val_from, 15, "3D4B5C", name="From"),
        text("→", "Small", "cozy/subtext", name="Arrow"),
        ftxt(val_to, 15, "4FAF8A", name="To"),
    ]
    if diff_str:
        kids.append(
            {
                "name": "Diff",
                "layout": "H",
                "pad": [1, 6, 1, 6],
                "radius": 6,
                "fill": {"hex": "EAF8F2", "opacity": 1.0},
                "children": [ftxt(diff_str, 12, "4FAF8A", name="Value")],
            }
        )
    return {
        "name": "Cmp " + label,
        "layout": "H",
        "gap": 8,
        "fillW": True,
        "cross": "CENTER",
        "children": kids,
    }


# ================================================================ OPTION A: Dual-Panel Modal
def table_row_a(lv, mult, luck, reel, bar, cost_str, status_txt, kind):
    is_curr = kind == "current"
    is_nxt = kind == "next"
    is_mx = kind == "max"

    bg = v("cozy/panel")
    border_kw = {}
    text_color = "3D4B5C"

    if is_curr:
        bg = {"hex": "EBF5FB", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/sky-lip"), "strokeW": 1.5}
        text_color = "2B6CB0"
    elif is_nxt:
        bg = {"hex": "EAF8F2", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/mint-lip"), "strokeW": 1.5}
        text_color = "23784F"
    elif is_mx:
        bg = {"hex": "FEF8E7", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/gold"), "strokeW": 1.5}
        text_color = "9C6805"
    elif kind == "muted":
        text_color = "7A8A99"

    lv_str = f"+{lv}" if lv > 0 else "+0"
    return {
        "name": f"Row {lv_str}",
        "layout": "H",
        "gap": 6,
        "pad": [4, 8, 4, 8],
        "h": 28,
        "radius": 8,
        "cross": "CENTER",
        "fill": bg,
        **border_kw,
        "children": [
            ftxt(lv_str, 13, text_color, name="Lv", w=34),
            ftxt(mult, 12, "7A8A99", name="Mult", w=42),
            ftxt(luck, 12, text_color, name="Luck", w=54),
            ftxt(reel, 12, text_color, name="Reel", w=48),
            ftxt(bar, 12, text_color, name="Bar", w=52),
            ftxt(cost_str, 12, text_color, name="Cost", w=68),
            {"name": "StatusBox", "layout": "H", "main": "CENTER", "w": 72, "children": [status_badge(status_txt, kind)]},
        ],
    }


def make_dual_panel_modal():
    # Left Column: Item + Step Diff + Actions
    left_kids = [
        {
            "name": "Equipment Pic",
            "w": 100,
            "h": 100,
            "radius": 20,
            "fill": "FFFFFF",
            **BORDER,
            "layout": "H",
            "main": "CENTER",
            "cross": "CENTER",
            "children": [img("equipment/CoralRod", 84)],
        },
        text("Coral Rod", "Title", name="Title", align="CENTER", w=290),
        {
            "name": "Levels",
            "layout": "H",
            "gap": 8,
            "cross": "CENTER",
            "main": "CENTER",
            "children": [
                es.info_pill("+3", "cozy/on-accent", "cozy/sky-lip"),
                text("→", "Title", "cozy/subtext", name="Arrow"),
                es.info_pill("+4", "cozy/on-accent", "cozy/mint-lip"),
            ],
        },
        {
            "name": "Stat Box",
            "layout": "V",
            "gap": 8,
            "pad": 12,
            "radius": 14,
            "fill": v("cozy/sand"),
            "fillW": True,
            "children": [
                stat_cmp_row("Luck", "+16.9%", "+17.5%", "+0.6%"),
                stat_cmp_row("Reel Power", "+0.34", "+0.35", "+0.01"),
                stat_cmp_row("Catch Bar", "+5.6%", "+5.8%", "+0.2%"),
            ],
        },
        {
            "name": "Materials Note",
            "layout": "H",
            "gap": 8,
            "cross": "CENTER",
            "pad": [4, 8, 4, 8],
            "opacity": 0.65,
            "children": [
                img("materials/enhance_stone", 22),
                text("x2 Enhance Stone (Phase 2: +6+)", "Caption", "cozy/subtext", name="Label"),
            ],
        },
        {
            "name": "Buttons",
            "layout": "H",
            "gap": 10,
            "fillW": True,
            "main": "CENTER",
            "children": [
                btn("Ghost", "Cancel", "Btn Cancel", fillW=True),
                es.price_btn("4.0k", style="gold"),
            ],
        },
    ]

    left_panel = {
        "name": "Left Panel (Upgrade Step)",
        "layout": "V",
        "gap": 10,
        "w": 310,
        "cross": "CENTER",
        "children": left_kids,
    }

    # Right Column: Progression Table
    table_head = {
        "name": "Table Header",
        "layout": "H",
        "gap": 6,
        "pad": [6, 8, 6, 8],
        "radius": 8,
        "fill": v("cozy/sand"),
        "cross": "CENTER",
        "children": [
            ftxt("LV", 12, "7A8A99", name="H_Lv", w=34),
            ftxt("MULT", 12, "7A8A99", name="H_Mult", w=42),
            ftxt("LUCK", 12, "7A8A99", name="H_Luck", w=54),
            ftxt("REEL", 12, "7A8A99", name="H_Reel", w=48),
            ftxt("BAR", 12, "7A8A99", name="H_Bar", w=52),
            ftxt("COST", 12, "7A8A99", name="H_Cost", w=68),
            ftxt("STATUS", 12, "7A8A99", name="H_Status", w=72, align="CENTER"),
        ],
    }

    rows = [table_row_a(*item) for item in PROGRESSION_DATA]
    table_container = {
        "name": "Progression Table",
        "layout": "V",
        "gap": 2,
        "w": 440,
        "radius": 12,
        "pad": 6,
        "fill": v("cozy/panel"),
        **BORDER,
        "children": [table_head] + rows,
    }

    right_panel = {
        "name": "Right Panel (Progression Ladder)",
        "layout": "V",
        "gap": 8,
        "w": 460,
        "children": [
            {
                "name": "Header Line",
                "layout": "H",
                "fillW": True,
                "main": "SPACE_BETWEEN",
                "cross": "CENTER",
                "children": [
                    text("Enhance Progression (+0 to +10)", "Heading", name="Title"),
                    es.info_pill("Max +48% Total", "cozy/gold-lip", "cozy/sand"),
                ],
            },
            table_container,
        ],
    }

    divider = {
        "type": "RECT",
        "name": "Divider",
        "w": 2,
        "h": 460,
        "fill": v("cozy/track"),
    }

    return {
        "name": "Dual-Panel Enhance Modal",
        "layout": "H",
        "gap": 24,
        "pad": [28, 32, 28, 32],
        "w": 860,
        "radius": 32,
        "clip": True,
        "fill": v("cozy/panel"),
        **BORDER,
        "effects": SOFT,
        "x": 210,
        "y": 95,
        "cross": "CENTER",
        "children": [left_panel, divider, right_panel],
    }


# ================================================================ OPTION B: Tabbed Modal
def table_row_b(lv, mult, luck, reel, bar, cost_str, status_txt, kind):
    is_curr = kind == "current"
    is_nxt = kind == "next"
    is_mx = kind == "max"

    bg = v("cozy/panel")
    border_kw = {}
    text_color = "3D4B5C"

    if is_curr:
        bg = {"hex": "EBF5FB", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/sky-lip"), "strokeW": 1.5}
        text_color = "2B6CB0"
    elif is_nxt:
        bg = {"hex": "EAF8F2", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/mint-lip"), "strokeW": 1.5}
        text_color = "23784F"
    elif is_mx:
        bg = {"hex": "FEF8E7", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/gold"), "strokeW": 1.5}
        text_color = "9C6805"
    elif kind == "muted":
        text_color = "7A8A99"

    lv_str = f"+{lv}" if lv > 0 else "+0"
    return {
        "name": f"Row {lv_str}",
        "layout": "H",
        "gap": 6,
        "pad": [3, 8, 3, 8],
        "h": 27,
        "radius": 6,
        "cross": "CENTER",
        "fill": bg,
        **border_kw,
        "children": [
            ftxt(lv_str, 12, text_color, name="Lv", w=32),
            ftxt(mult, 12, "7A8A99", name="Mult", w=42),
            ftxt(luck, 12, text_color, name="Luck", w=54),
            ftxt(reel, 12, text_color, name="Reel", w=48),
            ftxt(bar, 12, text_color, name="Bar", w=48),
            ftxt(cost_str, 12, text_color, name="Cost", w=64),
            {"name": "StatusBox", "layout": "H", "main": "CENTER", "w": 66, "children": [status_badge(status_txt, kind)]},
        ],
    }


def make_tabbed_modal():
    tabs = {
        "name": "Tabs",
        "layout": "H",
        "gap": 8,
        "fillW": True,
        "children": [
            btn("Ghost", "Step Upgrade", "Btn Tab Step", fillW=True),
            btn("Primary", "Progression Table", "Btn Tab Table", fillW=True),
        ],
    }

    summary_bar = {
        "name": "Summary Bar",
        "layout": "H",
        "gap": 10,
        "pad": [6, 12, 6, 12],
        "radius": 12,
        "fill": v("cozy/sand"),
        "cross": "CENTER",
        "fillW": True,
        "children": [
            img("equipment/CoralRod", 28),
            text("Coral Rod", "Heading", name="ItemName"),
            es.info_pill("+3 Current", "cozy/on-accent", "cozy/sky-lip"),
            text("+16.9% Luck  |  +0.34 Reel Power", "Small", "cozy/subtext", name="Stats"),
        ],
    }

    table_head = {
        "name": "Table Header",
        "layout": "H",
        "gap": 6,
        "pad": [5, 8, 5, 8],
        "radius": 8,
        "fill": v("cozy/sand"),
        "cross": "CENTER",
        "children": [
            ftxt("LEVEL", 11, "7A8A99", name="H_Lv", w=32),
            ftxt("MULT", 11, "7A8A99", name="H_Mult", w=42),
            ftxt("LUCK", 11, "7A8A99", name="H_Luck", w=54),
            ftxt("REEL", 11, "7A8A99", name="H_Reel", w=48),
            ftxt("BAR", 11, "7A8A99", name="H_Bar", w=48),
            ftxt("COST", 11, "7A8A99", name="H_Cost", w=64),
            ftxt("STATUS", 11, "7A8A99", name="H_Status", w=66, align="CENTER"),
        ],
    }

    rows = [table_row_b(*item) for item in PROGRESSION_DATA]
    table_box = {
        "name": "Table Box",
        "layout": "V",
        "gap": 2,
        "fillW": True,
        "pad": 6,
        "radius": 14,
        "fill": v("cozy/panel"),
        **BORDER,
        "children": [table_head] + rows,
    }

    body = [tabs, summary_bar, table_box]
    footer = [
        btn("Ghost", "Close", "Btn Close", fillW=True),
        es.lip_btn(
            "Btn Upgrade Now",
            [
                ftxt("UPGRADE TO +4", 14, "FFFFFF", name="Text"),
                es.cost("ui/status/coin", "4.0k", "FFFFFF", size=18, fs=16),
            ],
            style="gold",
            w=190,
        ),
    ]

    return es.modal("Enhance · Tabbed Table View", body, footer, w=540, x=370, y=80)


# ================================================================ OPTION C: Milestone Ladder Table
def milestone_row(milestone_lbl, luck, reel, bar, status_lbl, kind):
    is_curr = kind == "current"
    is_nxt = kind == "next"
    is_mx = kind == "max"

    bg = v("cozy/panel")
    border_kw = {}
    text_color = "3D4B5C"

    if is_curr:
        bg = {"hex": "EBF5FB", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/sky-lip"), "strokeW": 1.5}
        text_color = "2B6CB0"
    elif is_nxt:
        bg = {"hex": "EAF8F2", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/mint-lip"), "strokeW": 1.5}
        text_color = "23784F"
    elif is_mx:
        bg = {"hex": "FEF8E7", "opacity": 1.0}
        border_kw = {"stroke": v("cozy/gold"), "strokeW": 1.5}
        text_color = "9C6805"
    elif kind == "muted":
        text_color = "7A8A99"

    return {
        "name": "Row " + milestone_lbl,
        "layout": "H",
        "gap": 8,
        "pad": [7, 10, 7, 10],
        "radius": 10,
        "cross": "CENTER",
        "fill": bg,
        **border_kw,
        "children": [
            ftxt(milestone_lbl, 13, text_color, name="Milestone", w=95),
            ftxt(luck, 13, text_color, name="Luck", w=58),
            ftxt(reel, 13, text_color, name="Reel", w=54),
            ftxt(bar, 13, text_color, name="Bar", w=54),
            {"name": "StatusBox", "layout": "H", "main": "CENTER", "w": 68, "children": [status_badge(status_lbl, kind)]},
        ],
    }


def make_milestone_modal():
    body = [
        {
            "name": "Picture",
            "w": 96,
            "h": 96,
            "radius": 20,
            "fill": "FFFFFF",
            **BORDER,
            "layout": "H",
            "main": "CENTER",
            "cross": "CENTER",
            "children": [img("equipment/CoralRod", 80)],
        },
        text("Enhance Coral Rod", "Title", name="Title", align="CENTER", w=440),
        {
            "name": "Levels",
            "layout": "H",
            "gap": 8,
            "cross": "CENTER",
            "children": [
                es.info_pill("+3", "cozy/on-accent", "cozy/sky-lip"),
                text("→", "Title", "cozy/subtext", name="Arrow"),
                es.info_pill("+4", "cozy/on-accent", "cozy/mint-lip"),
            ],
        },
        # Milestone Ladder Table
        {
            "name": "Milestone Ladder Table",
            "layout": "V",
            "gap": 4,
            "pad": 8,
            "radius": 14,
            "fill": v("cozy/sand"),
            "fillW": True,
            "children": [
                {
                    "name": "Milestone Header",
                    "layout": "H",
                    "gap": 8,
                    "pad": [4, 10, 4, 10],
                    "cross": "CENTER",
                    "children": [
                        ftxt("MILESTONE", 11, "7A8A99", name="H_Mile", w=95),
                        ftxt("LUCK", 11, "7A8A99", name="H_Luck", w=58),
                        ftxt("REEL", 11, "7A8A99", name="H_Reel", w=54),
                        ftxt("BAR", 11, "7A8A99", name="H_Bar", w=54),
                        ftxt("STATUS", 11, "7A8A99", name="H_Status", w=68, align="CENTER"),
                    ],
                },
                milestone_row("+0 Base", "+15.0%", "+0.30", "+5.0%", "Base", "muted"),
                milestone_row("+3 Current", "+16.9%", "+0.34", "+5.6%", "CURRENT", "current"),
                milestone_row("+4 Next", "+17.5%", "+0.35", "+5.8%", "NEXT", "next"),
                milestone_row("+10 Peak Max", "+22.2%", "+0.44", "+7.4%", "PEAK", "max"),
            ],
        },
        {
            "name": "Toggle Note",
            "layout": "H",
            "gap": 6,
            "cross": "CENTER",
            "children": [
                ftxt("Tap any row to preview or view full +0…+10 table", 12, "7A8A99", name="Note"),
            ],
        },
        {
            "name": "Materials",
            "layout": "H",
            "gap": 8,
            "cross": "CENTER",
            "opacity": 0.65,
            "children": [
                img("materials/enhance_stone", 24),
                text("x2 Enhance Stone (phase 2: +6 and up)", "Caption", "cozy/subtext", name="Label"),
            ],
        },
    ]

    footer = [
        btn("Ghost", "Cancel", "Btn Cancel", fillW=True),
        es.price_btn("4.0k", style="gold"),
    ]

    return es.modal("Enhance · Milestone Ladder", body, footer, w=500, x=390, y=70)


# ================================================================ DOCUMENTATION BOARDS
def make_boards():
    b_rules = es.board(
        "Enhance Formula & Math Rules",
        "Exact compound stat growth and coin sink formulas used in Aura Fishing economy.",
        [
            {
                "name": "Rules List",
                "layout": "V",
                "gap": 10,
                "children": [
                    text("1. Stat Multiplier: Stat = Base * (1.04 ^ level). Each level gives +4% compound stat boost (+48.0% total at +10).", "Small", "cozy/text"),
                    text("2. Affected Stats: Luck, Reel Power, Catch Bar Size, Resilience (Rod stats scaled simultaneously).", "Small", "cozy/text"),
                    text("3. Upgrade Cost: math.floor(Price * 0.1 * 1.5 ^ level). Costs scale exponentially (1.2k -> 46.1k for Coral Rod).", "Small", "cozy/text"),
                    text("4. Phase 2 Materials: Enhancing from +6 to +10 requires Enhance Stones (x2, x3, x4, x5, x6).", "Small", "cozy/text"),
                    text("5. Safety Guarantee: Enhancing NEVER breaks or downgrades items. It is 100% permanent progression.", "Small", "cozy/text"),
                ],
            }
        ],
        w=640,
    )

    b_ux = es.board(
        "UX Layout Comparison & Recommendations",
        "Trade-offs for the 3 progression table designs to guide player experience and UI implementation.",
        [
            {
                "name": "Comparison List",
                "layout": "V",
                "gap": 10,
                "children": [
                    text("Option A (Dual-Panel Modal, 860x540): Best for PC / Tablet. Immediate visibility of current step and entire +0…+10 ladder side-by-side with zero clicks.", "Small", "cozy/text"),
                    text("Option B (Tabbed Modal, 540x560): Keeps existing compact popup size. Switch tabs to inspect full ladder; includes quick upgrade button directly inside table.", "Small", "cozy/text"),
                    text("Option C (Milestone Ladder, 500x560): Best for Mobile! Shows only the 4 key milestones (+0 Base, +3 Current, +4 Next, +10 Peak) without overwhelming screen space.", "Small", "cozy/text"),
                    text("Recommendation: Implement Option C as standard mobile view, with an expandable table sheet (Option B/A) for deeper inspection.", "Small", "cozy/text"),
                ],
            }
        ],
        w=740,
    )

    return b_rules, b_ux


def build():
    # 3 Screen Blocks
    scr_a = es.screen_block(
        "C16-A · Dual-Panel Modal (Split View)",
        m.screen("Screen C16-A Dual Panel", [make_dual_panel_modal()], dim=True),
        60,
        180,
    )
    scr_b = es.screen_block(
        "C16-B · Tabbed Switcher (540px Modal)",
        m.screen("Screen C16-B Tabbed", [make_tabbed_modal()], dim=True),
        1400,
        180,
    )
    scr_c = es.screen_block(
        "C16-C · Milestone Ladder (Compact 500px)",
        m.screen("Screen C16-C Milestone", [make_milestone_modal()], dim=True),
        2740,
        180,
    )

    b_rules, b_ux = make_boards()
    b_rules.update(x=60, y=980)
    b_ux.update(x=740, y=980)

    sec = {
        "type": "SECTION",
        "name": "C16 · Enhance Progression Table — 3 Design Layouts (Pick One)",
        "fill": "FBF7EF",
        "x": COL_X,
        "y": SEC_Y,
        "w": 4140,
        "h": 1420,
        "children": [
            text(
                "C16 · Enhance Progression Table — 3 UI Layout Variants",
                "Display",
                name="Title",
                x=60,
                y=40,
            ),
            text(
                "Compare 3 UI layouts for adding a progression comparison table to Screen C16 (Enhance popup 3539:29395). Shows Coral Rod +0…+10 stat growth (+4% compound), costs, and milestones. No checkmarks, bullets, or emojis.",
                "Body",
                "cozy/subtext",
                name="Sub",
                x=60,
                y=96,
                w=2200,
            ),
            scr_a,
            scr_b,
            scr_c,
            b_rules,
            b_ux,
        ],
    }

    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(_here, "out")
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "25_enhance_table_variants_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
