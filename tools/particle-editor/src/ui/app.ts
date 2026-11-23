import { createLayer, createProject, parseProject } from "../model.js";
import type { Asset, Camera, Layer, Project, Tier } from "../model.js";
import { PreviewRenderer } from "../render/preview.js";
import { ApiError, eventsUrl, request, textureUrl } from "./api.js";
import type { FileState, Sample } from "./api.js";
import { button, byId, clamp, element, pressed } from "./dom.js";
import { Inspector } from "./inspector.js";
import type { InspectorMode, ProjectEdit } from "./inspector.js";
import { Library } from "./library.js";
import { Timeline } from "./timeline.js";

type Snapshot = { project: Project; layerId: string | null; assetId: string | null; mode: InspectorMode };

const canvas = byId<HTMLCanvasElement>("preview");
const workspace = byId("workspace");
const inspectorBody = byId("inspector-body");
const samplesDialog = byId<HTMLDialogElement>("samples-dialog");
const layerMenu = byId<HTMLSelectElement>("add-layer");
const tierMenu = byId<HTMLSelectElement>("preview-tier");
const speedMenu = byId<HTMLSelectElement>("playback-speed");
const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
const undoStack: Snapshot[] = [];
const redoStack: Snapshot[] = [];

let project = createProject();
let savedSignature = JSON.stringify(project);
let filePath: string | null = null;
let revision: string | null = null;
let assetVersion = 0;
let layerId: string | null = null;
let assetId: string | null = null;
let mode: InspectorMode = "properties";
let playing = false;
let playhead = 0;
let previewTier: Tier = 3;
let previewCamera: Camera | undefined;
let redraw = true;
let ready = false;
let busy: string | null = null;
let conflict = false;
let diskError: string | undefined;
let lastAssetError: string | undefined;
let feedback: { message: string; tone: "warning" | "info" } | undefined;
let queuedEvent = false;
let eventVersion = 0;

const renderer = new PreviewRenderer(canvas, (message) => {
  if (message === lastAssetError) return;
  lastAssetError = message;
  notify(`Texture preview failed. ${message}`);
});
const timeline = new Timeline(selectLayer, seek);
const library = new Library({ selectLayer, selectAsset, toggleLayer, renameLayer, texture });
const inspector = new Inspector({
  project: () => project,
  edit,
  texture,
  changeSheet: importTexture,
  useAsset: (id) => {
    const layer = activeLayer();
    if (!layer) return;
    edit((draft) => {
      const target = draft.layers.find((item) => item.id === layer.id);
      if (target) target.assetId = id;
    });
    selectLayer(layer.id, "properties");
  },
  spriteFromAsset: (id) => addLayer("sprite", id),
});

function texture(asset: Asset): string {
  return textureUrl(asset, assetVersion);
}

function activeLayer(): Layer | undefined {
  return project.layers.find((layer) => layer.id === layerId);
}

function activeAsset(): Asset | undefined {
  return project.assets.find((asset) => asset.id === assetId);
}

function notify(message: string, tone: "warning" | "info" = "warning"): void {
  feedback = { message, tone };
  updateChrome();
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function hasDraftInput(): boolean {
  return Array.from(inspectorBody.querySelectorAll<HTMLInputElement>("input[data-field]")).some((input) => input.value !== input.defaultValue && ["text", "number", "color"].includes(input.type));
}

function dirty(): boolean {
  return JSON.stringify(project) !== savedSignature || hasDraftInput();
}

function updateChrome(): void {
  const changed = dirty();
  const status = byId("file-status");
  status.dataset.dirty = String(changed);
  status.textContent = busy ?? (changed ? "Unsaved changes" : filePath ? "Saved" : ready ? "Untitled" : "Connecting");
  byId("file-name").textContent = project.name;
  const pathLabel = byId("file-path");
  pathLabel.textContent = filePath ?? "Unsaved project";
  pathLabel.title = filePath ?? "";
  document.title = `${project.name} | Aura Particle Editor`;

  workspace.inert = !ready || busy !== null;
  for (const id of ["new-file", "open-file", "save-file", "save-as", "open-samples", "reload-file", "copy-file"]) {
    byId<HTMLButtonElement>(id).disabled = busy !== null;
  }

  const notice = byId("notice");
  const message = conflict ? "The project changed on disk. Reload it or save your edits as a copy." : feedback?.message ?? diskError;
  notice.hidden = !message;
  notice.dataset.tone = conflict ? "warning" : feedback?.tone ?? "warning";
  byId("notice-message").textContent = message ?? "";
  byId("reload-file").hidden = !conflict;
  byId("copy-file").hidden = !conflict;
  byId("dismiss-notice").hidden = conflict || !feedback;
}

function syncRenderer(): void {
  redraw = true;
  void renderer.setProject(project, texture).then(() => { redraw = true; }).catch((error) => notify(errorMessage(error)));
}

function showInspector(preservePosition = false): void {
  if (mode === "sheet" && !activeLayer()) mode = "properties";
  if (mode === "asset" && !activeAsset()) mode = "properties";
  pressed(byId("properties-tab"), mode === "properties" || mode === "asset");
  pressed(byId("sheet-tab"), mode === "sheet");
  pressed(byId("scene-tab"), mode === "scene");
  byId<HTMLButtonElement>("sheet-tab").disabled = !activeLayer();
  inspector.show(mode, activeLayer(), activeAsset(), preservePosition);
}

function updateViews(rebuildInspector: boolean, preservePosition = true): void {
  if (!activeLayer()) layerId = project.layers[0]?.id ?? null;
  if (!activeAsset()) assetId = null;
  library.update(project, layerId, mode === "asset" ? assetId : null);
  timeline.update(project, layerId, previewTier);
  timeline.updateTime(playhead);
  timeline.updatePlaying(playing);
  pressed(byId("grid-toggle"), project.scene.grid);
  pressed(byId("model-toggle"), project.scene.mannequin);
  pressed(byId("loop"), project.loop);
  byId("empty-preview").hidden = project.layers.length > 0;
  if (rebuildInspector) showInspector(preservePosition);
  inspector.updateTime(playhead, true);
  updateChrome();
}

function snapshot(): Snapshot {
  return { project, layerId, assetId, mode };
}

function edit(change: ProjectEdit, rebuildInspector = false): boolean {
  if (!ready) return false;
  const before = snapshot();
  const draft = structuredClone(project);
  change(draft);
  let parsed: Project;
  try {
    parsed = parseProject(draft);
  } catch (error) {
    notify(errorMessage(error));
    return false;
  }
  if (JSON.stringify(parsed) === JSON.stringify(project)) return true;
  undoStack.push(before);
  if (undoStack.length > 45) undoStack.shift();
  redoStack.length = 0;
  project = parsed;
  const nextCamera = project.scene.camera;
  const oldCamera = before.project.scene.camera;
  if (nextCamera.yaw !== oldCamera.yaw || nextCamera.pitch !== oldCamera.pitch || nextCamera.zoom !== oldCamera.zoom) previewCamera = undefined;
  playhead = clamp(playhead, 0, project.duration);
  syncRenderer();
  updateViews(rebuildInspector);
  return true;
}

function restoreHistory(from: Snapshot[], to: Snapshot[]): void {
  const entry = from.pop();
  if (!entry) return;
  to.push(snapshot());
  ({ project, layerId, assetId, mode } = entry);
  playhead = clamp(playhead, 0, project.duration);
  previewCamera = undefined;
  syncRenderer();
  updateViews(true);
}

function selectLayer(id: string, nextMode: InspectorMode = mode === "sheet" ? "sheet" : "properties"): void {
  if (layerId === id && mode === nextMode) return;
  layerId = id;
  mode = nextMode;
  updateViews(true, false);
}

function selectAsset(id: string): void {
  if (mode === "asset" && assetId === id) return;
  assetId = id;
  mode = "asset";
  updateViews(true, false);
}

function renameLayer(id: string): void {
  selectLayer(id, "properties");
  inspector.renameLayer();
}

function toggleLayer(id: string): void {
  edit((draft) => {
    const layer = draft.layers.find((item) => item.id === id);
    if (layer) layer.visible = !layer.visible;
  }, mode === "properties" && layerId === id);
}

function addLayer(kind: Layer["kind"], textureId = assetId ?? project.assets[0]?.id ?? null): void {
  const layer = createLayer(kind, textureId);
  layer.timing.duration = project.duration;
  if (!edit((draft) => { draft.layers.push(layer); })) return;
  if (project.layers.length === 1 && playhead === 0) seek(Math.min(0.4, project.duration / 2));
  library.show("layers");
  selectLayer(layer.id, "properties");
}

function moveLayer(direction: -1 | 1): void {
  const index = project.layers.findIndex((layer) => layer.id === layerId);
  if (index < 0 || !project.layers[index + direction]) return;
  edit((draft) => {
    const [layer] = draft.layers.splice(index, 1);
    draft.layers.splice(index + direction, 0, layer);
  });
}

function duplicateLayer(): void {
  const layer = activeLayer();
  if (!layer) return;
  const copy = structuredClone(layer);
  copy.id = createLayer(layer.kind).id;
  copy.name += " copy";
  const index = project.layers.indexOf(layer);
  if (edit((draft) => { draft.layers.splice(index + 1, 0, copy); })) selectLayer(copy.id, "properties");
}

function deleteLayer(): void {
  const index = project.layers.findIndex((layer) => layer.id === layerId);
  if (index < 0) return;
  if (edit((draft) => { draft.layers.splice(index, 1); }, true)) {
    const next = project.layers[Math.min(index, project.layers.length - 1)];
    if (next) selectLayer(next.id, "properties");
  }
}

function seek(time: number): void {
  playing = false;
  playhead = clamp(time, 0, project.duration);
  timeline.updateTime(playhead);
  timeline.updatePlaying(playing);
  inspector.updateTime(playhead);
  redraw = true;
}

function togglePlaying(): void {
  if (playhead >= project.duration) playhead = 0;
  playing = !playing;
  timeline.updatePlaying(playing);
  timeline.updateTime(playhead);
  inspector.updateTime(playhead);
  redraw = true;
}

function acceptFile(next: FileState, behavior: "open" | "save" | "reload"): void {
  project = parseProject(next.project);
  savedSignature = JSON.stringify(project);
  if (behavior !== "save" || filePath !== next.path) {
    undoStack.length = 0;
    redoStack.length = 0;
  }
  filePath = next.path;
  revision = next.revision;
  assetVersion = next.assetVersion;
  diskError = next.error;
  conflict = false;
  feedback = undefined;
  lastAssetError = undefined;
  ready = true;
  if (behavior === "open") {
    layerId = project.layers[0]?.id ?? null;
    assetId = null;
    mode = layerId ? "properties" : "scene";
    library.show("layers");
    playhead = layerId ? Math.min(0.4, project.duration / 2) : 0;
    playing = layerId !== null && !reducedMotion.matches;
  } else {
    playhead = Math.min(playhead, project.duration);
  }
  if (behavior !== "save") previewCamera = undefined;
  syncRenderer();
  updateViews(true, behavior !== "open");
}

function settleInput(): void {
  if (document.activeElement instanceof HTMLInputElement) document.activeElement.blur();
}

function confirmReplacement(): boolean {
  settleInput();
  return !dirty() || window.confirm("Discard the unsaved changes to this project?");
}

async function fileOperation<T>(label: string, operation: () => Promise<T>, accept: (result: T) => void): Promise<void> {
  if (busy) return;
  busy = label;
  updateChrome();
  try {
    accept(await operation());
  } catch (error) {
    if (error instanceof ApiError && error.status === 409 && filePath) conflict = true;
    notify(errorMessage(error));
  } finally {
    busy = null;
    updateChrome();
    if (queuedEvent) {
      queuedEvent = false;
      const version = eventVersion;
      void request<FileState>("/api/session").then((state) => {
        if (eventVersion === version) receiveState(state);
      }).catch((error) => notify(errorMessage(error)));
    }
  }
}

function replaceFile(route: string, label: string, body: object = {}): void {
  if (busy || !confirmReplacement()) return;
  void fileOperation(label, () => request<FileState | null>(route, body), (next) => {
    if (next) acceptFile(next, "open");
  });
}

function save(saveAs = false): void {
  if (busy || !ready) return;
  settleInput();
  if (conflict && !saveAs) {
    updateChrome();
    return;
  }
  void fileOperation("Saving", () => request<FileState | null>("/api/save", { project, revision, saveAs }), (next) => {
    if (next) acceptFile(next, "save");
  });
}

function reloadFromDisk(): void {
  if (busy || !filePath || !confirmReplacement()) return;
  void fileOperation("Reloading", () => request<FileState>("/api/open", { path: filePath }), (next) => acceptFile(next, "reload"));
}

function importTexture(targetLayerId?: string): void {
  if (busy) return;
  void fileOperation("Importing texture", () => request<{ asset: Asset } | null>("/api/import", {}), (result) => {
    if (!result) return;
    const existing = project.assets.find((asset) => asset.path === result.asset.path);
    const imported = existing ?? result.asset;
    if (!edit((draft) => {
      if (!existing) draft.assets.push(imported);
      const target = draft.layers.find((layer) => layer.id === targetLayerId);
      if (target) target.assetId = imported.id;
    }, targetLayerId !== undefined)) return;
    if (targetLayerId === undefined) {
      library.show("assets");
      selectAsset(imported.id);
    }
  });
}

async function showExamples(): Promise<void> {
  if (busy || samplesDialog.open) return;
  const sampleList = byId("sample-list");
  sampleList.replaceChildren(element("p", "asset-info", "Loading examples"));
  samplesDialog.showModal();
  try {
    const samples = await request<Sample[]>("/api/samples");
    const items = samples.map((sample) => button(sample.name, () => {
      samplesDialog.close();
      replaceFile("/api/sample", "Opening example", { id: sample.id });
    }));
    sampleList.replaceChildren(...(items.length ? items : [element("p", "asset-info", "No examples found in this workspace.")]));
  } catch (error) {
    sampleList.replaceChildren(element("p", "asset-info", errorMessage(error)));
  }
}

function receiveState(next: FileState): void {
  if (busy) {
    queuedEvent = true;
    return;
  }
  if (!ready) {
    acceptFile(next, "open");
    return;
  }
  diskError = next.error;
  if (next.path !== filePath || next.revision !== revision) {
    if (!dirty()) {
      acceptFile(next, "reload");
      notify("Reloaded changes from disk.", "info");
      return;
    }
    conflict = true;
  }
  if (next.assetVersion !== assetVersion && next.path === filePath) {
    assetVersion = next.assetVersion;
    lastAssetError = undefined;
    syncRenderer();
    library.updateAssets(project.assets, mode === "asset" ? assetId : null);
    if (!hasDraftInput()) showInspector(true);
  }
  updateChrome();
}

function liveStatus(connected: boolean, label: string): void {
  const status = byId("live-status");
  status.dataset.live = String(connected);
  status.textContent = label;
}

function on(id: string, action: () => void): void {
  byId(id).addEventListener("click", action);
}

on("new-file", () => replaceFile("/api/new", "Creating project"));
on("open-file", () => replaceFile("/api/open", "Opening project"));
on("save-file", () => save());
on("save-as", () => save(true));
on("open-samples", () => void showExamples());
on("first-sample", () => void showExamples());
on("reload-file", reloadFromDisk);
on("copy-file", () => save(true));
on("dismiss-notice", () => { feedback = undefined; updateChrome(); });
on("first-layer", () => addLayer("sprite"));
on("raise-layer", () => moveLayer(-1));
on("lower-layer", () => moveLayer(1));
on("duplicate-layer", duplicateLayer);
on("delete-layer", deleteLayer);
on("import-png", () => importTexture());
on("properties-tab", () => { mode = "properties"; updateViews(true, false); });
on("sheet-tab", () => { mode = "sheet"; updateViews(true, false); });
on("scene-tab", () => { mode = "scene"; updateViews(true, false); });
on("play", togglePlaying);
on("rewind", () => seek(0));
on("loop", () => edit((draft) => { draft.loop = !draft.loop; }, mode === "scene"));
on("grid-toggle", () => edit((draft) => { draft.scene.grid = !draft.scene.grid; }, mode === "scene"));
on("model-toggle", () => edit((draft) => { draft.scene.mannequin = !draft.scene.mannequin; }, mode === "scene"));
on("reset-camera", () => { previewCamera = undefined; redraw = true; });

layerMenu.addEventListener("change", () => {
  const { value } = layerMenu;
  layerMenu.value = "";
  if (value === "sprite" || value === "emitter" || value === "ribbon") addLayer(value);
});
tierMenu.addEventListener("change", () => {
  previewTier = Number(tierMenu.value) as Tier;
  timeline.update(project, layerId, previewTier);
  redraw = true;
});
inspectorBody.addEventListener("input", updateChrome);
inspectorBody.addEventListener("change", updateChrome);

let orbit: { x: number; y: number; yaw: number; pitch: number } | undefined;
canvas.addEventListener("pointerdown", (event) => {
  if (event.button !== 0) return;
  const camera = previewCamera ?? project.scene.camera;
  orbit = { x: event.clientX, y: event.clientY, yaw: camera.yaw, pitch: camera.pitch };
  canvas.setPointerCapture(event.pointerId);
});
canvas.addEventListener("lostpointercapture", () => { orbit = undefined; });
canvas.addEventListener("pointermove", (event) => {
  if (!orbit || !canvas.hasPointerCapture(event.pointerId)) return;
  previewCamera = {
    yaw: orbit.yaw + (event.clientX - orbit.x) * 0.008,
    pitch: clamp(orbit.pitch + (event.clientY - orbit.y) * 0.008, 0.03, 1.45),
    zoom: (previewCamera ?? project.scene.camera).zoom,
  };
  redraw = true;
});
canvas.addEventListener("wheel", (event) => {
  event.preventDefault();
  const camera = previewCamera ?? project.scene.camera;
  previewCamera = { ...camera, zoom: clamp(camera.zoom * Math.exp(-event.deltaY * 0.0015), 0.2, 8) };
  redraw = true;
}, { passive: false });
new ResizeObserver(() => { redraw = true; inspector.updateTime(playhead, true); }).observe(canvas);

window.addEventListener("beforeunload", (event) => {
  if (!dirty()) return;
  event.preventDefault();
  event.returnValue = "";
});
window.addEventListener("keydown", (event) => {
  if (!ready || busy || samplesDialog.open || event.defaultPrevented) return;
  const key = event.key.toLowerCase();
  const modifier = event.ctrlKey || event.metaKey;
  const control = event.target instanceof Element && event.target.closest("input, select, textarea, [contenteditable='true']");
  let action: (() => void) | undefined;
  if (modifier && key === "s") action = () => save(event.shiftKey);
  else if (modifier && key === "o") action = () => replaceFile("/api/open", "Opening project");
  else if (modifier && key === "n") action = () => replaceFile("/api/new", "Creating project");
  else if (!control && modifier && key === "d") action = duplicateLayer;
  else if (!control && modifier && key === "z") action = () => event.shiftKey ? restoreHistory(redoStack, undoStack) : restoreHistory(undoStack, redoStack);
  else if (!control && modifier && key === "y") action = () => restoreHistory(redoStack, undoStack);
  else if (!control && !modifier && key === "delete") action = deleteLayer;
  else if (!control && !modifier && key === "f2" && layerId) action = () => { if (layerId) renameLayer(layerId); };
  else if (!control && !modifier && key === "home") action = () => seek(0);
  else if (!control && !modifier && key === " " && !(event.target instanceof HTMLButtonElement)) action = togglePlaying;
  if (action) {
    event.preventDefault();
    action();
  }
});

let lastTick = 0;
function tick(now: number): void {
  if (playing && lastTick) {
    playhead += Math.min(0.1, (now - lastTick) / 1000) * Number(speedMenu.value);
    if (playhead > project.duration) {
      if (project.loop) playhead %= project.duration;
      else seek(project.duration);
    }
    timeline.updateTime(playhead);
    inspector.updateTime(playhead);
    redraw = true;
  }
  if (redraw) {
    redraw = false;
    renderer.render(playhead, previewTier, previewCamera);
  }
  lastTick = now;
  requestAnimationFrame(tick);
}

async function boot(): Promise<void> {
  updateChrome();
  requestAnimationFrame(tick);
  try {
    acceptFile(await request<FileState>("/api/session"), "open");
  } catch (error) {
    notify(errorMessage(error));
  }
  const events = new EventSource(eventsUrl());
  events.addEventListener("open", () => liveStatus(true, "Live reload"));
  events.addEventListener("error", () => liveStatus(false, "Live reload disconnected"));
  events.addEventListener("message", (event) => {
    eventVersion += 1;
    try {
      receiveState(JSON.parse(event.data) as FileState);
    } catch (error) {
      notify(errorMessage(error));
    }
  });
}

void boot();
