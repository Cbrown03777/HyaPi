"use client";
import * as React from 'react';

export function PiDebugBar() {
  const [search] = React.useState(() => (typeof window !== 'undefined') ? new URLSearchParams(window.location.search) : null);
  const enabled = search?.get('piDebug') === '1';
  if (!enabled) return null;
  const ua = typeof navigator !== 'undefined' ? navigator.userAgent : 'n/a';
  const ready = typeof window !== 'undefined' ? !!window.__piReady : false;
  const hasPi = typeof window !== 'undefined' ? !!window.Pi : false;
  const hasAuth = typeof window !== 'undefined' ? !!window.Pi?.authenticate : false;
  const initErr = typeof window !== 'undefined' ? (window.__piInitError || '') : '';
  return (
    <div style={{ position:'fixed', bottom:8, left:8, zIndex:10000, padding:'8px 10px', fontSize:12, background:'rgba(0,0,0,0.6)', color:'#fff', borderRadius:8, fontFamily:'monospace', maxWidth:320 }}>
      <div><b>Pi Debug</b></div>
      <div>location: {typeof window !== 'undefined' ? window.location.href : 'n/a'}</div>
      <div>has window.Pi: {String(hasPi)}</div>
      <div>has Pi.authenticate: {String(hasAuth)}</div>
      <div>pi ready: {String(ready)}</div>
      <div>init error: {initErr || '-'}</div>
      <div>UA: {ua}</div>
    </div>
  );
}
