"use client";
import { useState, useMemo } from 'react';

type Rate = { venue?: string; market?: string; baseApr?: number; rewardsApr?: number; feeBps?: number; updatedAt?: string };
const pct = (n = 0) => `${(n * 100).toFixed(2)}%`;
const net = (r: Rate) => (r.baseApr ?? 0) + (r.rewardsApr ?? 0) - ((r.feeBps ?? 0) / 1e4);

export function HowItWorks({ rates }: { rates?: Rate[] }) {
  const [open, setOpen] = useState(false);
  const allow = useMemo(() => new Set(['aave:USDT', 'justlend:USDT', 'stride:stATOM']), []);
  const top = useMemo(() => {
    const rs = rates ?? [];
    return rs
      .map((r) => ({ key: `${(r.venue || '').toLowerCase()}:${(r.market || '').toUpperCase()}`, r }))
      .filter((x) => allow.has(x.key))
      .sort((a, b) => net(b.r) - net(a.r))
      .slice(0, 3);
  }, [rates, allow]);

  return (
    <section className="py-6 sm:py-8 border-t border-neutral-200">
      <div className="max-w-6xl mx-auto px-4">
        <h3 className="text-lg font-semibold">How yield is generated</h3>
        <div className="mt-3 grid grid-cols-1 sm:grid-cols-4 gap-3">
          <div className="rounded-lg border border-neutral-200 p-4">
            <div className="font-medium">Deposit Pi</div>
            <div className="text-sm text-neutral-600 mt-1">Approve in Pi App; funds stay custodied via A2U/Platform.</div>
          </div>
          <div className="rounded-lg border border-neutral-200 p-4">
            <div className="font-medium">Allocation engine</div>
            <div className="text-sm text-neutral-600 mt-1">Governance weights + guardrails plan deposits/withdrawals.</div>
          </div>
          <div className="rounded-lg border border-neutral-200 p-4">
            <div className="font-medium">Venues</div>
            <div className="text-sm text-neutral-600 mt-1">Aave, JustLend, Stride and more—curated, monitored.</div>
          </div>
          <div className="rounded-lg border border-neutral-200 p-4">
            <div className="font-medium">Earnings & PPS</div>
            <div className="text-sm text-neutral-600 mt-1">Yield compounds into PPS; your hyaPi reflects NAV.</div>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="mt-4 text-sm px-3 py-2 border rounded hover:bg-neutral-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-600"
        >
          View venue breakdown
        </button>
      </div>

      {open && (
        <div className="fixed inset-0 z-50">
          <div className="absolute inset-0 bg-black/40" onClick={() => setOpen(false)} />
          <div className="absolute right-0 top-0 h-full w-full sm:w-[420px] bg-white shadow-xl p-4 overflow-y-auto">
            <div className="flex items-center justify-between mb-3">
              <h4 className="text-lg font-semibold">Venue breakdown</h4>
              <button onClick={() => setOpen(false)} className="text-sm px-2 py-1 border rounded hover:bg-neutral-50" aria-label="Close">Close</button>
            </div>
            {(!rates || rates.length === 0) ? (
              <p className="text-neutral-600">Live rates unavailable right now.</p>
            ) : (
              <ul className="space-y-3">
                {top.map(({ key, r }) => (
                  <li key={key} className="border rounded p-3">
                    <div className="flex items-center justify-between">
                      <div className="font-medium uppercase">{key}</div>
                      <div className="text-indigo-700 font-semibold">{pct(net(r))}</div>
                    </div>
                    <div className="text-xs text-neutral-600 mt-1">
                      Breakdown: base {pct(r.baseApr ?? 0)}
                      {r.rewardsApr ? <> + rewards {pct(r.rewardsApr)}</> : null}
                      {r.feeBps ? <> − fee {pct((r.feeBps || 0) / 1e4)}</> : null}
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      )}
    </section>
  );
}
