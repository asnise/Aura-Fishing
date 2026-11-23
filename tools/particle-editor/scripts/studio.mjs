import { spawnSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const workspace = fileURLToPath(new URL('../../../', import.meta.url));
const project = fileURLToPath(new URL('../studio/default.project.json', import.meta.url));
const outputDir = join(workspace, 'build', 'aura-particle-editor');
const output = join(outputDir, 'AuraParticleImporter.rbxm');
const rojo = process.env.ROJO ?? (process.platform === 'win32' ? 'D:\\tools\\rojo\\rojo.exe' : 'rojo');

mkdirSync(outputDir, { recursive: true });
const build = spawnSync(rojo, ['build', project, '-o', output], { stdio: 'inherit', windowsHide: true });
if (build.error) throw build.error;
if (build.status !== 0) process.exit(build.status ?? 1);
console.log('Studio plugin package built at ' + output);
// Also install it where Studio loads local plugins; Studio reloads a changed plugin file by itself.
const install = spawnSync(rojo, ['build', project, '--plugin', 'AuraParticleImporter.rbxm'], { stdio: 'inherit', windowsHide: true });
if (install.status !== 0) process.exit(install.status ?? 1);
