import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { withTx, db } from '../services/db';

export const devRouter = Router();

// Simple gate: only enabled when both flags are on and request comes from dev token
function assertDevAllowed(req: Request) {
  if (process.env.ALLOW_DEV_TOKENS !== '1' || process.env.ENABLE_DEV_FAUCET !== '1') {
    const err: any = new Error('dev faucet disabled');
    err.status = 403;
    throw err;
  }
  const user = (req as any).user as { isDev?: boolean } | undefined;
  if (!user?.isDev) {
    const err: any = new Error('dev faucet requires dev auth');
    err.status = 401;
    throw err;
  }
}

const AmountBody = z.object({ amountPi: z.number().positive().finite().max(1_000_000_000).default(100_000) });

/** POST /v1/dev/faucet/balance
 * Credits the authenticated user's hyaPi balance for local testing.
 */
devRouter.post('/faucet/balance', async (req: Request, res: Response) => {
  try {
    assertDevAllowed(req);
    const user = (req as any).user as { userId: number; piAddress?: string };
    const { amountPi } = AmountBody.parse(req.body ?? {});

    await withTx(async (tx) => {
      // Ensure user exists (dev only convenience)
      if (user?.userId) {
        await tx.query(
          `INSERT INTO users (id, pi_address)
           VALUES ($1, $2)
           ON CONFLICT (id) DO UPDATE SET pi_address = EXCLUDED.pi_address`,
          [user.userId, user.piAddress ?? `dev_${user.userId}`]
        );
      }
      await tx.query(
        `INSERT INTO balances (user_id, hyapi_amount)
         VALUES ($1, $2)
         ON CONFLICT (user_id) DO UPDATE
           SET hyapi_amount = balances.hyapi_amount + EXCLUDED.hyapi_amount`,
        [user.userId, amountPi]
      );
    });

    res.json({ success: true, data: { credited: amountPi } });
  } catch (e: any) {
    const status = e.status || 400;
    res.status(status).json({ success: false, error: { code: 'DEV_FAUCET_ERROR', message: e.message } });
  }
});

/** POST /v1/dev/faucet/buffer
 * Increases the treasury buffer so redemptions can be paid instantly in dev.
 */
devRouter.post('/faucet/buffer', async (req: Request, res: Response) => {
  try {
    assertDevAllowed(req);
    const { amountPi } = AmountBody.parse(req.body ?? {});

    await db.query(`UPDATE treasury SET buffer_pi = buffer_pi + $1, last_updated = now() WHERE id = true`, [amountPi]);

    res.json({ success: true, data: { added: amountPi } });
  } catch (e: any) {
    const status = e.status || 400;
    res.status(status).json({ success: false, error: { code: 'DEV_FAUCET_ERROR', message: e.message } });
  }
});
