// apps/web/src/lib/pi.ts
import type { PiAuthScope, PiSDK } from '@/types/pi-sdk';

// Public auth/user result types
export interface PiAuthUser { uid: string; username?: string }
export interface PiLoginResult { uid: string; username: string; accessToken: string }

// Instrumented diagnostics structures
export interface PiAuthDiagnostics {
  ts: string;
  ua: string;
  isPiBrowser: boolean;
  hasWindowPi: boolean;
  hasAuthenticate: boolean;
  passedScopes: unknown;
  normalizedScopes?: string[];
  note?: string;
}

const ALLOWED_SCOPES: PiAuthScope[] = ['username', 'payments', 'wallet'];
type InternalDiag = PiAuthDiagnostics; // alias for clarity

function coerceScopes(input: unknown, fallback: PiAuthScope[] = ['username','payments']): string[] {
  if (Array.isArray(input)) {
    return (input as any[]).flat()
      .map(s => (typeof s === 'string' ? s.trim() : ''))
      .filter(Boolean)
      .filter(s => (ALLOWED_SCOPES as readonly string[]).includes(s as PiAuthScope));
  }
  if (typeof input === 'string') {
    return input.split(/[\,\s]+/g)
      .map(s => s.trim())
      .filter(Boolean)
      .filter(s => (ALLOWED_SCOPES as readonly string[]).includes(s as PiAuthScope));
  }
  return [...fallback];
}

function makeDiag(opts: { scopes: unknown }): InternalDiag {
  const ua = typeof navigator !== 'undefined' ? navigator.userAgent : '';
  const g: any = typeof window !== 'undefined' ? window : {};
  return {
    ts: new Date().toISOString(),
    ua,
    isPiBrowser: /PiBrowser/i.test(ua),
    hasWindowPi: !!g.Pi,
    hasAuthenticate: !!(g.Pi && typeof g.Pi.authenticate === 'function'),
    passedScopes: opts?.scopes
  };
}

let __shimInstalled = false;
export function installPiAuthShim(): void {
  if (typeof window === 'undefined' || __shimInstalled) return;
  const g: any = window as any;
  const Pi = g.Pi;
  if (!Pi || typeof Pi.authenticate !== 'function') return;
  const original = Pi.authenticate.bind(Pi);
  Pi.authenticate = async (opts: any, onIncomplete?: (p: any) => void) => {
    const diag = makeDiag({ scopes: opts?.scopes });
    try {
      const normalized = coerceScopes(opts?.scopes);
      diag.normalizedScopes = normalized;
      const validInput = Array.isArray(opts?.scopes) || typeof opts?.scopes === 'string';
      if (!validInput) {
        diag.note = 'Invalid scopes type (must be array or string).';
        console.error('[Pi auth diag]', diag);
        throw Object.assign(new Error('Pi auth failed: invalid scopes type'), { diag });
      }
      if (!normalized.length) {
        diag.note = 'Scopes normalized to empty (none are allowed).';
        console.error('[Pi auth diag]', diag);
        throw Object.assign(new Error('Pi auth failed: no valid scopes provided'), { diag });
      }
      const safe = { ...(opts || {}), scopes: normalized };
      console.debug('[Pi auth diag OK]', diag);
      return await original(safe, onIncomplete);
    } catch (err) {
      if (!(err as any).diag) (err as any).diag = diag;
      throw err;
    }
  };
  __shimInstalled = true;
  console.debug('[Pi.authenticate shim] installed');
}

// Relaxed readiness: we only require Pi.authenticate to exist.
export async function waitForPiSDK(opts?: { timeoutMs?: number; intervalMs?: number }) {
  const timeoutMs = opts?.timeoutMs ?? 10000;
  const intervalMs = opts?.intervalMs ?? 50;
  if (typeof window === 'undefined') throw new Error('No window');
  const g: any = window as any;
  const start = Date.now();
  if (g.Pi?.authenticate) { installPiAuthShim(); return g.Pi; }
  for (let i = 0; i < Math.ceil(timeoutMs / intervalMs); i++) {
    if (g.Pi?.authenticate) { installPiAuthShim(); return g.Pi; }
    await new Promise(r => setTimeout(r, intervalMs));
  }
  throw new Error(g.__piInitError || 'Pi SDK not available');
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
  const Pi = await waitForPiSDK(); // shim ensured
  const scopes = coerceScopes(rawScopes, ['username','payments']);
  try {
    const res = await Pi.authenticate({ scopes }, (p:any) => console.debug('[Pi incomplete payment]', p?.identifier));
    const uid = res?.user?.uid || res?.user?.username || '';
    const username = (res?.user?.username || res?.user?.uid || '').toString();
    const accessToken = res?.accessToken || res?.access_token || '';
    if (!uid || !accessToken) throw new Error('Pi authenticate returned no uid or access token');
    return { uid, username, accessToken };
  } catch (e:any) {
    console.error('[piLogin error]', e?.message, e?.diag || {});
    throw e; // propagate with diagnostics
  }
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

