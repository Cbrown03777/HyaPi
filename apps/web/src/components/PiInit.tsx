'use client';

import { useEffect } from 'react';

export function PiInit() {
  useEffect(() => {
    const w: any = typeof window !== 'undefined' ? (window as any) : null;
    if (!w) return;
    if (w.Pi && typeof w.Pi.init === 'function') {
      try {
        w.Pi.init({ version: '2.0', sandbox: true });
      } catch (e) {
        console.warn('Pi.init failed', e);
      }
    }
  }, []);
  return null;
}
