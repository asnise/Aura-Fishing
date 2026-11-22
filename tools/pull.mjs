// Show what QA reported: failed tasks and open tickets (reads Firestore over public REST, 2 document reads).
//   node qa/tools/pull.mjs          (agents: run at the start of a session and after fixing)
import { readFile } from 'node:fs/promises';

const root = new URL('../', import.meta.url);
const { projectId } = JSON.parse(await readFile(new URL('config.json', root), 'utf8'));
if (!projectId || projectId.startsWith('YOUR_')) { console.log('qa/config.json is not set up yet (see qa/README.md).'); process.exit(0); }

// Firestore REST returns typed values ({stringValue: ...}); flatten them.
function decode(v) {
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('booleanValue' in v) return v.booleanValue;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(decode);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, decode(x)]));
  return null;
}
async function doc(name) {
  const res = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/qa/${name}`);
  if (res.status === 404) return {};
  if (res.status === 403 && name === 'ideas') { console.log('(qa/ideas is not readable yet: publish qa/firestore.rules)'); return {}; }
  if (!res.ok) throw new Error(`${name}: HTTP ${res.status}`);
  return decode({ mapValue: { fields: (await res.json()).fields } });
}

const data = JSON.parse(await readFile(new URL('data/qadata.json', root), 'utf8'));
const [state, tickets, ideas] = await Promise.all([doc('state'), doc('tickets'), doc('ideas')]);
const title = id => data.tasks.find(t => t.id === id)?.title ?? '';

const failed = Object.entries(state.tasks || {}).filter(([, s]) => s.r === 'fail');
const open = Object.entries(tickets.items || {}).filter(([id, t]) => t.status === 'open' && !data.fixes[id]);
console.log(`FAILED tasks (${failed.length})`);
for (const [id, s] of failed) console.log(`  ${id} ${title(id)}\n    ${s.by}: ${s.c}`);
console.log(`OPEN tickets without a dev fix (${open.length})`);
for (const [id, t] of open) console.log(`  ${id} [${t.severity}] ${t.title} (task ${t.task || '-'}) by ${t.by}\n    steps: ${t.steps}\n    expected: ${t.expected}\n    actual: ${t.actual}`);

// Ideas report: what is waiting for a decision, and what was approved but not built yet.
const all = Object.entries(ideas.items || {});
const score = i => Object.values(i.votes || {}).reduce((a, b) => a + b, 0);
const show = ([id, i]) => {
  console.log(`  ${id} [${i.category}] ${i.title}  (by ${i.by}, posted ${i.at}, updated ${i.updatedAt}, votes ${score(i)}, ${(i.comments || []).length} comments)`);
  console.log('    ' + String(i.body || '').split('\n').join('\n    '));
  for (const c of (i.comments || []).slice(-3)) console.log(`    > ${c.by} ${c.at}: ${c.text}`);
};
const group = (title, statuses) => { const list = all.filter(([, i]) => statuses.includes(i.status)); console.log(`${title} (${list.length})`); list.forEach(show); };
console.log('IDEAS summary: ' + ['proposed', 'discussing', 'approved', 'rejected', 'done'].map(k => `${k}=${all.filter(([, i]) => i.status === k).length}`).join(' '));
group('IDEAS waiting for a decision', ['proposed', 'discussing']);
group('IDEAS approved, not built yet', ['approved']);
console.log('After fixing: node qa/tools/fix.mjs <ticketId> "what changed"');
