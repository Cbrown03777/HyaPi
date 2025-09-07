'use client';
import React, { useEffect, useMemo, useState } from 'react';
import { useToast } from '@/components/ToastProvider';
import { makeClient } from '@/lib/http';
import { formatPercent, formatUSD, timeago } from '@/lib/format';
import clsx from 'clsx';

interface RateRow { venue:string; chain:string; market:string; baseApr:number; baseApy?:number; rewardApr?:number; rewardApy?:number; rewardMeritApr?:number; rewardSelfApr?:number; asOf:string; }
interface Holding { key:string; usd:number }
interface Target { key:string; weight:number }
interface Action { kind:'increase'|'decrease'|'buffer'; key?:string; usd:number }

function clamp01(n: number) {
	if (!Number.isFinite(n)) return 0;
	return Math.max(0, Math.min(1, n));
}

const DEFAULT_TARGETS: Target[] = [
	{ key:'aave:USDT', weight:0.34 },
	{ key:'justlend:USDT', weight:0.33 },
	{ key:'stride:stATOM', weight:0.33 }
];
const DEFAULT_HOLDINGS: Holding[] = [
	{ key:'aave:USDT', usd:4000 },
	{ key:'justlend:USDT', usd:0 },
	{ key:'stride:stATOM', usd:0 }
];

export default function AllocationPlanner() {
	const toast = useToast();
	const [token, setToken] = useState('');
	useEffect(()=>{ try {
		const t = (globalThis as any).hyapiBearer || (typeof localStorage !== 'undefined' ? localStorage.getItem('hyapiBearer') : undefined);
		if (typeof t === 'string' && t.trim()) setToken(t.trim());
	} catch {} },[]);
	useEffect(()=>{ try { if (token) { (globalThis as any).hyapiBearer = token; localStorage.setItem('hyapiBearer', token); } } catch {} }, [token]);
	const client = useMemo(()=> token ? makeClient(token) : null, [token]);

	const [rates, setRates] = useState<RateRow[]>([]);
	const [rateFilter, setRateFilter] = useState<string>('');
	const [ratesError, setRatesError] = useState<string|undefined>();
	const [holdings, setHoldings] = useState<Holding[]>(DEFAULT_HOLDINGS);
	const [targets, setTargets] = useState<Target[]>(DEFAULT_TARGETS);
	const MAX_ROWS = 3;
	const [guards, setGuards] = useState<{ maxSingleVenuePct?:string; maxNewPct?:string; minTicketUsd?:string; dustUsd?:string }>({});
	const [preview, setPreview] = useState<Action[]|null>(null);
	const [busy, setBusy] = useState(false);
	const [error, setError] = useState<string|undefined>();
	const [dupError, setDupError] = useState<string|undefined>();

	function totalApy(r: RateRow) {
		const b = r.baseApy ?? ((1 + r.baseApr/365)**365 - 1);
		const rw = r.rewardApy ?? (r.rewardApr ? ((1 + r.rewardApr/365)**365 - 1) : 0);
		return b + rw;
	}
	function normalizedKey(r: RateRow) { return `${r.venue}:${r.chain}:${r.market}`; }
	function parseKey(key: string): { venue:string; chain?:string; market?:string } {
		const parts = key.split(':').filter(Boolean);
		if (parts.length >= 3) return { venue:String(parts[0]), chain:String(parts[1]), market:String(parts[2]) };
		if (parts.length === 2) return { venue:String(parts[0]), market:String(parts[1]) };
		if (parts.length === 1) return { venue:String(parts[0]) };
		return { venue:'' };
	}
	function chainsFor(venue:string, market:string) {
		return Array.from(new Set(rates.filter(r=> r.venue===venue && r.market===market).map(r=> r.chain)));
	}
	function bestKeyTriples(limit:number) {
		return [...rates]
			.sort((a,b)=> totalApy(b) - totalApy(a))
			.filter((r,i,arr)=> arr.findIndex(z=> normalizedKey(z)===normalizedKey(r))===i)
			.slice(0, limit)
			.map(r => ({ key: normalizedKey(r), apy: totalApy(r) }));
	}
	function suggestFromRates() {
		if (!rates.length) return;
		const top = bestKeyTriples(3);
		if (!top.length) return;
		const total = top.reduce((s,x)=> s + x.apy, 0) || 1;
		setTargets(top.map(t => ({ key: t.key, weight: t.apy / total })));
	}
	function autoAllocateHoldings() {
		if (!rates.length) return;
		const totalUsd = holdings.reduce((s,h)=> s + h.usd, 0) || 0;
		const top = bestKeyTriples(3);
		if (!top.length) return;
		const sumApy = top.reduce((s,x)=> s + x.apy, 0) || 1;
		setHoldings(top.map(t => ({ key: t.key, usd: totalUsd ? (totalUsd * (t.apy / sumApy)) : 0 })));
	}

	// Fetch rates (works even without auth token since endpoint is public)
	useEffect(()=>{
		const apiBase = process.env.NEXT_PUBLIC_GOV_API_BASE || '/api';
		(async()=>{
			try {
				setRatesError(undefined);
				if (client) {
					const { data } = await client.get('/v1/venues/rates');
					if (data?.success) { setRates(data.data as RateRow[]); return; }
				}
				// fallback unauthenticated fetch
				const resp = await fetch(`${apiBase}/v1/venues/rates`);
				if (!resp.ok) throw new Error('fetch failed');
				const json = await resp.json();
				if (json?.success) setRates(json.data as RateRow[]); else setRatesError('rates unavailable');
			} catch (e:any) {
				console.warn('rates fetch error', e?.message);
				setRatesError('rates unavailable');
			}
		})();
	}, [client]);

	function updateHolding(i:number, field:'key'|'usd', val:string) {
		setHoldings(h => h.map((r,idx)=> idx===i ? { ...r, [field]: field==='usd'? Number(val): val } : r));
	}
	function addHolding() { setHoldings(h => h.length>=MAX_ROWS ? h : [...h, { key:'', usd:0 }]); }
	function updateTarget(i:number, field:'key'|'weight', val:string) {
		setTargets(t => t.map((r,idx)=> {
			if (idx!==i) return r;
			if (field==='weight') return { ...r, weight: Number(val) };
			return { ...r, key: val };
		}));
	}
	function addTarget() { setTargets(t => t.length>=MAX_ROWS ? t : [...t, { key:'', weight:0 }]); }

	// helper: derive chain for a given holding/target key using current rates
	const chainForKey = (key:string): string => {
		if (!key) return '';
		const { venue, chain, market } = parseKey(key);
		if (chain) return chain;
		if (venue && market) {
			const r = rates.find(r => r.venue===venue && r.market===market);
			return r?.chain || '';
		}
		return '';
	};

	// Duplicate validation (only within holdings list itself OR within targets list itself, not across both)
	useEffect(()=> {
		const seenHoldings = new Set<string>();
		for (const h of holdings) {
			if (!h.key) continue;
			if (seenHoldings.has(h.key)) { setDupError('Duplicate key in holdings list'); return; }
			seenHoldings.add(h.key);
		}
		const seenTargets = new Set<string>();
		for (const t of targets) {
			if (!t.key) continue;
			if (seenTargets.has(t.key)) { setDupError('Duplicate key in targets list'); return; }
			seenTargets.add(t.key);
		}
		setDupError(undefined);
	}, [holdings, targets]);

	const weightSum = targets.reduce((a,b)=> a + (Number.isFinite(b.weight)? b.weight:0), 0);

	function buildGuardsObject() {
		const out: any = {};
		if (guards.maxSingleVenuePct) out.maxSingleVenuePct = Number(guards.maxSingleVenuePct);
		if (guards.maxNewPct) out.maxNewPct = Number(guards.maxNewPct);
		if (guards.minTicketUsd) out.minTicketUsd = Number(guards.minTicketUsd);
		if (guards.dustUsd) out.dustUsd = Number(guards.dustUsd);
		return out;
	}

	async function doPreview() {
		if (!client) return;
		setBusy(true); setError(undefined);
		try {
			const body = { holdings, targets, guards: buildGuardsObject() };
			const { data } = await client.post('/v1/alloc/preview', body);
			if (!data?.success) throw new Error(data?.error?.message || 'preview failed');
			setPreview(data.data.actions || []);
		} catch (e:any) { setError(e.message || 'preview failed'); setPreview(null); }
		finally { setBusy(false); }
	}

	async function doExecute() {
		if (!client) return;
		setBusy(true); setError(undefined);
		try {
			const body = { holdings, targets, guards: buildGuardsObject() };
			const { data } = await client.post('/v1/alloc/execute', body);
			if (!data?.success) throw new Error(data?.error?.message || 'execute failed');
			toast.success('Plan persisted');
			setPreview(null);
		} catch (e:any) { setError(e.message || 'execute failed'); }
		finally { setBusy(false); }
	}

	function dismissError() { setError(undefined); }

	return (
		<div className="max-w-screen-xl mx-auto p-4 md:p-6 space-y-6">
			<header className="space-y-1">
				<h1 className="text-2xl font-semibold">Allocation Planner</h1>
				<p className="text-sm text-white/60">Preview & simulate venue rebalances. Weights must sum to 1.0.</p>
			</header>

			{/* Token input if missing */}
			{!token && (
				<div className="rounded border border-amber-400/30 bg-amber-500/10 p-3 text-xs space-y-2">
					<p className="text-amber-200">Dev token required for preview / execute. Public rates still load without it.</p>
					<form onSubmit={e=>{ e.preventDefault(); const form = e.target as HTMLFormElement; const inp = form.querySelector('input[name=devtok]') as HTMLInputElement; setToken(inp.value.trim()); }} className="flex gap-2 items-center">
						<input name="devtok" placeholder="dev pi_dev_address:1" className="flex-1 rounded bg-black/30 border border-white/10 px-2 py-1" />
						<button className="rounded bg-brand-600 px-3 py-1 text-xs font-medium">Set Token</button>
					</form>
				</div>
			)}

			{error && (
				<div className="relative rounded-md border border-red-400/40 bg-red-500/10 p-3 text-sm text-red-200 flex items-start gap-3">
					<span className="font-medium">Error:</span><span className="flex-1">{error}</span>
					<button onClick={dismissError} className="ml-2 text-red-300 hover:text-red-100 focus:outline-none" aria-label="Dismiss error">✕</button>
				</div>
			)}

			<section className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
				{/* Rates Card */}
				<div className="rounded border border-white/15 bg-white/5 p-4 flex flex-col">
					<h2 className="font-medium text-sm mb-2 flex items-center justify-between">Live Rates
						<input value={rateFilter} onChange={e=>setRateFilter(e.target.value)} placeholder="filter (e.g. aave arbitrum usdt)" className="ml-2 flex-1 rounded bg-black/30 border border-white/10 px-2 py-1 text-[10px]" />
					</h2>
					{ratesError && <div className="text-xs text-red-300">{ratesError}</div>}
					<div className="overflow-x-auto -mx-2 px-2">
						{rates.length > 0 ? (
							<table className="min-w-full text-xs">
								<thead>
									<tr className="text-left text-white/60">
										<th className="py-1 pr-3">Venue</th>
										<th className="py-1 pr-3">Chain</th>
										<th className="py-1 pr-3">Market</th>
										<th className="py-1 pr-3">Base APR</th>
										<th className="py-1 pr-3">Reward APR</th>
										<th className="py-1 pr-3">Merit APR</th>
										<th className="py-1 pr-3">Self APR</th>
										<th className="py-1 pr-3">Total APY</th>
										<th className="py-1 pr-3">As Of</th>
									</tr>
								</thead>
								<tbody>
									{[...rates]
										.filter(r => {
											if (!rateFilter.trim()) return true;
											return rateFilter.toLowerCase().split(/\s+/).every(tok =>
												[r.venue, r.chain, r.market].some(f => f.toLowerCase().includes(tok))
											);
										})
										.sort((a,b)=> b.baseApr - a.baseApr)
										.map(r=> {
											const totalApy = (()=>{
												const bApy = r.baseApy ?? ((1 + r.baseApr/365)**365 - 1);
												const rwApy = r.rewardApy ?? (r.rewardApr? ((1 + r.rewardApr/365)**365 - 1) : 0);
												return bApy + rwApy;
											})();
											return (
											<tr key={r.venue+':'+r.chain+':'+r.market} className="odd:bg-white/5">
												<td className="py-1 pr-3 font-medium">{r.venue}</td>
												<td className="py-1 pr-3">{r.chain}</td>
												<td className="py-1 pr-3">{r.market}</td>
												<td className="py-1 pr-3">{formatPercent(r.baseApr)}</td>
												<td className="py-1 pr-3">{r.rewardApr!=null? formatPercent(r.rewardApr): '—'}</td>
												<td className="py-1 pr-3">{r.rewardMeritApr!=null? formatPercent(r.rewardMeritApr): '—'}</td>
												<td className="py-1 pr-3">{r.rewardSelfApr!=null? formatPercent(r.rewardSelfApr): '—'}</td>
												<td className="py-1 pr-3">{formatPercent(totalApy)}</td>
												<td className="py-1 pr-3 whitespace-nowrap">{timeago(r.asOf)}</td>
											</tr>
											);
										})}
								</tbody>
							</table>
						) : (
							<div className="text-xs text-white/40">No rates</div>
						)}
					</div>
				</div>

				{/* Holdings */}
				<div className="rounded border border-white/15 bg-white/5 p-4">
					<div className="flex items-center justify-between mb-2">
						<h2 className="font-medium text-sm">Holdings (USD) <span className="text-[10px] text-white/40">(max {MAX_ROWS})</span></h2>
						<button type="button" onClick={autoAllocateHoldings} className="text-[10px] md:text-xs px-2 py-1 rounded border border-white/20 hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-brand-500 disabled:opacity-50" disabled={!rates.length}>Auto Allocate</button>
					</div>
					<div className="space-y-2">
						{holdings.map((h,i)=>(
							<div key={i} className="grid grid-cols-4 gap-2 text-xs">
								<label className="flex flex-col" htmlFor={`h-key-${i}`}>
									<span className="sr-only">Key</span>
									<input id={`h-key-${i}`} value={h.key} onChange={e=>updateHolding(i,'key',e.target.value)} className="rounded bg-black/30 border border-white/10 px-2 py-1" placeholder="venue:market or venue:chain:market" />
								</label>
								{(() => {
									const { venue, market, chain } = parseKey(h.key);
									const opts = venue && market ? chainsFor(venue, market) : [];
									if (!opts.length) return <div className="flex flex-col justify-center text-[10px] text-white/60 select-none">{chain || '—'}</div>;
									return (
										<select value={chainForKey(h.key)} onChange={e=> {
											if (!venue || !market) return;
											updateHolding(i,'key', `${venue}:${e.target.value}:${market}`);
										}} className="rounded bg-black/30 border border-white/10 px-2 py-1">
											<option value="">(auto)</option>
											{opts.map(c=> <option key={c} value={c}>{c}</option>)}
										</select>
									);
								})()}
								<label className="flex flex-col" htmlFor={`h-usd-${i}`}>
									<span className="sr-only">USD</span>
									<input id={`h-usd-${i}`} type="number" min={0} step="0.01" value={h.usd} onChange={e=>updateHolding(i,'usd',e.target.value)} className="rounded bg-black/30 border border-white/10 px-2 py-1 text-right" />
								</label>
							</div>
						))}
						<button onClick={addHolding} disabled={holdings.length>=MAX_ROWS} className="w-full mt-1 rounded border border-white/20 text-xs py-1 hover:bg-white/10 disabled:opacity-40 focus:outline-none focus:ring-2 focus:ring-brand-500">Add row</button>
					</div>
				</div>

				{/* Targets */}
				<div className="rounded border border-white/15 bg-white/5 p-4">
					<div className="flex items-center justify-between mb-2">
						<h2 className="font-medium text-sm">Targets (weights) <span className="text-[10px] text-white/40">(max {MAX_ROWS})</span></h2>
						<button type="button" onClick={suggestFromRates} className="text-[10px] md:text-xs px-2 py-1 rounded border border-white/20 hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-brand-500 disabled:opacity-50" disabled={rates.length===0}>Suggest</button>
					</div>
					<div className="space-y-2">
						{targets.map((t,i)=>(
							<div key={i} className="grid grid-cols-4 gap-2 text-xs">
								<label className="flex flex-col" htmlFor={`t-key-${i}`}>
									<span className="sr-only">Key</span>
									<input id={`t-key-${i}`} value={t.key} onChange={e=>updateTarget(i,'key',e.target.value)} className="rounded bg-black/30 border border-white/10 px-2 py-1" placeholder="venue:market or venue:chain:market" />
								</label>
								{(() => {
									const { venue, market, chain } = parseKey(t.key);
									const opts = venue && market ? chainsFor(venue, market) : [];
									if (!opts.length) return <div className="flex flex-col justify-center text-[10px] text-white/60 select-none">{chain || '—'}</div>;
									return (
										<select value={chainForKey(t.key)} onChange={e=> {
											if (!venue || !market) return;
											updateTarget(i,'key', `${venue}:${e.target.value}:${market}`);
										}} className="rounded bg-black/30 border border-white/10 px-2 py-1">
											<option value="">(auto)</option>
											{opts.map(c=> <option key={c} value={c}>{c}</option>)}
										</select>
									);
								})()}
								<label className="flex flex-col" htmlFor={`t-w-${i}`}>
									<span className="sr-only">Weight</span>
									<input
										id={`t-w-${i}`}
										type="number"
										min={0}
										max={1}
										step="0.0001"
										value={t.weight}
										onChange={e=>updateTarget(i,'weight',e.target.value)}
										onBlur={() => {
											setTargets(prev => {
												const next = prev.map((row,idx)=> idx===i ? { ...row, weight: clamp01(row.weight)} : { ...row, weight: clamp01(row.weight)});
												const sum = next.reduce((s,x)=> s + x.weight, 0);
												if (sum === 0) return next;
												// Normalize so weights sum to 1
												return next.map(x => ({ ...x, weight: x.weight / sum }));
											});
										}}
										className={clsx('rounded bg-black/30 border px-2 py-1 text-right', Math.abs(weightSum-1)>1e-6 ? 'border-red-400/60 border-2' : 'border-white/10')}
									/>
								</label>
							</div>
						))}
						<button onClick={addTarget} disabled={targets.length>=MAX_ROWS} className="w-full mt-1 rounded border border-white/20 text-xs py-1 hover:bg-white/10 disabled:opacity-40 focus:outline-none focus:ring-2 focus:ring-brand-500">Add row</button>
					</div>
					<div className="text-[10px] mt-1 text-white/60">Sum: {weightSum.toFixed(4)} {Math.abs(weightSum-1)>1e-6 && <span className="text-red-300 ml-1">(must equal 1)</span>}</div>
				</div>

				{/* Guardrails */}
				<div className="rounded border border-white/15 bg-white/5 p-4">
					<h2 className="font-medium text-sm mb-2">Guardrails (overrides)</h2>
					<div className="space-y-3 text-xs">
						<label className="flex flex-col gap-1" htmlFor="g-maxSingle">
							<span className="flex items-center gap-1">Max Single Venue %<span className="text-white/40" title="Hard cap fraction (0-1) of total portfolio any single venue may represent after rebalance. Applied before new capital cap.">?</span></span>
							<input id="g-maxSingle" value={guards.maxSingleVenuePct || ''} onChange={e=>setGuards(g=>({...g, maxSingleVenuePct:e.target.value}))} placeholder="0.60" className="rounded bg-black/30 border border-white/10 px-2 py-1" />
							<p className="text-[10px] text-white/40">Example: 0.60 with 10k TVL limits any venue key to $6k target.</p>
						</label>
						<label className="flex flex-col gap-1" htmlFor="g-maxNew">
							<span className="flex items-center gap-1">Max New Allocation %<span className="text-white/40" title="Max fraction of TOTAL portfolio that can be newly added (net increase) to a venue this cycle. Prevents rushing into a position even if target weight is higher.">?</span></span>
							<input id="g-maxNew" value={guards.maxNewPct || ''} onChange={e=>setGuards(g=>({...g, maxNewPct:e.target.value}))} placeholder="0.10" className="rounded bg-black/30 border border-white/10 px-2 py-1" />
							<p className="text-[10px] text-white/40">If venue needs $4k more but Max New is 0.10 on 10k TVL, only $1k increase ordered.</p>
						</label>
						<label className="flex flex-col gap-1" htmlFor="g-minTicket">
							<span className="flex items-center gap-1">Min Ticket USD<span className="text-white/40" title="Smallest absolute trade size to emit. Filters micro rebalances that cost more than benefit.">?</span></span>
							<input id="g-minTicket" value={guards.minTicketUsd || ''} onChange={e=>setGuards(g=>({...g, minTicketUsd:e.target.value}))} placeholder="50" className="rounded bg-black/30 border border-white/10 px-2 py-1" />
							<p className="text-[10px] text-white/40">Actions below this USD amount are skipped entirely.</p>
						</label>
						<label className="flex flex-col gap-1" htmlFor="g-dust">
							<span className="flex items-center gap-1">Dust USD<span className="text-white/40" title="Residual threshold: even if above Min Ticket, amounts below Dust are suppressed to avoid noise / slippage risk.">?</span></span>
							<input id="g-dust" value={guards.dustUsd || ''} onChange={e=>setGuards(g=>({...g, dustUsd:e.target.value}))} placeholder="5" className="rounded bg-black/30 border border-white/10 px-2 py-1" />
							<p className="text-[10px] text-white/40">Useful to hide nearly-zero deltas that accumulate from rounding.</p>
						</label>
						<div className="text-[10px] text-white/50 leading-snug pt-1">Server enforces: max 3 holdings & 3 targets, no duplicate within the same list. Same key may appear in both holdings and targets (representing current vs desired).</div>
					</div>
				</div>
			</section>

			{/* Actions */}
			{dupError && <div className="rounded border border-red-400/40 bg-red-500/10 px-3 py-2 text-xs text-red-200">{dupError}</div>}
			<div className="flex flex-col sm:flex-row gap-3">
				<button onClick={doPreview} disabled={busy || !!dupError} className="min-h-[44px] flex-1 rounded bg-brand-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-500">{busy? 'Working...' : 'Preview'}</button>
				<button onClick={doExecute} disabled={busy || !preview || preview.length===0 || !!dupError} className="min-h-[44px] flex-1 rounded bg-emerald-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500">Execute</button>
			</div>

			{/* Preview result */}
			<section className="rounded border border-white/15 bg-white/5 p-4">
				<h2 className="font-medium text-sm mb-2">Preview Result</h2>
				{preview == null && <div className="text-xs text-white/40">No preview yet.</div>}
				{preview && preview.length === 0 && <div className="text-xs text-white/60">No rebalance needed (below threshold).</div>}
				{preview && preview.length > 0 && (
					<ul className="space-y-1 text-xs">
						{preview.map((a,i)=> {
							const ch = a.key ? chainForKey(a.key) : '';
							return (
								<li key={i} className="flex justify-between rounded border border-white/10 bg-black/20 px-2 py-1">
									<span className="flex items-center gap-1">
										{a.kind === 'increase' && <span className="text-emerald-400" aria-hidden>↑</span>}
										{a.kind === 'decrease' && <span className="text-red-400" aria-hidden>↓</span>}
										{a.kind === 'buffer' && <span className="text-indigo-300" aria-hidden>⧉</span>}
										<span>{a.kind}{a.key? ` ${a.key}`:''}{ch? ` (${ch})`:''}</span>
									</span>
									<span className="tabular-nums">{formatUSD(a.usd)}</span>
								</li>
							);
						})}
					</ul>
				)}
			</section>
		</div>
	);
}
