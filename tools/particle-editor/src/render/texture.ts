import type { Asset, Rect, Sheet } from '../model.js';
import { frameRect } from './atlas.js';

type Matte = Asset['matte'];
type FrameBounds = { boxes: Map<number, Rect>; height: number };
type Frame = { rect: Rect; bounds: Rect; scale: number };

const luminance = (red: number, green: number, blue: number) => (.2126 * red + .7152 * green + .0722 * blue) / 255;

export class PreviewTexture {
  readonly width: number;
  readonly height: number;
  private pixels?: Uint8ClampedArray;
  private variants = new Map<string, HTMLCanvasElement>();
  private boundsCache = new Map<string, FrameBounds>();

  constructor(private image: HTMLImageElement) {
    this.width = image.naturalWidth;
    this.height = image.naturalHeight;
  }

  private canvas(): HTMLCanvasElement {
    const canvas = this.image.ownerDocument.createElement('canvas');
    canvas.width = this.width;
    canvas.height = this.height;
    return canvas;
  }

  private sourcePixels(): Uint8ClampedArray {
    if (this.pixels) return this.pixels;
    const context = this.canvas().getContext('2d', { willReadFrequently: true });
    if (!context) throw new Error('Could not read texture pixels.');
    context.drawImage(this.image, 0, 0);
    this.pixels = context.getImageData(0, 0, this.width, this.height).data;
    return this.pixels;
  }

  paint(matte: Matte, color: string): CanvasImageSource {
    const hex = /^#[\da-f]{6}$/i.test(color) ? color.toLowerCase() : '#ffffff';
    if (matte === 'rgba' && hex === '#ffffff') return this.image;
    const key = `${matte}:${hex}`;
    const cached = this.variants.get(key);
    if (cached) return cached;

    const rgb = Number.parseInt(hex.slice(1), 16);
    const red = rgb >> 16;
    const green = (rgb >> 8) & 255;
    const blue = rgb & 255;
    const canvas = this.canvas();
    const context = canvas.getContext('2d');
    if (!context) throw new Error('Could not tint texture.');
    const image = context.createImageData(this.width, this.height);
    const pixels = image.data;
    pixels.set(this.sourcePixels());
    for (let offset = 0; offset < pixels.length; offset += 4) {
      if (matte === 'luma') {
        pixels[offset + 3] *= luminance(pixels[offset], pixels[offset + 1], pixels[offset + 2]);
        pixels[offset] = red;
        pixels[offset + 1] = green;
        pixels[offset + 2] = blue;
      } else {
        pixels[offset] *= red / 255;
        pixels[offset + 1] *= green / 255;
        pixels[offset + 2] *= blue / 255;
      }
    }
    context.putImageData(image, 0, 0);
    this.variants.set(key, canvas);
    if (this.variants.size > 6) this.variants.delete(this.variants.keys().next().value!);
    return canvas;
  }

  frame(sheet: Sheet, index: number, matte: Matte): Frame | null {
    const rect = frameRect(sheet, this.width, this.height, index);
    if (!rect) return null;
    if (!sheet.normalize) return { rect, bounds: rect, scale: 1 };

    const key = JSON.stringify([matte, sheet.columns, sheet.rows, sheet.margin, sheet.gap, sheet.crop, sheet.first, sheet.last]);
    let measured = this.boundsCache.get(key);
    if (!measured) {
      measured = { boxes: new Map(), height: 0 };
      for (let frame = sheet.first; frame <= sheet.last; frame++) {
        const cell = frameRect(sheet, this.width, this.height, frame);
        if (!cell) continue;
        const box = this.visibleBounds(cell, matte);
        if (!box) continue;
        measured.boxes.set(frame, box);
        measured.height = Math.max(measured.height, box.height);
      }
      this.boundsCache.set(key, measured);
      if (this.boundsCache.size > 8) this.boundsCache.delete(this.boundsCache.keys().next().value!);
    }

    const bounds = measured.boxes.get(index) ?? rect;
    // Cap enlargement so the small, dim frames in the plume sheets can still fall away.
    return { rect, bounds, scale: Math.max(1, Math.min(1.65, measured.height / bounds.height)) };
  }

  private visibleBounds(rect: Rect, matte: Matte): Rect | null {
    const pixels = this.sourcePixels();
    let left = rect.x + rect.width;
    let top = rect.y + rect.height;
    let right = rect.x - 1;
    let bottom = rect.y - 1;
    for (let y = rect.y; y < rect.y + rect.height; y++) {
      for (let x = rect.x; x < rect.x + rect.width; x++) {
        const offset = (y * this.width + x) * 4;
        const alpha = matte === 'luma' ? pixels[offset + 3] * luminance(pixels[offset], pixels[offset + 1], pixels[offset + 2]) : pixels[offset + 3];
        if (alpha < 14) continue;
        left = Math.min(left, x);
        right = Math.max(right, x);
        top = Math.min(top, y);
        bottom = Math.max(bottom, y);
      }
    }
    if (right < left) return null;
    return { x: left, y: top, width: right - left + 1, height: bottom - top + 1 };
  }
}
