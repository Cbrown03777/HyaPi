// apps/api/src/services/alloc.ts
import { db } from './db';
import { getCompositeRates } from './gov';
// NOTE: @hyapi/alloc currently exports computeTargets/planRebalance from source (ensure build ran)
import { computeTargets, planRebalance } from '@hyapi/alloc';
import type { Guardrails, GovWeights, Rate } from '@hyapi/alloc';

export async function loadGovWeights(): Promise<GovWeights> {
  const q = await db.query<{ chain: string; weight_fraction: number }>(
    `SELECT chain, weight_fraction FROM allocations_current`
  );
  const mapping: Record<string,string> = {
    sui: 'aave:USDT',
    aptos: 'justlend:USDT',
    cosmos: 'stride:stATOM'
  };
  const out: Record<string, number> = {};
  for (const r of q.rows) {
    const key = mapping[r.chain];
    if (key) out[key] = r.weight_fraction;
  }
  return out;
}

export async function loadHoldings(): Promise<Record<string, number>> {
  const q = await db.query<{ key: string; usd_notional: string }>(
    `SELECT key, usd_notional FROM venue_holdings`
  );
  const out: Record<string, number> = {};
  for (const r of q.rows) out[r.key] = Number(r.usd_notional);
  return out;
}

export function defaultGuards(): Guardrails {
  return {
    lambda: Number(process.env.ALLOC_LAMBDA ?? '0.7'),
    softmaxK: Number(process.env.ALLOC_K ?? '6'),
    bufferBps: Number(process.env.ALLOC_BUFFER_BPS ?? '1000'),
    minTradeUSD: Number(process.env.ALLOC_MIN_TRADE_USD ?? '50'),
    maxVenueBps: {
      aave: Number(process.env.ALLOC_CAP_AAVE_BPS ?? '6000'),
      justlend: Number(process.env.ALLOC_CAP_JUSTLEND_BPS ?? '6000'),
      stride: Number(process.env.ALLOC_CAP_STRIDE_BPS ?? '6000')
    },
    maxDriftBps: Number(process.env.ALLOC_MAX_DRIFT_BPS ?? '25'),
    cooldownSec: Number(process.env.ALLOC_COOLDOWN_SEC ?? '600'),
    allowVenue: {
      aave: process.env.ALLOW_AAVE !== '0',
      justlend: process.env.ALLOW_JUSTLEND !== '0',
      stride: process.env.ALLOW_STRIDE !== '0'
    },
    staleRateMaxSec: Number(process.env.ALLOC_STALE_SEC ?? '3600')
  };
}

export async function makePreview(tvlUSD: number) {
  const [gov, rates, current] = await Promise.all([
    loadGovWeights(),
    getCompositeRates(),
    loadHoldings()
  ]);

  const guards = defaultGuards();

  // Persist rate snapshots (best effort)
  for (const r of rates) {
    try {
      await db.query(`INSERT INTO venue_rates (key, base_apr, as_of) VALUES ($1,$2,$3)`, [
        `${r.venue}:${r.market}`, r.baseApr, r.asOf
      ]);
    } catch {}
  }

  const targets = computeTargets(gov as any, rates as any, guards as any);
  const plan = planRebalance({
    tvlUSD,
    bufferBps: guards.bufferBps,
    current: current as any,
    targetWeights: targets as any,
    minTradeUSD: guards.minTradeUSD,
    maxDriftBps: guards.maxDriftBps
  });

  return { guards, gov, rates, targets, plan };
}

export async function savePlanAndMarkExecuted(preview: Awaited<ReturnType<typeof makePreview>>) {
  const { plan, targets } = preview as any;
  const ins = await db.query<{ id: string }>(
    `INSERT INTO rebalance_plans (tvl_usd, buffer_usd, drift_bps, target_json, actions_json, status)
     VALUES ($1,$2,$3,$4,$5,'executed') RETURNING id`, [
      (plan.bufferUSD ?? 0) + (plan.totalDeltaUSD ?? 0),
      plan.bufferUSD ?? 0,
      plan.driftBps ?? 0,
      JSON.stringify(targets),
      JSON.stringify(plan.actions ?? [])
    ]
  );
  return ins.rows[0].id;
}

// Apply a set of absolute holdings (usd notionals) to the venue_holdings table.
// Keys may include chain (venue:chain:market) or just (venue:market). We upsert each.
export async function updateHoldings(next: Record<string, number>) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    for (const [key, usd] of Object.entries(next)) {
      await client.query(
        `INSERT INTO venue_holdings(key, usd_notional) VALUES ($1,$2)
         ON CONFLICT (key) DO UPDATE SET usd_notional = EXCLUDED.usd_notional, updated_at = now()`,
        [key, usd]
      );
    }
    // Optionally zero out keys that disappeared (we keep them for history; skip deletion)
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally { client.release(); }
}

// Allocation summary (current holdings × live rates → gross & net APY)
export async function allocationSummary() {
  const [holdings, rates] = await Promise.all([loadHoldings(), getCompositeRates()]);
  const feeShare = 0.10; // platform reward fee (10%)
  const baskets: Array<{
    key: string;
    usd: number;
    baseApr?: number;
    rewardApr?: number;
    grossApy?: number;
    netApy?: number;
    dailyNetUsd?: number;
  }> = [];
  const totalUsd = Object.values(holdings).reduce((a,b)=>a+b,0) || 0;
  const rateIndex: Record<string, any> = {};
  for (const r of rates) {
    // canonical keys without chain and with chain if present
    const baseKey = `${r.venue}:${r.market}`;
    if (!(baseKey in rateIndex)) rateIndex[baseKey] = r;
    if ((r as any).chain) {
      const chainKey = `${r.venue}:${(r as any).chain}:${r.market}`;
      rateIndex[chainKey] = r;
    }
  }
  for (const [key, usd] of Object.entries(holdings)) {
    const r = rateIndex[key];
    if (!r) {
      baskets.push({ key, usd });
      continue;
    }
    const baseApr = r.baseApr ?? 0;
    const rewardApr = r.rewardApr ?? 0;
    const baseApy = r.baseApy ?? ( (1 + baseApr/365)**365 - 1 );
    const rewardApy = r.rewardApy ?? (rewardApr ? ((1 + rewardApr/365)**365 - 1) : 0);
    const grossApy = baseApy + rewardApy;
    const netApy = grossApy * (1 - feeShare);
    const dailyNetUsd = usd * netApy / 365;
    baskets.push({ key, usd, baseApr, rewardApr, grossApy, netApy, dailyNetUsd });
  }
  const totalGrossApy = totalUsd ? baskets.reduce((s,b)=> s + (b.grossApy ?? 0) * b.usd, 0) / totalUsd : 0;
  const totalNetApy = totalUsd ? baskets.reduce((s,b)=> s + (b.netApy ?? 0) * b.usd, 0) / totalUsd : 0;
  return {
    asOf: new Date().toISOString(),
    totalUsd,
    totalGrossApy,
    totalNetApy,
    baskets: baskets.sort((a,b)=> (b.usd||0)-(a.usd||0))
  };
}

// Persist snapshot (called after successful execute)
export async function recordAllocationSnapshot() {
  try {
    const summary = await allocationSummary();
    await db.query(`INSERT INTO allocation_history (as_of, total_usd, total_gross_apy, total_net_apy, baskets_json)
                    VALUES ($1,$2,$3,$4,$5)`, [
      summary.asOf,
      summary.totalUsd,
      summary.totalGrossApy,
      summary.totalNetApy,
      JSON.stringify(summary.baskets)
    ]);
  } catch (e) {
    console.warn('recordAllocationSnapshot failed', (e as any)?.message);
  }
}

export async function getAllocationHistory(limit = 200) {
  const q = await db.query<{
    as_of: Date; total_usd: string; total_gross_apy: number; total_net_apy: number; baskets_json: any;
  }>(`SELECT as_of, total_usd, total_gross_apy, total_net_apy, baskets_json FROM allocation_history ORDER BY as_of DESC LIMIT $1`, [limit]);
  return q.rows.map(r => ({
    asOf: r.as_of.toISOString(),
    totalUsd: Number(r.total_usd),
    totalGrossApy: r.total_gross_apy,
    totalNetApy: r.total_net_apy,
    baskets: r.baskets_json
  }));
}

// Parse lock share curve from env: e.g. "0:0.20,3w:0.35,26w:0.60,52w:0.80,104w:0.90"
export function loadLockShareCurve(): Array<{ weeks:number; share:number }> {
  const raw = process.env.LOCK_SHARE_CURVE || '0:0.20,3w:0.35,26w:0.60,52w:0.80,104w:0.90';
  return raw.split(',').map(p=>p.trim()).filter(Boolean).map(seg => {
    const [wStr, sStr] = seg.split(':').map(x=>x.trim());
    let weeks = 0;
    if (/w$/i.test(wStr)) weeks = Number(wStr.slice(0,-1)); else weeks = Number(wStr);
    const share = Number(sStr);
    return { weeks: Number.isFinite(weeks)? weeks:0, share: Number.isFinite(share)? share:0 };
  }).sort((a,b)=> a.weeks - b.weeks);
}
