import { Router } from 'express';
import { z } from 'zod';
import { approvePayment as serverApprovePayment, completePayment as serverCompletePayment } from '../services/pi';
import { db, withTx } from '../services/db';
import { platformApprove, platformComplete, platformCreateA2U, platformGetPayment } from '../services/piPlatform';
import { createA2U } from '../services/piA2U';
import { runPiPayoutSweep } from '../services/piPayoutWorker';

export const piRouter = Router();

piRouter.post('/approve/:paymentId', async (req, res) => {
  try {
    const { paymentId } = req.params as { paymentId: string };
    const user = (req as any).user;
    if (!user?.userId) return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'no user' } });

    await withTx(async (tx) => {
      await tx.query(
        `INSERT INTO pi_payments(pi_payment_id, direction, uid, amount_pi, status)
         VALUES ($1,'U2A',COALESCE($2::text,'unknown'),0,'created')
         ON CONFLICT (pi_payment_id) DO NOTHING`,
        [paymentId, user.uid ?? null]
      );
    });

    await platformApprove(paymentId);
    await db.query(`UPDATE pi_payments SET status='approved', updated_at=now() WHERE pi_payment_id=$1`, [paymentId]);
    res.json({ success: true });
  } catch (e: any) {
    res.status(400).json({ success: false, error: { code: 'APPROVE_FAIL', message: e.message } });
  }
});

// Manual trigger to sweep A2U payouts and update statuses/txids
piRouter.post('/refresh', async (_req, res) => {
  try {
    const result = await runPiPayoutSweep(25);
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(500).json({ success: false, error: { code: 'REFRESH_FAIL', message: e.message } });
  }
});

piRouter.post('/complete/:paymentId', async (req, res) => {
  try {
    const { paymentId } = req.params as { paymentId: string };
    const { txid } = req.body as { txid: string };
    const user = (req as any).user;

    await platformComplete(paymentId, txid);
    // Fetch payment to get amount and metadata
    let amount = 0;
    let lockupWeeks = 0;
    try {
      const pr = await platformGetPayment(paymentId);
      amount = Number(pr.data?.amount ?? 0);
      lockupWeeks = Number(pr.data?.metadata?.lockupWeeks ?? 0);
    } catch {}

    await withTx(async (tx) => {
      await tx.query(
        `UPDATE pi_payments SET status='completed', txid=$2, amount_pi = COALESCE($3, amount_pi), updated_at=now() WHERE pi_payment_id=$1`,
        [paymentId, txid, Number.isFinite(amount) ? amount : null]
      );

      // Minimal stake crediting (MVP): create stake and credit balance
      if (user?.userId && amount > 0) {
        // compute apy and init fee consistent with staking route
        const apyRow = await tx.query<{ apy_bps: number }>(
          `SELECT apy_bps FROM v_apy_for_lock WHERE lockup_weeks=$1 LIMIT 1`,
          [lockupWeeks]
        );
        const apy_bps = apyRow.rows[0]?.apy_bps ?? 500;
        const init_fee_bps = lockupWeeks === 0 ? 50 : 0;
        await tx.query(
          `INSERT INTO stakes (user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps)
           VALUES ($1,$2,$3,$4,$5)`,
          [user.userId, amount, lockupWeeks, apy_bps, init_fee_bps]
        );
        await tx.query(
          `INSERT INTO balances (user_id, hyapi_amount)
           VALUES ($1,$2)
           ON CONFLICT (user_id) DO UPDATE SET hyapi_amount = balances.hyapi_amount + EXCLUDED.hyapi_amount`,
          [user.userId, amount]
        );
      }
    });

    res.json({ success: true });
  } catch (e: any) {
    res.status(400).json({ success: false, error: { code: 'COMPLETE_FAIL', message: e.message } });
  }
});

// New SDK callback endpoints (array signature style) - approve
piRouter.post('/payments/:id/approve', async (req, res) => {
  const id = z.string().min(1).parse(req.params.id);
  console.log('[pi/api approve] inbound', { id, ts: new Date().toISOString() });
  try {
    const dto = await serverApprovePayment(id);
    console.log('[pi/api approve] ok', { id });
    return res.json({ success: true, data: dto });
  } catch (e: any) {
    const status = e?.response?.status ?? 500;
    console.error('[pi/api approve] fail', { id, status, body: e?.response?.data });
    return res.status(status).json({ success: false, error: { code: 'APPROVE_FAILED', status } });
  }
});

// New SDK callback endpoints - complete
piRouter.post('/payments/:id/complete', async (req, res) => {
  const id = z.string().min(1).parse(req.params.id);
  const txid = z.string().min(4).parse(req.body?.txid);
  console.log('[pi/api complete] inbound', { id, txid, ts: new Date().toISOString() });
  try {
    const dto = await serverCompletePayment(id, txid);
    console.log('[pi/api complete] ok', { id });
    return res.json({ success: true, data: dto });
  } catch (e: any) {
    const status = e?.response?.status ?? 500;
    console.error('[pi/api complete] fail', { id, status, body: e?.response?.data });
    return res.status(status).json({ success: false, error: { code: 'COMPLETE_FAILED', status } });
  }
});

// Debug echo endpoint to verify connectivity/CORS
piRouter.post('/debug/echo', (req, res) => {
  return res.json({
    ok: true,
    ts: new Date().toISOString(),
    headers: { origin: req.headers.origin, auth: !!req.headers.authorization },
    body: req.body ?? null
  });
});

piRouter.post('/payout', async (req, res) => {
  try {
    const user = (req as any).user;
    const { amountPi, memo, metadata } = req.body as { amountPi: number; memo?: string; metadata?: any };
    if (!user?.uid) return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'no uid' } });

    try {
      const r = await platformCreateA2U({ amount: amountPi, memo: memo ?? 'HyaPi redemption', metadata, uid: user.uid });
      const piPaymentId = r?.data?.identifier ?? r?.data?.paymentId ?? 'unknown';
      await db.query(
        `INSERT INTO pi_payments(pi_payment_id, direction, uid, amount_pi, status)
         VALUES ($1,'A2U',$2,$3,'created')
         ON CONFLICT (pi_payment_id) DO NOTHING`,
        [piPaymentId, user.uid, amountPi]
      );
      res.json({ success: true, data: { piPaymentId } });
    } catch (e: any) {
      const msg = e?.message ?? String(e);
      console.error('A2U payout create failed', msg);
      if (process.env.ALLOW_DEV_TOKENS === '1') {
        const piPaymentId = `dev-a2u-${Date.now()}`;
        await db.query(
          `INSERT INTO pi_payments(pi_payment_id, direction, uid, amount_pi, status)
           VALUES ($1,'A2U',$2,$3,'created')
           ON CONFLICT (pi_payment_id) DO NOTHING`,
          [piPaymentId, user.uid, amountPi]
        );
        return res.json({ success: true, data: { piPaymentId, dev: true } });
      }
      throw e;
    }
  } catch (e: any) {
    res.status(400).json({ success: false, error: { code: 'PAYOUT_FAIL', message: e.message } });
  }
});

// New endpoint initiating a full A2U payout using Stellar SDK flow
piRouter.post('/payouts', async (req, res) => {
  try {
    const user = (req as any).user;
    const { amountPi, memo, metadata, redemptionId } = req.body as { amountPi: number; memo?: string; metadata?: any; redemptionId?: number };
    if (!user?.uid) return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'no uid' } });

    // Kick off full A2U: create -> sign+submit -> complete
    const { identifier, txid } = await createA2U({ uid: user.uid, amount: amountPi, memo: memo ?? 'HyaPi redemption', metadata });

    await withTx(async (tx) => {
      await tx.query(
        `INSERT INTO pi_payments(pi_payment_id, direction, uid, amount_pi, status, txid)
         VALUES ($1,'A2U',$2,$3,'completed',$4)
         ON CONFLICT (pi_payment_id) DO UPDATE SET status='completed', txid=EXCLUDED.txid, amount_pi=EXCLUDED.amount_pi, updated_at=now()`,
        [identifier, user.uid, amountPi, txid]
      );

      if (redemptionId) {
        await tx.query(`UPDATE redemptions SET status='paid', updated_at=now() WHERE id=$1 AND user_id=$2`, [redemptionId, user.userId]);
      }
    });

    res.json({ success: true, data: { piPaymentId: identifier, txid } });
  } catch (e: any) {
    const msg = e?.message ?? String(e);
    if (process.env.ALLOW_DEV_TOKENS === '1') {
      const fallbackId = `dev-a2u-${Date.now()}`;
      await db.query(
        `INSERT INTO pi_payments(pi_payment_id, direction, uid, amount_pi, status)
         VALUES ($1,'A2U',$2,$3,'created')
         ON CONFLICT (pi_payment_id) DO NOTHING`,
        [fallbackId, (req as any).user?.uid ?? 'unknown', (req.body as any)?.amountPi ?? 0]
      );
      return res.json({ success: true, data: { piPaymentId: fallbackId, dev: true } });
    }
    res.status(400).json({ success: false, error: { code: 'PAYOUTS_FAIL', message: msg } });
  }
});
