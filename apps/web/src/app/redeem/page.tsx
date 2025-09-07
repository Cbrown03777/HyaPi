'use client';
import { useEffect, useRef, useState } from 'react';
import { GOV_API_BASE } from '@hyapi/shared';
import { signInWithPi } from '@/lib/pi';
import { Button } from '@/components/Button';
import { NumberWithSlider } from '@/components/NumberWithSlider';
import { RedeemPreset } from '@/components/RedeemPreset';
import { useToast } from '@/components/ToastProvider';
import { useActivity } from '@/components/ActivityProvider';
import { ActivityPanel } from '@/components/ActivityPanel';
import { fmtNumber, fmtCompact } from '@/lib/format';

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
      if (path === 'instant') {
  const m = `Instant redemption paid (${fmtCompact(amt)} Pi). ID ${r?.id}`
        setMsg(m);
        toast.success(m);
  activity.log({ id: opId, kind: 'redeem', title: `Instant redeem ${fmtCompact(amt)} Pi`, detail: `id ${r?.id}`, status: 'success' });
      } else if (path === 'queued') {
  const m = `Queued redemption created for ${fmtCompact(amt)} Pi. ETA ${r?.eta_ts}`
        setMsg(m);
        toast.warn(m);
  activity.log({ id: opId, kind: 'redeem', title: `Queued redeem ${fmtCompact(amt)} Pi`, detail: `ETA ${r?.eta_ts}`, status: 'pending' });
      } else {
  const m = `Redemption ${r?.id} (${fmtCompact(amt)} Pi) is ${r?.status}`
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
    <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-6">
  <h2 className="text-xl sm:text-2xl font-semibold leading-tight">Redeem hyaPi → Pi</h2>

      {/* Headline stats */}
  {balance != null && (
        <div className="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div className="panel panel-gradient p-3">
            <div className="text-xs text-[var(--text-700)]">Available</div>
            <div className="mt-1 text-lg font-semibold">{fmtNumber(balance)} hyaPi</div>
          </div>
          <div className="panel panel-gradient p-3">
            <div className="text-xs text-[var(--text-700)]">Est. Pi value</div>
            <div className="mt-1 text-lg font-semibold">{fmtNumber(piValue ?? (balance * (pps ?? 1)))} Pi</div>
          </div>
          <div className="panel panel-gradient p-3">
            <div className="text-xs text-[var(--text-700)]">PPS</div>
            <div className="mt-1 text-lg font-semibold">{fmtNumber(pps ?? 1)}</div>
          </div>
        </div>
      )}

      <div className="mt-4 space-y-4">
        {balance != null && (
          <div className="panel panel-gradient p-4">
            <div className="mb-2 text-sm text-[var(--text-700)]">Quick picks</div>
            <RedeemPreset balance={balance} onPick={(v) => setAmt(v)} />
          </div>
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
          <div role="alert" className="text-xs text-[color:var(--danger)]">
            {invalidReason}
          </div>
        )}

        {msg && (
          <div className="rounded-xl2 border border-[rgba(34,216,138,0.35)] bg-[rgba(34,216,138,0.12)] p-3 text-sm">
            {msg}
          </div>
        )}

        <div className="space-y-1">
          <p className="text-sm text-[var(--text-700)]">
            Instant if treasury buffer has liquidity. Otherwise queued (e.g., Cosmos unbonding ~21 days).
          </p>
          {hasLocked && (
            <p className="text-xs text-[color:var(--warn)]">
              Early exit fee applies while a locked stake is active
              {Number.isFinite(feeBps ?? NaN) ? ` (${((feeBps as number) / 100).toFixed(2)}% of amount)` : ''}.
            </p>
          )}
        </div>
      </div>
      <ActivityPanel />

  {/* Sticky footer (mobile-first) */}
  <div id="sticky-actions" className="fixed inset-x-0 bottom-0 z-50 border-t border-white/10 bg-black/60 backdrop-blur sm:static sm:bg-transparent sm:border-0">
        <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-3 flex items-center gap-2">
          <Button
            onClick={submit}
            disabled={busy || !token || !!invalidReason}
            loading={busy}
            className="flex-1"
            aria-label="Redeem"
            rightIcon={<span>⇄</span>}
          >
            Redeem
          </Button>
          <Button
            variant="secondary"
            onClick={() => setShowPreview(true)}
            className="px-3 py-2"
            aria-haspopup="dialog"
            aria-controls="redeem-preview"
            disabled={!!invalidReason}
          >
            Preview
          </Button>
        </div>
      </div>

      {/* Preview modal */}
      {showPreview && (
        <div
          role="dialog"
          id="redeem-preview"
          aria-modal="true"
          className="fixed inset-0 z-40 flex items-end justify-center bg-black/50 p-4 sm:items-center"
          onClick={() => setShowPreview(false)}
        >
          <div ref={dialogRef} className="w-full max-w-md" onClick={(e)=>e.stopPropagation()}>
            <div className="panel panel-gradient p-4">
              <div className="text-sm font-medium">Redeem summary</div>
              <div className="mt-2 space-y-2 text-sm text-white/80">
                <div className="flex justify-between"><span>Amount</span><span className="tabular-nums">{fmtNumber(amt)} Pi</span></div>
                <div className="flex justify-between"><span>Available</span><span className="tabular-nums">{fmtNumber(balance ?? 0)} hyaPi</span></div>
                <div className="text-xs text-white/60">Path depends on buffer liquidity; may be queued.</div>
              </div>
              <div className="mt-3 flex items-center justify-end gap-2">
                <Button className="px-3 py-1.5" variant="secondary" onClick={()=>setShowPreview(false)}>Close</Button>
                <Button className="px-3 py-1.5" onClick={()=>{ setShowPreview(false); submit(); }}>Confirm & Redeem</Button>
              </div>
            </div>
      </div>
      {/* Spacer to prevent bottom content being hidden behind sticky footers on mobile */}
      <div className="h-16 sm:hidden" />
        </div>
      )}
    </div>
  );
}
