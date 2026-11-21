"""Aura Gacha — 4 reveal concepts as animation storyboards (Figma Section on page Out Space).

Run:  python -I docs/figma/aura_gacha.py docs/figma/out
Send: figma-run.mjs --channel=aura-fishing build_tree docs/figma/out/16_aura_gacha.json
Then: python -I tools/art/figma_images.py --root <rootId>
"""
import importlib.util
import json
import math
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
img, text, v, BORDER, SOFT, ftxt, btn, tag, small_pill, PAGE_ID = (m.img, m.text, m.v, m.BORDER, m.SOFT, m.ftxt, m.btn, m.tag, m.small_pill, m.PAGE_ID)

FW, FH = 384, 216  # storyboard frame (16:9)
RAR = {"Common": "9AA5B1", "Rare": "5AA9F0", "Epic": "B07CF0", "Legendary": "F2A93B", "Mythic": "F2668B"}


# ------------------------------------------------------------------ fx helpers
def svg(w, h, body, name, **kw):
    d = {"type": "SVG", "name": name, "w": w, "h": h, "svg": f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg">{body}</svg>'}
    d.update(kw)
    return d


def rays(size, color, n=14, opacity=0.35, name="Rays", **kw):
    c = size / 2
    body = ""
    for i in range(n):
        a0 = 2 * math.pi * i / n
        a1 = a0 + math.pi / n * 0.55
        x0, y0 = c + c * math.cos(a0), c + c * math.sin(a0)
        x1, y1 = c + c * math.cos(a1), c + c * math.sin(a1)
        body += f'<path d="M{c:.0f} {c:.0f} L{x0:.0f} {y0:.0f} L{x1:.0f} {y1:.0f}Z" fill="#{color}" fill-opacity="{opacity}"/>'
    return svg(size, size, body, name, **kw)


def glow(color, d, x, y, a=0.8, name="Glow"):
    return {"type": "ELLIPSE", "name": name, "w": d, "h": d, "x": x, "y": y, "fill": {"hex": color, "opacity": 0.55}, "effects": [{"color": color, "a": a, "blur": d * 0.6}]}


def cracks(size, color="FFFFFF", name="Cracks", **kw):
    c = size / 2
    body = "".join(f'<polyline points="{p}" stroke="#{color}" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' for p in [
        f"{c},{c} {c - 10},{c - 18} {c - 4},{c - 30} {c - 14},{c - 44}",
        f"{c},{c} {c + 14},{c - 8} {c + 22},{c + 6} {c + 38},{c + 2}",
        f"{c},{c} {c + 4},{c + 18} {c - 8},{c + 30} {c - 2},{c + 42}"])
    return svg(size, size, body, name, **kw)


def sparkles(points, size=18):
    return [img("auras/fx_sparkle", size, x=x, y=y) for x, y in points]


def confetti(points):
    cols = ["FF9E80", "7FD3B0", "9AD4F5", "F2B544", "B79CF2"]
    return [{"type": "RECT", "name": "Confetti", "w": 6, "h": 10, "x": x, "y": y, "radius": 2, "fill": cols[i % 5]} for i, (x, y) in enumerate(points)]


def frame(name, kids, dark=True):
    bg = {"grad": ["3A3466", "1A2140"], "angle": 90} if dark else {"grad": ["DDF5EE", "A8DCD8"], "angle": 90}
    return {"name": name, "w": FW, "h": FH, "radius": 16, "clip": True, "fill": bg, "children": kids}


def white_title(t, size=22, **kw):
    return ftxt(t, size, "FFFFFF", name="Title", textStroke="3D4B5C", textStrokeW=2, **kw)


def center(child, w, y):
    return {"name": "Center", "layout": "H", "w": FW, "x": 0, "y": y, "main": "CENTER", "children": [child]} if w else child


def roll_buttons(y=162):
    return {"name": "Roll Buttons", "layout": "H", "gap": 8, "w": FW, "x": 0, "y": y, "main": "CENTER", "children": [
        btn("Gem", "ROLL x1  5", "Btn Roll 1"), btn("Gold", "x10  45", "Btn Roll 10")]}


def pity(y=136, value="Mythic pity  37 / 90"):
    return {"name": "Pity", "layout": "H", "w": FW, "x": 0, "y": y, "main": "CENTER", "children": [
        {"name": "Pill", "layout": "H", "gap": 6, "pad": [3, 10, 3, 6], "radius": 999, "fill": {"hex": "FFFFFF", "opacity": 0.85}, "cross": "CENTER",
         "children": [img("auras/fx_sparkle", 14), text(value, "Caption", "cozy/text", name="Value")]}]}


def reveal(aura="NeonWave", name="NEON WAVE", rarity="Rare", chance="1 in 100", is_new=True):
    col = RAR[rarity]
    kids = [rays(300, col, 16, 0.3, x=42, y=-50), glow(col, 120, 132, 30), img("auras/" + aura, 96, x=144, y=36)]
    kids += sparkles([(70, 30), (300, 50), (90, 120), (290, 120), (190, 14)])
    kids += [{"name": "Name Row", "layout": "V", "gap": 2, "w": FW, "x": 0, "y": 136, "cross": "CENTER", "children": [
        white_title(name, 22), {"name": "Tags", "layout": "H", "gap": 6, "children": [tag(rarity), text(chance, "Caption", "cozy/on-accent", name="Chance")]
                               + ([small_pill("NEW!", "cozy/coral", "New")] if is_new else [])}]},
             {"name": "Buttons", "layout": "H", "gap": 8, "w": FW, "x": 0, "y": 188, "main": "CENTER", "children": []}]
    return kids


def step(title, timing, notes, fr):
    return {"name": "Step " + title, "layout": "V", "gap": 6, "w": FW, "children": [
        fr, {"name": "Caption", "layout": "H", "gap": 6, "cross": "CENTER", "children": [
            text(title, "Heading", name="Step"), small_pill(timing, "cozy/sky-lip", "Timing")]},
        text(notes, "Small", "cozy/subtext", name="Notes", w=FW)]}


# ------------------------------------------------------------------ concept A: Crystal Orb Crack
def concept_a():
    s1 = frame("Idle", [{"type": "RECT", "name": "Pedestal", "w": 120, "h": 26, "x": 132, "y": 112, "radius": 13, "fill": {"hex": "B79CF2", "opacity": 0.6}},
                        glow("B79CF2", 90, 147, 30, 0.5), img("auras/UnknownAura", 84, x=150, y=34), pity(), roll_buttons()])
    s2 = frame("Charge", [{"type": "RECT", "name": "Vignette", "w": FW, "h": FH, "x": 0, "y": 0, "fill": {"hex": "000000", "opacity": 0.25}},
                          glow("FFFFFF", 150, 117, 33, 0.6), img("auras/UnknownAura", 120, x=132, y=48),
                          *[{"type": "RECT", "name": "Shake", "w": 3, "h": 16, "x": x, "y": y, "radius": 2, "fill": {"hex": "FFFFFF", "opacity": 0.7}} for x, y in [(118, 90), (124, 120), (262, 92), (256, 122)]],
                          center(white_title("...", 20), 1, 176)])
    s3 = frame("Tease", [rays(260, RAR["Epic"], 12, 0.35, x=62, y=-22), glow(RAR["Epic"], 150, 117, 33, 0.9), img("auras/UnknownAura", 120, x=132, y=48),
                         cracks(120, "FFFFFF", x=132, y=48),
                         {"name": "Ladder", "layout": "H", "gap": 4, "x": 120, "y": 186, "children": [
                             {"type": "ELLIPSE", "name": "Tier", "w": 14, "h": 14, "fill": RAR[r] if i <= 2 else {"hex": "FFFFFF", "opacity": 0.25}} for i, r in enumerate(["Common", "Rare", "Epic", "Legendary", "Mythic"])]}])
    s4 = frame("Burst", [rays(420, "FFFFFF", 18, 0.5, x=-18, y=-102), {"type": "RECT", "name": "Flash", "w": FW, "h": FH, "x": 0, "y": 0, "fill": {"hex": "FFFFFF", "opacity": 0.75}},
                         glow(RAR["Epic"], 180, 102, 18, 1), *confetti([(40, 30), (90, 160), (320, 40), (300, 170), (200, 20), (150, 190), (60, 100), (340, 110)])])
    s5 = frame("Reveal", reveal("SolarFlare", "SOLAR FLARE", "Epic", "1 in 750"))
    return ("A", "Crystal Orb Crack", "Orb on an altar charges, cracks, leaks light in the rolled rarity's colour, then bursts. Classic, clear, works for x1 and x10 (x10 = 10 small orbs crack in a row).",
            [step("1 Idle", "loop", "Mystery orb floats on the altar (bob 4px, 2s loop). Pity pill shows progress to a guaranteed Mythic. ROLL x1 / x10.", s1),
             step("2 Charge", "0.0-0.8s", "Screen dims, orb scales 1.0 -> 1.4 with ease-in, shakes harder each 0.2s. SFX: rising hum. Mobile: light haptic ticks.", s2),
             step("3 Tease", "0.8-1.6s", "Cracks appear; glow steps up the rarity ladder (white -> blue -> purple ...) and STOPS at the rolled tier. Each step +pitch.", s3),
             step("4 Burst", "1.6-2.0s", "White flash 0.1s, rays + confetti burst, orb shards fly. Epic+: 0.3s slow-mo. Mythic: screen shake + rainbow flash.", s4),
             step("5 Reveal", "2.0s+", "Aura orb pops in (overshoot scale 1.2 -> 1.0), rotating rays, name + tag + chance + NEW!. Buttons: EQUIP / ROLL AGAIN.", s5)])


# ------------------------------------------------------------------ concept B: Reel Slot
def slot_window(orbs, y0=0, blur=False, frame_col="F2B544"):
    kids = []
    for i, (a, dy) in enumerate(orbs):
        kids.append(img("auras/" + a, 64, x=28, y=y0 + dy, opacity=0.45 if blur else 1))
    kids.append({"type": "RECT", "name": "Center Line", "w": 120, "h": 4, "x": 0, "y": 74, "fill": {"hex": "FFFFFF", "opacity": 0.6}})
    return {"name": "Reel", "w": 120, "h": 150, "x": 132, "y": 18, "radius": 22, "clip": True, "fill": {"grad": ["FFF8EC", "F3E9D8"], "angle": 90},
            "stroke": frame_col, "strokeW": 4, "children": kids}


def concept_b():
    s1 = frame("Pull", [slot_window([("SparklingDew", -30), ("UnknownAura", 44), ("NeonWave", 118)]),
                        img("equipment/BambooRod", 70, x=262, y=40), roll_buttons(176)], dark=False)
    s2 = frame("Spin", [slot_window([("NeonWave", -20), ("SolarFlare", 20), ("SparklingDew", 60), ("AbyssalShadow", 100)], blur=True),
                        *[{"type": "RECT", "name": "Speed Line", "w": 4, "h": 40, "x": x, "y": 40, "radius": 2, "fill": {"hex": "FFFFFF", "opacity": 0.5}} for x in [110, 270]],
                        center(white_title("SPINNING!", 18), 1, 180)], dark=False)
    s3 = frame("Near miss", [glow(RAR["Legendary"], 160, 112, 13, 0.7), slot_window([("DragonEmperor", 10), ("SolarFlare", 86)], frame_col=RAR["Legendary"]),
                             {"type": "SVG", "name": "Arrow", "w": 20, "h": 20, "x": 106, "y": 84,
                              "svg": '<svg width="20" height="20" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M2 2L18 10L2 18Z" fill="#FFFFFF"/></svg>'},
                             center(white_title("so close...", 18), 1, 180)])
    s4 = frame("Lock", [rays(300, RAR["Epic"], 14, 0.35, x=42, y=-50), slot_window([("SolarFlare", 44)], frame_col=RAR["Epic"]),
                        *confetti([(40, 40), (330, 50), (70, 170), (300, 160), (190, 190), (20, 120)])])
    s5 = frame("Reveal", reveal("SolarFlare", "SOLAR FLARE", "Epic", "1 in 750"))
    return ("B", "Reel Slot  (CHOSEN, in code: UI/AuraReel)", "A slot-machine reel of aura orbs, pulled like a fishing reel. Speed blur, slows down, near-misses on rarer orbs, then locks. Strong 'one more spin' pull.",
            [step("1 Pull", "loop", "Reel shows 3 orbs. Pressing ROLL 'casts' the rod lever; the reel jerks up first (anticipation 0.15s).", s1),
             step("2 Spin", "0.0-1.0s", "Reel spins fast (motion blur via faded copies). SFX: reel clicking, tick rate follows speed.", s2),
             step("3 Near miss", "1.0-2.2s", "Slows with ease-out. A rarer orb drifts past the centre line first ('so close...'). Frame tint hints at the final tier.", s3),
             step("4 Lock", "2.2-2.5s", "Snaps onto the result, frame flashes rarity colour, confetti. SFX: ka-ching. Haptic: medium.", s4),
             step("5 Reveal", "2.5s+", "Same reveal card as all concepts (rays, name, tag, chance, NEW!). x10: 10 reels stop left -> right.", s5)])


# ------------------------------------------------------------------ concept C: Lucky Bobber
def pond(kids):
    water = [{"type": "RECT", "name": "Water", "w": FW, "h": 100, "x": 0, "y": 116, "fill": {"grad": ["9AD4F5", "5A9BD0"], "angle": 90}}]
    return frame("Pond", water + kids, dark=False)


def ripple(d, x, y, color="FFFFFF", a=0.8):
    return {"type": "ELLIPSE", "name": "Ripple", "w": d, "h": d * 0.3, "x": x, "y": y, "stroke": {"hex": color, "opacity": a}, "strokeW": 3}


def concept_c():
    s1 = pond([{"type": "SVG", "name": "Arc", "w": 220, "h": 90, "x": 60, "y": 20,
                "svg": '<svg width="220" height="90" viewBox="0 0 220 90" xmlns="http://www.w3.org/2000/svg"><path d="M5 85 Q110 -20 215 80" stroke="#FFFFFF" stroke-width="3" stroke-dasharray="6 8" fill="none"/></svg>'},
               img("ui/status/bobber", 34, x=250, y=70), roll_buttons(176)])
    s2 = pond([ripple(70, 157, 128), ripple(120, 132, 122, a=0.5), img("ui/status/bobber", 34, x=175, y=112), center(white_title("...", 20), 1, 30)])
    s3 = pond([glow(RAR["Epic"], 160, 112, 80, 0.9), ripple(90, 147, 126, RAR["Rare"]), ripple(150, 117, 118, RAR["Epic"]), ripple(210, 87, 110, RAR["Epic"], 0.5),
               img("ui/status/bobber", 34, x=175, y=112), center(white_title("Something's glowing!", 16), 1, 30)])
    s4 = pond([*[{"type": "ELLIPSE", "name": "Splash", "w": d, "h": d, "x": x, "y": y, "fill": {"hex": "FFFFFF", "opacity": 0.85}} for d, x, y in
                 [(30, 150, 90), (22, 210, 80), (16, 130, 70), (26, 190, 60), (14, 230, 100)]],
               glow(RAR["Epic"], 140, 122, 10, 1), img("auras/SolarFlare", 90, x=147, y=34), *sparkles([(100, 30), (280, 40), (120, 110), (260, 100)])])
    s5 = frame("Reveal", reveal("SolarFlare", "SOLAR FLARE", "Epic", "1 in 750"))
    return ("C", "Lucky Bobber", "Most on-theme: you CAST for your aura. Ripples change colour as the rarity climbs, then the aura bursts out of the water. Reuses fishing sounds players already know.",
            [step("1 Cast", "0.0-0.6s", "ROLL throws a bobber along a dotted arc into the altar pond. SFX: the normal cast whoosh + plop.", s1),
             step("2 Wait", "0.6-1.2s", "Bobber bobs, white ripples. Tiny pause builds tension (like waiting for a bite).", s2),
             step("3 Glow", "1.2-2.0s", "Ripples tint up the ladder (white -> blue -> purple ...), water glows from below. Legendary+: water turns gold, fish jump.", s3),
             step("4 Splash", "2.0-2.4s", "Big splash, aura orb rises out of the water with sparkles. SFX: splash + choir 'aah' for Epic+.", s4),
             step("5 Reveal", "2.4s+", "Shared reveal card. x10: ten bobbers land in a row, each splashes in turn (skip after the first).", s5)])


# ------------------------------------------------------------------ concept D: Shell Pack (x10)
def card(rarity, face_up=False, aura=None, x=0, y=0, w=52, h=70, glowing=False):
    col = RAR[rarity]
    kids = [img("auras/" + aura, 40, x=6, y=14)] if face_up and aura else [img("auras/fx_sparkle", 22, x=15, y=24)]
    d = {"name": "Card " + rarity, "w": w, "h": h, "x": x, "y": y, "radius": 10, "clip": True,
         "fill": "FFF8EC" if face_up else {"grad": ["9AD4F5", "B79CF2"], "angle": 90}, "stroke": col if (glowing or face_up) else "FFFFFF", "strokeW": 3, "children": kids}
    if glowing:
        d["effects"] = [{"color": col, "a": 0.9, "blur": 14}]
    return d


def concept_d():
    pack = {"name": "Pack", "w": 120, "h": 150, "x": 132, "y": 16, "radius": 20, "fill": {"grad": ["FFB59F", "B79CF2"], "angle": 90}, "stroke": "FFFFFF", "strokeW": 4,
            "effects": [{"color": "B79CF2", "a": 0.7, "blur": 24}], "children": [
                img("auras/UnknownAura", 70, x=25, y=22), {"name": "Label", "layout": "H", "w": 120, "x": 0, "y": 104, "main": "CENTER",
                                                          "children": [white_title("x10", 26)]}]}
    s1 = frame("Pack", [glow("B79CF2", 170, 107, 6, 0.5), pack, center(white_title("TAP TO OPEN", 16), 1, 184)])
    torn = dict(pack, children=pack["children"] + [{"type": "RECT", "name": "Seam Light", "w": 120, "h": 10, "x": 0, "y": 40, "fill": "FFFFFF",
                                                     "effects": [{"color": "FFFFFF", "a": 1, "blur": 18}]}])
    s2 = frame("Tear", [rays(300, "FFFFFF", 14, 0.3, x=42, y=-60), torn, center(white_title("swipe!", 16), 1, 184)])
    rs = ["Common", "Rare", "Common", "Common", "Epic", "Common", "Rare", "Common", "Legendary", "Common"]
    s3 = frame("Fan", [glow(RAR["Legendary"], 90, 268, 92, 0.7)] + [card(r, x=46 + (i % 5) * 60, y=24 + (i // 5) * 84, glowing=(r != "Common")) for i, r in enumerate(rs)])
    auras = {"Common": "SparklingDew", "Rare": "NeonWave", "Epic": "SolarFlare", "Legendary": "DragonEmperor"}
    s4 = frame("Flip", [card(r, face_up=i < 5, aura=auras[r], x=46 + (i % 5) * 60, y=24 + (i // 5) * 84, glowing=(i == 4)) for i, r in enumerate(rs)]
               + [{"name": "Skip", "layout": "H", "w": FW, "x": 0, "y": 190, "main": "MAX", "pad": [0, 10, 0, 0], "children": [small_pill("SKIP >>", "cozy/subtext", "Btn Skip")]}])
    s5 = frame("Summary", [rays(220, RAR["Legendary"], 12, 0.3, x=200, y=-10)] + [card(r, face_up=True, aura=auras[r], x=20 + (i % 5) * 50, y=40 + (i // 5) * 74, w=44, h=64,
                                                                                    glowing=(r == "Legendary")) for i, r in enumerate(rs)]
               + [img("auras/DragonEmperor", 80, x=278, y=40), center(white_title("DRAGON EMPEROR!", 16), 1, 8),
                  {"name": "Buttons", "layout": "H", "gap": 8, "x": 260, "y": 150, "children": [small_pill("EQUIP BEST", "cozy/coral", "Btn Equip Best")]}])
    return ("D", "Shell Pack (x10)", "Built for multi-rolls: open a pack, 10 cards fan out face-down with rarity-coloured edges (you SEE a gold edge before it flips), flip one by one, summary grid.",
            [step("1 Pack", "loop", "A glowing x10 pack wobbles. TAP or swipe to open. Single rolls use a 1-card pack with the same flow.", s1),
             step("2 Tear", "0.0-0.5s", "Swipe tears the seam, light leaks out, pack shakes. SFX: paper rip + sparkle. Haptic: medium.", s2),
             step("3 Fan", "0.5-1.2s", "10 cards fly out face-down. Edge glow = rarity (the dopamine tease: you spot the GOLD one first).", s3),
             step("4 Flip", "1.2s+", "Auto-flip left -> right 0.15s each; commons flip fast, Epic+ pause and burst. SKIP jumps to the summary.", s4),
             step("5 Summary", "end", "Grid of all 10, best one big on the right with rays. EQUIP BEST / ROLL x10 AGAIN.", s5)])


LADDER = [("Common", "1.2s total, no burst, soft 'pop'"), ("Rare", "+blue rays, chime"), ("Epic", "+purple cracks/ripples, 0.3s slow-mo, haptic"),
          ("Legendary", "+gold full-screen rays, choir, longer tease"), ("Mythic", "+black-out then rainbow, screen shake, SERVER-WIDE toast 'X rolled Dragon Emperor!'")]


def build():
    concepts = [concept_a(), concept_b(), concept_c(), concept_d()]
    rows = []
    for key, title, desc, steps in concepts:
        rows.append({"name": f"Concept {key} — {title}", "layout": "V", "gap": 16, "pad": 28, "radius": 28, "fill": v("cozy/panel"), **BORDER, "effects": SOFT,
                     "children": [{"name": "Head", "layout": "V", "gap": 4, "children": [text(f"{key}. {title}", "Title", name="Title"),
                                                                                      text(desc, "Body", "cozy/subtext", name="Desc", w=2040)]},
                                  {"name": "Storyboard", "layout": "H", "gap": 24, "children": steps}]})
    ladder = {"name": "Rarity Escalation", "layout": "V", "gap": 10, "pad": 28, "radius": 28, "fill": v("cozy/panel"), **BORDER, "children": [
        text("Rarity escalation (all concepts)", "Title", name="Title"),
        text("The higher the roll, the longer and louder the build-up. Players learn the colour ladder, so a purple flash = heart rate up.", "Body", "cozy/subtext", name="Desc", w=1200),
        {"name": "Ladder", "layout": "H", "gap": 12, "children": [
            {"name": "Tier " + r, "layout": "V", "gap": 6, "pad": 14, "w": 230, "radius": 18, "fill": v("cozy/sand"), "children": [
                tag(r if r != "Mythic" else "Mythic"), text(n, "Small", "cozy/text", name="Rule", w=200)]} for r, n in LADDER]},
        text("Retention extras: Mythic pity counter (shown on the altar) • x10 = 10% discount • SKIP after first view • Auto-roll until Epic+ • 'NEW!' for first-time auras",
             "Small", "cozy/subtext", name="Extras", w=1200)]}
    sec = {"type": "SECTION", "name": "Aura Gacha · 4 concepts", "fill": "F3E9D8", "x": 8900, "y": 4600, "children": [
        text("Aura Gacha — 4 reveal concepts (storyboards)", "Display", name="Title", x=60, y=40),
        text("Each row = one concept, 5 key frames left -> right with timing and animation/SFX notes. Pick one (or mix), then I build it in code.",
             "Body", "cozy/subtext", name="Sub", x=60, y=96, w=2000),
        {"name": "Concepts", "layout": "V", "gap": 40, "x": 60, "y": 150, "children": [ladder] + rows}]}
    return {"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    json.dump(build(), open(os.path.join(out, "16_aura_gacha.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("written")
