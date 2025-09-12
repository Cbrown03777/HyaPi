"use client";
import { useEffect, useRef, useState } from 'react';
import { GOV_API_BASE } from '@hyapi/shared';
import { signInWithPi } from '@/lib/pi';
import { Button as AppButton } from '@/components/Button';
import { NumberWithSlider } from '@/components/NumberWithSlider';
// RedeemPreset removed in favor of MUI ButtonGroup presets
import { useToast } from '@/components/ToastProvider';
import { useActivity } from '@/components/ActivityProvider';
import { ActivityPanel } from '@/components/ActivityPanel';
import { fmtNumber, fmtCompact } from '@/lib/format';
import { ButtonGroup as MuiButtonGroup, Button as MuiButton, Alert, Chip, Box, Card, CardContent, Typography, Stack } from '@mui/material';

export default function RedeemPage() {
  const [token, setToken] = useState<string>('');
  const [amt, setAmt] = useState<number>(20);
  const [balance, setBalance] = useState<number | null>(null);
  const [piValue, setPiValue] = useState<number | null>(null);
  const [pps, setPps] = useState<number | null>(null);
  const [msg, setMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const toast = useToast();
  const activity = useActivity();
  const dialogRef = useRef<HTMLDivElement | null>(null);
  const [hasLocked, setHasLocked] = useState<boolean | null>(null);
  const [feeBps, setFeeBps] = useState<number | null>(null);
  const [redeemPath, setRedeemPath] = useState<"instant" | "queued" | "other" | null>(null);
  const [etaTs, setEtaTs] = useState<number | null>(null);

  useEffect(() => {
    (async () => {
      const maybe = await signInWithPi();
      const t = typeof maybe === 'string' ? maybe : (maybe as any)?.accessToken ?? '';
      setToken(t);
  if (t) (globalThis as any).hyapiBearer = t;
      // Try to fetch current balance for presets (optional)
      try {
        const res = await fetch(`${GOV_API_BASE}/v1/portfolio`, {
          headers: { Authorization: `Bearer ${t}` },
        });
        const j = await res.json();
        if (res.ok && j?.success) {
          const b = Number(j.data?.hyapi_amount ?? '0');
          if (Number.isFinite(b)) setBalance(b);
          const ev = Number(j.data?.effective_pi_value ?? '0');
          if (Number.isFinite(ev)) setPiValue(ev);
          const p = Number(j.data?.pps_1e18 ?? '1000000000000000000') / 1e18;
          if (Number.isFinite(p)) setPps(p);
          if (typeof j.data?.has_locked_active === 'boolean') setHasLocked(j.data.has_locked_active);
          if (Number.isFinite(Number(j.data?.early_exit_fee_bps))) setFeeBps(Number(j.data.early_exit_fee_bps));
        }
      } catch {}
    })();
  }, []);

  async function submit() {
    setMsg(null);
    setBusy(true);
  const opId = crypto.randomUUID();
  activity.log({ id: opId, kind: 'redeem', title: `Redeeming ${fmtCompact(amt)} Pi`, status: 'in-flight' });
    try {
      const res = await fetch(`${GOV_API_BASE}/v1/stake/redeem`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Idempotency-Key': crypto.randomUUID(),
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ amountPi: amt }),
      });
  if (res.status >= 500) toast.error('Network error. Please try again.');
  const j = await res.json();
  if (!res.ok || j?.success === false) throw new Error(j?.error?.message || 'Redeem failed');
      const r = j.data?.redemption;
      const path = j.data?.path as 'instant' | 'queued' | undefined;
      setRedeemPath(path ?? 'other');
      if (typeof r?.eta_ts === 'number') setEtaTs(r.eta_ts);
      if (path === 'instant') {
        const m = `Instant redemption paid (${fmtCompact(amt)} Pi). ID ${r?.id}`;
        setMsg(m);
        toast.success(m);
        activity.log({ id: opId, kind: 'redeem', title: `Instant redeem ${fmtCompact(amt)} Pi`, detail: `id ${r?.id}`, status: 'success' });
      } else if (path === 'queued') {
        const m = `Queued redemption created for ${fmtCompact(amt)} Pi. ETA ${r?.eta_ts}`;
        setMsg(m);
        toast.warn(m);
        activity.log({ id: opId, kind: 'redeem', title: `Queued redeem ${fmtCompact(amt)} Pi`, detail: `ETA ${r?.eta_ts}`, status: 'pending' });
      } else {
        const m = `Redemption ${r?.id} (${fmtCompact(amt)} Pi) is ${r?.status}`;
        setMsg(m);
        toast.info(m);
        activity.log({ id: opId, kind: 'redeem', title: `Redeem ${fmtCompact(amt)} Pi`, detail: `${r?.status}`, status: 'success' });
      }
    } catch (e: any) {
  const m = `❌ ${e.message}`
  setMsg(m);
  toast.error(m);
  activity.log({ id: opId, kind: 'redeem', title: 'Redeem failed', detail: e.message, status: 'error' });
    } finally {
      setBusy(false);
    }
  }

  const invalidReason = !Number.isFinite(amt) || amt <= 0
    ? 'Enter an amount greater than 0'
    : balance != null && amt > balance
    ? 'Amount exceeds available balance'
    : '';

  // Focus trap for preview modal
  useEffect(() => {
    if (!showPreview) return;
    const root = dialogRef.current;
    if (!root) return;
    const selectors = 'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])';
    const focusables = Array.from(root.querySelectorAll<HTMLElement>(selectors)).filter(el => !el.hasAttribute('disabled'));
    const first = focusables[0];
    const last = focusables[focusables.length - 1];
    first?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        setShowPreview(false);
      } else if (e.key === 'Tab' && focusables.length) {
        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last?.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first?.focus();
        }
      }
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [showPreview]);

  return (
    <Box>
  <Typography variant="h5" fontWeight={600}>Redeem hyaPi → Pi</Typography>

      {/* Headline stats */}
  {balance != null && (
        <Box sx={{ mt: 2, display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', sm: 'repeat(3,1fr)' } }}>
          <Card variant="outlined" sx={{ background: 'linear-gradient(145deg, rgba(255,255,255,0.03), rgba(255,255,255,0.08))' }}>
            <CardContent sx={{ py: 1.5 }}>
              <Typography variant="caption" color="text.secondary">Available</Typography>
              <Typography variant="subtitle1" fontWeight={600}>{fmtNumber(balance)} hyaPi</Typography>
            </CardContent>
          </Card>
          <Card variant="outlined" sx={{ background: 'linear-gradient(145deg, rgba(255,255,255,0.03), rgba(255,255,255,0.08))' }}>
            <CardContent sx={{ py: 1.5 }}>
              <Typography variant="caption" color="text.secondary">Est. Pi value</Typography>
              <Typography variant="subtitle1" fontWeight={600}>{fmtNumber(piValue ?? (balance * (pps ?? 1)))} Pi</Typography>
            </CardContent>
          </Card>
          <Card variant="outlined" sx={{ background: 'linear-gradient(145deg, rgba(255,255,255,0.03), rgba(255,255,255,0.08))' }}>
            <CardContent sx={{ py: 1.5 }}>
              <Typography variant="caption" color="text.secondary">PPS</Typography>
              <Typography variant="subtitle1" fontWeight={600}>{fmtNumber(pps ?? 1)}</Typography>
            </CardContent>
          </Card>
        </Box>
      )}

      <Stack spacing={3} sx={{ mt: 4 }}>
        {balance != null && (
          <Card variant="outlined" sx={{ background: 'linear-gradient(145deg, rgba(255,255,255,0.03), rgba(255,255,255,0.08))' }}>
            <CardContent sx={{ pt: 2 }}>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }} id="preset-label">Quick picks</Typography>
            <MuiButtonGroup variant="outlined" size="small" aria-labelledby="preset-label" aria-label="Quick amount presets 25 50 75 100 percent">
              {[25,50,75,100].map(p => (
                <MuiButton key={p} onClick={() => setAmt(Number((balance * (p/100)).toFixed(6)))} aria-label={`Set amount to ${p}% of balance`}>
                  {p}%
                </MuiButton>
              ))}
            </MuiButtonGroup>
            </CardContent>
          </Card>
        )}

        <NumberWithSlider
          label="Amount (Pi)"
          value={amt}
          onChange={setAmt}
          min={0}
          max={Math.max(100, balance ?? 100)}
          step={0.000001}
          {...(balance != null ? { balance } : {})}
        />
        {invalidReason && (
          <Typography role="alert" variant="caption" color="error.main">{invalidReason}</Typography>
        )}

        {msg && (
          <Alert
            severity={redeemPath === 'instant' ? 'success' : redeemPath === 'queued' ? 'info' : msg.startsWith('❌') ? 'error' : 'warning'}
            variant="outlined"
            sx={{ fontSize: 13 }}
            role="status"
          >
            {msg}
          </Alert>
        )}

        <Box>
          <Typography variant="body2" color="text.secondary">
            Instant if treasury buffer has liquidity. Otherwise queued (e.g., Cosmos unbonding ~21 days).
          </Typography>
          {hasLocked && (
            <Typography variant="caption" color="warning.main" display="block" sx={{ mt: 0.5 }}>
              Early exit fee applies while a locked stake is active
              {Number.isFinite(feeBps ?? NaN) ? ` (${((feeBps as number) / 100).toFixed(2)}% of amount)` : ''}.
            </Typography>
          )}
          <Stack direction="row" flexWrap="wrap" spacing={1} useFlexGap sx={{ mt: 1 }} aria-label="Redemption status chips">
            {redeemPath === 'instant' && <Chip size="small" color="success" label="Instant buffer" aria-label="Instant buffer redemption" />}
            {redeemPath === 'queued' && <Chip size="small" color="info" label="Queued" aria-label="Queued redemption" />}
            {redeemPath === 'queued' && etaTs && <Chip size="small" variant="outlined" label={`ETA ${new Date(etaTs*1000).toLocaleDateString()}`} aria-label={`Estimated completion date ${new Date(etaTs*1000).toLocaleDateString()}`} />}
            {hasLocked && Number.isFinite(feeBps ?? NaN) && <Chip size="small" variant="outlined" label={`Fee ${(feeBps as number / 100).toFixed(2)}%`} aria-label={`Early exit fee ${(feeBps as number / 100).toFixed(2)} percent`} />}
          </Stack>
        </Box>
      </Stack>
      <ActivityPanel />

  {/* Sticky footer (mobile-first) */}
  <Box id="sticky-actions" sx={{ position: { xs: 'fixed', sm: 'static' }, left: 0, right: 0, bottom: 0, zIndex: 50, borderTop: { xs: '1px solid rgba(255,255,255,0.1)', sm: 'none' }, bgcolor: { xs: 'rgba(0,0,0,0.6)', sm: 'transparent' }, backdropFilter: { xs: 'blur(10px)', sm: 'none' } }}>
        <Box sx={{ mx: 'auto', maxWidth: 'lg', px: { xs: 2, sm: 3 }, py: 2, display: 'flex', alignItems: 'center', gap: 2 }}>
          <AppButton
            onClick={submit}
            disabled={busy || !token || !!invalidReason}
            loading={busy}
            sx={{ flex: 1 }}
            aria-label="Redeem"
            rightIcon={<span>⇄</span>}
          >
            Redeem
          </AppButton>
          <AppButton
            variant="secondary"
            onClick={() => setShowPreview(true)}
            sx={{ px: 1.5, py: 1 }}
            aria-haspopup="dialog"
            aria-controls="redeem-preview"
            disabled={!!invalidReason}
          >
            Preview
          </AppButton>
        </Box>
      </Box>

      {/* Preview modal */}
      {showPreview && (
        <Box
          role="dialog"
          id="redeem-preview"
          aria-modal="true"
          onClick={() => setShowPreview(false)}
          sx={{ position: 'fixed', inset: 0, zIndex: 40, display: 'flex', alignItems: { xs: 'flex-end', sm: 'center' }, justifyContent: 'center', p: 2, bgcolor: 'rgba(0,0,0,0.5)' }}
        >
          <Box ref={dialogRef} onClick={(e)=>e.stopPropagation()} sx={{ width: '100%', maxWidth: 420 }}>
            <Card variant="outlined" sx={{ background: 'linear-gradient(145deg, rgba(255,255,255,0.07), rgba(255,255,255,0.15))' }}>
              <CardContent>
                <Typography variant="subtitle2" fontWeight={600}>Redeem summary</Typography>
                <Stack spacing={1} sx={{ mt: 2, fontSize: 14, color: 'rgba(255,255,255,0.8)' }}>
                  <Stack direction="row" justifyContent="space-between"><span>Amount</span><span>{fmtNumber(amt)} Pi</span></Stack>
                  <Stack direction="row" justifyContent="space-between" sx={{ fontVariantNumeric:'tabular-nums' }}>
                    <span>Available</span>
                    <span>{fmtNumber(balance ?? 0)} hyaPi</span>
                  </Stack>
                  <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.6)' }}>Path depends on buffer liquidity; may be queued.</Typography>
                </Stack>
                <Stack direction="row" spacing={1} justifyContent="flex-end" sx={{ mt: 3 }}>
                  <AppButton sx={{ px: 1.5, py: 0.75 }} variant="secondary" onClick={()=>setShowPreview(false)}>Close</AppButton>
                  <AppButton sx={{ px: 1.5, py: 0.75 }} onClick={()=>{ setShowPreview(false); submit(); }}>Confirm & Redeem</AppButton>
                </Stack>
              </CardContent>
            </Card>
      <Box sx={{ height: 64, display: { xs: 'block', sm: 'none' } }} />
          </Box>
        </Box>
      )}
    </Box>
  );
}
