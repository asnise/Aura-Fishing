// Bake UI screens into the place that is open in Roblox Studio (StarterGui), so the UI is stored in the
// place instead of being created when the game starts.
//
//   node tools/ui/bake.mjs              -> bake every screen in src/client/UI/Screens
//   node tools/ui/bake.mjs Modal Menus  -> bake only these
//   node tools/ui/bake.mjs --force Modal -> also replace screens marked Locked
//
// Needs the StudioBridge plugin connected (tools/studio-mcp). Reads the builder sources straight from
// src/ (no Rojo sync needed), runs them in Studio, replaces StarterGui.<Name>. Save the place afterwards.
// A ScreenGui with attribute Locked = true (set it after hand-editing in Studio) is skipped.
import { modulesPrelude, screenNames, luaList, runLuau } from "./lib.mjs";

const args = process.argv.slice(2);
const force = args.includes("--force");
const all = screenNames();
const wanted = args.filter((a) => !a.startsWith("--"));
for (const w of wanted) if (!all.includes(w)) { console.error(`unknown screen "${w}" (have: ${all.join(", ")})`); process.exit(2); }
const names = wanted.length ? wanted : all;

const code = modulesPrelude([], names) + `
local SG = game:GetService("StarterGui")
local FORCE = ${force}
local out = {}
for _, name in ${luaList(names)} do
	local old = SG:FindFirstChild(name)
	if old and old:GetAttribute("Locked") and not FORCE then
		table.insert(out, name .. ": skipped (Locked)")
		continue
	end
	local ok, res = pcall(function()
		local gui = require(screens[name]).Build()
		gui.Name = name
		gui:SetAttribute("BakedFrom", "src/client/UI/Screens/" .. name .. ".luau")
		gui:SetAttribute("BakedAt", os.date("!%Y-%m-%d %H:%M"))
		return gui
	end)
	if ok then
		if old then old:Destroy() end
		res.Parent = SG
		table.insert(out, name .. ": baked (" .. #res:GetDescendants() .. " instances)")
	else
		table.insert(out, name .. ": ERROR " .. tostring(res))
	end
end
holder:Destroy()
return table.concat(out, "\\n")
`;
const text = String((await runLuau(code)) ?? "");
console.log(text);
process.exit(text.includes("ERROR") ? 1 : 0);
