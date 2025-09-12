import { Router, Request, Response } from 'express';
import { db } from '../services/db';

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