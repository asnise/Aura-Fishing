"""E0 · Events hub — the Events window is ONLY a hub of banner cards (Cozy Lake style).

Each card = art + title + subtitle + tag pill + (timer) + OPEN button. OPEN runs that event's action from
Config/Events.luau (gacha page like E1, a teleport, a menu ...); no event content is shown inline.
Layout: Events Window 920x540 (x 100, y 90; right edge 1020 = clear of the leaderboard), header like E1/G1,
2-column card grid (cards 430x176, gap 12/16), footer caption.

Run:   python -I docs/figma/events_hub.py docs/figma/out            (writes out/23_events_hub.json)
Send:  python -I docs/figma/events_hub.py docs/figma/out --send     (build_tree + image fills)
Re-running replaces the section by name; placed 200px right of the E1 section (event_banner.py), same y.
"""
import importlib.util
import json
import os
import subprocess
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("event_banner", os.path.join(_here, "event_banner.py"))
eb = importlib.util.module_from_spec(_s)
_s.loader.exec_module(eb)
m, g = eb.m, eb.g
img, text, v, BORDER, SOFT, ftxt, btn, small_pill, chip, screen, PAGE_ID, W, H = (
    m.img, m.text, m.v, m.BORDER, m.SOFT, m.ftxt, m.btn, m.small_pill, m.chip, m.screen, m.PAGE_ID, m.W, m.H)
RAR = m.RARITY_HEX

SECTION_NAME = "E0 · Events hub"
FRAME_NAME = "Events Hub"
SEC_X, SEC_Y = eb.SEC_X + (W + 120) + 200, eb.SEC_Y

# geometry
WIN_X, WIN_Y, WIN_W, WIN_H = 100, 90, 920, 540
PAD = 24
GRID_Y = 96
CARD_W, CARD_H = 430, 176
GAP_X, GAP_Y = WIN_W - 2 * PAD - 2 * CARD_W, 16      # 12, 16
ART = 140
TX = 14 + ART + 14                                   # text column x = 168
TW = CARD_W - TX - 14                                # text column w = 248

# id, title, subtitle, tag (label, fill) | None, timer | None, art (image, size, grad, ray colour), soon
EVENTS = [
    # subtitles: the " • " joins become a line break ("\n") so a 2-line subtitle never leaves an orphan word
    ("NeonTide", "Neon Tide Banner", "Neon Wave x2\nFeatured: Abyssal Shadow", ("LIMITED", "cozy/coral"), "13d 05h left",
     ("auras/AbyssalShadow", 118, ["E5DBFA", "D3ECFA"], RAR["Legendary"]), False),
    ("AuraAltar", "Aura Altar", "Standard aura roll\nMythic guaranteed every 100", None, None,
     ("ui/icons/auras", 104, ["E5DBFA", "FBD8E2"], RAR["Epic"]), False),
    ("NagaBoss", "Naga Boss", "Every 30 minutes\nTeam up to reel it in", ("SOON", "cozy/subtext"), None,
     ("fish/NagaHatchling", 112, ["D2F0E2", "D3ECFA"], RAR["Uncommon"]), True),
    ("DailyLogin", "Daily Login", "Gems and bait every day", ("SOON", "cozy/subtext"), None,
     ("ui/icons/quests", 100, ["FBEAB8", "FFDCCF"], RAR["Bait"]), True),
]


def card_timer(t):
    return {"name": "Timer", "layout": "H", "gap": 5, "pad": [5, 10, 5, 6], "radius": 999, "cross": "CENTER", "fill": "FFFFFF", **BORDER, "children": [
        img("ui/status/auto_timer", 18), ftxt(t, 14, "E07A5C", name="Value")]}


def art(path, size, grad, ray):
    c = ART // 2
    return {"name": "Art", "w": ART, "h": ART, "x": 14, "y": (CARD_H - ART) // 2, "radius": 18, "clip": True, "fill": {"grad": grad, "angle": 90}, **BORDER, "children": [
        g.rays(320, ray, 12, 0.16, x=c - 160, y=c - 160),
        {"type": "ELLIPSE", "name": "Glow", "w": 96, "h": 96, "x": c - 48, "y": c - 48, "fill": {"hex": ray, "opacity": 0.35},
         "effects": [{"color": ray, "a": 0.5, "blur": 40, "spread": 4}]},
        img(path, size, x=c - size // 2, y=c - size // 2)]}


def event_card(eid, title, sub, tag, timer, art_spec, soon, x, y):
    left = card_timer(timer) if timer else {"name": "Spacer", "w": 1, "h": 1}
    kids = [art(*art_spec)]
    if tag:
        p = small_pill(tag[0], tag[1], "Tag")
        p.update({"x": 22, "y": (CARD_H - ART) // 2 + 8})
        kids.append(p)
    kids += [
        ftxt(title, 22, "3D4B5C", name="Title", x=TX, y=20),
        text(sub, "Small", "cozy/subtext", name="Subtitle", w=TW, x=TX, y=52),
        {"name": "Bottom", "layout": "H", "w": TW, "h": 56, "x": TX, "y": CARD_H - 14 - 56, "main": "SPACE_BETWEEN", "cross": "CENTER", "clip": False,
         "children": [left, btn("Ghost", "SOON", "Btn Open") if soon else btn("Primary", "OPEN", "Btn Open")]}]
    d = {"name": "Event Card " + eid, "w": CARD_W, "h": CARD_H, "x": x, "y": y, "radius": 24, "clip": False,
         "fill": {"grad": ["FFFDF7", "F6F0FB"], "angle": 90}, **BORDER, "effects": [{"color": "3D4B5C", "a": 0.06, "y": 4, "blur": 12}], "children": kids}
    if soon:
        d["opacity"] = 0.55
    return d


def events_window():
    cards = [event_card(*e, x=(i % 2) * (CARD_W + GAP_X), y=(i // 2) * (CARD_H + GAP_Y)) for i, e in enumerate(EVENTS)]
    rows = (len(EVENTS) + 1) // 2
    grid_h = rows * CARD_H + (rows - 1) * GAP_Y
    return {"name": "Events Window", "w": WIN_W, "h": WIN_H, "x": WIN_X, "y": WIN_Y, "radius": 32, "fill": {"grad": ["FBF7EF", "EFE6F8"], "angle": 90}, **BORDER,
            "effects": SOFT, "clip": True, "children": [
                {"name": "Header", "layout": "H", "w": WIN_W - 2 * PAD, "x": PAD, "y": 20, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
                    {"name": "Title", "layout": "H", "gap": 10, "cross": "CENTER", "children": [img("ui/icons/events", 44), text("Events", "Display", name="Title")]},
                    {"name": "Right", "layout": "H", "gap": 10, "cross": "CENTER", "children": [chip("Gems", "320"), btn("Danger", "X", "Btn Close")]}]},
                {"name": "Card Grid", "w": WIN_W - 2 * PAD, "h": grid_h, "x": PAD, "y": GRID_Y, "clip": False, "children": cards},
                text("New events every week", "Caption", "cozy/subtext", name="Footer Hint", w=WIN_W - 2 * PAD, align="CENTER", x=PAD, y=GRID_Y + grid_h + 22)]}


NOTE = ("Hub only: each card's OPEN runs its action (gacha page / teleport / menu). Cards come from Config/Events.luau — add an entry to add a card. "
        "Neon Tide Banner opens the E1 gacha page; Aura Altar opens the standard gacha (G1). SOON cards are greyed (55%) with a disabled SOON button. "
        "LIMITED cards show a countdown and disappear when it ends.")


def build():
    fr = screen(FRAME_NAME, [g.dim(0.35), events_window()])
    fr.update({"x": 60, "y": 110})
    sec = {"type": "SECTION", "name": SECTION_NAME, "fill": "FBF7EF", "w": W + 120, "h": H + 260, "x": SEC_X, "y": SEC_Y, "children": [
        text(SECTION_NAME, "Display", name="Title", x=60, y=30), fr, text(NOTE, "Body", "cozy/subtext", name="Note", w=W, x=60, y=110 + H + 30)]}
    return {"pageId": PAGE_ID, "replaceName": SECTION_NAME, "tree": sec}


def send(spec):
    res = eb.call("build_tree", spec)
    root = res["rootId"]
    print("section", root)
    r = subprocess.run([sys.executable, "-I", os.path.join(eb.ROOT, "tools", "art", "figma_images.py"), "--channel", eb.CHANNEL, "--root", root],
                       capture_output=True, text=True, encoding="utf-8")
    print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else r.stderr)
    tree = eb.call("get_node_info", {"nodeId": root})
    frame = eb.find(tree, lambda n: n["name"] == FRAME_NAME)[0]
    print("frame", frame["id"])
    return root, frame["id"]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else os.path.join(_here, "out")
    spec = build()
    path = os.path.join(out, "23_events_hub.json")
    json.dump(spec, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("written", path)
    if "--send" in sys.argv:
        send(spec)
