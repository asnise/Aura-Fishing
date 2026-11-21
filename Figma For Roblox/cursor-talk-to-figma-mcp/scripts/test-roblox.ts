// Offline test for the Figma -> Roblox converter. Run: bun scripts/test-roblox.ts <outFile>
import { writeFileSync } from "fs";
import { convertToRoblox, nodeIdFromFigmaUrl, parseExistingImages, moduleNameFrom, RbxNode } from "../src/talk_to_figma_mcp/roblox";

const white = { r: 255, g: 255, b: 255, a: 1 };
const navy = { r: 18, g: 28, b: 48, a: 0.9 };

const tree: RbxNode = {
  id: "1:2", name: "Main Menu", type: "FRAME", visible: true, x: 0, y: 0, width: 1920, height: 1080, rotation: 0, opacity: 1,
  fills: [{ type: "SOLID", color: { r: 10, g: 40, b: 80, a: 1 } }], clipsContent: true,
  children: [
    { id: "1:3", name: "Background [img]", type: "RECTANGLE", visible: true, x: 0, y: 0, width: 1920, height: 1080, rotation: 0, opacity: 1, rasterize: true, fills: [] },
    {
      id: "1:4", name: "Panel", type: "FRAME", visible: true, x: 660, y: 300, width: 600, height: 480, rotation: 0, opacity: 1,
      fills: [{ type: "SOLID", color: navy }], cornerRadius: 24,
      strokes: [{ type: "SOLID", color: { r: 90, g: 200, b: 255, a: 1 } }], strokeWeight: 3,
      effects: [{ type: "DROP_SHADOW", radius: 10, color: null }],
      layout: { mode: "VERTICAL", itemSpacing: 16, paddingLeft: 24, paddingRight: 24, paddingTop: 24, paddingBottom: 24, primaryAlign: "MIN", counterAlign: "CENTER" },
      children: [
        { id: "1:5", name: "Title", type: "TEXT", visible: true, x: 684, y: 324, width: 552, height: 64, rotation: 0, opacity: 1, fills: [],
          text: { characters: "AURA \"FISHING\"\nไทย", fontFamily: "Fredoka One", fontStyle: "Regular", fontSize: 48, alignH: "CENTER", alignV: "CENTER", autoResize: "NONE", fills: [{ type: "SOLID", color: white }] } },
        { id: "1:6", name: "Btn Play", type: "FRAME", visible: true, x: 760, y: 404, width: 400, height: 80, rotation: 0, opacity: 1,
          fills: [{ type: "GRADIENT_LINEAR", stops: [{ position: 0, color: { r: 255, g: 200, b: 60, a: 1 } }, { position: 1, color: { r: 255, g: 120, b: 0, a: 1 } }], transform: [[1, 0, 0], [0, 1, 0]] }],
          cornerRadius: 16,
          children: [
            { id: "1:7", name: "Label", type: "TEXT", visible: true, x: 760, y: 404, width: 400, height: 80, rotation: 0, opacity: 1, fills: [],
              text: { characters: "PLAY", fontFamily: "Inter", fontStyle: "Extra Bold", fontSize: 36, alignH: "CENTER", alignV: "CENTER", autoResize: "NONE", fills: [{ type: "SOLID", color: { r: 20, g: 20, b: 40, a: 1 } }] } },
          ] },
        { id: "1:8", name: "Settings [btn]", type: "RECTANGLE", visible: true, x: 760, y: 500, width: 400, height: 60, rotation: 0, opacity: 1, fills: [{ type: "SOLID", color: { r: 40, g: 60, b: 100, a: 1 } }], cornerRadius: 12 },
        { id: "1:9", name: "Fish Icon", type: "GROUP", visible: true, x: 930, y: 580, width: 60, height: 60, rotation: 0, opacity: 1, rasterize: true },
        { id: "1:10", name: "Avatar", type: "RECTANGLE", visible: true, x: 910, y: 650, width: 100, height: 100, rotation: 0, opacity: 1, fills: [{ type: "IMAGE", imageHash: "abc123", scaleMode: "FILL", opacity: 1 }] },
      ],
    },
    { id: "1:11", name: "Coin Badge", type: "ELLIPSE", visible: true, x: 40, y: 40, width: 64, height: 64, rotation: 0, opacity: 1, isCircle: true, rasterize: false, fills: [{ type: "SOLID", color: { r: 255, g: 205, b: 70, a: 1 } }] },
    { id: "1:12", name: "Tilted Tag", type: "FRAME", visible: false, x: 1700, y: 60, width: 160, height: 50, centerX: 1780, centerY: 85, rotation: 15, opacity: 0.6, fills: [{ type: "SOLID", color: white }],
      children: [{ id: "1:13", name: "Tag Text", type: "TEXT", visible: true, x: 1700, y: 60, width: 160, height: 50, rotation: 0, opacity: 1, fills: [], text: { characters: "NEW", fontFamily: "Gotham", fontStyle: "Bold", fontSize: 24, alignH: "CENTER", alignV: "CENTER", autoResize: "NONE", fills: [{ type: "SOLID", color: { r: 255, g: 0, b: 0, a: 1 } }] } }] },
    { id: "1:14", name: "Debug [skip]", type: "FRAME", visible: true, x: 0, y: 0, width: 10, height: 10, rotation: 0, opacity: 1 },
  ],
};

const name = moduleNameFrom(tree.name);
const res = convertToRoblox(tree, { moduleName: name, sizeMode: "scale", rootFit: "aspect", includeHidden: true, existingImages: { Avatar: "rbxassetid://12345" } });
writeFileSync(process.argv[2] || "out.luau", res.luau);

const assert = (c: any, m: string) => { if (!c) { console.error("FAIL:", m); process.exit(1); } };
assert(name === "MainMenu", "module name");
assert(nodeIdFromFigmaUrl("https://www.figma.com/design/AbC/Aura?node-id=12-34&t=x") === "12:34", "url parse");
assert(res.assets.length === 3, `3 assets, got ${res.assets.length}`);
assert(res.luau.includes('"rbxassetid://12345"'), "preserve existing id");
assert(parseExistingImages(res.luau).Avatar === "rbxassetid://12345", "parse ids");
assert(!res.luau.includes("Debug"), "skip layer");
assert(res.luau.includes('Instance.new("TextButton")'), "button");
assert(res.luau.includes("UIListLayout"), "layout");
assert(res.luau.includes("CanvasGroup"), "canvas group for opacity");
assert(res.luau.includes("Rotation = -15"), "rotation");
console.log(`OK: ${res.instanceCount} instances, ${res.assets.length} assets`);
console.log("warnings:", res.warnings);
