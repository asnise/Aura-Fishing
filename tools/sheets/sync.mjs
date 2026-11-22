// Push project tasks and the update log to the shared Google Sheet.
//   node tools/sheets/sync.mjs                 dry run: show what would change
//   node tools/sheets/sync.mjs --apply         write QA_Tasks and Dev_Log
//   node tools/sheets/sync.mjs --apply --set B3=testing --set A12=done
// Sources: docs/TASKS.md (task checklist + "บันทึกการอัปเดต") and dashboard/data/project.json.
// The sheet owns Status / QA Comment / Tester / Last Updated for tasks it already has (QA team
// edits them); this script only adds new tasks, refreshes titles, and applies --set overrides.
import { readFile } from 'node:fs/promises';
import { loadProject } from '../../dashboard/snapshots.mjs';

const URL_ = 'https://script.google.com/macros/s/AKfycbwJ1af-Md2Pwi3yuVejTG0WikAgHZUqGq3ODriFQvclIBkWpz6XcN-ILDApYQzjiYbzjA/exec';
const LABEL = { done: 'Completed', testing: 'Ready for testing', progress: 'In progress', failed: 'Bug / Failed', planned: 'Not started', design: 'Not started' };
const args = process.argv.slice(2);
const apply = args.includes('--apply');
const overrides = Object.fromEntries(args.flatMap((a, i) => (a === '--set' ? [args[i + 1].split('=')] : [])));

function system(id) {
  if (['A1', 'A5', 'A6', 'B14', 'B18', 'B19'].includes(id)) return 'Fishing';
  if (['B3', 'B4', 'B8', 'B12', 'B20', 'B21', 'C2'].includes(id)) return 'Inventory';
  if (id === 'A11') return 'Save';
  if (id.startsWith('B') || ['A2', 'A4', 'A9', 'A15', 'A17'].includes(id)) return 'UI';
  return 'General';
}

// Test steps per task id: the "ทดสอบ" block under each "### <ids>." heading of docs/TASKS.md.
function testSteps(markdown) {
  const steps = new Map();
  const lines = markdown.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const heading = /^### ((?:[A-Z]\d+)(?:\s*\+\s*[A-Z]\d+)*)\./.exec(lines[i]);
    if (!heading) continue;
    const ids = heading[1].split('+').map(x => x.trim());
    const out = [];
    for (let j = i + 1; j < lines.length && !/^#{1,3} /.test(lines[j]); j++) {
      const m = /^- ทดสอบ(?: \(คุณ\))?:\s*(.*)$/.exec(lines[j]);
      if (!m) continue;
      if (m[1]) out.push(m[1]);
      for (let k = j + 1; k < lines.length && /^ {2,}- /.test(lines[k]); k++) out.push(lines[k].replace(/^ +- (\[[ xX]\] )?/, ''));
      break;
    }
    const text = out.map(l => l.replace(/[*`]/g, '').trim()).filter(Boolean).map((l, n) => (/^\d+\. /.test(l) ? l : `${n + 1}. ${l}`)).join('\n');
    if (text) for (const id of ids) steps.set(id, text);
  }
  return steps;
}

const NO_STEPS = 'ยังไม่มีขั้นตอนเฉพาะงานนี้ ให้ดูคำอธิบายใน docs/TASKS.md หรือถาม dev; ทดสอบตามขั้นตอนทั่วไปในแท็บ QA_Guide แล้วบันทึกผลใน QA Comment';

const GUIDE = [
  ['', 'วิธีตรวจงาน (QA) ทำตามลำดับ 1 > 2 > 3'],
  ['1', 'เตรียมเครื่อง: เปิด Roblox Studio > เปิด places/AuraFishing.rbxlx > Plugins > Rojo > Connect > กด Play (F5) เปิดหน้าต่าง Output (View > Output) ต้องไม่มีตัวแดง [Registry] Content errors'],
  ['2', 'เปิดแท็บ QA_Tasks กรองคอลัมน์ Status = "Ready for testing" แล้วเลือกตรวจทีละแถว (Not started = ยังไม่ทำ ไม่ต้องตรวจ, Completed = ผ่านแล้ว)'],
  ['3', 'อ่านคอลัมน์ "How to Test" แล้วทำตามข้อ 1, 2, 3 ตามลำดับ เทียบสิ่งที่เห็นกับที่เขียนไว้ในแต่ละข้อ'],
  ['', 'ผลการตรวจ'],
  ['PASS', 'ผ่านทุกข้อ: ตั้ง Status = "Completed" และเขียน QA Comment สั้น ๆ เช่น "Passed - Studio desktop" (Last Updated และ Tester เติมให้อัตโนมัติ)'],
  ['FAIL', 'ไม่ผ่านหรือเจอบั๊ก: ตั้ง Status = "Bug / Failed" แล้วเขียน QA Comment: (1) ข้อที่ไม่ผ่าน (2) สิ่งที่เห็นจริง vs สิ่งที่ควรเป็น (3) ขั้นตอนทำซ้ำ (4) ข้อความแดงใน Output ถ้ามี (5) ลิงก์ภาพ/วิดีโอ'],
  ['NEW', 'บั๊กที่ไม่เกี่ยวกับงานไหน: เพิ่มแถวใหม่ท้ายตาราง ID = BUG-1, BUG-2, ... Type = Bug เลือก System ใส่ Title สั้น ๆ Status = "Bug / Failed" และ QA Comment แบบ FAIL'],
  ['', 'หลังแก้บั๊ก'],
  ['FIX', 'Dev แก้แล้วจะตั้ง Status กลับเป็น "Ready for testing" และลงสรุปในแท็บ Dev_Log ให้ QA ตรวจซ้ำตามข้อ 3 อีกรอบ แล้วตั้ง Completed หรือ Bug / Failed ตามผล'],
  ['', 'ข้อห้าม'],
  ['NOTE', 'แก้ได้เฉพาะ Status, QA Comment, Tester อย่าแก้ ID, Title, How to Test เพราะ dev จะอัปเดตทับทุกรอบ ถ้าขั้นตอนไม่ชัดให้เขียนใน QA Comment']
];

async function call(path, body) {
  const res = await fetch(URL_ + path, body && { method: 'POST', headers: { 'Content-Type': 'text/plain;charset=utf-8' }, body: JSON.stringify(body), redirect: 'follow' });
  const data = await res.json();
  if (data.error) throw new Error(data.error);
  return data;
}

const project = await loadProject();
const remote = await call('');
const byId = new Map(remote.map(r => [r.id, r]));
const now = new Date().toLocaleString('sv-SE', { timeZone: 'Asia/Bangkok' });

const steps = testSteps(await readFile(new URL('../../docs/TASKS.md', import.meta.url), 'utf8'));
const merged = project.tasks.map(task => {
  const old = byId.get(task.id);
  const label = overrides[task.id] ? LABEL[overrides[task.id]] ?? overrides[task.id] : old?.status || LABEL[task.status];
  const changed = !old || (overrides[task.id] && label !== old.status);
  return {
    id: task.id, type: old?.type || 'Task', group: old?.group || system(task.id), title: task.name.th, status: label,
    qaComment: old?.qaComment || '', howTo: steps.get(task.id) || NO_STEPS, updatedAt: changed ? now : old.updatedAt, tester: old?.tester || 'QA'
  };
});
// Keep sheet-only rows (QA-1, BUG-3 ...) that QA added by hand.
const known = new Set(project.tasks.map(t => t.id));
merged.push(...remote.filter(r => !known.has(r.id)).map(r => {
  const label = overrides[r.id] ? LABEL[overrides[r.id]] ?? overrides[r.id] : r.status;
  return label === r.status ? r : { ...r, status: label, updatedAt: now };
}));

const added = merged.filter(t => !byId.has(t.id)).length;
const log = project.history.map(e => [e.at, e.source, e.text.th || e.text.en]);
console.log(`QA_Tasks: ${remote.length} in sheet -> ${merged.length} (${added} new, ${merged.length - remote.length - added} sheet-only kept)`);
console.log(`How to Test: ${merged.filter(t => t.howTo && t.howTo !== NO_STEPS).length} tasks with steps`);
console.log(`Dev_Log: ${log.length} entries`);
if (!apply) { console.log('Dry run. Add --apply to write.'); process.exit(0); }

console.log('QA_Tasks:', JSON.stringify(await call('', merged)));
try {
  console.log('QA_Guide:', JSON.stringify(await call('', { sheet: 'QA_Guide', rows: GUIDE })));
  console.log('Dev_Log:', JSON.stringify(await call('', { sheet: 'Dev_Log', rows: log })));
} catch (err) {
  console.log('Guide/Log skipped:', err.message, '(redeploy tools/sheets/setup_qa_sheet.gs as a new Web App version)');
}
