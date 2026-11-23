import pg from 'pg';

import { databaseUrl, postgresSslEnabled } from './config.js';

const { Pool } = pg;

export type Db = pg.Pool;

export function createPool(connectionString: string): Db {
  // Keep pools small on free-tier hosts (one process × many DBs).
  const max = Number(process.env.PG_POOL_MAX ?? (postgresSslEnabled() ? 2 : 5));
  return new Pool({
    connectionString,
    max: Number.isFinite(max) && max > 0 ? max : 2,
    ssl: postgresSslEnabled()
      ? {
          // Neon / managed Postgres terminate TLS at the proxy.
          rejectUnauthorized: false,
        }
      : undefined,
  });
}

/**
 * Create `dbName` if missing by connecting to a maintenance DB first.
 * Tries `neondb` (Neon default) then `postgres`.
 */
export async function ensureDatabase(dbName: string): Promise<void> {
  if (!/^[a-zA-Z0-9_]+$/.test(dbName)) {
    throw new Error(`Invalid database name: ${dbName}`);
  }
  const candidates = ['neondb', 'postgres'];
  let lastError: unknown;
  for (const adminDb of candidates) {
    const pool = createPool(databaseUrl(adminDb));
    try {
      const exists = await pool.query(
        `SELECT 1 FROM pg_database WHERE datname = $1`,
        [dbName],
      );
      if (exists.rowCount === 0) {
        await pool.query(`CREATE DATABASE ${dbName}`);
        console.log(`[db] created database ${dbName}`);
      }
      await pool.end();
      return;
    } catch (err) {
      lastError = err;
      await pool.end().catch(() => undefined);
    }
  }
  throw lastError instanceof Error
    ? lastError
    : new Error(`Could not ensure database ${dbName}`);
}

export async function migrate(pool: Db, statements: string[]): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const sql of statements) {
      await client.query(sql);
    }
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
