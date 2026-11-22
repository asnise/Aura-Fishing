// Record that a ticket was fixed (shown to QA as "dev fixed, please retest"), then rebuild qadata.json.
//   node qa/tools/fix.mjs T-ABC123 "Fixed hotspot ring not clearing; see HotspotService.luau"
import { readFile, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const [id, ...words] = process.argv.slice(2);
if (!/^T-/.test(id || '') || !words.length) { console.error('usage: node qa/tools/fix.mjs <ticketId> "note"'); process.exit(1); }
const file = new URL('../data/fixes.json', import.meta.url);
const fixes = JSON.parse(await readFile(file, 'utf8'));
fixes[id] = { note: words.join(' '), at: new Date().toISOString() };
await writeFile(file, JSON.stringify(fixes, null, 1) + '\n');
execFileSync(process.execPath, [fileURLToPath(new URL('build.mjs', import.meta.url))], { stdio: 'inherit' });
