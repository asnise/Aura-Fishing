// Let an agent post to the Ideas forum (or comment on a post) using its own Firebase account.
//   node qa/tools/post.mjs --title "Co-op fishing" --category system --body "details..." [--status proposed]
//   node qa/tools/post.mjs --body-file report.md --title "Weekly summary" --category other
//   node qa/tools/post.mjs --comment I-ABC123 --body "Dev note: implemented in FishingService"
// Credentials: QA_AGENT_EMAIL / QA_AGENT_PASSWORD, from the environment or from qa/.agent.env (gitignored).
// Setup: Firebase console > Authentication > Email/Password on, add that user, turn OFF sign-ups,
// and put the email in qa/firestore.rules. Uses 1 sign-in + 1 Firestore commit (1 write) per call.
import { readFile } from 'node:fs/promises';

const root = new URL('../', import.meta.url);
const arg = name => { const i = process.argv.indexOf('--' + name); return i > 0 ? process.argv[i + 1] : undefined; };
const CATEGORIES = ['system', 'balance', 'content', 'ui', 'monetize', 'other'];
const STATUSES = ['proposed', 'discussing', 'approved', 'rejected', 'done'];

// --- Firestore REST typed values ---
export function encode(v) {
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(encode) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, encode(x)])) } };
}

async function main() {
  const env = Object.fromEntries((await readFile(new URL('.agent.env', root), 'utf8').catch(() => '')).split(/\r?\n/).filter(l => l.includes('=')).map(l => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()]));
  const email = process.env.QA_AGENT_EMAIL || env.QA_AGENT_EMAIL;
  const password = process.env.QA_AGENT_PASSWORD || env.QA_AGENT_PASSWORD;
  const { apiKey, projectId } = JSON.parse(await readFile(new URL('config.json', root), 'utf8'));
  if (!email || !password) throw new Error('Set QA_AGENT_EMAIL and QA_AGENT_PASSWORD (env or qa/.agent.env). See header of qa/tools/post.mjs.');

  const body = arg('body-file') ? await readFile(arg('body-file'), 'utf8') : arg('body');
  const commentOn = arg('comment');
  if (!body?.trim()) throw new Error('--body or --body-file is required');
  if (!commentOn && !arg('title')) throw new Error('--title is required for a new post');
  const category = arg('category') || 'other';
  const status = arg('status') || 'proposed';
  if (!CATEGORIES.includes(category)) throw new Error('--category must be one of ' + CATEGORIES.join(', '));
  if (!STATUSES.includes(status)) throw new Error('--status must be one of ' + STATUSES.join(', '));

  const login = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password, returnSecureToken: true })
  });
  if (!login.ok) throw new Error('Agent sign-in failed: ' + ((await login.json()).error?.message || login.status));
  const { idToken } = await login.json();

  const at = new Date().toISOString();
  const by = 'agent';
  const name = `projects/${projectId}/databases/(default)/documents/qa/ideas`;
  const path = id => `items.\`${id}\``; // ids contain "-", so field paths need backticks
  let id;
  let write;
  if (commentOn) {
    id = commentOn;
    write = {
      update: { name, fields: { items: encode({ [id]: { updatedAt: at } }) } },
      updateMask: { fieldPaths: [path(id) + '.updatedAt'] },
      updateTransforms: [
        { fieldPath: path(id) + '.comments', appendMissingElements: { values: [encode({ by, at, text: body.trim() })] } },
        { fieldPath: path(id) + '.history', appendMissingElements: { values: [encode({ at, by, type: 'comment', text: 'เพิ่มความเห็น' })] } }
      ]
    };
  } else {
    id = 'I-' + Date.now().toString(36).toUpperCase();
    const idea = { title: arg('title').trim(), body: body.trim(), category, status, by, at, updatedAt: at, votes: {}, comments: [], history: [{ at, by, type: 'created', text: 'สร้างโพสต์' }] };
    write = { update: { name, fields: { items: encode({ [id]: idea }) } }, updateMask: { fieldPaths: [path(id)] } };
  }

  const res = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + idToken }, body: JSON.stringify({ writes: [write] })
  });
  if (!res.ok) throw new Error(`Firestore commit failed: ${res.status} ${(await res.text()).slice(0, 300)}`);
  console.log(commentOn ? `Commented on ${id}` : `Posted ${id}`);
}

if (process.argv[1] && import.meta.url.endsWith(process.argv[1].replaceAll('\\', '/').split('/').pop())) {
  main().catch(err => { console.error(err.message); process.exit(1); });
}
