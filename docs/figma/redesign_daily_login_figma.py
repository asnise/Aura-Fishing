"""Redesign Screen 21 Daily Login in Figma (3794:1650) based on user reference.
- Applies dark translucent overlay + circular green checkmark badge to claimed rewards.
- Rebuilds Option F as a 3-3-1 Calendar Tear-off Daily Login window matching the reference.
- Updates existing claimed overlays across all options on the board.
"""
import json
import os
import subprocess
import tempfile
import base64

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN = os.path.join(ROOT, "Figma For Roblox", "cursor-talk-to-figma-mcp", "scripts", "figma-run.mjs")
channel = "aura-fishing"

def call(cmd, params):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(params, f)
    try:
        r = subprocess.run(["node", RUN, f"--channel={channel}", cmd, f.name, "--timeout=300"], capture_output=True, text=True, encoding="utf-8")
    finally:
        os.unlink(f.name)
    if r.returncode != 0:
        raise SystemExit(f"{cmd} failed: {r.stderr.strip() or r.stdout.strip()}")
    return json.loads(r.stdout)

# SVG helpers
def check_badge_svg(size=46, color="#70DE43", bg_alpha=0.20):
    # Circular green ring + bold green checkmark
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" fill="none" xmlns="http://www.w3.org/2000/svg">'
        f'<circle cx="{size/2}" cy="{size/2}" r="{size/2 - 3}" fill="{color}" fill-opacity="{bg_alpha}" stroke="{color}" stroke-width="4.5"/>'
        f'<path d="M{size*0.27:.1f} {size*0.50:.1f} l{size*0.17:.1f} {size*0.17:.1f} l{size*0.30:.1f} -{size*0.30:.1f}" '
        f'stroke="{color}" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>'
        f'</svg>'
    )

def binder_pegs_svg(w=133, h=8):
    # 2 small binder rings at top of calendar card
    x1 = int(w * 0.25)
    x2 = int(w * 0.75)
    return (
        f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" fill="none" xmlns="http://www.w3.org/2000/svg">'
        f'<rect x="{x1-5}" y="0" width="10" height="{h}" rx="3" fill="#DDE4EC" stroke="#8CA0B3" stroke-width="1.2"/>'
        f'<rect x="{x2-5}" y="0" width="10" height="{h}" rx="3" fill="#DDE4EC" stroke="#8CA0B3" stroke-width="1.2"/>'
        f'</svg>'
    )

def day7_pegs_svg(w=420, h=8):
    # 4 binder rings across the wide day 7 card
    xs = [int(w * 0.15), int(w * 0.38), int(w * 0.62), int(w * 0.85)]
    rects = "".join([f'<rect x="{x-5}" y="0" width="10" height="{h}" rx="3" fill="#DDE4EC" stroke="#8CA0B3" stroke-width="1.2"/>' for x in xs])
    return (
        f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" fill="none" xmlns="http://www.w3.org/2000/svg">'
        f'{rects}'
        f'</svg>'
    )

def plus_chip_svg(size=24):
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" fill="none" xmlns="http://www.w3.org/2000/svg">'
        f'<circle cx="{size/2}" cy="{size/2}" r="{size/2}" fill="#F2B544"/>'
        f'<path d="M{size/2} {size*0.25} V{size*0.75} M{size*0.25} {size/2} H{size*0.75}" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"/>'
        f'</svg>'
    )

def ftxt(t, size, color="3D4B5C", name="Value", **kw):
    d = {
        "type": "TEXT",
        "name": name,
        "text": str(t),
        "font": {"family": "Fredoka One", "style": "Regular"},
        "size": size,
        "color": color,
    }
    d.update(kw)
    return d

def ntxt(t, size, color="3D4B5C", name="Text", bold=True, **kw):
    d = {
        "type": "TEXT",
        "name": name,
        "text": str(t),
        "font": {"family": "Nunito", "style": "Bold" if bold else "Regular"},
        "size": size,
        "color": color,
    }
    d.update(kw)
    return d

def build_calendar_window():
    card_w = 133
    card_h = 142

    def make_card(day_num, title, icon_key, amount_text, state="locked"):
        is_ready = (state == "ready")
        is_claimed = (state == "claimed")
        
        tab_bg = "F5A623" if is_ready else "38BDF8"
        stroke_col = "F2B544" if is_ready else "E6DCCB"
        stroke_w = 2.5 if is_ready else 2

        card_children = [
            # Top Header Tab (height 34)
            {
                "name": "HeaderTab",
                "w": card_w,
                "h": 34,
                "layout": "V",
                "main": "CENTER",
                "cross": "CENTER",
                "gap": 1,
                "pad": [2, 0, 4, 0],
                "fill": tab_bg,
                "children": [
                    {
                        "type": "SVG",
                        "name": "BinderPegs",
                        "svg": binder_pegs_svg(card_w, 7),
                        "w": card_w,
                        "h": 7,
                    },
                    ftxt(title, 15, "FFFFFF", name="DayLabel")
                ]
            },
            # Body Content (height card_h - 34)
            {
                "name": "Body",
                "w": card_w,
                "h": card_h - 34,
                "layout": "V",
                "main": "CENTER",
                "cross": "CENTER",
                "gap": 4,
                "pad": [4, 6, 6, 6],
                "fill": "FFFDF7",
                "children": [
                    {
                        "type": "RECT",
                        "name": f"Img {icon_key}",
                        "w": 46,
                        "h": 46,
                    },
                    ftxt(amount_text, 13 if is_ready else 12, "3D4B5C", name="Amount", textAlignHorizontal="CENTER")
                ]
            }
        ]

        # If claimed: add dark translucent overlay covering entire card + centered green check badge
        if is_claimed:
            card_children.append({
                "type": "RECT",
                "name": "ClaimedOverlay",
                "w": card_w,
                "h": card_h,
                "x": 0,
                "y": 0,
                "radius": 16,
                "fill": {"hex": "1E293B", "opacity": 0.55},
                "absolute": True,
            })
            card_children.append({
                "type": "SVG",
                "name": "ClaimedCheckBadge",
                "svg": check_badge_svg(46, "#70DE43"),
                "w": 46,
                "h": 46,
                "x": int((card_w - 46) / 2),
                "y": int((card_h - 46) / 2),
                "absolute": True,
            })

        # If ready: add a prominent "READY" badge
        if is_ready:
            card_children.append({
                "name": "ReadyBadge",
                "layout": "H",
                "pad": [2, 8, 2, 8],
                "radius": 999,
                "fill": "FF9E80",
                "x": int((card_w - 56) / 2),
                "y": card_h - 22,
                "absolute": True,
                "children": [
                    ntxt("READY", 10, "FFFFFF", name="TagText", bold=True)
                ]
            })

        return {
            "name": f"Day {day_num} Card",
            "w": card_w,
            "h": card_h,
            "layout": "V",
            "radius": 16,
            "stroke": stroke_col,
            "strokeW": stroke_w,
            "clip": True,
            "children": card_children
        }

    # Day 7 Wide Grand Reward Card
    day7_w = 420
    day7_h = 118
    day7_card = {
        "name": "Day 7 Grand Reward Card",
        "w": day7_w,
        "h": day7_h,
        "layout": "V",
        "radius": 16,
        "stroke": "E6DCCB",
        "strokeW": 2,
        "clip": True,
        "children": [
            # Header Tab
            {
                "name": "HeaderTab",
                "w": day7_w,
                "h": 34,
                "layout": "H",
                "main": "SPACE_BETWEEN",
                "cross": "CENTER",
                "pad": [0, 16, 0, 16],
                "fill": "38BDF8",
                "children": [
                    ftxt("Day 7", 16, "FFFFFF", name="DayLabel"),
                    {
                        "type": "SVG",
                        "name": "BinderPegs",
                        "svg": day7_pegs_svg(160, 7),
                        "w": 160,
                        "h": 7,
                    },
                    {
                        "name": "GrandPill",
                        "layout": "H",
                        "pad": [2, 10, 2, 10],
                        "radius": 999,
                        "fill": "FBEAB8",
                        "stroke": "C98B1E",
                        "strokeW": 1,
                        "children": [
                            ntxt("GRAND REWARD", 11, "C98B1E", name="GrandText", bold=True)
                        ]
                    }
                ]
            },
            # Dual Reward Body
            {
                "name": "Body",
                "w": day7_w,
                "h": day7_h - 34,
                "layout": "H",
                "main": "CENTER",
                "cross": "CENTER",
                "gap": 18,
                "pad": [6, 16, 6, 16],
                "fill": "FFFDF7",
                "children": [
                    # Left item: 1000 Pearls
                    {
                        "name": "PearlsReward",
                        "layout": "H",
                        "gap": 8,
                        "cross": "CENTER",
                        "children": [
                            {"type": "RECT", "name": "Img ui/status/pearl", "w": 42, "h": 42},
                            ftxt("1,000 Pearls", 15, "3D4B5C", name="PearlAmount")
                        ]
                    },
                    # Plus chip
                    {
                        "type": "SVG",
                        "name": "PlusChip",
                        "svg": plus_chip_svg(22),
                        "w": 22,
                        "h": 22,
                    },
                    # Right item: 50 Gems
                    {
                        "name": "GemsReward",
                        "layout": "H",
                        "gap": 8,
                        "cross": "CENTER",
                        "children": [
                            {"type": "RECT", "name": "Img ui/status/gem", "w": 46, "h": 46},
                            ftxt("50 Gems", 16, "C98B1E", name="GemAmount")
                        ]
                    }
                ]
            }
        ]
    }

    # Full Option F Frame
    window_tree = {
        "name": "F. Pocket Calendar",
        "w": 460,
        "layout": "V",
        "gap": 16,
        "absolute": True,
        "x": 946,
        "y": 1150,
        "children": [
            # Option title
            {
                "name": "Option title",
                "layout": "V",
                "gap": 4,
                "children": [
                    ftxt("F. Calendar Cards (Reference Match)", 22, "3D4B5C", name="Name"),
                    ntxt("3-3-1 tear-off calendar layout with dark claimed overlay, green check badges, and Day 7 grand reward", 14, "7A8A99", name="Description")
                ]
            },
            # Cozy Lake Window
            {
                "name": "Daily Login",
                "w": 460,
                "layout": "V",
                "pad": [20, 20, 20, 20],
                "gap": 14,
                "radius": 24,
                "fill": "FFF8EC",
                "stroke": "E6DCCB",
                "strokeW": 2,
                "children": [
                    # Header
                    {
                        "name": "Header",
                        "w": 420,
                        "layout": "V",
                        "gap": 8,
                        "children": [
                            # Title Row with Close
                            {
                                "name": "TitleRow",
                                "w": 420,
                                "layout": "H",
                                "main": "SPACE_BETWEEN",
                                "cross": "CENTER",
                                "children": [
                                    {
                                        "name": "Heading",
                                        "layout": "V",
                                        "gap": 2,
                                        "children": [
                                            ftxt("Daily Login", 26, "3D4B5C", name="Title"),
                                            ntxt("Log in every day for free rewards", 13, "7A8A99", name="Subtitle")
                                        ]
                                    },
                                    # Close button
                                    {
                                        "name": "Close",
                                        "w": 36,
                                        "h": 36,
                                        "radius": 18,
                                        "fill": "F27A7A",
                                        "stroke": "CC5454",
                                        "strokeW": 2,
                                        "layout": "H",
                                        "main": "CENTER",
                                        "cross": "CENTER",
                                        "children": [
                                            ftxt("X", 18, "FFFFFF", name="Label")
                                        ]
                                    }
                                ]
                            },
                            # Chips Row (Timer + Streak)
                            {
                                "name": "ChipsRow",
                                "layout": "H",
                                "gap": 8,
                                "cross": "CENTER",
                                "children": [
                                    {
                                        "name": "ResetTimer",
                                        "layout": "H",
                                        "pad": [4, 12, 4, 12],
                                        "radius": 999,
                                        "fill": "F3E9D8",
                                        "stroke": "E6DCCB",
                                        "strokeW": 1.5,
                                        "children": [
                                            ntxt("Resets in 05:01:32", 11, "3D4B5C", name="Label")
                                        ]
                                    },
                                    {
                                        "name": "StreakChip",
                                        "layout": "H",
                                        "pad": [4, 12, 4, 12],
                                        "radius": 999,
                                        "fill": "FBEAB8",
                                        "stroke": "C98B1E",
                                        "strokeW": 1.5,
                                        "children": [
                                            ntxt("Streak: 2 Days", 11, "C98B1E", name="Label")
                                        ]
                                    }
                                ]
                            }
                        ]
                    },
                    # Calendar Grid (3-3-1)
                    {
                        "name": "CalendarGrid",
                        "w": 420,
                        "layout": "V",
                        "gap": 10,
                        "children": [
                            # Row 1: Day 1 (Claimed), Day 2 (Claimed), Day 3 (Ready)
                            {
                                "name": "Row1",
                                "w": 420,
                                "layout": "H",
                                "gap": 10,
                                "children": [
                                    make_card(1, "Day 1", "ui/status/coin", "1,000 Coins", state="claimed"),
                                    make_card(2, "Day 2", "equipment/Worm", "15 Worms", state="claimed"),
                                    make_card(3, "Day 3", "ui/status/gem", "15 Gems", state="ready"),
                                ]
                            },
                            # Row 2: Days 4, 5, 6 (Locked)
                            {
                                "name": "Row2",
                                "w": 420,
                                "layout": "H",
                                "gap": 10,
                                "children": [
                                    make_card(4, "Day 4", "equipment/GlowGrub", "10 Glow Grubs", state="locked"),
                                    make_card(5, "Day 5", "ui/status/pearl", "500 Pearls", state="locked"),
                                    make_card(6, "Day 6", "equipment/SquidBait", "10 Squid Baits", state="locked"),
                                ]
                            },
                            # Row 3: Day 7 Grand Reward
                            day7_card
                        ]
                    },
                    # Claim Action Footer
                    {
                        "name": "ClaimFooter",
                        "w": 420,
                        "h": 52,
                        "layout": "H",
                        "main": "CENTER",
                        "cross": "CENTER",
                        "radius": 16,
                        "fill": "7FD3B0",
                        "stroke": "4FAF8A",
                        "strokeSides": {"b": 5},
                        "children": [
                            ftxt("CLAIM DAY 3", 22, "FFFFFF", name="Label")
                        ]
                    }
                ]
            }
        ]
    }
    return window_tree

if __name__ == "__main__":
    print("1. Updating Option F (3796:2686) with refined Calendar Tear-Off design...")
    tree = build_calendar_window()
    res = call("build_tree", {"replaceId": "3796:2686", "tree": tree})
    new_f_id = res["rootId"]
    print("Option F replaced! Root ID:", new_f_id)

    print("\n2. Filling images in Option F...")
    img_script = os.path.join(ROOT, "tools", "art", "figma_images.py")
    subprocess.run(["python", "-I", img_script, "--channel=aura-fishing", f"--root={new_f_id}"], check=False)

    print("\n3. Exporting preview PNG...")
    f = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
    json.dump({"nodeId": new_f_id, "format": "PNG", "scale": 2}, f)
    f.close()
    r = subprocess.run(["node", RUN, f"--channel={channel}", "export_node_as_image", f.name], capture_output=True, text=True)
    d = json.loads(r.stdout)
    raw = base64.b64decode(d['imageData'])
    out_path = os.path.join(ROOT, "docs", "figma", "shots", "daily_login_option_f.png")
    with open(out_path, "wb") as img_f:
        img_f.write(raw)
    print("Saved preview to:", out_path, "Size:", len(raw), "bytes")
