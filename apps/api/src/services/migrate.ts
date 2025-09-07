import fs from 'node:fs';
import path from 'node:path';
import { db } from './db';

interface Migration { file: string; sql: string }

// Simple migrations table (idempotent creation)
async function ensureMigrationsTable() {
	await db.query(`CREATE TABLE IF NOT EXISTS _migrations (
		id serial PRIMARY KEY,
		filename text UNIQUE NOT NULL,
		applied_at timestamptz NOT NULL DEFAULT now()
	)`);
}

export async function runMigrations(dir?: string) {
	// Resolve migrations directory robustly: prefer repo-root/infra/db
	if (!dir) {
		const candidates = [
			path.resolve(__dirname, '../../../../infra/db'), // services -> src -> api -> apps -> (root)/infra/db
			path.resolve(process.cwd(), 'infra/db'),
		];
		for (const c of candidates) {
			try { if (fs.statSync(c).isDirectory()) { dir = c; break; } } catch {}
		}
		if (!dir) throw new Error('Could not locate infra/db directory for migrations');
	}
	await ensureMigrationsTable();
	const doneQ = await db.query<{ filename: string }>('SELECT filename FROM _migrations');
	const done = new Set(doneQ.rows.map(r => r.filename));
	const files = fs.readdirSync(dir)
		.filter(f => /^(\d{4}_.+\.sql)$/i.test(f))
		.sort();
	for (const f of files) {
		if (done.has(f)) continue;
		const full = path.join(dir, f);
		const sql = fs.readFileSync(full, 'utf8');
		if (!sql.trim()) { // skip empty but still mark so we don't warn each boot
			await db.query('INSERT INTO _migrations(filename) VALUES ($1) ON CONFLICT DO NOTHING', [f]);
			continue;
		}
		try {
			await db.query('BEGIN');
			await db.query(sql);
			await db.query('INSERT INTO _migrations(filename) VALUES ($1)', [f]);
			await db.query('COMMIT');
			console.log('[migrate] applied', f);
		} catch (e:any) {
			await db.query('ROLLBACK');
			console.error('[migrate] failed', f, e.message);
			throw e; // stop further processing; surfacing first failure
		}
	}
}

// Convenience one-shot when launched directly (optional)
if (require.main === module) {
	runMigrations().then(()=>{ console.log('migrations complete'); process.exit(0); })
		.catch(()=> process.exit(1));
}
