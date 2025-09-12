import { Router, Request, Response } from 'express';
import type { PoolClient } from 'pg';
import { db, withTx } from '../services/db';

export const finalizeRouter = Router();

/**
 * POST /v1/gov/proposals/:id/finalize
 * - Marks proposal as finalized
 * - Computes quorum + pass/fail from tallies
 * - Stores total_votes_power, quorum_met, passed, status='finalized'
 * Notes:
 * - Uses balances sum to estimate total supply for quorum (MVP).
 * - Quorum = 10% of total supply (1e18-scaled) by default (MVP).
 * - You can tweak to pull from gov_params later.
 */
finalizeRouter.post('/:id/finalize', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const force = (req.query.force as string) === '1';

    // Load proposal
    const p = await db.query<{
      id: string;
      status: string;
      end_ts: string;
    }>(`SELECT id, status, end_ts FROM gov_proposals WHERE id = $1`, [id]);

    const prop = p.rows[0];
    if (!prop) {
      return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'proposal not found' } });
    }

    // Must be active and voting window ended (unless force=1)
    const now = new Date();
    const end = new Date(prop.end_ts);
    if (prop.status !== 'active') {
      return res.status(409).json({ success: false, error: { code: 'BAD_STATE', message: `cannot finalize from status ${prop.status}` } });
    }
    if (!force && now < end) {
      return res.status(409).json({ success: false, error: { code: 'EARLY', message: 'voting window not ended' } });
    }

    // Current tallies (NUMERIC(78,0))
    const t = await db.query<{
      for_power: string | null;
      against_power: string | null;
      abstain_power: string | null;
    }>(
      `SELECT for_power, against_power, abstain_power
       FROM gov_tallies WHERE proposal_id=$1`,
      [id]
    );
    const forPower     = BigInt(t.rows[0]?.for_power     ?? '0');
    const againstPower = BigInt(t.rows[0]?.against_power ?? '0');
    const abstainPower = BigInt(t.rows[0]?.abstain_power ?? '0');
    const totalVotes   = forPower + againstPower + abstainPower;

    // Total supply from balances (convert to 1e18 scale)
    const s = await db.query<{ total: string | null }>(
      `SELECT COALESCE(SUM(hyapi_amount), 0)::text AS total FROM balances`
    );
    const totalSupplyTokens = Number(s.rows[0]?.total ?? '0'); // in whole tokens
    // 1e18 scaling to match voting_power units
    const totalSupplyE18 = BigInt(Math.floor(totalSupplyTokens * 1e18));

    // Quorum = 10% of supply (MVP)
    const quorumDenomBps = 1000n; // 10% = 1000 bps
    const quorumThreshold = (totalSupplyE18 * quorumDenomBps) / 10000n;
    const quorumMet = totalVotes >= quorumThreshold;

    // Pass rule (MVP): for > against AND quorum met (ties fail)
    const passed = quorumMet && (forPower > againstPower);

    // Persist in a transaction
    const out = await withTx(async (tx: PoolClient) => {
      const upd = await tx.query(
        `UPDATE gov_proposals
           SET quorum_met = $2,
               passed = $3,
               total_votes_power = $4,
               status = 'finalized',
               updated_at = now()
         WHERE id = $1
         RETURNING id, quorum_met, passed, total_votes_power, status`,
        [id, quorumMet, passed, totalVotes.toString()]
      );
      return upd.rows[0];
    });



    const body = {
      success: true,
      data: {
        proposal_id: out.id,
        status: out.status,
        quorum_met: out.quorum_met,
        passed: out.passed,
        total_votes_power: out.total_votes_power,
        tallies: {
          for_power: forPower.toString(),
          against_power: againstPower.toString(),
          abstain_power: abstainPower.toString()
        },
        quorum_threshold: quorumThreshold.toString()
      }
    };
    await (res as any).saveIdem?.(body);
    res.json(body);
  } catch (e: any) {
    console.error('proposals.finalize error:', e);
    res.status(500).json({ success: false, error: { code: 'SERVER', message: e.message } });
  }
});
