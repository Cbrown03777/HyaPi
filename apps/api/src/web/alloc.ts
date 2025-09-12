import { Router } from 'express';
import { z } from 'zod';
import { makePreview, savePlanAndMarkExecuted, allocationSummary, recordAllocationSnapshot, getAllocationHistory, loadLockShareCurve, updateHoldings, setOverrideTargets } from '../services/alloc';
import { db } from '../services/db';

// Schemas for new allocation planner contract (additive; does not break existing GET /preview)
const HoldingSchema = z.object({ key: z.string(), usd: z.number().nonnegative() });
const TargetSchema = z.object({ key: z.string(), weight: z.number().nonnegative() });
const GuardsOverrideSchema = z.object({
  maxSingleVenuePct: z.number().positive().max(1).optional(),
  maxNewPct: z.number().positive().max(1).optional(),
  minTicketUsd: z.number().positive().optional(),
  dustUsd: z.number().positive().optional()
}).partial();
const PreviewBodySchema = z.object({
  holdings: z.array(HoldingSchema).nonempty(),
  targets: z.array(TargetSchema).nonempty(),
  guards: GuardsOverrideSchema.optional()
});

export const allocRouter = Router();
export const allocGovPublicRouter = Router();

allocRouter.get('/preview', async (req, res) => {
  try {
    const tvlUSD = Number((req.query.tvlUSD as string) ?? '10000');
    const out = await makePreview(tvlUSD);
    res.json({ success: true, data: out });
  } catch (e: any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message: e.message }});
  }
});

// Current allocation summary (gross/net APY per holding basket)
allocRouter.get('/summary', async (req, res) => {
  try {
    const summary = await allocationSummary();
    res.json({ success:true, data: summary });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message: e.message }});
  }
});

// Admin: force a snapshot into allocation_history immediately
allocRouter.post('/snapshot', async (req, res) => {
  try {
    // Basic admin auth: allow if DEV token or if ALLOC_ALLOW_EXEC_IDS contains userId
    const user = (req as any).user;
    const allowList = (process.env.ALLOC_ALLOW_EXEC_IDS || '').split(',').map(s=>s.trim()).filter(Boolean);
    const isAdmin = user?.isDev || (user?.userId && allowList.includes(String(user.userId)));
    if (!isAdmin) return res.status(403).json({ success:false, error:{ code:'FORBIDDEN', message:'not authorized' }});

    // Compute summary and persist a snapshot
    const summary = await allocationSummary();
    await recordAllocationSnapshot();
    res.json({ success:true, data: { snapshot: summary } });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message: e.message }});
  }
});

// Historical snapshots
allocRouter.get('/history', async (req,res) => {
  try {
    const limit = Math.min(1000, Number(req.query.limit) || 200);
    const rows = await getAllocationHistory(limit);
    res.json({ success:true, data: rows });
  } catch (e:any) { res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }}); }
});

// Dynamic-interval EMA: derive median interval to compute ~7d span smoothing
allocRouter.get('/ema', async (req,res) => {
  try {
    const hist = await getAllocationHistory(1000);
    if (hist.length < 2) return res.json({ success:true, data:{ ema7:null, latest: hist[0]?.totalNetApy ?? null } });
    const chronological = [...hist].reverse(); // oldest -> newest
    // Collect deltas in seconds
    const deltas = [] as number[];
    for (let i=1;i<chronological.length;i++) {
      const prev = new Date(chronological[i-1].asOf).getTime();
      const cur = new Date(chronological[i].asOf).getTime();
      const ds = (cur - prev)/1000;
      if (ds > 5) deltas.push(ds); // ignore ultra-short anomalies
    }
    deltas.sort((a,b)=>a-b);
    const median = deltas.length? deltas[Math.floor(deltas.length/2)] : 3600; // fallback 1h
    const periodsPerDay = 86400 / median;
    const spanPeriods = Math.max(5, Math.round(periodsPerDay * 7)); // 7 days
    const k = 2 / (spanPeriods + 1);
    let ema = chronological[0].totalNetApy;
    for (let i=1;i<chronological.length;i++) {
      const v = chronological[i].totalNetApy;
      ema = v * k + ema * (1 - k);
    }
    res.json({ success:true, data:{ ema7: ema, latest: hist[0].totalNetApy, medianIntervalSec: median, periodsPerDay } });
  } catch (e:any) { res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }}); }
});

allocRouter.get('/lock-curve', (_req,res)=> {
  res.json({ success:true, data: loadLockShareCurve() });
});

// Enumerate permissible dynamic allocation target keys (derived from latest composite rates)
allocRouter.get('/keys', async (_req,res) => {
  try {
    // Reuse allocationSummary rate mapping indirectly by querying venue_rates recent rows OR call getCompositeRates
    const rows = await (await import('../services/gov')).getCompositeRates?.();
    const keys = new Set<string>();
    if (Array.isArray(rows)) {
      for (const r of rows) {
        const base = `${(r as any).venue}:${(r as any).market}`;
        keys.add(base);
        if ((r as any).chain) keys.add(`${(r as any).venue}:${(r as any).chain}:${(r as any).market}`);
      }
    }
    res.json({ success:true, data: Array.from(keys).sort() });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});

// Active precedence layer (override > gov) normalized weights + source + normalization sum
allocRouter.get('/active-targets', async (_req,res) => {
  try {
    // First attempt override
    const override = await db.query<{ key:string; weight_fraction:number; applied_at:Date }>(
      `SELECT key, weight_fraction, applied_at FROM allocation_targets
        WHERE source='override' AND (expires_at IS NULL OR expires_at > now())
        ORDER BY applied_at DESC`);
    const use = override.rows.length ? { rows: override.rows, source: 'override' as const } :
      await (async () => {
        const gov = await db.query<{ key:string; weight_fraction:number; applied_at:Date }>(
          `SELECT key, weight_fraction, applied_at FROM allocation_targets
             WHERE source='gov'
             ORDER BY applied_at DESC`);
        return { rows: gov.rows, source: gov.rows.length? 'gov' as const : 'legacy' as const };
      })();
    if (!use.rows.length) return res.json({ success:true, data:{ source: use.source, normalization:1, weights: {} } });
    // Retain first-seen value per key (latest applied_at ordering). Normalize.
    const latest: Record<string, number> = {};
    for (const r of use.rows) if (!(r.key in latest)) latest[r.key] = Number(r.weight_fraction);
    const sum = Object.values(latest).reduce((a,b)=>a+b,0) || 1;
    const norm: Record<string, number> = {};
    for (const k of Object.keys(latest)) norm[k] = latest[k] / sum;
    res.json({ success:true, data:{ source: use.source, normalization: sum, weights: norm } });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});

// Governance-approved allocation history (dynamic keys) – PUBLIC mirror
async function handleGovHistory(req: any, res: any) {
  try {
    const limit = Math.min(500, Number(req.query.limit)||100);
    const proposalId = req.query.proposalId ? String(req.query.proposalId) : null;
    const sinceRaw = req.query.since ? String(req.query.since) : null;
    let since: Date | null = null;
    if (sinceRaw) {
      const d = new Date(sinceRaw);
      if (!isNaN(d.getTime())) since = d; else return res.status(400).json({ success:false, error:{ code:'BAD_SINCE', message:'invalid since timestamp' }});
    }
    const clauses: string[] = [];
    const params: any[] = [];
    if (proposalId) { clauses.push(`proposal_id = $${params.length+1}`); params.push(proposalId); }
    if (since) { clauses.push(`applied_at >= $${params.length+1}`); params.push(since); }
    const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
    params.push(limit);
    const sql = `SELECT proposal_id, key, weight_fraction, applied_at, normalization
                   FROM gov_allocation_history
                   ${where}
                   ORDER BY applied_at DESC, id DESC
                   LIMIT $${params.length}`;
    const rows = await db.query<{ proposal_id:string; key:string; weight_fraction:string; applied_at:Date; normalization:string|null }>(sql, params);
    if (rows.rowCount === 0 && !proposalId && !since) {
      // Fallback: synthesize a single snapshot.
      // Attempt precedence: active targets (override -> gov). If none, synthesize from current holdings.
      const use = await (async () => {
        const ov = await db.query<{ key:string; weight_fraction:string; applied_at:Date }>(
          `SELECT key, weight_fraction, applied_at
             FROM allocation_targets
            WHERE source='override' AND (expires_at IS NULL OR expires_at > now())
            ORDER BY applied_at DESC`
        );
        if (ov.rowCount) return { kind:'targets' as const, rows: ov.rows, source: 'override' as const };
        const gv = await db.query<{ key:string; weight_fraction:string; applied_at:Date }>(
          `SELECT key, weight_fraction, applied_at
             FROM allocation_targets
            WHERE source='gov'
            ORDER BY applied_at DESC`
        );
        if (gv.rowCount) return { kind:'targets' as const, rows: gv.rows, source: 'gov' as const };
        // No targets exist – use current holdings snapshot
        const vh = await db.query<{ key:string; usd_notional:string }>(`SELECT key, usd_notional FROM venue_holdings`);
        const total = vh.rows.reduce((s,r)=> s + Number(r.usd_notional), 0);
        const nowIso = new Date().toISOString();
        const data = vh.rows.map(r => ({ proposalId: 'holdings', key: r.key, weight: Number(r.usd_notional), appliedAt: nowIso, normalization: Math.max(1, total) }));
        return { kind:'holdings' as const, data };
      })();

      if (use.kind === 'holdings') {
        return res.json({ success:true, data: use.data, meta:{ fallback:'holdings' } });
      } else {
        const latest: Record<string, { weight:number; appliedAt: Date }> = {};
        for (const r of use.rows) {
          if (!(r.key in latest)) latest[r.key] = { weight: Number(r.weight_fraction), appliedAt: r.applied_at };
        }
        const normSum = Object.values(latest).reduce((s,v)=> s + v.weight, 0) || 1;
        const data = Object.entries(latest).map(([key, v]) => ({
          proposalId: use.source === 'override' ? 'override' : 'active',
          key,
          weight: v.weight,
          appliedAt: v.appliedAt.toISOString(),
          normalization: normSum
        }));
        return res.json({ success:true, data, meta:{ fallback:'active-targets', source: use.source } });
      }
    }
    res.json({ success:true, data: rows.rows.map(r=>({
      proposalId: r.proposal_id,
      key: r.key,
      weight: Number(r.weight_fraction),
      appliedAt: r.applied_at.toISOString(),
      normalization: r.normalization ? Number(r.normalization) : 1
    })) });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
}
allocGovPublicRouter.get('/gov-history', handleGovHistory);
allocRouter.get('/gov-history', handleGovHistory);

// Clear override targets (admin only)
allocRouter.post('/override/clear', async (req,res) => {
  try {
    const user = (req as any).user;
    const allowList = (process.env.ALLOC_ALLOW_EXEC_IDS || '').split(',').map(s=>s.trim()).filter(Boolean);
    const isAdmin = user?.isDev || (user?.userId && allowList.includes(String(user.userId)));
    if (!isAdmin) return res.status(403).json({ success:false, error:{ code:'FORBIDDEN', message:'not authorized' }});
    await db.query(`DELETE FROM allocation_targets WHERE source='override'` as any);
    res.json({ success:true, data:{ cleared:true }});
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});

// New POST /preview (additive API) allowing custom holdings/targets/guards
allocRouter.post('/preview', async (req, res) => {
  try {
    const body = PreviewBodySchema.parse(req.body);
    // server-side hard limits mirroring frontend guard rails
    if (body.holdings.length > 3 || body.targets.length > 3) {
      return res.status(400).json({ success:false, error:{ code:'LIMIT', message:'max 3 holdings and 3 targets' }});
    }
    // duplicate key check only within each list independently (targets can mirror holdings)
    const seenHoldings = new Set<string>();
    for (const h of body.holdings) {
      if (!h.key) continue;
      if (seenHoldings.has(h.key)) return res.status(400).json({ success:false, error:{ code:'DUPLICATE_KEYS', message:'duplicate key in holdings list' }});
      seenHoldings.add(h.key);
    }
    const seenTargets = new Set<string>();
    for (const t of body.targets) {
      if (!t.key) continue;
      if (seenTargets.has(t.key)) return res.status(400).json({ success:false, error:{ code:'DUPLICATE_KEYS', message:'duplicate key in targets list' }});
      seenTargets.add(t.key);
    }
    const totalUsd = body.holdings.reduce((a,b)=>a + b.usd, 0);
    const weightsByKey: Record<string, number> = {};
    for (const t of body.targets) weightsByKey[t.key] = t.weight;
    const sumWeights = Object.values(weightsByKey).reduce((a,b)=>a+b,0);
    const guards = body.guards || {};
    const actions: { kind:'increase'|'decrease'|'buffer'; key?:string; usd:number }[] = [];
    const maxSingle = guards.maxSingleVenuePct ? guards.maxSingleVenuePct * totalUsd : undefined;
    const maxNew = guards.maxNewPct ? guards.maxNewPct * totalUsd : undefined;
    const minTicket = guards.minTicketUsd ?? 0;
    const dust = guards.dustUsd ?? 0;
    // map current holdings
    const cur: Record<string, number> = {};
    for (const h of body.holdings) cur[h.key] = (cur[h.key] ?? 0) + h.usd;
    const allKeys = new Set([...Object.keys(cur), ...Object.keys(weightsByKey)]);
    for (const k of allKeys) {
      const current = cur[k] ?? 0;
      const desired = (weightsByKey[k] ?? 0) * totalUsd;
      let delta = desired - current; // positive => increase
      if (delta > 0 && typeof maxSingle === 'number') {
        const capRemaining = Math.max(0, maxSingle - current);
        delta = Math.min(delta, capRemaining);
      }
      if (delta > 0 && typeof maxNew === 'number') delta = Math.min(delta, maxNew);
      if (Math.abs(delta) < minTicket) continue;
      const abs = Math.abs(delta);
      if (abs < dust) continue;
      if (abs > 0) actions.push({ kind: delta >= 0 ? 'increase':'decrease', key: k, usd: abs });
    }
    // Buffer: leftover weight (if weights sum < 1)
    if (sumWeights < 0.999 && totalUsd > 0) {
      const bufPct = 1 - sumWeights;
      const bufUsd = bufPct * totalUsd;
      if (bufUsd >= (guards.minTicketUsd ?? 0)) actions.push({ kind:'buffer', usd: bufUsd });
    }
    return res.json({ success:true, data:{ guards: body.guards ?? {}, actions } });
  } catch (e:any) {
    if (e?.issues) return res.status(400).json({ success:false, error:{ code:'VALIDATION', message:'invalid body' }});
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});

const ExecSchema = z.object({ tvlUSD: z.number().positive() });
const ExecuteBodySchema = PreviewBodySchema; // same shape when using advanced execute

allocRouter.post('/execute', async (req, res) => {
  try {
  // Basic admin auth: allow if DEV token or if ALLOC_ALLOW_EXEC_IDS contains userId
  const user = (req as any).user;
  const allowList = (process.env.ALLOC_ALLOW_EXEC_IDS || '').split(',').map(s=>s.trim()).filter(Boolean);
  const isAdmin = user?.isDev || (user?.userId && allowList.includes(String(user.userId)));
  if (!isAdmin) return res.status(403).json({ success:false, error:{ code:'FORBIDDEN', message:'not authorized' }});
    // Dual-mode: if body has holdings/targets treat as advanced execute; else legacy path (tvlUSD)
    if (req.body && Array.isArray(req.body.holdings) && Array.isArray(req.body.targets)) {
      const body = ExecuteBodySchema.parse(req.body);
      if (body.holdings.length > 3 || body.targets.length > 3) {
        return res.status(400).json({ success:false, error:{ code:'LIMIT', message:'max 3 holdings and 3 targets' }});
      }
      const seenHoldings = new Set<string>();
      for (const h of body.holdings) {
        if (!h.key) continue;
        if (seenHoldings.has(h.key)) return res.status(400).json({ success:false, error:{ code:'DUPLICATE_KEYS', message:'duplicate key in holdings list' }});
        seenHoldings.add(h.key);
      }
      const seenTargets = new Set<string>();
      for (const t of body.targets) {
        if (!t.key) continue;
        if (seenTargets.has(t.key)) return res.status(400).json({ success:false, error:{ code:'DUPLICATE_KEYS', message:'duplicate key in targets list' }});
        seenTargets.add(t.key);
      }
      // Reuse preview logic inline (duplicate minimal logic to avoid cross-call overhead)
      const totalUsd = body.holdings.reduce((a,b)=>a + b.usd, 0);
      const weightsByKey: Record<string, number> = {};
      for (const t of body.targets) weightsByKey[t.key] = t.weight;
      const guards = body.guards || {};
      const actions: { kind:'increase'|'decrease'|'buffer'; key?:string; usd:number }[] = [];
      const maxSingle = guards.maxSingleVenuePct ? guards.maxSingleVenuePct * totalUsd : undefined;
      const maxNew = guards.maxNewPct ? guards.maxNewPct * totalUsd : undefined;
      const minTicket = guards.minTicketUsd ?? 0;
      const dust = guards.dustUsd ?? 0;
      const cur: Record<string, number> = {};
      for (const h of body.holdings) cur[h.key] = (cur[h.key] ?? 0) + h.usd;
      const allKeys = new Set([...Object.keys(cur), ...Object.keys(weightsByKey)]);
      for (const k of allKeys) {
        const current = cur[k] ?? 0;
        let desired = (weightsByKey[k] ?? 0) * totalUsd;
        if (typeof maxSingle === 'number') desired = Math.min(desired, maxSingle);
        let delta = desired - current;
        if (delta > 0 && typeof maxNew === 'number') delta = Math.min(delta, maxNew);
        if (Math.abs(delta) < minTicket) continue;
        const abs = Math.abs(delta);
        if (abs < dust) continue;
        if (abs > 0) actions.push({ kind: delta >= 0 ? 'increase':'decrease', key: k, usd: abs });
      }
      const syntheticPlan = {
        bufferUSD: 0,
        actions: actions.map(a=>({ kind:a.kind, key:a.key, deltaUSD:a.usd })),
        totalDeltaUSD: actions.reduce((s,a)=>s+a.usd,0),
        driftBps: 0
      };
      const resolvedGuards = { lambda:0, softmaxK:0, bufferBps:0, minTradeUSD:0, maxVenueBps:{ aave:10000, justlend:10000, stride:10000 }, maxDriftBps:0, cooldownSec:0, allowVenue:{ aave:true, justlend:true, stride:true }, staleRateMaxSec:3600 };
      const id = await savePlanAndMarkExecuted({ plan: syntheticPlan, targets: weightsByKey, guards: resolvedGuards, gov:{}, rates:[], });
      // Compute final target holdings (authoritative) based on totalUsd and weights.
      try {
        const finalHoldings: Record<string, number> = {};
        if (totalUsd > 0) {
          for (const [k,w] of Object.entries(weightsByKey)) {
            finalHoldings[k] = w * totalUsd;
          }
        }
        await updateHoldings(finalHoldings);
        // Persist override targets (no expiry by default)
        await setOverrideTargets(weightsByKey, null);
      } catch (e) {
        console.warn('updateHoldings failed (non-fatal)', (e as any)?.message);
      }
      await recordAllocationSnapshot();
      return res.json({ success:true, data:{ totalUsd, orders: actions, plan_id: id } });
    } else {
      const parsed = ExecSchema.parse(req.body);
      const preview = await makePreview(parsed.tvlUSD);
      const id = await savePlanAndMarkExecuted(preview);
  await recordAllocationSnapshot();
      res.json({ success:true, data:{ plan_id: id, actions: (preview as any).plan.actions } });
    }
  } catch (e: any) {
    if (e?.issues) return res.status(400).json({ success:false, error:{ code:'VALIDATION', message:'invalid body' }});
    res.status(500).json({ success:false, error:{ code:'SERVER', message: e.message }});
  }
});
