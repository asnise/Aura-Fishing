"""Daily Login option B "Grand Shelf" (3794:1753) restyled as F "Calendar Cards" (3796:2955) — user, 2026-11-23:
same tear-off calendar look (header tab with binder pegs + white body, dark overlay + check when claimed) but in
Cozy Lake theme colours instead of F's neon blue, and a mint check. Only the 7 day cards are replaced.

Run:  python -I docs/figma/daily_login_b_calendar.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/37_daily_b_calendar_ops.json
Then: python -I tools/art/figma_images.py --root 3794:1753
"""
import json
import os
import sys

INK, CREAM, SAND_LINE = "3D4B5C", "FFFDF7", "E6DCCB"
SKY, CORAL, GOLD, GOLD_LIP = "6BB3DE", "FF9E80", "F2B544", "C98B1E"
MINT, MINT_LIP = "7FD3B0", "4FB58C"
FRED = {"family": "Fredoka One", "style": "Regular"}
NUN = {"family": "Nunito", "style": "Bold"}

# replaceId, day, image key, amount text, state ("claimed" | "today" | "locked")
DAYS = [("3794:1773", 1, "ui/status/coin", "1,000 Coins", "claimed"),
        ("3794:1784", 2, "equipment/Worm", "15 Worms", "claimed"),
        ("3794:1795", 3, "ui/status/gem", "15 Gems", "today"),
        ("3794:1806", 4, "equipment/GlowGrub", "10 Glow Grubs", "locked"),
        ("3794:1816", 5, "ui/status/pearl", "500 Pearls", "locked"),
        ("3794:1826", 6, "equipment/SquidBait", "10 Squid Baits", "locked")]


def txt(t, size, color, font=FRED, **kw):
    d = {"type": "TEXT", "text": t, "font": font, "size": size, "color": color, "name": kw.pop("name", "Text")}
    d.update(kw)
    return d


def pegs(w, n=2):
    """Binder pegs on the header tab (small cream pills with an ink rim)."""
    gap = w / (n + 1)
    return [{"name": f"Peg {i + 1}", "w": 16, "h": 7, "x": round(gap * (i + 1) - 8), "y": 4, "radius": 999,
             "fill": CREAM, "stroke": {"hex": INK, "opacity": 0.35}, "strokeW": 1} for i in range(n)]


def check_badge(cx, cy, d=46):
    tick = (f'<svg width="{d}" height="{d}" viewBox="0 0 46 46" xmlns="http://www.w3.org/2000/svg">'
            f'<circle cx="23" cy="23" r="21" fill="#{MINT}" stroke="#{MINT_LIP}" stroke-width="3"/>'
            '<path d="M13 23.5l6.5 6.5L33 16" stroke="#FFFFFF" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>')
    return {"type": "SVG", "name": "ClaimedCheck", "svg": tick, "w": d, "h": d, "x": cx - d // 2, "y": cy - d // 2}


def day_card(day, key, amount, state, w=134, h=148):
    head = SKY if state != "today" else CORAL
    kids = [
        {"name": "HeaderTab", "w": w, "h": 34, "x": 0, "y": 0, "fill": head, "children": pegs(w) + [
            txt(f"Day {day}", 16, "FFFFFF", name="DayLabel", x=0, y=10, w=w, align="CENTER")]},
        {"type": "RECT", "name": "Img " + key, "w": 52, "h": 52, "x": (w - 52) // 2, "y": 46},
        txt(amount, 13, INK, name="Amount", x=0, y=104, w=w, align="CENTER"),
    ]
    if state == "today":
        kids.append({"name": "ReadyBadge", "layout": "H", "pad": [2, 10, 3, 10], "radius": 999, "fill": CORAL, "x": w // 2 - 28, "y": 124,
                     "children": [txt("READY", 11, "FFFFFF", font=NUN, name="TagText")]})
    if state == "claimed":
        kids += [{"type": "RECT", "name": "ClaimedOverlay", "w": w, "h": h, "x": 0, "y": 0, "radius": 18, "fill": {"hex": INK, "opacity": 0.5}},
                 check_badge(w // 2, 76)]
    return {"name": f"Day {day} reward", "w": w, "h": h, "radius": 18, "clip": True, "fill": CREAM,
            "stroke": CORAL if state == "today" else SAND_LINE, "strokeW": 3 if state == "today" else 2, "children": kids}


def grand_card(w=270, h=306):
    return {"name": "Day 7 reward", "w": w, "h": h, "radius": 18, "clip": True, "fill": CREAM, "stroke": GOLD, "strokeW": 2, "children": [
        {"name": "HeaderTab", "w": w, "h": 40, "x": 0, "y": 0, "fill": GOLD, "children": pegs(w, 3) + [
            txt("Day 7", 18, "FFFFFF", name="DayLabel", x=0, y=12, w=w, align="CENTER")]},
        {"name": "GrandPill", "layout": "H", "pad": [3, 12, 4, 12], "radius": 999, "fill": "FBEAB8", "stroke": GOLD_LIP, "strokeW": 1.5, "x": w // 2 - 58, "y": 60,
         "children": [txt("GRAND REWARD", 11, GOLD_LIP, font=NUN, name="GrandText")]},
        {"type": "RECT", "name": "Img ui/status/gem", "w": 96, "h": 96, "x": (w - 96) // 2, "y": 104},
        txt("50 Gems", 26, GOLD_LIP, name="Reward amount", x=0, y=214, w=w, align="CENTER")]}


def build():
    ops = [{"replaceId": rid, "tree": day_card(day, key, amount, state)} for rid, day, key, amount, state in DAYS]
    ops.append({"replaceId": "3794:1836", "tree": grand_card()})
    return ops


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "37_daily_b_calendar_ops.json")
    with open(p, "w", encoding="utf-8") as fh:
        json.dump(build(), fh, ensure_ascii=False, indent=1)
    print("wrote", p)
