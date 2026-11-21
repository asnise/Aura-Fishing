// Selection panel: shows what is selected in Figma (name, type, id, path),
// lets the user copy ids for the agent and write a note per node.
import { copyIdsButton, selCount, selList } from "./dom.js";
import { postToPlugin } from "./plugin.js";

let current = [];

export function copyText(text, button) {
  // navigator.clipboard is often blocked in the plugin iframe; use a temp textarea
  const ta = document.createElement("textarea");
  ta.value = text;
  document.body.appendChild(ta);
  ta.select();
  const copied = document.execCommand("copy");
  ta.remove();
  if (button && copied) {
    const old = button.textContent;
    button.textContent = "Copied";
    setTimeout(() => (button.textContent = old), 1200);
  }
  return copied;
}

function el(tag, className, text) {
  const e = document.createElement(tag);
  if (className) e.className = className;
  if (text !== undefined) e.textContent = text;
  return e;
}

function itemView(item) {
  const box = el("div", "sel-item");

  const row = el("div", "sel-row");
  const name = el("div", "sel-name", item.name);
  name.title = "Zoom to this layer";
  name.addEventListener("click", () => postToPlugin({ type: "focus-node", id: item.id }));
  row.appendChild(name);
  row.appendChild(el("span", "sel-type", item.image ? `${item.type} img` : item.type));
  row.appendChild(el("span", "sel-id", item.id));
  const copy = el("button", "secondary small", "Copy id");
  copy.addEventListener("click", () => copyText(item.id, copy));
  row.appendChild(copy);
  box.appendChild(row);

  if (item.path) {
    const path = el("div", "sel-path", item.path);
    path.title = item.path;
    box.appendChild(path);
  }

  const note = el("input", "sel-note");
  note.placeholder = "Note for the agent: what is this? (Enter to save)";
  note.value = item.note || "";
  const save = () => {
    if (note.value === (item.note || "")) return;
    item.note = note.value;
    postToPlugin({ type: "set-note", id: item.id, note: note.value });
    note.classList.add("saved");
    setTimeout(() => note.classList.remove("saved"), 800);
  };
  note.addEventListener("keydown", (e) => {
    if (e.key === "Enter") save();
  });
  note.addEventListener("blur", save);
  box.appendChild(note);

  return box;
}

export function renderSelection(data) {
  // Do not rebuild while the user is typing a note (keeps focus)
  if (document.activeElement && document.activeElement.classList.contains("sel-note")) {
    if (data.selection.map((s) => s.id).join() === current.map((s) => s.id).join()) return;
  }
  current = data.selection || [];
  selCount.textContent = String(data.selectionCount || 0);
  copyIdsButton.disabled = current.length === 0;
  selList.textContent = "";
  if (current.length === 0) {
    selList.appendChild(el("div", "sel-empty", "Nothing selected"));
    return;
  }
  for (const item of current) selList.appendChild(itemView(item));
  if (data.truncated) selList.appendChild(el("div", "sel-empty", `+${data.selectionCount - current.length} more`));
}

copyIdsButton.addEventListener("click", () => {
  const text = current.map((s) => `${s.name} (${s.id})${s.note ? " - " + s.note : ""}`).join("\n");
  copyText(text, copyIdsButton);
});
