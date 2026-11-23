import type { Rect, Sheet } from '../model.js';

export function frameRect(sheet: Sheet, width: number, height: number, index: number): Rect | null {
  const { columns, rows, margin, gap, crop } = sheet;
  if (!Number.isInteger(index) || index < 0 || index >= columns * rows) return null;

  const left = Math.max(0, crop?.x ?? 0) + margin;
  const top = Math.max(0, crop?.y ?? 0) + margin;
  const right = Math.min(width, crop ? crop.x + crop.width : width) - margin;
  const bottom = Math.min(height, crop ? crop.y + crop.height : height) - margin;
  const cellWidth = (right - left - (columns - 1) * gap) / columns;
  const cellHeight = (bottom - top - (rows - 1) * gap) / rows;
  if (!(cellWidth >= 1 && cellHeight >= 1)) return null;

  const column = index % columns;
  const row = Math.floor(index / columns);
  const startX = left + column * (cellWidth + gap);
  const startY = top + row * (cellHeight + gap);
  const x = Math.round(startX);
  const y = Math.round(startY);
  return { x, y, width: Math.round(startX + cellWidth) - x, height: Math.round(startY + cellHeight) - y };
}

export function frameIndex(sheet: Sheet, time: number): number {
  const { first, last, fps, mode, reverse } = sheet;
  const length = Math.max(1, last - first + 1);
  const step = Number.isFinite(time) ? Math.floor(time * fps) : 0;
  let offset = 0;
  if (mode === 'once') {
    offset = Math.max(0, Math.min(length - 1, step));
  } else if (mode === 'loop' || mode === 'pingpong') {
    const period = mode === 'loop' ? length : Math.max(1, 2 * (length - 1));
    const phase = ((step % period) + period) % period;
    offset = phase < length ? phase : period - phase;
  }
  return reverse ? last - offset : first + offset;
}
