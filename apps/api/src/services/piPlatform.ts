import axios from 'axios';

const base = process.env.PI_API_BASE ?? 'https://api.minepi.com/v2';
const key = process.env.PI_API_KEY ?? '';

function requireKey() {
  if (!key) throw new Error('PI_API_KEY is not set');
}

function url(path: string) {
  return `${base}${path.startsWith('/') ? '' : '/'}${path}`;
}

export async function platformApprove(paymentId: string) {
  requireKey();
  return axios.post(url(`/payments/${encodeURIComponent(paymentId)}/approve`), {}, {
    headers: { Authorization: `Key ${key}` },
  });
}

export async function platformComplete(paymentId: string, txid: string) {
  requireKey();
  return axios.post(url(`/payments/${encodeURIComponent(paymentId)}/complete`), { txid }, {
    headers: { Authorization: `Key ${key}` },
  });
}

export async function platformCreateA2U(body: { amount: number; memo: string; metadata?: any; uid: string }) {
  requireKey();
  try {
    return await axios.post(url('/payments'), body, {
      headers: { Authorization: `Key ${key}` },
    });
  } catch (e: any) {
    const status = e?.response?.status;
    const data = e?.response?.data;
    const msg = `platformCreateA2U failed: ${status ?? 'no-status'} ${typeof data === 'string' ? data : JSON.stringify(data ?? {})}`;
    const err = new Error(msg);
    (err as any).status = status;
    (err as any).data = data;
    throw err;
  }
}

export async function platformMe(accessToken: string): Promise<{ uid: string; username?: string } | null> {
  try {
    const r = await axios.get(url('/me'), { headers: { Authorization: `Bearer ${accessToken}` } });
    const uid = r.data?.uid ?? r.data?.user?.uid;
    const username = r.data?.username ?? r.data?.user?.username;
    if (!uid) return null;
    return { uid, username };
  } catch {
    return null;
  }
}

export async function platformGetPayment(paymentId: string) {
  requireKey();
  return axios.get(url(`/payments/${encodeURIComponent(paymentId)}`), {
    headers: { Authorization: `Key ${key}` },
  });
}
