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

function piHeaders() {
  return { Authorization: `Key ${PI_KEY}`, 'Content-Type': 'application/json' } as const;
}

export async function approvePaymentAtPi(paymentId: string) {
  ensureServerKey();
  const url = `${PI_BASE}/payments/${encodeURIComponent(paymentId)}/approve`;
  console.log('[pi->approve] url', url, 'keyPrefix', PI_KEY.slice(0,6));
  try {
    const r = await axios.post(url, {}, { headers: piHeaders(), timeout: 15_000, validateStatus: () => true });
    const body = typeof r.data === 'string' ? r.data : JSON.stringify(r.data);
    console.log('[pi<-approve]', { status: r.status, bodySnippet: body.slice(0,300) });
    if (r.status >= 400) {
      const err: any = new Error(`Pi approve failed: ${r.status}`);
      err.response = r; throw err;
    }
    return r.data;
  } catch (e:any) {
    console.error('[pi approve ERR]', { status: e?.response?.status, body: e?.response?.data, message: e?.message });
    throw e;
  }
}

export async function completePaymentAtPi(paymentId: string, txid?: string) {
  ensureServerKey();
  const url = `${PI_BASE}/payments/${encodeURIComponent(paymentId)}/complete`;
  console.log('[pi->complete] url', url, 'keyPrefix', PI_KEY.slice(0,6));
  try {
    const r = await axios.post(url, { txid }, { headers: piHeaders(), timeout: 15_000, validateStatus: () => true });
    const body = typeof r.data === 'string' ? r.data : JSON.stringify(r.data);
    console.log('[pi<-complete]', { status: r.status, bodySnippet: body.slice(0,300) });
    if (r.status >= 400) {
      const err: any = new Error(`Pi complete failed: ${r.status}`);
      err.response = r; throw err;
    }
    return r.data;
  } catch (e:any) {
    console.error('[pi complete ERR]', { status: e?.response?.status, body: e?.response?.data, message: e?.message });
    throw e;
  }
}

export async function getMeWithUserToken(userAccessToken: string) {
  const url = `${PI_BASE}/me`;
  const { data } = await axios.get(url, { headers: { Authorization: `Bearer ${userAccessToken}` } });
  return data;
}
