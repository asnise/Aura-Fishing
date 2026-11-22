// Let an agent post to the Ideas forum (or comment on a post) with a Google service-account key.
//   node qa/tools/post.mjs --title "Co-op fishing" --category system --body "details..." [--status proposed]
//   node qa/tools/post.mjs --body-file report.md --title "Weekly summary" --category other
//   node qa/tools/post.mjs --comment I-ABC123 --body "Dev note: implemented in FishingService"
// Key: JSON file at qa/.agent-key.json (gitignored) or the path in QA_AGENT_KEY_FILE. Setup in qa/README.md.
// A service account is authorized by IAM, not by firestore.rules, so humans keep their email allowlist.
// Uses 1 token exchange + 1 Firestore commit (1 write) per call.
import { readFile } from 'node:fs/promises';
import { createSign } from 'node:crypto';
import { fileURLToPath } from 'node:url';

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

// Service-account JWT -> OAuth access token. cloud-platform scope is required for IAM auth to bypass firestore.rules; the account's role (Cloud Datastore User) still limits it to Firestore.
export async function accessToken(key) {
  const b64 = o => Buffer.from(JSON.stringify(o)).toString('base64url');
  const iat = Math.floor(Date.now() / 1000);
  const unsigned = b64({ alg: 'RS256', typ: 'JWT' }) + '.' + b64({ iss: key.client_email, scope: 'https://www.googleapis.com/auth/cloud-platform', aud: key.token_uri, iat, exp: iat + 600 });
  const jwt = unsigned + '.' + createSign('RSA-SHA256').update(unsigned).sign(key.private_key, 'base64url');
  const res = await fetch(key.token_uri, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jwt }) });
  const out = await res.json();
  if (!res.ok) throw new Error('Agent key rejected: ' + (out.error_description || out.error || res.status));
  return out.access_token;
}

async function main() {
  const keyPath = process.env.QA_AGENT_KEY_FILE || fileURLToPath(new URL('.agent-key.json', root));
  const keyText = await readFile(keyPath, 'utf8').catch(() => null);
  if (!keyText) throw new Error(`No agent key at ${keyPath}. Set it up as described in qa/README.md (or set QA_AGENT_KEY_FILE).`);
  const key = JSON.parse(keyText);
  const { projectId } = JSON.parse(await readFile(new URL('config.json', root), 'utf8'));
  // Cross-project keys work only if the account has Cloud Datastore User on the site's project (see README).
  if (key.project_id !== projectId) console.error(`Note: key is from project ${key.project_id}, site uses ${projectId}; needs IAM access there.`);

  const body = arg('body-file') ? await readFile(arg('body-file'), 'utf8') : arg('body');
  const commentOn = arg('comment');
  if (!body?.trim()) throw new Error('--body or --body-file is required');
  if (!commentOn && !arg('title')) throw new Error('--title is required for a new post');
  const category = arg('category') || 'other';
  const status = arg('status') || 'proposed';
  if (!CATEGORIES.includes(category)) throw new Error('--category must be one of ' + CATEGORIES.join(', '));
  if (!STATUSES.includes(status)) throw new Error('--status must be one of ' + STATUSES.join(', '));

  const idToken = await accessToken(key);

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
