/**
 * Starts all Maekel services in one process group for demo/QA hosts (Render).
 * Bind gateway to platform PORT when provided.
 */
import { spawn } from 'node:child_process';

if (process.env.PORT) {
  process.env.GATEWAY_PORT = process.env.PORT;
}

const services = [
  ['identity', '@maekel/identity-service'],
  ['market', '@maekel/market-service'],
  ['food', '@maekel/food-service'],
  ['ride', '@maekel/ride-service'],
  ['chat', '@maekel/chat-service'],
  ['games', '@maekel/games-service'],
  ['gateway', '@maekel/gateway'],
];

const children = [];

function start(name, workspace) {
  const child = spawn(
    'npm',
    ['run', 'start', '-w', workspace],
    {
      stdio: ['ignore', 'pipe', 'pipe'],
      env: process.env,
      shell: true,
    },
  );
  const tag = (stream) => {
    child[stream].on('data', (buf) => {
      const text = buf.toString();
      for (const line of text.split(/\r?\n/)) {
        if (line.trim()) console.log(`[${name}] ${line}`);
      }
    });
  };
  tag('stdout');
  tag('stderr');
  child.on('exit', (code, signal) => {
    console.error(`[${name}] exited code=${code} signal=${signal}`);
    for (const c of children) {
      if (!c.killed) c.kill('SIGTERM');
    }
    process.exit(code ?? 1);
  });
  children.push(child);
}

for (const [name, workspace] of services) {
  start(name, workspace);
}

console.log(
  `Maekel demo stack starting (gateway port ${process.env.GATEWAY_PORT ?? 8080})`,
);

function shutdown() {
  for (const c of children) {
    if (!c.killed) c.kill('SIGTERM');
  }
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
