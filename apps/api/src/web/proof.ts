import { Router, Request, Response } from 'express';
import { getProofOfReserves } from '../services/proofBalances';

export const proofRouter = Router();

// GET /v1/proof/reserves (public)
proofRouter.get('/reserves', async (_req: Request, res: Response) => {
  try {
    const data = await getProofOfReserves();
    return res.json({ success: true, data });
  } catch (e:any) {
    console.warn('proof reserves error', e?.message);
    return res.json({ success: true, data: { items: [], degraded: true } });
  }
});
