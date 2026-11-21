"""Build 8 Gacha Screen Concepts inspired by Alchemy Stars & modern gacha UIs.
Placed in Section: Gacha Redesign · 8 Concepts (Alchemy Stars Style) at x=33000, y=0.
"""
import json
import os
import subprocess
import sys
import tempfile

ROOT = r"d:\Roblox Project\Aura Fishing"
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")
PAGE_ID = "3465:14993"

W, H = 1440, 900

def hex_col(h):
    h = h.replace("#", "")
    return {"r": int(h[0:2], 16) / 255, "g": int(h[2:4], 16) / 255, "b": int(h[4:6], 16) / 255}

def paint_solid(h, opacity=1.0):
    return {"type": "SOLID", "color": hex_col(h), "opacity": opacity}

def paint_grad(colors, angle=90):
    stops = []
    for i, c in enumerate(colors):
        pos = i / (len(colors) - 1) if len(colors) > 1 else 0
        stops.append({"position": pos, "color": {**hex_col(c), "a": 1.0}})
    return {
        "type": "GRADIENT_LINEAR",
        "gradientTransform": [[0, 1, 0], [-1, 0, 1]] if angle == 90 else [[1, 0, 0], [0, 1, 0]],
        "gradientStops": stops
    }

def txt(characters, size=16, weight="Regular", color="FFFFFF", name="Text", **kw):
    style_map = {"Regular": 400, "Medium": 500, "SemiBold": 600, "Bold": 700, "ExtraBold": 800, "Black": 900}
    w_num = style_map.get(weight, 400)
    font_fam = "Fredoka One" if w_num >= 700 and size >= 20 else "Nunito"
    d = {
        "type": "TEXT",
        "name": name,
        "text": characters,
        "font": {"family": font_fam, "style": weight if font_fam == "Nunito" else "Regular"},
        "fontSize": size,
        "fill": color,
    }
    d.update(kw)
    return d

def img_slot(path, w, h, x=None, y=None, name=None, **kw):
    d = {
        "type": "RECT",
        "name": name or f"Img {path}",
        "w": w,
        "h": h,
        "fill": "FFFFFF",
    }
    if x is not None: d["x"] = x
    if y is not None: d["y"] = y
    d.update(kw)
    return d

def top_bar():
    return {
        "name": "TopBar [safe]",
        "w": W,
        "h": 58,
        "x": 0,
        "y": 0,
        "children": [
            # Back Button
            {
                "type": "FRAME",
                "name": "Btn Back",
                "x": 48,
                "y": 14,
                "w": 96,
                "h": 40,
                "radius": 12,
                "fill": "FFF8EC",
                "stroke": "E6DCCB",
                "strokeW": 2,
                "children": [
                    txt("BACK", size=14, weight="Bold", color="3D4B5C", x=28, y=10)
                ]
            },
            # Currencies (Gems, Star Tokens, Pearls)
            {
                "type": "FRAME",
                "name": "Currencies",
                "x": W - 48 - 380,
                "y": 14,
                "w": 380,
                "h": 40,
                "layout": "H",
                "gap": 12,
                "cross": "CENTER",
                "children": [
                    # Gems Chip
                    {
                        "type": "FRAME",
                        "name": "Chip Gems",
                        "w": 115,
                        "h": 36,
                        "radius": 999,
                        "fill": "1A2536",
                        "stroke": "4A6588",
                        "strokeW": 1.5,
                        "children": [
                            img_slot("ui/status/gem", 22, 22, x=8, y=7),
                            txt("2,350", size=15, weight="Bold", color="FFFFFF", x=36, y=8)
                        ]
                    },
                    # Star Tokens Chip
                    {
                        "type": "FRAME",
                        "name": "Chip StarTokens",
                        "w": 115,
                        "h": 36,
                        "radius": 999,
                        "fill": "1A2536",
                        "stroke": "FFA94D",
                        "strokeW": 1.5,
                        "children": [
                            img_slot("ui/status/star_token", 22, 22, x=8, y=7),
                            txt("12", size=15, weight="Bold", color="FFA94D", x=36, y=8)
                        ]
                    },
                    # Pearls Chip
                    {
                        "type": "FRAME",
                        "name": "Chip Pearls",
                        "w": 115,
                        "h": 36,
                        "radius": 999,
                        "fill": "1A2536",
                        "stroke": "7FD3B0",
                        "strokeW": 1.5,
                        "children": [
                            img_slot("ui/status/pearl", 22, 22, x=8, y=7),
                            txt("850", size=15, weight="Bold", color="7FD3B0", x=36, y=8)
                        ]
                    }
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# CONCEPT 1: Alchemy Stars Grand Summoner (Direct Reference)
# ---------------------------------------------------------------------------
def concept_1():
    banner_tabs = [
        {"title": "NEON TIDE", "sub": "RATE UP 2.0%", "active": True},
        {"title": "DRAGON EMPEROR", "sub": "FEATURED 5*", "active": False},
        {"title": "CELESTIAL REEL", "sub": "STANDARD POOL", "active": False},
        {"title": "NOVICE ALTAR", "sub": "GUARANTEED 5*", "active": False},
    ]
    tabs_kids = []
    for i, t in enumerate(banner_tabs):
        border_col = "5AA9F0" if t["active"] else "2C3B4E"
        bg_col = "1E2D40" if t["active"] else "131D2A"
        tabs_kids.append({
            "type": "FRAME",
            "name": f"Tab {t['title']}",
            "w": 180,
            "h": 85,
            "radius": 14,
            "fill": bg_col,
            "stroke": border_col,
            "strokeW": 2 if t["active"] else 1,
            "children": [
                txt(t["title"], size=16, weight="Bold", color="FFFFFF" if t["active"] else "9AA5B1", x=14, y=18),
                txt(t["sub"], size=12, weight="Bold", color="7FD3B0" if t["active"] else "627D98", x=14, y=44)
            ]
        })

    return {
        "type": "FRAME",
        "name": "Concept 01 · Alchemy Stars Grand Summoner",
        "w": W,
        "h": H,
        "radius": 24,
        "clip": True,
        "fill": {"grad": ["0D1520", "152336"], "angle": 90},
        "stroke": "3D4B5C",
        "strokeW": 2,
        "children": [
            top_bar(),
            # Left Vertical Banner Tabs
            {
                "type": "FRAME",
                "name": "Banner Tabs Left Rail",
                "x": 48,
                "y": 90,
                "w": 180,
                "h": 400,
                "layout": "V",
                "gap": 12,
                "children": tabs_kids
            },
            # Center Hero Stage (Large Aura Splash Art)
            {
                "type": "FRAME",
                "name": "Hero Stage",
                "x": 260,
                "y": 70,
                "w": 860,
                "h": 660,
                "children": [
                    img_slot("auras_Art/CelestialLeviathan", 640, 640, x=110, y=10),
                    # Element Pill
                    {
                        "type": "FRAME",
                        "name": "Badge Element",
                        "x": 310,
                        "y": 480,
                        "w": 100,
                        "h": 32,
                        "radius": 999,
                        "fill": "5AA9F0",
                        "children": [
                            txt("TIDAL 5★", size=13, weight="ExtraBold", color="FFFFFF", x=18, y=7)
                        ]
                    },
                    # Aura Name
                    txt("CELESTIAL LEVIATHAN", size=38, weight="Bold", color="FFFFFF", x=310, y=520),
                    txt("Deep Ocean Emperor Aura · Grants +50% Luck & Mega Bite VFX", size=16, weight="Medium", color="A9DCF7", x=310, y=570),
                ]
            },
            # Bottom Left: Pity Progress & Utility Buttons
            {
                "type": "FRAME",
                "name": "Bottom Left Info",
                "x": 260,
                "y": 760,
                "w": 500,
                "h": 90,
                "children": [
                    txt("Standard Altar · Pity: 38 / 50 pulls to guaranteed Mythic", size=14, weight="Bold", color="A8DCD8", x=0, y=0),
                    # Pity Bar
                    {
                        "type": "FRAME",
                        "name": "Pity Track",
                        "x": 0,
                        "y": 24,
                        "w": 380,
                        "h": 8,
                        "radius": 999,
                        "fill": "1A2536",
                        "children": [
                            {"type": "RECT", "name": "Pity Fill", "w": 288, "h": 8, "radius": 999, "fill": "7FD3B0"}
                        ]
                    },
                    # Utility Pills
                    {
                        "type": "FRAME",
                        "name": "Btn Rates",
                        "x": 0,
                        "y": 46,
                        "w": 140,
                        "h": 36,
                        "radius": 18,
                        "fill": "1E2D40",
                        "stroke": "3D4B5C",
                        "strokeW": 1.5,
                        "children": [
                            txt("Summon Rates", size=13, weight="Bold", color="E6DCCB", x=22, y=8)
                        ]
                    },
                    {
                        "type": "FRAME",
                        "name": "Btn Exchange Shop",
                        "x": 154,
                        "y": 46,
                        "w": 170,
                        "h": 36,
                        "radius": 18,
                        "fill": "1E2D40",
                        "stroke": "FFA94D",
                        "strokeW": 1.5,
                        "children": [
                            txt("Star Token Shop", size=13, weight="Bold", color="FFA94D", x=26, y=8)
                        ]
                    }
                ]
            },
            # Bottom Right: Dual Roll Buttons
            {
                "type": "FRAME",
                "name": "Bottom Right CTAs",
                "x": W - 48 - 460,
                "y": 750,
                "w": 460,
                "h": 100,
                "children": [
                    # Roll x1
                    {
                        "type": "FRAME",
                        "name": "Btn Roll x1",
                        "x": 0,
                        "y": 14,
                        "w": 190,
                        "h": 72,
                        "radius": 20,
                        "fill": "1E2D40",
                        "stroke": "5AA9F0",
                        "strokeW": 2,
                        "children": [
                            txt("SUMMON x1", size=17, weight="Bold", color="FFFFFF", x=42, y=14),
                            img_slot("ui/status/gem", 20, 20, x=55, y=42),
                            txt("100 Gems", size=14, weight="Bold", color="A9DCF7", x=82, y=42)
                        ]
                    },
                    # Roll x10 (Primary Glowing Golden Lip Button)
                    {
                        "type": "FRAME",
                        "name": "Btn Roll x10",
                        "x": 210,
                        "y": 8,
                        "w": 250,
                        "h": 78,
                        "radius": 22,
                        "fill": "F2B544",
                        "stroke": "C98B1E",
                        "strokeW": 3,
                        "children": [
                            # Save Badge
                            {
                                "type": "FRAME",
                                "name": "Badge Discount",
                                "x": 120,
                                "y": -12,
                                "w": 115,
                                "h": 22,
                                "radius": 999,
                                "fill": "FF7A7A",
                                "children": [
                                    txt("SAVE 10% + 10★", size=11, weight="ExtraBold", color="FFFFFF", x=12, y=4)
                                ]
                            },
                            txt("SUMMON x10", size=20, weight="Bold", color="FFFFFF", x=62, y=14),
                            img_slot("ui/status/gem", 22, 22, x=70, y=44),
                            txt("900 Gems", size=16, weight="ExtraBold", color="FFFFFF", x=98, y=44)
                        ]
                    }
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# CONCEPT 2: Honkai Star Rail Cosmic Warp Pedestal
# ---------------------------------------------------------------------------
def concept_2():
    return {
        "type": "FRAME",
        "name": "Concept 02 · Star Rail Cosmic Warp Pedestal",
        "w": W,
        "h": H,
        "radius": 24,
        "clip": True,
        "fill": {"grad": ["090E1A", "182638"], "angle": 90},
        "stroke": "3D4B5C",
        "strokeW": 2,
        "children": [
            top_bar(),
            # Center Glass Warp Window
            {
                "type": "FRAME",
                "name": "Warp Pedestal Stage",
                "x": 100,
                "y": 80,
                "w": 1240,
                "h": 650,
                "radius": 28,
                "fill": "0E1724",
                "stroke": "4A6588",
                "strokeW": 2,
                "children": [
                    # Top Horizontal Tabs
                    {
                        "type": "FRAME",
                        "name": "Warp Tabs",
                        "x": 360,
                        "y": 24,
                        "w": 520,
                        "h": 46,
                        "radius": 999,
                        "fill": "1A2536",
                        "layout": "H",
                        "gap": 8,
                        "pad": 4,
                        "children": [
                            {"type": "FRAME", "w": 165, "h": 38, "radius": 999, "fill": "5AA9F0", "children": [txt("FEATURED WARP", size=13, weight="Bold", color="FFFFFF", x=24, y=10)]},
                            {"type": "FRAME", "w": 165, "h": 38, "radius": 999, "children": [txt("STANDARD WARP", size=13, weight="Bold", color="9AA5B1", x=24, y=10)]},
                            {"type": "FRAME", "w": 165, "h": 38, "radius": 999, "children": [txt("ROD & BAIT WARP", size=13, weight="Bold", color="9AA5B1", x=20, y=10)]},
                        ]
                    },
                    # Featured Aura Artwork
                    img_slot("auras_Art/DragonEmperor", 520, 520, x=360, y=80),
                    # Floating Stats Pill
                    {
                        "type": "FRAME",
                        "name": "Pill Stats",
                        "x": 120,
                        "y": 260,
                        "w": 240,
                        "h": 160,
                        "radius": 18,
                        "fill": "142130",
                        "stroke": "F2B544",
                        "strokeW": 1.5,
                        "children": [
                            txt("FEATURED 5★ AURA", size=12, weight="Bold", color="F2B544", x=18, y=16),
                            txt("Dragon Emperor", size=22, weight="Bold", color="FFFFFF", x=18, y=36),
                            txt("+45% Luck Boost", size=14, weight="Bold", color="7FD3B0", x=18, y=74),
                            txt("+25% Auto Reel Power", size=14, weight="Bold", color="7FD3B0", x=18, y=98),
                            txt("Golden Dragon VFX Trails", size=13, weight="Medium", color="E6DCCB", x=18, y=122),
                        ]
                    },
                    # Right Side Pity Chamber
                    {
                        "type": "FRAME",
                        "name": "Pity Chamber",
                        "x": 900,
                        "y": 260,
                        "w": 220,
                        "h": 160,
                        "radius": 18,
                        "fill": "142130",
                        "stroke": "4A6588",
                        "strokeW": 1.5,
                        "children": [
                            txt("WARP PITY METER", size=12, weight="Bold", color="9AA5B1", x=18, y=16),
                            txt("42 / 50", size=32, weight="Bold", color="FFA94D", x=18, y=36),
                            txt("8 pulls to guaranteed 5★", size=13, weight="Medium", color="E6DCCB", x=18, y=82),
                            txt("Base 5★ Rate: 2.0%", size=12, weight="Bold", color="A9DCF7", x=18, y=118),
                        ]
                    }
                ]
            },
            # Bottom Integrated Bar
            {
                "type": "FRAME",
                "name": "Bottom Bar",
                "x": 100,
                "y": 760,
                "w": 1240,
                "h": 85,
                "radius": 22,
                "fill": "101928",
                "stroke": "3D4B5C",
                "strokeW": 1.5,
                "children": [
                    txt("Warp Details & Rates", size=14, weight="Bold", color="E6DCCB", x=40, y=32),
                    txt("Exchange Shop", size=14, weight="Bold", color="FFA94D", x=230, y=32),
                    # Dual Buttons on Right
                    {
                        "type": "FRAME",
                        "name": "Btn 1 Pull",
                        "x": 780,
                        "y": 14,
                        "w": 200,
                        "h": 58,
                        "radius": 16,
                        "fill": "1E2D40",
                        "stroke": "5AA9F0",
                        "strokeW": 2,
                        "children": [
                            txt("Warp x1 (100 Gems)", size=15, weight="Bold", color="FFFFFF", x=24, y=18)
                        ]
                    },
                    {
                        "type": "FRAME",
                        "name": "Btn 10 Pulls",
                        "x": 1000,
                        "y": 14,
                        "w": 215,
                        "h": 58,
                        "radius": 16,
                        "fill": "F2B544",
                        "stroke": "C98B1E",
                        "strokeW": 2,
                        "children": [
                            txt("Warp x10 (900 Gems)", size=16, weight="ExtraBold", color="FFFFFF", x=24, y=18)
                        ]
                    }
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# CONCEPT 3: Vintage Cozy Lake Storybook Atelier (Reverse 1999)
# ---------------------------------------------------------------------------
def concept_3():
    return {
        "type": "FRAME",
        "name": "Concept 03 · Vintage Cozy Atelier (Reverse 1999)",
        "w": W,
        "h": H,
        "radius": 24,
        "clip": True,
        "fill": "2A211B",
        "stroke": "E6DCCB",
        "strokeW": 2,
        "children": [
            top_bar(),
            # Storybook Left Page (Parchment Card)
            {
                "type": "FRAME",
                "name": "Storybook Left Page",
                "x": 80,
                "y": 90,
                "w": 720,
                "h": 740,
                "radius": 24,
                "fill": "FFF8EC",
                "stroke": "E6DCCB",
                "strokeW": 3,
                "children": [
                    txt("CHAPTER IV · THE SACRED REEL", size=14, weight="Bold", color="7A8A99", x=40, y=36),
                    txt("Lotus Naga of the Ancient Depths", size=32, weight="Bold", color="3D4B5C", x=40, y=64),
                    # Illustration Box
                    {
                        "type": "FRAME",
                        "name": "Illustration Box",
                        "x": 40,
                        "y": 120,
                        "w": 640,
                        "h": 460,
                        "radius": 16,
                        "fill": "D3ECFA",
                        "stroke": "A9DCF7",
                        "strokeW": 2,
                        "children": [
                            img_slot("auras_Art/LotusNaga", 440, 440, x=100, y=10)
                        ]
                    },
                    txt("Lore Snippet: In the deepest springs of Cozy Lake, the Lotus Naga stirs...", size=14, weight="Medium", color="7A8A99", x=40, y=600),
                    txt("Drop Rate: 2.0% Mythic | Guaranteed in 50 casts", size=15, weight="Bold", color="4FAF8A", x=40, y=640)
                ]
            },
            # Storybook Right Page (Controls & Dial)
            {
                "type": "FRAME",
                "name": "Storybook Right Page",
                "x": 830,
                "y": 90,
                "w": 530,
                "h": 740,
                "radius": 24,
                "fill": "F3E9D8",
                "stroke": "E6DCCB",
                "strokeW": 3,
                "children": [
                    txt("OFFERING MECHANISM", size=16, weight="Bold", color="3D4B5C", x=40, y=40),
                    # Vintage Dial Frame
                    {
                        "type": "FRAME",
                        "name": "Dial Frame",
                        "x": 40,
                        "y": 80,
                        "w": 450,
                        "h": 320,
                        "radius": 20,
                        "fill": "FFF8EC",
                        "stroke": "E6DCCB",
                        "strokeW": 2,
                        "children": [
                            txt("SACRED PITY DIAL", size=14, weight="Bold", color="7A8A99", x=30, y=24),
                            txt("38 / 50", size=48, weight="Bold", color="E27D60", x=30, y=56),
                            txt("12 offerings until Sacred Guarantee", size=14, weight="Bold", color="3D4B5C", x=30, y=130),
                            txt("Your Offerings: 2,350 Gems", size=14, weight="Medium", color="7A8A99", x=30, y=160),
                        ]
                    },
                    # Carved Wood Buttons
                    {
                        "type": "FRAME",
                        "name": "Btn Cast One",
                        "x": 40,
                        "y": 440,
                        "w": 450,
                        "h": 70,
                        "radius": 16,
                        "fill": "FFF8EC",
                        "stroke": "3D4B5C",
                        "strokeW": 2,
                        "children": [
                            txt("CAST ONCE · 100 GEMS", size=18, weight="Bold", color="3D4B5C", x=120, y=24)
                        ]
                    },
                    {
                        "type": "FRAME",
                        "name": "Btn Cast Decade",
                        "x": 40,
                        "y": 530,
                        "w": 450,
                        "h": 80,
                        "radius": 18,
                        "fill": "FF9E80",
                        "stroke": "E07A5C",
                        "strokeW": 3,
                        "children": [
                            txt("CAST DECADE · 900 GEMS", size=20, weight="Bold", color="FFFFFF", x=95, y=26)
                        ]
                    }
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# CONCEPT 4: Tactical Holographic Terminal (Arknights / Cyber)
# ---------------------------------------------------------------------------
def concept_4():
    return {
        "type": "FRAME",
        "name": "Concept 04 · Tactical Holographic Terminal",
        "w": W,
        "h": H,
        "radius": 24,
        "clip": True,
        "fill": "0D1117",
        "stroke": "30363D",
        "strokeW": 2,
        "children": [
            top_bar(),
            # Tactical Top Title
            txt("[OPERATIONAL ARCHIVE: SUMMON ALTAR 07]", size=14, weight="Bold", color="58A6FF", x=48, y=74),
            # Center Hologram Matrix
            {
                "type": "FRAME",
                "name": "Hologram Matrix",
                "x": 48,
                "y": 100,
                "w": 920,
                "h": 620,
                "radius": 18,
                "fill": "161B22",
                "stroke": "58A6FF",
                "strokeW": 1.5,
                "children": [
                    img_slot("auras/NeonWave", 500, 500, x=210, y=50),
                    txt("REEL FREQUENCY DETECTED: NEON WAVE", size=24, weight="Bold", color="58A6FF", x=30, y=520),
                    txt("Probability Sync: 2.0% | Resonance Pity: 38/50", size=14, weight="Medium", color="8B949E", x=30, y=560)
                ]
            },
            # Tactical Right Side Stats
            {
                "type": "FRAME",
                "name": "Tactical Sidebar",
                "x": 990,
                "y": 100,
                "w": 400,
                "h": 620,
                "radius": 18,
                "fill": "161B22",
                "stroke": "30363D",
                "strokeW": 1.5,
                "children": [
                    txt("PROBABILITY MATRIX", size=14, weight="Bold", color="FFA94D", x=24, y=24),
                    txt("Mythic 5★: 2.00%", size=15, weight="Bold", color="FF7A7A", x=24, y=60),
                    txt("Legendary 4★: 8.00%", size=15, weight="Bold", color="FFA94D", x=24, y=90),
                    txt("Epic 3★: 25.00%", size=15, weight="Bold", color="B79CF2", x=24, y=120),
                    txt("Rare 2★: 65.00%", size=15, weight="Bold", color="5AA9F0", x=24, y=150),
                    txt("GUARANTEED LOGIC: Pull 10 ensures 1x Epic+", size=13, weight="Medium", color="8B949E", x=24, y=200),
                ]
            },
            # Bottom Command CTAs
            {
                "type": "FRAME",
                "name": "Tactical Bottom CTA",
                "x": 48,
                "y": 740,
                "w": 1342,
                "h": 110,
                "radius": 18,
                "fill": "161B22",
                "stroke": "30363D",
                "strokeW": 1.5,
                "children": [
                    {"type": "FRAME", "name": "Btn Single", "x": 780, "y": 20, "w": 240, "h": 70, "radius": 12, "fill": "21262D", "stroke": "58A6FF", "strokeW": 2, "children": [txt("RESONATE x1 [100 G]", size=16, weight="Bold", color="FFFFFF", x=30, y=24)]},
                    {"type": "FRAME", "name": "Btn Multi", "x": 1050, "y": 20, "w": 260, "h": 70, "radius": 12, "fill": "238636", "stroke": "2EA043", "strokeW": 2, "children": [txt("OVERDRIVE x10 [900 G]", size=17, weight="Bold", color="FFFFFF", x=30, y=24)]}
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# CONCEPT 5: Pop Comic Magazine (Blue Archive / ZZZ Style)
# ---------------------------------------------------------------------------
def concept_5():
    return {
        "type": "FRAME",
        "name": "Concept 05 · Pop Comic Magazine (Blue Archive)",
        "w": W,
        "h": H,
        "radius": 24,
        "clip": True,
        "fill": "5AA9F0",
        "stroke": "3D4B5C",
        "strokeW": 2,
        "children": [
            top_bar(),
            # Magazine Cover Card
            {
                "type": "FRAME",
                "name": "Magazine Cover",
                "x": 60,
                "y": 80,
                "w": 1320,
                "h": 760,
                "radius": 28,
                "fill": "FFFFFF",
                "stroke": "3D4B5C",
                "strokeW": 4,
                "children": [
                    # Header Comic Banner
                    {
                        "type": "FRAME",
                        "name": "Header Magazine",
                        "x": 0,
                        "y": 0,
                        "w": 1320,
                        "h": 90,
                        "fill": "FFD45C",
                        "children": [
                            txt("AURA ANGLER MONTHLY · SPECIAL ISSUE", size=32, weight="Black", color="3D4B5C", x=40, y=26),
                            txt("VOL. 07", size=24, weight="Black", color="E07A5C", x=1180, y=30)
                        ]
                    },
                    # Featured Art
                    img_slot("auras_Art/NebulaKoi", 520, 520, x=400, y=110),
                    # Comic Stickers
                    {
                        "type": "FRAME",
                        "name": "Sticker Rate Up",
                        "x": 120,
                        "y": 140,
                        "w": 260,
                        "h": 80,
                        "radius": 16,
                        "fill": "FF6B6B",
                        "children": [
                            txt("MEGA RATE UP!", size=26, weight="Black", color="FFFFFF", x=30, y=22)
                        ]
                    },
                    {
                        "type": "FRAME",
                        "name": "Speech Bubble",
                        "x": 120,
                        "y": 250,
                        "w": 260,
                        "h": 120,
                        "radius": 20,
                        "fill": "FFF8EC",
                        "stroke": "3D4B5C",
                        "strokeW": 3,
                        "children": [
                            txt("Nebula Koi emerges from starlit water! Grants huge luck bonuses!", size=15, weight="Bold", color="3D4B5C", x=20, y=24)
                        ]
                    },
                    # Bottom Arcade Buttons
                    {
                        "type": "FRAME",
                        "name": "Btn Arcade 1",
                        "x": 780,
                        "y": 640,
                        "w": 240,
                        "h": 80,
                        "radius": 22,
                        "fill": "4FAF8A",
                        "stroke": "2B8A64",
                        "strokeW": 4,
                        "children": [
                            txt("ROLL 1x · 100 G", size=18, weight="Black", color="FFFFFF", x=45, y=26)
                        ]
                    },
                    {
                        "type": "FRAME",
                        "name": "Btn Arcade 10",
                        "x": 1040,
                        "y": 640,
                        "w": 240,
                        "h": 80,
                        "radius": 22,
                        "fill": "FF9E80",
                        "stroke": "E07A5C",
                        "strokeW": 4,
                        "children": [
                            txt("ROLL 10x · 900 G", size=18, weight="Black", color="FFFFFF", x=40, y=26)
                        ]
                    }
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# CONCEPT 6: Sacred Water Shrine Window (Cozy Fantasy Window Modal)
# ---------------------------------------------------------------------------
def concept_6():
    return {
        "type": "FRAME",
        "name": "Concept 06 · Sacred Water Shrine Window",
        "w": W,
        "h": H,
        "radius": 24,
        "clip": True,
        "fill": "121D28",
        "stroke": "3D4B5C",
        "strokeW": 2,
        "children": [
            top_bar(),
            # Central Altar Window
            {
                "type": "FRAME",
                "name": "Altar Window",
                "x": 140,
                "y": 80,
                "w": 1160,
                "h": 760,
                "radius": 32,
                "fill": "FFF8EC",
                "stroke": "E6DCCB",
                "strokeW": 4,
                "children": [
                    # Header Ribbon
                    {
                        "type": "FRAME",
                        "name": "Ribbon Header",
                        "x": 420,
                        "y": -16,
                        "w": 320,
                        "h": 48,
                        "radius": 14,
                        "fill": "FF9E80",
                        "children": [
                            txt("SACRED AURA SHRINE", size=18, weight="Bold", color="FFFFFF", x=60, y=12)
                        ]
                    },
                    # Sacred Water Pool
                    {
                        "type": "FRAME",
                        "name": "Water Pool",
                        "x": 40,
                        "y": 60,
                        "w": 1080,
                        "h": 540,
                        "radius": 24,
                        "fill": {"grad": ["D3ECFA", "7FD3B0"], "angle": 90},
                        "children": [
                            img_slot("auras_Art/SerpentOfTheVoid", 500, 500, x=290, y=20),
                            txt("Serpent of the Void (Mythic 5★)", size=26, weight="Bold", color="3D4B5C", x=40, y=470)
                        ]
                    },
                    # Dock Footer Controls
                    {
                        "type": "FRAME",
                        "name": "Dock Controls",
                        "x": 40,
                        "y": 620,
                        "w": 1080,
                        "h": 100,
                        "radius": 20,
                        "fill": "F3E9D8",
                        "children": [
                            txt("Shrine Blessing: 38/50 Offerings Completed", size=16, weight="Bold", color="3D4B5C", x=40, y=40),
                            {"type": "FRAME", "name": "Btn 1", "x": 600, "y": 20, "w": 210, "h": 60, "radius": 16, "fill": "9AD4F5", "stroke": "6BB3DE", "strokeW": 2, "children": [txt("1 Blessing · 100 G", size=16, weight="Bold", color="FFFFFF", x=30, y=18)]},
                            {"type": "FRAME", "name": "Btn 10", "x": 830, "y": 20, "w": 220, "h": 60, "radius": 16, "fill": "F2B544", "stroke": "C98B1E", "strokeW": 2, "children": [txt("10 Blessings · 900 G", size=16, weight="Bold", color="FFFFFF", x=24, y=18)]}
                        ]
                    }
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# CONCEPT 7: Mystic Tarot Spread (Fate of the Depths)
# ---------------------------------------------------------------------------
def concept_7():
    return {
        "type": "FRAME",
        "name": "Concept 07 · Mystic Tarot Spread",
        "w": W,
        "h": H,
        "radius": 24,
        "clip": True,
        "fill": "0F172A",
        "stroke": "3D4B5C",
        "strokeW": 2,
        "children": [
            top_bar(),
            # 3 Fanned Tarot Cards
            # Card Left
            {
                "type": "FRAME",
                "name": "Tarot Left",
                "x": 120,
                "y": 140,
                "w": 340,
                "h": 540,
                "radius": 20,
                "fill": "1E293B",
                "stroke": "475569",
                "strokeW": 2,
                "children": [
                    txt("PAST FATE", size=16, weight="Bold", color="94A3B8", x=115, y=30),
                    img_slot("auras/FrostPearl", 240, 240, x=50, y=120),
                    txt("Frost Pearl (Rare)", size=18, weight="Bold", color="E2E8F0", x=90, y=420)
                ]
            },
            # Card Center (Hero Card)
            {
                "type": "FRAME",
                "name": "Tarot Center Main",
                "x": 520,
                "y": 90,
                "w": 400,
                "h": 620,
                "radius": 24,
                "fill": "1E293B",
                "stroke": "F59E0B",
                "strokeW": 4,
                "children": [
                    txt("CELESTIAL FATE · 5★", size=18, weight="Bold", color="F59E0B", x=105, y=30),
                    img_slot("auras/SolarFlare", 320, 320, x=40, y=90),
                    txt("SOLAR FLARE", size=32, weight="Bold", color="FFFFFF", x=90, y=450),
                    txt("Blazing Aura · +45% Bite Rate", size=15, weight="Medium", color="CBD5E1", x=85, y=510)
                ]
            },
            # Card Right
            {
                "type": "FRAME",
                "name": "Tarot Right",
                "x": 980,
                "y": 140,
                "w": 340,
                "h": 540,
                "radius": 20,
                "fill": "1E293B",
                "stroke": "475569",
                "strokeW": 2,
                "children": [
                    txt("FUTURE FATE", size=16, weight="Bold", color="94A3B8", x=110, y=30),
                    img_slot("auras/UnknownAura", 240, 240, x=50, y=120),
                    txt("Mystery Aura", size=18, weight="Bold", color="E2E8F0", x=110, y=420)
                ]
            },
            # Bottom Controls
            {
                "type": "FRAME",
                "name": "Tarot Bottom Controls",
                "x": 420,
                "y": 750,
                "w": 600,
                "h": 85,
                "children": [
                    {"type": "FRAME", "name": "Btn 1", "x": 0, "y": 8, "w": 280, "h": 68, "radius": 18, "fill": "334155", "stroke": "64748B", "strokeW": 2, "children": [txt("REVEAL 1 FATE · 100 G", size=16, weight="Bold", color="FFFFFF", x=40, y=22)]},
                    {"type": "FRAME", "name": "Btn 10", "x": 310, "y": 8, "w": 290, "h": 68, "radius": 18, "fill": "D97706", "stroke": "B45309", "strokeW": 2, "children": [txt("SPREAD 10 FATES · 900 G", size=16, weight="Bold", color="FFFFFF", x=36, y=22)]}
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# CONCEPT 8: Split-Screen Dual Showcase (Modern Genshin Wish)
# ---------------------------------------------------------------------------
def concept_8():
    return {
        "type": "FRAME",
        "name": "Concept 08 · Split Dual Showcase (Genshin Wish)",
        "w": W,
        "h": H,
        "radius": 24,
        "clip": True,
        "fill": "111E2E",
        "stroke": "3D4B5C",
        "strokeW": 2,
        "children": [
            top_bar(),
            # Left 65% Main Banner
            {
                "type": "FRAME",
                "name": "Main Banner Left",
                "x": 48,
                "y": 80,
                "w": 880,
                "h": 760,
                "radius": 24,
                "fill": "16273B",
                "stroke": "325175",
                "strokeW": 2,
                "children": [
                    txt("TRENCH MONARCHS · EVENT WISH", size=16, weight="Bold", color="FFA94D", x=40, y=36),
                    txt("Abyssal Shadow", size=42, weight="Bold", color="FFFFFF", x=40, y=70),
                    img_slot("auras_Art/AbyssalShadow", 520, 520, x=180, y=120),
                    txt("Event Duration: 14d remaining", size=14, weight="Medium", color="7FD3B0", x=40, y=690)
                ]
            },
            # Right 35% Roster Showcase & Controls
            {
                "type": "FRAME",
                "name": "Roster & Controls Right",
                "x": 950,
                "y": 80,
                "w": 442,
                "h": 760,
                "radius": 24,
                "fill": "16273B",
                "stroke": "325175",
                "strokeW": 2,
                "children": [
                    txt("FEATURED 4★ AURAS", size=14, weight="Bold", color="E6DCCB", x=30, y=30),
                    # 4 Small Roster Slots
                    {
                        "type": "FRAME",
                        "name": "Roster Slot 1",
                        "x": 30,
                        "y": 64,
                        "w": 382,
                        "h": 68,
                        "radius": 14,
                        "fill": "1E344D",
                        "children": [
                            img_slot("auras/CoralHeart", 48, 48, x=10, y=10),
                            txt("Coral Heart", size=16, weight="Bold", color="FFFFFF", x=70, y=16),
                            txt("+3.5% Rate Boost", size=12, weight="Bold", color="7FD3B0", x=70, y=38)
                        ]
                    },
                    {
                        "type": "FRAME",
                        "name": "Roster Slot 2",
                        "x": 30,
                        "y": 142,
                        "w": 382,
                        "h": 68,
                        "radius": 14,
                        "fill": "1E344D",
                        "children": [
                            img_slot("auras/FrostPearl", 48, 48, x=10, y=10),
                            txt("Frost Pearl", size=16, weight="Bold", color="FFFFFF", x=70, y=16),
                            txt("+3.5% Rate Boost", size=12, weight="Bold", color="7FD3B0", x=70, y=38)
                        ]
                    },
                    {
                        "type": "FRAME",
                        "name": "Roster Slot 3",
                        "x": 30,
                        "y": 220,
                        "w": 382,
                        "h": 68,
                        "radius": 14,
                        "fill": "1E344D",
                        "children": [
                            img_slot("auras/TidalBloom", 48, 48, x=10, y=10),
                            txt("Tidal Bloom", size=16, weight="Bold", color="FFFFFF", x=70, y=16),
                            txt("+3.5% Rate Boost", size=12, weight="Bold", color="7FD3B0", x=70, y=38)
                        ]
                    },
                    {
                        "type": "FRAME",
                        "name": "Roster Slot 4",
                        "x": 30,
                        "y": 298,
                        "w": 382,
                        "h": 68,
                        "radius": 14,
                        "fill": "1E344D",
                        "children": [
                            img_slot("auras/StormCurrent", 48, 48, x=10, y=10),
                            txt("Storm Current", size=16, weight="Bold", color="FFFFFF", x=70, y=16),
                            txt("+3.5% Rate Boost", size=12, weight="Bold", color="7FD3B0", x=70, y=38)
                        ]
                    },
                    # Pity meter
                    {
                        "type": "FRAME",
                        "name": "Pity Box",
                        "x": 30,
                        "y": 390,
                        "w": 382,
                        "h": 120,
                        "radius": 16,
                        "fill": "122030",
                        "children": [
                            txt("PITY GUARANTEE", size=13, weight="Bold", color="A8DCD8", x=20, y=18),
                            txt("38 / 50 PULLS", size=24, weight="Bold", color="FFA94D", x=20, y=42),
                            txt("Guaranteed 5★ Mythic in 12 pulls", size=13, weight="Medium", color="E6DCCB", x=20, y=78)
                        ]
                    },
                    # Dual Buttons
                    {"type": "FRAME", "name": "Btn 1", "x": 30, "y": 550, "w": 382, "h": 76, "radius": 18, "fill": "1E344D", "stroke": "5AA9F0", "strokeW": 2, "children": [txt("WISH x1 · 100 GEMS", size=17, weight="Bold", color="FFFFFF", x=100, y=26)]},
                    {"type": "FRAME", "name": "Btn 10", "x": 30, "y": 646, "w": 382, "h": 84, "radius": 20, "fill": "F2B544", "stroke": "C98B1E", "strokeW": 2, "children": [txt("WISH x10 · 900 GEMS", size=19, weight="Bold", color="FFFFFF", x=90, y=28)]}
                ]
            }
        ]
    }

# ---------------------------------------------------------------------------
# MAIN SECTION BUILDER
# ---------------------------------------------------------------------------
def main():
    sec_x = 33000
    sec_y = 0
    col_w = 1440
    gap_x = 100
    gap_y = 100

    c1 = concept_1()
    c2 = concept_2()
    c3 = concept_3()
    c4 = concept_4()
    c5 = concept_5()
    c6 = concept_6()
    c7 = concept_7()
    c8 = concept_8()

    # Position in 2 rows of 4 columns inside the section
    # Row 1 (y = 160)
    c1["x"] = 100
    c1["y"] = 160

    c2["x"] = 100 + col_w + gap_x
    c2["y"] = 160

    c3["x"] = 100 + (col_w + gap_x) * 2
    c3["y"] = 160

    c4["x"] = 100 + (col_w + gap_x) * 3
    c4["y"] = 160

    # Row 2 (y = 160 + 900 + 100 = 1160)
    c5["x"] = 100
    c5["y"] = 1160

    c6["x"] = 100 + col_w + gap_x
    c6["y"] = 1160

    c7["x"] = 100 + (col_w + gap_x) * 2
    c7["y"] = 1160

    c8["x"] = 100 + (col_w + gap_x) * 3
    c8["y"] = 1160

    total_w = 100 + (col_w + gap_x) * 3 + col_w + 100 # ~6400px
    total_h = 160 + 900 + gap_y + 900 + 100 # ~2200px

    sec_tree = {
        "type": "SECTION",
        "name": "Gacha UI Redesign · 8 Concepts (Alchemy Stars Style)",
        "x": sec_x,
        "y": sec_y,
        "w": total_w,
        "h": total_h,
        "fill": "F8F5EE",
        "children": [
            # Header text inside section
            txt("GACHA UI REDESIGN · 8 CONCEPTS (ALCHEMY STARS & MODERN GACHA UI)", size=36, weight="Bold", color="3D4B5C", x=100, y=50),
            txt("Designed for 1440x900 Roblox Safe Zone. Select your preferred concept or mix-and-match elements.", size=18, weight="Medium", color="7A8A99", x=100, y=96),
            c1, c2, c3, c4,
            c5, c6, c7, c8
        ]
    }

    out_json = os.path.join(ROOT, "docs", "figma", "out_gacha_concepts.json")
    os.makedirs(os.path.dirname(out_json), exist_ok=True)
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump([{"pageId": PAGE_ID, "tree": sec_tree}], f, ensure_ascii=False, indent=2)
    print("Wrote spec to", out_json)

    # Call apply_patch
    print("Applying patch to Figma...")
    res = subprocess.run(["python", "-I", os.path.join(ROOT, "docs", "figma", "apply_patch.py"), out_json],
                         capture_output=True, text=True, encoding="utf-8")
    print("Apply patch result:", res.stdout)
    if res.returncode != 0:
        print("Apply patch error:", res.stderr)
        return

    # Extract the root ID
    built_id = res.stdout.strip().split()[-1]
    print(f"Built section rootId: {built_id}")

    # Fill images
    print("Filling images from assets/art...")
    img_res = subprocess.run(["python", "-I", os.path.join(ROOT, "tools", "art", "figma_images.py"),
                              "--channel=aura-fishing", f"--root={built_id}"],
                             capture_output=True, text=True, encoding="utf-8")
    print("Image fill output:", img_res.stdout)

if __name__ == "__main__":
    main()
