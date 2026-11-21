"""Generate 3 Daily Quests & Milestone Chest UI Layout Variants in Figma on page Out Space.
Run: python -I docs/figma/quests_screen_variants.py docs/figma/out
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


def lip_btn(name, label, style="mint", w=110, h=42, fs=16, disabled=False):
    fill_col = v("cozy/sand") if disabled else v(f"cozy/{style}")
    lip_col = v("cozy/track") if disabled else v(f"cozy/{style}-lip")
    text_col = "9AA5B1" if disabled else "FFFFFF"
    return {
        "name": name,
        "layout": "H",
        "w": w,
        "h": h,
        "radius": 14,
        "cross": "CENTER",
        "main": "CENTER",
        "fill": fill_col,
        "stroke": lip_col,
        "strokeSides": {"b": 4},
        "children": [ftxt(label, fs, text_col, name="Label")],
    }


def gem_reward_chip(amount, muted=False):
    col = "7A8A99" if muted else "8C6FD6"
    bg = v("cozy/track") if muted else v("cozy/sand")
    return {
        "name": "RewardChip",
        "layout": "H",
        "gap": 6,
        "pad": [4, 12, 4, 8],
        "radius": 999,
        "cross": "CENTER",
        "fill": bg,
        "children": [
            img("ui/status/pearl", 18),
            ftxt(f"+{amount} Gems", 13, col, name="Amount"),
        ],
    }


def progress_bar(current, target, fill_color="cozy/mint", w=180, h=14):
    ratio = min(1.0, current / target) if target > 0 else 0
    fill_w = max(10, int(w * ratio))
    return {
        "name": "ProgressTrack",
        "w": w,
        "h": h,
        "radius": 999,
        "fill": v("cozy/track"),
        "children": [
            {
                "name": "Fill",
                "w": fill_w,
                "h": h,
                "radius": 999,
                "fill": v(fill_color),
            }
        ],
    }


# ==============================================================================
# VARIANT 1: Classic Cozy Deck (760x610)
# ==============================================================================
def build_variant_1():
    # Milestone Track: 3 Chests (1 claimed, 1 ready, 1 locked)
    milestone_track = {
        "name": "MilestoneTrack",
        "layout": "H",
        "fillW": True,
        "pad": [10, 16, 10, 16],
        "gap": 16,
        "radius": 16,
        "cross": "CENTER",
        "main": "SPACE_BETWEEN",
        "fill": v("cozy/sand"),
        "children": [
            {
                "name": "LeftInfo",
                "layout": "V",
                "gap": 2,
                "children": [
                    text("Daily Chest Progress", "Heading", "cozy/text", name="Title"),
                    text("2 / 3 Quests Completed", "Caption", "cozy/subtext", name="Sub"),
                ],
            },
            {
                "name": "MilestoneNodes",
                "layout": "H",
                "gap": 12,
                "cross": "CENTER",
                "children": [
                    # Node 1: 1/3 Claimed
                    {
                        "name": "Node1",
                        "layout": "H",
                        "gap": 6,
                        "pad": [4, 10, 4, 8],
                        "radius": 999,
                        "cross": "CENTER",
                        "fill": v("cozy/panel"),
                        **BORDER,
                        "children": [
                            img("ui/status/treasure_chest", 20),
                            text("1/3", "Caption", "cozy/mint-lip", name="Step"),
                            text("CLAIMED", "Caption", "cozy/subtext", name="Tag"),
                        ],
                    },
                    # Node 2: 2/3 Ready to Claim
                    {
                        "name": "Node2",
                        "layout": "H",
                        "gap": 6,
                        "pad": [4, 10, 4, 8],
                        "radius": 999,
                        "cross": "CENTER",
                        "fill": v("cozy/panel"),
                        "stroke": v("cozy/mint"),
                        "strokeW": 2,
                        "children": [
                            img("ui/status/treasure_chest", 20),
                            text("2/3", "Caption", "cozy/mint-lip", name="Step"),
                            lip_btn("BtnOpenSilver", "OPEN", "mint", w=62, h=28, fs=12),
                        ],
                    },
                    # Node 3: 3/3 Gold Mega Chest (Locked)
                    {
                        "name": "Node3",
                        "layout": "H",
                        "gap": 6,
                        "pad": [4, 10, 4, 8],
                        "radius": 999,
                        "cross": "CENTER",
                        "fill": v("cozy/track"),
                        "children": [
                            vec("icon_lock", "7A8A99", 14),
                            text("3/3 Gold Chest", "Caption", "cozy/subtext", name="Step"),
                        ],
                    },
                ],
            },
        ],
    }

    # 3 Quest Cards
    # Card 1: In Progress
    card1 = {
        "name": "QuestCard1_InProgress",
        "layout": "H",
        "fillW": True,
        "pad": [12, 16, 12, 16],
        "gap": 16,
        "radius": 16,
        "cross": "CENTER",
        "fill": v("cozy/panel"),
        **BORDER,
        "children": [
            img("ui/icons/daily_login", 48),
            {
                "name": "Info",
                "layout": "V",
                "gap": 4,
                "fillW": True,
                "children": [
                    text("Catch 10 Fish in Shallows", "Heading", "cozy/text", name="Title"),
                    text("Any fish caught between 0-20m depth", "Caption", "cozy/subtext", name="Sub"),
                    {
                        "name": "ProgressRow",
                        "layout": "H",
                        "gap": 10,
                        "cross": "CENTER",
                        "children": [
                            progress_bar(7, 10, "cozy/mint", w=160, h=10),
                            text("7 / 10", "Caption", "cozy/mint-lip", name="Val"),
                        ],
                    },
                ],
            },
            gem_reward_chip(15),
            {
                "name": "StatusPill",
                "layout": "H",
                "pad": [6, 14, 6, 14],
                "radius": 999,
                "cross": "CENTER",
                "fill": v("cozy/sand"),
                "children": [text("IN PROGRESS", "Caption", "cozy/subtext", name="Tag")],
            },
        ],
    }

    # Card 2: Ready to Claim
    card2 = {
        "name": "QuestCard2_Claimable",
        "layout": "H",
        "fillW": True,
        "pad": [12, 16, 12, 16],
        "gap": 16,
        "radius": 16,
        "cross": "CENTER",
        "fill": v("cozy/panel"),
        "stroke": v("cozy/gold"),
        "strokeW": 2,
        "children": [
            img("fish/AncientCoelacanth", 48),
            {
                "name": "Info",
                "layout": "V",
                "gap": 4,
                "fillW": True,
                "children": [
                    text("Reel in 3 Rare+ Fish", "Heading", "cozy/text", name="Title"),
                    text("Rare, Epic, or Legendary catches count", "Caption", "cozy/subtext", name="Sub"),
                    {
                        "name": "ProgressRow",
                        "layout": "H",
                        "gap": 10,
                        "cross": "CENTER",
                        "children": [
                            progress_bar(3, 3, "cozy/gold", w=160, h=10),
                            text("3 / 3 COMPLETED", "Caption", "cozy/gold-lip", name="Val"),
                        ],
                    },
                ],
            },
            gem_reward_chip(25),
            lip_btn("BtnClaim", "CLAIM", "mint", w=110, h=42, fs=16),
        ],
    }

    # Card 3: Claimed
    card3 = {
        "name": "QuestCard3_Claimed",
        "layout": "H",
        "fillW": True,
        "pad": [12, 16, 12, 16],
        "gap": 16,
        "radius": 16,
        "cross": "CENTER",
        "fill": v("cozy/panel"),
        "stroke": v("cozy/track"),
        "strokeW": 1,
        "opacity": 0.75,
        "children": [
            img("ui/icons/bag", 48),
            {
                "name": "Info",
                "layout": "V",
                "gap": 4,
                "fillW": True,
                "children": [
                    text("Earn 5,000 Coins", "Heading", "cozy/subtext", name="Title"),
                    text("Sell any catches to Fish Merchant", "Caption", "cozy/subtext", name="Sub"),
                    {
                        "name": "ProgressRow",
                        "layout": "H",
                        "gap": 10,
                        "cross": "CENTER",
                        "children": [
                            progress_bar(5000, 5000, "cozy/track", w=160, h=10),
                            text("5,000 / 5,000", "Caption", "cozy/subtext", name="Val"),
                        ],
                    },
                ],
            },
            gem_reward_chip(20, muted=True),
            {
                "name": "StatusPill",
                "layout": "H",
                "pad": [6, 16, 6, 16],
                "radius": 999,
                "cross": "CENTER",
                "fill": v("cozy/track"),
                "children": [text("CLAIMED", "Caption", "cozy/subtext", name="Tag")],
            },
        ],
    }

    # Header with Timer & Wallet
    head = {
        "name": "Header",
        "layout": "H",
        "fillW": True,
        "main": "SPACE_BETWEEN",
        "cross": "CENTER",
        "children": [
            {
                "name": "TitleGroup",
                "layout": "H",
                "gap": 12,
                "cross": "CENTER",
                "children": [
                    text("Daily Quests", "Title", name="Title"),
                    {
                        "name": "TimerPill",
                        "layout": "H",
                        "gap": 6,
                        "pad": [4, 10, 4, 8],
                        "radius": 999,
                        "cross": "CENTER",
                        "fill": v("cozy/sand"),
                        "children": [
                            vec("icon_timer", "7A8A99", 14),
                            text("Resets in 14h 22m", "Caption", "cozy/subtext", name="Timer"),
                        ],
                    },
                ],
            },
            {
                "name": "Right",
                "layout": "H",
                "gap": 10,
                "cross": "CENTER",
                "children": [chip("Gems", "381"), btn("Danger", "X", "Btn Close")],
            },
        ],
    }

    body = [milestone_track, card1, card2, card3]
    return {
        "name": "Window Daily Quests (Option 1)",
        "layout": "V",
        "w": 760,
        "h": 610,
        "pad": 20,
        "gap": 12,
        "radius": 24,
        "fill": v("cozy/panel"),
        **BORDER,
        "effects": SOFT,
        "children": [head, *body],
    }


# ==============================================================================
# VARIANT 2: Split Journal & Grand Chest (840x610)
# ==============================================================================
def build_variant_2():
    head = {
        "name": "Header",
        "layout": "H",
        "fillW": True,
        "main": "SPACE_BETWEEN",
        "cross": "CENTER",
        "children": [
            {
                "name": "TitleGroup",
                "layout": "H",
                "gap": 12,
                "cross": "CENTER",
                "children": [
                    text("Quest Journal", "Title", name="Title"),
                    {
                        "name": "TimerPill",
                        "layout": "H",
                        "gap": 6,
                        "pad": [4, 10, 4, 8],
                        "radius": 999,
                        "cross": "CENTER",
                        "fill": v("cozy/sand"),
                        "children": [
                            vec("icon_timer", "7A8A99", 14),
                            text("Resets in 14h 22m", "Caption", "cozy/subtext", name="Timer"),
                        ],
                    },
                ],
            },
            {
                "name": "Right",
                "layout": "H",
                "gap": 10,
                "cross": "CENTER",
                "children": [chip("Gems", "381"), btn("Danger", "X", "Btn Close")],
            },
        ],
    }

    # Left Column: Quest Cards
    left_rows = [
        # Quest 1
        {
            "name": "Row1",
            "layout": "V",
            "gap": 8,
            "pad": 12,
            "radius": 16,
            "fill": v("cozy/sand"),
            "children": [
                {
                    "name": "Top",
                    "layout": "H",
                    "main": "SPACE_BETWEEN",
                    "cross": "CENTER",
                    "fillW": True,
                    "children": [
                        text("Catch 10 Fish in Shallows", "Heading", "cozy/text", name="Title"),
                        gem_reward_chip(15),
                    ],
                },
                {
                    "name": "Bottom",
                    "layout": "H",
                    "main": "SPACE_BETWEEN",
                    "cross": "CENTER",
                    "fillW": True,
                    "children": [
                        progress_bar(7, 10, "cozy/mint", w=240, h=10),
                        text("7 / 10", "Caption", "cozy/mint-lip", name="Count"),
                    ],
                },
            ],
        },
        # Quest 2
        {
            "name": "Row2",
            "layout": "V",
            "gap": 8,
            "pad": 12,
            "radius": 16,
            "fill": v("cozy/sand"),
            "stroke": v("cozy/gold"),
            "strokeW": 2,
            "children": [
                {
                    "name": "Top",
                    "layout": "H",
                    "main": "SPACE_BETWEEN",
                    "cross": "CENTER",
                    "fillW": True,
                    "children": [
                        text("Reel in 3 Rare+ Fish", "Heading", "cozy/text", name="Title"),
                        lip_btn("BtnClaimRow2", "CLAIM", "mint", w=88, h=32, fs=13),
                    ],
                },
                {
                    "name": "Bottom",
                    "layout": "H",
                    "main": "SPACE_BETWEEN",
                    "cross": "CENTER",
                    "fillW": True,
                    "children": [
                        progress_bar(3, 3, "cozy/gold", w=240, h=10),
                        text("COMPLETED (+25 Gems)", "Caption", "cozy/gold-lip", name="Count"),
                    ],
                },
            ],
        },
        # Quest 3
        {
            "name": "Row3",
            "layout": "V",
            "gap": 8,
            "pad": 12,
            "radius": 16,
            "fill": v("cozy/sand"),
            "opacity": 0.7,
            "children": [
                {
                    "name": "Top",
                    "layout": "H",
                    "main": "SPACE_BETWEEN",
                    "cross": "CENTER",
                    "fillW": True,
                    "children": [
                        text("Earn 5,000 Coins", "Heading", "cozy/subtext", name="Title"),
                        text("CLAIMED", "Caption", "cozy/subtext", name="Tag"),
                    ],
                },
                {
                    "name": "Bottom",
                    "layout": "H",
                    "main": "SPACE_BETWEEN",
                    "cross": "CENTER",
                    "fillW": True,
                    "children": [
                        progress_bar(5000, 5000, "cozy/track", w=240, h=10),
                        text("5,000 / 5,000", "Caption", "cozy/subtext", name="Count"),
                    ],
                },
            ],
        },
    ]

    left_col = {
        "name": "LeftCol",
        "layout": "V",
        "w": 490,
        "gap": 10,
        "children": left_rows,
    }

    # Right Column: Big Grand Chest Showcase
    right_col = {
        "name": "RightCol_GrandChest",
        "layout": "V",
        "w": 290,
        "h": 500,
        "pad": 16,
        "gap": 12,
        "radius": 20,
        "cross": "CENTER",
        "fill": v("cozy/sand"),
        **BORDER,
        "children": [
            text("Today's Mega Chest", "Heading", "cozy/text", name="Title"),
            img("ui/status/treasure_chest", 100),
            {
                "name": "ProgressRing",
                "layout": "V",
                "gap": 4,
                "cross": "CENTER",
                "children": [
                    text("2 / 3 Quests Done", "Title", "cozy/mint-lip", name="PCount"),
                    text("1 more quest to unlock!", "Caption", "cozy/subtext", name="Hint"),
                ],
            },
            {
                "name": "RewardsPreview",
                "layout": "V",
                "gap": 6,
                "pad": 10,
                "fillW": True,
                "radius": 12,
                "fill": v("cozy/panel"),
                "children": [
                    text("Chest Contains:", "Caption", "cozy/subtext", name="Lbl"),
                    text("+50 Gems", "Heading", "cozy/gem-lip", name="R1"),
                    text("+500 Pearls", "Heading", "cozy/mint-lip", name="R2"),
                    text("x5 Golden Bait", "Heading", "cozy/gold-lip", name="R3"),
                ],
            },
            lip_btn("BtnOpenMega", "1 MORE NEEDED", "sand", w=250, h=46, fs=14, disabled=True),
        ],
    }

    split_body = {
        "name": "SplitBody",
        "layout": "H",
        "fillW": True,
        "gap": 16,
        "children": [left_col, right_col],
    }

    return {
        "name": "Window Quest Journal (Option 2)",
        "layout": "V",
        "w": 840,
        "h": 610,
        "pad": 20,
        "gap": 14,
        "radius": 24,
        "fill": v("cozy/panel"),
        **BORDER,
        "effects": SOFT,
        "children": [head, split_body],
    }


# ==============================================================================
# VARIANT 3: Quest Deck + Claim Celebration Modal (Full User Flow Preview)
# ==============================================================================
def build_variant_3():
    # Reward Claimed Celebration Modal (520x390)
    celebration_modal = {
        "name": "Modal Quest Reward Claimed",
        "layout": "V",
        "w": 520,
        "radius": 36,
        "clip": True,
        "fill": v("cozy/panel"),
        **BORDER,
        "effects": SOFT,
        "children": [
            {
                "name": "Body",
                "layout": "V",
                "gap": 10,
                "pad": [34, 40, 26, 40],
                "fillW": True,
                "cross": "CENTER",
                "children": [
                    img("ui/status/treasure_chest", 110),
                    text("Quest Completed!", "Title", "cozy/text", name="Title"),
                    text("Reel in 3 Rare+ Fish", "Body", "cozy/subtext", name="Sub"),
                    {
                        "name": "RewardRow",
                        "layout": "H",
                        "gap": 10,
                        "cross": "CENTER",
                        "pad": [8, 20, 8, 20],
                        "radius": 999,
                        "fill": v("cozy/sand"),
                        "children": [
                            img("ui/status/pearl", 32),
                            ftxt("+25 Gems", 36, "8C6FD6", name="Amount"),
                        ],
                    },
                ],
            },
            {
                "name": "Footer",
                "layout": "H",
                "pad": [16, 32, 20, 32],
                "fillW": True,
                "main": "CENTER",
                "fill": v("cozy/sand"),
                "children": [
                    lip_btn("BtnAwesome", "AWESOME!", "mint", w=354, h=54, fs=22),
                ],
            },
        ],
    }

    # Holder showing both the deck and the modal side by side
    return {
        "name": "Flow Preview (Option 3)",
        "layout": "H",
        "gap": 24,
        "cross": "CENTER",
        "children": [
            build_variant_1(),
            celebration_modal,
        ],
    }


# ==============================================================================
# MASTER BUILD FUNCTION
# ==============================================================================
def build():
    v1 = build_variant_1()
    v2 = build_variant_2()
    v3 = build_variant_3()

    # Wrap in Variant Cards for presentation
    p1 = es.board(
        "Option 1: Classic Cozy Deck",
        "Standard 760x610 window with top milestone track and 3 rich quest cards. Clean, native, matches Fishdex and Shop.",
        [v1],
        w=820,
    )
    p2 = es.board(
        "Option 2: Adventure Journal (Split Layout)",
        "840x610 window with quest tasks on the left and a grand daily chest showcase on the right. Highlights daily retention.",
        [v2],
        w=900,
    )
    p3 = es.board(
        "Option 3: Full Flow Preview (Deck + Celebration Modal)",
        "Shows the quest window alongside the Quest Reward Claimed celebration popup when the player presses CLAIM.",
        [v3],
        w=1420,
    )

    p1.update(x=60, y=160)
    p2.update(x=920, y=160)
    p3.update(x=60, y=860)

    sec = {
        "type": "SECTION",
        "name": "C7 · Daily Quests — 3 Design Layouts (Pick One)",
        "fill": "FBF7EF",
        "x": 25000,
        "y": 2000,
        "children": [
            text("C7 · Daily Quests — 3 UI Layout Variants to Choose", "Display", name="Title", x=60, y=40),
            text(
                "Compare 3 UX layouts for the Daily Quests & Milestone Chest system (C7). Ready for player feedback. No checkmarks, bullets, or emojis used.",
                "Body",
                "cozy/subtext",
                name="Sub",
                x=60,
                y=96,
                w=1800,
            ),
            p1,
            p2,
            p3,
        ],
    }
    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(_here, "out")
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "24_daily_quests_variants_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
