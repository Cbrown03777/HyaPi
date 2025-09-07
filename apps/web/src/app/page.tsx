'use client';

import React from 'react';
import { useEffect, useMemo, useState, useCallback } from 'react';
import axios from 'axios';
import { GOV_API_BASE } from '@hyapi/shared';
import { signInWithPi } from '@/lib/pi';
import { Button } from '@/components/Button';
import { StatCard } from '@/components/StatCard';
import Hero from '@/components/Hero';
import StatsRow from '@/components/StatsRow';
import GovernancePeek from '@/components/GovernancePeek';
import VenueChips from '@/components/VenueChips';
import ProposalCard, { type Proposal as ProposalModel } from '@/components/ProposalCard';
import { Card } from '@/components/ui/Card';
import { SkeletonCard } from '@/components/Skeleton';
import { useToast } from '@/components/ToastProvider';
import { ActivityPanel } from '@/components/ActivityPanel';
import { useActivity } from '@/components/ActivityProvider';
import { fmtNumber as fmtDec, fmtCompact, fmtPercent } from '@/lib/format';
import { Button as BaseButton } from '@/components/Button';

type Portfolio = {
  hyapi_amount: string;       // decimal string
  pps_1e18: string;           // 1e18-scaled string
  effective_pi_value: string; // decimal string
  pps_series?: { as_of_date: string; pps_1e18: string }[];
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
        else setToken('dev pi_dev_address:1'); // fallback for local dev
      } catch {
        setToken('dev pi_dev_address:1');
      }
    })();
  }, []);
  return token;
}

export default function GovernancePage() {
  const token = useBearer();
  const toast = useToast();
  const activity = useActivity();
  const [loading, setLoading] = useState(false);
  const [proposals, setProposals] = useState<ProposalModel[]>([]);
  const [loadingProposals, setLoadingProposals] = useState<boolean>(false);
  const [err, setErr] = useState<string | null>(null);

  const client = useMemo(() => {
    const ax = axios.create({
      baseURL: GOV_API_BASE,
      headers: { Authorization: `Bearer ${token}` },
    });
    ax.interceptors.response.use(
      (res) => res,
      (error) => {
        const status = error?.response?.status as number | undefined;
        if (status && status >= 500) {
          toast.error('Network error. Please try again.');
        }
        return Promise.reject(error);
      }
    );
    return ax;
  }, [token, toast]);

  const refreshActive = async () => {
    setLoadingProposals(true);
    try {
      const { data } = await client.get('/v1/gov/proposals?status=active');
      setProposals(data.data ?? []);
    } finally {
      setLoadingProposals(false);
    }
  };

  const refreshOne = async (id: string) => {
    const { data } = await client.get(`/v1/gov/proposals/${id}`);
    setProposals((prev) =>
      prev.map((p) => (p.proposal_id === id ? data.data : p))
    );
  };

  useEffect(() => {
    if (!token) return;
    (async () => {
      try {
  // expose for ActivityPanel fetch (avoids prop drilling)
  (globalThis as any).hyapiBearer = token;
        setErr(null);
        await Promise.all([refreshActive(), refreshPortfolio()]);
      } catch (e: any) {
        setErr(e?.message ?? 'Failed to load proposals');
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  const vote = async (id: string, support: 'for' | 'against' | 'abstain') => {
    if (!token) return alert('Sign in first');
    setLoading(true);
    setErr(null);
  const opId = crypto.randomUUID();
  activity.log({ id: opId, kind: 'vote', title: `Voting ${support}`, detail: `proposal ${id}`, status: 'in-flight' });
    try {
    await client.post(
        `/v1/gov/${id}/votes`,
        { support },
        { headers: { 'Idempotency-Key': crypto.randomUUID() } }
      );
  await refreshOne(id);
  toast.success('Vote submitted');
  activity.log({ id: opId, kind: 'vote', title: `Voted ${support}`, detail: `proposal ${id}`, status: 'success' })
    } catch (e: any) {
  const msg = e?.response?.data?.error?.message ?? e?.message ?? 'Vote failed'
  setErr(msg);
  toast.error(msg);
  activity.log({ id: opId, kind: 'vote', title: 'Vote failed', detail: `proposal ${id}: ${msg}`, status: 'error' })
    } finally {
      setLoading(false);
    }
  };

  const finalize = async (id: string) => {
    if (!token) return alert('Sign in first');
    setLoading(true);
    setErr(null);
    const opId = crypto.randomUUID();
    activity.log({ id: opId, kind: 'finalize', title: 'Finalizing proposal', detail: `proposal ${id}`, status: 'in-flight' });
    try {
  await client.post(`/v1/gov/${id}/finalize?force=1`);
  await refreshOne(id);
  toast.success('Proposal finalized');
  activity.log({ id: opId, kind: 'finalize', title: 'Finalized proposal', detail: `proposal ${id}`, status: 'success' });
    } catch (e: any) {
  const msg = e?.response?.data?.error?.message ?? e?.message ?? 'Finalize failed'
  setErr(msg);
  toast.error(msg);
  activity.log({ id: opId, kind: 'finalize', title: 'Finalize failed', detail: `proposal ${id}: ${msg}`, status: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const execute = async (id: string) => {
    if (!token) return alert('Sign in first');
    setLoading(true);
    setErr(null);
    const opId = crypto.randomUUID();
    activity.log({ id: opId, kind: 'execute', title: 'Starting execution', detail: `proposal ${id}`, status: 'in-flight' });
    try {
  await client.post(`/v1/gov/execution/${id}`);
  await refreshOne(id);
  toast.success('Execution started');
  activity.log({ id: opId, kind: 'execute', title: 'Execution started', detail: `proposal ${id}`, status: 'success' });
    } catch (e: any) {
  const msg = e?.response?.data?.error?.message ?? e?.message ?? 'Execute failed'
  setErr(msg);
  toast.error(msg);
  activity.log({ id: opId, kind: 'execute', title: 'Execute failed', detail: `proposal ${id}: ${msg}`, status: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const [pf, setPf] = useState<Portfolio | null>(null);
  // Admin alloc panel state (hidden by default; toggle via localStorage flag or keyboard)
  const [showAllocAdmin, setShowAllocAdmin] = useState<boolean>(false);
  const [rates, setRates] = useState<any[]>([]);
  const [preview, setPreview] = useState<any|null>(null);
  const [allocSummary, setAllocSummary] = useState<any|null>(null);
  const [allocHistory, setAllocHistory] = useState<any[]>([]);
  const [allocEma, setAllocEma] = useState<{ ema7:number|null; latest:number|null }|null>(null);
  const [showGross, setShowGross] = useState(false);
  const [hoverPoint, setHoverPoint] = useState<{ idx:number; v:number } | null>(null);
  const [tvlInput, setTvlInput] = useState<number>(10000);
  const [allocLoading, setAllocLoading] = useState<boolean>(false);
  const [allocErr, setAllocErr] = useState<string|undefined>();

  useEffect(()=>{
    if (typeof window !== 'undefined' && localStorage.getItem('allocAdmin') === '1') setShowAllocAdmin(true);
    const handler = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.shiftKey && e.key.toLowerCase() === 'a') {
        setShowAllocAdmin(s => {
          const ns = !s; if (typeof window !== 'undefined') localStorage.setItem('allocAdmin', ns ? '1':'0'); return ns;
        });
      }
    };
    window.addEventListener('keydown', handler);
    return ()=> window.removeEventListener('keydown', handler);
  },[]);

  const loadRates = useCallback(async () => {
    if (!token) return;
    try {
      const { data } = await client.get('/v1/venues/rates');
      if (data.success) setRates(data.data);
    } catch (e:any) { setAllocErr(e.message); }
  }, [token, client]);
  const loadPreview = useCallback(async (tvl: number) => {
    if (!token) return;
    setAllocLoading(true); setAllocErr(undefined);
    try {
      const { data } = await client.get(`/v1/alloc/preview?tvlUSD=${tvl}`);
      if (data.success) setPreview(data.data);
    } catch (e:any) { setAllocErr(e.message); }
    finally { setAllocLoading(false); }
  }, [token, client]);
  const loadSummary = useCallback(async () => {
    if (!token) return;
    try {
      const { data } = await client.get('/v1/alloc/summary');
      if (data.success) setAllocSummary(data.data);
    } catch (e:any) { /* non-fatal */ }
  }, [token, client]);
  const loadHistory = useCallback(async () => {
    if (!token) return;
    try {
      const { data } = await client.get('/v1/alloc/history?limit=300');
      if (data.success) setAllocHistory(data.data.reverse()); // chronological
    } catch {}
  }, [token, client]);
  const loadEma = useCallback(async () => {
    if (!token) return;
    try {
      const { data } = await client.get('/v1/alloc/ema');
      if (data.success) setAllocEma(data.data);
    } catch {}
  }, [token, client]);
  async function executePlan() {
    if (!token || !preview) return;
    setAllocLoading(true); setAllocErr(undefined);
    try {
      const { data } = await client.post('/v1/alloc/execute', { tvlUSD: tvlInput });
      if (data.success) {
        toast.success('Plan executed');
        await loadPreview(tvlInput);
      } else throw new Error(data.error?.message || 'execute failed');
    } catch (e:any) { setAllocErr(e.message); }
    finally { setAllocLoading(false); }
  }
  useEffect(()=>{ if (showAllocAdmin) { loadRates(); loadPreview(tvlInput); loadSummary(); loadHistory(); loadEma(); } }, [showAllocAdmin, loadRates, loadPreview, loadSummary, loadHistory, loadEma, tvlInput]);
  useEffect(()=>{ if (token) { loadSummary(); loadHistory(); loadEma(); const id = setInterval(()=>{ loadSummary(); loadEma(); }, 60_000); return ()=> clearInterval(id); } }, [token, loadSummary, loadHistory, loadEma]);

  const refreshPortfolio = async () => {
  const { data } = await client.get('/v1/portfolio');
  if (data?.success) setPf(data.data as Portfolio);
};



  return (
  <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-6 space-y-6">
  <StatsRow pf={pf} allocSummary={allocSummary} allocEma={allocEma} showGross={showGross} />
  <Hero token={token} />

      {/* Portfolio summary */}
      {!pf && (
        <div className="mt-2 grid grid-cols-1 gap-3 sm:grid-cols-3">
          <SkeletonCard />
          <SkeletonCard />
          <SkeletonCard />
        </div>
      )}
      {pf && (
        <>
          <h2 className="mt-2 text-sm font-semibold text-white/70">Portfolio</h2>
          <div className="mt-2 grid grid-cols-1 gap-3 sm:grid-cols-3">
            <StatCard label="hyaPi Balance" value={`${Number(pf.hyapi_amount) >= 10000 ? fmtCompact(Number(pf.hyapi_amount)) : fmtDec(pf.hyapi_amount)} hyaPi`} tone="accent" />
            <StatCard
              label="Effective Pi Value"
              value={`${Number(pf.effective_pi_value) >= 10000 ? fmtCompact(Number(pf.effective_pi_value)) : fmtDec(pf.effective_pi_value)} Pi`}
              sub="via PPS"
              tone="primary"
            />
            {(() => {
              const pps = Number(pf.pps_1e18) / 1e18;
              const growthPct = Number.isFinite(pps) ? (pps - 1) * 100 : null;
                const statsProps = growthPct == null
                  ? { label: 'Growth vs Pi', value: '—', tone: 'base' as const }
                  : { label: 'Growth vs Pi', value: fmtPercent(growthPct, 2, { sign: true }), tone: 'base' as const, sub: 'based on current PPS', hint: 'Computed as (PPS ÷ 1.0 − 1) × 100. PPS represents Pi per 1 hyaPi.' };
                return <StatCard {...statsProps} />;
            })()}
          </div>

          {/* Quick CTAs */}
      <div className="mt-4 flex gap-3">
            <a href="/stake" className="flex-1">
        <Button className="w-full" rightIcon={<span>➔</span>}>Stake</Button>
            </a>
            <a href="/redeem" className="flex-1">
        <Button variant="secondary" className="w-full" rightIcon={<span>⇄</span>}>Redeem</Button>
            </a>
          </div>

          <ActivityPanel />
        </>
      )}
      {err && (
        <Card className="border-[color:var(--danger)]/30 bg-[color:var(--danger)]/10 p-3 text-sm text-[var(--fg)]">
          {err}
        </Card>
      )}

      {loadingProposals && (
        <div className="mt-3 space-y-3">
          <SkeletonCard />
          <SkeletonCard />
        </div>
      )}
      {!loadingProposals && proposals.length === 0 && (
        <Card className="border-dashed p-4 text-[var(--fg2)]">
          No active proposals yet. <a href="/create" className="underline">Create one?</a>
        </Card>
      )}

      <GovernancePeek proposals={proposals} onVote={vote} onFinalize={finalize} onExecute={execute} busy={loading} />
      {proposals.length > 2 && (
        <div className="mt-4 grid grid-cols-1 gap-3 md:grid-cols-2">
          {proposals.slice(2).map(p => (
            <ProposalCard key={p.proposal_id} p={p} onVote={vote} onFinalize={finalize} onExecute={execute} busy={loading} />
          ))}
        </div>
      )}
      {showAllocAdmin && (
        <div className="mt-10 border border-white/15 rounded p-4 space-y-4 bg-white/5">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold">Allocation Admin (Ctrl+Shift+A)</h2>
            <div className="flex gap-2 items-center text-xs text-white/60">
              <label className="flex items-center gap-1">
                TVL:
                <input type="number" className="bg-black/30 border border-white/10 rounded px-2 py-0.5 w-28 text-right" value={tvlInput} onChange={e=>setTvlInput(Number(e.target.value)||0)} />
              </label>
              <BaseButton className="btn-modern btn-secondary !text-xs" disabled={allocLoading} onClick={()=>loadPreview(tvlInput)}>Preview</BaseButton>
              <BaseButton className="btn-modern btn-primary !text-xs" disabled={allocLoading || !preview} onClick={executePlan}>Simulate Execute</BaseButton>
            </div>
          </div>
          {allocSummary && (
            <div className="border border-white/10 rounded p-3 text-xs space-y-2">
              <h3 className="font-medium text-sm">Current Allocation Performance</h3>
              <div className="flex items-center gap-2 text-[10px]">
                <label className="flex items-center gap-1 select-none cursor-pointer">
                  <input type="checkbox" checked={showGross} onChange={e=>setShowGross(e.target.checked)} className="accent-brand-600" /> Show gross instead of net
                </label>
                {allocEma && <span className="text-white/40">EMA7 Net: {allocEma.ema7? (allocEma.ema7*100).toFixed(2)+'%':'—'}</span>}
              </div>
              <VenueChips baskets={allocSummary.baskets} showGross={showGross} />
              <div className="text-[10px] text-white/40">Total Net APY weighted: {allocSummary.totalNetApy? (allocSummary.totalNetApy*100).toFixed(2)+'%':'—'} (fee adj)</div>
              {allocHistory.length>2 && (() => {
                const points = allocHistory.map(h => showGross? h.totalGrossApy : h.totalNetApy).filter((v:number)=>typeof v==='number');
                if (points.length < 2) return null;
                const min = Math.min(...points);
                const max = Math.max(...points);
                const range = max - min || 1;
                const svgPath = points.map((v,i)=>{
                  const x = (i/(points.length-1))*100;
                  const y = 100 - ((v - min)/range)*100;
                  return `${i===0?'M':'L'}${x},${y}`;
                }).join(' ');
                const hp = hoverPoint && hoverPoint.idx < points.length ? hoverPoint : null;
                const hpX = hp ? (hp.idx/(points.length-1))*100 : null;
                const hpY = hp ? 100 - ((hp.v - min)/range)*100 : null;
                return (
                  <div className="mt-2">
                    <h4 className="font-medium text-[11px] mb-1">History (recent)</h4>
                    <div className="h-32 w-full relative overflow-hidden rounded bg-black/30 border border-white/10">
                      <svg viewBox="0 0 100 100" preserveAspectRatio="none" className="absolute inset-0 w-full h-full"
                        onMouseMove={e=> {
                          const rect = (e.target as SVGElement).getBoundingClientRect();
                          const rel = (e.clientX - rect.left) / rect.width;
                          const idx = Math.max(0, Math.min(points.length-1, Math.round(rel * (points.length-1))));
                          setHoverPoint({ idx, v: points[idx] });
                        }}
                        onMouseLeave={()=> setHoverPoint(null)}>
                        {/* axes */}
                        <line x1="0" y1="100" x2="100" y2="100" stroke="#666" strokeWidth="0.4" />
                        <line x1="0" y1="0" x2="0" y2="100" stroke="#666" strokeWidth="0.4" />
                        {/* grid lines (quartiles) */}
                        {[0.25,0.5,0.75].map(g=> <line key={g} x1="0" x2="100" y1={100-g*100} y2={100-g*100} stroke="#444" strokeWidth="0.3" strokeDasharray="1 2" />)}
                        <path d={svgPath} fill="none" stroke="#4ade80" strokeWidth="1.2" />
                        {hp && hpX!=null && hpY!=null && (
                          <g>
                            <circle cx={hpX} cy={hpY} r={1.8} fill="#facc15" />
                            <line x1={hpX} x2={hpX} y1={hpY} y2={100} stroke="#facc15" strokeWidth="0.4" strokeDasharray="1 1" />
                          </g>
                        )}
                      </svg>
                      {hp && (
                        <div className="absolute bottom-1 left-1 text-[10px] px-1.5 py-0.5 rounded bg-black/70 border border-white/10">
                          {(hp.v*100).toFixed(2)}% {(showGross? 'gross':'net')}
                        </div>
                      )}
                      <div className="absolute top-1 right-1 text-[10px] text-white/40">Range {(min*100).toFixed(2)}–{(max*100).toFixed(2)}%</div>
                    </div>
                  </div>
                );
              })()}
              {allocEma?.ema7 && allocSummary?.totalUsd && (
                <div className="text-[10px] text-white/40 flex flex-wrap gap-2 pt-1">
                  {(() => {
                    const tvl = allocSummary.totalUsd;
                    const apy = allocEma.ema7;
                    const weekly = tvl * apy / 52;
                    const monthly = tvl * apy / 12;
                    return (
                      <>
                        <span>Projected net (EMA7): ~{fmtDec(weekly)} USD/wk</span>
                        <span>~{fmtDec(monthly)} USD/mo</span>
                      </>
                    );
                  })()}
                </div>
              )}
            </div>
          )}
          {allocErr && <div className="text-xs text-red-400">Error: {allocErr}</div>}
          <div className="grid md:grid-cols-2 gap-6">
            <div className="space-y-3">
              <div>
                <h3 className="font-medium text-sm mb-1">Live Rates</h3>
                <div className="overflow-x-auto border border-white/10 rounded">
                  <table className="min-w-full text-xs">
                    <thead>
                      <tr className="text-left bg-white/10">
                        <th className="px-2 py-1">Venue</th>
                        <th className="px-2 py-1">Market</th>
                        <th className="px-2 py-1">APR</th>
                        <th className="px-2 py-1">APY</th>
                        <th className="px-2 py-1">Est Net</th>
                        <th className="px-2 py-1">As Of</th>
                      </tr>
                    </thead>
                    <tbody>
                      {rates.map((r:any)=>(
                        <tr key={r.venue+':'+r.market} className="odd:bg-white/5">
                          <td className="px-2 py-1 font-medium">{r.venue}</td>
                          <td className="px-2 py-1">{r.market}</td>
                          <td className="px-2 py-1">{(r.baseApr*100).toFixed(2)}%</td>
                          <td className="px-2 py-1">{r.baseApy !== undefined ? (r.baseApy*100).toFixed(2)+'%' : '—'}</td>
                          <td className="px-2 py-1">{r.estNetApy !== undefined ? (r.estNetApy*100).toFixed(2)+'%' : '—'}</td>
                          <td className="px-2 py-1 whitespace-nowrap">{new Date(r.asOf).toLocaleTimeString()}</td>
                        </tr>
                      ))}
                      {rates.length === 0 && (
                        <tr><td colSpan={6} className="px-2 py-4 text-center text-white/40">No rates</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
              {preview && (
                <div className="border border-white/10 rounded p-2 space-y-2">
                  <h3 className="font-medium text-sm">Governance Weights</h3>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    {Object.entries(preview.gov).map(([k,v]:any)=>(
                      <div key={k} className="flex justify-between"><span className="truncate pr-1">{k}</span><span>{(Number(v)*100).toFixed(2)}%</span></div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            <div className="space-y-3">
              {preview && (
                <>
                  <div className="border border-white/10 rounded p-2">
                    <h3 className="font-medium text-sm mb-1">Target Weights</h3>
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      {Object.entries(preview.targets).map(([k,v]:any)=>(
                        <div key={k} className="flex justify-between"><span className="truncate pr-1">{k}</span><span>{(v*100).toFixed(2)}%</span></div>
                      ))}
                    </div>
                  </div>
                  <div className="border border-white/10 rounded p-2">
                    <h3 className="font-medium text-sm mb-1">Planned Actions (drift {preview.plan?.driftBps} bps)</h3>
                    <div className="space-y-1 text-xs">
                      {(preview.plan?.actions || []).map((a:any,i:number)=>(
                        <div key={i} className="flex justify-between border border-white/10 rounded px-2 py-1">
                          <span>{a.kind}{a.key? ' '+a.key:''}</span>
                          <span>{a.deltaUSD?.toFixed(2)} USD</span>
                        </div>
                      ))}
                      {(!preview.plan?.actions || preview.plan.actions.length===0) && <div className="text-white/40">No actions (below drift threshold)</div>}
                    </div>
                  </div>
                </>
              )}
              {!preview && <div className="text-xs text-white/40">No preview loaded.</div>}
            </div>
          </div>
          <div className="text-[10px] text-white/40 pt-1">Drift threshold {preview?.guards?.maxDriftBps} bps; buffer {(preview?.guards?.bufferBps ?? 0)/100}%.</div>
        </div>
      )}
    </div>
  );
}
