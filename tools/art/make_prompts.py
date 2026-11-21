"""Builds docs/ART_PROMPTS.md from tools/art/sheets.json (single source of truth for cell order).
Run: python -I tools/art/make_prompts.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
data = json.load(open(os.path.join(ROOT, "tools", "art", "sheets.json"), encoding="utf-8"))
POS = ["top-left", "top-center", "top-right", "middle-left", "center", "middle-right", "bottom-left", "bottom-center", "bottom-right"]

lines = []
w = lines.append
w("# Aura Fishing — Art prompts (3×3 grid, 1:1)")
w("")
w("> Generated from `tools/art/sheets.json` by `tools/art/make_prompts.py`. Don't edit by hand — edit the JSON and re-run.")
w("")
w("## How to use")
w("1. Copy one **Prompt** block into your image generator. Set the aspect ratio to **1:1** (1024×1024 or larger).")
w("2. If your generator has a negative prompt box, paste the **Negative** line into it.")
w("3. Save the image, then slice it:")
w("   ```")
w("   python -I tools/art/slice_grid.py <sheet id> <image.png>")
w("   ```")
w("   You get transparent 512×512 PNGs in `assets/art/<folder>/<name>.png` plus `assets/art/<sheet id>_contact.png` to check what landed where.")
w("4. If a cell came out wrong, regenerate the whole sheet or swap in the cell from another attempt (the slot order never changes).")
w("5. Cell order is always **left → right, top → bottom** (1 = top-left, 9 = bottom-right).")
w("")
w("## Sheets")
w("| # | Sheet id | Purpose | Saved to |")
w("|---|---|---|---|")
for i, s in enumerate(data["sheets"], 1):
    w(f"| {i} | `{s['id']}` | {s['title']} | `assets/art/{s['folder']}/` |")
w("")
for i, s in enumerate(data["sheets"], 1):
    w(f"---\n\n## {i}. `{s['id']}` — {s['title']}")
    w("")
    w("| Cell | Position | File | Content |")
    w("|---|---|---|---|")
    for n, (name, desc) in enumerate(s["items"]):
        w(f"| {n + 1} | {POS[n]} | `{name}.png` | {desc} |")
    w("")
    cells = " ".join(f"Cell {n + 1} ({POS[n]}): {desc}." for n, (_, desc) in enumerate(s["items"]))
    prompt = f"{data['style']} Set note: {s['note']} The 9 cells, in reading order left to right, top to bottom: {cells}"
    w("**Prompt**")
    w("```text")
    w(prompt)
    w("```")
    w("**Negative**")
    w("```text")
    w(data["negative"])
    w("```")
    w("")

w("---\n\n## Bonus — single images (not grids)")
w("")
w("**Game icon (1:1, 512×512, for the Roblox game page)**")
w("```text")
w("Roblox game icon, cozy pastel fishing game called Aura Fishing. A cute chunky round fish jumping out of calm mint-blue water, "
  "surrounded by a soft lavender and gold magical aura glow, a coral and cream fishing bobber in the corner. Soft cel-shaded 3D cartoon, "
  "rounded friendly shapes, pastel palette (mint #7FD3B0, coral #FF9E80, sky #9AD4F5, gold #F2B544, lavender #B79CF2), bright and readable at small size, "
  "centered composition, no text, no letters.")
w("```")
w("")
w("**Game thumbnail (16:9, 1920×1080)**")
w("```text")
w("Wide cozy scene for a Roblox fishing game: a small round grassy island with a wooden dock on a calm pastel lake at golden hour, "
  "a blocky toy-like Roblox-style character casting a fishing rod with a glowing lavender aura swirling around them, a big shiny fish leaping from the water, "
  "soft cel-shaded 3D cartoon, pastel palette mint, coral, sky blue, warm gold, lavender, soft light, lots of empty sky on the right for a title, no text.")
w("```")
w("")
w("**Loading screen background (16:9)**")
w("```text")
w("Soft dreamy pastel lake at dawn seen from a wooden dock, gentle ripples, floating sparkles, distant small islands, mint and sky-blue water, "
  "cream and peach sky, cozy and calm, soft cel-shaded 3D cartoon, very low detail in the centre so UI can sit on top, no characters, no text.")
w("```")

out = os.path.join(ROOT, "docs", "ART_PROMPTS.md")
open(out, "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("wrote", out)
