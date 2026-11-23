"""Apply FULL-CARD Claimed Overlays across all daily login options on the board.
- The dark translucent overlay covers the entire day card frame (not just the icon well).
- A circular green checkmark badge is positioned in the exact center of the card.
- Removes old well-level badges/overlays so there is no double-overlay.
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

def check_badge_svg(size=52, color="#70DE43", bg_alpha=0.22):
    r = size / 2 - 3
    stroke_w = 4.5 if size >= 48 else 3.8
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" fill="none" xmlns="http://www.w3.org/2000/svg">'
        f'<circle cx="{size/2}" cy="{size/2}" r="{r}" fill="{color}" fill-opacity="{bg_alpha}" stroke="{color}" stroke-width="{stroke_w}"/>'
        f'<path d="M{size*0.27:.1f} {size*0.50:.1f} L{size*0.44:.1f} {size*0.68:.1f} L{size*0.74:.1f} {size*0.35:.1f}" '
        f'stroke="{color}" stroke-width="{stroke_w}" stroke-linecap="round" stroke-linejoin="round"/>'
        f'</svg>'
    )

# 1. Clean up old well-level overlays and badges
old_node_ids = [
    # Option A wells
    "3794:1681", "3796:2846",
    "3794:1692", "3796:2849",
    # Option C wells
    "3794:1888", "3796:2858",
    "3794:1899", "3796:2861",
    # Option D wells
    "3794:1972", "3796:2864",
    "3794:1983", "3796:2867",
    # Option E wells
    "3794:2165", "3796:2870",
    "3794:2176", "3796:2873",
    # After Claiming Horizontal well
    "3796:3082", "3796:3083",
]

print("1. Removing old well-level overlays and badges...")
call("patch_nodes", {"patches": [{"id": nid, "remove": True} for nid in old_node_ids]})
print("Cleaned up old well nodes!")

# 2. Target cards for FULL-CARD overlays
# Format: (card_node_id, card_width, card_height, corner_radius, badge_size)
cards = [
    # Option A: Day 1 (152.5 x 148), Day 2 (152.5 x 148)
    ("3794:1675", 152.5, 148, 18, 52),
    ("3794:1686", 152.5, 148, 18, 52),
    # Option B: Day 1 (134 x 148), Day 2 (134 x 148)
    ("3794:1773", 134, 148, 18, 50),
    ("3794:1784", 134, 148, 18, 50),
    # Option C: Day 1 (109.3 x 146), Day 2 (109.3 x 146)
    ("3794:1882", 109.3, 146, 18, 44),
    ("3794:1893", 109.3, 146, 18, 44),
    # Option D: Day 1 (108.9 x 146), Day 2 (108.9 x 146)
    ("3794:1966", 108.9, 146, 18, 44),
    ("3794:1977", 108.9, 146, 18, 44),
    # Option E: Day 1 (315 x 84), Day 2 (315 x 84)
    ("3794:2160", 315, 84, 18, 46),
    ("3794:2171", 315, 84, 18, 46),
    # After Claiming: Horizontal Card (340 x 84)
    ("3796:3079", 340, 84, 18, 46),
]

print("\n2. Applying FULL-CARD overlays and centered badges...")
for card_id, w, h, radius, badge_size in cards:
    # 1. Full-card dark translucent overlay
    call("build_tree", {
        "parentId": card_id,
        "tree": {
            "type": "RECT",
            "name": "FullCardClaimedOverlay",
            "w": w,
            "h": h,
            "x": 0,
            "y": 0,
            "radius": radius,
            "fill": {"hex": "1E293B", "opacity": 0.55},
            "absolute": True
        }
    })
    # 2. Centered green check badge
    bx = round((w - badge_size) / 2, 1)
    by = round((h - badge_size) / 2, 1)
    call("build_tree", {
        "parentId": card_id,
        "tree": {
            "type": "SVG",
            "name": "FullCardCheckBadge",
            "svg": check_badge_svg(badge_size, "#70DE43"),
            "w": badge_size,
            "h": badge_size,
            "x": bx,
            "y": by,
            "absolute": True
        }
    })
    print(f"  Applied to card {card_id} ({w}x{h}) badge_pos=({bx}, {by})")

print("\nAll full-card overlays applied successfully!")
