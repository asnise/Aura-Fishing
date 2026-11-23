import { existsSync, readFileSync, renameSync, unlinkSync, writeFileSync } from 'node:fs';
import { basename, dirname, relative, resolve } from 'node:path';
import { parseArgs } from 'node:util';

const modelUrl = new URL('../../../build/aura-particle-editor/app/model.js', import.meta.url);
const layerKinds = ['sprite', 'emitter', 'ribbon'];
const { positionals, values } = parseArgs({
  allowPositionals: true,
  options: {
    name: { type: 'string' }, texture: { type: 'string' }, matte: { type: 'string' },
    columns: { type: 'string' }, rows: { type: 'string' }, fps: { type: 'string' },
  },
});
const [command, inputFile, argument] = positionals;

function printUsage() {
  console.log([
    'project new <project.json> [--name "Effect name"]',
    'project validate <project.json>',
    'project add <project.json> <sprite|emitter|ribbon> [--name Name] [--texture local.png]',
    '    [--columns 4 --rows 4 --fps 14 --matte luma]',
    'project duplicate <project.json> <layer-id> [--name Name]',
  ].join('\n'));
}

function serialize(project) {
  return JSON.stringify(project, null, 2) + '\n';
}

function replaceFile(path, before, text) {
  const scratch = path + '.' + crypto.randomUUID() + '.tmp';
  try {
    writeFileSync(scratch, text, { flag: 'wx' });
    if (readFileSync(path, 'utf8') !== before) throw new Error('Project was edited during the command. Retry against the latest file.');
    renameSync(scratch, path);
  } finally {
    if (existsSync(scratch)) unlinkSync(scratch);
  }
}

if (!inputFile || !['new', 'validate', 'add', 'duplicate'].includes(command)) {
  printUsage();
  process.exitCode = command ? 1 : 0;
} else {
  try {
    if (!existsSync(modelUrl)) throw new Error('Build Aura Particle Editor first.');
    const { createProject, createLayer, parseProject } = await import(modelUrl.href);
    const file = resolve(inputFile);
    if (command === 'new') {
      const project = createProject(values.name);
      writeFileSync(file, serialize(project), { flag: 'wx' });
      console.log(JSON.stringify({ file, name: project.name }));
    } else {
      const before = readFileSync(file, 'utf8');
      const project = parseProject(JSON.parse(before.replace(/^\uFEFF/, '')));
      if (command === 'validate') {
        const missing = project.assets.filter(asset => !existsSync(resolve(dirname(file), asset.path))).map(asset => asset.path);
        console.log(JSON.stringify({ file, layers: project.layers.length, assets: project.assets.length, missing }));
        if (missing.length > 0) process.exitCode = 1;
      } else {
        let layer;
        if (command === 'duplicate') {
          const index = project.layers.findIndex(item => item.id === argument);
          if (index < 0) throw new Error('No layer has ID ' + argument);
          layer = structuredClone(project.layers[index]);
          layer.id = crypto.randomUUID();
          layer.name = values.name ?? layer.name + ' copy';
          project.layers.splice(index + 1, 0, layer);
        } else {
          if (!layerKinds.includes(argument)) throw new Error('Choose sprite, emitter or ribbon.');
          let texture = null;
          if (values.texture) {
            const absolute = resolve(values.texture);
            if (!existsSync(absolute)) throw new Error('Image file does not exist: ' + absolute);
            const path = relative(dirname(file), absolute).replaceAll('\\', '/');
            texture = project.assets.find(asset => asset.path === path && asset.matte === (values.matte ?? 'luma'));
            if (!texture) {
              texture = { id: crypto.randomUUID(), name: basename(absolute), path, matte: values.matte ?? 'luma' };
              project.assets.push(texture);
            }
          }
          layer = createLayer(argument, texture?.id ?? null);
          layer.name = values.name ?? layer.name;
          if (values.columns !== undefined) layer.sheet.columns = Number(values.columns);
          if (values.rows !== undefined) layer.sheet.rows = Number(values.rows);
          if (values.fps !== undefined) layer.sheet.fps = Number(values.fps);
          layer.sheet.last = layer.sheet.columns * layer.sheet.rows - 1;
          project.layers.push(layer);
        }
        replaceFile(file, before, serialize(parseProject(project)));
        console.log(JSON.stringify({ file, layerId: layer.id, name: layer.name }));
      }
    }
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
