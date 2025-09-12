// apps/api/src/web/proposals.ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import type { PoolClient } from 'pg';
import { db, withTx } from '../services/db';
import { ensureSnapshot, hasProposerPower, scheduleWindow } from '../services/gov';

export const proposalsRouter = Router();

// ---------- Schemas ----------
const CreateSchema = z.object({
  title: z.string().min(3).max(140),
  description: z.string().optional(),
  allocation: z.array(z.object({ key: z.string().min(2).max(64), weight: z.number().min(0).max(1) })).min(1).max(16)
});

// ---------- GET /v1/gov/proposals ----------
proposalsRouter.get('/proposals', async (req: Request, res: Response) => {
  try {
    const status = (req.query.status as string) ?? 'active';
    const limit  = Number((req.query.limit as string) ?? '20');

    const q = await db.query<{
      proposal_id: string;
      title: string;
      status: string;
      start_ts: string;
      end_ts: string;
      allocation: Record<string, number> | null;
      for_power: string | null;
      against_power: string | null;
      abstain_power: string | null;
    }>(/* sql */`
      SELECT
        p.id AS proposal_id,
        p.title,
        p.status,
        p.start_ts,
        p.end_ts,
        jsonb_object_agg(a.key, a.weight_fraction)
          FILTER (WHERE a.key IS NOT NULL) AS allocation,
        t.for_power,
        t.against_power,
        t.abstain_power
      FROM gov_proposals p
      LEFT JOIN gov_proposal_allocations a ON a.proposal_id = p.id
      LEFT JOIN gov_tallies t ON t.proposal_id = p.id
      WHERE ($1::text IS NULL OR p.status = $1)
      GROUP BY p.id, t.for_power, t.against_power, t.abstain_power
      ORDER BY p.start_ts DESC
      LIMIT $2
    `, [status === 'past' ? null : status, limit]);

    const body = { success: true, data: q.rows };
    await (res as any).saveIdem?.(body);
    res.json(body);
  } catch (e: any) {
    console.error('proposals.list error:', e);
    res.status(500).json({ success: false, error: { code: 'SERVER', message: e.message } });
  }
});

// ---------- POST /v1/gov/proposals ----------
proposalsRouter.post('/proposals', async (req: Request, res: Response) => {
  try {
    const parsed = CreateSchema.parse(req.body);
    const sum = parsed.allocation.reduce((s,a)=>s + a.weight,0);
    if (Math.abs(sum - 1) > 1e-9) {
      return res.status(400).json({ success: false, error: { code: 'BAD_ALLOC', message: 'weights must sum to 1.0' } });
    }
    const seen = new Set<string>();
    for (const a of parsed.allocation) {
      if (seen.has(a.key)) return res.status(400).json({ success:false, error:{ code:'DUP_KEYS', message:`duplicate key ${a.key}` }});
      seen.add(a.key);
    }

    const user = (req as any).user as { userId: number };
    if (!user?.userId) {
      return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'missing user' } });
    }

    // Take a fresh snapshot and check proposer power at that snapshot
    const snap = await ensureSnapshot(); // { snapshot_id, total_supply }
    const ok   = await hasProposerPower(user.userId, Number(snap.snapshot_id));
    if (!ok) {
      return res.status(403).json({ success: false, error: { code: 'NO_POWER', message: 'insufficient proposer power' } });
    }

    const win = await scheduleWindow(); // { start_ts, end_ts }

    // Insert proposal + allocations in a transaction
    const pid = await withTx<string>(async (t: PoolClient) => {
      const ins = await t.query<{ id: string }>(/*sql*/`
        INSERT INTO gov_proposals(title, description, proposer_user_id, snapshot_id, start_ts, end_ts, status)
        VALUES ($1,$2,$3,$4,$5,$6,'active')
        RETURNING id
      `, [parsed.title, parsed.description ?? null, user.userId, snap.snapshot_id, win.start_ts, win.end_ts]);

      const proposalId = ins.rows[0].id;

      await t.query(`INSERT INTO gov_tallies(proposal_id) VALUES ($1) ON CONFLICT DO NOTHING`, [proposalId]);

      const values: any[] = [proposalId];
      const rows: string[] = [];
      parsed.allocation.forEach((a, i) => {
        // push key then weight so parameter order is (proposal_id, key, weight) repeating
        values.push(a.key, a.weight);
        // placeholder indexes: $1 is proposal_id, then pairs start at $2
        const keyIdx = 2 + i*2;
        const weightIdx = 3 + i*2;
        rows.push(`($1,$${keyIdx},$${weightIdx})`);
      });
      const sqlIns = `INSERT INTO gov_proposal_allocations(proposal_id, key, weight_fraction) VALUES ${rows.join(',')}`;
      await t.query(sqlIns, values);

      return String(proposalId);
    });

    const body = {
      success: true,
      data: {
        proposal_id: pid,
        snapshot_id: String(snap.snapshot_id),
        start_ts: win.start_ts,
        end_ts:   win.end_ts,
        status:   'active'
      }
    };
    await (res as any).saveIdem?.(body);
    res.json(body);
  } catch (e: any) {
    console.error('proposals.create error:', e);
    if (e?.issues) {
      return res.status(400).json({ success: false, error: { code: 'VALIDATION', message: 'invalid body', issues: e.issues } });
    }
    res.status(500).json({ success: false, error: { code: 'SERVER', message: e.message } });
  }
});

// ---------- GET /v1/gov/proposals/:id ----------
proposalsRouter.get('/proposals/:id', async (req: Request, res: Response) => {
   // Validate id is a positive integer
   const idNum = Number(req.params.id);
   if (!Number.isSafeInteger(idNum) || idNum <= 0) {
     return res.status(400).json({ success:false, error:{ code:'BAD_REQUEST', message:'invalid id' }});
   }
  try {

    const q = await db.query<{
      proposal_id: string;
      title: string;
      description: string | null;
      status: string;
      start_ts: string;
      end_ts: string;
      snapshot_id: string;
      quorum_met: boolean | null;
      passed: boolean | null;
      total_votes_power: string | null;
      allocation: Record<string, number> | null;
      for_power: string | null;
      against_power: string | null;
      abstain_power: string | null;
    }>(/*sql*/`
      SELECT
        p.id AS proposal_id,
        p.title,
        p.description,
        p.status,
        p.start_ts,
        p.end_ts,
        p.snapshot_id,
        p.quorum_met,
        p.passed,
        p.total_votes_power,
    jsonb_object_agg(a.key, a.weight_fraction) AS allocation,
        t.for_power,
        t.against_power,
        t.abstain_power
      FROM gov_proposals p
      LEFT JOIN gov_proposal_allocations a ON a.proposal_id = p.id
      LEFT JOIN gov_tallies t ON t.proposal_id = p.id
      WHERE p.id = $1

      GROUP BY p.id, t.for_power, t.against_power, t.abstain_power
    `, [idNum]);

    const row = q.rows[0] ?? null;
    res.json({ success: true, data: row });
  } catch (e: any) {
    console.error('proposals.detail error:', e);
    res.status(500).json({ success: false, error: { code: 'SERVER', message: e.message } });
  }
});

// ---------- GET /v1/gov/config ----------
// Front-end expects quorumVotes in either data.quorumVotes or data.quorum_votes.
proposalsRouter.get('/config', async (_req: Request, res: Response) => {
  try {
    // Minimal placeholder until governance parameters are persisted.
    const quorumVotes = Number(process.env.GOV_QUORUM_VOTES ?? 1000);
    const votingPeriodSec = Number(process.env.GOV_VOTING_PERIOD_SEC ?? 3 * 24 * 3600); // 3 days default
    res.json({ success: true, data: { quorumVotes, votingPeriodSec } });
  } catch (e: any) {
    res.status(500).json({ success:false, error:{ code:'SERVER', message:e.message }});
  }
});
