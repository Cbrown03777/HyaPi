"use client";

// Prompt 3 — Home page refactor to Aave-style hero + KPIs using MUI

import React, { useEffect, useMemo, useState, useCallback } from 'react';
import axios from 'axios';
import { GOV_API_BASE } from '@hyapi/shared';
import { signInWithPi } from '@/lib/pi';
import { fmtNumber as fmtDec, fmtCompact, fmtPercent } from '@/lib/format';
// Using Box/Stack instead of Grid to avoid any local name collisions with strict types
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Box from '@mui/material/Box';
import Skeleton from '@mui/material/Skeleton';
import Stack from '@mui/material/Stack';
import Divider from '@mui/material/Divider';
import SecurityIcon from '@mui/icons-material/Security';
import GavelIcon from '@mui/icons-material/Gavel';
import LanIcon from '@mui/icons-material/Lan';
import AutoGraphIcon from '@mui/icons-material/AutoGraph';
import VisibilityIcon from '@mui/icons-material/Visibility';
import ShieldOutlinedIcon from '@mui/icons-material/ShieldOutlined';
import { useTheme } from '@mui/material/styles';
import Link from 'next/link';

type Portfolio = {
  hyapi_amount: string;
  pps_1e18: string;
  effective_pi_value: string;
};

type AllocSummary = {
  totalUsd?: number;
  totalNetApy?: number;
  totalGrossApy?: number;
  pps?: number;
};

function useBearer() {
  const [token, setToken] = useState<string>('');
  useEffect(() => {
    (async () => {
      try {
        const maybe = await signInWithPi();
        if (typeof maybe === 'string') setToken(maybe);
        else if (maybe && typeof maybe === 'object' && 'accessToken' in maybe)
          // @ts-ignore
          setToken(maybe.accessToken as string);
        else setToken('dev pi_dev_address:1');
      } catch {
        setToken('dev pi_dev_address:1');
      }
    })();
  }, []);
  return token;
}

export default function HomePage() {
  const token = useBearer();
  const theme = useTheme();
  const [portfolio, setPortfolio] = useState<Portfolio | null>(null);
  const [summary, setSummary] = useState<AllocSummary | null>(null);
  const [ema7, setEma7] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [volume30d, setVolume30d] = useState<number | null>(null); // placeholder
  const [usersCount, setUsersCount] = useState<number | null>(null); // placeholder

  const client = useMemo(() => axios.create({ baseURL: GOV_API_BASE, headers: { Authorization: `Bearer ${token}` } }), [token]);

  const loadData = useCallback(async () => {
    if (!token) return;
    setLoading(true);
    try {
      const [pfRes, sumRes, emaRes] = await Promise.allSettled([
        client.get('/v1/portfolio'),
        client.get('/v1/alloc/summary'),
        client.get('/v1/alloc/ema')
      ]);
      if (pfRes.status === 'fulfilled' && pfRes.value.data?.success) setPortfolio(pfRes.value.data.data);
      if (sumRes.status === 'fulfilled' && sumRes.value.data?.success) setSummary(sumRes.value.data.data);
      if (emaRes.status === 'fulfilled' && emaRes.value.data?.success) setEma7(emaRes.value.data.data?.ema7 ?? null);
      // Placeholders (could be replaced by real endpoints later)
      if (process.env.NEXT_PUBLIC_ENABLE_PLACEHOLDERS === '1') {
        setVolume30d(125000); // stub USD volume
        setUsersCount(842); // stub user count
      }
    } finally {
      setLoading(false);
    }
  }, [client, token]);

  useEffect(() => { loadData(); }, [loadData]);

  const tvlPi = portfolio ? Number(portfolio.effective_pi_value) : null;
  const tvlUsd = summary?.totalUsd ?? null;
  const netApy = ema7 ?? summary?.totalNetApy ?? null;
  const avgNetApyDisplay = netApy != null ? fmtPercent(netApy * 100, 2) : '—';
  const tvlPiDisplay = tvlPi != null ? (tvlPi >= 10000 ? fmtCompact(tvlPi) : fmtDec(tvlPi)) + ' Pi' : '—';
  const tvlUsdDisplay = tvlUsd != null ? '$' + (tvlUsd >= 10000 ? fmtCompact(tvlUsd) : fmtDec(tvlUsd)) : '—';
  const volume30dDisplay = volume30d != null ? '$' + (volume30d >= 10000 ? fmtCompact(volume30d) : fmtDec(volume30d)) : '—';
  const usersDisplay = usersCount != null ? (usersCount >= 10000 ? fmtCompact(usersCount) : fmtDec(usersCount)) : '—';

  interface HeroKpiCardProps { label: string; value: React.ReactNode; chip?: string | undefined }
  const HeroKpiCard = ({ label, value, chip }: HeroKpiCardProps) => (
    <Card sx={{ bgcolor: 'background.paper', borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
      <CardContent sx={{ p: 2.5 }}>
        <Typography variant="caption" sx={{ textTransform: 'uppercase', letterSpacing: 0.5, color: 'text.secondary' }}>{label}</Typography>
        <Typography variant="h6" sx={{ mt: 0.5, fontWeight: 600, letterSpacing: '-0.5px', display: 'flex', alignItems: 'center', gap: 1 }}>
          {value}
          {chip && <Chip label={chip} size="small" color="primary" sx={{ fontSize: '0.65rem', height: 20 }} />}
        </Typography>
      </CardContent>
    </Card>
  );

  return (
    <Box sx={{ px: { xs: 2, md: 0 }, py: 4, maxWidth: 1200, mx: 'auto' }}>
      {/* Hero Section */}
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 4 }}>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', gap: 3 }}>
            <Box>
              <Typography variant="overline" sx={{ color: 'primary.light', fontWeight: 600, letterSpacing: '1px' }}>hyaPi</Typography>
              <Typography variant="h3" sx={{ fontWeight: 700, letterSpacing: '-1px', lineHeight: 1.15, mt: 1 }}>
                Governance‑driven yield for Pi holders
              </Typography>
              <Typography variant="body1" sx={{ mt: 2, color: 'text.secondary', maxWidth: 520 }}>
                Aggregate staking across venues with transparent governance, risk guardrails, and on‑chain style allocation history.
              </Typography>
            </Box>
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ width: '100%' }}>
              <Button component={Link} href="/stake" variant="contained" size="large" sx={{ flex: { xs: 1, sm: 'unset' } }} endIcon={<AutoGraphIcon fontSize="small" />}>
                Get Started
              </Button>
              <Button component={Link} href="/portfolio" variant="outlined" size="large" sx={{ flex: { xs: 1, sm: 'unset' }, borderColor: 'rgba(255,255,255,0.15)' }}>
                View Portfolio
              </Button>
            </Stack>
            <Stack direction="row" spacing={2} sx={{ mt: 1, flexWrap: 'wrap' }}>
              <Chip icon={<ShieldOutlinedIcon />} label="Non‑custodial" size="small" variant="outlined" color="primary" />
              <Chip icon={<SecurityIcon />} label="Guardrails" size="small" variant="outlined" />
              <Chip icon={<VisibilityIcon />} label="Transparent" size="small" variant="outlined" />
            </Stack>
          </Box>
  </Box>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Stack spacing={2} sx={{ height: '100%' }}>
            <HeroKpiCard label="TVL (Pi)" value={loading ? <Skeleton width={120} /> : tvlPiDisplay} />
            <HeroKpiCard label="TVL (USD)" value={loading ? <Skeleton width={120} /> : tvlUsdDisplay} />
            <HeroKpiCard label="Avg Net APY" value={loading ? <Skeleton width={80} /> : avgNetApyDisplay} chip={netApy != null ? 'EMA7' : undefined} />
            <HeroKpiCard label="30d Volume" value={loading ? <Skeleton width={100} /> : volume30dDisplay} />
          </Stack>
        </Box>
      </Box>

      {/* KPI Grid Section (4 cards) */}
      <Box sx={{ mt: 4, display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', sm: 'repeat(2,1fr)', md: 'repeat(4,1fr)' } }}>
        <Box>
          <HeroKpiCard label="TVL" value={loading ? <Skeleton width={90} /> : tvlPiDisplay} />
        </Box>
        <Box>
          <HeroKpiCard label="30d Volume" value={loading ? <Skeleton width={90} /> : volume30dDisplay} />
        </Box>
        <Box>
          <HeroKpiCard label="Avg Net APY" value={loading ? <Skeleton width={70} /> : avgNetApyDisplay} chip={netApy != null ? 'Live' : undefined} />
        </Box>
        <Box>
          <HeroKpiCard label="Users" value={loading ? <Skeleton width={50} /> : usersDisplay} />
        </Box>
      </Box>

      {/* Trust / Risk Row */}
      <Box sx={{ mt: 6, display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', md: 'repeat(3,1fr)' } }}>
        <Box>
          <Card sx={{ height: '100%', borderRadius: 3, border: '1px solid', borderColor: 'divider', display: 'flex', flexDirection: 'column' }}>
            <CardContent sx={{ flexGrow: 1 }}>
              <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1 }}>
                <LanIcon fontSize="small" color="primary" />
                <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>Non‑custodial custody path</Typography>
              </Stack>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                Deposit Pi → mint hyaPi 1:1. Underlying staking allocation is transparent; redeem back through the same path.
              </Typography>
            </CardContent>
          </Card>
        </Box>
        <Box>
          <Card sx={{ height: '100%', borderRadius: 3, border: '1px solid', borderColor: 'divider', display: 'flex', flexDirection: 'column' }}>
            <CardContent sx={{ flexGrow: 1 }}>
              <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1 }}>
                <SecurityIcon fontSize="small" color="primary" />
                <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>Guardrails</Typography>
              </Stack>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                Allocation drift limits, buffer thresholds and proposal execution rules enforce disciplined rebalancing.
              </Typography>
            </CardContent>
          </Card>
        </Box>
        <Box>
            <Card sx={{ height: '100%', borderRadius: 3, border: '1px solid', borderColor: 'divider', display: 'flex', flexDirection: 'column' }}>
              <CardContent sx={{ flexGrow: 1 }}>
                <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1 }}>
                  <GavelIcon fontSize="small" color="primary" />
                  <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>Transparent governance</Typography>
                </Stack>
                <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                  Every proposal, vote and executed weight is queryable. Historical net yield is chartable and auditable.
                </Typography>
              </CardContent>
            </Card>
        </Box>
      </Box>

      {/* Personal Portfolio Snapshot (if available) */}
      {portfolio && (
        <Box sx={{ mt: 8 }}>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Your Portfolio</Typography>
          <Box sx={{ display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', sm: 'repeat(3,1fr)' } }}>
            <Box>
              <HeroKpiCard label="hyaPi Balance" value={`${fmtDec(Number(portfolio.hyapi_amount))} hyaPi`} />
            </Box>
            <Box>
              <HeroKpiCard label="Effective Pi" value={tvlPiDisplay} />
            </Box>
            <Box>
              {(() => {
                const pps = Number(portfolio.pps_1e18) / 1e18;
                const growthPct = (pps - 1) * 100;
                return <HeroKpiCard label="Growth vs Pi" value={Number.isFinite(growthPct) ? fmtPercent(growthPct, 2, { sign: true }) : '—'} />;
              })()}
            </Box>
          </Box>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mt: 3 }}>
            <Button component={Link} href="/stake" variant="contained" size="large" sx={{ flex: 1 }}>Stake</Button>
            <Button component={Link} href="/redeem" variant="outlined" size="large" sx={{ flex: 1, borderColor: 'rgba(255,255,255,0.15)' }}>Redeem</Button>
          </Stack>
        </Box>
      )}
    </Box>
  );
}

