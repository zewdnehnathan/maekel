import proxy from '@fastify/http-proxy';
import {
  createService,
  env,
  envInt,
  listen,
} from '@maekel/shared';

const port = envInt('GATEWAY_PORT', 8080);

async function boot() {
  const app = await createService({
    name: 'gateway',
    port,
    bodyLimit: 12 * 1024 * 1024,
  });

  const routes: Array<{ prefix: string; upstream: string }> = [
    { prefix: '/v1/auth', upstream: env('IDENTITY_URL', 'http://127.0.0.1:3001') },
    { prefix: '/v1/me', upstream: env('IDENTITY_URL', 'http://127.0.0.1:3001') },
    { prefix: '/v1/admin', upstream: env('IDENTITY_URL', 'http://127.0.0.1:3001') },
    { prefix: '/v1/market', upstream: env('MARKET_URL', 'http://127.0.0.1:3002') },
    { prefix: '/v1/food', upstream: env('FOOD_URL', 'http://127.0.0.1:3003') },
    { prefix: '/v1/ride', upstream: env('RIDE_URL', 'http://127.0.0.1:3004') },
    { prefix: '/v1/chat', upstream: env('CHAT_URL', 'http://127.0.0.1:3005') },
    { prefix: '/v1/games', upstream: env('GAMES_URL', 'http://127.0.0.1:3006') },
    { prefix: '/v1/events', upstream: env('EVENTS_URL', 'http://127.0.0.1:3007') },
  ];

  for (const route of routes) {
    await app.register(proxy, {
      upstream: route.upstream,
      prefix: route.prefix,
      rewritePrefix: route.prefix,
    });
  }

  app.get('/', async () => ({
    name: 'Maekel Gateway',
    version: '0.1.0',
    routes: routes.map((r) => r.prefix),
  }));

  await listen(app, port);
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
