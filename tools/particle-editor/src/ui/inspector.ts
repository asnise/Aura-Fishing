import type { Asset, Layer, Project, Rect, Sheet } from "../model.js";
import { button, byId, clamp, element } from "./dom.js";
import { SheetPreview } from "./sheet-preview.js";

export type InspectorMode = "properties" | "sheet" | "scene" | "asset";
export type ProjectEdit = (draft: Project) => void;

type Update<T> = (change: (draft: T) => void) => boolean;
type Commit<T> = (value: T) => boolean;

interface Actions {
  project: () => Project;
  edit: (change: ProjectEdit, rebuildInspector?: boolean) => boolean;
  texture: (asset: Asset) => string;
  changeSheet: (layerId: string) => void;
  useAsset: (id: string) => void;
  spriteFromAsset: (id: string) => void;
}

function setting<T, Key extends keyof T>(update: Update<T>, key: Key): Commit<T[Key]> {
  return (value) => update((target) => { target[key] = value; });
}

function field(label: string, input: HTMLElement, compact = false): HTMLLabelElement {
  const result = element("label", compact ? "field compact-field" : "field");
  result.append(element("span", "", label), input);
  input.dataset.field = input.getAttribute("aria-label") ?? label;
  return result;
}

function textField(label: string, value: string, commit: Commit<string>): HTMLLabelElement {
  const input = element("input");
  input.defaultValue = value;
  input.value = value;
  input.required = true;
  input.addEventListener("change", () => {
    const next = input.value.trim();
    if (next && next !== value && commit(next)) value = next;
    input.value = value;
    input.defaultValue = value;
  });
  input.addEventListener("keydown", (event) => { if (event.key === "Enter") input.blur(); });
  return field(label, input);
}

function numericInput(value: number, min: number, max: number, commit: Commit<number>, integer: boolean): HTMLInputElement {
  const input = element("input");
  input.type = "number";
  input.defaultValue = String(value);
  input.value = input.defaultValue;
  input.step = integer ? "1" : "any";
  input.min = String(min);
  input.max = String(max);
  input.addEventListener("change", () => {
    const numeric = input.valueAsNumber;
    if (Number.isFinite(numeric)) {
      const next = clamp(integer ? Math.round(numeric) : numeric, min, max);
      if (next !== value && commit(next)) value = next;
    }
    input.value = String(value);
    input.defaultValue = input.value;
  });
  input.addEventListener("keydown", (event) => { if (event.key === "Enter") input.blur(); });
  return input;
}

function numberField(label: string, value: number, min: number, max: number, commit: Commit<number>, integer = false): HTMLLabelElement {
  return field(label, numericInput(value, min, max, commit, integer));
}

function vectorField(
  label: string, value: readonly number[], axisLabels: string[], min: number, max: number,
  commit: (index: number, value: number) => boolean,
): HTMLElement {
  const row = element("div", "vector-fields");
  value.forEach((component, index) => {
    const axis = axisLabels[index];
    const input = numericInput(component, min, max, (next) => commit(index, next), false);
    input.setAttribute("aria-label", `${label} ${axis}`);
    row.append(field(axis, input, true));
  });
  const group = element("div", "vector-control");
  group.append(element("span", "vector-label", label), row);
  return group;
}

function selectField<T extends string>(label: string, value: T, options: readonly [T, string][], commit: Commit<T>): HTMLLabelElement {
  const select = element("select");
  for (const [option, label] of options) {
    const item = element("option", "", label);
    item.value = option;
    select.append(item);
  }
  select.value = value;
  select.addEventListener("change", () => {
    const next = select.value as T;
    if (next !== value && commit(next)) value = next;
    select.value = value;
  });
  return field(label, select);
}

function booleanField(label: string, value: boolean, commit: Commit<boolean>): HTMLLabelElement {
  const input = element("input");
  input.type = "checkbox";
  input.checked = value;
  input.addEventListener("change", () => {
    if (commit(input.checked)) value = input.checked;
    input.checked = value;
  });
  return field(label, input);
}

function colorField(label: string, value: string, commit: Commit<string>): HTMLLabelElement {
  const input = element("input");
  input.type = "color";
  input.defaultValue = value;
  input.value = value;
  input.addEventListener("change", () => {
    if (input.value !== value && commit(input.value)) value = input.value;
    input.value = value;
    input.defaultValue = value;
  });
  return field(label, input);
}

function section(title: string, ...fields: HTMLElement[]): HTMLElement {
  const result = element("section", "inspector-section");
  result.append(element("h3", "", title), ...fields);
  return result;
}

function heading(name: string, kind?: Layer["kind"]): HTMLElement {
  const result = element("div", "inspector-heading");
  if (kind) {
    result.dataset.kind = kind;
    result.append(element("span", "kind-mark"));
  }
  result.append(element("h2", "", name));
  return result;
}

export class Inspector {
  private readonly body = byId("inspector-body");
  private preview: SheetPreview | null = null;
  private time = 0;

  constructor(private readonly actions: Actions) {}

  show(mode: InspectorMode, layer: Layer | undefined, asset: Asset | undefined, preservePosition: boolean): void {
    const focused = document.activeElement;
    const scroll = preservePosition ? this.body.scrollTop : 0;
    const fieldName = preservePosition && focused instanceof HTMLElement && this.body.contains(focused) ? focused.dataset.field : undefined;
    this.preview = null;

    if (mode === "scene") this.showScene(this.actions.project());
    else if (mode === "asset" && asset) this.showAsset(asset, layer !== undefined);
    else if (mode === "sheet" && layer) this.showSheet(layer);
    else if (layer) this.showLayer(layer);
    else this.body.replaceChildren(element("p", "empty-inspector", "Select or add a layer to edit it."));

    this.body.scrollTop = scroll;
    if (fieldName) {
      const control = this.body.querySelector<HTMLElement>(`[data-field="${CSS.escape(fieldName)}"]`);
      control?.focus({ preventScroll: true });
    }
    this.updateTime(this.time, true);
  }

  updateTime(time: number, force = false): void {
    this.time = time;
    this.preview?.update(time, force);
  }

  renameLayer(): void {
    const name = this.body.querySelector<HTMLInputElement>(`[data-field="Layer name"]`);
    name?.focus();
    name?.select();
  }

  private updateLayer(id: string, change: (layer: Layer) => void, rebuild = false): boolean {
    return this.actions.edit((draft) => {
      const layer = draft.layers.find((item) => item.id === id);
      if (layer) change(layer);
    }, rebuild);
  }

  private textureField(layer: Layer, rebuild = false): HTMLElement {
    const textures: [string, string][] = [["", "None"], ...this.actions.project().assets.map((asset): [string, string] => [asset.id, asset.name])];
    return selectField("Texture", layer.assetId ?? "", textures, (value) => this.updateLayer(layer.id, (target) => {
      target.assetId = value || null;
    }, rebuild));
  }

  private showLayer(layer: Layer): void {
    const header = heading(layer.name, layer.kind);
    const update: Update<Layer> = (change) => this.updateLayer(layer.id, change);
    const timing: Update<Layer["timing"]> = (change) => update((target) => change(target.timing));
    const controls = section("Layer",
      textField("Layer name", layer.name, (value) => {
        if (!setting(update, "name")(value)) return false;
        const title = header.querySelector("h2");
        if (title) title.textContent = value;
        return true;
      }),
      this.textureField(layer),
      selectField("Quality tier", String(layer.tier), [["1", "1"], ["2", "2"], ["3", "3"]], (value) => setting(update, "tier")(Number(value) as Layer["tier"])),
      booleanField("Visible", layer.visible, setting(update, "visible")),
    );
    const appearance = section("Appearance",
      colorField("Tint", layer.color, setting(update, "color")),
      numberField("Opacity", layer.opacity, 0, 1, setting(update, "opacity")),
      selectField("Blend", layer.blend, [["screen", "Screen"], ["add", "Additive"], ["normal", "Normal"]], setting(update, "blend")),
    );
    const transform = section("Transform",
      vectorField("Position", layer.position, ["X", "Y", "Z"], -1000, 1000, (index, value) => update((target) => { target.position[index] = value; })),
      vectorField("Size", layer.size, ["W", "H"], 0.001, 1000, (index, value) => update((target) => { target.size[index] = value; })),
      vectorField("Anchor", layer.anchor, ["X", "Y"], -4, 4, (index, value) => update((target) => { target.anchor[index] = value; })),
      numberField("Rotation (deg)", layer.rotation, -36000, 36000, setting(update, "rotation")),
    );
    const time = section("Timing",
      numberField("Start (s)", layer.timing.start, 0, 600, setting(timing, "start")),
      numberField("Duration (s)", layer.timing.duration, 0.01, 600, setting(timing, "duration")),
      numberField("Speed", layer.timing.speed, 0.01, 100, setting(timing, "speed")),
      numberField("Offset (s)", layer.timing.offset, -600, 600, setting(timing, "offset")),
      numberField("Fade in (s)", layer.timing.fadeIn, 0, 600, setting(timing, "fadeIn")),
      numberField("Fade out (s)", layer.timing.fadeOut, 0, 600, setting(timing, "fadeOut")),
    );
    this.body.replaceChildren(header, controls, appearance, transform, this.effectSettings(layer, update), time);
  }

  private effectSettings(layer: Layer, update: Update<Layer>): HTMLElement {
    if (layer.kind === "sprite") {
      const settings: Update<typeof layer.sprite> = (change) => update((target) => { if (target.kind === "sprite") change(target.sprite); });
      const { sprite } = layer;
      return section("Sprite",
        selectField("Plane", sprite.plane, [["billboard", "Billboard"], ["ground", "Ground"]], setting(settings, "plane")),
        numberField("Start scale", sprite.scaleStart, 0, 30, setting(settings, "scaleStart")),
        numberField("End scale", sprite.scaleEnd, 0, 30, setting(settings, "scaleEnd")),
        numberField("Depth bias", sprite.depthBias, -1000, 1000, setting(settings, "depthBias")),
      );
    }
    if (layer.kind === "emitter") {
      const settings: Update<typeof layer.emitter> = (change) => update((target) => { if (target.kind === "emitter") change(target.emitter); });
      const { emitter } = layer;
      return section("Emitter",
        numberField("Rate (/s)", emitter.rate, 0, 600, setting(settings, "rate")),
        numberField("Burst", emitter.burst, 0, 600, setting(settings, "burst"), true),
        numberField("Lifetime (s)", emitter.lifetime, 0.01, 60, setting(settings, "lifetime")),
        numberField("Speed", emitter.speed, 0, 250, setting(settings, "speed")),
        numberField("Spread (deg)", emitter.spread, 0, 360, setting(settings, "spread")),
        numberField("Radius", emitter.radius, 0, 250, setting(settings, "radius")),
        vectorField("Direction", emitter.direction, ["X", "Y", "Z"], -250, 250, (index, value) => settings((target) => { target.direction[index] = value; })),
        booleanField("Radial", emitter.radial, setting(settings, "radial")),
        numberField("Gravity", emitter.gravity, -250, 250, setting(settings, "gravity")),
        numberField("Drag", emitter.drag, 0, 30, setting(settings, "drag")),
        numberField("Spin (deg/s)", emitter.spin, -3600, 3600, setting(settings, "spin")),
        numberField("End size", emitter.sizeEnd, 0, 30, setting(settings, "sizeEnd")),
        booleanField("Random frame", emitter.randomFrame, setting(settings, "randomFrame")),
        numberField("Seed", emitter.seed, -2147483648, 2147483647, setting(settings, "seed"), true),
      );
    }
    const settings: Update<typeof layer.ribbon> = (change) => update((target) => { if (target.kind === "ribbon") change(target.ribbon); });
    const { ribbon } = layer;
    return section("Ribbon",
      numberField("Radius", ribbon.radius, 0.001, 250, setting(settings, "radius")),
      numberField("Tilt (deg)", ribbon.tilt, -360, 360, setting(settings, "tilt")),
      numberField("Arc (deg)", ribbon.arc, 1, 360, setting(settings, "arc")),
      numberField("Speed (deg/s)", ribbon.speed, -3600, 3600, setting(settings, "speed")),
      numberField("Phase (deg)", ribbon.phase, -36000, 36000, setting(settings, "phase")),
      numberField("Scroll", ribbon.scroll, -100, 100, setting(settings, "scroll")),
      booleanField("Taper", ribbon.taper, setting(settings, "taper")),
    );
  }

  private showSheet(layer: Layer): void {
    const { sheet } = layer;
    const asset = this.actions.project().assets.find((item) => item.id === layer.assetId);
    if (asset) {
      this.preview = new SheetPreview(
        () => this.actions.project().layers.find((item) => item.id === layer.id) ?? layer,
        asset,
        this.actions.texture(asset),
      );
    }
    const source = section("Sheet source",
      this.textureField(layer, true),
      button("Change sheet", () => this.actions.changeSheet(layer.id)),
    );
    const preview = this.preview?.section ?? section("Frame preview", element("p", "sheet-message", "Select a texture to preview its frames."));
    const update: Update<Sheet> = (change) => this.updateLayer(layer.id, (target) => change(target.sheet));
    const updateGrid = (axis: "columns" | "rows", value: number) => this.updateLayer(layer.id, ({ sheet }) => {
      const coveredLastCell = sheet.last === sheet.columns * sheet.rows - 1;
      sheet[axis] = value;
      const max = sheet.columns * sheet.rows - 1;
      sheet.first = Math.min(sheet.first, max);
      sheet.last = coveredLastCell ? max : clamp(sheet.last, sheet.first, max);
    }, true);
    const toggleCrop = (enabled: boolean) => this.updateLayer(layer.id, ({ sheet }) => {
      const [width, height] = this.preview?.dimensions ?? [1, 1];
      sheet.crop = enabled ? { x: 0, y: 0, width, height } : null;
    }, true);
    const grid = section("Grid",
      numberField("Columns", sheet.columns, 1, 64, (value) => updateGrid("columns", value), true),
      numberField("Rows", sheet.rows, 1, 64, (value) => updateGrid("rows", value), true),
      numberField("Margin (px)", sheet.margin, 0, 4096, setting(update, "margin"), true),
      numberField("Gap (px)", sheet.gap, 0, 4096, setting(update, "gap"), true),
      booleanField("Crop region", sheet.crop !== null, toggleCrop),
    );
    if (sheet.crop) {
      const updateCrop: Update<Rect> = (change) => update((target) => { if (target.crop) change(target.crop); });
      grid.append(
        numberField("Crop X (px)", sheet.crop.x, 0, 65536, setting(updateCrop, "x"), true),
        numberField("Crop Y (px)", sheet.crop.y, 0, 65536, setting(updateCrop, "y"), true),
        numberField("Crop width (px)", sheet.crop.width, 1, 65536, setting(updateCrop, "width"), true),
        numberField("Crop height (px)", sheet.crop.height, 1, 65536, setting(updateCrop, "height"), true),
      );
    }

    const lastCell = sheet.columns * sheet.rows;
    const playback = section("Flipbook playback",
      numberField("First frame", sheet.first + 1, 1, sheet.last + 1, (value) => this.updateLayer(layer.id, ({ sheet }) => { sheet.first = value - 1; }, true), true),
      numberField("Last frame", sheet.last + 1, sheet.first + 1, lastCell, (value) => this.updateLayer(layer.id, ({ sheet }) => { sheet.last = value - 1; }, true), true),
      numberField("Frames per second", sheet.fps, 0.1, 240, setting(update, "fps")),
      selectField("Playback", sheet.mode, [["loop", "Loop"], ["once", "Once"], ["pingpong", "Ping-pong"], ["fixed", "Fixed"]], setting(update, "mode")),
      booleanField("Reverse", sheet.reverse, setting(update, "reverse")),
      booleanField("Normalize frames", sheet.normalize, setting(update, "normalize")),
    );
    this.body.replaceChildren(heading(layer.name, layer.kind), source, preview, grid, playback);
  }

  private showScene(project: Project): void {
    const { scene } = project;
    const update: Update<Project> = (change) => this.actions.edit(change);
    const editScene: Update<Project["scene"]> = (change) => update((draft) => change(draft.scene));
    const editCamera: Update<Project["scene"]["camera"]> = (change) => editScene((draft) => change(draft.camera));
    this.body.replaceChildren(heading("Scene"),
      section("Project",
        textField("Project name", project.name, setting(update, "name")),
        numberField("Duration (s)", project.duration, 0.1, 600, setting(update, "duration")),
        booleanField("Loop", project.loop, setting(update, "loop")),
      ),
      section("Viewport",
        colorField("Background", scene.background, setting(editScene, "background")),
        colorField("Glow", scene.glow, setting(editScene, "glow")),
        booleanField("Grid", scene.grid, setting(editScene, "grid")),
        booleanField("Mannequin", scene.mannequin, setting(editScene, "mannequin")),
      ),
      section("Camera",
        numberField("Yaw (rad)", scene.camera.yaw, -100000, 100000, setting(editCamera, "yaw")),
        numberField("Pitch (rad)", scene.camera.pitch, 0.03, 1.45, setting(editCamera, "pitch")),
        numberField("Zoom", scene.camera.zoom, 0.2, 8, setting(editCamera, "zoom")),
      ),
    );
  }

  private showAsset(asset: Asset, hasLayer: boolean): void {
    const image = element("img");
    image.alt = `Texture ${asset.name}`;
    const sample = element("div", "asset-preview checker");
    sample.append(image);
    const info = element("p", "asset-info", "Loading PNG");
    image.addEventListener("load", () => { info.textContent = `${image.naturalWidth} × ${image.naturalHeight} px`; });
    image.addEventListener("error", () => { info.textContent = "Could not load this PNG. Check its file path."; image.hidden = true; });
    image.src = this.actions.texture(asset);

    const update: Update<Asset> = (change) => this.actions.edit((draft) => {
      const target = draft.assets.find((item) => item.id === asset.id);
      if (target) change(target);
    });
    const controls = section("Texture",
      sample,
      info,
      element("p", "asset-info", asset.path),
      selectField("Matte", asset.matte, [["luma", "Luma from black"], ["rgba", "PNG alpha"]], setting(update, "matte")),
    );
    if (hasLayer) controls.append(button("Use on selected layer", () => this.actions.useAsset(asset.id)));
    controls.append(button("Add sprite from texture", () => this.actions.spriteFromAsset(asset.id)));
    this.body.replaceChildren(heading(asset.name), controls);
  }
}
