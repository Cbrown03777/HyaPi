import { Router, Request, Response } from 'express';
import { db } from '../services/db';
import { aave, justlend, stride } from '../../../../packages/venues/dist';
type Rate = { venue?: string; baseApr?: number; rewardsApr?: number; feeBps?: number; market?: string };

export const portfolioRouter = Router(); // <-- NAMED export

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
    res.json({
      success: true,
      data: {
        hyapi_amount: row.hyapi_amount,
        pps_1e18: row.pps_1e18,
        effective_pi_value: row.effective_pi_value,
  pps_series: ppsSeries.rows,
  has_locked_active: (locked.rows?.[0]?.cnt ?? 0) > 0,
  early_exit_fee_bps: (locked.rows?.[0]?.cnt ?? 0) > 0 ? 100 : 0
      }
    });
  } catch (e:any) {
    console.error('portfolio error', e);
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});

// Simple KPI metrics for the landing page
portfolioRouter.get('/metrics', async (_req: Request, res: Response) => {
  try {
    // TVA: sum effective_pi_value across users
    const tva = await db.query(`SELECT COALESCE(SUM(effective_pi_value),0)::numeric(38,6) AS tva_pi FROM v_user_portfolio`);

    // 24h payouts: sum credits in last 24h; fallback to 0 if table missing
    let payouts24hUsd = 0;
    try {
      const r = await db.query(`SELECT COALESCE(SUM(amount_usd),0)::numeric AS usd FROM credits WHERE created_at >= now() - interval '24 hours'`);
      payouts24hUsd = Number(r.rows?.[0]?.usd ?? 0);
    } catch {}

    // Participants: distinct users with any active stake
    let users = 0;
    try {
      const r = await db.query(`SELECT COUNT(DISTINCT user_id)::int AS users FROM stakes WHERE status='active'`);
      users = Number(r.rows?.[0]?.users ?? 0);
    } catch {}

    // Live Net APR (weighted) — optional placeholder: average of top 3 allowlist venues
    let liveNetApr: number | null = null;
    try {
      const allow = new Set(['aave:USDT','justlend:USDT','stride:stATOM']);
      const all = await Promise.allSettled([
        aave.getLiveRates(['USDT','USDC']).then(r=>r.map(x=>({ ...x, venue:'aave' } as Rate))),
        justlend.getLiveRates(['USDT','USDD']).then(r=>r.map(x=>({ ...x, venue:'justlend' } as Rate))),
        stride.getLiveRates(['stATOM']).then(r=>r.map(x=>({ ...x, venue:'stride' } as Rate))),
      ]);
      const merged: Rate[] = [];
      all.forEach((p:any)=>{ if(p.status==='fulfilled') merged.push(...p.value); });
      const top = merged
        .map(r => ({ key: `${(r.venue||'').toLowerCase()}:${(r.market||'').toUpperCase()}`, r }))
        .filter(x => allow.has(x.key))
        .slice(0,3);
      const net = (r: Rate) => (r.baseApr ?? 0) + (r.rewardsApr ?? 0) - ((r.feeBps ?? 0)/1e4);
      if (top.length) liveNetApr = top.reduce((s, x) => s + net(x.r), 0) / top.length;
    } catch {}

    // Convert TVA Pi to USD if we have a price; otherwise return null
    let tvaUsd: number | null = null;
    try {
      const price = Number(process.env.PI_USD_PRICE ?? '0');
      if (price > 0) tvaUsd = Number(tva.rows?.[0]?.tva_pi ?? 0) * price;
    } catch {}

    res.json({ success: true, data: { tvaUsd, payouts24hUsd, users, liveNetApr } });
  } catch (e: any) {
    console.error('portfolio.metrics error', e);
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});