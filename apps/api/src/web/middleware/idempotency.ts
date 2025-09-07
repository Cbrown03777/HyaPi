import { Request, Response, NextFunction } from 'express';
import { getCache, setCache } from '../../services/cache';

export async function idempotency(req: Request, res: Response, next: NextFunction) {
  const key = req.headers['idempotency-key'] as string | undefined;
  if (!key) return next();
  const cached = await getCache(key);
  if (cached) return res.json(cached);
  (res as any).saveIdem = async (body: any) => { await setCache(key, body, 3600); };
  next();
}

