import type { Asset, Camera, Layer, Project, Rect, Vec3 } from '../model.js';
import { frameIndex } from './atlas.js';
import { addMannequin, createProjection, drawGrid } from './scene.js';
import type { DrawItem, Projection } from './scene.js';
import { PreviewTexture } from './texture.js';

type View = { context: CanvasRenderingContext2D; project: Projection; queue: DrawItem[] };
type Material = { texture: PreviewTexture; matte: Asset['matte']; color: string; image: CanvasImageSource };
type TextureEntry = { pending: Promise<PreviewTexture>; texture?: PreviewTexture };
type AssetBinding = { asset: Asset; entry: TextureEntry };

const DEGREES = Math.PI / 180;
const TURN = 2 * Math.PI;
const PARTICLE_LIMIT = 1024;
const composites: Record<Layer['blend'], GlobalCompositeOperation> = {
  screen: 'screen', add: 'lighter', normal: 'source-over',
};

const mix = (first: number, last: number, progress: number) => first + (last - first) * progress;
const repeat = (value: number, period: number) => ((value % period) + period) % period;

function sample(seed: number, index: number, channel: number): number {
  const value = Math.sin(seed * 11.033 + index * 12.9898 + channel * 78.233) * 43758.5453;
  return value - Math.floor(value);
}

function addSprite(view: View, layer: Layer, material: Material, index: number, position: Vec3,
  scale: number, opacity: number, rotation: number, ground = false, depthBias = 0): void {
  if (opacity <= 0 || scale <= 0) return;
  const center = view.project(...position);
  if (center.depth >= 10.5) return;
  const frame = material.texture.frame(layer.sheet, index, material.matte);
  if (!frame) return;
  const { rect, bounds } = frame;
  const anchorX = (bounds.x - rect.x + bounds.width * layer.anchor[0]) / rect.width;
  const anchorY = (bounds.y - rect.y + bounds.height * layer.anchor[1]) / rect.height;
  const width = layer.size[0] * scale * frame.scale;
  const height = layer.size[1] * scale * frame.scale;
  const { context, project } = view;
  const axisX = ground ? project(position[0] + .1, position[1], position[2]) : null;
  const axisZ = ground ? project(position[0], position[1], position[2] + .1) : null;
  view.queue.push({ depth: center.depth + depthBias, draw() {
    context.save();
    if (axisX && axisZ) {
      context.transform((axisX.x - center.x) * 10, (axisX.y - center.y) * 10,
        (axisZ.x - center.x) * 10, (axisZ.y - center.y) * 10, center.x, center.y);
    } else {
      context.translate(center.x, center.y);
      context.scale(center.scale, center.scale);
    }
    context.rotate(rotation * DEGREES);
    context.globalAlpha = opacity;
    context.globalCompositeOperation = composites[layer.blend];
    context.drawImage(material.image, rect.x, rect.y, rect.width, rect.height,
      -anchorX * width, -anchorY * height, width, height);
    context.restore();
  } });
}

function scaleProgress(layer: Layer, clock: number, elapsed: number): number {
  const { sheet, timing } = layer;
  const length = sheet.last - sheet.first + 1;
  if (length > 1 && sheet.mode === 'loop') return repeat(clock * sheet.fps, length) / length;
  if (length > 1 && sheet.mode === 'pingpong') {
    const period = 2 * (length - 1);
    const phase = repeat(clock * sheet.fps, period);
    return Math.min(phase, period - phase) / (length - 1);
  }
  return elapsed / timing.duration;
}

function coneDirection(direction: Vec3, spread: number): (distance: number, angle: number) => Vec3 {
  const magnitude = Math.hypot(...direction);
  const [x, y, z] = magnitude > 0 ? direction.map(value => value / magnitude) : [0, 1, 0];
  const horizontal = Math.hypot(x, z);
  const rightX = horizontal > .0001 ? z / horizontal : 1;
  const rightZ = horizontal > .0001 ? -x / horizontal : 0;
  const cosSpread = Math.cos(spread * DEGREES / 2);
  return (distance, angle) => {
    const forward = mix(1, cosSpread, distance);
    const sideways = Math.sqrt(Math.max(0, 1 - forward * forward));
    const across = Math.cos(angle) * sideways;
    const vertical = Math.sin(angle) * sideways;
    return [
      x * forward + rightX * across + y * rightZ * vertical,
      y * forward + (z * rightX - x * rightZ) * vertical,
      z * forward + rightZ * across - y * rightX * vertical,
    ];
  };
}

function addEmitter(view: View, layer: Extract<Layer, {kind: 'emitter'}>, material: Material,
  clock: number, opacity: number): void {
  if (clock < 0) return;
  const e = layer.emitter;
  const direction = coneDirection(e.direction, e.spread);
  const [originX, originY, originZ] = layer.position;
  const burst = clock < e.lifetime ? Math.min(e.burst, PARTICLE_LIMIT) : 0;
  const last = Math.floor(clock * e.rate);
  const first = Math.max(1, Math.floor((clock - e.lifetime) * e.rate) + 1, last - PARTICLE_LIMIT + burst + 1);

  // Spawn times come from the playhead, so a backwards scrub reproduces the same particles.
  function particle(index: number, age: number): void {
    const progress = age / e.lifetime;
    const angle = sample(e.seed, index, 0) * TURN;
    const cos = Math.cos(angle);
    const sin = Math.sin(angle);
    const radius = e.radius * (e.radial ? 1 : Math.sqrt(sample(e.seed, index, 1)));
    const [x, y, z] = direction(sample(e.seed, index, 2), sample(e.seed, index, 3) * TURN);
    const vx = e.radial ? x * cos - z * sin : x;
    const vz = e.radial ? x * sin + z * cos : z;
    const travel = e.drag > .0001 ? -Math.expm1(-age * e.drag) / e.drag : age;
    const fall = e.drag > .0001 ? (age - travel) / e.drag : age * age / 2;
    const position: Vec3 = [originX + cos * radius + vx * e.speed * travel,
      originY + y * e.speed * travel + e.gravity * fall, originZ + sin * radius + vz * e.speed * travel];
    const frame = e.randomFrame
      ? layer.sheet.first + Math.floor(sample(e.seed, index, 4) * (layer.sheet.last - layer.sheet.first + 1))
      : frameIndex(layer.sheet, age);
    addSprite(view, layer, material, frame, position, mix(1, e.sizeEnd, progress),
      opacity * Math.sin(Math.PI * progress), layer.rotation + e.spin * age);
  }

  for (let index = 0; index < burst; index++) particle(-1 - index, clock);
  for (let index = first; index <= last; index++) particle(index, Math.max(0, clock - index / e.rate));
}

function drawRibbonSlice(context: CanvasRenderingContext2D, image: CanvasImageSource, rect: Rect,
  start: number, span: number): void {
  const first = Math.min(span, 1 - start);
  const fraction = first / span;
  context.drawImage(image, rect.x + rect.width * start, rect.y, rect.width * first, rect.height, 0, 0, fraction, 1);
  if (span - first > 1e-7) {
    context.drawImage(image, rect.x, rect.y, rect.width * (span - first), rect.height, fraction, 0, 1 - fraction, 1);
  }
}

function addRibbon(view: View, layer: Extract<Layer, {kind: 'ribbon'}>, material: Material,
  clock: number, opacity: number): void {
  const r = layer.ribbon;
  const frame = material.texture.frame(layer.sheet, frameIndex(layer.sheet, clock), material.matte);
  if (!frame) return;
  const [originX, originY, originZ] = layer.position;
  const tilt = r.tilt * DEGREES;
  const sweep = r.arc * DEGREES;
  const start = (r.phase + layer.rotation + r.speed * clock) * DEGREES + (.5 - layer.anchor[0]) * sweep;
  const width = r.radius * layer.size[0];
  const slices = Math.max(4, Math.ceil(r.arc / 7.5));
  const { context, project, queue } = view;
  const point = (angle: number, height = 0) => {
    const across = r.radius * Math.sin(angle);
    return project(originX + width * Math.cos(angle), originY + across * Math.sin(tilt) + height,
      originZ + across * Math.cos(tilt));
  };
  const step = sweep / slices;
  const scroll = repeat(r.scroll * clock, 1);
  for (let i = 0; i < slices; i++) {
    const angle = start + i * step;
    const middle = angle + step / 2;
    const left = point(angle);
    const right = point(angle + step);
    const center = point(middle);
    if (center.depth >= 10.5) continue;
    const taper = r.taper ? Math.sin((i + .5) / slices * Math.PI) ** 1.15 : 1;
    const height = layer.size[1] * mix(.45, 1, taper);
    const top = point(middle, height * layer.anchor[1]);
    const bottom = point(middle, height * (layer.anchor[1] - 1));
    const length = Math.hypot(width * Math.sin(middle), r.radius * Math.cos(middle)) * step;
    const facing = Math.min(1, Math.abs(right.x - left.x) * 1.45 / (center.scale * length));
    const alpha = opacity * taper * mix(.22, 1, facing);
    const u = repeat(i / slices + scroll, 1);
    queue.push({ depth: center.depth, draw() {
      context.save();
      context.globalAlpha = alpha;
      context.globalCompositeOperation = composites[layer.blend];
      context.transform(right.x - left.x, right.y - left.y, bottom.x - top.x, bottom.y - top.y,
        left.x + top.x - center.x, left.y + top.y - center.y);
      drawRibbonSlice(context, material.image, frame.bounds, u, 1 / slices);
      context.restore();
    } });
  }
}

export class PreviewRenderer {
  private context: CanvasRenderingContext2D;
  private project?: Project;
  private revision = 0;
  private assets = new Map<string, AssetBinding>();
  private textureCache = new Map<string, TextureEntry>();
  private materials = new Map<string, Material>();
  private failedLayers = new Set<string>();

  constructor(private canvas: HTMLCanvasElement, private onAssetError?: (message: string) => void) {
    const context = canvas.getContext('2d', { alpha: false });
    if (!context) throw new Error('Canvas 2D is unavailable.');
    this.context = context;
  }

  private async loadTexture(path: string): Promise<PreviewTexture> {
    const image = this.canvas.ownerDocument.createElement('img');
    image.src = path;
    await image.decode();
    if (!image.naturalWidth || !image.naturalHeight) throw new Error('The image is empty.');
    return new PreviewTexture(image);
  }

  async setProject(project: Project, url: (asset: Asset) => string): Promise<void> {
    const revision = ++this.revision;
    this.project = project;
    this.assets.clear();
    this.failedLayers.clear();
    const currentLayers = new Set(project.layers.map(layer => layer.id));
    for (const id of this.materials.keys()) {
      if (!currentLayers.has(id)) this.materials.delete(id);
    }

    const currentPaths = new Set<string>();
    const loading = project.assets.map(async (asset) => {
      try {
        const path = url(asset);
        currentPaths.add(path);
        let entry = this.textureCache.get(path);
        if (!entry) {
          const created: TextureEntry = { pending: this.loadTexture(path) };
          this.textureCache.set(path, created);
          created.pending = created.pending.then(texture => {
            created.texture = texture;
            return texture;
          }, (error: unknown) => {
            if (this.textureCache.get(path) === created) this.textureCache.delete(path);
            throw error;
          });
          entry = created;
        }
        this.assets.set(asset.id, { asset, entry });
        await entry.pending;
      } catch (error) {
        if (revision === this.revision) this.reportAssetError(asset, error);
      }
    });
    for (const path of this.textureCache.keys()) {
      if (this.textureCache.size <= currentPaths.size + 12) break;
      if (!currentPaths.has(path)) this.textureCache.delete(path);
    }
    await Promise.all(loading);
  }

  private reportAssetError(asset: Asset, error: unknown): void {
    const detail = error instanceof Error ? error.message : String(error);
    this.onAssetError?.(`${asset.name}: ${detail}`);
  }

  render(time: number, tier = 3, camera?: Camera): void {
    const { project, canvas, context } = this;
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    if (!project || !width || !height) return;
    const density = Math.min(canvas.ownerDocument.defaultView?.devicePixelRatio ?? 1, 1.75);
    const pixelWidth = Math.round(width * density);
    const pixelHeight = Math.round(height * density);
    if (canvas.width !== pixelWidth || canvas.height !== pixelHeight) {
      canvas.width = pixelWidth;
      canvas.height = pixelHeight;
    }

    context.setTransform(density, 0, 0, density, 0, 0);
    context.globalAlpha = 1;
    context.globalCompositeOperation = 'source-over';
    const { scene } = project;
    const background = context.createRadialGradient(width / 2, height * .58, 0,
      width / 2, height * .58, Math.max(width * .55, height * .76));
    background.addColorStop(0, scene.glow);
    background.addColorStop(1, scene.background);
    context.fillStyle = background;
    context.fillRect(0, 0, width, height);

    const view: View = { context, project: createProjection(width, height, camera ?? scene.camera), queue: [] };
    if (scene.grid) drawGrid(context, view.project);
    if (scene.mannequin) addMannequin(context, view.project, view.queue);
    const playhead = Number.isFinite(time) ? Math.max(0, Math.min(project.duration, time)) : 0;
    for (const layer of project.layers) {
      if (!layer.visible || layer.tier > tier || !layer.assetId || this.failedLayers.has(layer.id)) continue;
      const binding = this.assets.get(layer.assetId);
      const texture = binding?.entry.texture;
      if (!binding || !texture) continue;
      const { timing } = layer;
      const elapsed = playhead - timing.start;
      if (elapsed < 0 || elapsed > timing.duration) continue;
      const fadeIn = timing.fadeIn ? elapsed / timing.fadeIn : 1;
      const fadeOut = timing.fadeOut ? (timing.duration - elapsed) / timing.fadeOut : 1;
      const opacity = layer.opacity * Math.min(1, fadeIn, fadeOut);
      if (opacity <= 0) continue;
      const clock = elapsed * timing.speed + timing.offset;
      const { matte } = binding.asset;
      try {
        let material = this.materials.get(layer.id);
        if (!material || material.texture !== texture || material.matte !== matte || material.color !== layer.color) {
          material = { texture, matte, color: layer.color, image: texture.paint(matte, layer.color) };
          this.materials.set(layer.id, material);
        }
        if (layer.kind === 'sprite') {
          const scale = mix(layer.sprite.scaleStart, layer.sprite.scaleEnd, scaleProgress(layer, clock, elapsed));
          addSprite(view, layer, material, frameIndex(layer.sheet, clock), layer.position, scale,
            opacity, layer.rotation, layer.sprite.plane === 'ground', layer.sprite.depthBias);
        } else if (layer.kind === 'emitter') {
          addEmitter(view, layer, material, clock, opacity);
        } else {
          addRibbon(view, layer, material, clock, opacity);
        }
      } catch (error) {
        this.failedLayers.add(layer.id);
        this.reportAssetError(binding.asset, error);
      }
    }
    view.queue.sort((a, b) => a.depth - b.depth);
    for (const item of view.queue) item.draw();
  }
}
