import { Router } from 'express';
import { z } from 'zod';
import { approvePaymentAtPi as serverApprovePayment, completePaymentAtPi as serverCompletePayment } from '../services/pi';
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

    // Approve upstream
    const piResp = await platformApprove(paymentId);
    // Fetch full payment to capture amount / metadata if not present
    let paymentData: any = piResp.data;
    try { const full = await platformGetPayment(paymentId); paymentData = full.data || paymentData; } catch {}
    const amount = Number(paymentData?.amount ?? 0);
    const memo = paymentData?.memo ?? null;
    const lockupWeeks = Number(paymentData?.metadata?.lockupWeeks ?? 0) || null;
    const statusText = paymentData?.status?.developer_approved ? 'approved' : 'created';

    await db.query(
      `INSERT INTO pi_payments (pi_payment_id, direction, uid, amount_pi, status, payload, status_text, memo, lockup_weeks)
       VALUES ($1,'U2A',COALESCE($2::text,'unknown'),$3,$4,$5::jsonb,$6,$7,$8)
       ON CONFLICT (pi_payment_id) DO UPDATE
         SET payload=EXCLUDED.payload,
             status_text=EXCLUDED.status_text,
             memo=EXCLUDED.memo,
             lockup_weeks=EXCLUDED.lockup_weeks,
             amount_pi = CASE WHEN pi_payments.amount_pi=0 AND EXCLUDED.amount_pi>0 THEN EXCLUDED.amount_pi ELSE pi_payments.amount_pi END,
             updated_at=now()`,
      [paymentId, user.uid ?? null, Number.isFinite(amount) ? amount : 0, statusText === 'approved' ? 'approved' : 'created', JSON.stringify(paymentData || {}), statusText, memo, lockupWeeks]
    );

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

    const piResp = await platformComplete(paymentId, txid);
    let paymentData: any = piResp.data;
    try { const full = await platformGetPayment(paymentId); paymentData = full.data || paymentData; } catch {}
    const amount = Number(paymentData?.amount ?? 0);
    const memo = paymentData?.memo ?? null;
    const lockupWeeks = Number(paymentData?.metadata?.lockupWeeks ?? 0) || 0;

    await withTx(async (tx) => {
      await tx.query(
        `UPDATE pi_payments
           SET status='completed',
               status_text='completed',
               txid=$2,
               amount_pi = CASE WHEN amount_pi=0 AND $3 IS NOT NULL THEN $3 ELSE amount_pi END,
               payload=$4::jsonb,
               memo=$5,
               lockup_weeks=$6,
               updated_at=now()
         WHERE pi_payment_id=$1`,
        [paymentId, txid, Number.isFinite(amount) ? amount : null, JSON.stringify(paymentData || {}), memo, lockupWeeks || null]
      );

      // Credit stake + balance if not already (simple guard: check existing stake for this payment via tx_ref?)
      if (user?.userId && amount > 0) {
        const apyRow = await tx.query<{ apy_bps: number }>(`SELECT apy_bps FROM v_apy_for_lock WHERE lockup_weeks=$1 LIMIT 1`, [lockupWeeks]);
        const apy_bps = apyRow.rows[0]?.apy_bps ?? 500;
        const init_fee_bps = lockupWeeks === 0 ? 50 : 0;
        await tx.query(
          `INSERT INTO stakes (user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps)
             VALUES ($1,$2,$3,$4,$5)
             ON CONFLICT DO NOTHING`,
          [user.userId, amount, lockupWeeks, apy_bps, init_fee_bps]
        );
        await tx.query(
          `INSERT INTO balances (user_id, hyapi_amount)
             VALUES ($1,$2)
             ON CONFLICT (user_id) DO UPDATE SET hyapi_amount = balances.hyapi_amount + EXCLUDED.hyapi_amount`,
          [user.userId, amount]
        );
      }

      // Record liquidity event (deposit) with new meta/amount columns if present
      try {
        await tx.query(
          `INSERT INTO liquidity_events(kind, amount, meta, amount_usd, tx_ref)
             VALUES ('deposit',$1,$2::jsonb,$3,$4)`,
          [Number.isFinite(amount) ? amount : 0, JSON.stringify({ paymentId, txid, memo, lockupWeeks }), (Number.isFinite(amount) ? amount : 0) * Number(process.env.PI_USD_PRICE ?? '0.35'), `pi:${paymentId}`]
        );
      } catch {}
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
