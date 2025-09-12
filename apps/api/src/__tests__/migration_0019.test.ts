import { db } from '../services/db';

async function tableExists(name: string) {
  const q = await db.query(`SELECT to_regclass($1) as r`, [name]);
  return !!q.rows[0].r;
}

(async () => {
  const results: Record<string, any> = {};
  try {
    results.tvl_buffer_exists = await tableExists('public.tvl_buffer');
    results.allocation_baskets_exists = await tableExists('public.allocation_baskets');
    results.allocation_basket_venues_exists = await tableExists('public.allocation_basket_venues');
    results.liquidity_events_exists = await tableExists('public.liquidity_events');
    const enumCheck = await db.query(`SELECT 1 FROM pg_type WHERE typname='liquidity_kind'`);
    results.liquidity_kind_type = enumCheck.rowCount === 1;
    if (results.tvl_buffer_exists) {
      const buf = await db.query(`SELECT buffer_usd FROM public.tvl_buffer WHERE id=1`);
      results.tvl_buffer_row = buf.rowCount === 1;
    }
    console.log(JSON.stringify({ success: true, results }));
  } catch (e:any) {
    console.error(JSON.stringify({ success:false, error: e.message, results }));
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
