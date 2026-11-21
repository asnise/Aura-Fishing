"""After uploading images to Roblox: put each rbxassetid into assets/catalog.json, then run
    python -I tools/art/sync_ui_assets.py
to regenerate src/shared/Config/UIAssets.luau (no Figma access needed).

Optional bulk fill from a CSV exported/written by hand:  key,rbxassetid   (key = global id or art key like fish/BubbleCarp)
    python -I tools/art/sync_ui_assets.py ids.csv
"""
import csv
import importlib.util
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
spec = importlib.util.spec_from_file_location("extract_assets", os.path.join(ROOT, "tools", "art", "extract_assets.py"))
ex = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ex)

cat_path = os.path.join(ROOT, "assets", "catalog.json")
cat = json.load(open(cat_path, encoding="utf-8"))
if len(sys.argv) > 1:
    for row in csv.reader(open(sys.argv[1], encoding="utf-8")):
        if len(row) < 2 or row[0].startswith("#"):
            continue
        key, rid = row[0].strip(), row[1].strip()
        if not rid:
            continue  # row not filled yet (partial ids.csv)
        if rid.isdigit():
            rid = "rbxassetid://" + rid
        grp = "global" if key in cat["global"] else "art" if key in cat["art"] else None
        if not grp:
            print("unknown key", key)
            continue
        cat[grp][key]["rbxassetid"] = rid
    json.dump(cat, open(cat_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
ex.write_luau(cat)
ex.write_markdown(cat)
done = sum(1 for g in ("global", "art") for v in cat[g].values() if v.get("rbxassetid"))
total = len(cat["global"]) + len(cat["art"])
print(f"UIAssets.luau regenerated — {done}/{total} assets have ids")
