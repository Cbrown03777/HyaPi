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

  function coerceScopesArray(input: unknown): string[] {
    const ALLOWED = ['username','payments','wallet'] as const;
    if (Array.isArray(input)) {
      return input
        .flat()
        .map(s => (typeof s === 'string' ? s.trim() : ''))
        .filter(Boolean)
        .filter(s => (ALLOWED as readonly string[]).includes(s));
    }
    if (typeof input === 'string') {
      return input
        .split(/[\,\s]+/g)
        .map(s => s.trim())
        .filter(Boolean)
        .filter(s => (ALLOWED as readonly string[]).includes(s));
    }
    return ['username','payments'];
  }

  Pi.authenticate = async (optsOrScopes: any, onIncomplete?: (p: any) => void) => {
    const scopesArr = (Array.isArray(optsOrScopes?.scopes) || typeof optsOrScopes?.scopes === 'string')
      ? coerceScopesArray(optsOrScopes.scopes)
      : coerceScopesArray(optsOrScopes);

    (window as any).__piDebug = {
      ...(window as any).__piDebug,
      lastAuthCall: {
        ts: new Date().toISOString(),
        receivedType: Array.isArray(optsOrScopes) ? 'array' : typeof optsOrScopes,
        receivedKeys: optsOrScopes && typeof optsOrScopes === 'object' ? Object.keys(optsOrScopes) : null,
        coercedScopes: scopesArr
      }
    };
    console.debug('[Pi.authenticate shim] calling SDK with array scopes:', scopesArr);
    try {
      return await original(scopesArr, onIncomplete);
    } catch (err: any) {
      console.warn('[Pi.authenticate shim] array form failed, retrying with object form', err?.message);
      return await original({ scopes: scopesArr }, onIncomplete);
    }
  };

  __shimInstalled = true;
  console.debug('[Pi.authenticate shim] installed (array-first fallback-to-object)');
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
  const Pi = await waitForPiSDK();
  const desiredScopes = rawScopes ?? ['username','payments'];
  try {
    const res = await Pi.authenticate(desiredScopes, (p:any)=>console.debug('[Pi] incomplete payment', p?.identifier));
    const uid = res?.user?.uid || res?.user?.username || '';
    const username = (res?.user?.username || res?.user?.uid || '').toString();
    const accessToken = res?.accessToken || res?.access_token || '';
    if (!uid || !accessToken) throw new Error('Pi authenticate returned no uid or access token');
    return { uid, username, accessToken };
  } catch (e:any) {
    console.error('[piLogin error]', e?.message, e?.diag || {});
    throw e;
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
  const base = process.env.NEXT_PUBLIC_API_BASE || process.env.NEXT_PUBLIC_GOV_API_BASE || '/api';
  const callbacks = {
    onReadyForServerApproval: async (paymentId: string) => {
      console.debug('[Pi] onReadyForServerApproval', paymentId);
      try {
        // New body-based public endpoint (no bearer required)
        await fetch(`${base}/v1/pi/approve`, { method: 'POST', headers: { 'Content-Type':'application/json' }, body: JSON.stringify({ paymentId }) });
      } catch (e) {
        console.warn('server approve (public) failed, trying auth route', (e as any)?.message);
        try {
          await fetch(`${base}/v1/pi/approve/${paymentId}`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } });
        } catch(err){ console.error('server approve fallback failed', (err as any)?.message); }
      }
    },
    onReadyForServerCompletion: async (paymentId: string, txid: string) => {
      console.debug('[Pi] onReadyForServerCompletion', paymentId, txid);
      try {
        await fetch(`${base}/v1/pi/complete`, { method: 'POST', headers: { 'Content-Type':'application/json' }, body: JSON.stringify({ paymentId }) });
      } catch (e) {
        console.warn('server complete (public) failed, trying auth route', (e as any)?.message);
        try {
          await fetch(`${base}/v1/pi/complete/${paymentId}`, { method: 'POST', headers: { 'Content-Type':'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ txid }) });
        } catch(err){ console.error('server complete fallback failed', (err as any)?.message); }
      }
    },
    onCancel: (paymentId: string) => console.log('payment canceled', paymentId),
    onError: (error: any, paymentId: string) => console.error('payment error', error, paymentId),
  };
  return Pi.createPayment(paymentData, callbacks);
}

// Public helpers (explicit) for manual server approval/completion if needed elsewhere
export async function approveOnServer(paymentId: string): Promise<void> {
  const base = process.env.NEXT_PUBLIC_API_BASE || '/api';
  const r = await fetch(`${base}/v1/pi/approve`, { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ paymentId }) });
  if (!r.ok) throw new Error('server approve failed');
}
export async function completeOnServer(paymentId: string): Promise<void> {
  const base = process.env.NEXT_PUBLIC_API_BASE || '/api';
  const r = await fetch(`${base}/v1/pi/complete`, { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ paymentId }) });
  if (!r.ok) throw new Error('server complete failed');
}

