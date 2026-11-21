import { CHANNEL } from "./config.js";
import { postToPlugin } from "./plugin.js";
import { copyText } from "./selection.js";
import { formatHandoff } from "./handoff.js";

const $ = (id) => document.getElementById(id);
const inspect = $("work-inspect");
const motion = $("work-motion");
const workOutput = $("work-output");
const workCopy = $("work-copy");
const mode = $("handoff-mode");
const task = $("handoff-task");
const done = $("handoff-done");
const handoff = $("handoff-output");
let selection = { selection: [] };
let request = 0;

function updateHandoff() {
  handoff.value = formatHandoff({ channel: CHANNEL, selection, mode: mode.value, task: task.value, done: done.value });
}

function copyOutput(output, button) {
  if (!copyText(output.value, button)) {
    output.focus();
    output.select();
  }
}

function read(view) {
  const nodeId = selection.selection[0]?.id;
  if (!nodeId && view !== "commands") return;
  workOutput.value = "Reading...";
  workCopy.disabled = true;
  postToPlugin({ type: "workbench-read", view, nodeId, request: ++request });
}

inspect.addEventListener("click", () => read("layer"));
motion.addEventListener("click", () => read("motion"));
$("work-tools").addEventListener("click", () => read("commands"));
workCopy.addEventListener("click", () => copyOutput(workOutput, workCopy));
$("handoff-copy").addEventListener("click", (event) => copyOutput(handoff, event.currentTarget));
for (const input of [mode, task, done]) input.addEventListener("input", updateHandoff);

export function updateWorkbenchSelection(data) {
  const first = data.selection[0];
  if (first?.id !== selection.selection[0]?.id) {
    request++;
    workOutput.value = "";
    workCopy.disabled = true;
  }
  selection = data;
  $("work-selection").textContent = first ? `${first.name} (${first.id})` : "Select a layer in Figma.";
  inspect.disabled = motion.disabled = !first;
  updateHandoff();
}

export function renderWorkbenchResult(message) {
  if (message.request !== request) return;
  workOutput.value = message.error || JSON.stringify(message.result, null, 2);
  workCopy.disabled = !workOutput.value;
}
