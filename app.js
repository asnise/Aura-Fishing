// Aura Fishing QA board. Static page: content comes from data/qadata.json (built from docs/TASKS.md),
// QA results, tickets and ideas live in three Firestore documents (qa/state, qa/tickets, qa/ideas).
// Quota: 3 document reads per load (cached 5 min in localStorage), 1 write per user action, no listeners.
const FB = 'https://www.gstatic.com/firebasejs/10.12.0/';
const CACHE_KEY = 'aura-qa-cache.v2';
const CACHE_MS = 5 * 60 * 1000;

const DEV = { done: 'เสร็จแล้ว', testing: 'รอ QA ตรวจ', progress: 'กำลังทำ', planned: 'ยังไม่เริ่ม', design: 'ออกแบบแล้ว' };
const RESULT = { none: 'ยังไม่ตรวจ', pass: 'ผ่าน', fail: 'ไม่ผ่าน' };
const SEVERITY = { low: 'ต่ำ', medium: 'กลาง', high: 'สูง', critical: 'วิกฤต' };
const IDEA_STATUS = { proposed: 'เสนอใหม่', discussing: 'กำลังคุย', approved: 'เอา (อนุมัติ)', rejected: 'ไม่เอา', done: 'ทำแล้ว' };
const IDEA_CATEGORY = { system: 'ระบบเกม', balance: 'บาลานซ์', content: 'คอนเทนต์', ui: 'UI / UX', monetize: 'รายได้', other: 'อื่น ๆ' };

const $ = selector => document.querySelector(selector);
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
const now = () => new Date().toISOString();
const when = iso => (iso ? new Date(iso).toLocaleString('th-TH', { dateStyle: 'short', timeStyle: 'short' }) : '');
const icon = path => `<svg viewBox="0 0 24 24" aria-hidden="true">${path}</svg>`;
const ICON = {
  refresh: icon('<polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>'),
  plus: icon('<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>'),
  pass: icon('<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>'),
  fail: icon('<circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>'),
  theme: icon('<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>'),
  login: icon('<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/>')
};

let data;
let backend;
let user = null;
let qa = { tasks: {} };
let tickets = { items: {} };
let ideas = { items: {} };
let syncedAt = 0;
const filters = { q: '', dev: '', result: '', group: '', iq: '', istatus: '', icat: '' };

// patch = { set: {field: value, votes: {key: 1}}, push: {history: entry, comments: entry} }
// Same semantics as the Firestore merge write below, so memory, local mode and Firestore stay in step.
function applyPatch(idea, { set = {}, push = {} }) {
  for (const [k, v] of Object.entries(set)) idea[k] = k === 'votes' ? { ...idea.votes, ...v } : v;
  for (const [k, v] of Object.entries(push)) (idea[k] ||= []).push(v);
  return idea;
}

// ---------- backends ----------
// Both expose: load() -> {qa, tickets, ideas}, saveTask, saveTicket, addComment, patchIdea(id, patch).
function localBackend() {
  const key = 'aura-qa-local.v1';
  const read = () => { try { return JSON.parse(localStorage.getItem(key)) || {}; } catch { return {}; } };
  const write = state => localStorage.setItem(key, JSON.stringify(state));
  return {
    name: 'local',
    async load() { const s = read(); return { qa: s.qa || { tasks: {} }, tickets: s.tickets || { items: {} }, ideas: s.ideas || { items: {} } }; },
    async patchIdea(id, patch) { const s = await this.load(); s.ideas.items[id] = applyPatch(s.ideas.items[id] || {}, patch); write(s); },
    async saveTask(id, value) { const s = await this.load(); s.qa.tasks[id] = value; write(s); },
    async saveTicket(id, ticket) { const s = await this.load(); s.tickets.items[id] = { ...s.tickets.items[id], ...ticket }; write(s); },
    async addComment(id, comment) { const s = await this.load(); s.tickets.items[id].comments.push(comment); write(s); }
  };
}

async function firebaseBackend(cfg) {
  const [{ initializeApp }, authLib, fs] = await Promise.all([
    import(FB + 'firebase-app.js'), import(FB + 'firebase-auth.js'), import(FB + 'firebase-firestore.js')
  ]);
  const app = initializeApp(cfg);
  const auth = authLib.getAuth(app);
  const db = fs.getFirestore(app);
  const stateRef = fs.doc(db, 'qa', 'state');
  const ticketsRef = fs.doc(db, 'qa', 'tickets');
  const ideasRef = fs.doc(db, 'qa', 'ideas');
  authLib.onAuthStateChanged(auth, u => { user = u && { name: u.displayName || u.email, email: u.email }; renderChrome(); render(); refreshDialog(); });
  return {
    name: 'firebase',
    signIn: () => authLib.signInWithPopup(auth, new authLib.GoogleAuthProvider()),
    signOut: () => authLib.signOut(auth),
    async load() {
      const [a, b, c] = await Promise.all([fs.getDoc(stateRef), fs.getDoc(ticketsRef), fs.getDoc(ideasRef).catch(() => null)]); // old rules without qa/ideas: ideas stay empty instead of breaking the page
      return { qa: a.data() || { tasks: {} }, tickets: b.data() || { items: {} }, ideas: c?.data() || { items: {} } };
    },
    patchIdea(id, { set = {}, push = {} }) {
      const fields = { ...set, ...Object.fromEntries(Object.entries(push).map(([k, v]) => [k, fs.arrayUnion(v)])) };
      return fs.setDoc(ideasRef, { items: { [id]: fields } }, { merge: true });
    },
    // setDoc + merge writes only the touched map key, so concurrent QA users do not overwrite each other.
    saveTask: (id, value) => fs.setDoc(stateRef, { tasks: { [id]: value } }, { merge: true }),
    saveTicket: (id, ticket) => fs.setDoc(ticketsRef, { items: { [id]: ticket } }, { merge: true }),
    addComment: (id, comment) => fs.setDoc(ticketsRef, { items: { [id]: { comments: fs.arrayUnion(comment) } } }, { merge: true })
  };
}

// ---------- data ----------
function applyLoaded(loaded, at) {
  qa = { tasks: loaded.qa.tasks || {} };
  tickets = { items: loaded.tickets.items || {} };
  ideas = { items: loaded.ideas?.items || {} };
  syncedAt = at;
}

async function load(force = false) {
  try {
    const cached = JSON.parse(localStorage.getItem(CACHE_KEY) || 'null');
    if (!force && cached && Date.now() - cached.at < CACHE_MS && cached.backend === backend.name) return applyLoaded(cached, cached.at);
  } catch { /* cache unreadable: fall through to a fresh read */ }
  try {
    applyLoaded(await backend.load(), Date.now());
    saveCache();
  } catch (err) {
    toast('โหลดข้อมูลไม่สำเร็จ: ' + err.message, true);
  }
}

function saveCache() {
  try { localStorage.setItem(CACHE_KEY, JSON.stringify({ at: syncedAt, backend: backend.name, qa, tickets, ideas })); } catch { /* storage full: cache is optional */ }
}

const taskById = id => data.tasks.find(t => t.id === id);
const resultOf = task => qa.tasks[task.id]?.r || 'none';
const changed = task => !!qa.tasks[task.id] && qa.tasks[task.id].h !== task.rev;
const openTickets = () => Object.entries(tickets.items).filter(([, t]) => t.status === 'open');

async function write(action, label) {
  if (!user && backend.name === 'firebase') return toast('ต้องเข้าสู่ระบบก่อน', true);
  try {
    await action();
    saveCache();
    toast(label);
    return true;
  } catch (err) {
    toast(err.code === 'permission-denied' ? 'บัญชีนี้ไม่มีสิทธิ์แก้ไข (ติดต่อผู้ดูแลเพื่อเพิ่มอีเมล)' : err.message, true);
    return false;
  }
}

// ---------- ui helpers ----------
function toast(message, error = false) {
  const el = $('#toast');
  el.textContent = message;
  el.classList.toggle('error', error);
  el.hidden = false;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => { el.hidden = true; }, 3500);
}

const badge = (kind, text) => `<span class="badge b-${kind}">${esc(text)}</span>`;
const canWrite = () => backend.name === 'local' || !!user;

function renderChrome() {
  $('#refreshBtn').innerHTML = ICON.refresh;
  $('#themeBtn').innerHTML = ICON.theme;
  const auth = $('#authBtn');
  auth.hidden = backend.name === 'local';
  auth.innerHTML = user ? esc(user.name) + ' · ออก' : ICON.login + ' เข้าสู่ระบบ';
  const sync = $('#syncInfo');
  sync.dataset.mode = backend.name;
  sync.textContent = (backend.name === 'local' ? 'โหมดทดลอง' : 'Firebase') + (syncedAt ? ' · โหลด ' + when(new Date(syncedAt).toISOString()) : '');
  const n = openTickets().length;
  $('#ticketCount').textContent = n;
  $('#ticketCount').hidden = !n;
  const open = Object.values(ideas.items).filter(i => i.status === 'proposed' || i.status === 'discussing').length;
  $('#ideaCount').textContent = open;
  $('#ideaCount').hidden = !open;
  const banner = $('#banner');
  banner.hidden = backend.name !== 'local';
  banner.textContent = 'โหมดทดลองในเครื่อง: ยังไม่ได้ตั้งค่า Firebase (qa/config.json) ผลตรวจและ Ticket จะเก็บในเบราว์เซอร์นี้เท่านั้น';
  const page = location.hash.slice(1).split('/')[0] || 'tasks';
  document.querySelectorAll('#nav a').forEach(a => a.toggleAttribute('aria-current', a.hash === '#' + page));
  $('#workspaceName').textContent = ({ tasks: 'ตรวจงาน', tickets: 'ตรวจงาน', ideas: 'ข้อเสนอ', systems: 'โปรเจกต์', log: 'โปรเจกต์' })[page] || 'QA';
}

function setTheme(theme) {
  document.documentElement.dataset.theme = theme;
  try { localStorage.setItem('aura-qa-theme', theme); } catch { /* theme still applies for this visit */ }
}

// ---------- pages ----------
const pages = { tasks: tasksPage, systems: systemsPage, tickets: ticketsPage, ideas: ideasPage, log: logPage };

function render() {
  renderChrome();
  const page = location.hash.slice(1).split('/')[0] || 'tasks';
  $('#view').innerHTML = (pages[page] || tasksPage)();
  bindFilters();
}

function tasksPage() {
  const list = data.tasks.filter(task => {
    const result = resultOf(task);
    if (filters.dev && task.status !== filters.dev) return false;
    if (filters.group && task.group !== filters.group) return false;
    if (filters.result === 'changed' ? !changed(task) : filters.result && result !== filters.result) return false;
    const q = filters.q.toLowerCase();
    return !q || [task.id, task.title, task.titleEn, task.note].some(v => String(v).toLowerCase().includes(q));
  });
  const count = r => data.tasks.filter(t => resultOf(t) === r && t.status !== 'planned').length;
  const toCheck = data.tasks.filter(t => t.status !== 'planned' && (resultOf(t) === 'none' || changed(t))).length;
  const option = (value, text, current) => `<option value="${value}"${current === value ? ' selected' : ''}>${text}</option>`;
  return `
    <header class="page-header">
      <div><h2>งานที่ต้องตรวจ</h2><p>${esc(data.stage.name)} · สร้างจาก docs/TASKS.md เมื่อ ${when(data.generated)}</p></div>
    </header>
    <dl class="stat-grid">
      <div class="stat"><dt>รอตรวจ</dt><dd>${toCheck}</dd><small>รวมงานที่แก้หลังตรวจ</small></div>
      <div class="stat"><dt>ผ่าน</dt><dd>${count('pass')}</dd><small>จาก ${data.tasks.filter(t => t.status !== 'planned').length} งาน</small></div>
      <div class="stat"><dt>ไม่ผ่าน</dt><dd>${count('fail')}</dd><small>ต้องให้ dev แก้</small></div>
      <div class="stat"><dt>Ticket เปิดอยู่</dt><dd>${openTickets().length}</dd><small>ทั้งหมด ${Object.keys(tickets.items).length}</small></div>
    </dl>
    <section class="panel">
      <div class="toolbar">
        <div class="toolbar-filters">
          <label class="field field-search"><span>ค้นหา</span><input type="search" id="fq" placeholder="ID หรือชื่องาน" value="${esc(filters.q)}"></label>
          <label class="field"><span>สถานะ dev</span><select id="fdev"><option value="">ทั้งหมด</option>${Object.entries(DEV).map(([k, v]) => option(k, v, filters.dev)).join('')}</select></label>
          <label class="field"><span>ผลตรวจ</span><select id="fresult"><option value="">ทั้งหมด</option>${Object.entries(RESULT).map(([k, v]) => option(k, v, filters.result)).join('')}${option('changed', 'แก้หลังตรวจ', filters.result)}</select></label>
          <label class="field"><span>หมวด</span><select id="fgroup"><option value="">ทั้งหมด</option>${option('A', 'A ต้นแบบ', filters.group)}${option('B', 'B UI', filters.group)}${option('C', 'C ระบบเกม', filters.group)}</select></label>
        </div>
        <p class="row-count">${list.length} จาก ${data.tasks.length} งาน</p>
      </div>
      <div class="table-scroll" tabindex="0">
        <table class="data-table">
          <thead><tr><th>ID</th><th>งาน</th><th>สถานะ dev</th><th>ผลตรวจ</th><th>ผู้ตรวจล่าสุด</th></tr></thead>
          <tbody>${list.map(task => {
            const state = qa.tasks[task.id];
            return `<tr data-open="${esc(task.id)}">
              <td><span class="id">${esc(task.id)}</span></td>
              <th scope="row">${esc(task.title)}${task.note ? `<small>${esc(task.note)}</small>` : ''}</th>
              <td>${badge(task.status, DEV[task.status])}</td>
              <td>${badge(resultOf(task), RESULT[resultOf(task)])} ${changed(task) ? badge('changed', 'แก้หลังตรวจ') : ''}${state?.c ? `<small>${esc(state.c)}</small>` : ''}</td>
              <td>${state ? `${esc(state.by)}<small>${when(state.at)}</small>` : '<span class="muted">-</span>'}</td>
            </tr>`;
          }).join('') || '<tr><td class="empty" colspan="5">ไม่พบงานที่ตรงกับตัวกรอง</td></tr>'}</tbody>
        </table>
      </div>
    </section>`;
}

function systemsPage() {
  const total = status => data.systems.filter(s => s.status === status).length;
  return `
    <header class="page-header"><div><h2>ระบบเกม</h2><p>${esc(data.stage.summary)}</p></div></header>
    <dl class="stat-grid">
      <div class="stat"><dt>เสร็จแล้ว</dt><dd>${total('done')}</dd></div>
      <div class="stat"><dt>รอ QA ตรวจ</dt><dd>${total('testing')}</dd></div>
      <div class="stat"><dt>กำลังทำ</dt><dd>${total('progress')}</dd></div>
      <div class="stat"><dt>ยังไม่เริ่ม / ออกแบบ</dt><dd>${total('planned') + total('design')}</dd></div>
    </dl>
    <section class="panel"><div class="table-scroll" tabindex="0"><table class="data-table">
      <thead><tr><th>ระบบ</th><th>สถานะ</th><th>รายละเอียด</th><th>งานที่เกี่ยวข้อง</th></tr></thead>
      <tbody>${data.systems.map(s => `<tr>
        <th scope="row">${esc(s.name)}</th>
        <td>${badge(s.status, DEV[s.status] || s.status)}</td>
        <td>${esc(s.summary)}</td>
        <td><div class="chips">${s.tasks.map(id => `<button class="chip" data-open="${esc(id)}" title="${esc(taskById(id)?.title || '')}">${esc(id)}</button>`).join('')}</div></td>
      </tr>`).join('')}</tbody>
    </table></div></section>`;
}

function ticketsPage() {
  const items = Object.entries(tickets.items).sort((a, b) => (b[1].at || '').localeCompare(a[1].at || ''));
  return `
    <header class="page-header">
      <div><h2>Ticket / บั๊ก</h2><p>แจ้งบั๊กหรือข้อสงสัย dev จะแก้แล้วบันทึกไว้ที่ Ticket ให้ QA ตรวจซ้ำและปิด</p></div>
      <button class="btn primary" data-new-ticket>${ICON.plus} แจ้ง Ticket</button>
    </header>
    <section class="panel">
      ${items.map(([id, t]) => {
        const fix = data.fixes[id];
        return `<article class="ticket">
          <header><span><span class="id">${esc(id)}</span> ${esc(t.title)}</span>
            <span>${badge(t.severity, SEVERITY[t.severity] || t.severity)} ${badge(t.status, t.status === 'open' ? 'เปิดอยู่' : 'ปิดแล้ว')} ${fix && t.status === 'open' ? badge('fixed', 'dev แก้แล้ว รอตรวจซ้ำ') : ''}</span></header>
          <small class="muted">${esc(t.by)} · ${when(t.at)}${t.task ? ` · งาน <button class="chip" data-open="${esc(t.task)}">${esc(t.task)}</button>` : ''}</small>
          ${t.steps ? `<p><b>ขั้นตอน</b>\n${esc(t.steps)}</p>` : ''}
          ${t.expected ? `<p><b>ควรเป็น</b> ${esc(t.expected)}</p>` : ''}
          ${t.actual ? `<p><b>ที่เกิดขึ้น</b> ${esc(t.actual)}</p>` : ''}
          ${fix ? `<div class="comment"><b>Dev (${when(fix.at)})</b>\n${esc(fix.note)}</div>` : ''}
          ${(t.comments || []).map(c => `<div class="comment"><b>${esc(c.by)}</b> <span class="muted">${when(c.at)}</span>\n${esc(c.text)}</div>`).join('')}
          <div class="row">
            <input data-comment="${esc(id)}" placeholder="เพิ่มความเห็น">
            <button class="btn" data-add-comment="${esc(id)}">ส่ง</button>
            <button class="btn ${t.status === 'open' ? 'pass' : ''}" data-toggle-ticket="${esc(id)}">${t.status === 'open' ? 'ปิด Ticket' : 'เปิดใหม่'}</button>
          </div>
        </article>`;
      }).join('') || '<p class="empty muted" style="padding:27px;text-align:center">ยังไม่มี Ticket</p>'}
    </section>`;
}

// ---------- ideas (forum-style proposals) ----------
const voteKey = () => (user?.email || user?.name || 'local').replace(/[.#$/[\]]/g, '_');
const score = idea => Object.values(idea.votes || {}).reduce((sum, v) => sum + v, 0);
const lastActivity = idea => idea.updatedAt || idea.at || '';

function ideasPage() {
  const q = filters.iq.toLowerCase();
  const all = Object.entries(ideas.items);
  const list = all
    .filter(([id, i]) => (!filters.istatus || i.status === filters.istatus) && (!filters.icat || i.category === filters.icat)
      && (!q || [id, i.title, i.body, i.by].some(v => String(v ?? '').toLowerCase().includes(q))))
    .sort((a, b) => lastActivity(b[1]).localeCompare(lastActivity(a[1])));
  const count = (...statuses) => all.filter(([, i]) => statuses.includes(i.status)).length;
  const option = (value, text, current) => `<option value="${value}"${current === value ? ' selected' : ''}>${text}</option>`;
  return `
    <header class="page-header">
      <div><h2>ข้อเสนอ / ไอเดีย</h2><p>โพสต์สิ่งที่อยากเพิ่มหรือเปลี่ยน แล้วมาช่วยกันโหวตและเคาะว่าจะเอาหรือไม่ ทุกการแก้ไขบันทึกเวลาไว้</p></div>
      <button class="btn primary" data-new-idea>${ICON.plus} โพสต์ไอเดีย</button>
    </header>
    <dl class="stat-grid">
      <div class="stat"><dt>เสนอใหม่</dt><dd>${count('proposed')}</dd><small>รอคนมาดู</small></div>
      <div class="stat"><dt>กำลังคุย</dt><dd>${count('discussing')}</dd><small>ยังไม่เคาะ</small></div>
      <div class="stat"><dt>เอา</dt><dd>${count('approved')}</dd><small>อนุมัติ รอทำ</small></div>
      <div class="stat"><dt>ปิดแล้ว</dt><dd>${count('rejected', 'done')}</dd><small>ไม่เอา หรือทำแล้ว</small></div>
    </dl>
    <section class="panel">
      <div class="toolbar">
        <div class="toolbar-filters">
          <label class="field field-search"><span>ค้นหา</span><input type="search" id="iq" placeholder="หัวข้อหรือรายละเอียด" value="${esc(filters.iq)}"></label>
          <label class="field"><span>สถานะ</span><select id="istatus"><option value="">ทั้งหมด</option>${Object.entries(IDEA_STATUS).map(([k, v]) => option(k, v, filters.istatus)).join('')}</select></label>
          <label class="field"><span>หมวด</span><select id="icat"><option value="">ทั้งหมด</option>${Object.entries(IDEA_CATEGORY).map(([k, v]) => option(k, v, filters.icat)).join('')}</select></label>
        </div>
        <p class="row-count">${list.length} จาก ${all.length} โพสต์</p>
      </div>
      ${list.map(([id, i]) => `
        <article class="idea" data-idea="${esc(id)}" tabindex="0">
          <header><span class="idea-title">${esc(i.title)}</span><span>${badge(i.status, IDEA_STATUS[i.status] || i.status)} ${badge('cat', IDEA_CATEGORY[i.category] || i.category)}</span></header>
          <p class="idea-excerpt">${esc((i.body || '').slice(0, 180))}${(i.body || '').length > 180 ? '...' : ''}</p>
          <small class="muted">${esc(i.by)} · โพสต์ ${when(i.at)}${i.updatedAt && i.updatedAt !== i.at ? ` · แก้ไขล่าสุด ${when(i.updatedAt)}` : ''} · โหวต ${score(i) > 0 ? '+' : ''}${score(i)} · ${(i.comments || []).length} ความเห็น</small>
        </article>`).join('') || '<p class="empty muted" style="padding:27px;text-align:center">ยังไม่มีโพสต์ที่ตรงกับตัวกรอง</p>'}
    </section>`;
}

function logPage() {
  return `
    <header class="page-header"><div><h2>ประวัติพัฒนา</h2><p>100 รายการล่าสุดจาก docs/TASKS.md</p></div></header>
    <section class="panel"><ul class="log">${data.history.map(h => `<li><time>${esc(h.at.slice(0, 16).replace('T', ' '))}</time><span>${esc(h.text)}</span></li>`).join('')}</ul></section>`;
}
function bindFilters() {
  const bind = (selector, key) => {
    const el = $(selector);
    if (!el) return;
    el.addEventListener('input', () => {
      filters[key] = el.value;
      const caret = el.selectionStart;
      render();
      if (key === 'q' || key === 'iq') { const next = $(selector); next.focus(); next.setSelectionRange(caret, caret); }
    });
  };
  bind('#fq', 'q'); bind('#fdev', 'dev'); bind('#fresult', 'result'); bind('#fgroup', 'group');
  bind('#iq', 'iq'); bind('#istatus', 'istatus'); bind('#icat', 'icat');
}

// ---------- dialogs ----------
const dialog = $('#dialog');
const closeBtn = '<button class="btn" value="cancel" formmethod="dialog" formnovalidate>ปิด</button>';

// Shown at the top of the check / ticket forms until the user signs in.
const loginNotice = () => (canWrite() ? '' : `
  <div class="notice">
    <span>${ICON.login} กรุณาเข้าสู่ระบบด้วย Google ก่อน จึงจะบันทึกผลตรวจ แจ้ง Ticket และโพสต์ไอเดียได้</span>
    <button class="btn primary" type="button" data-login>เข้าสู่ระบบ</button>
  </div>`);

function openTask(id) {
  const task = taskById(id);
  if (!task) return;
  const state = qa.tasks[id];
  const mine = Object.entries(tickets.items).filter(([, t]) => t.task === id);
  dialog.innerHTML = `
    <form method="dialog">
      ${loginNotice()}
      <h3><span class="id">${esc(task.id)}</span> ${esc(task.title)}</h3>
      <p>${badge(task.status, DEV[task.status])} ${badge(resultOf(task), RESULT[resultOf(task)])} ${changed(task) ? badge('changed', 'แก้หลังตรวจครั้งล่าสุด ต้องตรวจซ้ำ') : ''}</p>
      ${task.note ? `<p class="muted">${esc(task.note)}</p>` : ''}
      <h4>วิธีตรวจ</h4>
      ${task.steps.length
        ? `<ul class="steps">${task.steps.map((s, i) => `<li><label><input type="checkbox"><span>${i + 1}. ${esc(s)}</span></label></li>`).join('')}</ul>`
        : '<p class="muted">งานนี้ยังไม่มีขั้นตอนทดสอบใน docs/TASKS.md ให้ถาม dev หรือดูหัวข้องานนี้ในไฟล์ แล้วบันทึกผลที่เห็น</p>'}
      ${state ? `<p class="muted">ตรวจล่าสุดโดย ${esc(state.by)} · ${when(state.at)}</p>` : ''}
      ${mine.length ? `<p class="muted">Ticket ของงานนี้: ${mine.map(([tid, t]) => `${esc(tid)} (${t.status === 'open' ? 'เปิด' : 'ปิด'})`).join(', ')}</p>` : ''}
      <label class="field">ความเห็น QA (ผลตรวจ / สิ่งที่เห็น)<textarea id="qaComment">${esc(state?.c || '')}</textarea></label>
      <div class="actions">
        ${closeBtn}
        <button class="btn" type="button" data-ticket-for="${esc(id)}">${ICON.plus} แจ้ง Ticket</button>
        <button class="btn fail" type="button" data-result="fail" ${canWrite() ? '' : 'disabled'}>${ICON.fail} ไม่ผ่าน</button>
        <button class="btn pass" type="button" data-result="pass" ${canWrite() ? '' : 'disabled'}>${ICON.pass} ผ่าน</button>
      </div>
    </form>`;
  delete dialog.dataset.ideaId;
  dialog.dataset.task = id;
  dialog.showModal();
}

function openTicketForm(taskId = '') {
  dialog.innerHTML = `
    <form id="ticketForm" method="dialog">
      ${loginNotice()}
      <h3>แจ้ง Ticket</h3>
      <label class="field">หัวข้อ<input name="title" required maxlength="120"></label>
      <div class="grid2">
        <label class="field">งานที่เกี่ยวข้อง<select name="task"><option value="">ไม่ระบุ</option>${data.tasks.map(t => `<option value="${esc(t.id)}"${t.id === taskId ? ' selected' : ''}>${esc(t.id)} ${esc(t.title.slice(0, 40))}</option>`).join('')}</select></label>
        <label class="field">ความรุนแรง<select name="severity">${Object.entries(SEVERITY).map(([k, v]) => `<option value="${k}"${k === 'medium' ? ' selected' : ''}>${v}</option>`).join('')}</select></label>
      </div>
      <label class="field">ขั้นตอนทำซ้ำ<textarea name="steps" maxlength="2000"></textarea></label>
      <label class="field">ที่ควรเป็น<input name="expected" maxlength="500"></label>
      <label class="field">ที่เกิดขึ้นจริง (รวมข้อความแดงใน Output)<textarea name="actual" maxlength="2000"></textarea></label>
      <div class="actions">${closeBtn}<button class="btn primary" ${canWrite() ? '' : 'disabled'}>ส่ง Ticket</button></div>
    </form>`;
  delete dialog.dataset.ideaId;
  dialog.dataset.task = '';
  dialog.showModal();
}

const catOptions = current => Object.entries(IDEA_CATEGORY).map(([k, v]) => `<option value="${k}"${k === current ? ' selected' : ''}>${v}</option>`).join('');

function showDialog(html, key = '', value = '') {
  dialog.innerHTML = html;
  delete dialog.dataset.task;
  delete dialog.dataset.ideaId;
  if (key) dialog.dataset[key] = value;
  if (!dialog.open) dialog.showModal();
}

function openIdeaForm() {
  showDialog(`
    <form id="ideaForm" method="dialog">
      ${loginNotice()}
      <h3>โพสต์ไอเดีย</h3>
      <label class="field">หัวข้อ<input name="title" required maxlength="140" placeholder="สั้น ๆ ให้รู้ว่าเสนออะไร"></label>
      <label class="field">หมวด<select name="category">${catOptions('system')}</select></label>
      <label class="field">รายละเอียด (ทำไมถึงอยากได้ ทำงานยังไง ผลกระทบ)<textarea name="body" required maxlength="5000" style="min-height:160px"></textarea></label>
      <div class="actions">${closeBtn}<button class="btn primary" ${canWrite() ? '' : 'disabled'}>โพสต์</button></div>
    </form>`);
}

function openIdea(id) {
  const i = ideas.items[id];
  if (!i) return;
  const mine = (i.votes || {})[voteKey()] || 0;
  const ups = Object.values(i.votes || {}).filter(v => v > 0).length;
  const downs = Object.values(i.votes || {}).filter(v => v < 0).length;
  showDialog(`
    <form method="dialog">
      ${loginNotice()}
      <h3>${esc(i.title)}</h3>
      <p>${badge(i.status, IDEA_STATUS[i.status] || i.status)} ${badge('cat', IDEA_CATEGORY[i.category] || i.category)}</p>
      <p class="muted">${esc(i.by)} · โพสต์ ${when(i.at)}${i.updatedAt && i.updatedAt !== i.at ? ` · แก้ไขล่าสุด ${when(i.updatedAt)}` : ''}</p>
      <div class="comment idea-body">${esc(i.body)}</div>
      <div class="row">
        <button class="btn ${mine > 0 ? 'pass' : ''}" type="button" data-vote="1" ${canWrite() ? '' : 'disabled'}>เห็นด้วย ${ups}</button>
        <button class="btn ${mine < 0 ? 'fail' : ''}" type="button" data-vote="-1" ${canWrite() ? '' : 'disabled'}>ไม่เห็นด้วย ${downs}</button>
        <label class="field" style="flex-direction:row;align-items:center;gap:8px;margin:0 0 0 auto">สถานะ
          <select data-idea-status ${canWrite() ? '' : 'disabled'}>${Object.entries(IDEA_STATUS).map(([k, v]) => `<option value="${k}"${k === i.status ? ' selected' : ''}>${v}</option>`).join('')}</select></label>
      </div>
      <h4>ความเห็น (${(i.comments || []).length})</h4>
      ${(i.comments || []).map(c => `<div class="comment"><b>${esc(c.by)}</b> <span class="muted">${when(c.at)}</span>\n${esc(c.text)}</div>`).join('') || '<p class="muted">ยังไม่มีความเห็น</p>'}
      <div class="row">
        <input id="ideaComment" placeholder="เขียนความเห็น">
        <button class="btn" type="button" data-idea-comment ${canWrite() ? '' : 'disabled'}>ส่ง</button>
      </div>
      <h4>ประวัติการแก้ไข</h4>
      <ul class="history">${[...(i.history || [])].reverse().map(h => `<li><time>${when(h.at)}</time> <b>${esc(h.by)}</b> ${esc(h.text)}</li>`).join('')}</ul>
      <div class="actions">${closeBtn}<button class="btn" type="button" data-idea-edit ${canWrite() ? '' : 'disabled'}>แก้ไขโพสต์</button></div>
    </form>`, 'ideaId', id);
}

function openIdeaEdit(id) {
  const i = ideas.items[id];
  showDialog(`
    <form id="ideaEditForm" method="dialog">
      <h3>แก้ไขโพสต์</h3>
      <label class="field">หัวข้อ<input name="title" required maxlength="140" value="${esc(i.title)}"></label>
      <label class="field">หมวด<select name="category">${catOptions(i.category)}</select></label>
      <label class="field">รายละเอียด<textarea name="body" required maxlength="5000" style="min-height:160px">${esc(i.body)}</textarea></label>
      <div class="actions"><button class="btn" type="button" data-idea="${esc(id)}">ยกเลิก</button><button class="btn primary">บันทึก (จะลงเวลาแก้ไข)</button></div>
    </form>`, 'ideaId', id);
}

// After signing in, redraw an open form so its buttons and the login notice update.
function refreshDialog() {
  if (!dialog.open) return;
  if (dialog.dataset.ideaId) openIdea(dialog.dataset.ideaId);
  else if ($('#ideaForm')) openIdeaForm();
  else if (dialog.dataset.task) { const id = dialog.dataset.task; dialog.close(); openTask(id); }
  else if ($('#ticketForm')) { dialog.close(); openTicketForm(); }
}

// ---------- events ----------
const who = () => user?.name || 'local';

// One write per action: updates fields + appends a timestamped history entry (and optionally a comment).
async function ideaAction(id, { set = {}, push = {}, history, label }) {
  const at = now();
  const patch = {
    set: { ...set, updatedAt: at },
    push: { ...push, ...(history ? { history: { at, by: who(), type: history.type, text: history.text } } : {}) }
  };
  if (!(await write(() => backend.patchIdea(id, patch), label))) return false;
  applyPatch(ideas.items[id] ||= {}, patch);
  return true;
}

document.addEventListener('click', async event => {
  const el = event.target.closest('[data-open],[data-new-ticket],[data-ticket-for],[data-result],[data-add-comment],[data-toggle-ticket],[data-login],[data-idea],[data-new-idea],[data-vote],[data-idea-comment],[data-idea-edit]');
  if (!el) return;
  if (el.hasAttribute('data-login')) return backend.signIn().catch(err => toast(err.message, true));
  if (el.hasAttribute('data-new-idea')) return openIdeaForm();
  if (el.dataset.idea) return openIdea(el.dataset.idea);
  if (el.hasAttribute('data-idea-edit')) return openIdeaEdit(dialog.dataset.ideaId);
  if (el.dataset.vote) {
    const id = dialog.dataset.ideaId;
    const key = voteKey();
    const next = (ideas.items[id].votes?.[key] || 0) === Number(el.dataset.vote) ? 0 : Number(el.dataset.vote);
    if (await ideaAction(id, { set: { votes: { [key]: next } }, label: 'บันทึกโหวตแล้ว' })) { openIdea(id); render(); }
    return;
  }
  if (el.hasAttribute('data-idea-comment')) {
    const id = dialog.dataset.ideaId;
    const text = $('#ideaComment').value.trim();
    if (!text) return;
    const at = now();
    if (await ideaAction(id, { push: { comments: { by: who(), at, text } }, history: { type: 'comment', text: 'เพิ่มความเห็น' }, label: 'ส่งความเห็นแล้ว' })) { openIdea(id); render(); }
    return;
  }
  if (el.dataset.open) { event.stopPropagation(); if (!dialog.open) openTask(el.dataset.open); else { dialog.close(); openTask(el.dataset.open); } return; }
  if (el.hasAttribute('data-new-ticket')) return openTicketForm();
  if (el.dataset.ticketFor) { dialog.close(); return openTicketForm(el.dataset.ticketFor); }

  if (el.dataset.result) {
    const task = taskById(dialog.dataset.task);
    const value = { r: el.dataset.result, c: $('#qaComment').value.trim(), by: user?.name || 'local', at: now(), h: task.rev };
    if (value.r === 'fail' && !value.c) return toast('ไม่ผ่านต้องเขียนความเห็น (ข้อไหน / เห็นอะไร)', true);
    if (await write(() => backend.saveTask(task.id, value), 'บันทึกผล ' + task.id)) {
      qa.tasks[task.id] = value;
      dialog.close();
      render();
    }
    return;
  }

  const id = el.dataset.addComment || el.dataset.toggleTicket;
  if (el.dataset.addComment) {
    const input = document.querySelector(`[data-comment="${id}"]`);
    const comment = { by: user?.name || 'local', at: now(), text: input.value.trim() };
    if (!comment.text) return;
    if (await write(() => backend.addComment(id, comment), 'ส่งความเห็นแล้ว')) {
      (tickets.items[id].comments ||= []).push(comment);
      render();
    }
  } else {
    const t = tickets.items[id];
    const next = { ...t, status: t.status === 'open' ? 'closed' : 'open' };
    if (await write(() => backend.saveTicket(id, { status: next.status }), next.status === 'closed' ? 'ปิด Ticket แล้ว' : 'เปิด Ticket ใหม่')) {
      tickets.items[id] = next;
      render();
    }
  }
});

dialog.addEventListener('change', async event => {
  const select = event.target.closest('[data-idea-status]');
  if (!select) return;
  const id = dialog.dataset.ideaId;
  const from = ideas.items[id].status;
  if (select.value === from) return;
  const text = `เปลี่ยนสถานะ ${IDEA_STATUS[from] || from} > ${IDEA_STATUS[select.value]}`;
  if (await ideaAction(id, { set: { status: select.value }, history: { type: 'status', text }, label: 'เปลี่ยนสถานะแล้ว' })) { openIdea(id); render(); }
  else openIdea(id);
});

dialog.addEventListener('submit', async event => {
  if (event.submitter?.value === 'cancel') return; // the Close button: let the dialog close without saving
  const formId = event.target.id;
  if (formId === 'ideaForm') {
    event.preventDefault();
    const f = Object.fromEntries(new FormData(event.target));
    const id = 'I-' + Date.now().toString(36).toUpperCase();
    const at = now();
    const idea = { title: f.title.trim(), body: f.body.trim(), category: f.category, status: 'proposed', by: who(), at, updatedAt: at, votes: {}, comments: [], history: [{ at, by: who(), type: 'created', text: 'สร้างโพสต์' }] };
    if (await write(() => backend.patchIdea(id, { set: idea }), 'โพสต์ไอเดียแล้ว')) {
      ideas.items[id] = idea;
      dialog.close();
      location.hash = '#ideas';
      render();
    }
    return;
  }
  if (formId === 'ideaEditForm') {
    event.preventDefault();
    const id = dialog.dataset.ideaId;
    const f = Object.fromEntries(new FormData(event.target));
    const old = ideas.items[id];
    const parts = [f.title.trim() !== old.title && 'หัวข้อ', f.category !== old.category && 'หมวด', f.body.trim() !== old.body && 'รายละเอียด'].filter(Boolean);
    if (!parts.length) return openIdea(id);
    if (await ideaAction(id, { set: { title: f.title.trim(), body: f.body.trim(), category: f.category }, history: { type: 'edit', text: 'แก้ไข ' + parts.join(', ') }, label: 'บันทึกการแก้ไขแล้ว' })) { openIdea(id); render(); }
    return;
  }
  if (formId !== 'ticketForm') return;
  event.preventDefault();
  const f = Object.fromEntries(new FormData(event.target));
  const id = 'T-' + Date.now().toString(36).toUpperCase();
  const ticket = { title: f.title.trim(), task: f.task, severity: f.severity, steps: f.steps.trim(), expected: f.expected.trim(), actual: f.actual.trim(), status: 'open', by: user?.name || 'local', at: now(), comments: [] };
  if (await write(() => backend.saveTicket(id, ticket), 'สร้าง Ticket ' + id)) {
    tickets.items[id] = ticket;
    dialog.close();
    location.hash = '#tickets';
    render();
  }
});

dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });
$('#refreshBtn').addEventListener('click', async () => { await load(true); render(); toast('โหลดข้อมูลล่าสุดแล้ว'); });
$('#themeBtn').addEventListener('click', () => setTheme(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark'));
$('#authBtn').addEventListener('click', () => (user ? backend.signOut() : backend.signIn().catch(err => toast(err.message, true))));
window.addEventListener('hashchange', render);

// ---------- boot ----------
(async () => {
  try { setTheme(localStorage.getItem('aura-qa-theme') || 'dark'); } catch { /* keep default */ }
  data = await (await fetch('data/qadata.json')).json();
  data.fixes ||= {};
  const cfg = await fetch('config.json').then(r => r.json()).catch(() => ({}));
  // ?local forces the browser-only backend, handy for trying the UI without touching Firestore.
  const useFirebase = cfg.apiKey && !cfg.apiKey.startsWith('YOUR_') && !new URLSearchParams(location.search).has('local');
  backend = useFirebase ? await firebaseBackend(cfg) : localBackend();
  await load();
  render();
})();
