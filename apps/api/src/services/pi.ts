import axios from 'axios';

const PI_BASE = process.env.PI_API_BASE || 'https://api.minepi.com/v2';
const PI_KEY = process.env.PI_API_KEY || '';

function keyHeader() {
  if (!PI_KEY) throw new Error('PI_API_KEY not configured');
  return { Authorization: `Key ${PI_KEY}` };
}

// MUST use Server API Key for approve/complete with verbose logging
export async function approvePayment(paymentId: string) {
  const url = `${PI_BASE}/payments/${paymentId}/approve`;
  console.log('[pi/approve->Pi]', { url, ts: new Date().toISOString(), authScheme: 'Key', keyPrefix: (PI_KEY||'').slice(0,6) });
  try {
    const { data, status } = await axios.post(url, null, { headers: keyHeader(), timeout: 15_000 });
    console.log('[pi/approve<-Pi]', { status, snippet: JSON.stringify(data).slice(0,200) });
    return data;
  } catch (err: any) {
    console.error('[pi/approve ERR]', { status: err?.response?.status, data: err?.response?.data, ts: new Date().toISOString() });
    if (err?.response?.status === 401 || err?.response?.status === 403) {
      console.warn('[pi/auth] using Server Key scheme, key prefix:', (PI_KEY||'').slice(0,6));
    }
    throw err;
  }
}

export async function completePayment(paymentId: string, txid: string) {
  const url = `${PI_BASE}/payments/${paymentId}/complete`;
  console.log('[pi/complete->Pi]', { url, ts: new Date().toISOString(), txid });
  try {
    const { data, status } = await axios.post(url, { txid }, { headers: keyHeader(), timeout: 15_000 });
    console.log('[pi/complete<-Pi]', { status, snippet: JSON.stringify(data).slice(0,200) });
    return data;
  } catch (err: any) {
    console.error('[pi/complete ERR]', { status: err?.response?.status, data: err?.response?.data, ts: new Date().toISOString() });
    if (err?.response?.status === 401 || err?.response?.status === 403) {
      console.warn('[pi/auth] using Server Key scheme, key prefix:', (PI_KEY||'').slice(0,6));
    }
    throw err;
  }
}

// User scoped – uses Pioneer user access token /me endpoint
export async function getMeWithUserToken(userAccessToken: string) {
  const url = `${PI_BASE}/me`;
  const { data } = await axios.get(url, { headers: { Authorization: `Bearer ${userAccessToken}` } });
  return data;
}
