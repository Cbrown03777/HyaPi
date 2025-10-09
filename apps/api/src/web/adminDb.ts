import { Router, Request, Response, NextFunction } from 'express';
import { db } from '../services/db';

function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const token = req.header('x-admin-token') || req.header('X-Admin-Token');
  const expected = process.env.ADMIN_API_TOKEN || '';
  if (!expected) {
    return res.status(503).json({ ok: false, error: { code: 'ADMIN_DISABLED', message: 'ADMIN_API_TOKEN not set' } });
  }
  if (!token || token !== expected) {
    return res.status(401).json({ ok: false, error: { code: 'UNAUTH' } });
  }
  return next();
}

export const adminDbRouter = Router();

// GET /v1/admin/db/inspect - discover NAV/PPS related tables and describe them
adminDbRouter.get('/inspect', requireAdmin, async (_req, res) => {
  try {
    const patterns = ['pps','share','shares','principal','yield','balance','nav','tvl'];
    const likeClauses = patterns.map(p => `column_name ILIKE '%${p}%'`).join(' OR ');
    const sql = `SELECT DISTINCT table_schema, table_name
                 FROM information_schema.columns
                 WHERE (${likeClauses})
                   AND table_schema NOT IN ('pg_catalog','information_schema')
                 ORDER BY 1,2`;
    const tables = await db.query<{ table_schema: string; table_name: string }>(sql);
    const out: any[] = [];
    for (const t of tables.rows) {
      try {
        const cols = await db.query<{ column_name: string; data_type: string; is_nullable: string }>(
          `SELECT column_name, data_type, is_nullable
             FROM information_schema.columns
            WHERE table_schema = $1 AND table_name = $2
            ORDER BY ordinal_position`, [t.table_schema, t.table_name]
        );
        const cnt = await db.query<{ c: string }>(`SELECT COUNT(*)::text AS c FROM ${t.table_schema}.${t.table_name}`);
        out.push({ schema: t.table_schema, table: t.table_name, count: cnt.rows[0]?.c, columns: cols.rows });
      } catch (e: any) {
        out.push({ schema: t.table_schema, table: t.table_name, error: e?.message || 'describe_failed' });
      }
    }
    res.json({ ok: true, data: out });
  } catch (e: any) {
    res.status(500).json({ ok: false, error: { code: 'INSPECT_FAIL', message: e?.message || 'error' } });
  }
});

// GET /v1/admin/db/print - print key tables definitions and constraints
adminDbRouter.get('/print', requireAdmin, async (_req, res) => {
  try {
    const wanted = ['pi_payments','stakes','balances','liquidity_events'];
    const defs: Record<string, any> = {};
    for (const tbl of wanted) {
      const cols = await db.query(`SELECT column_name, data_type, is_nullable, column_default
                                     FROM information_schema.columns
                                    WHERE table_schema='public' AND table_name=$1
                                    ORDER BY ordinal_position`, [tbl]);
      const idx = await db.query(`SELECT indexname, indexdef FROM pg_indexes WHERE schemaname='public' AND tablename=$1 ORDER BY indexname`, [tbl]);
      defs[tbl] = { columns: cols.rows, indexes: idx.rows };
    }
    const constraints = await db.query(
      `SELECT t.relname AS table, c.conname, pg_get_constraintdef(c.oid) AS def
         FROM pg_constraint c
         JOIN pg_class t ON c.conrelid = t.oid
        WHERE t.relname = ANY($1::text[])`, [wanted]
    );
    res.json({ ok: true, data: { defs, constraints: constraints.rows } });
  } catch (e: any) {
    res.status(500).json({ ok: false, error: { code: 'PRINT_FAIL', message: e?.message || 'error' } });
  }
});
