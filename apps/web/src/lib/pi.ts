// apps/web/src/lib/pi.ts
declare global {
  interface Window { Pi?: any }
}

export async function initPi() {
  if (typeof window === 'undefined' || !window.Pi) return null; // not in Pi Browser
  const Pi = window.Pi;
  Pi.init?.({ version: "2.0" });
  return Pi;
}

export async function signInWithPi(): Promise<{ accessToken: string; uid: string; username?: string } | string> {
  // Fallback for local browser outside Pi Browser:
  if (typeof window === 'undefined' || !(window as any).Pi) {
    return 'dev pi_dev_address:1';
  }

  const Pi = (window as any).Pi;
  try {
    // Request payments + username scopes (adjust if you need more)
    const authRes = await Pi.authenticate(
      { scopes: ['payments', 'username'] },
      onIncompletePaymentFound
    );
    // returns { accessToken, user: { uid, username } }
    const { accessToken, user } = authRes;
    // Send token to server on each API call via Authorization: Bearer <accessToken>
    return { accessToken, uid: user?.uid, username: user?.username };
  } catch (e) {
    console.error('Pi auth failed', e);
    return 'dev pi_dev_address:1';
  }

  function onIncompletePaymentFound(payment: any) {
    // Optional: call our server to finalize/complete lingering payments
    // fetch(`${process.env.NEXT_PUBLIC_GOV_API_BASE}/v1/pi/incomplete`, { ... })
    console.log('incomplete payment found', payment);
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

