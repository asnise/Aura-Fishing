"""Emit editable C41 trade concepts for the Aura Fishing Figma relay."""

import json


PAGE_ID = "3465:14993"
BUTTONS = {
    "primary": "3487:4284",
    "secondary": "3487:4286",
    "ghost": "3487:4294",
}
COINS_CHIP = "3487:4301"
EMPTY_SLOT = "3491:10580"
ART = {
    "Dewdrop Koi": "3491:6775",
    "Shrimp": "3491:6895",
    "Bamboo Rod +1": "3491:6850",
    "Pebble Minnow": "3491:6757",
    "Worm": "3491:6892",
}
KOI = ("Dewdrop Koi", "Rare / 4.00 kg")
SHRIMP = ("Shrimp", "Bait / 1 unit")
ROD = ("Bamboo Rod +1", "Uncommon / Spare rod")
FEE = "269"  # 5% of the rarity-weighted 5,480 Coins above the 100 Coins threshold.
art_placements = {}


def tone(name, opacity=None):
    paint = {"var": f"cozy/{name}"}
    if opacity is not None:
        paint["opacity"] = opacity
    return paint


def text(name, value, x, y, w, style="Body", color="text", align="LEFT"):
    return {
        "type": "TEXT", "name": name, "text": value, "x": x, "y": y, "w": w,
        "textStyle": f"Aura Fishing/{style}", "color": tone(color), "align": align,
    }


def frame(name, x, y, w, h, children=(), **style):
    return {
        "type": "FRAME", "name": name, "x": x, "y": y, "w": w, "h": h,
        "children": list(children), **style,
    }


def divider(x, y, w):
    return {"type": "RECT", "name": "Divider", "x": x, "y": y, "w": w, "h": 2, "fill": tone("track")}


def button(label, x, y, style="primary"):
    return {
        "type": "INSTANCE", "name": f"Btn {label.title()}", "ref": BUTTONS[style],
        "x": x, "y": y, "texts": {"Label": label},
    }


def tag(label, x, y, w, color):
    return frame(
        f"{label} status", x, y, w, 28,
        [text("Label", label, 0, 5, w, "Small", align="CENTER")],
        fill=tone(color, 0.28), radius=14,
    )


def art(key, name, x, y, size):
    ref = f"c41_trade_{key}"
    art_placements[ref] = {"sourceId": ART[name], "size": size}
    return frame(f"Artwork {name}", x, y, size, size, key=ref, clip=True)


def item_row(key, item, x, y, w, *, action=None, h=72, role=None):
    name, info = item
    image_size = min(h - 14, 54)
    label_x = image_size + 22
    action_space = 124 if action == "add" else 72 if action == "remove" else 0
    label_width = w - label_x - action_space - 8
    children = [
        art(key, name, 10, (h - image_size) // 2, image_size),
        text("Item name", name, label_x, 10, label_width),
        text("Item details", info, label_x, 34, label_width, "Small", "subtext"),
    ]
    if action == "add":
        children.append(button("ADD", w - 114, (h - 57) // 2, "secondary"))
    if action == "remove":
        children.append(tag("Remove", w - 72, (h - 28) // 2, 64, "danger"))
    if role:
        children.append(tag(role, w - 108, (h - 28) // 2, 96, "sky" if role == "You send" else "mint"))
    return frame(name, x, y, w, h, children, fill=tone("panel"), stroke=tone("track"), strokeW=2, radius=16)


def window(title, children, *, review=False):
    footer = [
        divider(24, 510, 712),
        {"type": "INSTANCE", "name": "Coin fee", "ref": COINS_CHIP, "x": 24, "y": 534, "texts": {"Value": FEE}},
        text("Fee unit", "Coins each", 152, 531, 164),
        text("Fee timing", "Charged on completion", 152, 555, 215, "Small", "subtext"),
        button("CONFIRM", 579, 528),
    ]
    if review:
        footer.append(button("EDIT OFFER", 379, 528, "ghost"))
    return frame(
        f"Window {title}", 0, 70, 760, 610,
        [
            text("Window title", title, 24, 19, 392, "Title"),
            text("Trade partner", "Trading with MossFinn", 24, 54, 360, "Body", "subtext"),
            tag("3 / 4 items", 440, 33, 124, "sky"),
            button("CANCEL", 590, 18, "ghost"),
            divider(24, 92, 712),
            *children,
            *footer,
        ],
        fill=tone("panel"), stroke=tone("track"), strokeW=2, radius=24,
        effects=[{"color": "3D4B5C", "a": 0.12, "x": 0, "y": 9, "blur": 20}],
    )


def option_a():
    return window("Trade", [
        frame("Your offer", 24, 112, 350, 360, [
            text("Heading", "Your offer", 16, 15, 180, "Heading"),
            tag("Reviewing", 232, 12, 102, "sky"),
            item_row("a_koi", KOI, 14, 61, 322, action="remove"),
            item_row("a_shrimp", SHRIMP, 14, 143, 322, action="remove"),
            button("ADD ITEM", 14, 246, "secondary"),
        ], fill=tone("sand"), radius=18),
        frame("MossFinn offer", 386, 112, 350, 360, [
            text("Heading", "MossFinn's offer", 16, 15, 202, "Heading"),
            tag("Confirmed", 230, 12, 104, "mint"),
            item_row("a_rod", ROD, 14, 61, 322),
        ], fill=tone("scene", 0.28), stroke=tone("track"), strokeW=2, radius=18),
        text("Offer edit rule", "Changing an offer clears both confirmations.", 24, 482, 570, "Small", "subtext"),
    ])


def option_b():
    return window("Trade", [
        frame("Offer review", 24, 112, 322, 364, [
            text("Your offer heading", "Your offer", 14, 12, 164, "Heading"),
            tag("Reviewing", 201, 11, 105, "sky"),
            item_row("b_koi", KOI, 10, 51, 302, action="remove", h=61),
            item_row("b_shrimp", SHRIMP, 10, 120, 302, action="remove", h=61),
            divider(14, 198, 294),
            text("Partner offer heading", "MossFinn's offer", 14, 214, 184, "Heading"),
            tag("Confirmed", 201, 211, 105, "mint"),
            item_row("b_rod", ROD, 10, 252, 302, h=67),
        ], fill=tone("sand"), radius=18),
        frame("Your bag", 358, 112, 378, 364, [
            text("Heading", "Your bag", 14, 12, 184, "Heading"),
            tag("3 eligible items", 230, 11, 134, "mint"),
            item_row("b_minnow", ("Pebble Minnow", "Common / 0.22 kg"), 12, 52, 354, action="add"),
            item_row("b_worm", ("Worm", "Bait / 4 available"), 12, 134, 354, action="add"),
            item_row("b_extra_shrimp", ("Shrimp", "Bait / 2 more"), 12, 216, 354, action="add"),
        ], fill=tone("scene", 0.28), stroke=tone("track"), strokeW=2, radius=18),
        text("Offer edit rule", "Changing an offer clears both confirmations.", 24, 482, 570, "Small", "subtext"),
    ])


def shared_slot(key, item, owner, x, slot_ref, placeholder):
    name, detail = item
    own = owner == "You"
    return frame(f"{owner} slot {name}", x, 152, 169, 220, [
        tag(owner, 18, 12, 133, "sky" if own else "mint"),
        {
            "type": "INSTANCE", "name": "Item Slot", "ref": slot_ref,
            "x": 40, "y": 48, "hide": [placeholder, "Count Row"],
        },
        art(f"c_{key}", name, 52, 59, 64),
        text("Item name", name, 5, 147, 159, "Body", align="CENTER"),
        text("Item details", detail, 4, 174, 161, "Small", "subtext", "CENTER"),
        *([text("Remove action", "Remove", 4, 196, 161, "Small", "danger-lip", "CENTER")] if own else []),
    ], fill=tone("sky" if own else "scene", 0.18), stroke=tone("track"), strokeW=2, radius=18)


def option_c():
    return window("Trade", [
        text("Offer heading", "Shared offer slots", 24, 111, 330, "Heading"),
        shared_slot("koi", KOI, "You", 24, "3491:10517", "Img fish/DewdropKoi"),
        shared_slot("shrimp", SHRIMP, "You", 205, "3491:10545", "Img equipment/Worm"),
        shared_slot("rod", ROD, "MossFinn", 386, "3491:10510", "Img fish/PearlClam"),
        frame("Open slot", 567, 152, 169, 220, [
            tag("Open slot", 18, 12, 133, "track"),
            {"type": "INSTANCE", "name": "Empty slot", "ref": EMPTY_SLOT, "x": 40, "y": 48},
            text("Add item action", "ADD ITEM", 4, 152, 161, "Heading", "sky-lip", "CENTER"),
        ], fill=tone("sand"), stroke=tone("track"), strokeW=2, radius=18),
        frame("Trade confirmation", 24, 391, 712, 72, [
            text("Your confirmation", "You", 14, 25, 42),
            tag("Reviewing", 64, 22, 116, "sky"),
            text("Partner confirmation", "MossFinn", 369, 25, 88),
            tag("Confirmed", 468, 22, 116, "mint"),
        ], fill=tone("sand"), radius=18),
        text("Offer edit rule", "Changing an offer clears both confirmations.", 24, 482, 570, "Small", "subtext"),
    ])


def option_d():
    return window("Review trade", [
        text("Sent heading", "You give", 24, 112, 340, "Heading"),
        item_row("d_koi", KOI, 24, 145, 712, h=63, role="You send"),
        item_row("d_shrimp", SHRIMP, 24, 216, 712, h=63, role="You send"),
        text("Received heading", "You receive", 24, 294, 340, "Heading"),
        item_row("d_rod", ROD, 24, 326, 712, h=63, role="You get"),
        frame("Review status", 24, 405, 712, 72, [
            text("Review guidance", "Check the items before confirming.", 16, 12, 424),
            text("Offer edit rule", "Editing the offer clears both confirmations.", 16, 39, 424, "Small", "subtext"),
            tag("MossFinn confirmed", 506, 22, 190, "mint"),
        ], fill=tone("scene", 0.28), stroke=tone("track"), strokeW=2, radius=18),
    ], review=True)


def option(letter, name, description, x, y, screen):
    return frame(f"{letter} - {name}", x, y, 760, 680, [
        text("Option title", f"{letter}. {name}", 0, 0, 760, "Title"),
        text("Option description", description, 0, 36, 760, "Body", "subtext"),
        screen,
    ], key=f"c41_trade_option_{letter}")


def spec():
    board = {
        "type": "SECTION", "name": "C41 · Trade — 4 options", "x": 1900, "y": 8000,
        "w": 1648, "h": 1588, "fill": tone("sand"),
        "children": [
            text("Board title", "Trade layouts", 40, 28, 900, "Display"),
            text(
                "Shared trade rules",
                "Same server. Trade License to invite. Up to 4 items total. Both players confirm. Each pays the Coins fee.",
                40, 87, 1568, "Body", "subtext",
            ),
        ],
    }
    options = [
        option("A", "Two Offers", "Compare both players' offers at a glance.", 40, 140, option_a()),
        option("B", "Bag Sidebar", "Add items straight from your bag while both offers stay visible.", 848, 140, option_b()),
        option("C", "Four Shared Slots", "See every item and the remaining space in one row.", 40, 864, option_c()),
        option("D", "Review Sheet", "Review exactly what you give, receive, and pay before confirming.", 848, 864, option_d()),
    ]
    return {"pageId": PAGE_ID, "section": board, "options": options, "art": art_placements}


if __name__ == "__main__":
    print(json.dumps(spec(), ensure_ascii=True, separators=(",", ":")))
