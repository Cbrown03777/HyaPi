"use client";
import React, { useEffect, useMemo, useState } from 'react';
import { Box, Typography, Stack } from '@mui/material';
import { GOV_API_BASE } from '@hyapi/shared';

type HistRow = { proposalId:string; key:string; weight:number; appliedAt:string; normalization:number };

interface Props {
  limit?: number;
  since?: string; // ISO timestamp
  proposalId?: string;
  className?: string;
}

// Simple stacked line-ish chart using SVG (lightweight, no external deps)
export default function GovAllocationHistoryChart({ limit=200, since, proposalId, className }: Props) {
  const [rows, setRows] = useState<HistRow[]>([]);
  const [error, setError] = useState<string|undefined>();
  const [loading, setLoading] = useState(true);

  useEffect(()=> {
    (async () => {
      try {
        setLoading(true); setError(undefined);
        const params = new URLSearchParams();
        params.set('limit', String(limit));
        if (since) params.set('since', since);
        if (proposalId) params.set('proposalId', proposalId);
        const r = await fetch(`${GOV_API_BASE}/v1/alloc/gov-history?${params.toString()}`, { cache:'no-store' });
        const j = await r.json().catch(()=>null);
        if (!r.ok || !j?.success) throw new Error(j?.error?.message || 'fetch failed');
        setRows(j.data as HistRow[]);
      } catch (e:any) { setError(e.message || 'load failed'); }
      finally { setLoading(false); }
    })();
  }, [limit, since, proposalId]);

  const series = useMemo(() => {
    const map: Record<string, HistRow[]> = {};
    for (const r of rows) {
      (map[r.key] = map[r.key] || []).push(r);
    }
    for (const k of Object.keys(map)) {
      const arr = map[k];
      if (arr) arr.sort((a,b)=> new Date(a.appliedAt).getTime() - new Date(b.appliedAt).getTime());
    }
    return map;
  }, [rows]);

  const times = useMemo(()=> Array.from(new Set(rows.map(r=>r.appliedAt).sort())), [rows]);
  const keys = useMemo(()=> Object.keys(series).sort(), [series]);

  // Build per-time weight snapshot (normalized by row.normalization if present)
  const snapshots = useMemo(()=> {
    return times.map(ts => {
      const atRows = rows.filter(r=>r.appliedAt===ts);
      const out: Record<string, number> = {};
      for (const r of atRows) out[r.key] = r.normalization ? (r.weight / r.normalization) : r.weight;
      return { ts, weights: out };
    });
  }, [times, rows]);

  // Determine color palette
  const palette = ["#6366f1","#10b981","#f59e0b","#ef4444","#8b5cf6","#14b8a6","#ec4899","#0ea5e9","#84cc16","#f97316"];
  const colorFor = (k:string) => palette[keys.indexOf(k) % palette.length];

  // Prepare SVG path per key (step chart)
  const chartWidth = 600;
  const chartHeight = 180;
  const leftPad = 40;
  const rightPad = 10;
  const effectiveWidth = chartWidth - leftPad - rightPad;
  const allPoints = keys.length ? keys : [];
  const xFor = (ts:string) => {
    const idx = times.indexOf(ts);
    if (idx < 0) return leftPad;
    return leftPad + (effectiveWidth * (idx / Math.max(1, times.length - 1)));
  };
  const yFor = (w:number) => chartHeight - (w * (chartHeight - 20)) - 10; // top padding 10, bottom 10

  const paths = keys.map(k => {
    let d = '';
    let lastW = 0;
    const single = times.length === 1;
    times.forEach((ts,i) => {
      const snap = snapshots.find(s=>s.ts===ts);
      const w = snap?.weights[k] ?? lastW;
      lastW = w;
      const x = xFor(ts);
      const y = yFor(w);
      if (i===0) d += `M ${x} ${y}`; else d += ` L ${x} ${y}`;
      // If only one time point, draw a tiny horizontal segment so the stroke is visible
      if (single && i===0) {
        const x2 = leftPad + effectiveWidth; // extend across chart width
        d += ` L ${x2} ${y}`;
      }
    });
    return { key:k, d };
  });

  return (
    <Box className={className}>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 1 }}>
        <Typography variant="body2" fontWeight={600}>Governance Allocation History</Typography>
        {loading && <Typography variant="caption" color="text.secondary">Loading…</Typography>}
        {error && <Typography variant="caption" color="error.main">{error}</Typography>}
      </Stack>
      {rows.length===0 && !loading && !error && (
        <Typography variant="caption" color="text.secondary">No history.</Typography>
      )}
      {rows.length>0 && (
        <Box sx={{ overflowX: 'auto' }}>
          <svg width={chartWidth} height={chartHeight} style={{ background: 'rgba(0,0,0,0.2)', borderRadius: 12, border: '1px solid rgba(255,255,255,0.1)' }}>
            {/* axes */}
            <line x1={leftPad} y1={10} x2={leftPad} y2={chartHeight-10} stroke="#444" strokeWidth={1} />
            <line x1={leftPad} y1={chartHeight-10} x2={chartWidth-rightPad} y2={chartHeight-10} stroke="#444" strokeWidth={1} />
            {/* y ticks */}
            {[0,0.25,0.5,0.75,1].map(t => {
              const y = yFor(t);
              return <g key={t}>
                <line x1={leftPad} y1={y} x2={chartWidth-rightPad} y2={y} stroke="#222" strokeWidth={1} />
                <text x={leftPad-6} y={y+4} fontSize={9} textAnchor="end" fill="#888">{(t*100).toFixed(0)}%</text>
              </g>;
            })}
            {/* paths */}
            {paths.map(p => <path key={p.key} d={p.d} stroke={colorFor(p.key)} strokeWidth={2} fill="none" />)}
          </svg>
          <Stack direction="row" flexWrap="wrap" spacing={1.5} useFlexGap sx={{ mt: 1 }}>
            {keys.map(k => (
              <Stack key={k} direction="row" alignItems="center" spacing={0.5} sx={{ fontSize: 10 }}>
                <Box sx={{ width: 12, height: 12, borderRadius: 1, background: colorFor(k) }} />
                <Typography component="span" sx={{ fontSize: 10, color: 'white', opacity: 0.8 }}>{k}</Typography>
              </Stack>
            ))}
          </Stack>
        </Box>
      )}
    </Box>
  );
}
