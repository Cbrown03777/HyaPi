// apps/api/src/web/govBoost.ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { GOV_BOOST, getBoostForUser, type LockTermWeeks } from '../gov/boost';
import { upsertUserLock } from '../data/govRepo';

export const govBoostRouter = Router();
export const govBoostPublicRouter = Router();

// Public config
govBoostPublicRouter.get('/boost/config', (_req: Request, res: Response) => {
  const terms = Object.entries(GOV_BOOST).map(([weeks, boost]) => ({ weeks: Number(weeks), boost }));
  res.json({ terms });
});

// Authenticated: get my boost
govBoostRouter.get('/boost/me', async (req: Request, res: Response) => {
  try {
    const user = (req as any).user as { userId?: number };
    if (!user?.userId) return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'missing user' } });
    const info = await getBoostForUser(String(user.userId));
    res.json({ success: true, data: info });
  } catch (e: any) {
    res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: e.message } });
  }
});

// Authenticated: create/update my lock
const LockBody = z.object({
  termWeeks: z.union([z.literal(26), z.literal(52), z.literal(104)]),
  txUrl: z.string().url().optional(),
});

govBoostRouter.post('/boost/lock', async (req: Request, res: Response) => {
  try {
    const user = (req as any).user as { userId?: number };
    if (!user?.userId) return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'missing user' } });
    const body = LockBody.safeParse(req.body);
    if (!body.success) return res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: 'invalid body' } });
    const { termWeeks, txUrl } = body.data;
    // Idempotent upsert
    const lock = await upsertUserLock({ userId: String(user.userId), termWeeks: termWeeks as LockTermWeeks, txUrl: txUrl ?? null });
    res.json({ success: true, data: lock });
  } catch (e: any) {
    res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: e.message } });
  }
});
