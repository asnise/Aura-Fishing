// Rebuilds docs/economy/game_design_math/AuraFishing_GameDesignMath.xlsx (+ csv/) from the live Config files.
//   node tools/balance_sheet/build.mjs
// Needs: luau (scoop install luau) and python 3. No other packages.
import { execFileSync } from "node:child_process";
import { cpSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..", "..");
const work = join(here, ".work");
rmSync(work, { recursive: true, force: true });
mkdirSync(join(work, "cfg"), { recursive: true });

// Config files only use a few Roblox globals; give each copy tiny local stubs so plain luau can run them.
const stubs = "local function __c() return { __color = true } end local Color3 = { fromRGB = __c, new = __c } local Vector2 = { new = function(x, y) return { x = x, y = y } end } local UDim2 = { new = function() return {} end } local Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function() return 0 end }) end })\n";
const cfgDir = join(root, "src", "shared", "Config");
for (const f of readdirSync(cfgDir).filter((n) => n.endsWith(".luau"))) {
  writeFileSync(join(work, "cfg", f), stubs + readFileSync(join(cfgDir, f), "utf8"));
}
cpSync(join(here, "dump.luau"), join(work, "dump.luau"));
cpSync(join(here, "xl.py"), join(work, "xl.py"));
cpSync(join(here, "build.py"), join(work, "build.py"));

const json = execFileSync("luau", ["dump.luau"], { cwd: work, maxBuffer: 64 * 1024 * 1024 });
writeFileSync(join(work, "dump.json"), json);
const out = join(root, "docs", "economy", "game_design_math");
mkdirSync(join(out, "csv"), { recursive: true });
execFileSync("python", ["build.py", join(out, "AuraFishing_GameDesignMath.xlsx"), join(out, "csv")], { cwd: work, stdio: "inherit" });
rmSync(work, { recursive: true, force: true });
