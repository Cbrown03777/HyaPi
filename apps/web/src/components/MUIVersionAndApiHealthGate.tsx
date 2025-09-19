"use client";
import { useEffect, useState } from 'react';
import { assertMUIv6 } from '../utils/assertMUIv6';
import { checkApiHealth } from '../api/health';

export function MUIVersionAndApiHealthGate() {
  const [offline, setOffline] = useState(false);
  useEffect(() => {
    try { assertMUIv6(); } catch (e) { /* throw in dev guards v7 */ throw e; }
    checkApiHealth().then(r => setOffline(!r.ok)).catch(() => setOffline(true));
  }, []);
  if (!offline) return null;
  return (
    <div style={{ position:'fixed', top:0, left:0, right:0, zIndex:9999, background:'#fde047', color:'#111827', padding:'6px 12px', textAlign:'center' }}>
      Backend offline: some data may be stale
    </div>
  );
}
