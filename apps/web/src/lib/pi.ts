// apps/web/src/lib/pi.ts
import type { PiAuthScope, PiSDK } from '@/types/pi-sdk';

// Public auth/user result types
export interface PiAuthUser { uid: string; username?: string }
export interface PiLoginResult { uid: string; username: string; accessToken: string }

const ALLOWED_SCOPES: PiAuthScope[] = ['username', 'payments', 'wallet'];

function coerceScopes(input: unknown, fallback: PiAuthScope[] = ['username','payments']): string[] {
  if (Array.isArray(input)) {
    return (input as any[])
      .flat()
      .map(s => (typeof s === 'string' ? s.trim() : ''))
      .filter(Boolean)
      .filter(s => ALLOWED_SCOPES.includes(s as PiAuthScope));
  }
  if (typeof input === 'string') {
    return input
      .split(/[\,\s]+/g)
      .map(s => s.trim())
      .filter(Boolean)
      .filter(s => ALLOWED_SCOPES.includes(s as PiAuthScope));
  }
  return [...fallback];
}

/** One-time shim: wrap Pi.authenticate to always coerce scopes into a string[] */
export function installPiAuthShim(): void {
  if (typeof window === 'undefined') return;
  const g: any = window as any;
  const Pi = g.Pi;
  if (!Pi || typeof Pi.authenticate !== 'function' || g.__piShimInstalled) return;
  const original = Pi.authenticate.bind(Pi);
  Pi.authenticate = async (opts: any, onIncomplete?: (p: any) => void) => {
    const normalized = { ...(opts || {}) };
    normalized.scopes = coerceScopes(normalized.scopes);
    if (!Array.isArray(normalized.scopes) || normalized.scopes.length === 0) {
      normalized.scopes = ['username','payments'];
    }
    console.debug('[Pi.authenticate shim] coerced scopes =', normalized.scopes, ' (type=', typeof normalized.scopes, ')');
    return original(normalized, onIncomplete);
  };
  g.__piShimInstalled = true;
    console.debug('[Pi.authenticate shim] installed');
}

// Relaxed readiness: we only require Pi.authenticate to exist.
export async function waitForPiSDK(opts?: { timeoutMs?: number; intervalMs?: number }) {
  const timeoutMs = opts?.timeoutMs ?? 7000;
  const intervalMs = opts?.intervalMs ?? 100;
  const start = Date.now();
  if (typeof window === 'undefined') throw new Error('No window');
  const g: any = window as any;
  // fast path
  if (g.Pi?.authenticate) { installPiAuthShim(); return g.Pi; }
  while (Date.now() - start < timeoutMs) {
    if (g.Pi?.authenticate) { installPiAuthShim(); return g.Pi; }
    await new Promise(r => setTimeout(r, intervalMs));
  }
  throw new Error(g.__piInitError || 'Pi SDK not ready. Open in Pi Browser and ensure domain is whitelisted.');
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
export async function piLogin(rawScopes?: unknown): Promise<PiLoginResult> {
  const Pi = await waitForPiSDK(); // installs shim
  const scopes = coerceScopes(rawScopes, ['username','payments']); // defensive
  const onIncompletePaymentFound = (payment: any) => {
    console.debug('[pi] incomplete payment found', payment?.identifier);
  };
  const res = await Pi.authenticate({ scopes }, onIncompletePaymentFound);
  const uid = res?.user?.uid || res?.user?.username || '';
  const username = (res?.user?.username || res?.user?.uid || '').toString();
  const accessToken = res?.accessToken || res?.access_token || '';
  if (!uid || !accessToken) throw new Error('Pi authenticate returned no uid or access token');
  return { uid, username, accessToken };
}

// Compat shim for legacy callers expecting a bearer token string
export async function signInWithPi(): Promise<string> {
  const { accessToken } = await piLogin();
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

