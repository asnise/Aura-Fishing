// One-command QA for Aura Fishing. Run from anywhere:
//     node tools/check.mjs          (or tools\check.bat)
// 1. rojo sourcemap  ->  sourcemap.json
// 2. luau-lsp analyze (must be clean)
// 3. banned characters in strings the player can see: check marks, bullets, emoji
//    (Roblox fonts render them as boxes). Comments are ignored.
// Exit code 0 = all good, 1 = something failed (details printed).
import { spawnSync } from "node:child_process";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const ROJO = "D:\\tools\\rojo\\rojo.exe";
const DEFS = "D:/tools/luau-defs/globalTypes.d.luau";

let failed = false;
const step = (name) => console.log(`\n== ${name}`);

function run(cmd, args) {
	const r = spawnSync(cmd, args, { cwd: ROOT, encoding: "utf8", shell: false });
	if (r.error) {
		return { ok: false, out: String(r.error.message) };
	}
	return { ok: r.status === 0, out: (r.stdout || "") + (r.stderr || "") };
}

step("rojo sourcemap");
let r = run(ROJO, ["sourcemap", "default.project.json", "-o", "sourcemap.json"]);
console.log(r.ok ? "ok" : r.out.trim());
failed ||= !r.ok;

step("luau-lsp analyze");
r = run("luau-lsp", ["analyze", `--definitions=${DEFS}`, "--sourcemap=sourcemap.json", "src"]);
// "[INFO]/[WARN]" lines are luau-lsp's own logging; "file(l,c): Kind: msg" are diagnostics.
// Type/syntax errors fail the check; lints (DeprecatedApi, LocalUnused, ...) are listed as warnings.
const diags = r.out.split(/\r?\n/).filter((l) => /\(\d+,\d+\): \w+:/.test(l));
const errors = diags.filter((l) => /\): (TypeError|SyntaxError):/.test(l));
const warnings = diags.filter((l) => !errors.includes(l));
if (errors.length) console.log("errors:\n" + errors.join("\n"));
if (warnings.length) console.log("warnings (not failing):\n" + warnings.join("\n"));
console.log(`${errors.length} error(s), ${warnings.length} warning(s)`);
failed ||= !r.ok || errors.length > 0;

step("banned characters (check marks, bullets, emoji) outside comments");
// U+2713/2714 check marks, U+2022 bullet, emoji blocks (misc symbols/dingbats used as emoji + U+1F000..)
const BANNED = /[\u2713\u2714\u2022\u2600-\u27BF\u{1F000}-\u{1FAFF}\uFE0F]/u;
const hits = [];
function walk(dir) {
	for (const name of readdirSync(dir)) {
		const p = join(dir, name);
		if (statSync(p).isDirectory()) {
			walk(p);
		} else if (/\.luau?$/.test(name)) {
			readFileSync(p, "utf8")
				.split(/\r?\n/)
				.forEach((line, i) => {
					const code = line.replace(/--.*$/, "");
					const m = code.match(BANNED);
					if (m) {
						hits.push(`${relative(ROOT, p)}:${i + 1}  U+${m[0].codePointAt(0).toString(16).toUpperCase()}  ${line.trim()}`);
					}
				});
		}
	}
}
walk(join(ROOT, "src"));
console.log(hits.length ? hits.join("\n") : "none");
failed ||= hits.length > 0;

console.log(failed ? "\nFAILED" : "\nALL CHECKS PASSED");
process.exit(failed ? 1 : 0);
