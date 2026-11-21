// After tools/art/upload_assets.py: Open Cloud returns Decal ids, but ImageLabel.Image needs the
// Image id inside each decal. With Studio open (StudioBridge), load each decal and read its Texture,
// then write the image ids into assets/catalog.json and regenerate UIAssets.luau.
//   node tools/ui/resolve_decals.mjs
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { execFileSync } from "child_process";
import { root, runLuau } from "./lib.mjs";

const catPath = join(root, "assets", "catalog.json");
const cat = JSON.parse(readFileSync(catPath, "utf8"));
const todo = [];
for (const g of ["global", "art"]) for (const [k, v] of Object.entries(cat[g])) if (v.decal && v.rbxassetid) todo.push([g, k, v.rbxassetid.match(/\d+/)[0]]);
if (!todo.length) { console.log("nothing to resolve"); process.exit(0); }

const out = {};
for (let i = 0; i < todo.length; i += 15) {
  const chunk = todo.slice(i, i + 15);
  const code = `
local IS = game:GetService("InsertService")
local res = {}
for _, id in {${chunk.map(([, , id]) => id).join(", ")}} do
	local ok, model = pcall(function() return IS:LoadAsset(id) end)
	local tex = nil
	if ok and model then
		local d = model:FindFirstChildWhichIsA("Decal", true)
		tex = d and d.Texture:match("(%d+)")
		model:Destroy()
	end
	table.insert(res, tostring(id) .. "=" .. tostring(tex or (ok and "nodecal" or "error")))
end
return table.concat(res, ",")
`;
  const r = String((await runLuau(code, 120000)) ?? "");
  for (const pair of r.split(",")) { const [d, img] = pair.split("="); out[d] = img; }
  console.log(`resolved ${Math.min(i + 15, todo.length)}/${todo.length}`);
}
let fixed = 0;
const bad = [];
for (const [g, k, id] of todo) {
  const img = out[id];
  if (img && /^\d+$/.test(img)) { cat[g][k].rbxassetid = `rbxassetid://${img}`; delete cat[g][k].decal; fixed++; }
  else bad.push(`${k} (${img ?? "?"})`);
}
writeFileSync(catPath, JSON.stringify(cat, null, 1));
console.log(`image ids: ${fixed}/${todo.length}`);
if (bad.length) console.log("not ready (still in moderation? re-run later):", bad.join(", "));
console.log(execFileSync("python", ["-I", join(root, "tools", "art", "sync_ui_assets.py")], { encoding: "utf8" }));
