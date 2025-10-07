import { Router } from 'express';
import { z } from 'zod';
import { approvePayment, completePayment, getPayment } from '../services/piPayments';

export const piRoutesPayments = Router();

piRoutesPayments.post('/approve', async (req, res) => {
  try {
    const body = z.object({ paymentId: z.string().min(8) }).parse(req.body);
    const data = await approvePayment(body.paymentId);
    res.json({ success: true, data });
  } catch (e: any) {
    console.error('[pi/approve] error', e?.message);
    res.status(400).json({ success: false, error: e?.message || 'approve failed' });
  }
});

piRoutesPayments.post('/complete', async (req, res) => {
  try {
    const body = z.object({ paymentId: z.string().min(8) }).parse(req.body);
    const data = await completePayment(body.paymentId);
    res.json({ success: true, data });
  } catch (e: any) {
    console.error('[pi/complete] error', e?.message);
    res.status(400).json({ success: false, error: e?.message || 'complete failed' });
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
