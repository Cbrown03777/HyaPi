"use client";
import React, { useEffect, useMemo, useState, useCallback } from 'react';
import { useToast } from '@/components/ToastProvider';
import { makeClient } from '@/lib/http';
import { formatPercent, formatUSD, timeago } from '@/lib/format';
import GovAllocationHistoryChart from '@/components/GovAllocationHistoryChart';
import {
	Box,
	Typography,
	TextField,
	Table,
	TableBody,
	TableCell,
	TableContainer,
	TableHead,
	TableRow,
	Paper,
	Button,
	Chip,
	Stack,
	IconButton,
	Accordion,
	AccordionSummary,
	AccordionDetails,
	Tooltip,
	Divider,
	Alert,
	CircularProgress
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import AddIcon from '@mui/icons-material/Add';
import RefreshIcon from '@mui/icons-material/Refresh';
import AutoFixHighIcon from '@mui/icons-material/AutoFixHigh';
import SettingsBackupRestoreIcon from '@mui/icons-material/SettingsBackupRestore';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import Modal from '@mui/material/Modal';
import { useManualActions } from '@/hooks/useManualActions';

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
	useEffect(()=>{ try { const t = (globalThis as any).hyapiBearer || (typeof localStorage !== 'undefined' ? localStorage.getItem('hyapiBearer') : undefined); if (typeof t === 'string' && t.trim()) setToken(t.trim()); } catch {} },[]);
	useEffect(()=>{ try { if (token) { (globalThis as any).hyapiBearer = token; localStorage.setItem('hyapiBearer', token); } } catch {} }, [token]);
	const client = useMemo(()=> token ? makeClient(token) : null, [token]);

	const [rates, setRates] = useState<RateRow[]>([]);
	const [rateFilter, setRateFilter] = useState('');
	const [ratesError, setRatesError] = useState<string|undefined>();
	const [providerErrors, setProviderErrors] = useState<Record<string,string>>({});
	const [ratesLoading, setRatesLoading] = useState(false);
	const [ratesFetchedAt, setRatesFetchedAt] = useState<string | null>(null);
	const [holdings, setHoldings] = useState<Holding[]>(DEFAULT_HOLDINGS);
	const [targets, setTargets] = useState<Target[]>(DEFAULT_TARGETS);
	const MAX_ROWS = 3;
	const [guards, setGuards] = useState<{ maxSingleVenuePct?:string; maxNewPct?:string; minTicketUsd?:string; dustUsd?:string }>({});
	const [preview, setPreview] = useState<Action[]|null>(null);
	const [busy, setBusy] = useState(false);
	const [error, setError] = useState<string|undefined>();
	const [dupError, setDupError] = useState<string|undefined>();
	const [current, setCurrent] = useState<any|null>(null);
	const [currentLoading, setCurrentLoading] = useState(false);
	const fetchCurrent = useCallback(async ()=> {
		if (!client) return;
		setCurrentLoading(true);
		try {
			const { data } = await client.get('/v1/alloc/current');
			if (data?.success) setCurrent(data.data); else throw new Error(data?.error?.message || 'current failed');
		} catch (e:any) { console.warn('alloc.current error', e?.message); }
		finally { setCurrentLoading(false); }
	}, [client]);
	useEffect(()=> { fetchCurrent(); const id = setInterval(fetchCurrent, 30_000); return ()=> clearInterval(id); }, [fetchCurrent]);

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
	const fetchRates = useCallback(async (force=false) => {
		const apiBase = process.env.NEXT_PUBLIC_GOV_API_BASE || '/api';
		setRatesLoading(true);
		try {
			setRatesError(undefined);
			setProviderErrors({});
			let json: any | undefined;
			if (client && !force) { // prefer authenticated first (might return more in future)
				try {
					const { data } = await client.get('/v1/venues/rates');
					json = data;
				} catch (e:any) {
					// fall through to public fetch
				}
			}
			if (!json) {
				const url = `${apiBase}/v1/venues/rates${force ? '?debug=1' : ''}`; // debug=1 bypasses server cache
				const resp = await fetch(url, { cache:'no-store' });
				if (!resp.ok) throw new Error('fetch failed');
				json = await resp.json();
			}
			if (json?.success) {
				setRates(json.data as RateRow[]);
				setProviderErrors(json.errors || {});
				setRatesFetchedAt(new Date().toISOString());
				if ((!json.data || json.data.length===0) && json.errors) {
					setRatesError('all providers failed');
				}
			} else {
				setRatesError('rates unavailable');
			}
		} catch (e:any) {
			console.warn('rates fetch error', e?.message);
			setRatesError('rates unavailable');
		} finally {
			setRatesLoading(false);
		}
	}, [client]);

	useEffect(()=>{ fetchRates(false); }, [fetchRates]);

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

	async function routeExcessBuffer() {
		if (!client) return; setBusy(true);
		try { const { data } = await client.post('/v1/alloc/route-buffer', {}); if (!data?.success) throw new Error('route failed'); toast.success('Route trigger queued'); fetchCurrent(); }
		catch(e:any){ toast.error(e.message||'route failed'); }
		finally { setBusy(false); }
	}
	async function topUpBuffer() {
		if (!client) return; setBusy(true);
		try { const { data } = await client.post('/v1/alloc/top-up-buffer', {}); if (!data?.success) throw new Error('top-up failed'); toast.success('Top-up planning queued'); fetchCurrent(); }
		catch(e:any){ toast.error(e.message||'top-up failed'); }
		finally { setBusy(false); }
	}
	async function adjustToTargetWeights() {
		if (!client) return; setBusy(true);
		try {
			const { data } = await client.post('/v1/alloc/rebalance-to-targets', {});
			if (!data?.success) throw new Error(data?.error?.message || 'rebalance failed');
			toast.success('Adjusted to targets');
			fetchCurrent();
		} catch (e:any) { toast.error(e.message || 'rebalance failed'); }
		finally { setBusy(false); }
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

	const restoreGuards = () => setGuards({});

	// Color palette and keyed accessor for stable coloring of venues
			const palette = useMemo(()=>[
				'#6366f1', // indigo
				'#10b981', // emerald
				'#f59e0b', // amber
				'#ef4444', // red (fallback if >3)
				'#8b5cf6',
				'#14b8a6',
				'#0ea5e9',
			], []);
			const colorFor = useCallback((k:string, idx:number)=> palette[idx % palette.length], [palette]);

				// Manual Actions state
				const { data: planned, loading: plannedLoading, error: plannedError, refresh: refreshPlanned, confirm: confirmPlanned } = useManualActions('Planned');
				const [confirmOpen, setConfirmOpen] = useState(false);
				const [confirmId, setConfirmId] = useState<string|undefined>();
				const [avgPriceUSD, setAvgPriceUSD] = useState<string>('');
				const [feeUSD, setFeeUSD] = useState<string>('0');
				const [txUrl, setTxUrl] = useState<string>('');
				const [idemKey, setIdemKey] = useState<string>('');
				const [confirmBusy, setConfirmBusy] = useState(false);
				const selected = useMemo(()=> planned.find(p=> p.id===confirmId), [planned, confirmId]);
				const usdImpact = useMemo(()=>{
					const a = Number(selected?.amountPI || 0) * Number(avgPriceUSD || 0);
					const f = Number(feeUSD || 0);
					return a - f;
				}, [selected, avgPriceUSD, feeUSD]);
				function openConfirm(id:string){
					setConfirmId(id); setConfirmOpen(true);
					const row = planned.find(p=>p.id===id);
					if (row) setIdemKey(row.id);
				}
				function closeConfirm(){ setConfirmOpen(false); setConfirmId(undefined); setAvgPriceUSD(''); setFeeUSD('0'); setTxUrl(''); setIdemKey(''); }
				const canSubmit = Number(avgPriceUSD)>0 && Number(feeUSD)>=0 && /^https?:\/\//.test(txUrl);
				async function submitConfirm(){
					if (!confirmId) return;
					setConfirmBusy(true);
					try {
						await confirmPlanned(confirmId, { avgPriceUSD: Number(avgPriceUSD), feeUSD: Number(feeUSD||0), txUrl, idempotencyKey: (idemKey || selected?.id || '') });
						toast.success('Confirmed');
						closeConfirm();
						refreshPlanned();
					} catch (e:any) { toast.error(e.message || 'confirm failed'); }
					finally { setConfirmBusy(false); }
				}

	return (
		<Box maxWidth="lg" mx="auto" px={{ xs:2, md:4 }} py={4} display="flex" flexDirection="column" gap={4}>
			{/* TVL & Buffer Strip */}
			{current && (
				<>
				<Paper variant="outlined" sx={{ p:2 }}>
					<Stack direction={{ xs:'column', md:'row' }} spacing={2} alignItems={{ xs:'flex-start', md:'center' }} justifyContent="space-between">
						<Stack direction="row" spacing={3} flexWrap="wrap">
							<Box>
								<Typography variant="caption" sx={{opacity:0.6}}>Total TVL</Typography>
								<Typography fontWeight={600}>{formatUSD(current.totalUsd)}</Typography>
							</Box>
							<Box>
								<Typography variant="caption" sx={{opacity:0.6}}>Deployed</Typography>
								<Typography fontWeight={600}>{formatUSD(current.deployedUsd)}</Typography>
							</Box>
							<Box>
								<Typography variant="caption" sx={{opacity:0.6}}>Buffer</Typography>
								<Typography fontWeight={600}>{formatUSD(current.bufferUsd)}</Typography>
							</Box>
							<Box>
								<Typography variant="caption" sx={{opacity:0.6}}>Buffer Target</Typography>
								<Typography fontWeight={600}>{formatUSD(current.buffer.target)}</Typography>
							</Box>
						</Stack>
						<Stack direction="row" spacing={1}>
							<Tooltip title="Attempt to deploy excess buffer above upper band"><span><Button size="small" variant="contained" color="primary" disabled={!current.buffer.routeExcessEligible || busy} onClick={routeExcessBuffer}>Route Excess</Button></span></Tooltip>
							<Tooltip title="Plan withdrawals to restore target buffer"><span><Button size="small" variant="outlined" color="warning" disabled={!current.buffer.topUpEligible || busy} onClick={topUpBuffer}>Top Up</Button></span></Tooltip>
							<Tooltip title="Replace holdings with top-3 active targets and set buffer to target"><span><Button size="small" variant="outlined" color="secondary" disabled={busy} onClick={adjustToTargetWeights}>Adjust to targets</Button></span></Tooltip>
							<IconButton size="small" onClick={fetchCurrent} disabled={currentLoading}><RefreshIcon fontSize="small" /></IconButton>
						</Stack>
					</Stack>
					{/* Stacked bar of actual vs target weights (color-coded actual, vertical markers for target) */}
					<Box mt={2}>
						<Typography variant="caption" sx={{ opacity:0.7, display:'flex', alignItems:'center', gap:0.5 }}>Allocation vs Target <InfoOutlinedIcon fontSize="inherit" /></Typography>
						<Box sx={{ mt:0.5, borderRadius:1, overflow:'hidden', border:'1px solid', borderColor:'divider', position:'relative', height:24, display:'flex' }}>
							{current.venues.map((v:any, idx:number)=> {
								const actualPct = current.deployedUsd>0 ? v.usd/current.deployedUsd : 0;
								return <Box key={v.key}
									sx={{ flex: actualPct, bgcolor: colorFor(v.key, idx), opacity:0.4, position:'relative' }} />;
							})}
							{/* Target overlay markers */}
							{current.venues.map((v:any, idx:number)=> {
								const targetPct = v.weightTarget;
								return <Box key={v.key+'-marker'} sx={{ position:'absolute', left:`${(targetPct*100).toFixed(2)}%`, top:0, bottom:0, width:2, bgcolor: colorFor(v.key, idx) }} />;
							})}
						</Box>
						<Stack direction='row' spacing={1} flexWrap='wrap' mt={1} alignItems="center">
							<Typography variant="caption" sx={{opacity:0.6, mr:1}}>Legend: actual% (of deployed) / target% (drift)</Typography>
							{current.venues.map((v:any, idx:number)=> {
								const actualPct = current.deployedUsd>0 ? v.usd/current.deployedUsd : 0;
								const color = colorFor(v.key, idx);
								return (
									<Chip key={v.key}
										size='small'
										label={`${v.key} ${(actualPct*100).toFixed(2)}% / ${(v.weightTarget*100).toFixed(2)}% (${v.driftBps}bps)`}
										variant='outlined'
										sx={{ borderColor: color, color }}
										icon={<Box sx={{ width:10, height:10, borderRadius:0.5, bgcolor: color, mr:0.5 }} /> as any}
									/>
								);
							})}
						</Stack>
					</Box>
				</Paper>

				{/* Manual Actions Queue */}
				<Paper variant="outlined" sx={{ p:2 }}>
					<Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 1 }}>
						<Typography variant="h6">Manual Actions Queue</Typography>
						<IconButton onClick={()=> refreshPlanned()}><RefreshIcon/></IconButton>
					</Stack>
					{plannedError && <Alert severity="warning">{plannedError}</Alert>}
					<TableContainer component={Paper} variant="outlined">
						<Table size="small">
							<TableHead>
								<TableRow>
									<TableCell>ID</TableCell><TableCell>Venue</TableCell><TableCell align="right">Amount (PI)</TableCell><TableCell>Status</TableCell><TableCell>Created</TableCell><TableCell>Note</TableCell><TableCell align="right">Actions</TableCell>
								</TableRow>
							</TableHead>
							<TableBody>
								{planned.map(r => (
									<TableRow key={r.id}>
										<TableCell sx={{ fontFamily:'monospace' }}>{r.id}</TableCell>
										<TableCell>{r.venue}</TableCell>
										<TableCell align="right">{r.amountPI.toLocaleString()}</TableCell>
										<TableCell>{r.status}</TableCell>
										<TableCell>{timeago(r.createdAt)}</TableCell>
										<TableCell>{r.note || ''}</TableCell>
										<TableCell align="right"><Button size="small" variant="contained" onClick={()=> openConfirm(r.id)}>Confirm</Button></TableCell>
									</TableRow>
								))}
								{planned.length===0 && (
									<TableRow>
										<TableCell colSpan={7} align="center">{plannedLoading ? <CircularProgress size={20}/> : 'No planned actions'}</TableCell>
									</TableRow>
								)}
							</TableBody>
						</Table>
					</TableContainer>
				</Paper>

				<Modal open={confirmOpen} onClose={closeConfirm}>
					<Box sx={{ position:'fixed', top:'50%', left:'50%', transform:'translate(-50%, -50%)', width:{ xs:'90%', sm:480 }, bgcolor:'background.paper', border:'1px solid rgba(255,255,255,0.1)', borderRadius:2, p:2 }}>
						<Typography variant="h6" sx={{ mb:1 }}>Confirm Fill</Typography>
						{selected && (
							<Box sx={{ display:'flex', flexDirection:'column', gap:1 }}>
								<Typography variant="body2">Action: {selected.id} • {selected.venue} • {selected.amountPI.toLocaleString()} PI</Typography>
								<TextField label="Avg Price USD" type="number" value={avgPriceUSD} onChange={e=> setAvgPriceUSD(e.target.value)} fullWidth />
								<TextField label="Fee USD" type="number" value={feeUSD} onChange={e=> setFeeUSD(e.target.value)} fullWidth />
								<TextField label="Tx URL" value={txUrl} onChange={e=> setTxUrl(e.target.value)} fullWidth />
								<TextField label="Idempotency Key (optional)" value={idemKey} onChange={e=> setIdemKey(e.target.value)} fullWidth />
								<Typography variant="body2" sx={{ opacity:0.7 }}>USD impact preview: {formatUSD(usdImpact)}</Typography>
								<Stack direction="row" gap={1} justifyContent="flex-end" sx={{ mt:1 }}>
									<Button onClick={closeConfirm}>Cancel</Button>
									<Button variant="contained" disabled={!canSubmit || confirmBusy} onClick={submitConfirm}>{confirmBusy? 'Working…' : 'Confirm'}</Button>
								</Stack>
							</Box>
						)}
					</Box>
				</Modal>
				</>
			)}
			<GovAllocationHistoryChart className="" limit={150} />
			<Box>
				<Typography variant="h5" fontWeight={600}>Allocation Planner</Typography>
				<Typography variant="body2" sx={{ opacity:0.65 }}>Preview & simulate venue rebalances. Weights must sum to 1.0.</Typography>
			</Box>

			{!token && (
				<Alert severity="warning" variant="outlined" action={
					<Box component="form" onSubmit={e=>{e.preventDefault(); const form=e.currentTarget; const inp=form.querySelector('input[name=devtok]') as HTMLInputElement; setToken(inp.value.trim());}} sx={{display:'flex',alignItems:'center',gap:1}}>
						<TextField size="small" name="devtok" placeholder="dev pi_dev_address:1" />
						<Button type="submit" size="small" variant="contained">Set Token</Button>
					</Box>
				}>
					Dev token required for preview / execute. Public rates still load without it.
				</Alert>
			)}

			{error && (
				<Alert severity="error" variant="outlined" onClose={dismissError}>{error}</Alert>
			)}

			<Stack direction={{ xs:'column', lg:'row' }} spacing={4} alignItems="flex-start">
				<Stack spacing={4} flex={2} minWidth={0}>
					{/* Live Rates */}
					<Paper variant="outlined" sx={{ p:2 }}>
						<Stack direction="row" alignItems="center" spacing={2} mb={1}>
							<Typography variant="subtitle2" fontWeight={600}>Live Rates</Typography>
							<TextField size="small" placeholder="filter (aave arbitrum usdt)" value={rateFilter} onChange={e=>setRateFilter(e.target.value)} fullWidth />
							<Tooltip title="Reload (bypass cache)"><span><IconButton size="small" disabled={ratesLoading} onClick={()=> fetchRates(true)}><RefreshIcon fontSize="small" /></IconButton></span></Tooltip>
						</Stack>
						{ratesError && <Alert severity="error" variant="outlined" sx={{ mb:1 }}>{ratesError}</Alert>}
						{!ratesError && Object.keys(providerErrors).length>0 && (
							<Alert severity="warning" variant="outlined" sx={{ mb:1 }}>
								Some providers failed: {Object.entries(providerErrors).map(([k,v])=> `${k}: ${String(v).split(/[:\n]/)[0]}`).join('; ')}
							</Alert>) }
						{ratesFetchedAt && (
							<Typography variant="caption" sx={{ display:'block', mb:1, opacity:0.6 }}>Fetched {timeago(ratesFetchedAt)}{ratesLoading ? ' (refreshing...)':''}</Typography>
						)}
						<TableContainer sx={{ maxHeight: 300 }}>
							<Table size="small" stickyHeader>
								<TableHead>
									<TableRow>
										<TableCell>Venue</TableCell>
										<TableCell>Chain</TableCell>
										<TableCell>Market</TableCell>
										<TableCell>Base APR</TableCell>
										<TableCell>Reward APR</TableCell>
										<TableCell>Total APY</TableCell>
										<TableCell>Updated</TableCell>
									</TableRow>
								</TableHead>
								<TableBody>
									{rates.length === 0 && (
										<TableRow><TableCell colSpan={7}><Typography variant="caption" sx={{opacity:0.6}}>No rates</Typography></TableCell></TableRow>
									)}
									{[...rates]
										.filter(r => {
											if (!rateFilter.trim()) return true;
											return rateFilter.toLowerCase().split(/\s+/).every(tok => [r.venue,r.chain,r.market].some(f=>f.toLowerCase().includes(tok)));
										})
										.sort((a,b)=> b.baseApr - a.baseApr)
										.map(r => {
											const total = totalApy(r);
											return (
												<TableRow key={r.venue+':'+r.chain+':'+r.market} hover>
													<TableCell>{r.venue}</TableCell>
													<TableCell>{r.chain}</TableCell>
													<TableCell>{r.market}</TableCell>
													<TableCell>{formatPercent(r.baseApr)}</TableCell>
													<TableCell>{r.rewardApr!=null? formatPercent(r.rewardApr): '—'}</TableCell>
													<TableCell>{formatPercent(total)}</TableCell>
													<TableCell>{timeago(r.asOf)}</TableCell>
												</TableRow>
											);
										})}
								</TableBody>
							</Table>
						</TableContainer>
					</Paper>

					{/* Holdings Editor */}
					<Paper variant="outlined" sx={{ p:2 }}>
						<Stack direction="row" alignItems="center" justifyContent="space-between" mb={1}>
							<Typography variant="subtitle2" fontWeight={600}>Holdings (USD) <Typography component="span" variant="caption" sx={{opacity:0.5}}>(max {MAX_ROWS})</Typography></Typography>
							<Tooltip title="Auto allocate from top APY"><span><Button size="small" variant="outlined" startIcon={<AutoFixHighIcon />} disabled={!rates.length} onClick={autoAllocateHoldings}>Auto</Button></span></Tooltip>
						</Stack>
						<Table size="small">
							<TableHead>
								<TableRow>
									<TableCell>Key</TableCell>
									<TableCell>Chain</TableCell>
									<TableCell align="right">USD</TableCell>
									<TableCell></TableCell>
								</TableRow>
							</TableHead>
							<TableBody>
								{holdings.map((h,i)=>{
									const { venue, market, chain } = parseKey(h.key);
									const opts = venue && market ? chainsFor(venue, market) : [];
									return (
										<TableRow key={i}>
											<TableCell sx={{ minWidth: 200 }}>
												<TextField size="small" value={h.key} onChange={e=>updateHolding(i,'key',e.target.value)} placeholder="aave:chain:USDT" fullWidth />
											</TableCell>
											<TableCell sx={{ width:140 }}>
												{opts.length ? (
													<TextField size="small" select SelectProps={{native:true}} value={chainForKey(h.key)} onChange={e=> { if (!venue||!market) return; updateHolding(i,'key',`${venue}:${e.target.value}:${market}`); }} fullWidth>
														<option value="">(auto)</option>
														{opts.map(c=> <option key={c} value={c}>{c}</option>)}
													</TextField>
												) : (
													<Typography variant="caption" sx={{opacity:0.6}}>{chain||'—'}</Typography>
												)}
											</TableCell>
											<TableCell align="right" sx={{ width:150 }}>
												<TextField size="small" type="number" inputProps={{ step:0.01, min:0 }} value={h.usd} onChange={e=>updateHolding(i,'usd',e.target.value)} fullWidth />
											</TableCell>
											<TableCell align="right" sx={{ width:40 }}>
												{holdings.length>1 && (
													<IconButton size="small" aria-label="remove holding" onClick={()=> setHoldings(prev=> prev.filter((_,idx)=> idx!==i))}><DeleteOutlineIcon fontSize="small" /></IconButton>
												)}
											</TableCell>
										</TableRow>
									);
								})}
								<TableRow>
									<TableCell colSpan={4}>
										<Button size="small" startIcon={<AddIcon />} disabled={holdings.length>=MAX_ROWS} onClick={addHolding}>Add Holding</Button>
									</TableCell>
								</TableRow>
							</TableBody>
						</Table>
					</Paper>

					{/* Targets Editor */}
					<Paper variant="outlined" sx={{ p:2 }}>
						<Stack direction="row" alignItems="center" justifyContent="space-between" mb={1}>
							<Typography variant="subtitle2" fontWeight={600}>Targets (weights) <Typography component="span" variant="caption" sx={{opacity:0.5}}>(max {MAX_ROWS})</Typography></Typography>
							<Stack direction="row" spacing={1} alignItems="center">
								<Chip size="small" label={`Sum ${weightSum.toFixed(4)}`} color={Math.abs(weightSum-1)<=1e-6? 'success':'warning'} variant={Math.abs(weightSum-1)<=1e-6? 'filled':'outlined'} />
								<Tooltip title="Suggest from live rates"><span><Button size="small" variant="outlined" onClick={suggestFromRates} disabled={!rates.length}>Suggest</Button></span></Tooltip>
							</Stack>
						</Stack>
						<Table size="small">
							<TableHead>
								<TableRow>
									<TableCell>Key</TableCell>
									<TableCell>Chain</TableCell>
									<TableCell align="right">Weight</TableCell>
									<TableCell align="right">APY</TableCell>
									<TableCell></TableCell>
								</TableRow>
							</TableHead>
							<TableBody>
								{targets.map((t,i)=> {
									const { venue, market, chain } = parseKey(t.key);
									const opts = venue && market ? chainsFor(venue, market) : [];
									const rateRow = rates.find(r=> normalizedKey(r)===t.key);
									const apy = rateRow? totalApy(rateRow): undefined;
									return (
										<TableRow key={i} selected={Math.abs(weightSum-1)>1e-6 && i===0}>
											<TableCell sx={{ minWidth: 200 }}>
												<TextField size="small" value={t.key} onChange={e=>updateTarget(i,'key',e.target.value)} placeholder="aave:chain:USDT" fullWidth />
											</TableCell>
											<TableCell sx={{ width:140 }}>
												{opts.length ? (
													<TextField size="small" select SelectProps={{native:true}} value={chainForKey(t.key)} onChange={e=> { if (!venue||!market) return; updateTarget(i,'key',`${venue}:${e.target.value}:${market}`); }} fullWidth>
														<option value="">(auto)</option>
														{opts.map(c=> <option key={c} value={c}>{c}</option>)}
													</TextField>
												) : (
													<Typography variant="caption" sx={{opacity:0.6}}>{chain||'—'}</Typography>
												)}
											</TableCell>
											<TableCell align="right" sx={{ width:160 }}>
												<TextField
													size="small"
													type="number"
													value={t.weight}
													onChange={e=>updateTarget(i,'weight',e.target.value)}
													onBlur={()=> {
														setTargets(prev => {
															const next = prev.map((row,idx)=> idx===i ? { ...row, weight: clamp01(row.weight)} : { ...row, weight: clamp01(row.weight)});
															const sum = next.reduce((s,x)=> s + x.weight, 0);
															if (sum === 0) return next;
															return next.map(x => ({ ...x, weight: x.weight / sum }));
														});
													}}
													inputProps={{ step:0.0001, min:0, max:1 }}
													error={t.weight<0 || t.weight>1}
												/>
											</TableCell>
											<TableCell align="right" sx={{ width:120 }}>
												<Typography variant="caption" sx={{opacity: apy!=null?1:0.4}}>{apy!=null? formatPercent(apy): '—'}</Typography>
											</TableCell>
											<TableCell align="right" sx={{ width:40 }}>
												{targets.length>1 && (
													<IconButton size="small" aria-label="remove target" onClick={()=> setTargets(prev=> prev.filter((_,idx)=> idx!==i))}><DeleteOutlineIcon fontSize="small" /></IconButton>
												)}
											</TableCell>
										</TableRow>
									);
								})}
								<TableRow>
									<TableCell colSpan={5}>
										<Button size="small" startIcon={<AddIcon />} disabled={targets.length>=MAX_ROWS} onClick={addTarget}>Add Target</Button>
									</TableCell>
								</TableRow>
							</TableBody>
						</Table>
						{Math.abs(weightSum-1)>1e-6 && <Typography variant="caption" color="warning.main">Weights must sum to 1.0 (current {weightSum.toFixed(4)})</Typography>}
					</Paper>

					{/* Actions */}
					{dupError && <Alert severity="error" variant="outlined">{dupError}</Alert>}
					<Stack direction={{ xs:'column', sm:'row' }} spacing={2}>
						<Button onClick={doPreview} disabled={busy || !!dupError} variant="contained" color="primary" fullWidth>{busy? 'Working…':'Preview'}</Button>
						<Button onClick={doExecute} disabled={busy || !preview || preview.length===0 || !!dupError} variant="contained" color="success" fullWidth>Execute</Button>
					</Stack>

					{/* Preview */}
					<Paper variant="outlined" sx={{ p:2 }}>
						<Typography variant="subtitle2" fontWeight={600} mb={1}>Preview Result</Typography>
						{preview == null && <Typography variant="caption" sx={{opacity:0.6}}>No preview yet.</Typography>}
						{preview && preview.length === 0 && <Typography variant="caption" sx={{opacity:0.8}}>No rebalance needed (below threshold).</Typography>}
						{preview && preview.length > 0 && (
							<Stack spacing={1}>
								{preview.map((a,i)=> {
									const ch = a.key ? chainForKey(a.key) : '';
									const rateRow = a.key ? rates.find(r=> normalizedKey(r)===a.key) : undefined;
									const apy = rateRow? totalApy(rateRow): undefined;
									return (
										<Paper key={i} variant="outlined" sx={{ p:1, display:'flex', alignItems:'center', gap:1, bgcolor:'transparent' }}>
											<Chip size="small" label={a.kind} color={a.kind==='increase'? 'success': a.kind==='decrease'? 'error':'info'} />
											<Typography variant="caption" sx={{ flex:1 }}>{a.key || a.kind}{ch? ` (${ch})`:''}</Typography>
											{apy!=null && <Chip size="small" variant="outlined" label={formatPercent(apy)} />}
											<Typography variant="caption" sx={{ fontVariantNumeric:'tabular-nums' }}>{formatUSD(a.usd)}</Typography>
										</Paper>
									);
								})}
							</Stack>
						)}
					</Paper>
				</Stack>

				{/* Guardrails + meta side column */}
				<Stack flex={1} spacing={4} minWidth={300}>
					<Accordion defaultExpanded disableGutters>
						<AccordionSummary expandIcon={<ExpandMoreIcon />}>
							<Typography variant="subtitle2" fontWeight={600}>Guardrails</Typography>
						</AccordionSummary>
						<AccordionDetails>
							<Stack spacing={2}>
								<TextField size="small" label="Max Single Venue % (0-1)" value={guards.maxSingleVenuePct || ''} onChange={e=>setGuards(g=>({...g, maxSingleVenuePct:e.target.value}))} helperText="Cap fraction any single venue may reach" />
								<TextField size="small" label="Max New Allocation % (0-1)" value={guards.maxNewPct || ''} onChange={e=>setGuards(g=>({...g, maxNewPct:e.target.value}))} helperText="Maximum net increase fraction per cycle" />
								<TextField size="small" label="Min Ticket USD" value={guards.minTicketUsd || ''} onChange={e=>setGuards(g=>({...g, minTicketUsd:e.target.value}))} helperText="Skip trades below this size" />
								<TextField size="small" label="Dust USD" value={guards.dustUsd || ''} onChange={e=>setGuards(g=>({...g, dustUsd:e.target.value}))} helperText="Suppress near-zero deltas" />
								<Stack direction="row" spacing={1}>
									<Button size="small" variant="outlined" startIcon={<SettingsBackupRestoreIcon />} onClick={restoreGuards}>Restore defaults</Button>
								</Stack>
								<Typography variant="caption" sx={{ opacity:0.6 }}>Server enforces: max 3 holdings & 3 targets, duplicates only forbidden within each list.</Typography>
							</Stack>
						</AccordionDetails>
					</Accordion>
					<Paper variant="outlined" sx={{ p:2 }}>
						<Typography variant="subtitle2" fontWeight={600} gutterBottom>Notes</Typography>
						<Typography variant="caption" component="div" sx={{ lineHeight:1.5 }}>
							Preview and Execute calls remain unchanged. &quot;Suggest&quot; ranks highest APY venues. Weights auto-normalize on blur. Chips show action types & APY context.
						</Typography>
					</Paper>
				</Stack>
			</Stack>
			{busy && <CircularProgress size={28} sx={{ position:'fixed', bottom:24, right:24 }} />}
		</Box>
	);
}
