'use client';
import { useEffect, useRef, useState } from 'react';
import { GOV_API_BASE } from '@hyapi/shared';
import { signInWithPi } from '@/lib/pi';
import { Button } from '@/components/Button';
import { NumberWithSlider } from '@/components/NumberWithSlider';
import { LockupSlider } from '@/components/LockupSlider';
import { useToast } from '@/components/ToastProvider';
import { useActivity } from '@/components/ActivityProvider';
import { ActivityPanel } from '@/components/ActivityPanel';
import { Card } from '@/components/ui/Card';
import { fmtNumber, fmtCompact } from '@/lib/format';
import axios from 'axios';
import { fmtPercent } from '@/lib/format';

export default function StakePage() {
  const [token, setToken] = useState<string>('');
  const [amt, setAmt] = useState<number>(100);
  const [weeks, setWeeks] = useState<number>(0);
  // dynamic APY base fetched from allocation summary (net & gross)
  const [baseNetApy, setBaseNetApy] = useState<number>(0); // decimal
  const [baseGrossApy, setBaseGrossApy] = useState<number>(0);
  const [showGross, setShowGross] = useState(false);
  const [lockCurve, setLockCurve] = useState<Array<{ weeks:number; share:number }>>([]);
  const [apyBps, setApyBps] = useState<number>(500); // derived for backward compatibility
  const [msg, setMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [balance, setBalance] = useState<number>(1000); // will update from API when available
  const toast = useToast();
  const activity = useActivity();
  const dialogRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    (async () => {
      const maybe = await signInWithPi();
      setToken(typeof maybe === 'string' ? maybe : (maybe as any)?.accessToken ?? '');
  const t = typeof maybe === 'string' ? maybe : (maybe as any)?.accessToken ?? '';
  if (t) (globalThis as any).hyapiBearer = t;
      // Try to fetch available Pi balance (optional; backend may not expose yet)
      try {
        // Preferred endpoint if/when available
        const res1 = await fetch(`${GOV_API_BASE}/v1/wallet/balance`, { headers: { Authorization: `Bearer ${t}` } });
        if (res1.ok) {
          const j1 = await res1.json();
          const b1 = (j1?.data?.pi_balance ?? j1?.data?.balance ?? j1?.pi_balance ?? j1?.balance);
          const v1 = typeof b1 === 'string' ? Number(b1) : typeof b1 === 'number' ? b1 : NaN;
          if (Number.isFinite(v1) && v1 >= 0) setBalance(v1);
        } else if (res1.status === 404) {
          // In dev, assume ample Pi balance to enable flow
          if (t.startsWith('dev ')) {
            setBalance(1_000_000);
          } else {
            // fallback: leave existing default
          }
        }
      } catch {
        // keep placeholder; non-fatal
      }
      // load allocation summary (gross+net) & lock curve
      try {
        const ax = axios.create({ baseURL: GOV_API_BASE, headers: { Authorization: `Bearer ${t}` } });
        const [sumRes, curveRes] = await Promise.all([
          ax.get('/v1/alloc/summary'),
          ax.get('/v1/alloc/lock-curve')
        ]);
        if (sumRes.data?.success) {
          setBaseNetApy(sumRes.data.data?.totalNetApy || 0);
          setBaseGrossApy(sumRes.data.data?.totalGrossApy || 0);
        }
        if (curveRes.data?.success) setLockCurve(curveRes.data.data);
      } catch {}
    })();
  }, []);

  // lock share curve from server (piecewise step)
  const lockScale = (w: number) => {
    if (!lockCurve || lockCurve.length === 0) return 0;
    let share = lockCurve[0]?.share ?? 0;
    for (const pt of lockCurve) { if (w >= pt.weeks) share = pt.share; else break; }
    return share;
  };
  const baseDisplayed = showGross ? baseGrossApy : baseNetApy;
  const userScaledApy = baseDisplayed * lockScale(weeks);
  useEffect(()=> { setApyBps(Math.round(userScaledApy * 10000)); }, [userScaledApy]);

  async function submit() {
    setMsg(null);
    setBusy(true);
  const opId = crypto.randomUUID();
  activity.log({ id: opId, kind: 'stake', title: `Staking ${fmtCompact(amt)} Pi`, detail: `lock ${weeks}w`, status: 'in-flight' });
    try {
      // If running in Pi Browser, request a U2A payment; otherwise fallback to dev deposit
      const Pi = (globalThis as any).Pi;
      if (Pi && token && !token.startsWith('dev ')) {
        const paymentData = { amount: amt, memo: 'HyaPi stake deposit', metadata: { lockupWeeks: weeks } };
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
        const m = `✅ Payment submitted. You'll see your stake reflected after completion.`;
        setMsg(m);
        toast.success(m);
        activity.log({ id: opId, kind: 'stake', title: `Payment started ${fmtCompact(amt)} Pi`, detail: `lock ${weeks}w`, status: 'success' });
      } else {
        // Dev fallback: directly call deposit endpoint
        const res = await fetch(`${GOV_API_BASE}/v1/stake/deposit`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Idempotency-Key': crypto.randomUUID(),
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ amountPi: amt, lockupWeeks: weeks }),
        });
        if (res.status >= 500) toast.error('Network error. Please try again.');
        const j = await res.json();
        if (!res.ok || j?.success === false) throw new Error(j?.error?.message || 'Stake failed');
        const m = `✅ Staked ${fmtCompact(amt)} Pi (lock ${weeks}w). Stake id: ${j.data?.stake?.id}`
        setMsg(m);
        toast.success(m);
        activity.log({ id: opId, kind: 'stake', title: `Staked ${fmtCompact(amt)} Pi`, detail: `lock ${weeks}w`, status: 'success' });
      }
    } catch (e: any) {
  const m = `❌ ${e.message}`
  setMsg(m);
  toast.error(m);
  activity.log({ id: opId, kind: 'stake', title: 'Stake failed', detail: e.message, status: 'error' });
    } finally {
      setBusy(false);
    }
  }

  // simple client-side estimate: linear APY pro-rated by weeks; hyaPi minted 1:1 + yield
  const apy = userScaledApy; // already decimal
  // Pro-rate simple interest for preview (could switch to daily compounding for >8% accuracy)
  const estFinal = amt * (1 + apy * (weeks / 52));
  const isDev = token.startsWith('dev ');
  const invalidReason = !Number.isFinite(amt) || amt <= 0
    ? 'Enter an amount greater than 0'
    : (!isDev && amt > balance)
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
  <h2 className="text-xl sm:text-2xl font-semibold leading-tight">Stake Pi → receive hyaPi (1:1)</h2>

      <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
        {/* Card 1: Amount */}
  <Card className="p-4" title="Amount to stake" sub={`Available: ${fmtNumber(balance, 2)} Pi${isDev ? ' (dev)' : ''}`}>
          <div className="space-y-3">
            <NumberWithSlider
              label="Amount (Pi)"
              value={amt}
              onChange={setAmt}
              min={0}
              max={balance}
              step={0.000001}
              balance={balance}
            />
            {invalidReason && (
              <div role="alert" className="text-xs text-[color:var(--danger)]">
                {invalidReason}
              </div>
            )}
            <div className="flex flex-wrap gap-2" aria-label="Quick amount presets">
              {[25,50,75,100].map(p => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setAmt(Number((balance * (p/100)).toFixed(6)))}
                  className="rounded-full border border-white/15 bg-white/5 px-3 py-2 text-xs text-white/80 hover:bg-white/10 focus:outline-none focus-visible:ring-2 focus-visible:ring-[color:var(--acc)] focus-visible:ring-offset-2 focus-visible:ring-offset-black/20 transition-all"
                  aria-label={`Set ${p}%`}
                >
                  {p}%
                </button>
              ))}
            </div>
          </div>
        </Card>

        {/* Card 2: Lockup */}
        <Card className="p-4" title="Lockup duration & APY">
          <div className="space-y-3">
            <LockupSlider
              valueWeeks={weeks}
              onChange={(w, bps) => {
                setWeeks(w);
                setApyBps(bps);
              }}
            />
            <div className="rounded-md border border-white/10 bg-white/5 px-3 py-2 text-sm text-white/80 space-y-1">
              <div className="flex flex-wrap items-center gap-2">
                <span>Base {showGross ? 'Gross':'Net'} Platform APY:</span>
                <b>{baseDisplayed? (baseDisplayed*100).toFixed(2)+'%':'—'}</b>
                {!showGross && <span className="text-[10px] text-white/50" title="Net after 10% platform reward fee. Gross × 0.90">(fee)</span>}
                <label className="flex items-center gap-1 ml-auto text-[10px] cursor-pointer select-none">
                  <input type="checkbox" className="accent-brand-600" checked={showGross} onChange={e=>setShowGross(e.target.checked)} /> gross
                </label>
              </div>
              <div>Your Share ({(lockScale(weeks)*100).toFixed(0)}% of base): <b>{(apy*100).toFixed(2)}%</b></div>
              <div className="text-[10px] text-white/50 leading-snug">Early exit before expiry incurs 1% principal fee. No‑lock deposits charged 0.5% upfront entry fee.</div>
              {weeks === 0 && <div className="text-xs text-white/60">No-lock entry fee 0.5% applies</div>}
            </div>
            <div className="text-sm text-white/80">
              Est. hyaPi after period: <b className="tabular-nums">{fmtNumber(estFinal)}</b>
            </div>
          </div>
        </Card>
      </div>

      {msg && (
        <div className="mt-3 rounded-md border border-[color:var(--acc)]/30 bg-[color:var(--acc)]/10 p-3 text-sm text-white">
          {msg}
        </div>
      )}

      <ActivityPanel />

  {/* Sticky footer (mobile-first) */}
  <div id="sticky-actions" className="fixed inset-x-0 bottom-0 z-50 border-t border-white/10 bg-black/60 backdrop-blur sm:static sm:bg-transparent sm:border-0">
    <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-3 flex items-center gap-2">
            <Button
            onClick={submit}
      disabled={busy || !token || !!invalidReason}
            loading={busy}
            className="flex-1"
            aria-label="Stake"
          >
            Stake
          </Button>
          <Button
            variant="secondary"
      onClick={() => setShowPreview(true)}
            className="px-3 py-2"
            aria-haspopup="dialog"
            aria-controls="stake-preview"
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
          id="stake-preview"
          aria-modal="true"
          className="fixed inset-0 z-40 flex items-end justify-center bg-black/50 p-4 sm:items-center"
      onClick={() => setShowPreview(false)}
        >
      <div ref={dialogRef} className="w-full max-w-md" onClick={(e)=>e.stopPropagation()}>
            <Card className="p-4" title="Stake summary" sub="Review before submitting">
              <div className="space-y-2 text-sm text-white/80">
                <div className="flex justify-between"><span>Amount</span><span className="tabular-nums">{fmtNumber(amt)} Pi</span></div>
                <div className="flex justify-between"><span>Lockup</span><span>{weeks} weeks</span></div>
                <div className="flex justify-between"><span>Platform {showGross? 'Gross':'Net'} APY</span><span>{baseDisplayed? (baseDisplayed*100).toFixed(2)+'%':'—'}</span></div>
                <div className="flex justify-between"><span>Your Share</span><span>{(apy*100).toFixed(2)}%</span></div>
                <div className="flex justify-between"><span>Early Exit Fee</span><span>1%</span></div>
                {weeks===0 && <div className="flex justify-between"><span>Entry Fee</span><span>0.5%</span></div>}
                <div className="flex justify-between"><span>Share Factor</span><span>{(lockScale(weeks)*100).toFixed(0)}%</span></div>
                {weeks === 0 && (
                  <div className="flex justify-between"><span>Init fee</span><span>0.5%</span></div>
                )}
                <div className="flex justify-between"><span>Est. hyaPi after period</span><span className="tabular-nums">{fmtNumber(estFinal)}</span></div>
                {!((globalThis as any).Pi) && (
                  <div className="rounded border border-yellow-600/40 bg-yellow-600/10 p-2 text-yellow-200">
                    Open in Pi Browser to complete a real Testnet payment. In local dev we&apos;ll simulate the deposit.
                  </div>
                )}
              </div>
              <div className="mt-3 flex items-center justify-end gap-2">
                <Button className="px-3 py-1.5" variant="secondary" onClick={()=>setShowPreview(false)}>Close</Button>
                <Button className="px-3 py-1.5" onClick={()=>{ setShowPreview(false); submit(); }}>Confirm & Stake</Button>
              </div>
            </Card>
          </div>
        </div>
  )}
  {/* Spacer to prevent bottom content being hidden behind sticky footers on mobile */}
  <div className="h-16 sm:hidden" />
    </div>
  );
}
