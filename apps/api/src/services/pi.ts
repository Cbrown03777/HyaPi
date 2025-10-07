import axios from 'axios';

const PI_BASE = process.env.PI_API_BASE || 'https://api.minepi.com/v2';
const PI_KEY = process.env.PI_API_KEY || '';

function keyHeader() {
  if (!PI_KEY) throw new Error('PI_API_KEY not configured');
  return { Authorization: `Key ${PI_KEY}` };
}

// MUST use Server API Key for approve/complete
export async function approvePayment(paymentId: string) {
  const url = `${PI_BASE}/payments/${paymentId}/approve`;
  try {
    const { data } = await axios.post(url, null, { headers: keyHeader() });
    return data;
  } catch (err: any) {
    const status = err?.response?.status;
    const body = err?.response?.data;
    console.error('[pi/approve] status', status, 'body', body);
    if (status === 401 || status === 403) {
      console.warn('[pi/auth] using Server Key scheme, key prefix:', (PI_KEY || '').slice(0,6));
    }
    throw err;
  }
}

export async function completePayment(paymentId: string, txid: string) {
  const url = `${PI_BASE}/payments/${paymentId}/complete`;
  try {
    const { data } = await axios.post(url, { txid }, { headers: keyHeader() });
    return data;
  } catch (err: any) {
    const status = err?.response?.status;
    const body = err?.response?.data;
    console.error('[pi/complete] status', status, 'body', body);
    if (status === 401 || status === 403) {
      console.warn('[pi/auth] using Server Key scheme, key prefix:', (PI_KEY || '').slice(0,6));
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
