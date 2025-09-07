import { Pool, PoolClient } from 'pg';
export const db = new Pool({
  connectionString: process.env.DATABASE_URL, // e.g. postgres://user:pass@host:5432/db
  ssl: process.env.PGSSL === '1' ? { rejectUnauthorized: false } : undefined
});
// Generic transaction helper
export async function withTx<T>(fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const out = await fn(client);
    await client.query('COMMIT');
    return out;
  } catch (e) {
    try { await client.query('ROLLBACK'); } catch {}
    throw e;
  } finally {
    client.release();
  }
}

// Optional alias for existing call-sites that used db.tx(...)
export const tx = withTx;
export type { PoolClient };