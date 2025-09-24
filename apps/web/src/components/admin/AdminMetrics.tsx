"use client";
import React from 'react';
import { Card, CardContent, Typography, Stack, Chip, Box, LinearProgress, linearProgressClasses, Skeleton } from '@mui/material';
import { usePortfolioMetrics } from '@/hooks/usePortfolioMetrics';
import { fmtNumber as fmtDec, fmtCompact, fmtPercent } from '@/lib/format';

function Kpi({ label, value, badge }: { label: string; value: React.ReactNode; badge?: string | undefined }) {
  return (
    <Card variant="outlined" sx={{ borderRadius: 3 }}>
      <CardContent sx={{ p: 2.5 }}>
        <Typography variant="caption" sx={{ textTransform: 'uppercase', color: 'text.secondary' }}>{label}</Typography>
        <Typography variant="h6" sx={{ mt: 0.5, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 1 }}>
          {value}
          {badge && <Chip size="small" label={badge} color="warning" />}
        </Typography>
      </CardContent>
    </Card>
  );
}

function StackedBar({
  title,
  segments,
}: {
  title: string;
  segments: Array<{ label: string; color?: string; weight: number; tooltip?: string }>
}) {
  const total = segments.reduce((s, x) => s + x.weight, 0) || 1;
  return (
    <Card variant="outlined" sx={{ borderRadius: 3 }}>
      <CardContent sx={{ p: 2.5 }}>
        <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>{title}</Typography>
        <Box sx={{ display: 'flex', height: 14, borderRadius: 999, overflow: 'hidden', bgcolor: 'action.hover' }}>
          {segments.map((s, i) => (
            <Box key={i}
              title={s.tooltip ?? `${s.label}: ${fmtPercent(s.weight * 100, 1)}`}
              sx={{ width: `${(s.weight / total) * 100}%`, bgcolor: s.color || `hsl(${(i*67)%360}deg 70% 45%)` }} />
          ))}
        </Box>
        <Stack direction="row" spacing={1} sx={{ mt: 1, flexWrap: 'wrap' }}>
          {segments.map((s, i) => (
            <Chip key={i} size="small" variant="outlined" label={`${s.label} · ${fmtPercent(s.weight*100,1)}`} />
          ))}
        </Stack>
      </CardContent>
    </Card>
  );
}

export function AdminMetricsPanel() {
  const { data, isLoading } = usePortfolioMetrics();

  const tvlPi = data?.tvlPI ?? 0;
  const tvlUsd = data?.tvlUSD ?? 0;
  const apy = data?.apy7d ?? 0;
  const degraded = data?.prices.degraded ?? false;

  return (
    <Stack spacing={2}>
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
        <Kpi label="TVL (Pi)" value={isLoading ? <Skeleton width={100}/> : `${tvlPi >= 10_000 ? fmtCompact(tvlPi) : fmtDec(tvlPi)} Pi`} />
        <Kpi label="TVL (USD)" value={isLoading ? <Skeleton width={120}/> : `$${tvlUsd >= 10_000 ? fmtCompact(tvlUsd) : fmtDec(tvlUsd)}`}
             badge={degraded ? 'prices degraded' : undefined} />
        <Kpi label="PPS" value={isLoading ? <Skeleton width={60}/> : fmtDec(data?.pps ?? 1, 4)} />
        <Kpi label="APY (EMA7)" value={isLoading ? <Skeleton width={80}/> : fmtPercent((apy ?? 0) * 100, 2)} />
      </Stack>
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
        <StackedBar
          title="By Chain"
          segments={(data?.chainMix ?? []).map(m=>({ label: m.chain, weight: m.weight, tooltip: `${m.chain} · $${fmtDec(m.usd)}` }))}
        />
        <StackedBar
          title="By Asset/Market"
          segments={(data?.assetMix ?? []).map(m=>({ label: `${m.market}`, weight: m.weight, tooltip: `${m.market} on ${m.chain} · $${fmtDec(m.usd)}` }))}
        />
      </Stack>
    </Stack>
  );
}
