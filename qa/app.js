// Aura Fishing QA board. Static page: content comes from data/qadata.json (built from docs/TASKS.md),
// QA results and tickets live in two Firestore documents (qa/state, qa/tickets).
// Quota: 2 document reads per load (cached 5 min in localStorage), 1 write per user action, no listeners.
const FB = 'https://www.gstatic.com/firebasejs/10.12.0/';
const CACHE_KEY = 'aura-qa-cache.v1';
const CACHE_MS = 5 * 60 * 1000;

const DEV = { done: 'เสร็จแล้ว', testing: 'รอ QA ตรวจ', progress: 'กำลังทำ', planned: 'ยังไม่เริ่ม', design: 'ออกแบบแล้ว' };
const RESULT = { none: 'ยังไม่ตรวจ', pass: 'ผ่าน', fail: 'ไม่ผ่าน' };
const SEVERITY = { low: 'ต่ำ', medium: 'กลาง', high: 'สูง', critical: 'วิกฤต' };

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
  login: icon('<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/>')
};

let data;
let backend;
let user = null;
let qa = { tasks: {} };
let tickets = { items: {} };
let syncedAt = 0;
const filters = { q: '', dev: '', result: '', group: '' };

// ---------- backends ----------
// Both expose: load() -> {qa, tickets}, saveTask(id, value), saveTicket(id, ticket), addComment(id, comment).
function localBackend() {
  const key = 'aura-qa-local.v1';
  const read = () => { try { return JSON.parse(localStorage.getItem(key)) || {}; } catch { return {}; } };
  const write = state => localStorage.setItem(key, JSON.stringify(state));
  return {
    name: 'local',
    async load() { const s = read(); return { qa: s.qa || { tasks: {} }, tickets: s.tickets || { items: {} } }; },
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
  authLib.onAuthStateChanged(auth, u => { user = u && { name: u.displayName || u.email, email: u.email }; renderChrome(); render(); });
  return {
    name: 'firebase',
    signIn: () => authLib.signInWithPopup(auth, new authLib.GoogleAuthProvider()),
    signOut: () => authLib.signOut(auth),
    async load() {
      const [a, b] = await Promise.all([fs.getDoc(stateRef), fs.getDoc(ticketsRef)]);
      return { qa: a.data() || { tasks: {} }, tickets: b.data() || { items: {} } };
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
  try { localStorage.setItem(CACHE_KEY, JSON.stringify({ at: syncedAt, backend: backend.name, qa, tickets })); } catch { /* storage full: cache is optional */ }
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
  const auth = $('#authBtn');
  auth.hidden = backend.name === 'local';
  auth.innerHTML = user ? esc(user.name) + ' · ออก' : ICON.login + ' เข้าสู่ระบบ';
  $('#syncInfo').textContent = syncedAt ? 'โหลดเมื่อ ' + when(new Date(syncedAt).toISOString()) : '';
  const n = openTickets().length;
  $('#ticketCount').textContent = n ? `(${n})` : '';
  const banner = $('#banner');
  banner.hidden = backend.name !== 'local';
  banner.textContent = 'โหมดทดลองในเครื่อง: ยังไม่ได้ตั้งค่า Firebase (qa/config.json) ผลตรวจและ Ticket จะเก็บในเบราว์เซอร์นี้เท่านั้น';
  const page = location.hash.slice(1) || 'tasks';
  document.querySelectorAll('#nav a').forEach(a => a.toggleAttribute('aria-current', a.hash === '#' + page));
}

// ---------- pages ----------
const pages = { tasks: tasksPage, systems: systemsPage, tickets: ticketsPage, log: logPage };

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
    <h2>ตรวจงาน</h2>
    <p class="sub">${esc(data.stage.name)} · ข้อมูลงานสร้างจาก docs/TASKS.md เมื่อ ${when(data.generated)}</p>
    <div class="cards">
      <div class="card"><b>${toCheck}</b>รอตรวจ / ต้องตรวจซ้ำ</div>
      <div class="card"><b>${count('pass')}</b>ผ่าน</div>
      <div class="card"><b>${count('fail')}</b>ไม่ผ่าน</div>
      <div class="card"><b>${openTickets().length}</b>Ticket ที่เปิดอยู่</div>
    </div>
    <div class="filters">
      <input type="search" id="fq" placeholder="ค้นหา ID หรือชื่องาน" value="${esc(filters.q)}">
      <select id="fdev"><option value="">สถานะ dev ทั้งหมด</option>${Object.entries(DEV).map(([k, v]) => option(k, v, filters.dev)).join('')}</select>
      <select id="fresult"><option value="">ผลตรวจทั้งหมด</option>${Object.entries(RESULT).map(([k, v]) => option(k, v, filters.result)).join('')}${option('changed', 'แก้หลังตรวจ (ต้องตรวจซ้ำ)', filters.result)}</select>
      <select id="fgroup"><option value="">ทุกหมวด</option>${option('A', 'A ต้นแบบ', filters.group)}${option('B', 'B UI', filters.group)}${option('C', 'C ระบบเกม', filters.group)}</select>
      <span class="count">${list.length} / ${data.tasks.length} งาน</span>
    </div>
    <div class="table-wrap"><table>
      <thead><tr><th>ID</th><th>งาน</th><th>สถานะ dev</th><th>ผลตรวจ</th><th>ผู้ตรวจล่าสุด</th></tr></thead>
      <tbody>${list.map(task => {
        const state = qa.tasks[task.id];
        return `<tr data-open="${esc(task.id)}">
          <td class="id">${esc(task.id)}</td>
          <td>${esc(task.title)}${task.note ? `<small>${esc(task.note)}</small>` : ''}</td>
          <td>${badge(task.status, DEV[task.status])}</td>
          <td>${badge(resultOf(task), RESULT[resultOf(task)])} ${changed(task) ? badge('changed', 'แก้หลังตรวจ') : ''}${state?.c ? `<small>${esc(state.c)}</small>` : ''}</td>
          <td>${state ? `${esc(state.by)}<small>${when(state.at)}</small>` : ''}</td>
        </tr>`;
      }).join('') || '<tr><td colspan="5" class="muted">ไม่พบงาน</td></tr>'}</tbody>
    </table></div>`;
}

function systemsPage() {
  return `
    <h2>ระบบเกม</h2>
    <p class="sub">${esc(data.stage.summary)}</p>
    <div class="systems">${data.systems.map(s => `
      <article class="card">
        <header><span>${esc(s.name)}</span>${badge(s.status, DEV[s.status] || s.status)}</header>
        <p class="muted">${esc(s.summary)}</p>
        <div class="chips">${s.tasks.map(id => `<button class="chip" data-open="${esc(id)}" title="${esc(taskById(id)?.title || '')}">${esc(id)}</button>`).join('')}</div>
      </article>`).join('')}</div>`;
}

function ticketsPage() {
  const items = Object.entries(tickets.items).sort((a, b) => (b[1].at || '').localeCompare(a[1].at || ''));
  return `
    <div class="row"><h2 style="flex:1">Ticket / บั๊ก</h2><button class="btn primary" data-new-ticket>${ICON.plus} แจ้ง Ticket</button></div>
    <p class="sub">แจ้งบั๊กหรือข้อสงสัย dev จะแก้แล้วบันทึกไว้ที่ Ticket ให้ QA ตรวจซ้ำและปิด</p>
    ${items.map(([id, t]) => {
      const fix = data.fixes[id];
      return `<article class="card ticket">
        <header><span><span class="id">${esc(id)}</span> ${esc(t.title)}</span>
          <span>${badge(t.severity, SEVERITY[t.severity] || t.severity)} ${badge(t.status, t.status === 'open' ? 'เปิดอยู่' : 'ปิดแล้ว')} ${fix && t.status === 'open' ? badge('fixed', 'dev แก้แล้ว รอตรวจซ้ำ') : ''}</span></header>
        <small class="muted">${esc(t.by)} · ${when(t.at)}${t.task ? ` · งาน <a class="chip" data-open="${esc(t.task)}">${esc(t.task)}</a>` : ''}</small>
        ${t.steps ? `<p><b>ขั้นตอน</b>\n${esc(t.steps)}</p>` : ''}
        ${t.expected ? `<p><b>ควรเป็น</b> ${esc(t.expected)}</p>` : ''}
        ${t.actual ? `<p><b>ที่เกิดขึ้น</b> ${esc(t.actual)}</p>` : ''}
        ${fix ? `<div class="comment"><b>Dev (${when(fix.at)})</b>\n${esc(fix.note)}</div>` : ''}
        ${(t.comments || []).map(c => `<div class="comment"><b>${esc(c.by)}</b> <span class="muted">${when(c.at)}</span>\n${esc(c.text)}</div>`).join('')}
        <div class="row">
          <input data-comment="${esc(id)}" placeholder="เพิ่มความเห็น" style="flex:1;min-width:200px;min-height:32px;padding:4px 8px;border:1px solid var(--line);border-radius:6px;background:var(--bg)">
          <button class="btn" data-add-comment="${esc(id)}">ส่ง</button>
          <button class="btn ${t.status === 'open' ? 'pass' : ''}" data-toggle-ticket="${esc(id)}">${t.status === 'open' ? 'ปิด Ticket' : 'เปิดใหม่'}</button>
        </div>
      </article>`;
    }).join('') || '<p class="muted">ยังไม่มี Ticket</p>'}`;
}

function logPage() {
  return `<h2>ประวัติการพัฒนา</h2><p class="sub">100 รายการล่าสุดจาก docs/TASKS.md</p>
    <ul class="log">${data.history.map(h => `<li><time>${esc(h.at.slice(0, 16).replace('T', ' '))}</time><span>${esc(h.text)}</span></li>`).join('')}</ul>`;
}

function bindFilters() {
  const bind = (selector, key) => {
    const el = $(selector);
    if (!el) return;
    el.addEventListener('input', () => {
      filters[key] = el.value;
      const caret = el.selectionStart;
      render();
      if (key === 'q') { const next = $(selector); next.focus(); next.setSelectionRange(caret, caret); }
    });
  };
  bind('#fq', 'q'); bind('#fdev', 'dev'); bind('#fresult', 'result'); bind('#fgroup', 'group');
}

// ---------- dialogs ----------
const dialog = $('#dialog');
const closeBtn = '<button class="btn" value="cancel" formmethod="dialog">ปิด</button>';

function openTask(id) {
  const task = taskById(id);
  if (!task) return;
  const state = qa.tasks[id];
  const mine = Object.entries(tickets.items).filter(([, t]) => t.task === id);
  dialog.innerHTML = `
    <form method="dialog">
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
      ${canWrite() ? '' : '<p class="muted">เข้าสู่ระบบเพื่อบันทึกผล</p>'}
    </form>`;
  dialog.dataset.task = id;
  dialog.showModal();
}

function openTicketForm(taskId = '') {
  dialog.innerHTML = `
    <form id="ticketForm" method="dialog">
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
  dialog.dataset.task = '';
  dialog.showModal();
}

// ---------- events ----------
document.addEventListener('click', async event => {
  const el = event.target.closest('[data-open],[data-new-ticket],[data-ticket-for],[data-result],[data-add-comment],[data-toggle-ticket]');
  if (!el) return;
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

dialog.addEventListener('submit', async event => {
  if (event.target.id !== 'ticketForm') return;
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
$('#authBtn').addEventListener('click', () => (user ? backend.signOut() : backend.signIn().catch(err => toast(err.message, true))));
window.addEventListener('hashchange', render);

// ---------- boot ----------
(async () => {
  data = await (await fetch('data/qadata.json')).json();
  data.fixes ||= {};
  const cfg = await fetch('config.json').then(r => r.json()).catch(() => ({}));
  backend = cfg.apiKey && !cfg.apiKey.startsWith('YOUR_') ? await firebaseBackend(cfg) : localBackend();
  await load();
  render();
})();
