"use client";
import * as React from 'react';

declare global {
  interface Window { Pi?: any; __piReady?: boolean; __piInitError?: string }
}

export function PiInit() {
  React.useEffect(() => {
    let cancelled = false;
    async function boot() {
      const start = Date.now();
      while (!cancelled && (typeof window === 'undefined' || !window.Pi)) {
        if (Date.now() - start > 6000) {
          if (!cancelled) window.__piInitError = 'Pi SDK script not available';
          return;
        }
        await new Promise(r => setTimeout(r, 100));
      }
      if (cancelled) return;
      try {
        const network = process.env.NEXT_PUBLIC_PI_NETWORK || 'TESTNET';
        if (typeof window.Pi?.init === 'function') {
          window.Pi.init({ version: '2.0', network });
        }
        if (!window.Pi?.authenticate) {
          window.__piInitError = 'Pi SDK authenticate missing after init';
          return;
        }
        window.__piReady = true;
      } catch (e:any) {
        window.__piInitError = e?.message || 'Pi SDK init failed';
      }
    }
    boot();
    return () => { cancelled = true; };
  }, []);
  return null;
}
