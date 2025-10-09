import path from 'node:path';
import dotenv from 'dotenv';
// Load local env like the server does
dotenv.config({ path: path.resolve(__dirname, '../.env') });
import { db } from '../src/services/db';
import axios from 'axios';

async function findCandidateTables() {
  const patterns = ['pps','share','shares','principal','yield','balance','nav','tvl'];
  const likeClauses = patterns.map(p => `column_name ILIKE '%${p}%'`).join(' OR ');
  const sql = `SELECT DISTINCT table_schema, table_name
               FROM information_schema.columns
               WHERE (${likeClauses})
                 AND table_schema NOT IN ('pg_catalog','information_schema')
               ORDER BY 1,2`;
  const q = await db.query<{ table_schema: string; table_name: string }>(sql);
  return q.rows;
}

async function describeTable(schema: string, table: string) {
  const cols = await db.query<{ column_name: string; data_type: string; is_nullable: string }>(
    `SELECT column_name, data_type, is_nullable
       FROM information_schema.columns
      WHERE table_schema = $1 AND table_name = $2
      ORDER BY ordinal_position`, [schema, table]
  );
  const cnt = await db.query<{ c: string }>(`SELECT COUNT(*)::text AS c FROM ${schema}.${table}`);
  return { schema, table, count: cnt.rows[0]?.c, columns: cols.rows };
}

async function main() {
  const url = process.env.DATABASE_URL || '';
  const masked = url ? url.replace(/(:\/\/[^:]*):([^@]*@)/, '$1:***$2') : '<empty>';

  // HTTP mode: Use remote API to introspect when DATABASE_URL is an http(s) base
  if (/^https?:\/\//i.test(url)) {
    const base = url.replace(/\/$/, '');
    const token = process.env.ADMIN_API_TOKEN || '';
    if (!token) {
      console.error('[inspect] ADMIN_API_TOKEN is required for HTTP introspection against', base);
      process.exit(3);
    }
    console.log('[inspect] Using remote HTTP mode against', base);
    const hdrs = { 'X-Admin-Token': token } as any;
    try {
      const r = await axios.get(`${base}/v1/admin/db/inspect`, { headers: hdrs, timeout: 15000 });
      const data = r.data?.data || [];
      for (const d of data) {
        console.log(`\nTable: ${d.schema}.${d.table} (rows=${d.count ?? 'unknown'})`);
        if (Array.isArray(d.columns)) {
          for (const c of d.columns) {
            console.log(`  - ${c.column_name} :: ${c.data_type}${c.is_nullable === 'NO' ? '' : ' (nullable)'}`);
          }
        } else if (d.error) {
          console.log('  <error>', d.error);
        }
      }
      const p = await axios.get(`${base}/v1/admin/db/print`, { headers: hdrs, timeout: 15000 });
      console.log('\n-- Constraints --');
      for (const c of p.data?.data?.constraints || []) {
        console.log(`${c.table}.${c.conname}: ${c.def}`);
      }
    } catch (e: any) {
      console.error('[inspect] Remote HTTP mode failed', e?.response?.status, e?.message);
      process.exit(4);
    }
    return;
  }

  // Direct Postgres mode
  if (!/^postgres(ql)?:\/\//i.test(url)) {
    console.error('[inspect] DATABASE_URL missing or not a postgres URL:', masked);
    console.error('Example format: postgres://user:pass@host:5432/dbname');
    process.exit(2);
  }
  console.log('Inspecting schema for NAV/PPS related tables...');
  const tables = await findCandidateTables();
  for (const t of tables) {
    try {
      const d = await describeTable(t.table_schema, t.table_name);
      console.log(`\nTable: ${d.schema}.${d.table} (rows=${d.count})`);
      for (const c of d.columns) {
        console.log(`  - ${c.column_name} :: ${c.data_type}${c.is_nullable === 'NO' ? '' : ' (nullable)'}`);
      }
    } catch (e:any) {
      console.warn('Describe failed for', t, e.message);
    }
  }
  await db.end();
}

main().catch(e=>{console.error(e); process.exit(1);});
