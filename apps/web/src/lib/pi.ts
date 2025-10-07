// apps/web/src/lib/pi.ts
// Strong minimal Pi SDK typing + globals
type PiAuthScope = 'username' | 'payments' | 'wallet';
const ALLOWED_SCOPES: PiAuthScope[] = ['username', 'payments', 'wallet'];

interface PiSDK {
  init?: (opts: { version: string; network: string }) => void;
  authenticate: (opts: { scopes: string[] }, onIncompletePaymentFound?: (payment: any) => void) => Promise<any>;
  // createPayment kept as any (not used for auth typing scope bug)
  [k: string]: any;
}

declare global {
  interface Window {
    Pi?: PiSDK;
    __piReady?: boolean; // legacy debug
    __piInitError?: string;
  }
}

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

// ---- Scope normalization (returns plain string[]) ----
export function normalizeScopes(input?: unknown, fallback: PiAuthScope[] = ['username','payments']): string[] {
  if (Array.isArray(input)) {
    const arr = (input as any[]).flat().map(s => (typeof s === 'string' ? s.trim() : '')).filter(Boolean);
    return arr.filter(s => ALLOWED_SCOPES.includes(s as PiAuthScope));
  }
  if (typeof input === 'string') {
    const parts = input.split(/[\,\s]+/g).map(s => s.trim()).filter(Boolean);
    return parts.filter(s => ALLOWED_SCOPES.includes(s as PiAuthScope));
  }
  return [...fallback];
}

// New robust login helper (source of truth going forward)
export async function piLogin(rawScopes?: unknown): Promise<{ uid: string; accessToken: string }> {
  const Pi = await waitForPiSDK();
  const scopes = normalizeScopes(rawScopes, ['username','payments']);
  // HARD GUARDRAILS
  if (!Array.isArray(scopes)) throw new Error('Internal: scopes is not an array');
  if (!scopes.every(s => typeof s === 'string')) throw new Error('Internal: scopes contains non-string');
  if (scopes.length === 0) throw new Error('Internal: no valid scopes selected');
  console.debug('[piLogin] scopes validated:', scopes);
  if (!Array.isArray(scopes)) throw new Error('Internal: scopes not array at call site');
  const onIncompletePaymentFound = (payment: any) => {
    console.debug('[pi] incomplete payment found', payment?.identifier);
  };
  try {
    const res = await Pi.authenticate({ scopes }, onIncompletePaymentFound);
    const uid = res?.user?.uid || res?.user?.username || '';
    const accessToken = res?.accessToken || res?.access_token || '';
    if (!uid || !accessToken) throw new Error('Pi authenticate returned no uid or access token');
    return { uid, accessToken };
  } catch (e:any) {
    console.error('[piLogin] authenticate failed:', e);
    throw new Error(e?.message || 'Pi authenticate failed');
  }
}

// Compat shim for legacy callers expecting a bearer token string
export async function signInWithPi(): Promise<string> {
  const { accessToken } = await piLogin();
  if (!accessToken) throw new Error('Missing access token from Pi authenticate');
  return accessToken;
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

