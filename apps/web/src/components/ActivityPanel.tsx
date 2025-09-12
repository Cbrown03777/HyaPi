"use client";
import React, { useEffect } from "react";
import { Card, CardContent, Typography, IconButton, Chip, Box, Stack, Divider, Tooltip } from '@mui/material';
import { useActivity } from "./ActivityProvider";
import { GOV_API_BASE } from "@hyapi/shared";
import { fmtCompact } from "@/lib/format";

function timeAgo(ts: number): string {
  const s = Math.max(0, Math.floor((Date.now() - ts) / 1000));
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  return `${d}d ago`;
}

export function ActivityPanel() {
  const { items, clear, log } = useActivity();
  // On mount, fetch recent server history and merge (idempotently via log with id)
  useEffect(() => {
    let abort = false;
    (async () => {
      try {
        const token = (globalThis as any)?.hyapiBearer as string | undefined; // optional: set by pages when known
        const headers: HeadersInit = token ? { Authorization: `Bearer ${token}` } : {};
        const res = await fetch(`${GOV_API_BASE}/v1/activity/recent`, { headers });
        if (!res.ok) return;
        const j = await res.json();
        const srv = j?.data?.items as any[] | undefined;
        if (!srv || abort) return;
        for (const it of srv) {
          log({
            id: String(it.id ?? `${it.kind}:${it.ts}`),
            kind: it.kind,
            title: it.title,
            detail: it.detail,
            status: it.status,
            ts: typeof it.ts === 'string' ? new Date(it.ts).getTime() : (it.ts ?? Date.now()),
          });
        }
      } catch {}
    })();
    return () => { abort = true };
  }, [log]);
  if (!items.length) return null;
  return (
    <Card variant="outlined" sx={{ mt: 4, backdropFilter: 'blur(8px)', background: 'linear-gradient(145deg, rgba(255,255,255,0.05), rgba(255,255,255,0.12))' }}>
      <CardContent sx={{ py: 2 }}>
        <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 1 }}>
          <Typography variant="subtitle2" fontWeight={600}>Recent activity</Typography>
          <Typography component="button" onClick={clear} sx={{ cursor: 'pointer', border: 'none', background: 'none', p: 0, m: 0, fontSize: 11, color: 'text.secondary', '&:hover': { color: 'text.primary' } }}>Clear</Typography>
        </Stack>
        <Stack divider={<Divider flexItem sx={{ borderColor: 'divider', opacity: 0.4 }} />} spacing={0}>
          {items.slice(0,8).map(e => {
            const color = e.status === 'success' ? 'success' : e.status === 'error' ? 'error' : 'primary';
            const icon = e.kind === 'stake' ? '⇪' : e.kind === 'redeem' ? '⇄' : e.kind === 'vote' ? '✓' : e.kind === 'finalize' ? '⚑' : '▶';
            return (
              <Stack key={e.id} direction="row" spacing={2} alignItems="flex-start" py={1}>
                <Box aria-hidden sx={{ width: 24, height: 24, borderRadius: '50%', fontSize: 12, bgcolor: `${color}.main`, color: '#000', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 600, opacity: 0.9 }}>
                  {icon}
                </Box>
                <Box flex={1} minWidth={0}>
                  <Typography variant="body2" fontWeight={600} noWrap>{e.title}</Typography>
                  {e.detail && (
                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }} noWrap>
                      {e.detail.replace(/(\d+(?:\.\d+)?)\s?(Pi|hyaPi)/gi, (_, num, unit) => `${fmtCompact(Number(num))} ${unit}`)}
                    </Typography>
                  )}
                </Box>
                <Typography variant="caption" color="text.disabled" sx={{ whiteSpace: 'nowrap' }}>{timeAgo(e.ts)}</Typography>
              </Stack>
            );
          })}
        </Stack>
      </CardContent>
    </Card>
  );
}
