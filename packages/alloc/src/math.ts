import { Rate, GovWeights, TargetWeights, Guardrails, Holdings, VenueId } from "./types";

function keyOf(r: Rate) { return `${r.venue}:${r.market}`; }

function softmax(scores: number[], k: number) {
	const scaled = scores.map(s => Math.exp(k * s));
	const sum = scaled.reduce((a,b)=>a+b, 0);
	return scaled.map(x => (sum ? x/sum : 0));
}

export function normalize(x: Record<string, number>) {
	const sum = Object.values(x).reduce((a,b)=>a+b, 0);
	if (sum <= 0) return x;
	const out: Record<string, number> = {};
	for (const [k,v] of Object.entries(x)) out[k] = v / sum;
	return out;
}

export function sinceIsoSec(iso: string) {
	return (Date.now() - new Date(iso).getTime())/1000;
}

export function computeTargets(
	gov: GovWeights,
	rates: Rate[],
	guards: Guardrails
): TargetWeights {
	const fresh = rates.filter(r =>
		guards.allowVenue[r.venue as VenueId] &&
		sinceIsoSec(r.asOf) <= guards.staleRateMaxSec
	);
	if (!fresh.length) return normalize({...gov});

	const apy: Record<string, number> = {};
	for (const r of fresh) {
		const effectiveApy = r.baseApy ?? (Math.pow(1 + r.baseApr/365, 365) - 1);
		apy[keyOf(r)] = effectiveApy;
	}

	const keys = Object.keys(apy);
	const scores = keys.map(k => apy[k]);
	const pref = softmax(scores, guards.softmaxK);
	const prefMap: Record<string, number> = {};
	keys.forEach((k,i) => prefMap[k] = pref[i]);

	const unionKeys = new Set([...Object.keys(gov), ...Object.keys(prefMap)]);
	const blended: Record<string, number> = {};
	for (const k of unionKeys) {
		const g = gov[k] ?? 0;
		const p = prefMap[k] ?? 0;
		blended[k] = guards.lambda * g + (1 - guards.lambda) * p;
	}

	const capped = {...blended};
	const byVenue: Record<string, number> = {};
	for (const [k,w] of Object.entries(capped)) {
		const venue = k.split(":")[0] as VenueId;
		byVenue[venue] = (byVenue[venue] ?? 0) + w;
	}
	let excess = 0;
	for (const [v,total] of Object.entries(byVenue)) {
		const cap = (guards.maxVenueBps[v as VenueId] ?? 10_000)/10_000;
		if (total > cap) excess += (total - cap);
	}
	if (excess > 1e-9) {
		const scale: Record<string, number> = {};
		for (const [v,total] of Object.entries(byVenue)) {
			const cap = (guards.maxVenueBps[v as VenueId] ?? 10_000)/10_000;
			scale[v] = Math.min(1, cap / Math.max(total, 1e-12));
		}
		for (const k of Object.keys(capped)) {
			const v = k.split(":")[0];
			capped[k] = capped[k] * scale[v];
		}
		return normalize(capped);
	}

	return normalize(capped);
}

export function planRebalance(args: {
	tvlUSD: number;
	bufferBps: number;
	current: Holdings;
	targetWeights: TargetWeights;
	minTradeUSD: number;
	maxDriftBps: number;
}) {
	const { tvlUSD, bufferBps, current, targetWeights, minTradeUSD, maxDriftBps } = args;
	const bufferUSD = (bufferBps/10_000)*tvlUSD;
	const investable = Math.max(0, tvlUSD - bufferUSD);
	const targetsUSD: Record<string, number> = {};
	for (const [k,w] of Object.entries(targetWeights)) targetsUSD[k] = w * investable;

	const allKeys = new Set([...Object.keys(current), ...Object.keys(targetsUSD)]);
	let driftAbs = 0, base = 0;
	for (const k of allKeys) {
		const cur = current[k] ?? 0;
		const tar = targetsUSD[k] ?? 0;
		driftAbs += Math.abs(cur - tar);
		base += Math.max(cur, tar);
	}
	const driftBps = base ? Math.round(10_000 * driftAbs / base) : 0;
	if (driftBps < maxDriftBps) {
		return { bufferUSD, actions: [], totalDeltaUSD: 0, driftBps };
	}

	const actions: { kind:"increase"|"decrease"|"buffer"; key?:string; deltaUSD:number }[] = [];
	let totalDelta = 0;
	for (const k of allKeys) {
		const cur = current[k] ?? 0;
		const tar = targetsUSD[k] ?? 0;
		const delta = tar - cur;
		if (Math.abs(delta) >= minTradeUSD) {
			actions.push({ kind: delta >= 0 ? "increase" : "decrease", key: k, deltaUSD: Math.abs(delta) });
			totalDelta += Math.abs(delta);
		}
	}
	if (bufferUSD > 0) actions.push({ kind: "buffer", deltaUSD: bufferUSD });

	return { bufferUSD, actions, totalDeltaUSD: totalDelta, driftBps };
}
