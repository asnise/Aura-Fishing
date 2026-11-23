import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const tool = fileURLToPath(new URL('../', import.meta.url));
const workspace = fileURLToPath(new URL('../../../', import.meta.url));
const output = join(workspace, 'build', 'aura-particle-editor', 'app');
const dependencyDirs = [
  join(tool, 'node_modules'),
  join(workspace, 'node_modules'),
  join(workspace, 'Figma For Roblox', 'cursor-talk-to-figma-mcp', 'node_modules'),
];
const packages = dependencyDirs.find(directory => existsSync(join(directory, 'typescript', 'lib', 'tsc.js')) &&
  existsSync(join(directory, '@types', 'node', 'index.d.ts')));
if (!packages) {
  console.error('TypeScript and Node type definitions are missing. Install the dev dependencies in tools/particle-editor.');
  process.exit(1);
}

const compile = spawnSync(process.execPath, [
  join(packages, 'typescript', 'lib', 'tsc.js'),
  '--project', join(tool, 'tsconfig.json'), '--typeRoots', join(packages, '@types'),
], { stdio: 'inherit', windowsHide: true });
if (compile.error) throw compile.error;
if (compile.status !== 0) process.exit(compile.status ?? 1);

const staticExtensions = new Set(['.html', '.css', '.svg', '.png', '.woff2']);
function copyStatic(origin, target) {
  mkdirSync(target, { recursive: true });
  for (const entry of readdirSync(origin, { withFileTypes: true })) {
    const source = join(origin, entry.name);
    const destination = join(target, entry.name);
    if (entry.isDirectory()) copyStatic(source, destination);
    else if (staticExtensions.has(extname(entry.name))) copyFileSync(source, destination);
  }
}

copyStatic(join(tool, 'src', 'ui'), join(output, 'ui'));
copyFileSync(join(tool, 'project.schema.json'), join(output, 'project.schema.json'));
writeFileSync(join(output, 'package.json'), '{"type":"module"}\n');
console.log('Aura Particle Editor built at ' + output);
