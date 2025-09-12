// Quick sanity script for migration 0019 without ts-node dependency.
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: process.env.PGSSL === '1' ? { rejectUnauthorized:false } : undefined });

async function exists(regclass) {
  const q = await pool.query('SELECT to_regclass($1) as r', [regclass]);
  return !!q.rows[0].r;
}

(async () => {
  const out = {};
  try {
    out.tvl_buffer = await exists('public.tvl_buffer');
    out.allocation_baskets = await exists('public.allocation_baskets');
    out.allocation_basket_venues = await exists('public.allocation_basket_venues');
    out.liquidity_events = await exists('public.liquidity_events');
    const enumCheck = await pool.query("SELECT 1 FROM pg_type WHERE typname='liquidity_kind'");
    out.liquidity_kind_enum = enumCheck.rowCount === 1;
    if (out.tvl_buffer) {
      const row = await pool.query('SELECT id, buffer_usd FROM public.tvl_buffer WHERE id=1');
      out.tvl_buffer_row = row.rowCount === 1;
      if (row.rowCount) out.buffer_usd = row.rows[0].buffer_usd;
    }
    console.log(JSON.stringify({ success:true, out }));
  } catch (e) {
    console.error(JSON.stringify({ success:false, error:e.message, out }));
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
})();