"""Shop: the Buy button shows the currency icon + price instead of the word "Buy" (user request 2026-11-16).
Targeted patch of 05 Shop - Rods / 06 Shop - Baits: replaces only the Buy buttons and the Sub texts
(price moves out of the Sub line). Everything else in those frames stays as edited by hand.

Run:  python -I docs/figma/price_buttons.py docs/figma/out
Send: python -I docs/figma/apply_patch.py docs/figma/out/12_price_buttons_ops.json
Then: python -I tools/art/figma_images.py --root <each new button id>   (fills the coin icon)
"""
import importlib.util
import json
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("cozy_menus_spec", os.path.join(_here, "cozy_menus_spec.py"))
m = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(m)
v, text, img = m.v, m.text, m.img


def price_button(price, currency="Coins", name="Btn Buy", affordable=True):
    """Gold button: cream circle with the currency icon + price (Button text style). Ghost style when unaffordable."""
    face, lip, fg = ("cozy/gold", "cozy/gold-lip", "cozy/on-accent") if affordable else ("cozy/sand", "cozy/track", "cozy/text")
    icon = "ui/status/coin" if currency == "Coins" else "ui/status/gem"
    return {"name": name, "layout": "H", "pad": [12, 22, 16, 16], "gap": 8, "main": "CENTER", "cross": "CENTER",
            "radiusVar": "cozy/radius/button", "fill": v(face), "stroke": v(lip), "strokeSides": {"b": 5}, "strokeAlign": "INSIDE",
            "children": [
                {"name": "Icon", "layout": "H", "w": 30, "h": 30, "radius": 999, "fill": v("cozy/panel"), "main": "CENTER", "cross": "CENTER",
                 "children": [img(icon, 22)]},
                text(price, "Button", fg, name="Label")]}


def sub(t):
    return text(t, "Small", "cozy/subtext", name="Sub")


OPS = [
    # 05 Shop - Rods: Coral Rod (buyable)
    {"replaceId": "3492:21121", "tree": price_button("2,500", name="Btn Action")},
    {"replaceId": "3492:21120", "tree": sub("+5% Catch Bar, +0.30 Reel Power, +15% Resilience, +15% Luck")},
    # 06 Shop - Baits: pack of 10, price on the button
    {"replaceId": "3492:21164", "tree": price_button("20")},
    {"replaceId": "3492:21163", "tree": sub("+10% Luck  |  pack of 10")},
    {"replaceId": "3492:21171", "tree": price_button("150")},
    {"replaceId": "3492:21170", "tree": sub("+30% Luck, +10% Bite Speed  |  pack of 10")},
    {"replaceId": "3492:21180", "tree": price_button("900")},
    {"replaceId": "3492:21177", "tree": sub("+75% Luck, +1% Mutation  |  pack of 10")},
]

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, "12_price_buttons_ops.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(OPS, f, ensure_ascii=False, indent=1)
    print("wrote", path)
