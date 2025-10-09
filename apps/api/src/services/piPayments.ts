import axios from 'axios';
import assert from 'node:assert';
import { db } from './db';

const PI_API_BASE = process.env.PI_API_BASE ?? 'https://api.minepi.com/v2';
// Read lazily at call-time to avoid crashing server startup if not set yet
function getAppCreds() {
  const APP_ID = process.env.PI_APP_ID || '';
  const APP_SECRET = process.env.PI_APP_SECRET || '';
  return { APP_ID, APP_SECRET };
}

function piHeaders() {
  const scheme = process.env.PI_SERVER_AUTH_SCHEME || 'Key'; // 'Key' or 'Bearer'
  const { APP_SECRET } = getAppCreds();
  if (!APP_SECRET) throw new Error('PI_APP_SECRET not configured');
  return { Authorization: `${scheme} ${APP_SECRET}` };
}

export type PiPaymentStatus = 'pending_approval' | 'approved' | 'completed' | 'cancelled' | 'timed_out' | 'error';

export async function approvePayment(paymentId: string) {
  const url = `${PI_API_BASE}/payments/${encodeURIComponent(paymentId)}/approve`;
  const res = await axios.post(url, {}, { headers: piHeaders(), timeout: 15_000 });
  await db.query(
    `INSERT INTO pi_payments (pi_payment_id, status, payload)
     VALUES ($1,$2,$3)
     ON CONFLICT (pi_payment_id) DO UPDATE SET status=$2, payload=$3, updated_at=now()`,
    [paymentId, 'approved', res.data]
  );
  console.log('[piPayments] approve paymentId=%s status=%s env=%s', paymentId, res.status, process.env.PI_NETWORK);
  return res.data;
}

export async function completePayment(paymentId: string) {
  const url = `${PI_API_BASE}/payments/${encodeURIComponent(paymentId)}/complete`;
  const res = await axios.post(url, {}, { headers: piHeaders(), timeout: 15_000 });
  await db.query(
    `UPDATE pi_payments SET status='completed', payload=$2, updated_at=now() WHERE pi_payment_id=$1`,
    [paymentId, res.data]
  );
  console.log('[piPayments] complete paymentId=%s status=%s env=%s', paymentId, res.status, process.env.PI_NETWORK);
  return res.data;
}

export async function getPayment(paymentId: string) {
  const url = `${PI_API_BASE}/payments/${encodeURIComponent(paymentId)}`;
  const res = await axios.get(url, { headers: piHeaders(), timeout: 15_000 });
  return res.data;
}
