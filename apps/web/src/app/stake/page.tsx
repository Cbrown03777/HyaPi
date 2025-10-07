"use client";
import { useEffect, useState } from 'react';
import { GOV_API_BASE } from '@hyapi/shared';
import axios from 'axios';
import { signInWithPi, startDeposit, waitForPiSDK, isPiBrowser, piLogin } from '@/lib/pi';
import { useToast } from '@/components/ToastProvider';
import { useActivity } from '@/components/ActivityProvider';
import { ActivityPanel } from '@/components/ActivityPanel';
import { fmtNumber, fmtCompact, fmtPercent } from '@/lib/format';
import { fetchPortfolioMetrics } from '@/lib/metrics';
import {
  Box,
  Card,
  CardHeader,
  CardContent,
  Typography,
  TextField,
  Slider,
  ToggleButtonGroup,
  ToggleButton,
  Switch,
  FormControlLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Alert,
  Stack,
  Divider,
  Paper,
  Tooltip,
  Chip,
  Skeleton
} from '@mui/material';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
// No need to fetch boost config for ranges; use local rules per product spec.

// Stake Page (MUI refactor)

export default function StakePage() {
  // State
  const [token, setToken] = useState('');
  // User-entered stake amount (string to allow empty state)
  const [amount, setAmount] = useState<string>('');
  const [weeks, setWeeks] = useState(0);
  const [baseNetApy, setBaseNetApy] = useState(0); // decimal
  const [baseGrossApy, setBaseGrossApy] = useState(0);
  const [emaNetApy, setEmaNetApy] = useState<number | null>(null);
  const [showGross, setShowGross] = useState<boolean>(() => (typeof window !== 'undefined' && localStorage.getItem('stakeShowGross') === '1'));
  const [lockCurve, setLockCurve] = useState<Array<{ weeks: number; share: number }>>([]);
  const [msg, setMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);
  const [balance, setBalance] = useState<number>(0);
  interface PiUser { uid: string; username?: string }
  const [piUser, setPiUser] = useState<PiUser | null>(null);
  const [authLoading, setAuthLoading] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);
  const [authDiag, setAuthDiag] = useState<any>(null);
  const [piInitState, setPiInitState] = useState<'idle'|'waiting'|'ready'|'failed'>('idle');
  // Metrics KPI (7-day EMA APY)
  const [apy7d, setApy7d] = useState<number | null>(null);
  const [metricsLoading, setMetricsLoading] = useState(true);
  const [metricsErr, setMetricsErr] = useState<string | null>(null);
  const toast = useToast();
  const activity = useActivity();
  // Voting boost by lockup duration (affects voting power only; APY unchanged)
  function computeBoostPctByWeeks(w: number): number {
    if (w >= 104) return 0.50;      // 104 weeks → +50%
    if (w >= 52) return 0.35;       // 52–103 weeks → +35%
    if (w >= 26) return 0.20;       // 26–51 weeks → +20%
    return 0.0;                     // <26 weeks → no boost
  }
  const selectedBoostPct = computeBoostPctByWeeks(weeks);

  // Load auth, balances, APYs, curve
  useEffect(() => {
    (async () => {
      setPiInitState('waiting');
      try {
        await waitForPiSDK({ timeoutMs: 6000 });
        setPiInitState('ready');
      } catch {
        setPiInitState('failed');
      }
      // Fetch balance (optional)
      try {
        if (token) {
          const res1 = await fetch(`${GOV_API_BASE}/v1/wallet/balance`, { headers: { Authorization: `Bearer ${token}` } });
        if (res1.ok) {
          const j1 = await res1.json();
          const raw = (j1?.data?.pi_balance ?? j1?.data?.balance ?? j1?.pi_balance ?? j1?.balance);
          const v = typeof raw === 'string' ? Number(raw) : typeof raw === 'number' ? raw : NaN;
          if (Number.isFinite(v) && v >= 0) setBalance(v);
        }
        }
      } catch { /* silent */ }
      // Fetch allocation summary + lock curve
      try {
  if (!token) return;
  const client = axios.create({ baseURL: GOV_API_BASE, headers: { Authorization: `Bearer ${token}` } });
        const [sumRes] = await Promise.allSettled([
          client.get('/v1/alloc/summary')
        ]);
        // Fetch EMA separately so we can display same net APY as home
        try { const emaRes = await client.get('/v1/alloc/ema'); if (emaRes?.data?.success) setEmaNetApy(emaRes.data.data?.ema7 ?? emaRes.data.data?.latest ?? null); } catch {}
        if (sumRes.status === 'fulfilled' && sumRes.value.data?.success) {
          setBaseNetApy(sumRes.value.data.data?.totalNetApy || 0);
          setBaseGrossApy(sumRes.value.data.data?.totalGrossApy || 0);
        }
        // per-user APY scaling removed: ignore lock curve
      } catch { /* silent */ }
      // Fetch portfolio metrics for 7-day EMA APY (Home parity)
      try {
        setMetricsLoading(true);
  const m = await fetchPortfolioMetrics();
        setApy7d(m.apy7d ?? null);
      } catch (e:any) {
        setMetricsErr(e?.message || 'Failed to load');
      } finally {
        setMetricsLoading(false);
      }
    })();
  }, [token]);

  // lock share curve from server (piecewise step) with fallback defaults if absent yet
  const baseDisplayed = showGross ? baseGrossApy : baseNetApy;
  // Per-user APY scaling removed: APY is protocol-wide only
  const userScaledApy = baseDisplayed;
  const baselineApy = baseDisplayed;
  // Platform Net APY (smoothed to match Home when available)
  // Use portfolio metrics apy7d (EMA7) as single source of truth; fallback to emaNetApy/summary
  const platformNetApy = (apy7d != null ? apy7d : (emaNetApy ?? baseNetApy)); // decimal

  async function submit() {
    setMsg(null);
    setBusy(true);
    const opId = crypto.randomUUID();
  activity.log({ id: opId, kind: 'stake', title: `Staking ${fmtCompact(numericAmt)} Pi`, detail: `lock ${weeks}w`, status: 'in-flight' });
    try {
      const Pi = (globalThis as any).Pi;
      if (Pi && token && !token.startsWith('dev ')) {
  const paymentData = { amount: numericAmt, memo: 'HyaPi stake deposit', metadata: { lockupWeeks: weeks } };
        const callbacks = {
          onReadyForServerApproval: async (paymentId: string) => {
            await fetch(`${GOV_API_BASE}/v1/pi/approve/${paymentId}`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } });
          },
          onReadyForServerCompletion: async (paymentId: string, txid: string) => {
            await fetch(`${GOV_API_BASE}/v1/pi/complete/${paymentId}`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
              body: JSON.stringify({ txid })
            });
          },
          onCancel: (paymentId: string) => console.log('payment canceled', paymentId),
          onError: (error: any, paymentId: string) => console.error('payment error', error, paymentId),
        };
        await Pi.createPayment(paymentData, callbacks);
        const m = `Payment submitted. You'll see your stake after completion.`;
        setMsg(m);
        toast.success(m);
  activity.log({ id: opId, kind: 'stake', title: `Payment started ${fmtCompact(numericAmt)} Pi`, detail: `lock ${weeks}w`, status: 'success' });
      } else {
        const res = await fetch(`${GOV_API_BASE}/v1/stake/deposit`, {
          method: 'POST',
            headers: {
            'Content-Type': 'application/json',
            'Idempotency-Key': crypto.randomUUID(),
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ amountPi: numericAmt, lockupWeeks: weeks }),
        });
        if (res.status >= 500) toast.error('Network error. Please try again.');
        const j = await res.json();
        if (!res.ok || j?.success === false) throw new Error(j?.error?.message || 'Stake failed');
  const m = `Staked ${fmtCompact(numericAmt)} Pi (lock ${weeks}w). Stake id: ${j.data?.stake?.id}`;
        setMsg(m);
        toast.success(m);
  activity.log({ id: opId, kind: 'stake', title: `Staked ${fmtCompact(numericAmt)} Pi`, detail: `lock ${weeks}w`, status: 'success' });
      }
    } catch (e: any) {
      const m = e.message ? `Error: ${e.message}` : 'Stake failed';
      setMsg(m);
      toast.error(m);
      activity.log({ id: opId, kind: 'stake', title: 'Stake failed', detail: e.message, status: 'error' });
    } finally {
      setBusy(false);
    }
  }

  // simple client-side estimate: linear APY pro-rated by weeks; hyaPi minted 1:1 + yield
  // For now protocol APY equals platform net APY (no per-user scaling in current model)
  const apy = platformNetApy; // decimal
  const numericAmt = Number(amount || '0');
  const estFinal = numericAmt * (1 + apy * (weeks / 52));
  const invalidReason = !Number.isFinite(numericAmt) || numericAmt <= 0
    ? 'Enter an amount greater than 0'
    : (balance > 0 && numericAmt > balance)
      ? 'Amount exceeds available balance'
      : '';

  const lockMarks = [
    { value: 0, label: '0w' },
    { value: 26, label: '26w' },
    { value: 52, label: '52w' },
    { value: 104, label: '104w' }
  ];

  const quickPercents = [25, 50, 75, 100];

  async function handleLogin() {
    setAuthError(null); setAuthDiag(null); setAuthLoading(true);
    try {
      const { uid, accessToken, username } = await piLogin();
      setToken(accessToken); setPiUser({ uid, username } as PiUser); (globalThis as any).hyapiBearer = accessToken;
    } catch (e:any) {
      setAuthError(e?.message || 'Login failed');
      const dbg = (typeof window !== 'undefined' ? (window as any).__piDebug?.lastAuthCall : null);
      const base = e?.diag || {};
      setAuthDiag(dbg ? { ...base, lastAuthCall: dbg } : (Object.keys(base).length ? base : null));
    } finally { setAuthLoading(false); }
  }

  async function submitStake() {
    if (!piUser || !token || invalidReason) return;
    setBusy(true); setMsg(null);
    const opId = crypto.randomUUID();
    activity.log({ id: opId, kind: 'stake', title: `Staking ${fmtCompact(numericAmt)} Pi`, detail: `lock ${weeks}w`, status: 'in-flight' });
    try {
      await startDeposit(numericAmt, token, 'HyaPi stake deposit', { lockupWeeks: weeks });
      const m = `Payment submitted. You'll see your stake after completion.`;
      setMsg(m);
      toast.success(m);
      activity.log({ id: opId, kind: 'stake', title: `Payment started ${fmtCompact(numericAmt)} Pi`, detail: `lock ${weeks}w`, status: 'success' });
    } catch (e:any) {
      const m = e?.message ? `Error: ${e.message}` : 'Stake failed';
      setMsg(m); toast.error(m);
      activity.log({ id: opId, kind: 'stake', title: 'Stake failed', detail: e?.message, status: 'error' });
    } finally { setBusy(false); }
  }

  return (
    <Box maxWidth="lg" mx="auto" px={{ xs: 2, sm: 4 }} py={4}>
      <Typography variant="h5" fontWeight={600} gutterBottom>
        Stake Pi → receive hyaPi (1:1)
      </Typography>
      {piUser && (
        <Typography variant="caption" sx={{ display:'block', mb:2, color:'text.secondary' }}>Signed in: UID {piUser.uid}{piUser.username? ` (@${piUser.username})`:''}</Typography>
      )}

      {/* 7-day EMA APY KPI */}
      <Box mb={3}>
        <Card variant="outlined" sx={{ maxWidth: 360 }}>
          <CardContent>
            <Typography variant="overline" sx={{ color: 'text.secondary' }}>7-day APY (EMA)</Typography>
            {metricsLoading ? (
              <Typography variant="h4" sx={{ fontWeight:700, lineHeight:1 }}><span style={{display:'inline-block',width:140}}><Skeleton variant="text" height={42} /></span></Typography>
            ) : metricsErr ? (
              <Typography variant="body2" color="error">{metricsErr}</Typography>
            ) : (
              <Typography variant="h4" sx={{ fontWeight:700 }}>
                {apy7d != null ? fmtPercent(apy7d * 100, 2) : '—'}
              </Typography>
            )}
            <Typography variant="caption" sx={{ color:'text.secondary', display:'block', mt:0.5 }}>
              Based on recent PPS changes (EMA7). Updates daily.
            </Typography>
          </CardContent>
        </Card>
      </Box>

      {!piUser && (
        <Card sx={{ maxWidth:420, mb:4 }} variant="outlined">
          <CardHeader title="Connect your Pi Wallet" subheader="Log in to stake Pi and start earning yield." />
          <CardContent>
            <Stack spacing={2}>
              {piInitState === 'waiting' && <Typography variant="caption" sx={{ opacity:0.7 }}>Initializing Pi…</Typography>}
              {piInitState === 'failed' && (
                <Typography variant="caption" color="warning.main">Pi SDK not detected. Open in Pi Browser and ensure the exact domain is whitelisted.</Typography>
              )}
              <Button variant="contained" onClick={handleLogin} disabled={authLoading || piInitState==='waiting'}>{authLoading? 'Connecting…':'Log in with Pi'}</Button>
              {authError && (
                <Box>
                  <Typography variant="caption" color="error">{authError}</Typography>
                  {authDiag && (
                    <Box mt={1} sx={{ border:'1px dashed', borderColor:'divider', p:1, borderRadius:1, maxHeight:220, overflow:'auto' }}>
                      <Typography variant="caption" sx={{ fontWeight:600, display:'block', mb:0.5 }}>Diagnostics</Typography>
                      <Typography component="pre" variant="caption" sx={{ whiteSpace:'pre-wrap', wordBreak:'break-word', fontFamily:'monospace', fontSize:10, m:0 }}>
                        {JSON.stringify(authDiag, null, 2)}
                      </Typography>
                    </Box>
                  )}
                </Box>
              )}
              <Typography variant="caption" sx={{ opacity:0.45 }}>Pi Browser UA match: {isPiBrowser() ? 'yes':'no'} (non-blocking)</Typography>
              <Typography variant="caption" sx={{ opacity:0.45 }}>Auth uses detected Pi SDK only; UA is informational.</Typography>
            </Stack>
          </CardContent>
        </Card>
      )}

      {piUser && (
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={3} mt={1} alignItems="stretch">
        {/* Amount Card */}
        <Card sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          <CardHeader title="Amount to stake" subheader={`Available: ${fmtNumber(balance, 2)} Pi`} />
          <CardContent>
            <Stack spacing={2}>
              <TextField
                label="Amount (Pi)"
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                inputProps={{ min: 0, step: 0.000001 }}
                fullWidth
              />
              <Slider
                aria-label="Amount slider"
                value={numericAmt > balance ? balance : numericAmt}
                onChange={(_, v) => typeof v === 'number' && setAmount(String(Number(v.toFixed(6))))}
                min={0}
                max={balance || 1}
                step={balance / 200 || 0.5}
                valueLabelDisplay="auto"
              />
              <ToggleButtonGroup
                size="small"
                exclusive={false}
                aria-label="Quick amount presets"
                sx={{ flexWrap: 'wrap' }}
              >
                {quickPercents.map(p => (
                  <ToggleButton key={p} value={p} aria-label={`${p}%`} onClick={() => setAmount(Number((balance * (p / 100)).toFixed(6)).toString())}>
                    {p}%
                  </ToggleButton>
                ))}
              </ToggleButtonGroup>
              {invalidReason && <Alert severity="warning" variant="outlined" sx={{ fontSize: 12 }}>{invalidReason}</Alert>}
            </Stack>
          </CardContent>
        </Card>

        {/* Lockup Card */}
        <Card sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          <CardHeader
            title="Lockup duration & APY"
            action={
              <Tooltip
                title={
                  <Box sx={{ fontSize: 12, lineHeight: 1.3 }}>
                    APY is global and not affected by lock length. Early exit before expiry incurs 1% principal fee. No‑lock deposits charged 0.5% entry fee.
                  </Box>
                }
                placement="top"
                arrow
              >
                <InfoOutlinedIcon fontSize="small" sx={{ opacity: 0.7 }} />
              </Tooltip>
            }
          />
          <CardContent>
            <Stack spacing={2}>
              <Box>
                <Slider
                  aria-label="Lockup weeks"
                  value={weeks}
                  onChange={(_, v) => typeof v === 'number' && setWeeks(v)}
                  min={0}
                  max={104}
                  step={1}
                  marks={lockMarks}
                  valueLabelDisplay="auto"
                />
              </Box>
              <Paper variant="outlined" sx={{ p: 1.5, background: 'transparent' }}>
                <Stack spacing={0.5} fontSize={14}>
                  <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
                    <Typography variant="body2">Platform Net APY:</Typography>
                    <Typography fontWeight={600} fontSize={14}>{(platformNetApy * 100).toFixed(2)}%</Typography>
                    {apy7d != null && <Chip size="small" label="EMA7" variant="outlined" sx={{ height: 18, fontSize: 10 }} />}
                  </Box>
                  <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
                    <Typography variant="body2">Base {showGross ? 'Gross' : 'Net'} Platform APY:</Typography>
                    <Typography fontWeight={600} fontSize={14}>{baseDisplayed ? (baseDisplayed * 100).toFixed(2) + '%' : '—'}</Typography>
                    {!showGross && <Chip size="small" label="net" variant="outlined" sx={{ height: 18, fontSize: 10 }} />}
                    <FormControlLabel
                      sx={{ ml: 'auto' }}
                      control={<Switch size="small" checked={showGross} onChange={(e) => { const v = e.target.checked; setShowGross(v); if (typeof window !== 'undefined') localStorage.setItem('stakeShowGross', v ? '1' : '0'); }} />}
                      label={<Typography variant="caption">gross</Typography>}
                    />
                  </Box>
                  <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
                    <Typography variant="body2">Protocol {showGross ? 'Gross' : 'Net'} APY:</Typography>
                    <Typography fontWeight={600} fontSize={14}>{(apy * 100).toFixed(2)}%</Typography>
                  </Box>
                  <Box display="flex" alignItems="center" gap={1} flexWrap="wrap">
                    <Typography variant="body2">Governance voting boost (for {weeks}‑week lock):</Typography>
                    <Chip size="small" color={selectedBoostPct>0? 'secondary':'default'} label={`Boost +${Math.round(selectedBoostPct * 100)}%`} sx={{ height: 20 }} />
                    <Typography variant="caption" sx={{ opacity: 0.7 }}>(affects voting power only; APY unchanged)</Typography>
                  </Box>
                  <Typography variant="caption" sx={{ opacity: 0.65 }}>
                    Early exit before expiry incurs 1% principal fee. No‑lock deposits charged 0.5% upfront entry fee.
                  </Typography>
                </Stack>
              </Paper>
              <Typography variant="body2">Est. hyaPi after period: <b>{fmtNumber(estFinal)}</b></Typography>
            </Stack>
          </CardContent>
        </Card>
      </Stack>
      )}

      {msg && (
        <Alert severity={msg.startsWith('Error') ? 'error' : 'success'} sx={{ mt: 2 }} variant="outlined">{msg}</Alert>
      )}

      <Box mt={3}>
        <ActivityPanel />
      </Box>

      {/* Sticky actions for mobile */}
      {piUser && (
      <Paper
        elevation={3}
        sx={{
          position: { xs: 'fixed', sm: 'static' },
          bottom: { xs: 0, sm: 'auto' },
          left: 0,
          right: 0,
          borderTop: { xs: '1px solid', sm: 'none' },
          borderColor: 'divider',
          backdropFilter: { xs: 'blur(8px)', sm: 'none' },
          background: { xs: 'rgba(0,0,0,0.6)', sm: 'transparent' },
          px: { xs: 2, sm: 0 },
          py: 1.5,
          mt: { sm: 3 },
          zIndex: 40
        }}
      >
        <Stack direction="row" spacing={2} alignItems="center">
          <Button
            variant="contained"
            fullWidth
            disabled={busy || !piUser || !!invalidReason}
            onClick={submitStake}
          >
            {busy ? 'Submitting…' : 'Stake'}
          </Button>
          <Button
            variant="outlined"
            disabled={!!invalidReason}
            onClick={() => setPreviewOpen(true)}
          >
            Preview
          </Button>
        </Stack>
      </Paper>
      )}
      {piUser && <Box height={64} display={{ xs: 'block', sm: 'none' }} />}

      {/* Preview Dialog */}
      <Dialog open={previewOpen && !!piUser} onClose={() => setPreviewOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Stake summary</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={1} fontSize={14}>
            <Stack direction="row" justifyContent="space-between"><span>Amount</span><span>{fmtNumber(numericAmt)} Pi</span></Stack>
            <Stack direction="row" justifyContent="space-between"><span>Lockup</span><span>{weeks} weeks</span></Stack>
            <Stack direction="row" justifyContent="space-between"><span>Protocol {showGross ? 'Gross' : 'Net'} APY</span><span>{baseDisplayed ? (baseDisplayed * 100).toFixed(2) + '%' : '—'}</span></Stack>
            <Stack direction="row" justifyContent="space-between"><span>Effective APY</span><span>{(apy * 100).toFixed(2)}%</span></Stack>
            <Stack direction="row" justifyContent="space-between"><span>Early Exit Fee</span><span>1%</span></Stack>
            {weeks === 0 && (
              <Stack direction="row" justifyContent="space-between"><span>Entry Fee</span><span>0.5%</span></Stack>
            )}
            <Stack direction="row" justifyContent="space-between"><span>Est. hyaPi after period</span><span>{fmtNumber(estFinal)}</span></Stack>
            <Stack direction="row" justifyContent="space-between"><span>Governance voting boost</span><span>+{Math.round(selectedBoostPct * 100)}%</span></Stack>
            {!((globalThis as any).Pi) && (
              <Alert severity="info" variant="outlined" sx={{ mt: 1 }}>
                Open in Pi Browser to complete a real Testnet payment. In local dev we simulate the deposit.
              </Alert>
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button variant="outlined" onClick={() => setPreviewOpen(false)}>Close</Button>
          <Button variant="contained" onClick={() => { setPreviewOpen(false); submitStake(); }} disabled={busy || !!invalidReason}>Confirm & Stake</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
