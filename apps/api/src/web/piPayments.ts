import { Router } from 'express';
import { z } from 'zod';
import { approvePayment, completePayment, getPayment } from '../services/piPayments';
import { approvePaymentAtPi, completePaymentAtPi } from '../services/pi';

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
    const body = z.object({ paymentId: z.string().min(4), txid: z.string().optional() }).parse(req.body);
    const data = await completePaymentAtPi(body.paymentId, body.txid);
    res.json({ success: true, data });
  } catch (e: any) {
    const status = e?.response?.status ?? 500;
    const piBody = e?.response?.data ?? null;
    console.error('[pi/complete] error', status, e?.message);
    res.status(status).json({ success: false, error: { code: 'PI_COMPLETE_FAIL', status, body: piBody } });
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
