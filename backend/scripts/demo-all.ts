/**
 * Single-process demo/QA boot for Render free tier.
 * Imports every service into one Node process (one V8 heap, many ports).
 */
if (process.env.PORT) {
  process.env.GATEWAY_PORT = process.env.PORT;
}

console.log(
  `Maekel single-process demo starting (gateway ${process.env.GATEWAY_PORT ?? 8080})`,
);

// Start domain services before the gateway proxy.
await import('../apps/identity-service/src/main.ts');
await import('../apps/market-service/src/main.ts');
await import('../apps/food-service/src/main.ts');
await import('../apps/ride-service/src/main.ts');
await import('../apps/chat-service/src/main.ts');
await import('../apps/games-service/src/main.ts');
await import('../apps/gateway/src/main.ts');
