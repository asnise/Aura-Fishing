import assert from 'node:assert/strict';
import test from 'node:test';
import { createLayer } from '../../../build/aura-particle-editor/app/model.js';
import { frameIndex, frameRect } from '../../../build/aura-particle-editor/app/render/atlas.js';

test('grid slicing uses crop, pixel margins, gaps, and row-major indices', () => {
  const { sheet } = createLayer('sprite');
  Object.assign(sheet, { columns: 2, rows: 2, margin: 2, gap: 4, crop: { x: 10, y: 6, width: 80, height: 60 } });
  assert.deepEqual(frameRect(sheet, 100, 80, 3), { x: 52, y: 38, width: 36, height: 26 });
  assert.equal(frameRect(sheet, 100, 80, 4), null);
  assert.equal(frameRect({ ...sheet, margin: 60 }, 100, 80, 0), null);
});

test('range, reverse, ping-pong and one-shot map time to the intended cells', () => {
  const sheet = { ...createLayer('sprite').sheet, first: 4, last: 7, fps: 1, mode: 'pingpong', reverse: true };
  assert.deepEqual([0, 1, 2, 3, 4, 5, 6].map(time => frameIndex(sheet, time)), [7, 6, 5, 4, 5, 6, 7]);
  assert.equal(frameIndex({ ...sheet, mode: 'once', reverse: false }, 12), 7);
  assert.equal(frameIndex({ ...sheet, mode: 'fixed', reverse: false }, 12), 4);
});
