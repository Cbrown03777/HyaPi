// CommonJS runtime check for migration 0019 artifacts
let db;
try {
  // Try direct JS (if previously compiled)
  ({ db } = require('../services/db'));
} catch {
  // Fallback: attempt to register ts-node on the fly (dev dependency) if available
  try { require('ts-node/register'); ({ db } = require('../services/db')); } catch (e) {
    console.error('Unable to load db pool module', e.message);
    process.exit(1);
  }
}

async function tableExists(name) {
  const q = await db.query('SELECT to_regclass($1) as r', [name]);
  return !!q.rows[0].r;
}

(async () => {
  const results = {};
  try {
    results.tvl_buffer_exists = await tableExists('public.tvl_buffer');
    results.allocation_baskets_exists = await tableExists('public.allocation_baskets');
    results.allocation_basket_venues_exists = await tableExists('public.allocation_basket_venues');
    results.liquidity_events_exists = await tableExists('public.liquidity_events');
    const enumCheck = await db.query("SELECT 1 FROM pg_type WHERE typname='liquidity_kind'");
    results.liquidity_kind_type = enumCheck.rowCount === 1;
    if (results.tvl_buffer_exists) {
      const buf = await db.query('SELECT buffer_usd FROM public.tvl_buffer WHERE id=1');
      results.tvl_buffer_row = buf.rowCount === 1;
    }
    console.log(JSON.stringify({ success: true, results }));
  } catch (e) {
    console.error(JSON.stringify({ success:false, error: e.message, results }));
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();