import { Router } from 'express';
import { db } from '../services/db';
import { bufferTargets } from '../services/buffer';

export const adminAllocatorRouter = Router();

// GET /v1/admin/allocator/summary
// Lightweight summary of TVL, buffer bands, and drift vs active targets
adminAllocatorRouter.get('/summary', async (_req, res) => {
  try {
    // Buffer row (singleton)
    const buf = await db.query<{ buffer_usd: string; updated_at: Date }>(`SELECT buffer_usd, updated_at FROM tvl_buffer WHERE id=1`);
    const bufferUsd = Number(buf.rows[0]?.buffer_usd ?? 0);

    // Current venue holdings (authoritative executed holdings)
    const vh = await db.query<{ key: string; usd_notional: string }>(
      `SELECT key, usd_notional FROM venue_holdings ORDER BY key`
    );

    // Active targets (latest per key; override takes precedence over gov)
    const targetsQ = await db.query<{ key: string; weight_fraction: string; source: string; applied_at: Date; expires_at: Date | null }>(
      `SELECT key, weight_fraction, source, applied_at, expires_at
       FROM allocation_targets
       WHERE (source='override' AND (expires_at IS NULL OR expires_at > now()))
          OR source='gov'
       ORDER BY source='override' DESC, applied_at DESC`
    );

    const weights: Map<string, number> = new Map();
    const sources: Map<string, string> = new Map();
    for (const r of targetsQ.rows) {
      if (!weights.has(r.key)) {
        weights.set(r.key, Number(r.weight_fraction));
        sources.set(r.key, r.source);
      }
    }
    const totalW = Array.from(weights.values()).reduce((s,v)=> s+v, 0) || 0;
    if (totalW > 0) for (const k of Array.from(weights.keys())) weights.set(k, (weights.get(k)!) / totalW);

    const deployedUsd = vh.rows.reduce((s, r) => s + Number(r.usd_notional), 0);
    const totalUsd = deployedUsd + bufferUsd;
    const { target, upper, lower } = bufferTargets(totalUsd);
    const routeExcessEligible = bufferUsd > upper;
    const topUpEligible = bufferUsd < lower;

    // 24h totals in Pi (prefer explicit Pi tables if available; fallback to liquidity_events USD / price)
    const price = Number(process.env.PI_USD_PRICE ?? '0.35') || 0.35;
    async function sumDepositsPi24h(): Promise<number> {
      try {
        const q = await db.query<{ sum: string }>(
          `SELECT COALESCE(SUM(amount_pi),0)::text AS sum FROM stakes WHERE created_at >= now() - interval '24 hours'`
        );
        return Number(q.rows[0]?.sum ?? '0');
      } catch {
        try {
          const q2 = await db.query<{ sum: string }>(
            `SELECT COALESCE(SUM(amount_usd),0)::text AS sum FROM liquidity_events WHERE kind='deposit' AND created_at >= now() - interval '24 hours'`
          );
          const usd = Number(q2.rows[0]?.sum ?? '0');
          return price>0 ? usd / price : 0;
        } catch { return 0; }
      }
    }
    async function sumWithdrawsPi24h(): Promise<number> {
      try {
        const q = await db.query<{ sum: string }>(
          `SELECT COALESCE(SUM(amount_pi),0)::text AS sum FROM redemptions WHERE created_at >= now() - interval '24 hours'`
        );
        return Number(q.rows[0]?.sum ?? '0');
      } catch {
        try {
          const q2 = await db.query<{ sum: string }>(
            `SELECT COALESCE(SUM(amount_usd),0)::text AS sum FROM liquidity_events WHERE kind='withdraw' AND created_at >= now() - interval '24 hours'`
          );
          const usd = Number(q2.rows[0]?.sum ?? '0');
          return price>0 ? usd / price : 0;
        } catch { return 0; }
      }
    }
    const [deposits24hPi, withdraws24hPi] = await Promise.all([sumDepositsPi24h(), sumWithdrawsPi24h()]);
    const net24hPi = deposits24hPi - withdraws24hPi;

    // Compute drift vs target for top holdings (limit 3 for UI)
    const holdingsTop = [...vh.rows].sort((a,b)=> Number(b.usd_notional) - Number(a.usd_notional)).slice(0,3);
    const venues = holdingsTop.map(r => {
      const usd = Number(r.usd_notional);
      const weightActual = deployedUsd > 0 ? usd / deployedUsd : 0; // compare only deployed vs target weights
      const weightTarget = weights.get(r.key) ?? 0;
      const driftBps = Math.round((weightActual - weightTarget) * 10_000);
      return { key: r.key, usd, weightActual, weightTarget, driftBps };
    });
    const maxDriftBps = venues.reduce((m, v) => Math.max(m, Math.abs(v.driftBps)), 0) || 0;
    const avgDriftBps = venues.length ? Math.round(venues.reduce((s, v) => s + Math.abs(v.driftBps), 0) / venues.length) : 0;
    const activeTargetSource = weights.size === 0 ? 'none' : (Array.from(sources.values()).some(s=>s==='override') ? 'override' : 'gov');

    res.json({
      success: true,
      data: {
        totalUsd,
        deployedUsd,
        bufferUsd,
        buffer: { target, upper, lower, routeExcessEligible, topUpEligible },
        drift: { maxDriftBps, avgDriftBps },
        venues,
        activeTargetSource,
        deposits24hPi,
        withdraws24hPi,
        net24hPi
      }
    });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message: e.message }});
  }
});

// POST /v1/admin/allocator/suggest
// Returns a simple suggestion for the next action to take, based on buffer bands and drift.
adminAllocatorRouter.post('/suggest', async (_req, res) => {
  try {
    const buf = await db.query<{ buffer_usd: string }>(`SELECT buffer_usd FROM tvl_buffer WHERE id=1`);
    const bufferUsd = Number(buf.rows[0]?.buffer_usd ?? 0);
    const vh = await db.query<{ key: string; usd_notional: string }>(`SELECT key, usd_notional FROM venue_holdings`);
    const deployedUsd = vh.rows.reduce((s, r) => s + Number(r.usd_notional), 0);
    const totalUsd = deployedUsd + bufferUsd;
  const { upper, lower, target } = bufferTargets(totalUsd);

    if (bufferUsd > upper) {
      return res.json({ success:true, data: { kind: 'route-excess-buffer', label: 'Route excess buffer', endpoint: '/v1/alloc/route-buffer', method: 'POST', rationale: 'Buffer is above upper band.' }});
    }
    if (bufferUsd < lower) {
      return res.json({ success:true, data: { kind: 'top-up-buffer', label: 'Top up buffer', endpoint: '/v1/alloc/top-up-buffer', method: 'POST', rationale: 'Buffer is below lower band.' }});
    }

    // Consider net 24h flows to guide deploy/meet suggestions even within band
    const price = Number(process.env.PI_USD_PRICE ?? '0.35') || 0.35;
    async function depositsPi24h(): Promise<number> {
      try {
        const q = await db.query<{ sum: string }>(`SELECT COALESCE(SUM(amount_pi),0)::text AS sum FROM stakes WHERE created_at >= now() - interval '24 hours'`);
        return Number(q.rows[0]?.sum ?? '0');
      } catch {
        try {
          const q2 = await db.query<{ sum: string }>(`SELECT COALESCE(SUM(amount_usd),0)::text AS sum FROM liquidity_events WHERE kind='deposit' AND created_at >= now() - interval '24 hours'`);
          return price>0 ? Number(q2.rows[0]?.sum ?? '0') / price : 0;
        } catch { return 0; }
      }
    }
    async function withdrawsPi24h(): Promise<number> {
      try {
        const q = await db.query<{ sum: string }>(`SELECT COALESCE(SUM(amount_pi),0)::text AS sum FROM redemptions WHERE created_at >= now() - interval '24 hours'`);
        return Number(q.rows[0]?.sum ?? '0');
      } catch {
        try {
          const q2 = await db.query<{ sum: string }>(`SELECT COALESCE(SUM(amount_usd),0)::text AS sum FROM liquidity_events WHERE kind='withdraw' AND created_at >= now() - interval '24 hours'`);
          return price>0 ? Number(q2.rows[0]?.sum ?? '0') / price : 0;
        } catch { return 0; }
      }
    }
    const [depPi, wdrPi] = await Promise.all([depositsPi24h(), withdrawsPi24h()]);
    const netPi = depPi - wdrPi;
    if (netPi > 0 && bufferUsd < target) {
      // Within band but new capital and buffer below target: quick rebalance to targets (will set buffer to target)
      return res.json({ success:true, data: { kind: 'rebalance-to-targets', label: 'Deploy to targets', endpoint: '/v1/alloc/rebalance-to-targets', method: 'POST', rationale: 'Net deposits in 24h and buffer below target.' }});
    }
    if (netPi < 0 && bufferUsd > target) {
      // Net withdrawals recently: ensure buffer at target for upcoming needs
      return res.json({ success:true, data: { kind: 'rebalance-to-targets', label: 'Rebalance vs targets', endpoint: '/v1/alloc/rebalance-to-targets', method: 'POST', rationale: 'Net withdrawals in 24h; align deployed weights and keep buffer at target.' }});
    }

    // Compute drift vs targets to decide whether a quick rebalance is advisable
    const targetsQ = await db.query<{ key: string; weight_fraction: string; source: string; applied_at: Date; expires_at: Date | null }>(
      `SELECT key, weight_fraction, source, applied_at, expires_at
         FROM allocation_targets
        WHERE (source='override' AND (expires_at IS NULL OR expires_at > now()))
           OR source='gov'
        ORDER BY source='override' DESC, applied_at DESC`
    );
    const weights: Map<string, number> = new Map();
    for (const r of targetsQ.rows) if (!weights.has(r.key)) weights.set(r.key, Number(r.weight_fraction));
    const sum = Array.from(weights.values()).reduce((s,v)=> s+v, 0) || 0;
    if (sum > 0) for (const k of Array.from(weights.keys())) weights.set(k, (weights.get(k)!) / sum);

    const topHoldings = [...vh.rows].sort((a,b)=> Number(b.usd_notional) - Number(a.usd_notional)).slice(0,3);
    const drifts = topHoldings.map(r => {
      const usd = Number(r.usd_notional);
      const weightActual = deployedUsd > 0 ? usd / deployedUsd : 0;
      const weightTarget = weights.get(r.key) ?? 0;
      return Math.abs(Math.round((weightActual - weightTarget) * 10_000));
    });
  const maxDriftBps = drifts.reduce((m,v)=> Math.max(m, v), 0);
    const DRIFT_THRESHOLD_BPS = Number(process.env.ALLOC_SUGGEST_DRIFT_BPS ?? 50);
    if (maxDriftBps >= DRIFT_THRESHOLD_BPS) {
      return res.json({ success:true, data: { kind: 'rebalance-to-targets', label: 'Rebalance to targets', endpoint: '/v1/alloc/rebalance-to-targets', method: 'POST', rationale: `Max drift ${maxDriftBps}bps exceeds threshold.` }});
    }

    return res.json({ success:true, data: { kind: 'none', label: 'No action needed', rationale: 'Buffer within band and drift below threshold.' }});
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message: e.message }});
  }
});
