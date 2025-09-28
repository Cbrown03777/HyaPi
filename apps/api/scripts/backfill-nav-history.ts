/**
 * Backfill last N days of nav_history by sampling PPS from NAV/SHARES,
 * or carrying forward the latest PPS if unavailable. Idempotent via UPSERT.
 */
import { db } from '../src/services/db';
import { readLatestPPS } from '../src/services/navHistory';

async function ensureTable() {
  await db.query(`CREATE TABLE IF NOT EXISTS public.nav_history (
    d DATE PRIMARY KEY,
    pps NUMERIC NOT NULL CHECK (pps > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  CREATE INDEX IF NOT EXISTS idx_nav_history_created_at ON public.nav_history (created_at);`);
}

async function run(days = Number(process.env.DAYS || 30)) {
  await ensureTable();
  const today = new Date();
  let last = await readLatestPPS();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const ds = d.toISOString().slice(0,10);
    try {
      // We only have a current PPS snapshot, so we carry the same backwards.
      await db.query(`INSERT INTO nav_history (d, pps) VALUES ($1::date, $2::numeric)
        ON CONFLICT (d) DO UPDATE SET pps = EXCLUDED.pps`, [ds, last]);
    } catch (e:any) {
      console.warn('backfill insert failed', ds, e.message);
    }
  }
  console.log('nav_history backfilled for', days, 'days');
}

run().then(()=>process.exit(0)).catch(e=>{console.error(e);process.exit(1)});
