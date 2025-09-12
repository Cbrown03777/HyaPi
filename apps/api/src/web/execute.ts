import { Router, Request, Response } from 'express';
import type { PoolClient } from 'pg';
import { db, withTx } from '../services/db';
import { setOverrideTargets } from '../services/alloc';

export const executeRouter = Router();

/**
 * POST /v1/gov/execution/:id
 * - Requires proposal.status='finalized' and passed=true (unless ?force=1)
 * - Applies proposal allocation into allocations_current (upsert per chain)
 * - Marks proposal status='executed' and sets executed_at=now()
 * - (History table optional; not required for MVP)
 */
executeRouter.post('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const force = (req.query.force as string) === '1';

    // Load proposal gate
    const p = await db.query<{
      id: string;
      status: string;
      passed: boolean | null;
    }>(
      `SELECT id, status, passed FROM gov_proposals WHERE id=$1`,
      [id]
    );
    const prop = p.rows[0];
    if (!prop) {
      return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'proposal not found' } });
    }
    if (!force) {
      if (prop.status !== 'finalized') {
        return res.status(409).json({ success: false, error: { code: 'BAD_STATE', message: `expected finalized, got ${prop.status}` } });
      }
      if (prop.passed !== true) {
        return res.status(409).json({ success: false, error: { code: 'FAILED', message: 'proposal did not pass' } });
      }
    }

    // Fetch the proposal's target allocation
    const a = await db.query<{ key: string; weight_fraction: number }>(
      `SELECT key, weight_fraction
         FROM gov_proposal_allocations
        WHERE proposal_id=$1`,
      [id]
    );
    if (a.rows.length === 0) {
      return res.status(400).json({ success: false, error: { code: 'NO_ALLOCATION', message: 'no allocation found for proposal' } });
    }

    // Apply allocation + mark executed in one tx
    const applied = await withTx(async (tx: PoolClient) => {
      // Normalize weights (defensive) and write into allocation_targets with source='gov'
  const total = a.rows.reduce((s,r)=> s + Number(r.weight_fraction||0), 0) || 1;
      await tx.query(`DELETE FROM allocation_targets WHERE source='gov'`);
      for (const r of a.rows) {
        const w = Number(r.weight_fraction||0)/total;
        await tx.query(
          `INSERT INTO allocation_targets(key, weight_fraction, source, applied_at)
           VALUES ($1,$2,'gov', now())`, [r.key, w]
        );
      }
      // Record history snapshot of this governance execution
      for (const r of a.rows) {
        await tx.query(`INSERT INTO gov_allocation_history(proposal_id, key, weight_fraction, normalization) VALUES ($1,$2,$3,$4)`,
          [id, r.key, r.weight_fraction, total]);
      }
      const upd = await tx.query(
        `UPDATE gov_proposals
            SET status='executed',
                executed_at = now(),
                updated_at = now()
          WHERE id=$1
          RETURNING id, status, executed_at`,
        [id]
      );
      return { proposal: upd.rows[0], applied: a.rows };
    });

    const body = {
      success: true,
      data: {
        proposal_id: applied.proposal.id,
        status: applied.proposal.status,
        executed_at: applied.proposal.executed_at,
        allocation_applied: applied.applied
      }
    };
    await (res as any).saveIdem?.(body);
    res.json(body);
  } catch (e: any) {
    console.error('execution.apply error:', e);
    res.status(500).json({ success: false, error: { code: 'SERVER', message: e.message } });
  }
});
