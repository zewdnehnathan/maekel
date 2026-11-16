import { config as loadEnv } from 'dotenv';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = fileURLToPath(new URL('.', import.meta.url));
loadEnv({ path: resolve(here, '../../../.env') });

export function env(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (value === undefined || value === '') {
    throw new Error(`Missing env ${name}`);
  }
  return value;
}

export function envInt(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const n = Number(raw);
  if (Number.isNaN(n)) throw new Error(`Invalid int env ${name}`);
  return n;
}

export function databaseUrl(dbName: string): string {
  const host = env('POSTGRES_HOST', 'localhost');
  const port = env('POSTGRES_PORT', '5432');
  const user = env('POSTGRES_USER', 'postgres');
  const password = env('POSTGRES_PASSWORD', 'postgres');
  const ssl =
    (process.env.POSTGRES_SSL ?? '').toLowerCase() === 'true' ||
    (process.env.POSTGRES_SSL ?? '') === '1'
      ? '?sslmode=require'
      : '';
  return `postgres://${encodeURIComponent(user)}:${encodeURIComponent(password)}@${host}:${port}/${dbName}${ssl}`;
}

/** True when cloud Postgres (Neon, etc.) needs TLS. */
export function postgresSslEnabled(): boolean {
  const raw = (process.env.POSTGRES_SSL ?? '').toLowerCase();
  return raw === 'true' || raw === '1';
}
