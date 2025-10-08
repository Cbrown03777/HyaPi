import { Router } from 'express';
import { z } from 'zod';
import { approvePayment, completePayment, getPayment } from '../services/piPayments';
import { approvePaymentAtPi, completePaymentAtPiStrict, getPaymentAtPi } from '../services/pi';
import { recordPiPayment, creditStakeForDeposit } from '../data/paymentsRepo';
import assert from 'node:assert';

export const piRoutesPayments = Router();

piRoutesPayments.post('/approve', async (req, res) => {
  try {
    const body = z.object({ paymentId: z.string().min(4) }).parse(req.body);
    // Call raw Pi approve with full logging & propagate Pi status
    const data = await approvePaymentAtPi(body.paymentId);
    res.json({ success: true, data });
  } catch (e: any) {
    const status = e?.response?.status ?? 500;
    const piBody = e?.response?.data ?? null;
    console.error('[pi/approve] error', status, e?.message);
    res.status(status).json({ success: false, error: { code: 'PI_APPROVE_FAIL', status, body: piBody } });
  }
});

piRoutesPayments.post('/complete', async (req, res) => {
  try {
    const body = z.object({ paymentId: z.string().min(4), txid: z.string().min(6) }).parse(req.body);
    const { paymentId, txid } = body;
    // Pre-validate payment state
    let pre; try { pre = await getPaymentAtPi(paymentId); } catch (e:any) {
      return res.status(e?.response?.status || 502).json({ success:false, error:{ code:'PI_FETCH_FAIL', status: e?.response?.status, body: e?.response?.data }});
    }
    const preData = pre.data || {};
    try {
      assert(preData.direction === 'user_to_app', 'bad_direction');
      if (process.env.PI_APP_PUBLIC) assert(preData.to_address === process.env.PI_APP_PUBLIC, 'bad_to_address');
    } catch (verr:any) {
      return res.status(400).json({ success:false, error:{ code:'PREVALIDATION_FAIL', message: verr.message } });
    }
    // Complete w/ retry
    let completeResp: any; let attempt=0; let lastErr: any;
    while (attempt < 3) {
      attempt++;
      try {
        completeResp = await completePaymentAtPiStrict(paymentId, txid);
        if (completeResp.status >= 400) throw Object.assign(new Error('pi_non_2xx'), { response: completeResp });
        break;
      } catch (e:any) {
        lastErr = e;
        const code = e?.response?.status;
        if (code && (code === 409 || code >= 500) && attempt < 3) {
          await new Promise(r=>setTimeout(r, 250 * attempt));
          continue;
        }
        return res.status(code || 500).json({ success:false, error:{ code:'PI_COMPLETE_FAIL', status: code, body: e?.response?.data }});
      }
    }
    // Post fetch to confirm status
    let post; try { post = await getPaymentAtPi(paymentId); } catch {}
    const pdata = (post?.data) || preData;
    const identifier = pdata.identifier || pdata.paymentId || paymentId;
    const amount = Number(pdata.amount ?? 0);
    const user_uid = pdata.user_uid || pdata.uid || pdata.user?.uid || pdata.userUid;
    const lockWeeks = Number(pdata.metadata?.lockupWeeks ?? 0);
    const chainTxid = pdata.status?.transaction?.txid || txid;
    if (!identifier || !user_uid || !Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ success:false, error:{ code:'BAD_PI_PAYMENT', message:'Invalid Pi payment payload' }});
    }
    await recordPiPayment({ identifier, user_uid, amount, txid: chainTxid, metadata: pdata.metadata, from_address: pdata.from_address, to_address: pdata.to_address, raw: pdata });
    const credit = await creditStakeForDeposit({ user_uid, amount, lockWeeks, paymentId: identifier, txid: chainTxid });
    console.log('[credit]', { user_uid, amount, stakeId: credit.stakeId, paymentId: identifier });
    res.json({ success:true, credited:true, stake:{ id: credit.stakeId, principal_pi: credit.amount, lock_weeks: credit.lockWeeks }, payment:{ id: identifier, txid: chainTxid }, pi_status:{ developer_approved: pdata.status?.developer_approved, developer_completed: pdata.status?.developer_completed } });
  } catch (e:any) {
    const status = e?.response?.status ?? 500;
    const body = e?.response?.data ?? null;
    console.error('[pi/complete] error', status, e?.message);
    res.status(status).json({ success:false, error:{ code:'PI_COMPLETE_FAIL', status, body } });
  }
});

piRoutesPayments.get('/payments/:id', async (req, res) => {
  try {
    const data = await getPayment(req.params.id);
    res.json({ success: true, data });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e?.message || 'fetch failed' });
  }
});

// Optional probe endpoint for any arbitrary id (helpful for diagnosing id vs header issues)
piRoutesPayments.get('/probe/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const data = await approvePaymentAtPi(id).catch(e => { throw e; });
    res.json({ success: true, data });
  } catch (e:any) {
    const status = e?.response?.status ?? 500;
    res.status(status).json({ success:false, error:{ code:'PI_PROBE_FAIL', status, body: e?.response?.data ?? null } });
  }
});

piRoutesPayments.get('/inspect/:id', async (req, res) => {
  try {
    const r = await getPaymentAtPi(req.params.id);
    res.json({ ok: true, payment: r.data });
  } catch (e:any) {
    res.status(e?.response?.status || 500).json({ ok:false, status: e?.response?.status, body: e?.response?.data, err: e?.message });
  }
});

piRoutesPayments.get('/debug/:id', async (req,res) => {
  try {
    const r = await getPaymentAtPi(req.params.id);
    const p = r.data || {};
    res.json({ ok:true, id: p.identifier || p.paymentId, direction: p.direction, to_address: p.to_address, amount: p.amount, memo: p.memo, status: p.status });
  } catch (e:any) {
    res.status(e?.response?.status || 500).json({ ok:false, err: e?.message, status: e?.response?.status, body: e?.response?.data });
  }
});
