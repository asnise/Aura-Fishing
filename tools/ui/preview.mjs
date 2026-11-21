// Show one baked screen in the Studio viewport (edit mode), filled with the same sample data as the
// Figma frame (src/client/UI/SampleData.luau), so it can be captured and compared with Figma.
//
//   node tools/ui/preview.mjs <view>    views: modal | shop | baits | auras | fishdex | mainmenu
//   node tools/ui/preview.mjs off       hide every baked screen again (do this before saving)
//
// Same as clicking a screen in the "Aura UI" Studio panel. Nothing is saved.
import { modulesPrelude, runLuau } from "./lib.mjs";

const view = process.argv[2];
if (!view) { console.error("usage: preview.mjs <modal|shop|baits|auras|fishdex|mainmenu|off>"); process.exit(2); }

const code = modulesPrelude(["MenuFill", "SampleData"]) + `
local shown = require(ui.SampleData).Show(${JSON.stringify(view)}, ui)
holder:Destroy()
return if shown then shown:GetFullName() .. " shown" else "all hidden"
`;
console.log(await runLuau(code));
