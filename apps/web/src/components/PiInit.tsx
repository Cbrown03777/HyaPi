"use client";
import * as React from 'react';

declare global { interface Window { Pi?: any; __piReady?: boolean; __piInitError?: string } }

// Best-effort initializer: marks ready as soon as Pi.authenticate exists; init does not gate readiness.
export function PiInit() {
  React.useEffect(() => {
    let cancelled = false;
    (async () => {
      const start = Date.now();
      while (!cancelled && (typeof window === 'undefined' || !(window as any).Pi)) {
        if (Date.now() - start > 6000) {
          if (!cancelled) (window as any).__piInitError = 'Pi SDK script not available';
          return;
        }
        await new Promise(r => setTimeout(r, 100));
      }
      if (cancelled) return;
      const Pi = (window as any).Pi;
      // Mark ready immediately if authenticate present pre-init
      if (Pi?.authenticate) (window as any).__piReady = true;
      try {
        const network = process.env.NEXT_PUBLIC_PI_NETWORK || 'TESTNET';
        if (typeof Pi?.init === 'function') {
          Pi.init({ version: '2.0', network });
        }
      } catch (e:any) {
        (window as any).__piInitError = e?.message || 'Pi SDK init failed';
      }
      // Mark ready if authenticate appears after init
      if (Pi?.authenticate) (window as any).__piReady = true;
    })();
    return () => { cancelled = true; };
  }, []);
  return null;
}
