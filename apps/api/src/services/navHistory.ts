import { db } from './db';
import type { NavPoint } from '../types/nav';

// NOTE: readLatestPPS is authoritative and reused by backfill + endpoints.

export async function readLatestPPS(): Promise<number> {
  try {
    const q = await db.query<{ p:string }>(`SELECT pps_1e18::text AS p FROM pps_series ORDER BY as_of_date DESC LIMIT 1`);
    const raw = Number(q.rows[0]?.p ?? 1e18);
    if (!Number.isFinite(raw) || raw <= 0) return 1;
    return raw / 1e18;
  } catch { return 1; }
}

export async function persistTodayPPS(date: Date = new Date()): Promise<void> {
  try {
    const pps = await readLatestPPS();
    const d = date.toISOString().slice(0,10); // YYYY-MM-DD
    await db.query(`INSERT INTO nav_history(d, pps) VALUES ($1,$2)
      ON CONFLICT (d) DO UPDATE SET pps = EXCLUDED.pps`, [d, pps]);
  } catch (e) {
    console.warn('persistTodayPPS failed', (e as any)?.message);
  }
}

async function ensureNavHistoryTable(): Promise<void> {
  await db.query(`CREATE TABLE IF NOT EXISTS public.nav_history (
    d DATE PRIMARY KEY,
    pps NUMERIC NOT NULL CHECK (pps > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  CREATE INDEX IF NOT EXISTS idx_nav_history_created_at ON public.nav_history (created_at);`);
}

export async function getNavSeries(days = 30): Promise<NavPoint[]> {
  try {
    let q = await db.query<{ d: string; pps: string }>(`SELECT d::text, pps::text FROM nav_history WHERE d >= (current_date - interval '${days} days') ORDER BY d ASC`);
    if (!q.rowCount) {
      // Fallback derive from pps_series (as_of_date + pps_1e18) if nav_history not yet populated
      q = await db.query<{ d: string; pps: string }>(`SELECT as_of_date::text AS d, (pps_1e18/1e18)::text AS pps FROM pps_series WHERE as_of_date >= (current_date - interval '${days} days') ORDER BY as_of_date ASC`);
    }
    if (!q.rowCount) return [];
    const rows = q.rows.map(r => ({ d: r.d, pps: Number(r.pps) })).filter(r => Number.isFinite(r.pps) && r.pps>0);
    // Fill gaps forward
    const byDate: Record<string, number> = {};
    for (const r of rows) byDate[r.d] = r.pps;
    const out: NavPoint[] = [];
    const today = new Date(rows[rows.length-1].d + 'T00:00:00Z');
    const first = new Date(rows[0].d + 'T00:00:00Z');
    for (let d = new Date(first); d <= today; d.setUTCDate(d.getUTCDate()+1)) {
      const iso = d.toISOString().slice(0,10);
      if (byDate[iso] == null) {
        const prev = out.length ? out[out.length-1].pps : rows[0].pps;
        out.push({ d: iso, pps: prev });
      } else {
        out.push({ d: iso, pps: byDate[iso] });
      }
      if (out.length >= days) break; // guard
    }
    return out.slice(-days);
  } catch (e) {
    const msg = (e as any)?.message || '';
    if (/relation "?nav_history"? does not exist/i.test(msg)) {
      try {
        await ensureNavHistoryTable();
        // retry once
        return await getNavSeries(days);
      } catch (e2) {
        console.warn('ensureNavHistoryTable failed', (e2 as any)?.message);
      }
    } else {
      console.warn('getNavSeries failed', msg);
    }
    return [];
  }
}
