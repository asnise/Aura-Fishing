// Selection awareness + per-node notes.
// @stability new - selection panel in the UI, notes read by get_selection / get_node_note
//
// The UI shows what is selected (name, type, id) so the user can hand an exact
// id to the agent instead of a name it has to search for. A note is a short
// human description stored on the node ("coin icon, buy button"). Agents use
// name + note to understand a layer; they do not need to analyse image pixels.

const NOTE_KEY = "agentNote";
const MAX_ITEMS = 30;

export function getNote(node) {
  try {
    return node.getPluginData(NOTE_KEY) || "";
  } catch (e) {
    return "";
  }
}

export function setNote(node, note) {
  node.setPluginData(NOTE_KEY, String(note || "").slice(0, 500));
}

function pathOf(node) {
  const names = [];
  let p = node.parent;
  while (p && p.type !== "PAGE" && p.type !== "DOCUMENT") {
    names.unshift(p.name);
    p = p.parent;
  }
  return names.join(" > ");
}

function imageInfo(node) {
  const fills = "fills" in node && Array.isArray(node.fills) ? node.fills : [];
  const images = fills.filter((f) => f && f.type === "IMAGE").length;
  return images > 0 ? { imageFills: images } : null;
}

/** Compact, agent-friendly description of one node (no pixels, no deep tree). */
export function describeNode(node) {
  const out = {
    id: node.id,
    name: node.name,
    type: node.type,
    visible: node.visible,
    path: pathOf(node),
  };
  const note = getNote(node);
  if (note) out.note = note;
  if ("width" in node) out.size = { w: Math.round(node.width), h: Math.round(node.height) };
  if (node.type === "TEXT") out.text = String(node.characters).slice(0, 120);
  if ("children" in node) out.childCount = node.children.length;
  const img = imageInfo(node);
  if (img) out.image = img;
  return out;
}

export function describeSelection() {
  const sel = figma.currentPage.selection;
  return {
    selectionCount: sel.length,
    page: { id: figma.currentPage.id, name: figma.currentPage.name },
    selection: sel.slice(0, MAX_ITEMS).map(describeNode),
    truncated: sel.length > MAX_ITEMS,
  };
}

export function pushSelectionToUi() {
  figma.ui.postMessage({ type: "selection", data: describeSelection() });
}

// UI -> plugin: save a note typed in the Selection panel
export async function saveNoteFromUi(msg) {
  const node = await figma.getNodeByIdAsync(msg.id);
  if (!node) return;
  setNote(node, msg.note);
  pushSelectionToUi();
}

// UI -> plugin: select + zoom to a node (clicking a row)
export async function focusFromUi(msg) {
  const node = await figma.getNodeByIdAsync(msg.id);
  if (node && "x" in node) figma.viewport.scrollAndZoomIntoView([node]);
}

export function watchSelection() {
  const push = () => {
    try {
      pushSelectionToUi();
    } catch (e) {
      console.error("selection update failed:", e);
    }
  };
  figma.on("selectionchange", push);
  figma.on("currentpagechange", push);
  push();
}
