"""Editable Trade grid flow for the C41 Figma board."""

import json
import runpy
from pathlib import Path


base = runpy.run_path(str(Path(__file__).with_name("trade_options.py")))
tone, text, frame = (base[name] for name in ("tone", "text", "frame"))
divider, tag, button = (base[name] for name in ("divider", "tag", "button"))
PAGE_ID = base["PAGE_ID"]
EMPTY_SLOT = base["EMPTY_SLOT"]
INVENTORY_COLUMNS = 4
INVENTORY_ROWS = 3
VIEWPORT_HEIGHT = 280

SLOTS = {
    "carp": ("Bubble Carp", "3491:10503", "Img fish/PebbleMinnow", "3491:6760", 1),
    "shrimp_bag": ("Shrimp in inventory", "3491:10545", "Img equipment/Worm", "3491:6895", 2),
    "shrimp_offer": ("Shrimp in offer", "3491:10545", "Img equipment/Worm", "3491:6895", 1),
    "equipped": ("Coral Rod equipped", "3491:10571", "Img fish/DewdropKoi", "3491:6853", 1),
    "minnow": ("Pebble Minnow", "3491:10503", None, None, 1),
    "worm": ("Worm", "3491:10545", None, None, 4),
    "lily": ("Lily Trout", "3491:10510", "Img fish/PearlClam", "3491:6772", 1),
    "koi": ("Dewdrop Koi", "3491:10517", None, None, 1),
    "peer_rod": ("Moonsilver Rod +2", "3491:10524", "Img fish/CrystalGuppy", "3491:6856", 1),
    "bamboo": ("Bamboo Rod", "3491:10510", "Img fish/PearlClam", "3491:6850", 1),
    "naga_rod": ("Naga Scale Rod", "3491:10531", "Img fish/CoralSeahorse", "3491:6859", 1),
}

# One Rare modifier on an Epic Moonsilver Rod +2, one Shrimp and, after adding, one 2.70 kg Bubble Carp.
ROD_VALUE = (120_000 + 12_000 + 18_000 + 18_000) * 4
FEES = [f"{(ROD_VALUE + 80 + fish_value - 100) * 5 // 100:,}" for fish_value in (0, 77)]


def ref(name):
    return f"c41_trade_grid_{name}"


def frame_key(name, x, y, w, h, key, children=(), **props):
    return frame(name, x, y, w, h, children, key=ref(key), **props)


def tape(name, x, y, w, h, **style):
    return {"type": "RECT", "name": name, "x": x, "y": y, "w": w, "h": h, **style}


def slot_components():
    assets = []
    components = []
    for key, (name, component_id, placeholder, art_id, count) in SLOTS.items():
        hidden = [placeholder] if placeholder else []
        if count == 1:
            hidden.append("Count Row")
        if key == "equipped":
            hidden.append("Icon FaLock")
        children = [{
            "type": "INSTANCE", "name": "Cozy Lake Item Slot", "ref": component_id, "x": 0, "y": 0,
            "hide": hidden, "texts": {"Value": f"x{count}"},
        }]
        if art_id:
            mount = f"{key}_art"
            children.append(frame_key("Artwork", 12, 10, 64, 64, mount, clip=True))
            assets.append({"sourceId": art_id, "mount": ref(mount), "w": 64, "h": 64})
        if key == "equipped":
            children[-1]["opacity"] = 0.48
            children.append(frame_key("Lock icon", 29, 27, 30, 34, "equipped_lock"))
            assets.append({"sourceId": "3491:10578", "mount": ref("equipped_lock"), "w": 30, "h": 34})
        components.append({
            "type": "COMPONENT", "name": name, "key": ref(f"slot_{key}"),
            "w": 88, "h": 88, "children": children,
        })
    return frame("Trade slot samples", 1168, 1592, 710, 332, [
        text("Title", "Trade slot samples", 0, 0, 500, "Title"),
        text("Description", "Linked slots used across the Trade states.", 0, 40, 500, "Body", "subtext"),
        *[dict(c, x=8 + (i % 6) * 112, y=82 + (i // 6) * 108) for i, c in enumerate(components)],
    ]), assets


def slot(key, x, y, state, pane, selected=False):
    name = SLOTS[key][0]
    outlines = [
        tape("Selected slot outline", 0, 0, 88, 88, radius=20, stroke=tone("sky-lip"), strokeW=3, strokeAlign="INSIDE"),
    ] if selected else []
    return frame_key(name, x, y, 88, 88, f"{state}_{pane}_{key}", [
        {"type": "INSTANCE", "name": name, "ref": ref(f"slot_{key}"), "x": 0, "y": 0},
        *outlines,
    ])


def empty_slot(x, y):
    return {"type": "INSTANCE", "name": "Empty slot", "ref": EMPTY_SLOT, "x": x, "y": y}


def inventory_position(index):
    row, column = divmod(index, INVENTORY_COLUMNS)
    return column * 100, row * 96


def inventory(state, added):
    items = ["carp", "shrimp_bag", "equipped", "minnow", "worm", "lily", "koi"]
    if added:
        items.remove("carp")
    active = {"add": "carp", "locked": "equipped"}.get(state)
    is_scrolled = state == "scroll"
    cells = [slot(key, *inventory_position(i), state, "inventory", key == active)
             for i, key in enumerate(items)]
    if is_scrolled:
        for name, component_id in (
            ("Crystal Guppy", "3491:10524"),
            ("Pearl Clam", "3491:10510"),
            ("Coral Seahorse", "3491:10531"),
            ("Naga Hatchling", "3491:10538"),
        ):
            x, y = inventory_position(len(cells))
            cells.append({
                "type": "INSTANCE", "name": name, "ref": component_id,
                "x": x, "y": y, "hide": ["Count Row"],
            })
        for key in ("bamboo", "naga_rod"):
            cells.append(slot(key, *inventory_position(len(cells)), state, "inventory"))
    row_count = max(INVENTORY_ROWS, (len(cells) + INVENTORY_COLUMNS - 1) // INVENTORY_COLUMNS)
    cells.extend(empty_slot(*inventory_position(i)) for i in range(len(cells), row_count * INVENTORY_COLUMNS))
    content_height = (row_count - 1) * 96 + 88
    scroll_y = max(0, content_height - VIEWPORT_HEIGHT) if is_scrolled else 0
    scrollbar = []
    if scroll_y > 0:
        thumb_height = VIEWPORT_HEIGHT * VIEWPORT_HEIGHT // content_height
        scrollbar = [
            tape("Scroll track", 422, 66, 5, VIEWPORT_HEIGHT, radius=2.5, fill=tone("track")),
            tape("Scroll thumb", 422, 66 + VIEWPORT_HEIGHT - thumb_height,
                 5, thumb_height, radius=2.5, fill=tone("sky-lip")),
        ]
    return frame("Inventory Grid", 24, 112, 440, 380, [
        text("Inventory heading", "Your inventory", 16, 13, 250, "Heading"),
        text("Inventory guidance", "Tap an item to inspect it.", 16, 40, 344, "Small", "subtext"),
        frame_key("Grid [scroll]", 26, 66, 388, VIEWPORT_HEIGHT, f"{state}_viewport", [
            frame_key("Inventory rows", 0, -scroll_y, 388, content_height, f"{state}_rows", cells),
        ], clip=True),
        *scrollbar,
    ], fill=tone("panel"), stroke=tone("track"), strokeW=2, radius=18)


def offer(state, added):
    mine = ["shrimp_offer", "carp"] if added else ["shrimp_offer"]
    empty_offers = [empty_slot(34 + i * 100, 86) for i in range(len(mine), 2)]
    return frame("Offer Grid", 480, 112, 256, 380, [
        text("Offer heading", "Offer", 16, 13, 155, "Heading"),
        text("Your offer heading", "Your offer", 16, 58, 224),
        *[slot(key, 34 + i * 100, 86, state, "my_offer") for i, key in enumerate(mine)],
        *empty_offers,
        divider(16, 193, 224),
        text("Partner offer heading", "MossFinn's offer", 16, 213, 224),
        slot("peer_rod", 34, 241, state, "partner_offer", state == "partner"),
        empty_slot(134, 241),
        dict(tag("Waiting for confirmation", 16, 337, 224, "track"), fill=tone("track")),
    ], fill=tone("sand", 0.45), stroke=tone("track"), strokeW=2, radius=18)


def trade_window(state):
    added = state in {"added", "locked", "partner"}
    return frame("Window Trade", 0, 70, 760, 610, [
        text("Window title", "Trade", 24, 19, 372, "Title"),
        text("Trade partner", "Trading with MossFinn", 24, 54, 370, "Body", "subtext"),
        dict(button("X", 664, 18), name="Btn Close", ref="3487:4296", key=ref(f"{state}_close")),
        divider(24, 92, 712),
        inventory(state, added),
        offer(state, added),
        divider(24, 510, 712),
        {
            "type": "INSTANCE", "name": "Coin fee", "ref": base["COINS_CHIP"],
            "x": 24, "y": 537, "texts": {"Value": FEES[int(added)]},
        },
        text("Fee unit", "Coins each", 169, 533, 171),
        text("Fee timing", "Charged on completion", 169, 557, 233, "Small", "subtext"),
        dict(button("CONFIRM", 579, 528), key=ref(f"{state}_confirm")),
    ], fill=tone("panel"), stroke=tone("track"), strokeW=2, radius=24,
        effects=[{"color": "3D4B5C", "a": 0.12, "x": 0, "y": 9, "blur": 20}])


def state_frame(state, title, description, x, y, detail_y=None):
    contents = [
        text("State title", title, 0, 0, 1088, "Title"),
        text("State description", description, 0, 37, 1088, "Body", "subtext"),
        trade_window(state),
    ]
    if detail_y is not None:
        contents.append(frame_key("Item Card Mount", 782, detail_y, 280, 420, f"{state}_detail"))
    return frame_key(title, x, y, 1088, 704, f"state_{state}", contents)


def trade_action(disabled):
    children = [divider(0, 0, 244)]
    if disabled:
        children.append(text("Unavailable reason", "Unequip this rod to add it.", 0, 10, 244, "Small", "subtext"))
    y = 36 if disabled else 12
    main = "D8D1C4" if disabled else tone("sky")
    lip = "BCB3A4" if disabled else tone("sky-lip")
    caption = text("Label", "ADD TO TRADE", 0, 9, 244, "Button", "text", "CENTER")
    if disabled:
        caption["color"] = "8A8478"
    children.append(frame_key(
        "Btn Add to Trade (Disabled)" if disabled else "Btn Add to Trade",
        0, y, 244, 48, "add_disabled" if disabled else "add_button",
        [
            tape("Lip", 0, 0, 244, 48, fill=lip, radius=16),
            tape("Face", 0, 0, 244, 43, fill=main, radius=16),
            caption,
        ],
    ))
    return frame("Trade action", 0, 0, 244, y + 48, children)


def spec():
    board = {
        "type": "SECTION", "name": "C41 · Trade Grid — Item Card flow",
        "x": 1900, "y": 10000, "w": 2304, "h": 2710, "fill": tone("sand"),
        "children": [
            text("Board title", "Trade Grid", 40, 28, 1020, "Display"),
            text(
                "Flow summary",
                "Inspect an inventory item, add it to your offer, and inspect the other player's items before confirming.",
                40, 87, 2110, "Body", "subtext",
            ),
        ],
    }
    components, assets = slot_components()
    states = [
        state_frame("browse", "01. Browse inventory",
                    "Four columns by three visible rows. Each player has two offer slots.", 40, 136),
        state_frame("add", "02. Inspect and add",
                    "Select Bubble Carp to open the normal Item Card with Add to Trade.", 1176, 136, 230),
        state_frame("added", "03. Item added to your offer",
                    "Bubble Carp fills your second offer slot and the fee updates.", 40, 870),
        state_frame("locked", "04. Inspect an equipped item",
                    "Coral Rod details open with the Add to Trade button disabled.", 1176, 870, 213),
        state_frame("partner", "05. Inspect the partner's offer",
                    "Open Moonsilver Rod details from MossFinn's offer. Confirm stays in the Trade window.", 40, 1604, 238),
        state_frame("scroll", "06. Scroll through a larger inventory",
                    "The inventory scrolls on its own. Empty slots complete the last row.", 1176, 1604),
    ]
    cards = {
        "add": {
            "sourceId": "3600:50373", "mount": ref("add_detail"), "action": trade_action(False),
            "remove": ["Pill x41", "Pill HOT x3"], "texts": {"2.7 kg": "2.70 kg"},
        },
        "locked": {
            "sourceId": "3600:51441", "mount": ref("locked_detail"), "action": trade_action(True),
            "texts": {"Sharp": "Lucky", "of the Deep": "of Iron"},
        },
        "partner": {
            "sourceId": "3600:50146", "mount": ref("partner_detail"), "action": None,
            "texts": {"Sharp": "Lucky"},
        },
    }
    return dict(pageId=PAGE_ID, section=board, components=dict(components, x=40, y=2340),
                assets=assets, states=states, cards=cards)


if __name__ == "__main__":
    print(json.dumps(spec(), ensure_ascii=True, separators=(",", ":")))
