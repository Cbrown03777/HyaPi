// apps/api/src/web/govProposals.ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { listProposals } from '../data/govRepo';
import type { ProposalStatus } from '../types/gov';

export const govProposalsPublicRouter = Router();

const QuerySchema = z.object({
  limit: z.preprocess((v)=> Number(v ?? 20), z.number().min(1).max(100)).optional(),
  cursor: z.string().optional(),
  status: z.enum(['Open','Closed','Passed','Rejected','Failed','Canceled','All']).optional(),
});

// GET /v1/gov/proposals
// Public: list proposals for governance grid. No-store for dynamic content.
// Returns { success: true, data: { items, nextCursor } }

govProposalsPublicRouter.get('/proposals', async (req: Request, res: Response) => {
  try {
    const q = QuerySchema.safeParse(req.query);
    const limit = (q.success ? (q.data.limit ?? 20) : 20) as number;
    const cursor = q.success ? (q.data.cursor ?? undefined) : undefined;
    const status = q.success ? (q.data.status as ProposalStatus | 'All' | undefined) : undefined;

    const data = await listProposals({ limit, cursor, status });
    res.setHeader('Cache-Control', 'no-store');
    return res.json({ success: true, data });
  } catch (e: any) {
    console.error('govProposals.list error:', e);
    res.setHeader('Cache-Control', 'no-store');
    return res.json({ success: true, data: { items: [], nextCursor: null } });
  }
});
