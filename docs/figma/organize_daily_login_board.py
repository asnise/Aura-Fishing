"""Organize Screen 21 Daily Login board (3794:1650) with perfect spacing and alignment:
- Cleans up and aligns all 6 options in a 2-column grid with generous 64px row gaps and 80px column gaps.
- Col 1 (x=3718): Option A (y=5360), Option C (y=5970), Option E (y=6470)
- Col 2 (x=4558): Option B (y=5360), Option D (y=5970), Option F (y=6470)
- Row 4 (y=7230): After Claiming Day 3 styled as a full-width Cozy Lake presentation banner (w=1700)
- Header: Title and Subtitle aligned at top, Daily Login components placed cleanly.
- Section 3794:1650 resized to 1800 x 2340 with layoutMode=NONE for zero layout snapping bugs.
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

# Parent Section 3794:1650 origin
SEC_X = 3670
SEC_Y = 5200

def to_rel(abs_x, abs_y):
    return abs_x - SEC_X, abs_y - SEC_Y

# 1. Ensure Screen 21 layoutMode is NONE
print("1. Setting Screen 21 layoutMode to NONE...")
call("set_layout_mode", {"nodeId": "3794:1650", "layoutMode": "NONE"})

# 2. Resize Section to 1800 x 2340
print("2. Resizing Screen 21 to 1800 x 2340...")
call("resize_node", {"nodeId": "3794:1650", "width": 1800, "height": 2340})

# 3. Position Header Elements
print("3. Positioning Board Header...")
rx, ry = to_rel(3718, 5235)
call("move_node", {"nodeId": "3794:1651", "x": rx, "y": ry})  # Title

rx, ry = to_rel(3718, 5285)
call("move_node", {"nodeId": "3794:1652", "x": rx, "y": ry})  # Subtitle

rx, ry = to_rel(4558, 5240)
call("move_node", {"nodeId": "3794:1653", "x": rx, "y": ry})  # Daily Login components

# 4. Position Row 1: Option A & Option B (y=5360)
print("4. Positioning Row 1 (y=5360)...")
rx, ry = to_rel(3718, 5360)
call("move_node", {"nodeId": "3794:1656", "x": rx, "y": ry})  # Option A

rx, ry = to_rel(4558, 5360)
call("move_node", {"nodeId": "3794:1753", "x": rx, "y": ry})  # Option B

# 5. Position Row 2: Option C & Option D (y=5970)
print("5. Positioning Row 2 (y=5970)...")
rx, ry = to_rel(3718, 5970)
call("move_node", {"nodeId": "3794:1850", "x": rx, "y": ry})  # Option C

rx, ry = to_rel(4558, 5970)
call("move_node", {"nodeId": "3794:1945", "x": rx, "y": ry})  # Option D

# 6. Position Row 3: Option E & Option F (y=6470)
print("6. Positioning Row 3 (y=6470)...")
rx, ry = to_rel(3718, 6470)
call("move_node", {"nodeId": "3794:2060", "x": rx, "y": ry})  # Option E

rx, ry = to_rel(4558, 6470)
call("move_node", {"nodeId": "3796:2955", "x": rx, "y": ry})  # Option F

# Fix Option F Title Width so text doesn't overflow
print("   Adjusting Option F title width...")
call("resize_node", {"nodeId": "3796:2956", "width": 460, "height": 50})

# 7. Position Row 4: After Claiming Day 3 (y=7230)
print("7. Positioning Row 4: After Claiming Day 3 (y=7230)...")
rx, ry = to_rel(3718, 7230)
call("move_node", {"nodeId": "3796:3061", "x": rx, "y": ry})  # After claiming

print("\nBoard positions updated! Inspecting children...")
res = call("get_node_info", {"nodeId": "3794:1650"})
for c in res.get("children", []):
    bb = c.get("absoluteBoundingBox", {})
    print(f"  {c.get('name'):<30} | pos: ({bb.get('x')}, {bb.get('y')}) | size: {bb.get('width')}x{bb.get('height')}")

# 8. Export full board screenshot to verify
print("\n8. Exporting daily_login_board_final.png...")
f = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
json.dump({"nodeId": "3794:1650", "format": "PNG", "scale": 1}, f)
f.close()
r = subprocess.run(["node", RUN, f"--channel={channel}", "export_node_as_image", f.name], capture_output=True, text=True)
d = json.loads(r.stdout)
raw = base64.b64decode(d['imageData'])
out_path = os.path.join(ROOT, "docs", "figma", "shots", "daily_login_board_final.png")
with open(out_path, "wb") as img_f:
    img_f.write(raw)
print("Saved final board screenshot to:", out_path, "Size:", len(raw), "bytes")
