// apps/web/src/lib/pi.ts
declare global { interface Window { Pi?: any; __piReady?: boolean; __piInitError?: string } }

// Relaxed readiness: we only require Pi.authenticate to exist.
export async function waitForPiSDK(opts?: { timeoutMs?: number; intervalMs?: number }) {
  const timeoutMs = opts?.timeoutMs ?? 7000;
  const intervalMs = opts?.intervalMs ?? 100;
  const start = Date.now();
  if (typeof window !== 'undefined' && (window as any).Pi?.authenticate) {
    return (window as any).Pi;
  }
  return await new Promise<any>((resolve, reject) => {
    const id = setInterval(() => {
      const Pi = typeof window !== 'undefined' ? (window as any).Pi : undefined;
      if (Pi?.authenticate) {
        clearInterval(id);
        resolve(Pi);
      } else if (Date.now() - start > timeoutMs) {
        clearInterval(id);
        const initErr = typeof window !== 'undefined' ? (window as any).__piInitError : '';
        reject(new Error(initErr || 'Pi SDK not ready. Open in Pi Browser and ensure domain is whitelisted.'));
      }
    }, intervalMs);
  });
}

// Optional helper; display-only.
export function isPiBrowser(): boolean {
  if (typeof navigator === 'undefined') return false;
  try { return /PiBrowser/i.test(navigator.userAgent || ''); } catch { return false; }
}

// ---- Scope normalization ----
const ALLOWED_SCOPES = ['username', 'payments', 'wallet'] as const;
type AllowedScope = (typeof ALLOWED_SCOPES)[number];

export function normalizeScopes(input?: unknown, fallback: AllowedScope[] = ['username','payments']): AllowedScope[] {
  if (Array.isArray(input)) {
    const cleaned = input
      .map(s => (typeof s === 'string' ? s.trim() : ''))
      .filter(Boolean) as string[];
    return cleaned.filter(s => (ALLOWED_SCOPES as readonly string[]).includes(s)) as AllowedScope[];
  }
  if (typeof input === 'string') {
    const parts = input.split(/[\,\s]+/g).map(s => s.trim()).filter(Boolean);
    return parts.filter(s => (ALLOWED_SCOPES as readonly string[]).includes(s)) as AllowedScope[];
  }
  return fallback;
}

export async function signInWithPi(): Promise<{ accessToken: string; uid: string; username?: string } | string> {
  if (typeof window === 'undefined') return 'dev pi_dev_address:1';
  try { await waitForPiSDK({ timeoutMs: 7000 }); } catch { return 'dev pi_dev_address:1'; }
  const Pi = (window as any).Pi;
  try {
    const authRes = await Pi.authenticate(
      { scopes: ['payments', 'username'] },
      onIncompletePaymentFound
    );
    const { accessToken, user } = authRes;
    return { accessToken, uid: user?.uid, username: user?.username };
  } catch (e) {
    console.error('Pi auth failed', e);
    return 'dev pi_dev_address:1';
  }
  function onIncompletePaymentFound(payment: any) { console.log('incomplete payment found', payment); }
}

// New robust login helper (source of truth going forward)
export async function piLogin(rawScopes?: unknown): Promise<{ uid: string; accessToken: string; username?: string }> {
  const Pi = await waitForPiSDK();
  console.debug('[piLogin] Pi present:', !!Pi, 'has authenticate:', !!Pi?.authenticate);
  const scopes = normalizeScopes(rawScopes, ['username','payments']);
  if (!Array.isArray(scopes) || scopes.length === 0) throw new Error('No valid Pi scopes selected');
  console.debug('[piLogin] using scopes:', scopes);
  const onIncompletePaymentFound = (payment: any) => {
    console.debug('[piLogin] incomplete payment found', payment?.identifier || payment?.id || '');
  };
  try {
    const authResult = await Pi.authenticate({ scopes }, onIncompletePaymentFound);
    console.debug('[piLogin] auth result keys:', Object.keys(authResult || {}));
    const uid = authResult?.user?.uid || authResult?.user?.username || '';
    const accessToken = authResult?.accessToken || authResult?.access_token || '';
    const username = authResult?.user?.username;
    if (!uid || !accessToken) throw new Error('Pi authenticate returned no uid or access token');
    return { uid, accessToken, username };
  } catch (e:any) {
    console.error('[piLogin] authenticate failed:', e);
    throw new Error(e?.message || 'Pi authenticate failed');
  }
}

export async function startDeposit(amountPi: number, token: string, memo = 'HyaPi stake deposit', metadata: any = {}) {
  const Pi = (globalThis as any).Pi;
  if (!Pi) throw new Error('Pi SDK not present');
  const paymentData = { amount: amountPi, memo, metadata };
  const base = process.env.NEXT_PUBLIC_GOV_API_BASE || '/api';
  const callbacks = {
    onReadyForServerApproval: async (paymentId: string) => {
      await fetch(`${base}/v1/pi/approve/${paymentId}`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
    },
    onReadyForServerCompletion: async (paymentId: string, txid: string) => {
      await fetch(`${base}/v1/pi/complete/${paymentId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ txid }),
      });
    },
    onCancel: (paymentId: string) => console.log('payment canceled', paymentId),
    onError: (error: any, paymentId: string) => console.error('payment error', error, paymentId),
  };
  return Pi.createPayment(paymentData, callbacks);
}

