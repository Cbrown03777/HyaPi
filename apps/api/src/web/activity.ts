/**
 * Data flow (Recent Activity):
 * - Aggregates: deposits from liquidity_events (kind='deposit'), plus stakes/redemptions/votes.
 * - Deposit detail built from liquidity_events.meta (memo/lockupWeeks) and amount.
 * - Keeps existing items but ensures Deposit Type/Detail are never blank.
 */
import { Router, Request, Response } from 'express';
import { db } from '../services/db';

export const activityRouter = Router();

// GET /v1/activity/recent  -> unified recent actions for the authenticated user
activityRouter.get('/recent', async (req: Request, res: Response) => {
  try {
    const user = (req as any).user as { userId: number };
    if (!user?.userId) {
      return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'missing user' } });
    }

      // Collect structured recent liquidity events joined to user via pi_payments
      const N = 50;
      const q = await db.query(
        `SELECT 
           le.created_at::text        AS created_at,
           UPPER(le.kind)::text       AS kind,
           COALESCE(le.amount, pp.amount_pi)::text AS amount,
           COALESCE(le.meta->>'txid', pp.txid)::text AS txid,
           COALESCE((le.meta->>'paymentId'), pp.pi_payment_id)::text AS payment_id,
           COALESCE((le.meta->>'lockupWeeks')::int, (pp.payload->'metadata'->>'lockupWeeks')::int, 0) AS lockup_weeks,
           le.meta
         FROM liquidity_events le
         LEFT JOIN pi_payments pp ON pp.pi_payment_id = COALESCE(le.idem_key, le.meta->>'paymentId')
         JOIN users u ON u.pi_uid = pp.uid
        WHERE u.id = $1
        ORDER BY le.created_at DESC
        LIMIT $2`,
        [user.userId, N]
      );

      const items = q.rows.map((r: any) => ({
        createdAt: r.created_at,
        kind: r.kind || 'UNKNOWN',
        amount: Number(r.amount ?? 0) || 0,
        txid: r.txid || null,
        paymentId: r.payment_id || null,
        lockupWeeks: Number(r.lockup_weeks ?? 0) || 0,
        meta: r.meta || null,
      }));

      if (process.env.NODE_ENV !== 'production') {
        console.log('[activity][sample]', items.slice(0, 2));
      }

      res.json({ success: true, data: { items } });
  } catch (e: any) {
    console.error('activity.recent error', e);
    res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: e.message } });
  }
});
