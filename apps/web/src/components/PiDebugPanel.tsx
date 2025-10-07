"use client";
import * as React from 'react';

export function PiDebugPanel() {
  const [lines, setLines] = React.useState<string[]>([]);
  function log(msg: string, obj?: any) {
    const s = `[${new Date().toISOString()}] ${msg}` + (obj ? ` ${JSON.stringify(obj)}` : '');
    setLines(prev => [s, ...prev].slice(0, 50));
  }
  (globalThis as any).__pidbg = { log };
  return (
    <div style={{ position:'fixed', bottom:8, right:8, zIndex:9999, background:'rgba(0,0,0,.65)', color:'#fff', padding:8, width:320, maxHeight:260, overflow:'auto', fontSize:12, fontFamily:'monospace', borderRadius:4 }}>
      <div style={{ fontWeight:700, marginBottom:4 }}>Pi Debug</div>
      {lines.map((l,i)=><div key={i} style={{ whiteSpace:'pre-wrap' }}>{l}</div>)}
    </div>
  );
}
