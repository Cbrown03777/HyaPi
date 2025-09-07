import { Router, Request, Response } from 'express';
import type { PoolClient } from 'pg';
import { z } from 'zod';
import { db, withTx } from '../services/db';
import { platformCreateA2U } from '../services/piPlatform';

export const stakingRouter = Router();

/** Utils */
const nowUtc = () => new Date();

/** Zod schemas */
const DepositBody = z.object({
  amountPi: z.number().positive().finite(),
  lockupWeeks: z.number().int().min(0).max(104),
});

const RedeemBody = z.object({
  amountPi: z.number().positive().finite(),
});

/** Helper: pick APY (bps) for a given lockup using apy_tiers table */
async function pickApyBps(lockupWeeks: number): Promise<number> {
  const q = await db.query<{ apy_bps: number }>(
    `SELECT apy_bps
       FROM apy_tiers
      WHERE min_weeks <= $1
      ORDER BY min_weeks DESC
      LIMIT 1`,
    [lockupWeeks]
  );
  return q.rows[0]?.apy_bps ?? 500; // default 5% if tiers missing
}

/** POST /v1/stake/deposit
 * Body: { amountPi: number, lockupWeeks: number }
 * - records a stake row (DEV fallback). For Pi Testnet, prefer U2A payment flow via /v1/pi/*.
 * - credits user's hyaPi 1:1 (in balances.hyapi_amount)
 * - sets init_fee_bps = 50 if no-lock
 */
stakingRouter.post('/deposit', async (req: Request, res: Response) => {
  try {
    const user = (req as any).user as { userId: number };
    if (!user?.userId) {
      return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'missing user' } });
    }
    const body = DepositBody.parse(req.body);

    const apy_bps = await pickApyBps(body.lockupWeeks);
    const init_fee_bps = body.lockupWeeks === 0 ? 50 : 0;

    const out = await withTx(async (tx: PoolClient) => {
      // 1) create stake
      const ins = await tx.query(
        `INSERT INTO stakes (user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps)
         VALUES ($1,$2,$3,$4,$5)
         RETURNING id, user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps, unlock_ts, status`,
        [user.userId, body.amountPi, body.lockupWeeks, apy_bps, init_fee_bps]
      );

      // 2) credit user's hyaPi balance 1:1
      await tx.query(
        `INSERT INTO balances (user_id, hyapi_amount)
         VALUES ($1, $2)
         ON CONFLICT (user_id) DO UPDATE
           SET hyapi_amount = balances.hyapi_amount + EXCLUDED.hyapi_amount`,
        [user.userId, body.amountPi]
      );

      // (optional) record an audit row here

      return ins.rows[0];
    });

    const resp = { success: true, data: { stake: out } };
    await (res as any).saveIdem?.(resp);
    res.json(resp);
  } catch (e: any) {
    console.error('stake.deposit error', e);
    res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: e.message } });
  }
});

/** POST /v1/stake/redeem
 * Body: { amountPi: number }
 * - burns user's hyaPi immediately
 * - if treasury buffer >= amount → instant "paid"
 * - else create pending redemption with eta (MVP: now + 21 days)
 * - simple early-exit rule: if user has any active locked stake (unlock future), apply 1% fee (recorded on row)
 */
stakingRouter.post('/redeem', async (req: Request, res: Response) => {
  try {
    const user = (req as any).user as { userId: number };
    if (!user?.userId) {
      return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'missing user' } });
    }
    const body = RedeemBody.parse(req.body);
    const amount = body.amountPi;

    const result = await withTx(async (tx: PoolClient) => {
      // 0) ensure user has enough hyaPi
      const bal = await tx.query<{ hyapi_amount: string }>(
        `SELECT hyapi_amount::text FROM balances WHERE user_id=$1`,
        [user.userId]
      );
      const current = Number(bal.rows[0]?.hyapi_amount ?? 0);
      if (current < amount) {
        throw new Error('insufficient hyaPi balance');
      }

      // Burn hyaPi now
      await tx.query(
        `UPDATE balances SET hyapi_amount = hyapi_amount - $2 WHERE user_id=$1`,
        [user.userId, amount]
      );

      // Early exit: any active locked stakes?
      const s = await tx.query<{ cnt: string }>(
        `SELECT COUNT(*)::text AS cnt
           FROM stakes
          WHERE user_id=$1 AND status='active' AND lockup_weeks > 0 AND unlock_ts > now()`,
        [user.userId]
      );
      const hasLocked = Number(s.rows[0]?.cnt ?? '0') > 0;
      const early_exit_fee_bps = hasLocked ? 100 : 0; // 1% if user is locked

      // Treasury buffer
      const tre = await tx.query<{ buffer_pi: string }>(`SELECT buffer_pi::text FROM treasury WHERE id=true`);
      const buffer = Number(tre.rows[0]?.buffer_pi ?? 0);

      if (buffer >= amount) {
        // Instant payout path (MVP: just mark paid and reduce buffer)
        await tx.query(`UPDATE treasury SET buffer_pi = buffer_pi - $1, last_updated=now() WHERE id=true`, [amount]);
        const ins = await tx.query(
          `INSERT INTO redemptions (user_id, amount_pi, eta_ts, needs_unstake, status, updated_at)
           VALUES ($1,$2,NULL,false,'paid',now())
           RETURNING id, user_id, amount_pi, status, eta_ts, needs_unstake, created_at`,
          [user.userId, amount]
        );
        // Kick off an A2U payout on Testnet (non-blocking best-effort)
        try {
          const r = await platformCreateA2U({ amount, memo: 'HyaPi redemption', metadata: { redemptionId: ins.rows[0].id }, uid: (req as any).user?.uid });
          const piPaymentId = (r as any)?.data?.identifier ?? (r as any)?.data?.paymentId;
          if (piPaymentId) {
            await tx.query(
              `INSERT INTO pi_payments(pi_payment_id, direction, uid, amount_pi, status)
               VALUES ($1,'A2U',$2,$3,'created')
               ON CONFLICT (pi_payment_id) DO NOTHING`,
              [piPaymentId, (req as any).user?.uid ?? 'unknown', amount]
            );
          }
        } catch (e) {
          const msg = (e as any)?.message ?? String(e);
          console.error('A2U start failed', msg);
          // Optional dev fallback: if Platform API 404 or key missing, insert a placeholder row for testing the UI/db wiring
          if (process.env.ALLOW_DEV_TOKENS === '1') {
            const fallbackId = `dev-a2u-${Date.now()}`;
            await tx.query(
              `INSERT INTO pi_payments(pi_payment_id, direction, uid, amount_pi, status)
               VALUES ($1,'A2U',$2,$3,'created')
               ON CONFLICT (pi_payment_id) DO NOTHING`,
              [fallbackId, (req as any).user?.uid ?? 'unknown', amount]
            );
          }
        }
        return { redemption: ins.rows[0], early_exit_fee_bps, path: 'instant' as const };
      } else {
        // Queue path: estimate ETA (MVP: 21 days)
        const etaDays = 21;
        const eta = new Date(nowUtc().getTime() + etaDays * 24 * 60 * 60 * 1000);
        const ins = await tx.query(
          `INSERT INTO redemptions (user_id, amount_pi, eta_ts, needs_unstake, status, updated_at)
           VALUES ($1,$2,$3,true,'pending',now())
           RETURNING id, user_id, amount_pi, status, eta_ts, needs_unstake, created_at`,
          [user.userId, amount, eta]
        );
        return { redemption: ins.rows[0], early_exit_fee_bps, path: 'queued' as const };
      }
    });

    const resp = { success: true, data: result };
    await (res as any).saveIdem?.(resp);
    res.json(resp);
  } catch (e: any) {
    console.error('stake.redeem error', e);
    res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: e.message } });
  }
});

/** ---- Tiny PPS daily job (MVP) ----
 * Simulates daily growth and inserts into pps_series if today's row is missing.
 * dailyRate: 0.0005 ≈ ~18.3% APY (purely illustrative).
 */
export async function simulateDailyYieldIfNeeded(): Promise<void> {
  const today = new Date();
  const ymd = today.toISOString().slice(0, 10); // YYYY-MM-DD

  // Already inserted for today?
  const ex = await db.query<{ exists: boolean }>(
    `SELECT EXISTS(SELECT 1 FROM pps_series WHERE as_of_date = $1)::bool AS exists`,
    [ymd]
  );
  if (ex.rows[0]?.exists) return;

  // Get latest PPS (yesterday)
  const latest = await db.query<{ pps_1e18: string; as_of_date: string }>(
    `SELECT pps_1e18::text, as_of_date::text FROM v_pps_latest`
  );
  const prev = BigInt(latest.rows[0]?.pps_1e18 ?? '1000000000000000000'); // default 1e18

  // Simple constant daily rate (tune later or compute from allocations & chain APYs)
  const dailyRate = 0.0005; // 0.05% per day ~18.3% APR
  const increment = BigInt(Math.floor(Number(prev) * dailyRate));
  const next = prev + increment;

  await db.query(
    `INSERT INTO pps_series (as_of_date, pps_1e18)
     VALUES ($1, $2)`,
    [ymd, next.toString()]
  );
}
