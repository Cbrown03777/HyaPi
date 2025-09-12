import { Router, Request, Response } from 'express';

// Minimal wallet router to satisfy front-end balance fetch and eliminate 404 noise.
// Requires Bearer auth (handled by global auth middleware). If user is dev token, present
// a large mock balance; otherwise default to 0 until real balance integration.

export const walletRouter = Router();

walletRouter.get('/balance', async (req: Request, res: Response) => {
  try {
    const user = (req as any).user as { userId: number; isDev?: boolean } | undefined;
    if (!user?.userId) {
      return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'missing user' } });
    }
    const mockBalance = user.isDev ? 1_000_000 : 0;
    res.json({ success: true, data: { pi_balance: mockBalance, userId: user.userId } });
  } catch (e: any) {
    res.status(500).json({ success: false, error: { code: 'SERVER', message: e.message } });
  }
});
