"use client";
import clsx from 'clsx';

export type Proposal = {
  proposal_id: string;
  title: string;
  description?: string|null;
  status: 'active'|'finalized'|'executed'|string;
  start_ts?: string;
  end_ts?: string;
  allocation?: Record<string, number>;
  for_power?: string; against_power?: string; abstain_power?: string;
  tally?: { for_power?: string; against_power?: string; abstain_power?: string };
};

type Support = 'for'|'against'|'abstain';

function e18ToNumStr(x?: string) {
  if (!x) return '0';
  try {
    const n = BigInt(x);
    const whole = n / 10n**18n;
    const frac = (n % 10n**18n).toString().padStart(18,'0').slice(0,4);
    return frac === '0000' ? whole.toString() : `${whole}.${frac}`.replace(/\.?0+$/,'');
  } catch {
    const f = Number(x); if (!Number.isFinite(f)) return '0';
    return (f/1e18).toFixed(4).replace(/\.?0+$/,'');
  }
}

function percent(a: bigint, total: bigint) {
  if (total === 0n) return 0;
  const p = Number((a * 10000n) / total) / 100;
  return Math.max(0, Math.min(100, p));
}

function StatusPill({status}:{status:Proposal['status']}) {
  const styles = {
    active:   'bg-blue-50 text-blue-700 ring-1 ring-blue-200',
    finalized:'bg-amber-50 text-amber-700 ring-1 ring-amber-200',
    executed: 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200',
    default:  'bg-slate-100 text-slate-700 ring-1 ring-slate-200'
  } as const;
  return (
    <span className={clsx('inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium', styles[status as keyof typeof styles] ?? styles.default)}>
      {status}
    </span>
  );
}

export default function ProposalCard({ p, onVote, onFinalize, onExecute, busy }: {
  p: Proposal;
  onVote: (id: string, support: Support)=>void;
  onFinalize?: (id: string)=>void;
  onExecute?:  (id: string)=>void;
  busy?: boolean;
}) {
  const forP = p.for_power ?? p.tally?.for_power ?? '0';
  const agP  = p.against_power ?? p.tally?.against_power ?? '0';
  const abP  = p.abstain_power ?? p.tally?.abstain_power ?? '0';

  let a=0n, b=0n, c=0n, total=0n;
  try {
    a = BigInt(forP||'0'); b = BigInt(agP||'0'); c = BigInt(abP||'0');
    total = a+b+c;
  } catch{}

  const pctFor = percent(a,total);
  const pctAg  = percent(b,total);
  const pctAb  = percent(c,total);

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="text-base font-semibold text-slate-900">{p.title}</h3>
          {p.description && <p className="mt-1 text-sm text-slate-600">{p.description}</p>}
        </div>
        <StatusPill status={p.status}/>
      </div>

      {p.allocation && (
        <div className="mt-3 flex flex-wrap gap-2">
          {Object.entries(p.allocation).map(([k,v])=> (
            <span key={k} className="text-xs rounded-md bg-slate-100 text-slate-700 px-2 py-1">
              {k.toUpperCase()}: {(v*100).toFixed(0)}%
            </span>
          ))}
        </div>
      )}

      <div className="mt-4">
        <div className="h-2 w-full rounded-full bg-slate-100 overflow-hidden">
          <div className="h-2 bg-emerald-500" style={{ width: `${pctFor}%` }}/>
          <div className="h-2 bg-rose-500" style={{ width: `${pctAg}%` }}/>
          <div className="h-2 bg-amber-500" style={{ width: `${pctAb}%` }}/>
        </div>
        <div className="mt-2 grid grid-cols-3 gap-2 text-xs text-slate-700">
          <div>For: <span className="font-medium">{e18ToNumStr(forP)}</span> <span className="text-slate-500">({pctFor.toFixed(1)}%)</span></div>
          <div>Against: <span className="font-medium">{e18ToNumStr(agP)}</span> <span className="text-slate-500">({pctAg.toFixed(1)}%)</span></div>
          <div>Abstain: <span className="font-medium">{e18ToNumStr(abP)}</span> <span className="text-slate-500">({pctAb.toFixed(1)}%)</span></div>
        </div>
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        <button disabled={busy} onClick={()=>onVote(p.proposal_id,'for')} className="inline-flex items-center rounded-md bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-50">Vote For</button>
        <button disabled={busy} onClick={()=>onVote(p.proposal_id,'against')} className="inline-flex items-center rounded-md bg-rose-600 px-3 py-2 text-sm font-medium text-white hover:bg-rose-700 disabled:opacity-50">Against</button>
        <button disabled={busy} onClick={()=>onVote(p.proposal_id,'abstain')} className="inline-flex items-center rounded-md bg-amber-600 px-3 py-2 text-sm font-medium text-white hover:bg-amber-700 disabled:opacity-50">Abstain</button>
        {onFinalize && (<button disabled={busy} onClick={()=>onFinalize(p.proposal_id)} className="ml-auto inline-flex items-center rounded-md border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50">Finalize</button>)}
        {onExecute && (<button disabled={busy} onClick={()=>onExecute(p.proposal_id)} className="inline-flex items-center rounded-md border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50">Execute</button>)}
      </div>
    </div>
  );
}
