/**
 * Data flow (Portfolio):
 * - hyapi_amount sourced from v_user_portfolio (fed by balances table credit on /pi/complete).
 * - prices from @hyapi/prices; lock status from stakes.
 * - This ensures deposits reflect immediately on the Portfolio page post-completion.
 */
import { Router, Request, Response } from 'express';
import { db } from '../services/db';
import { getPrices, type SupportedSymbol } from '@hyapi/prices';
import { getPortfolioMetrics } from '../services/metrics';
import { getNavSeries } from '../services/navHistory';
import { calcApy } from '../services/apy';
import { getChainMix } from '../services/allocation';
import type { AllocationMetrics } from '../types/nav';

export const portfolioRouter = Router(); // <-- NAMED export (auth-required)
export const portfolioPublicRouter = Router(); // <-- NAMED export (no auth)

portfolioRouter.get('/', async (req: Request, res: Response) => {
  try {
    const user = (req as any).user as { userId: number };
    if (!user?.userId) {
      return res.status(401).json({ success: false, error: { code:'UNAUTH', message:'missing user' }});
    }

    const [pView, ppsSeries, locked] = await Promise.all([
      db.query(`SELECT hyapi_amount::text, pps_1e18::text, effective_pi_value::text
                FROM v_user_portfolio WHERE user_id = $1`, [user.userId]),
      db.query(`SELECT as_of_date::text, pps_1e18::text FROM pps_series ORDER BY as_of_date ASC`),
      db.query(`SELECT COUNT(*)::int AS cnt
                  FROM stakes
                 WHERE user_id=$1 AND status='active' AND lockup_weeks > 0 AND unlock_ts > now()`,[user.userId])
    ]);

    const row = pView.rows[0] ?? { hyapi_amount: '0', pps_1e18: '1000000000000000000', effective_pi_value: '0' };

    // Prices integration (guarded by PRICES_ENABLED)
    let pricesBlock: any = { PI: 0, LUNA: 0, BAND: 0, JUNO: 0, ATOM: 0, TIA: 0, DAI: 0, lastUpdatedISO: new Date().toISOString(), degraded: true };
    if (process.env.PRICES_ENABLED !== 'false') {
      try {
        const wanted: SupportedSymbol[] = ['PI','LUNA','BAND','JUNO','ATOM','TIA','DAI'];
        const { prices, asOf, degraded } = await getPrices(wanted);
        pricesBlock = { ...prices, lastUpdatedISO: asOf, degraded };
      } catch {
        // Keep degraded zeros on failure
      }
    }
    res.json({
      success: true,
      data: {
        hyapi_amount: row.hyapi_amount,
        pps_1e18: row.pps_1e18,
  effective_pi_value: row.effective_pi_value,
  prices: pricesBlock,
  pps_series: ppsSeries.rows,
  has_locked_active: (locked.rows?.[0]?.cnt ?? 0) > 0,
  early_exit_fee_bps: (locked.rows?.[0]?.cnt ?? 0) > 0 ? 100 : 0,
  balances: { hyapi: Number(row.hyapi_amount ?? '0') }
      }
    });
  } catch (e:any) {
    console.error('portfolio error', e);
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});

// Public metrics endpoint; do not 500.
portfolioPublicRouter.get('/metrics', async (_req: Request, res: Response) => {
  try {
    const { ok, data, status } = await getPortfolioMetrics();
    if (!ok || !data) {
      return res.status(status ?? 503).json({ success: false, error: { code: 'METRICS_UNAVAILABLE' } });
    }
    return res.json({ success: true, data });
  } catch (e:any) {
    console.error('metrics error', e?.message);
    return res.status(503).json({ success:false, error:{ code:'METRICS_UNAVAILABLE' }});
  }
});

// Public allocation + APY endpoint (non-fatal; never 500) GET /v1/portfolio/allocation
portfolioPublicRouter.get('/allocation', async (_req: Request, res: Response) => {
  const degraded = { success: true, data: { pps: 1, apy7d: 0, lifetimeGrowth: 0, chainMix: [], ppsSeries: [], degraded: true } };
  try {
    const series = await getNavSeries(30);
    if (!series.length) {
      return res.json(degraded);
    }
    let apy7d = 0, lifetimeGrowth = 0;
    try {
      const apyStats = calcApy(series);
      apy7d = apyStats.apy7d;
      lifetimeGrowth = apyStats.lifetimeGrowth;
    } catch {}
    const chainMix = await getChainMix().catch(()=>[]);
    const data: AllocationMetrics & { degraded: boolean } = {
      pps: series[series.length-1].pps ?? 1,
      apy7d: Number.isFinite(apy7d) ? apy7d : 0,
      lifetimeGrowth: Number.isFinite(lifetimeGrowth) ? lifetimeGrowth : 0,
      chainMix: chainMix || [],
      ppsSeries: series,
      degraded: !chainMix?.length
    };
    return res.json({ success: true, data });
  } catch (e:any) {
    console.warn('allocation endpoint degraded', e?.message);
    return res.json(degraded);
  }
});