"""Aura Card — one component set used everywhere an aura is shown, plus targeted patches.

Phase 1:  python -I docs/figma/aura_card.py docs/figma/out component
          build_tree out/19_aura_card_component.json   -> refs.auracard = component set id
Phase 2:  python -I docs/figma/aura_card.py docs/figma/out patches <setId>
          writes out/20_patch_*.json (each replaces ONE node in place via replaceId; nothing else is rebuilt)
Images:   python -I tools/art/figma_images.py --root ...   (instances named "... {img:auras/X}" get that orb)
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_s = importlib.util.spec_from_file_location("menus", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_s)
_s.loader.exec_module(m)
img, text, v, BORDER, SOFT, ftxt, btn, tag, PAGE_ID = m.img, m.text, m.v, m.BORDER, m.SOFT, m.ftxt, m.btn, m.tag, m.PAGE_ID

COMPONENTS_BOARD = "3487:4280"
RAR = {"Common": "9AA5B1", "Rare": "5AA9F0", "Epic": "B07CF0", "Legendary": "F2A93B", "Mythic": "F2668B"}
SAMPLE = {"Common": ("SparklingDew", "Sparkling Dew", "1/10", ["+5% Luck"]),
          "Rare": ("NeonWave", "Neon Wave", "1/100", ["+15% Luck", "+2% Catch Bar", "+3% Glowing"]),
          "Epic": ("SolarFlare", "Solar Flare", "1/750", ["+35% Luck", "+10% Sun-Forged"]),
          "Legendary": ("AbyssalShadow", "Abyssal Shadow", "1/5,000", ["+50% Luck", "+0.2 Auto Mult", "+3% Void-Touched"]),
          "Mythic": ("DragonEmperor", "Dragon Emperor", "1/50,000", ["+100% Luck", "+30% Stability", "+25% Golden"])}
MUT_COL = {"Glowing": "3CC4B0", "Sun-Forged": "F28C38", "Void-Touched": "8A5CC8", "Golden": "E0A82E"}


# ------------------------------------------------------------------ badges
def badge(t, fill=None, fg=None, name="Badge", text_name="Label"):
    """Small pill. Neutral = sand + slate text; coloured = white text."""
    return {"name": name, "layout": "H", "pad": [3, 10, 4, 10], "radius": 999, "fill": fill or v("cozy/sand"),
            "children": [dict(text(t, "Caption", fg or ("cozy/on-accent" if fill else "cozy/text"), name=text_name))]}


def stat_badge(t, i):
    col = next((c for k, c in MUT_COL.items() if k in t), None)
    return badge(t, col, name=f"Stat {i}", text_name=f"Stat {i}")


def badge_row(items, w=None, name="Badges", main="CENTER"):
    d = {"name": name, "layout": "H", "gap": 6, "cross": "CENTER", "main": main, "children": items}
    if w:
        d.update({"w": w, "wrap": True, "rowGap": 6})
    return d


def stat_slots(stats):
    slots = (stats + ["", "", ""])[:3]
    return [stat_badge(s or "+0% Stat", i + 1) for i, s in enumerate(slots)]


# ------------------------------------------------------------------ Aura Card variants
def card_large(r):
    aid, name, chance, stats = SAMPLE[r]
    return {"type": "COMPONENT", "name": f"Size=Large, Rarity={r}", "layout": "V", "gap": 8, "w": 336, "cross": "CENTER", "clip": False, "children": [
        {"name": "Orb", "w": 150, "h": 150, "clip": False, "children": [img("auras/" + aid, 140, x=5, y=5),
                                                                       dict(badge("NEW!", v("cozy/coral"), name="New Badge", text_name="New"), x=100, y=2)]},
        ftxt(name, 32, RAR[r], name="Name"),
        badge_row([tag(r), badge(chance, v("cozy/subtext"), name="Chance", text_name="Chance")], name="Tags"),
        badge_row(stat_slots(stats), w=336, name="Stats")]}


def card_row(r):
    aid, name, chance, stats = SAMPLE[r]
    return {"type": "COMPONENT", "name": f"Size=Row, Rarity={r}", "layout": "H", "gap": 12, "pad": 12, "w": 680, "h": 80, "radius": 16, "cross": "CENTER",
            "fill": v("cozy/sand"), "children": [
                img("auras/" + aid, 56),
                {"name": "Info", "layout": "V", "gap": 4, "fillW": True, "children": [
                    {"name": "Top", "layout": "H", "gap": 8, "cross": "CENTER", "children": [
                        ftxt(name, 20, RAR[r], name="Name"), tag(r), badge(chance, v("cozy/subtext"), name="Chance", text_name="Chance")]},
                    badge_row(stat_slots(stats), name="Stats", main="MIN")]},
                badge("x1", None, name="Status", text_name="Status")]}


def card_compact(r):
    aid, name, chance, stats = SAMPLE[r]
    return {"type": "COMPONENT", "name": f"Size=Compact, Rarity={r}", "layout": "V", "gap": 4, "pad": 10, "w": 120, "cross": "CENTER", "radius": 20,
            "fill": "FFFFFF", **BORDER, "clip": False, "children": [
                img("auras/" + aid, 72), tag(r),
                dict(badge("NEW!", v("cozy/coral"), name="New Badge", text_name="New"), absolute=True, x=66, y=-8)]}


def component_group():
    variants = [f(r) for f in (card_large, card_row, card_compact) for r in RAR]
    return {"parentId": COMPONENTS_BOARD, "replaceName": "Aura Card Group", "tree": {"name": "Aura Card Group", "layout": "V", "gap": 12, "children": [
        text("Aura Card — Size (Large / Row / Compact) × Rarity. Use instances everywhere an aura is shown.", "Heading", "cozy/subtext", name="Aura Card Label"),
        {"type": "VARIANTS", "key": "auracard", "name": "Aura Card", "layout": "H", "gap": 28, "pad": 24, "setRadius": 16,
         "w": 2400, "setFill": "FBF7EF",
         "description": "Standard aura display. Overrides: Name, Chance, Stat 1-3, Status, New; hide unused Stat slots / New Badge. "
                        "Orb image: name the instance '... {img:auras/<Id>}' and run tools/art/figma_images.py.",
         "children": variants}]}}


# ------------------------------------------------------------------ instances + patches
def aura_inst(set_id, size, r, aura_id, name, chance, stats, status=None, is_new=False, **kw):
    texts = {"Name": name, "Chance": chance}
    hide = []
    for i in range(3):
        if i < len(stats):
            texts[f"Stat {i + 1}"] = stats[i]
        else:
            hide.append(f"Stat {i + 1}")
    if status is not None:
        texts["Status"] = status
    if size != "Row" and not is_new:
        hide.append("New Badge")
    d = {"type": "INSTANCE", "ref": set_id, "variant": f"Size={size}, Rarity={r}", "name": f"Aura Card {{img:auras/{aura_id}}}", "texts": texts, "hide": hide}
    d.update(kw)
    return d


def patches(set_id):
    out = {}
    # 1) Gacha Reveal Card component: Orb -> Aura Card Large; Name/Tags/Stats removed
    out["reveal"] = [{"replaceId": "3492:20596", "tree": aura_inst(set_id, "Large", "Epic", "SolarFlare", "Solar Flare", "1/750", ["+35% Luck", "+10% Sun-Forged"], is_new=True)},
                     {"remove": ["3492:20600", "3492:20601", "3492:20606"]}]
    # 2) 08 Roll Result modal: image -> Aura Card Large; Name/Tags/Stats removed
    out["roll"] = [{"replaceId": "3492:17113", "tree": aura_inst(set_id, "Large", "Rare", "NeonWave", "Neon Wave", "1/100", ["+15% Luck", "+2% Catch Bar", "+3% Glowing"], is_new=True)},
                   {"remove": ["3492:17114", "3492:17115", "3492:17119"]}]
    # 3) 07 Auras window (built by script, not hand-edited): equipped card + list rows use Aura Card Row
    top = {"name": "Top", "layout": "H", "gap": 12, "fillW": True, "children": [btn("Gem", "ROLL AURA  (5 Gems)", "Btn Roll", fillW=True), btn("Ghost", "Low FX: OFF", "Btn LowFX")]}
    equipped = aura_inst(set_id, "Row", "Rare", "NeonWave", "Neon Wave", "1/100", ["+15% Luck", "+2% Catch Bar", "+3% Glowing"], status="EQUIPPED", fillW=True)

    def list_row(r, aid, nm, ch, st, owned, action):
        # one container: the Aura Card Row (its own background made transparent) + the action button INSIDE the card
        card = aura_inst(set_id, "Row", r, aid, nm, ch, st, status=owned, fillW=True)
        card["fill"] = None
        return {"name": "Row " + nm, "layout": "H", "gap": 0, "pad": [0, 12, 0, 0], "cross": "CENTER", "fillW": True, "h": m.ROW_H, "radius": 16,
                "fill": v("cozy/sand"), "clip": True, "children": [card] + ([action] if action else [])}
    rows = [list_row("Common", "SparklingDew", "Sparkling Dew", "1/10", ["+5% Luck"], "x3", btn("Secondary", "Equip", "Btn Equip")),
            list_row("Rare", "NeonWave", "Neon Wave", "1/100", ["+15% Luck", "+2% Catch Bar"], "x1", btn("Success", "Unequip", "Btn Equip")),
            list_row("Epic", "UnknownAura", "???", "1/750", [], "-", None)]
    lst = {"name": "List (max 3)", "layout": "V", "gap": 10, "fillW": True, "h": 3 * m.ROW_H + 20, "children": rows}
    pager = {"name": "Pager", "layout": "H", "gap": 10, "cross": "CENTER", "children": [btn("Ghost", "<", "Btn Page Prev"), ftxt("1 / 2", 18, "7A8A99", name="Page"),
                                                                                    btn("Ghost", ">", "Btn Page Next")]}
    foot = {"name": "Footer", "layout": "H", "fillW": True, "main": "SPACE_BETWEEN", "cross": "CENTER", "children": [
        pager, {"name": "Wallet", "layout": "H", "gap": 10, "children": [m.chip("Gems", "320")]}]}
    out["auras_list"] = [{"replaceId": "3492:21536", "tree": lst}]
    out["auras"] = [{"replaceId": "3492:21191", "tree": m.window("Auras", m.WIN_W, (m.W - m.WIN_W) // 2, m.SAFE_TOP, [top, equipped, lst, foot], h=m.WIN_H)}]
    # 4) G6 x10 grid -> Aura Card Compact instances
    res = [("Common", "SparklingDew"), ("Rare", "NeonWave"), ("Common", "SparklingDew"), ("Common", "SparklingDew"), ("Epic", "SolarFlare"),
           ("Common", "SparklingDew"), ("Rare", "NeonWave"), ("Common", "SparklingDew"), ("Legendary", "AbyssalShadow"), ("Common", "SparklingDew")]
    out["x10"] = [{"replaceId": "3492:21015", "tree": {"name": "Grid", "layout": "H", "wrap": True, "gap": 12, "rowGap": 16, "w": 712, "main": "CENTER", "clip": False,
                                                       "children": [aura_inst(set_id, "Compact", r, a, "", "", [], is_new=r in ("Epic", "Legendary")) for r, a in res]}}]
    # 5) 04 Catch Result: text lines -> badge rows
    out["catch"] = [
        {"replaceId": "3492:21670", "tree": badge_row([badge("4.2 kg"), badge("Manual", v("cozy/sky")), badge("PERFECT", v("cozy/gold"))], name="Meta")},
        {"replaceId": "3492:21679", "tree": badge_row([badge("Glowing x1.8", MUT_COL["Glowing"]), badge("Manual x1.5", v("cozy/sky")), badge("Perfect +0.25", v("cozy/gold"))],
                                                      name="Breakdown")}]
    # 6) 09 Fishdex window: fixed size + pager (8 per page)
    out["fishdex"] = [{"replaceId": "3492:21811", "tree": fishdex_window()}]
    return out


def fishdex_window():
    CARD_W, CARD_H = 228, 184   # fixed card size: 3 per row x 2 rows = 6 per page

    def card(f):
        name, rarity, depth, count, best, key = f
        known = name is not None
        return {"name": "Card " + (name or "Unknown"), "layout": "V", "gap": 6, "pad": 12, "w": CARD_W, "h": CARD_H, "radius": 18,
                "fill": v("cozy/panel" if known else "cozy/sand"), **BORDER, "children": [
                    {"name": "Picture", "w": CARD_W - 24, "h": 70, "radius": 12, "fill": "F4FAFD" if known else "EDE3D2", "clip": True, "children": [
                        img("fish/" + key, 96, 64, x=(CARD_W - 24 - 96) // 2, y=3, opacity=1 if known else 0.45)]},
                    text(name or "???", "Heading", "cozy/text" if known else "cozy/subtext", name="Name", w=CARD_W - 24),
                    badge_row([tag(rarity), badge(depth, v("cozy/sky"))], name="Where", main="MIN"),
                    badge_row([badge(f"Caught x{count}"), badge(f"Best {best} kg")] if known else [badge("Not caught yet")], name="Record", main="MIN")]}
    summary = {"name": "Summary", "layout": "H", "gap": 14, "cross": "CENTER", "fillW": True, "children": [
        text("Discovered 7 / 20", "Heading", name="Count"), m.progress("Progress", fillW=True)]}
    grid = {"name": "Grid (6 per page)", "layout": "H", "wrap": True, "gap": 12, "rowGap": 12, "fillW": True, "children": [card(f) for f in m.FISH[:6]]}
    pager = {"name": "Pager", "layout": "H", "gap": 10, "cross": "CENTER", "children": [btn("Ghost", "<", "Btn Page Prev"), ftxt("1 / 4", 18, "7A8A99", name="Page"),
                                                                                    btn("Ghost", ">", "Btn Page Next")]}
    foot = {"name": "Footer", "layout": "H", "fillW": True, "main": "CENTER", "cross": "CENTER", "children": [pager]}
    return m.window("Fishdex", m.WIN_W, (m.W - m.WIN_W) // 2, m.SAFE_TOP, [summary, grid, foot], h=m.WIN_H)


if __name__ == "__main__":
    out, mode = sys.argv[1], sys.argv[2]
    if mode == "component":
        json.dump(component_group(), open(os.path.join(out, "19_aura_card_component.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    else:
        for key, ops in patches(sys.argv[3]).items():
            json.dump(ops, open(os.path.join(out, f"20_patch_{key}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("written", mode)
