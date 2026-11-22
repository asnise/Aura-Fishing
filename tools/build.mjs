// Build qa/data/qadata.json from docs/TASKS.md + qa/data/project.json + qa/data/fixes.json.
//   node qa/tools/build.mjs
// Agents run this after editing docs/TASKS.md. CI runs it again before every deploy.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

const root = new URL('../../', import.meta.url);
const read = path => readFile(new URL(path, root), 'utf8');
const plain = text => text.replaceAll('**', '').replaceAll('`', '').trim();

function taskStatus(done, note) {
  if (done.toLowerCase() === 'x') return 'done';
  if (/ยังไม่เริ่ม|เลื่อนไปทีหลัง/.test(note)) return 'planned';
  if (/โค้ด.*เสร็จ|ครบทุกส่วนในเกม|ทดสอบผ่าน Studio Bridge|รอทดสอบ/.test(note)) return 'testing';
  return 'progress';
}

// "- [x] A1 — title  `note`" lines of the overview checklist.
function tasksFrom(markdown, names) {
  const overview = markdown.split(/^## เตรียมก่อนทดสอบ/m)[0];
  const row = /^- \[([ xX])\] ([A-Z]\d+) [—–] (.+?)(?: {2,}`([^`]*)`)? *$/gm;
  return [...overview.matchAll(row)].map(([, done, id, title, note = '']) => ({
    id, group: id[0], title: plain(title), titleEn: names[id] || '', status: taskStatus(done, note), note: plain(note)
  }));
}

// The "- ทดสอบ" block under each "### A1." / "### B15 + B6 + B9." heading becomes the QA steps.
function stepsFrom(markdown) {
  const steps = new Map();
  const lines = markdown.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const heading = /^### ((?:[A-Z]\d+)(?:\s*\+\s*[A-Z]\d+)*)\./.exec(lines[i]);
    if (!heading) continue;
    const out = [];
    for (let j = i + 1; j < lines.length && !/^#{1,3} /.test(lines[j]); j++) {
      const m = /^- ทดสอบ(?: \(คุณ\))?:\s*(.*)$/.exec(lines[j]);
      if (!m) continue;
      if (m[1]) out.push(m[1]);
      for (let k = j + 1; k < lines.length && /^ {2,}- /.test(lines[k]); k++) out.push(lines[k].replace(/^ +- (\[[ xX]\] )?/, ''));
      break;
    }
    const list = out.map(l => plain(l.replace(/^\d+\. /, ''))).filter(Boolean);
    if (list.length) for (const id of heading[1].split('+')) steps.set(id.trim(), list);
  }
  return steps;
}

function historyFrom(markdown) {
  const [, log = ''] = markdown.split(/^## บันทึกการอัปเดต\s*$/m);
  const entry = /^- (\d{4}-\d{2}-\d{2})(?:[ T](\d{2}:\d{2}(?::\d{2})?)([+-]\d{2}:\d{2}|Z)?)? +[—–] (.+)$/gm;
  return [...log.matchAll(entry)].map(([, day, time, zone, text]) => ({ at: time ? `${day}T${time}${zone || '+07:00'}` : day, text: plain(text) }));
}

const project = JSON.parse(await read('qa/data/project.json'));
const fixes = JSON.parse(await read('qa/data/fixes.json').catch(() => '{}'));
const markdown = (await read('docs/TASKS.md')).replace(/\r\n/g, '\n');
const steps = stepsFrom(markdown);
const tasks = tasksFrom(markdown, project.taskNames);
if (!tasks.length) throw new Error('No tasks found in docs/TASKS.md overview checklist.');

// rev changes whenever dev status, note or test steps change: the app then flags the task "changed since last QA".
for (const task of tasks) {
  task.steps = steps.get(task.id) || [];
  task.rev = createHash('sha1').update(JSON.stringify([task.status, task.note, task.steps])).digest('hex').slice(0, 8);
}

const ts = e => Date.parse(e.at.length === 10 ? `${e.at}T00:00:00+07:00` : e.at);
const history = [...project.history.map(h => ({ at: h.at, text: h.text.th })), ...historyFrom(markdown)].sort((a, b) => ts(b) - ts(a)).slice(0, 100);

const systems = project.systems.map(s => ({ id: s.id, status: s.status, name: s.name.th, nameEn: s.name.en, summary: s.summary.th, tasks: s.tasks }));
const data = { generated: new Date().toISOString(), stage: { name: project.stage.name.th, summary: project.stage.summary.th }, systems, tasks, history, fixes };
await writeFile(new URL('qa/data/qadata.json', root), JSON.stringify(data, null, 1) + '\n');
console.log(`qadata.json: ${tasks.length} tasks (${tasks.filter(t => t.steps.length).length} with test steps), ${systems.length} systems, ${history.length} log entries`);
