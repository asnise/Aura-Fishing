import assert from 'node:assert/strict';
import { mkdtemp, rm, rmdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { createProject } from '../../../build/aura-particle-editor/app/model.js';
import { ProjectFiles } from '../../../build/aura-particle-editor/app/server/files.js';

test('external JSON edits preserve the last valid preview and guard a stale save', async t => {
  const folder = await mkdtemp(join(tmpdir(), 'aura-project-'));
  const path = join(folder, 'project.json');
  t.after(async () => {
    await rm(path, { force: true });
    await rmdir(folder);
  });
  await writeFile(path, JSON.stringify(createProject('Original')));
  const files = new ProjectFiles(folder);
  const initial = await files.open(path);
  assert.equal(initial.project.name, 'Original');

  await writeFile(path, '{');
  assert.equal(await files.poll(), true);
  assert.equal(files.state.project.name, 'Original');
  assert.ok(files.state.error);

  await writeFile(path, JSON.stringify(createProject('External edit landed')));
  assert.equal(await files.poll(), true);
  assert.equal(files.state.project.name, 'External edit landed');
  assert.equal(files.state.error, undefined);
  await assert.rejects(
    files.save(createProject('Unsaved local edit'), initial.revision, false),
    /changed on disk/i,
  );
  const saved = await files.save(createProject('Fresh local edit'), files.state.revision, false);
  assert.equal(saved.project.name, 'Fresh local edit');
});
