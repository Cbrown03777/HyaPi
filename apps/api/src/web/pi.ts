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

    let paymentData: any = null;
    try {
      const r = await platformApprove(paymentId);
      paymentData = r.data;
    } catch (e:any) {
      const data = e?.response?.data;
      if (e?.response?.status === 400 && data?.error === 'already_approved' && data?.payment) {
        paymentData = data.payment;
      } else {
        throw e;
      }
    }

    // Optional full fetch for freshest metadata
    try { const full = await platformGetPayment(paymentId); if (full?.data) paymentData = full.data; } catch {}

  const identifier = paymentData?.identifier || paymentData?.paymentId || paymentId;
  const amount = Number(paymentData?.amount ?? 0) || 0;
    const memo = paymentData?.memo ?? null;
    const lockupWeeks = Number(paymentData?.metadata?.lockupWeeks ?? 0) || 0;
  const dir = 'user_to_app'; // canonical for deposits (U->A)
    const from_address = paymentData?.from_address ?? paymentData?.fromAddress ?? null;
    const to_address = paymentData?.to_address ?? paymentData?.toAddress ?? null;
    const approvedJson = JSON.stringify(paymentData || {});

    await db.query(
      `INSERT INTO pi_payments (
         pi_payment_id, direction, uid, amount_pi, status, status_text, payload, memo, lockup_weeks, from_address, to_address, updated_at
       ) VALUES ($1,$2,COALESCE($3::text,'unknown'),$4,'approved','approved',$5::jsonb,$6,$7,$8,$9,now())
       ON CONFLICT (pi_payment_id) DO UPDATE SET
         amount_pi=CASE WHEN pi_payments.amount_pi=0 AND EXCLUDED.amount_pi>0 THEN EXCLUDED.amount_pi ELSE pi_payments.amount_pi END,
         memo=EXCLUDED.memo,
         lockup_weeks=EXCLUDED.lockup_weeks,
         status='approved',
         status_text='approved',
         payload=EXCLUDED.payload,
         from_address=COALESCE(EXCLUDED.from_address, pi_payments.from_address),
         to_address=COALESCE(EXCLUDED.to_address, pi_payments.to_address),
         direction='user_to_app',
         updated_at=now()`,
      [identifier, dir, user.uid ?? null, amount, approvedJson, memo, lockupWeeks, from_address, to_address]
    );

    res.json({ success: true, paymentId: identifier, idempotent: true });
  } catch (e:any) {
    res.status(400).json({ success:false, error:{ code:'APPROVE_FAIL', message: e?.message || 'approve failed'} });
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
    try { const full = await platformGetPayment(paymentId); if (full?.data) paymentData = full.data; } catch {}
    const identifier = paymentData?.identifier || paymentData?.paymentId || paymentId;
    const amount = Number(paymentData?.amount ?? 0) || 0;
    const memo = paymentData?.memo ?? null;
    const lockupWeeks = Number(paymentData?.metadata?.lockupWeeks ?? 0) || 0;
  const dir = 'user_to_app';
    const from_address = paymentData?.from_address ?? paymentData?.fromAddress ?? null;
    const to_address = paymentData?.to_address ?? paymentData?.toAddress ?? null;
    const payloadJson = JSON.stringify(paymentData || {});

    await withTx(async (tx) => {
      await tx.query(
        `UPDATE pi_payments SET
           status='completed',
           status_text='completed',
           txid=$2,
           amount_pi=CASE WHEN amount_pi=0 AND $3>0 THEN $3 ELSE amount_pi END,
           payload=$4::jsonb,
           memo=$5,
           lockup_weeks=$6,
           from_address=COALESCE($7, from_address),
           to_address=COALESCE($8, to_address),
           direction='user_to_app',
           updated_at=now()
         WHERE pi_payment_id=$1`,
        [identifier, txid, amount, payloadJson, memo, lockupWeeks, from_address, to_address]
      );

      // Resolve user id by uid in payload if not provided in session
      let userId: number | null = user?.userId ?? null;
      const payloadUid = paymentData?.user_uid || paymentData?.uid;
      if (!userId && payloadUid) {
        const r = await tx.query<{ id: number }>(`SELECT id FROM users WHERE uid=$1 LIMIT 1`, [payloadUid]);
        userId = r.rows[0]?.id ?? null;
      }

      if (userId && amount > 0) {
        const idemKey = `pi_complete:${identifier}`;
        const exists = await tx.query(`SELECT 1 FROM liquidity_events WHERE idem_key=$1 LIMIT 1`, [idemKey]);
        if (exists.rowCount === 0) {
          const apyRow = await tx.query<{ apy_bps: number }>(`SELECT apy_bps FROM v_apy_for_lock WHERE lockup_weeks=$1 LIMIT 1`, [lockupWeeks]);
          const apy_bps = apyRow.rows[0]?.apy_bps ?? 500;
          const init_fee_bps = lockupWeeks === 0 ? 50 : 0;
          await tx.query(
            `INSERT INTO stakes (user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps)
             VALUES ($1,$2,$3,$4,$5)`,
            [userId, amount, lockupWeeks, apy_bps, init_fee_bps]
          );
          await tx.query(
            `INSERT INTO balances (user_id, hyapi_amount)
             VALUES ($1,$2)
             ON CONFLICT (user_id) DO UPDATE SET hyapi_amount = balances.hyapi_amount + EXCLUDED.hyapi_amount`,
            [userId, amount]
          );
          try {
            await tx.query(
              `INSERT INTO liquidity_events(kind, amount, meta, amount_usd, idem_key, tx_ref)
               VALUES ('deposit',$1,$2::jsonb,$3,$4,$5)`,
              [amount, JSON.stringify({ paymentId: identifier, txid, memo, lockupWeeks }), amount * Number(process.env.PI_USD_PRICE ?? '0.35'), idemKey, `pi:${identifier}`]
            );
          } catch {}
          console.log('[pi/complete][deposit/credited]', { paymentId: identifier, userId, principal: amount });
        }
      }
    });

    res.json({ success: true, paymentId: identifier, idempotent: true });
  } catch (e:any) {
    res.status(400).json({ success:false, error:{ code:'COMPLETE_FAIL', message: e?.message || 'complete failed'} });
  }
});

// Debug inspection endpoint
piRouter.get('/debug/payments/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const payment = await db.query(`SELECT * FROM pi_payments WHERE pi_payment_id=$1`, [id]);
    const liq = await db.query(`SELECT * FROM liquidity_events WHERE tx_ref=$1`, [`pi:${id}`]);
    res.json({ success:true, data: { payment: payment.rows[0] || null, liquidity: liq.rows } });
  } catch (e:any) {
    res.status(500).json({ success:false, error:{ code:'DEBUG_FAIL', message: e?.message || 'error' } });
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
