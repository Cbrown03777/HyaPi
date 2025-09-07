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

    // Collect last N rows from key ledgers and normalize client-side
    const N = 20;
    const { rows: stakes } = await db.query(
      `SELECT id, created_at, amount_pi, lockup_weeks
         FROM stakes WHERE user_id=$1
         ORDER BY created_at DESC
         LIMIT $2`,
      [user.userId, N]
    );
    const { rows: reds } = await db.query(
      `SELECT id, created_at, amount_pi, status, eta_ts
         FROM redemptions WHERE user_id=$1
         ORDER BY created_at DESC
         LIMIT $2`,
      [user.userId, N]
    );
    const { rows: votes } = await db.query(
      `SELECT proposal_id, support, voting_power, cast_at
         FROM gov_votes WHERE user_id=$1
         ORDER BY cast_at DESC
         LIMIT $2`,
      [user.userId, N]
    );

    const items = [
      ...stakes.map((s: any) => ({
        kind: 'stake',
        ts: s.created_at,
        title: `Staked ${s.amount_pi} Pi`,
        detail: `lock ${s.lockup_weeks}w`,
        id: `stake:${s.id}`,
        status: 'success',
      })),
      ...reds.map((r: any) => ({
        kind: 'redeem',
        ts: r.created_at,
        title: `Redeem ${r.amount_pi} Pi`,
        detail: r.status === 'paid' ? `paid` : r.eta_ts ? `ETA ${r.eta_ts}` : r.status,
        id: `red:${r.id}`,
        status: r.status === 'paid' ? 'success' : 'pending',
      })),
      ...votes.map((v: any) => ({
        kind: 'vote',
        ts: v.cast_at,
        title: `Voted ${v.support === 1 ? 'for' : v.support === 0 ? 'against' : 'abstain'}`,
        detail: `proposal ${v.proposal_id}`,
        id: `vote:${v.proposal_id}:${new Date(v.cast_at).getTime()}`,
        status: 'success',
      })),
    ]
      .sort((a, b) => new Date(b.ts).getTime() - new Date(a.ts).getTime())
      .slice(0, N);

    res.json({ success: true, data: { items } });
  } catch (e: any) {
    console.error('activity.recent error', e);
    res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: e.message } });
  }
});
