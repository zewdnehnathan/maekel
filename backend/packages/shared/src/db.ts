import pg from 'pg';

import { postgresSslEnabled } from './config.js';

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
