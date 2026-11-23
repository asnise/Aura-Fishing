"""Rebuild 'After claiming Day 3' (3794:2435) in Figma.
- Overlays the card directly with a dark translucent tint.
- Centers a prominent green circular checkmark badge on the card/reward.
- Removes the bottom label completely as requested by the user.
- Shows both the Calendar Card format and Horizontal Card format in claimed state, plus disabled 'CLAIMED TODAY' button.
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

def check_badge_svg(size=46, color="#70DE43", bg_alpha=0.20):
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" fill="none" xmlns="http://www.w3.org/2000/svg">'
        f'<circle cx="{size/2}" cy="{size/2}" r="{size/2 - 3}" fill="{color}" fill-opacity="{bg_alpha}" stroke="{color}" stroke-width="4.5"/>'
        f'<path d="M{size*0.27:.1f} {size*0.50:.1f} l{size*0.17:.1f} {size*0.17:.1f} l{size*0.30:.1f} -{size*0.30:.1f}" '
        f'stroke="{color}" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>'
        f'</svg>'
    )

def binder_pegs_svg(w=133, h=8):
    x1 = int(w * 0.25)
    x2 = int(w * 0.75)
    return (
        f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" fill="none" xmlns="http://www.w3.org/2000/svg">'
        f'<rect x="{x1-5}" y="0" width="10" height="{h}" rx="3" fill="#DDE4EC" stroke="#8CA0B3" stroke-width="1.2"/>'
        f'<rect x="{x2-5}" y="0" width="10" height="{h}" rx="3" fill="#DDE4EC" stroke="#8CA0B3" stroke-width="1.2"/>'
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

def build_after_claiming_section():
    card_w = 133
    card_h = 142

    # Calendar Card Day 3 (Claimed State)
    calendar_card_claimed = {
        "name": "Day 3 Calendar Card (Claimed)",
        "w": card_w,
        "h": card_h,
        "layout": "V",
        "radius": 16,
        "stroke": "E6DCCB",
        "strokeW": 2,
        "clip": True,
        "children": [
            # Header Tab (Amber gold)
            {
                "name": "HeaderTab",
                "w": card_w,
                "h": 34,
                "layout": "V",
                "main": "CENTER",
                "cross": "CENTER",
                "gap": 1,
                "pad": [2, 0, 4, 0],
                "fill": "F5A623",
                "children": [
                    {
                        "type": "SVG",
                        "name": "BinderPegs",
                        "svg": binder_pegs_svg(card_w, 7),
                        "w": card_w,
                        "h": 7,
                    },
                    ftxt("Day 3", 15, "FFFFFF", name="DayLabel")
                ]
            },
            # Body Content
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
                        "name": "Img ui/status/gem",
                        "w": 46,
                        "h": 46,
                    },
                    ftxt("15 Gems", 13, "3D4B5C", name="Amount", textAlignHorizontal="CENTER")
                ]
            },
            # Dark Translucent Overlay covering the whole card
            {
                "type": "RECT",
                "name": "ClaimedOverlay",
                "w": card_w,
                "h": card_h,
                "x": 0,
                "y": 0,
                "radius": 16,
                "fill": {"hex": "1E293B", "opacity": 0.55},
                "absolute": True,
            },
            # Green Circular Check Badge centered
            {
                "type": "SVG",
                "name": "ClaimedCheckBadge",
                "svg": check_badge_svg(46, "#70DE43"),
                "w": 46,
                "h": 46,
                "x": int((card_w - 46) / 2),
                "y": int((card_h - 46) / 2),
                "absolute": True,
            }
        ]
    }

    # Horizontal Card Day 3 (Claimed State) - Overlay covers the icon well with centered checkmark
    horizontal_card_claimed = {
        "name": "Day 3 Horizontal Card (Claimed)",
        "w": 340,
        "h": 84,
        "layout": "H",
        "pad": [14, 18, 14, 18],
        "gap": 16,
        "cross": "CENTER",
        "radius": 18,
        "fill": "F3E9D8",
        "stroke": "E6DCCB",
        "strokeW": 2,
        "children": [
            # Icon Well with dark overlay & centered checkmark
            {
                "name": "RewardWell",
                "w": 56,
                "h": 56,
                "radius": 14,
                "fill": "FFFFFF",
                "stroke": "E6DCCB",
                "strokeW": 1.5,
                "clip": True,
                "children": [
                    {
                        "type": "RECT",
                        "name": "Img ui/status/gem",
                        "w": 40,
                        "h": 40,
                        "x": 8,
                        "y": 8,
                        "absolute": True,
                    },
                    # Dark overlay covering the well
                    {
                        "type": "RECT",
                        "name": "ClaimedOverlay",
                        "w": 56,
                        "h": 56,
                        "x": 0,
                        "y": 0,
                        "radius": 14,
                        "fill": {"hex": "1E293B", "opacity": 0.55},
                        "absolute": True,
                    },
                    # Centered checkmark badge
                    {
                        "type": "SVG",
                        "name": "ClaimedCheckBadge",
                        "svg": check_badge_svg(38, "#70DE43"),
                        "w": 38,
                        "h": 38,
                        "x": 9,
                        "y": 9,
                        "absolute": True,
                    }
                ]
            },
            # Text details (NO bottom label!)
            {
                "name": "Details",
                "layout": "V",
                "gap": 4,
                "children": [
                    ftxt("Day 3", 17, "3D4B5C", name="Day"),
                    ntxt("15 Gems", 15, "3D4B5C", name="RewardAmount", bold=True),
                ]
            }
        ]
    }

    # Disabled Button
    disabled_button = {
        "name": "Btn Claimed Today",
        "w": 280,
        "h": 56,
        "layout": "H",
        "main": "CENTER",
        "cross": "CENTER",
        "radius": 16,
        "fill": "D8D1C4",
        "stroke": "BCB3A4",
        "strokeSides": {"b": 5},
        "children": [
            ftxt("CLAIMED TODAY", 20, "7A8A99", name="Label")
        ]
    }

    tree = {
        "name": "After claiming",
        "layout": "V",
        "gap": 16,
        "absolute": True,
        "x": 30,
        "y": 1880,
        "children": [
            # Header Title
            {
                "name": "HeadingGroup",
                "layout": "V",
                "gap": 4,
                "children": [
                    ftxt("After claiming Day 3", 22, "3D4B5C", name="Title"),
                    ntxt("Card is covered by dark translucent overlay with green checkmark (no bottom label); claim button becomes disabled", 14, "7A8A99", name="Sub")
                ]
            },
            # Cards & Button Row
            {
                "name": "ClaimedRow",
                "layout": "H",
                "gap": 24,
                "cross": "CENTER",
                "children": [
                    calendar_card_claimed,
                    horizontal_card_claimed,
                    disabled_button
                ]
            }
        ]
    }
    return tree

if __name__ == "__main__":
    print("Rebuilding 'After claiming Day 3' (3796:2816)...")
    tree = build_after_claiming_section()
    res = call("build_tree", {"replaceId": "3796:2816", "tree": tree})
    new_after_id = res["rootId"]
    print("Rebuilt successfully! Root ID:", new_after_id)

    print("\nFilling images in the rebuilt section...")
    img_script = os.path.join(ROOT, "tools", "art", "figma_images.py")
    subprocess.run(["python", "-I", img_script, "--channel=aura-fishing", f"--root={new_after_id}"], check=False)

    print("\nExporting preview PNG...")
    f = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
    json.dump({"nodeId": new_after_id, "format": "PNG", "scale": 2}, f)
    f.close()
    r = subprocess.run(["node", RUN, f"--channel={channel}", "export_node_as_image", f.name], capture_output=True, text=True)
    d = json.loads(r.stdout)
    raw = base64.b64decode(d['imageData'])
    out_path = os.path.join(ROOT, "docs", "figma", "shots", "after_claiming_fixed.png")
    with open(out_path, "wb") as img_f:
        img_f.write(raw)
    print("Saved preview to:", out_path, "Size:", len(raw), "bytes")
