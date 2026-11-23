import assert from 'node:assert/strict';
import test from 'node:test';
import { createLayer, createProject, parseProject } from '../../../build/aura-particle-editor/app/model.js';

test('an AI-authored project can omit default inspector values', () => {
  const project = parseProject({
    version: 1,
    name: 'River Mist',
    assets: [{ id: 'mist', name: 'Mist sheet', path: 'textures/mist.png' }],
    layers: [{ id: 'column', name: 'Column', kind: 'sprite', assetId: 'mist', sheet: { columns: 4, rows: 4 } }],
  });
  assert.equal(project.assets[0].matte, 'luma');
  assert.equal(project.layers[0].sheet.last, 15);
  assert.equal(project.layers[0].timing.speed, 1);
  assert.deepEqual(project.layers[0].position, [0, .15, 0]);
});

test('invalid sheet ranges and references identify the owning field', () => {
  const project = createProject('Validation');
  const layer = createLayer('sprite');
  project.layers.push(layer);
  layer.sheet.last = 4;
  assert.throws(() => parseProject(project), /layers\[0\]\.sheet\.last/);
  layer.sheet.last = 0;
  layer.assetId = 'missing';
  assert.throws(() => parseProject(project), /layers\[0\]\.assetId/);
});

test('layer defaults round-trip across all supported layer kinds', () => {
  const project = createProject('Layer defaults');
  project.layers = [createLayer('sprite'), createLayer('emitter'), createLayer('ribbon')];
  assert.equal(new Set(project.layers.map(layer => layer.id)).size, 3);
  assert.deepEqual(parseProject(JSON.parse(JSON.stringify(project))), project);
});
