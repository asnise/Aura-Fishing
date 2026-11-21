"""Generate 6 Aquarium Fish Card Remove button variants in Figma on page Out Space.
Run: python -I docs/figma/card_remove_variants.py docs/figma/out
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
v, text, BORDER, SOFT, PAGE_ID = m.v, m.text, m.BORDER, m.SOFT, m.PAGE_ID
img, ftxt = m.img, m.ftxt


def svgn(body, size, name, vb=48, **kw):
    d = {
        "type": "SVG",
        "svg": f'<svg width="{size}" height="{size}" viewBox="0 0 {vb} {vb}" fill="none" xmlns="http://www.w3.org/2000/svg">{body}</svg>',
        "w": size,
        "h": size,
        "name": name,
    }
    d.update(kw)
    return d

W_, H_ = 162, 176
WATER = {"grad": ["D3ECFA", "A9DCF7"], "angle": 90}
COL_RAR = "FFA94D"  # Legendary orange


def base_card(name, children, stroke=None, strokeW=2):
    b = {"stroke": stroke or v("cozy/track"), "strokeW": strokeW}
    return {
        "name": name,
        "w": W_,
        "h": H_,
        "radius": 18,
        "clip": True,
        "fill": "FFFFFF",
        **b,
        "children": children,
    }


def water_layer(mut_x=W_ - 32, mut_y=6, extra_water=None):
    kids = [
        {"type": "RECT", "name": "Water", "w": W_, "h": 118, "x": 0, "y": 0, "fill": WATER},
        {"type": "ELLIPSE", "name": "Bubble", "w": 10, "h": 10, "x": 18, "y": 22, "fill": {"hex": "FFFFFF", "opacity": 0.6}},
        {"type": "ELLIPSE", "name": "Bubble", "w": 6, "h": 6, "x": 30, "y": 42, "fill": {"hex": "FFFFFF", "opacity": 0.6}},
        img("fish/AncientCoelacanth", 96, x=33, y=12),
        dict(m.corner_svg(COL_RAR, 32)),
        img("fish/mut_golden", 26, x=mut_x, y=mut_y),
    ]
    if extra_water:
        kids.extend(extra_water)
    return kids


# --- OPTION 1: Top-Right Out Button ---
def opt1_card():
    # Minus button at top-right, mut badge shifted to left of it
    btn_minus = {
        "name": "Btn Remove",
        "w": 26,
        "h": 26,
        "x": W_ - 32,
        "y": 6,
        "radius": 999,
        "fill": "FFFFFF",
        **BORDER,
        "layout": "H",
        "main": "CENTER",
        "cross": "CENTER",
        "children": [svgn('<path d="M12 24h24" stroke="#E27D60" stroke-width="6" stroke-linecap="round"/>', 14, "Minus")],
    }
    w = water_layer(mut_x=W_ - 62, mut_y=6, extra_water=[btn_minus])
    bottom = [
        text("Ancient Coelacanth", "Heading", "cozy/text", name="FishName", x=12, y=124),
        {
            "name": "Rate",
            "layout": "H",
            "gap": 4,
            "pad": [3, 10, 3, 6],
            "radius": 999,
            "cross": "CENTER",
            "x": 10,
            "y": 146,
            "fill": v("cozy/sand"),
            "children": [img("ui/status/pearl", 16), text("+0.60/s", "Caption", "cozy/mint-lip", name="Value")],
        },
    ]
    return base_card("Card Option 1", w + bottom)


# --- OPTION 2: Completely Clean Card (Tap to View / Out in Detail Sheet) ---
def opt2_card():
    w = water_layer()
    bottom = [
        text("Ancient Coelacanth", "Heading", "cozy/text", name="FishName", x=12, y=124),
        {
            "name": "Rate",
            "layout": "H",
            "gap": 6,
            "pad": [3, 12, 3, 8],
            "radius": 999,
            "cross": "CENTER",
            "x": 10,
            "y": 146,
            "fill": v("cozy/sand"),
            "children": [img("ui/status/pearl", 16), text("+0.60/s", "Caption", "cozy/mint-lip", name="Value")],
        },
    ]
    return base_card("Card Option 2", w + bottom)


# --- OPTION 3: Selected State with Dual Action Bar ---
def opt3_card():
    w = water_layer()
    # When selected, bottom area has 2 compact action buttons
    btn_info = {
        "name": "Btn Info",
        "w": 68,
        "h": 26,
        "x": 10,
        "y": 144,
        "radius": 999,
        "fill": v("cozy/sand"),
        **BORDER,
        "layout": "H",
        "main": "CENTER",
        "cross": "CENTER",
        "children": [ftxt("INFO", 12, "7A8A99", name="Label")],
    }
    btn_out = {
        "name": "Btn Out",
        "w": 68,
        "h": 26,
        "x": 84,
        "y": 144,
        "radius": 999,
        "fill": v("cozy/coral"),
        "layout": "H",
        "main": "CENTER",
        "cross": "CENTER",
        "children": [ftxt("OUT", 12, "FFFFFF", name="Label")],
    }
    bottom = [
        text("Ancient Coelacanth", "Caption", "cozy/text", name="FishName", x=12, y=124),
        btn_info,
        btn_out,
    ]
    return base_card("Card Option 3", w + bottom, stroke={"hex": "7FD3B0"}, strokeW=3)


# --- OPTION 4: Tank Manage Mode (Batch / Jiggle Out) ---
def opt4_card():
    badge_out = {
        "name": "Badge Remove",
        "w": 28,
        "h": 28,
        "x": W_ - 34,
        "y": 6,
        "radius": 999,
        "fill": {"hex": "E27D60"},
        "stroke": "FFFFFF",
        "strokeW": 2,
        "layout": "H",
        "main": "CENTER",
        "cross": "CENTER",
        "children": [svgn('<path d="M12 24h24" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round"/>', 14, "Minus")],
    }
    w = water_layer(mut_x=W_ - 64, mut_y=6, extra_water=[badge_out])
    bottom = [
        text("Ancient Coelacanth", "Heading", "cozy/text", name="FishName", x=12, y=124),
        {
            "name": "Rate",
            "layout": "H",
            "gap": 4,
            "pad": [3, 10, 3, 6],
            "radius": 999,
            "cross": "CENTER",
            "x": 10,
            "y": 146,
            "fill": v("cozy/sand"),
            "children": [img("ui/status/pearl", 16), text("+0.60/s", "Caption", "cozy/mint-lip", name="Value")],
        },
    ]
    return base_card("Card Option 4", w + bottom)


# --- OPTION 5: Split Cozy Footer (Lip Button) ---
def opt5_card():
    w = water_layer()
    lip_btn_out = {
        "name": "Btn Out",
        "w": 42,
        "h": 26,
        "x": 110,
        "y": 144,
        "radius": 8,
        "fill": {"hex": "E27D60"},
        "layout": "H",
        "main": "CENTER",
        "cross": "CENTER",
        "children": [ftxt("OUT", 12, "FFFFFF", name="Label")],
    }
    bottom = [
        text("Ancient Coelacanth", "Heading", "cozy/text", name="FishName", x=12, y=124),
        {
            "name": "Rate",
            "layout": "H",
            "gap": 4,
            "pad": [3, 8, 3, 5],
            "radius": 999,
            "cross": "CENTER",
            "x": 10,
            "y": 144,
            "fill": v("cozy/sand"),
            "children": [img("ui/status/pearl", 16), text("+0.60/s", "Caption", "cozy/mint-lip", name="Value")],
        },
        lip_btn_out,
    ]
    return base_card("Card Option 5", w + bottom)


# --- OPTION 6: Bag / Return Icon with Confirm ---
def opt6_card():
    w = water_layer()
    btn_bag = {
        "name": "Btn Bag",
        "w": 28,
        "h": 28,
        "x": 124,
        "y": 142,
        "radius": 999,
        "fill": v("cozy/sand"),
        **BORDER,
        "layout": "H",
        "main": "CENTER",
        "cross": "CENTER",
        "children": [img("ui/icons/bag", 18)],
    }
    bottom = [
        text("Ancient...", "Heading", "cozy/text", name="FishName", x=12, y=124),
        {
            "name": "Rate",
            "layout": "H",
            "gap": 4,
            "pad": [3, 8, 3, 5],
            "radius": 999,
            "cross": "CENTER",
            "x": 10,
            "y": 144,
            "fill": "FFFFFF",
            "children": [img("ui/status/pearl", 16), text("+0.60/s", "Caption", "cozy/mint-lip", name="Value")],
        },
        btn_bag,
    ]
    return base_card("Card Option 6", w + bottom)


VARIANTS = [
    ("Option 1", "Top-Right Out Button", "ปุ่มลบย้ายไปมุมขวาบนในน้ำ พื้นที่ล่างโล่ง แสดงชื่อปลาได้เต็ม ไม่โดนตัด ...", opt1_card),
    ("Option 2", "Clean Card (Tap for Details)", "ไม่มีปุ่มบนการ์ดเลย การ์ดสวยสะอาด 100% แตะการ์ดเพื่อเปิดแผงรายละเอียดแล้วกด Return to Bag ปลอดภัยจากการเผลอกดผิด", opt2_card),
    ("Option 3", "Selected Action Bar", "แสดงปุ่มเมื่อแตะเลือกการ์ด (เส้นขอบสีเขียวมินต์) มีปุ่มคู่ INFO และ OUT ใช้งานง่าย กดแม่นยำ", opt3_card),
    ("Option 4", "Tank Manage Mode", "โหมดจัดตู้ปลา ปกติไม่มีปุ่ม แต่เมื่อกด Manage Tank จะขึ้นป้ายสีแดงให้แตะเอาออกทีละตัวหรือหลายตัวพร้อมกัน", opt4_card),
    ("Option 5", "Split Cozy Lip Button", "แบ่งแถบล่างเป็น 2 ฝั่งชัดเจน ซ้ายแสดงอัตรา ขวาเป็นปุ่มสี่เหลี่ยมมนสไตล์ Cozy Lake สลักคำว่า OUT ชัดเจน", opt5_card),
    ("Option 6", "Bag Icon with Confirm", "เปลี่ยนสัญลักษณ์ x เป็นไอคอนกระเป๋า สื่อว่าเป็นการเก็บกลับเข้ากระเป๋า พร้อมป๊อปอัปยืนยันสั้นๆ 1 จังหวะ", opt6_card),
]


def panel(key, title, desc, fn):
    return {
        "name": f"Variant {key} — {title}",
        "layout": "V",
        "gap": 14,
        "pad": 24,
        "w": 360,
        "radius": 24,
        "fill": v("cozy/panel"),
        **BORDER,
        "effects": SOFT,
        "children": [
            text(f"{key}: {title}", "Title", name="Title"),
            text(desc, "Small", "cozy/subtext", name="Desc", w=312),
            {"name": "CenterHolder", "layout": "H", "main": "CENTER", "fillW": True, "children": [fn()]},
        ],
    }


def build():
    cards = []
    for i, o in enumerate(VARIANTS):
        col, row = i % 3, i // 3
        c = panel(*o)
        c.update(x=60 + col * 400, y=160 + row * 380)
        cards.append(c)

    sec = {
        "type": "SECTION",
        "name": "Aquarium · Card Remove Variants (6 Options)",
        "fill": "FBF7EF",
        "x": 23000,
        "y": 2000,
        "children": [
            text("Aquarium — 6 Card Remove Variants to Choose", "Display", name="Title", x=60, y=40),
            text(
                "Compare 6 UX variations to solve the Aquarium fish remove button. No checkmarks, bullets, or emojis used.",
                "Body",
                "cozy/subtext",
                name="Sub",
                x=60,
                y=96,
                w=1200,
            ),
        ] + cards,
    }
    return [{"pageId": PAGE_ID, "replaceName": sec["name"], "tree": sec}]


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(_here, "out")
    os.makedirs(out, exist_ok=True)
    p = os.path.join(out, "23_card_variants_ops.json")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(build(), f, ensure_ascii=False, indent=1)
    print("wrote", p)
