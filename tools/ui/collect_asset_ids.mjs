// After Bulk Import in Studio's Asset Manager: insert the imported images into the place (select them in
// Asset Manager -> right-click -> Insert, which creates Decals named after the files), then run
//
//   node tools/ui/collect_asset_ids.mjs            -> finds them by name, writes assets/asset_ids.csv,
//                                                     runs tools/art/sync_ui_assets.py (UIAssets.luau)
//   node tools/ui/collect_asset_ids.mjs --cleanup  -> same, then deletes those inserted Decals/ImageLabels
//
// Every PNG in assets/ui-global and assets/art has a unique file name, so the name is the key.
import { readdirSync, writeFileSync, statSync } from "fs";
import { join, basename } from "path";
import { execFileSync } from "child_process";
import { root, luaList, runLuau } from "./lib.mjs";

const cleanup = process.argv.includes("--cleanup");
const keys = {}; // file base name -> catalog key
for (const f of readdirSync(join(root, "assets", "ui-global"))) if (f.endsWith(".png")) keys[f.slice(0, -4)] = f.slice(0, -4);
const artDir = join(root, "assets", "art");
for (const folder of readdirSync(artDir)) {
  const p = join(artDir, folder);
  if (!statSync(p).isDirectory()) continue;
  const walk = (dir, rel) => {
    for (const f of readdirSync(dir)) {
      const full = join(dir, f);
      if (statSync(full).isDirectory()) walk(full, `${rel}/${f}`);
      else if (f.endsWith(".png")) keys[basename(f, ".png")] = `${rel}/${basename(f, ".png")}`;
    }
  };
  walk(p, folder);
}

const code = `
local NAMES = {}
for _, n in ${luaList(Object.keys(keys))} do NAMES[n] = true end
local found, inst = {}, {}
for _, svc in { workspace, game:GetService("ServerStorage"), game:GetService("ReplicatedStorage"), game:GetService("StarterGui") } do
	for _, d in svc:GetDescendants() do
		local name = d.Name:gsub("%.png$", "")
		if NAMES[name] then
			local id = (d:IsA("Decal") or d:IsA("Texture")) and d.Texture
				or ((d:IsA("ImageLabel") or d:IsA("ImageButton")) and not d:GetAttribute("ImageKey") and d.Image)
				or (d:IsA("ImageAsset") and d.Image) or nil
			if id and id ~= "" and id:match("%d") then
				found[name] = id:match("(%d+)")
				table.insert(inst, d)
			end
		end
	end
end
if ${cleanup} then for _, d in inst do d:Destroy() end end
local out = {}
for n, id in found do table.insert(out, n .. "," .. id) end
return table.concat(out, "\\n")
`;
const res = String((await runLuau(code)) ?? "");
const lines = res.split("\n").filter(Boolean);
const csv = lines.map((l) => { const [n, id] = l.split(","); return `${keys[n]},${id}`; });
const missing = Object.keys(keys).filter((n) => !lines.some((l) => l.startsWith(n + ",")));
const out = join(root, "assets", "asset_ids.csv");
writeFileSync(out, "# key,rbxassetid (written by tools/ui/collect_asset_ids.mjs)\n" + csv.join("\n") + "\n");
console.log(`found ${csv.length}/${Object.keys(keys).length} image ids -> ${out}`);
if (missing.length) console.log("missing:", missing.join(", "));
if (csv.length) console.log(execFileSync("python", ["-I", join(root, "tools", "art", "sync_ui_assets.py"), out], { encoding: "utf8" }));
