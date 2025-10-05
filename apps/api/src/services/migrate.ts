// apps/api/src/services/migrate.ts
import fs from 'node:fs';
import path from 'node:path';
import { db } from './db';

const MIGRATIONS_ENABLED =
  (process.env.MIGRATIONS_ENABLED ?? 'true').toLowerCase() === 'true';
const EXPLICIT_DIR = process.env.MIGRATIONS_DIR || '';

interface Migration { file: string; sql: string }

async function ensureMigrationsTable() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      id serial PRIMARY KEY,
      filename text UNIQUE NOT NULL,
      applied_at timestamptz NOT NULL DEFAULT now()
    )
  `);
}

function resolveDir(): string | null {
  // 1) If MIGRATIONS_DIR is set, prefer it
  if (EXPLICIT_DIR) {
    const d = path.isAbsolute(EXPLICIT_DIR)
      ? EXPLICIT_DIR
      : path.resolve(process.cwd(), EXPLICIT_DIR);
    if (fs.existsSync(d) && fs.statSync(d).isDirectory()) return d;
  }

  // 2) Auto-discover common locations
  const candidates = [
    // original infra/db resolution from compiled output
    path.resolve(__dirname, '../../../../infra/db'),
    // repo-root/infra/db
    path.resolve(process.cwd(), 'infra/db'),
    // allow shipping migrations inside API
    path.resolve(process.cwd(), 'apps/api/migrations'),
  ];
  for (const c of candidates) {
    try {
      if (fs.statSync(c).isDirectory()) return c;
    } catch {}
  }
  return null;
}

export async function runMigrations(): Promise<void> {
  if (!MIGRATIONS_ENABLED) {
    console.warn('[migrate] skipped (MIGRATIONS_ENABLED=false)');
    return;
  }

  const dir = resolveDir();
  if (!dir) {
    const msg = 'Could not locate migrations directory (infra/db or MIGRATIONS_DIR)';
    if ((process.env.NODE_ENV ?? 'production') === 'production') {
      console.warn(`[migrate] ${msg}; skipping in production`);
      return;
    }
    // In dev, fail loudly so you notice
    throw new Error(msg);
  }

  await ensureMigrationsTable();

  const files = fs
    .readdirSync(dir)
    // support both 0001_init.sql and 0010-something.sql
    .filter((f) => /^\d{4}[_-].+\.sql$/i.test(f))
    .sort();

  if (files.length === 0) {
    console.warn(`[migrate] no .sql files in ${dir}, skipping`);
    return;
  }

  const doneQ = await db.query<{ filename: string }>(
    'SELECT filename FROM _migrations'
  );
  const done = new Set(doneQ.rows.map((r) => r.filename));

  for (const f of files) {
    if (done.has(f)) continue;

    const full = path.join(dir, f);
    const sql = fs.readFileSync(full, 'utf8');
    if (!sql.trim()) {
      await db.query(
        'INSERT INTO _migrations(filename) VALUES ($1) ON CONFLICT DO NOTHING',
        [f]
      );
      continue;
    }

    try {
      await db.query('BEGIN');
      await db.query(sql);
      await db.query('INSERT INTO _migrations(filename) VALUES ($1)', [f]);
      await db.query('COMMIT');
      console.log('[migrate] applied', f);
    } catch (e: any) {
      await db.query('ROLLBACK');
      console.error('[migrate] failed', f, e?.message);
      // In prod, log and continue serving; in dev, throw
      if ((process.env.NODE_ENV ?? 'production') !== 'production') throw e;
      return;
    }
  }
}

// Convenience CLI
if (require.main === module) {
  runMigrations()
    .then(() => {
      console.log('migrations complete');
      process.exit(0);
    })
    .catch((e) => {
      console.error(e?.message || e);
      process.exit(1);
    });
}
