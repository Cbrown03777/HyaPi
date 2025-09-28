import { db } from '../src/services/db';

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
