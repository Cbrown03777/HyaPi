import { Router } from 'express';
import { db } from '../services/db';
import { bufferTargets, maybeRouteExcessBuffer, planTopUpBuffer } from '../services/buffer';
import { updateHoldings, recordAllocationSnapshot } from '../services/alloc';

export const allocCurrentRouter = Router();

allocCurrentRouter.get('/current', async (_req, res) => {
  try {
    // Buffer row (singleton)
    const buf = await db.query<{ buffer_usd: string; updated_at: Date }>(`SELECT buffer_usd, updated_at FROM tvl_buffer WHERE id=1`);
    const bufferUsd = Number(buf.rows[0]?.buffer_usd ?? 0);

    // Current venue holdings (authoritative executed holdings)
    const vh = await db.query<{ key: string; usd_notional: string }>(
      `SELECT key, usd_notional FROM venue_holdings ORDER BY key`
    );

    // Active targets (take latest row per key per precedence: override -> gov). We mirror loadActiveTargets logic lightly.
    const targetsQ = await db.query<{ key: string; weight_fraction: string; source: string; applied_at: Date; expires_at: Date | null }>(
      `SELECT key, weight_fraction, source, applied_at, expires_at
       FROM allocation_targets
       WHERE (source='override' AND (expires_at IS NULL OR expires_at > now()))
          OR source='gov'
       ORDER BY source='override' DESC, applied_at DESC`
    );

    const targets: Map<string, number> = new Map();
    const targetSourcePerKey: Map<string, string> = new Map();
    for (const r of targetsQ.rows) {
      if (!targets.has(r.key)) {
        targets.set(r.key, Number(r.weight_fraction));
        targetSourcePerKey.set(r.key, r.source);
      }
    }
    // Normalize weights to 1
    const totalTarget = Array.from(targets.values()).reduce((s,v)=>s+v,0) || 0;
    if (totalTarget > 0) {
      for (const k of Array.from(targets.keys())) {
        targets.set(k, (targets.get(k)!)/totalTarget);
      }
    }

    const deployed = vh.rows.reduce((s, r) => s + Number(r.usd_notional), 0);
    const total = deployed + bufferUsd;

    // Limit to 3 venues for display: choose by highest target weight; fallback to deployed usd
    const topKeys = Array.from(targets.entries()).sort((a,b)=> b[1]-a[1]).slice(0,3).map(([k])=>k);
    let rows = vh.rows.filter(r=> topKeys.includes(r.key));
    if (rows.length < 3) {
      const missing = new Set(rows.map(r=>r.key));
      const fallback = vh.rows.filter(r=> !missing.has(r.key)).sort((a,b)=> Number(b.usd_notional)-Number(a.usd_notional));
      for (const r of fallback) { if (rows.length>=3) break; rows.push(r); }
    }
    const venues = rows.map(r => {
      const usd = Number(r.usd_notional);
      const weightActual = deployed > 0 ? usd / deployed : 0; // compare only deployed vs target weights
      const weightTarget = targets.get(r.key) ?? 0;
      const driftBps = Math.round((weightActual - weightTarget) * 10_000);
      return {
        key: r.key,
        usd,
        weightActual,
        weightTarget,
        driftBps
      };
    });

  const maxDriftBps = venues.reduce((m, v) => Math.max(m, Math.abs(v.driftBps)), 0);
  const avgDriftBps = venues.length ? Math.round(venues.reduce((s, v) => s + Math.abs(v.driftBps), 0) / venues.length) : 0;
  const { target: bufferTarget, upper: bufferUpper, lower: bufferLower } = bufferTargets(total);
  const routeExcessEligible = bufferUsd > bufferUpper;
  const topUpEligible = bufferUsd < bufferLower;

    res.json({
      success: true,
      data: {
        totalUsd: total,
        bufferUsd,
        deployedUsd: deployed,
        drift: { maxDriftBps, avgDriftBps },
        venues,
        buffer: { target: bufferTarget, upper: bufferUpper, lower: bufferLower, routeExcessEligible, topUpEligible },
        activeTargetSource: totalTarget === 0 ? 'none' : (Array.from(targetSourcePerKey.values()).some(s=>s==='override') ? 'override' : 'gov')
      }
    });
  } catch (e: any) {
    res.status(500).json({ success: false, error: { code: 'SERVER', message: e.message } });
  }
});

// Route excess buffer (stub/placeholder)
allocCurrentRouter.post('/route-buffer', async (_req, res) => {
  try {
    const result = await maybeRouteExcessBuffer();
    res.json({ success:true, data: { result } });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});

// Top up buffer placeholder (would plan withdrawals to reach target)
allocCurrentRouter.post('/top-up-buffer', async (_req, res) => {
  try {
    const result = await planTopUpBuffer();
    res.json({ success:true, data: result });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});

// Admin: Rebalance current holdings to active targets (limit 3) and set buffer to target
allocCurrentRouter.post('/rebalance-to-targets', async (req, res) => {
  try {
    const user = (req as any).user;
    const allowList = (process.env.ALLOC_ALLOW_EXEC_IDS || '').split(',').map(s=>s.trim()).filter(Boolean);
    const isAdmin = user?.isDev || (user?.userId && allowList.includes(String(user.userId)));
    if (!isAdmin) return res.status(403).json({ success:false, error:{ code:'FORBIDDEN', message:'not authorized' }});

    // Load active targets (same precedence as GET /current)
    const targetsQ = await db.query<{ key: string; weight_fraction: string; source: string; applied_at: Date; expires_at: Date | null }>(
      `SELECT key, weight_fraction, source, applied_at, expires_at
         FROM allocation_targets
        WHERE (source='override' AND (expires_at IS NULL OR expires_at > now()))
           OR source='gov'
        ORDER BY source='override' DESC, applied_at DESC`
    );
    const weights: Map<string, number> = new Map();
    for (const r of targetsQ.rows) {
      if (!weights.has(r.key)) weights.set(r.key, Number(r.weight_fraction));
    }
    if (weights.size === 0) return res.status(400).json({ success:false, error:{ code:'NO_TARGETS', message:'no active targets' }});
    // Keep only top 3 by weight and renormalize
    const top3 = Array.from(weights.entries()).sort((a,b)=> b[1]-a[1]).slice(0,3);
    const topSum = top3.reduce((s, [,w])=> s + w, 0) || 1;
    const normTop = top3.map(([k,w])=> [k, w / topSum] as const);

    // Compute total and buffer target
    const bufQ = await db.query<{ buffer_usd:string }>(`SELECT buffer_usd FROM tvl_buffer WHERE id=1`);
    const bufferUsd = Number(bufQ.rows[0]?.buffer_usd ?? 0);
    const vh = await db.query<{ usd_notional:string }>(`SELECT usd_notional FROM venue_holdings`);
    const deployedUsd = vh.rows.reduce((s,r)=> s + Number(r.usd_notional), 0);
    const total = deployedUsd + bufferUsd;
    const { target } = bufferTargets(total);
    const toDeploy = Math.max(0, total - target);

    const nextHoldings: Record<string, number> = {};
    for (const [k,w] of normTop) nextHoldings[k] = toDeploy * w;

    // Apply atomically and set buffer to target
    await updateHoldings(nextHoldings);
    await db.query(`UPDATE tvl_buffer SET buffer_usd = $1, updated_at = now() WHERE id=1`, [target]);
  // Record a fresh snapshot so /v1/alloc/ema reflects new composition promptly
  try { await recordAllocationSnapshot(); } catch {}
    res.json({ success:true, data:{ toDeploy, bufferTarget: target, holdings: nextHoldings } });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});
