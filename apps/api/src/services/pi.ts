import axios from 'axios';

const PI_BASE = process.env.PI_API_BASE || 'https://api.minepi.com/v2';
const PI_KEY  = (process.env.PI_API_KEY || '').trim();

function ensureServerKey() {
  if (!PI_KEY) {
    console.error('[pi/key] missing PI_API_KEY');
    throw new Error('PI_API_KEY is missing/empty at runtime');
  }
}

const reqCfg = { timeout: 15_000 } as const;

export async function approvePayment(paymentId: string) {
  ensureServerKey();
  const url = `${PI_BASE}/payments/${paymentId}/approve`;
  const headers = { Authorization: `Key ${PI_KEY}` };
  console.log('[pi/approve->Pi]', { url, keyPrefix: PI_KEY.slice(0,6), ts: new Date().toISOString() });
  try {
    const { data, status } = await axios.post(url, null, { ...reqCfg, headers });
    console.log('[pi/approve<-Pi]', { status, ok: true });
    return data;
  } catch (e: any) {
    console.error('[pi/approve ERR]', { status: e?.response?.status, body: e?.response?.data, ts: new Date().toISOString() });
    throw e;
  }
}

export async function completePayment(paymentId: string, txid: string) {
  ensureServerKey();
  const url = `${PI_BASE}/payments/${paymentId}/complete`;
  const headers = { Authorization: `Key ${PI_KEY}` };
  console.log('[pi/complete->Pi]', { url, keyPrefix: PI_KEY.slice(0,6), txid, ts: new Date().toISOString() });
  try {
    const { data, status } = await axios.post(url, { txid }, { ...reqCfg, headers });
    console.log('[pi/complete<-Pi]', { status, ok: true });
    return data;
  } catch (e: any) {
    console.error('[pi/complete ERR]', { status: e?.response?.status, body: e?.response?.data, ts: new Date().toISOString() });
    throw e;
  }
}

export async function getMeWithUserToken(userAccessToken: string) {
  const url = `${PI_BASE}/me`;
  const { data } = await axios.get(url, { headers: { Authorization: `Bearer ${userAccessToken}` } });
  return data;
}
