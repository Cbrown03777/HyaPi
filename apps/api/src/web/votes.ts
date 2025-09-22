// apps/api/src/web/votes.ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import type { PoolClient } from 'pg';
import { db, withTx } from '../services/db';
import { getBoostForUser } from '../gov/boost';

export const votesRouter = Router();

const BodySchema = z.object({
  support: z.enum(['for', 'against', 'abstain']),
});

// map string -> smallint codes used in DB (0=against, 1=for, 2=abstain)
const SUPPORT_CODE = {
  for: 1,
  against: 0,
  abstain: 2,
} as const;

votesRouter.post('/:id/votes', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const body = BodySchema.parse(req.body);

    const user = (req as any).user as { userId: number };
    if (!user?.userId) {
      return res
        .status(401)
        .json({ success: false, error: { code: 'UNAUTH', message: 'missing user' } });
    }

    // Ensure user has voting power
    const bal = await db.query<{ hyapi_amount: string }>(
      'SELECT hyapi_amount FROM balances WHERE user_id = $1',
      [user.userId],
    );
    const amount = Number(bal.rows[0]?.hyapi_amount ?? 0);
    if (!Number.isFinite(amount) || amount <= 0) {
      return res
        .status(400)
        .json({ success: false, error: { code: 'NO_POWER', message: 'no voting power' } });
    }

    // Base voting power from hyaPi balance
    let powerDecimal = amount; // base units
    // Apply boosted governance multiplier (does not affect APY)
    try {
      const boost = await getBoostForUser(String(user.userId));
      if (boost.active && boost.boostPct > 0) {
        powerDecimal = powerDecimal * (1 + boost.boostPct);
      }
    } catch {}
    // Scale to integer units (store in NUMERIC(78,0))
    const votingPower = BigInt(Math.floor(powerDecimal * 1e18)).toString();
    const supportCode = SUPPORT_CODE[body.support];

    await withTx(async (t: PoolClient) => {
      // Upsert vote (use smallint code + voting_power column)
      await t.query(
        `INSERT INTO gov_votes (proposal_id, user_id, support, voting_power)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (proposal_id, user_id)
         DO UPDATE SET support = EXCLUDED.support, voting_power = EXCLUDED.voting_power`,
        [id, user.userId, supportCode, votingPower],
      );

      // Recompute tallies by support code (sum voting_power)
      await t.query(
        `INSERT INTO gov_tallies (proposal_id, for_power, against_power, abstain_power)
         SELECT
           $1,
           COALESCE(SUM(CASE WHEN support = 1 THEN voting_power ELSE 0 END), 0),
           COALESCE(SUM(CASE WHEN support = 0 THEN voting_power ELSE 0 END), 0),
           COALESCE(SUM(CASE WHEN support = 2 THEN voting_power ELSE 0 END), 0)
         FROM gov_votes
         WHERE proposal_id = $1
         ON CONFLICT (proposal_id) DO UPDATE SET
           for_power = EXCLUDED.for_power,
           against_power = EXCLUDED.against_power,
           abstain_power = EXCLUDED.abstain_power`,
        [id],
      );
    });

    res.json({ success: true });
  } catch (e: any) {
    console.error('votes.create error:', e);
    res
      .status(400)
      .json({ success: false, error: { code: 'BAD_REQUEST', message: e.message } });
  }
});
