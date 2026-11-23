export type Vec2 = [number, number];
export type Vec3 = [number, number, number];
export type Tier = 1 | 2 | 3;
export type Rect = { x: number; y: number; width: number; height: number };
export type Camera = { yaw: number; pitch: number; zoom: number };

export interface Asset {
  id: string;
  name: string;
  path: string;
  matte: 'luma' | 'rgba';
}

export interface Sheet {
  columns: number;
  rows: number;
  margin: number;
  gap: number;
  crop: Rect | null;
  first: number;
  last: number;
  fps: number;
  mode: 'loop' | 'once' | 'pingpong' | 'fixed';
  reverse: boolean;
  normalize: boolean;
}

export interface Timing {
  start: number;
  duration: number;
  speed: number;
  offset: number;
  fadeIn: number;
  fadeOut: number;
}

export interface SpriteSettings {
  plane: 'billboard' | 'ground';
  scaleStart: number;
  scaleEnd: number;
  depthBias: number;
}

export interface EmitterSettings {
  rate: number;
  lifetime: number;
  speed: number;
  spread: number;
  radius: number;
  direction: Vec3;
  gravity: number;
  drag: number;
  spin: number;
  sizeEnd: number;
  seed: number;
  randomFrame: boolean;
  radial: boolean;
  burst: number;
}

export interface RibbonSettings {
  radius: number;
  tilt: number;
  arc: number;
  speed: number;
  phase: number;
  scroll: number;
  taper: boolean;
}

interface LayerBase {
  id: string;
  name: string;
  assetId: string | null;
  visible: boolean;
  tier: Tier;
  position: Vec3;
  size: Vec2;
  anchor: Vec2;
  rotation: number;
  color: string;
  opacity: number;
  blend: 'screen' | 'add' | 'normal';
  sheet: Sheet;
  timing: Timing;
}

export type Layer = LayerBase & (
  | { kind: 'sprite'; sprite: SpriteSettings }
  | { kind: 'emitter'; emitter: EmitterSettings }
  | { kind: 'ribbon'; ribbon: RibbonSettings }
);

export interface Project {
  version: 1;
  name: string;
  duration: number;
  loop: boolean;
  scene: {
    background: string;
    glow: string;
    grid: boolean;
    mannequin: boolean;
    camera: Camera;
  };
  assets: Asset[];
  layers: Layer[];
}

export function createProject(name = 'Untitled effect'): Project {
  return {
    version: 1, name, duration: 6, loop: true,
    scene: {
      background: '#101820', glow: '#233d4e', grid: true, mannequin: true,
      camera: { yaw: .42, pitch: .41, zoom: 1 },
    },
    assets: [], layers: [],
  };
}

export function createLayer(kind: Layer['kind'], assetId: string | null = null): Layer {
  const common: LayerBase = {
    id: crypto.randomUUID(), name: { sprite: 'Sprite', emitter: 'Emitter', ribbon: 'Ribbon' }[kind],
    assetId, visible: true, tier: 1, position: [0, .15, 0], size: [2.8, 2.8], anchor: [.5, .5],
    rotation: 0, color: '#ffffff', opacity: .85, blend: 'screen',
    sheet: { columns: 1, rows: 1, crop: null, margin: 0, gap: 0, first: 0, last: 0, fps: 14, mode: 'loop', reverse: false, normalize: false },
    timing: { start: 0, duration: 6, speed: 1, offset: 0, fadeIn: .15, fadeOut: .2 },
  };
  if (kind === 'sprite') return { ...common, kind, sprite: { plane: 'billboard', scaleStart: 1, scaleEnd: 1, depthBias: 0 } };
  if (kind === 'emitter') return {
    ...common, kind, size: [.34, .34],
    emitter: {
      rate: 12, lifetime: 1.5, speed: 1.2, spread: 50, radius: .35, direction: [0, 1, 0],
      gravity: -.25, drag: .18, sizeEnd: .54, spin: 22, seed: 42, randomFrame: true, radial: false, burst: 0,
    },
  };
  return {
    ...common, kind, position: [0, 2.48, 0], size: [1, 1.7],
    ribbon: { radius: 1.65, tilt: 15, arc: 360, speed: 34, phase: 0, scroll: 0, taper: false },
  };
}

type Fields = Record<string, unknown>;

function invalid(path: string, description: string): never {
  throw new Error(path + ' ' + description);
}

function record(value: unknown, path: string): Fields {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) invalid(path, 'must be an object');
  return value as Fields;
}

function optionalRecord(value: unknown, path: string): Fields {
  return value === undefined ? {} : record(value, path);
}

function string(value: unknown, path: string, fallback?: string): string {
  const result = value === undefined ? fallback : value;
  if (typeof result !== 'string' || result.trim().length === 0) invalid(path, 'must be a non-empty string');
  return result;
}

function choice<T extends string>(value: unknown, path: string, values: readonly T[], fallback: T): T {
  const result = value === undefined ? fallback : value;
  if (typeof result !== 'string' || !values.includes(result as T)) invalid(path, 'must be one of ' + values.join(', '));
  return result as T;
}

function boolean(value: unknown, path: string, fallback: boolean): boolean {
  if (value === undefined) return fallback;
  if (typeof value !== 'boolean') invalid(path, 'must be a boolean');
  return value;
}

function number(value: unknown, path: string, fallback: number, min: number, max: number, integer = false): number {
  const result = value === undefined ? fallback : value;
  if (typeof result !== 'number' || !Number.isFinite(result) || result < min || result > max || (integer && !Number.isInteger(result))) {
    invalid(path, 'must be ' + (integer ? 'an integer' : 'a number') + ' from ' + min + ' to ' + max);
  }
  return result;
}

function tuple<T extends Vec2 | Vec3>(value: unknown, path: string, fallback: T, min: number, max: number): T {
  if (value === undefined) return fallback;
  if (!Array.isArray(value) || value.length !== fallback.length) invalid(path, 'must contain ' + fallback.length + ' numbers');
  return value.map((component, i) => number(component, path + '[' + i + ']', fallback[i], min, max)) as T;
}

function color(value: unknown, path: string, fallback: string): string {
  const result = string(value, path, fallback);
  if (!/^#[\da-f]{6}$/i.test(result)) invalid(path, 'must be a six-digit hex color');
  return result.toLowerCase();
}

function list(value: unknown, path: string): unknown[] {
  if (value === undefined) return [];
  if (!Array.isArray(value)) invalid(path, 'must be an array');
  return value;
}

function readAsset(value: unknown, index: number): Asset {
  const root = 'assets[' + index + ']';
  const data = record(value, root);
  const id = string(data.id, root + '.id');
  const path = string(data.path, root + '.path');
  if (/[\u0000-\u001f]/.test(path) || /^\w+:\/\//.test(path)) invalid(root + '.path', 'must name a local image file');
  return { id, name: string(data.name, root + '.name', id), path, matte: choice(data.matte, root + '.matte', ['luma', 'rgba'], 'luma') };
}

function readSheet(value: unknown, root: string): Sheet {
  const data = optionalRecord(value, root);
  const columns = number(data.columns, root + '.columns', 1, 1, 64, true);
  const rows = number(data.rows, root + '.rows', 1, 1, 64, true);
  const lastCell = columns * rows - 1;
  const first = number(data.first, root + '.first', 0, 0, lastCell, true);
  let crop: Rect | null = null;
  if (data.crop !== undefined && data.crop !== null) {
    const rect = record(data.crop, root + '.crop');
    crop = {
      x: number(rect.x, root + '.crop.x', 0, 0, 65536, true),
      y: number(rect.y, root + '.crop.y', 0, 0, 65536, true),
      width: number(rect.width, root + '.crop.width', Number.NaN, 1, 65536, true),
      height: number(rect.height, root + '.crop.height', Number.NaN, 1, 65536, true),
    };
  }
  return {
    columns, rows, crop,
    margin: number(data.margin, root + '.margin', 0, 0, 4096, true),
    gap: number(data.gap, root + '.gap', 0, 0, 4096, true),
    first, last: number(data.last, root + '.last', lastCell, first, lastCell, true),
    fps: number(data.fps, root + '.fps', 14, .1, 240),
    mode: choice(data.mode, root + '.mode', ['loop', 'once', 'pingpong', 'fixed'], 'loop'),
    reverse: boolean(data.reverse, root + '.reverse', false),
    normalize: boolean(data.normalize, root + '.normalize', false),
  };
}

function readLayer(value: unknown, index: number, assets: Set<string>): Layer {
  const root = 'layers[' + index + ']';
  const data = record(value, root);
  const kind = choice(data.kind, root + '.kind', ['sprite', 'emitter', 'ribbon'], 'sprite');
  const defaults = createLayer(kind);
  const assetId = data.assetId === undefined || data.assetId === null ? null : string(data.assetId, root + '.assetId');
  if (assetId !== null && !assets.has(assetId)) invalid(root + '.assetId', 'does not match an asset ID');
  const timing = optionalRecord(data.timing, root + '.timing');
  const common: LayerBase = {
    id: string(data.id, root + '.id'),
    name: string(data.name, root + '.name', defaults.name),
    assetId,
    visible: boolean(data.visible, root + '.visible', true),
    tier: number(data.tier, root + '.tier', 1, 1, 3, true) as Tier,
    position: tuple(data.position, root + '.position', defaults.position, -1000, 1000),
    size: tuple(data.size, root + '.size', defaults.size, .001, 1000),
    anchor: tuple(data.anchor, root + '.anchor', defaults.anchor, -4, 4),
    rotation: number(data.rotation, root + '.rotation', 0, -36000, 36000),
    color: color(data.color, root + '.color', defaults.color),
    opacity: number(data.opacity, root + '.opacity', defaults.opacity, 0, 1),
    blend: choice(data.blend, root + '.blend', ['screen', 'add', 'normal'], 'screen'),
    sheet: readSheet(data.sheet, root + '.sheet'),
    timing: {
      start: number(timing.start, root + '.timing.start', 0, 0, 600),
      duration: number(timing.duration, root + '.timing.duration', 6, .01, 600),
      speed: number(timing.speed, root + '.timing.speed', 1, .01, 100),
      offset: number(timing.offset, root + '.timing.offset', 0, -600, 600),
      fadeIn: number(timing.fadeIn, root + '.timing.fadeIn', .15, 0, 600),
      fadeOut: number(timing.fadeOut, root + '.timing.fadeOut', .2, 0, 600),
    },
  };

  if (defaults.kind === 'sprite') {
    const at = root + '.sprite';
    const params = optionalRecord(data.sprite, at);
    return { ...common, kind: 'sprite', sprite: {
      plane: choice(params.plane, at + '.plane', ['billboard', 'ground'], 'billboard'),
      scaleStart: number(params.scaleStart, at + '.scaleStart', 1, 0, 30),
      scaleEnd: number(params.scaleEnd, at + '.scaleEnd', 1, 0, 30),
      depthBias: number(params.depthBias, at + '.depthBias', 0, -1000, 1000),
    } };
  }
  if (defaults.kind === 'emitter') {
    const at = root + '.emitter';
    const params = optionalRecord(data.emitter, at);
    const e = defaults.emitter;
    return { ...common, kind: 'emitter', emitter: {
      rate: number(params.rate, at + '.rate', e.rate, 0, 600),
      lifetime: number(params.lifetime, at + '.lifetime', e.lifetime, .01, 60),
      speed: number(params.speed, at + '.speed', e.speed, 0, 250),
      spread: number(params.spread, at + '.spread', e.spread, 0, 360),
      radius: number(params.radius, at + '.radius', e.radius, 0, 250),
      direction: tuple(params.direction, at + '.direction', e.direction, -250, 250),
      gravity: number(params.gravity, at + '.gravity', e.gravity, -250, 250),
      drag: number(params.drag, at + '.drag', e.drag, 0, 30),
      spin: number(params.spin, at + '.spin', e.spin, -3600, 3600),
      sizeEnd: number(params.sizeEnd, at + '.sizeEnd', e.sizeEnd, 0, 30),
      seed: number(params.seed, at + '.seed', e.seed, -2147483648, 2147483647, true),
      randomFrame: boolean(params.randomFrame, at + '.randomFrame', e.randomFrame),
      radial: boolean(params.radial, at + '.radial', e.radial),
      burst: number(params.burst, at + '.burst', e.burst, 0, 600, true),
    } };
  }
  const at = root + '.ribbon';
  const params = optionalRecord(data.ribbon, at);
  const r = defaults.ribbon;
  return { ...common, kind: 'ribbon', ribbon: {
    radius: number(params.radius, at + '.radius', r.radius, .001, 250),
    tilt: number(params.tilt, at + '.tilt', r.tilt, -360, 360),
    arc: number(params.arc, at + '.arc', r.arc, 1, 360),
    speed: number(params.speed, at + '.speed', r.speed, -3600, 3600),
    phase: number(params.phase, at + '.phase', r.phase, -36000, 36000),
    scroll: number(params.scroll, at + '.scroll', r.scroll, -100, 100),
    taper: boolean(params.taper, at + '.taper', r.taper),
  } };
}

function idSet<T extends { id: string }>(items: readonly T[], path: string): Set<string> {
  const ids = new Set<string>();
  for (const [index, item] of items.entries()) {
    if (ids.has(item.id)) invalid(path + '[' + index + '].id', 'is already used');
    ids.add(item.id);
  }
  return ids;
}

export function parseProject(value: unknown): Project {
  const data = record(value, 'Project');
  if (data.version !== 1) invalid('Project.version', 'must equal 1');
  const defaults = createProject();
  const scene = optionalRecord(data.scene, 'scene');
  const camera = optionalRecord(scene.camera, 'scene.camera');
  const assets = list(data.assets, 'assets').map(readAsset);
  const assetIds = idSet(assets, 'assets');
  const layers = list(data.layers, 'layers').map((item, index) => readLayer(item, index, assetIds));
  idSet(layers, 'layers');
  return {
    version: 1, name: string(data.name, 'Project.name', defaults.name),
    duration: number(data.duration, 'Project.duration', defaults.duration, .1, 600),
    loop: boolean(data.loop, 'Project.loop', defaults.loop),
    scene: {
      background: color(scene.background, 'scene.background', defaults.scene.background),
      glow: color(scene.glow, 'scene.glow', defaults.scene.glow),
      grid: boolean(scene.grid, 'scene.grid', true),
      mannequin: boolean(scene.mannequin, 'scene.mannequin', true),
      camera: {
        yaw: number(camera.yaw, 'scene.camera.yaw', .42, -100000, 100000),
        pitch: number(camera.pitch, 'scene.camera.pitch', .41, .03, 1.45),
        zoom: number(camera.zoom, 'scene.camera.zoom', 1, .2, 8),
      },
    },
    assets, layers,
  };
}
