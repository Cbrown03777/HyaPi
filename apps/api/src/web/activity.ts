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
           le.id AS _le_id,
           le.created_at::text                                    AS "createdAt",
           UPPER((le.kind)::text)                                  AS "kind",
           CASE (le.kind)::text
             WHEN 'deposit'  THEN 'Deposit'
             WHEN 'withdraw' THEN 'Redemption'
             ELSE INITCAP((le.kind)::text)
           END                                                     AS "kindLabel",
           (CASE WHEN (le.kind)::text = 'withdraw' THEN -1 ELSE 1 END) * COALESCE(le.amount, pp.amount_pi) AS "amountPi",
           LOWER(pp.status)                                        AS "status",
           COALESCE(le.meta->>'txid', pp.txid)                     AS "txid",
           COALESCE(le.idem_key, le.meta->>'paymentId', pp.pi_payment_id) AS "paymentId",
           COALESCE(
             NULLIF(le.meta->>'lockupWeeks','')::int,
             NULLIF(pp.payload->'metadata'->>'lockupWeeks','')::int,
             pp.lockup_weeks,
             0
           )                                                       AS "lockupWeeks",
           COALESCE(le.meta->>'memo', pp.memo, 'HyaPi stake deposit') AS "memo",
           le.meta                                                 AS "meta"
         FROM liquidity_events le
         JOIN pi_payments pp ON COALESCE(le.idem_key, le.meta->>'paymentId') = pp.pi_payment_id
         JOIN users u ON u.pi_uid = pp.uid
        WHERE u.id = $1
        ORDER BY le.created_at DESC
        LIMIT $2`,
        [user.userId, N]
      );

      const raw = q.rows as any[];
      const items = raw.map(r => {
        const shortTx = r.txid ? `${String(r.txid).slice(0,8)}…` : undefined;
        const details = `Lockup: ${Number(r.lockupWeeks ?? 0) || 0} weeks` + (shortTx ? ` • Tx: ${shortTx}` : '');
        const typeLabel = r.kindLabel;
        return { ...r, details, typeLabel };
      });

      // Optional: server-side backfill for older rows missing meta keys (idempotent)
      for (const r of items) {
        const needsPatch = !r.paymentId || !r.txid || (r.lockupWeeks == null);
        if (needsPatch && r._le_id) {
          try {
            await db.query(
              `UPDATE liquidity_events
                 SET meta = COALESCE(meta, '{}'::jsonb) || jsonb_strip_nulls(
                              jsonb_build_object(
                                'paymentId', $2,
                                'txid', $3,
                                'lockupWeeks', $4
                              )
                            )
               WHERE id = $1`,
              [r._le_id, r.paymentId || null, r.txid || null, r.lockupWeeks ?? 0]
            );
          } catch {}
        }
      }

      if (process.env.NODE_ENV !== 'production') {
        console.log('[activity][sample]', items.slice(0, 2));
      }

      res.json({ success: true, data: { items } });
  } catch (e: any) {
    console.error('activity.recent error', e);
    res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: e.message } });
  }
});
