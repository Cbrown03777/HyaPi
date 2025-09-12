// Buffer target & hysteresis utilities
export const BUFFER_TARGET_BPS = Number(process.env.BUFFER_TARGET_BPS ?? 1000); // 10%
export const BUFFER_HYSTERESIS_BPS = Number(process.env.BUFFER_HYSTERESIS_BPS ?? 200); // 2%

export function bufferTargets(totalUsd: number) {
  const target = totalUsd * (BUFFER_TARGET_BPS / 10_000);
  const upper = target * (1 + BUFFER_HYSTERESIS_BPS / 10_000);
  const lower = target * (1 - BUFFER_HYSTERESIS_BPS / 10_000);
  return { target, upper, lower };
}

// Placeholder for future routing logic (planned_actions / rebalance queue)
// Currently only computes whether excess exists and logs.
import { db } from './db';

let plannedActionsHasIdemKey: boolean | null = null;
let plannedActionsHasIdemUniqueIdx: boolean | null = null;
async function hasPlannedActionsIdem(): Promise<boolean> {
  if (plannedActionsHasIdemKey === null) {
    try {
  const q = await db.query(`SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='planned_actions' AND column_name='idem_key'`);
  plannedActionsHasIdemKey = (q as any)?.rowCount > 0;
    } catch {
      plannedActionsHasIdemKey = false;
    }
  }
  return plannedActionsHasIdemKey;
}
async function hasPlannedActionsIdemUniqueIndex(): Promise<boolean> {
  if (plannedActionsHasIdemUniqueIdx === null) {
    try {
      const q = await db.query(`SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='planned_actions' AND indexname='uq_planned_actions_idem_key'`);
      plannedActionsHasIdemUniqueIdx = (q as any)?.rowCount > 0;
    } catch {
      plannedActionsHasIdemUniqueIdx = false;
    }
  }
  return plannedActionsHasIdemUniqueIdx;
}
async function insertPlannedAction(kind: 'supply'|'redeem', venue: string, amount: number, reason: string, idem: string | null) {
  const hasIdem = await hasPlannedActionsIdem();
  const hasIdx = await hasPlannedActionsIdemUniqueIndex();
  if (hasIdem && idem) {
    if (hasIdx) {
      try {
        await db.query(`INSERT INTO planned_actions(kind, venue_key, amount_usd, reason, idem_key) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (idem_key) DO NOTHING`, [kind, venue, amount, reason, idem]);
        return;
      } catch (e:any) {
        if (!/no unique|exclusion constraint/i.test(e?.message || '')) throw e;
        // fall through to WHERE NOT EXISTS
      }
    }
    // Fallback idempotency without unique index
    await db.query(`INSERT INTO planned_actions(kind, venue_key, amount_usd, reason, idem_key)
                    SELECT $1,$2,$3,$4,$5
                    WHERE NOT EXISTS (SELECT 1 FROM planned_actions WHERE idem_key=$5)`, [kind, venue, amount, reason, idem]);
  } else {
    await db.query(`INSERT INTO planned_actions(kind, venue_key, amount_usd, reason) VALUES ($1,$2,$3,$4)`, [kind, venue, amount, reason]);
  }
}
// Lightweight active target loader (mirrors alloc.ts precedence) returning normalized weights.
async function loadActiveTargetsSimple(): Promise<Record<string, number>> {
  const q = await db.query<{ key:string; weight_fraction:string; source:string; expires_at:Date|null; applied_at:Date }>(
    `SELECT key, weight_fraction, source, expires_at, applied_at
       FROM allocation_targets
      WHERE (source='override' AND (expires_at IS NULL OR expires_at > now()))
         OR source='gov'
      ORDER BY (source='override') DESC, applied_at DESC`
  );
  const map: Record<string, number> = {};
  for (const r of q.rows) if (!(r.key in map)) map[r.key] = Number(r.weight_fraction);
  const total = Object.values(map).reduce((s,v)=>s+v,0) || 0;
  if (total>0) for (const k of Object.keys(map)) map[k] = map[k]/total;
  return map;
}

export async function maybeRouteExcessBuffer() {
  try {
    const buf = await db.query<{ buffer_usd: string }>(`SELECT buffer_usd FROM tvl_buffer WHERE id=1 FOR UPDATE`);
    const bufferUsd = Number(buf.rows[0]?.buffer_usd ?? 0);
    const vh = await db.query<{ key:string; usd_notional: string }>(`SELECT key, usd_notional FROM venue_holdings`);
    const deployed = vh.rows.reduce((s,r)=> s + Number(r.usd_notional), 0);
    const total = deployed + bufferUsd;
    if (!total) return { routed:false, reason:'empty-total' };
    const { target, upper } = bufferTargets(total);
    if (bufferUsd <= upper) return { routed:false, reason:'within-band' };
    const excess = bufferUsd - target;
  const targets = await loadActiveTargetsSimple();
    if (!Object.keys(targets).length) return { routed:false, reason:'no-targets' };
    // Compute desired delta per venue proportional to target weights.
  const actions: Array<{ venue:string; amount:number }> = [];
  const top3 = Object.entries(targets).sort((a,b)=> b[1]-a[1]).slice(0,3);
  for (const [k,w] of top3) actions.push({ venue:k, amount: excess * w });
    // Insert planned supply actions & decrease buffer immediately by excess (optimistic) down to target.
    await db.query('UPDATE tvl_buffer SET buffer_usd = buffer_usd - $1, updated_at = now() WHERE id=1', [excess]);
    for (const a of actions) {
      if (a.amount <= 0) continue;
      const idem = `supply:${a.venue}:${Date.now()}`;
      await insertPlannedAction('supply', a.venue, a.amount, 'route_excess_buffer', idem);
      await db.query(`INSERT INTO liquidity_events(kind, amount_usd, venue_key, tx_ref) VALUES ('rebalance_in',$1,$2,$3)`, [a.amount, a.venue, 'plan:buffer-route']);
    }
    console.log(`[buffer] routed excess ${excess.toFixed(2)} across ${actions.length} venues`);
    return { routed:true, excess, actions: actions.length };
  } catch (e:any) {
    console.warn('maybeRouteExcessBuffer error', e.message);
    return { routed:false, error:e.message };
  }
}

// Compute proportional withdrawal plan when buffer below lower target (not invoked yet)
export async function planTopUpBuffer() {
  const buf = await db.query<{ buffer_usd: string }>(`SELECT buffer_usd FROM tvl_buffer WHERE id=1`);
  const bufferUsd = Number(buf.rows[0]?.buffer_usd ?? 0);
  const vh = await db.query<{ key:string; usd_notional:string }>(`SELECT key, usd_notional FROM venue_holdings`);
  const deployed = vh.rows.reduce((s,r)=> s + Number(r.usd_notional), 0);
  const total = deployed + bufferUsd;
  const { target, lower } = bufferTargets(total);
  if (bufferUsd >= lower) return { needed:0 };
  const needed = target - bufferUsd;
  // Proportional pulls
  const actions: Array<{ venue:string; amount:number }> = [];
  const top3 = [...vh.rows].sort((a,b)=> Number(b.usd_notional)-Number(a.usd_notional)).slice(0,3);
  for (const r of top3) {
    const part = deployed>0 ? (Number(r.usd_notional)/deployed) : 0;
    const amt = needed * part;
    if (amt>0) actions.push({ venue:r.key, amount: amt });
  }
  for (const a of actions) {
    const idem = `redeem:${a.venue}:${Date.now()}`;
    await insertPlannedAction('redeem', a.venue, a.amount, 'top_up_buffer', idem);
    await db.query(`INSERT INTO liquidity_events(kind, amount_usd, venue_key, tx_ref) VALUES ('rebalance_out',$1,$2,$3)`, [a.amount, a.venue, 'plan:buffer-topup']);
  }
  return { needed, actions: actions.length };
}
