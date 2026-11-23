import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const workspace = fileURLToPath(new URL('../../../', import.meta.url));
const server = fileURLToPath(new URL('../../../build/aura-particle-editor/app/server/server.js', import.meta.url));
if (!existsSync(server)) {
  console.error('Build Aura Particle Editor first.');
  process.exit(1);
}
const child = spawn(process.execPath, [server, '--workspace', workspace, ...process.argv.slice(2)], { stdio: 'inherit' });
child.on('error', error => {
  console.error(error.message);
  process.exitCode = 1;
});
child.on('exit', code => { process.exitCode = code ?? 1; });
