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

