import { Router, Request, Response } from 'express';
import { aave as aaveConnector, justlend as justlendConnector, stride as strideConnector, type Rate } from '@hyapi/venues';
import { db } from '../services/db';
import { setTimeout as delay } from 'node:timers/promises';

export const venuesRouter = Router();

// Build connectors once (env read on module load)
const connectors = [
	{ name: 'aave',     getRates: () => aaveConnector.getLiveRates(['USDT','USDC','DAI','AUSD']) },
	{ name: 'justlend', getRates: () => justlendConnector.getLiveRates(['USDT','USDD']) },
	// Include all currently supported Stride liquid staking tokens (env APR fallbacks in connector)
	{ name: 'stride',   getRates: () => strideConnector.getLiveRates(['stATOM','stTIA','stJUNO','stLUNA','stBAND']) },
] as const;

// Simple helper to enforce a timeout on a promise
async function withTimeout<T>(p: Promise<T>, ms: number, label: string): Promise<T> {
	let to: NodeJS.Timeout;
	const timeoutPromise = new Promise<never>((_, reject) => {
		to = setTimeout(() => reject(new Error(label + ' timeout after ' + ms + 'ms')), ms);
	});
	try {
		return await Promise.race([p, timeoutPromise]);
	} finally {
		clearTimeout(to!);
	}
}

type Cache = { ts: number; data: (Rate & { source?: string })[] };
let cache: Cache | null = null;
const TTL_MS = Number(process.env.VENUES_CACHE_TTL_MS ?? 60_000);

venuesRouter.get('/rates', async (req: Request, res: Response) => {
	try {
		const now = Date.now();
		const debug = req.query.debug === '1';
		if (!debug && cache && now - cache.ts < TTL_MS) {
			return res.json({ success: true, cached: true, data: cache.data });
		}

		const started = Date.now();
		const timeoutMs = Number(process.env.VENUE_RATE_TIMEOUT_MS ?? 5_000);
		const results = await Promise.allSettled(
			connectors.map(async (c) => {
				try {
					const r = await withTimeout(c.getRates(), timeoutMs, c.name);
					// Do not overwrite existing rate.source (e.g., gql vs llama) – only set if missing.
					return (r as any[]).map(x => ({ ...x, source: (x as any).source || c.name }));
				} catch (err:any) {
					console.error(`[venues.rates] provider ${c.name} error:`, err?.message);
					throw err;
				}
			})
		);

		const merged: (Rate & { source?:string })[] = [];
		const errors: Record<string,string> = {};
		results.forEach((r,i) => {
			const name = connectors[i].name;
			if (r.status === 'fulfilled') merged.push(...r.value);
			else errors[name] = (r.reason?.message ?? 'failed');
		});

		const elapsed = Date.now() - started;
		const successProviders = connectors.filter((_,i)=> results[i].status === 'fulfilled').length;
		const failProviders = connectors.length - successProviders;
		console.log(`[venues.rates] fetched in ${elapsed}ms ok=${successProviders} fail=${failProviders} cached=${false}`);

		if (!debug && merged.length > 0) cache = { ts: now, data: merged };

		// Persist snapshot asynchronously (fire & forget) if we have rows
		if (merged.length > 0) {
			(async () => {
				// Insert minimal required legacy columns first (key, base_apr, as_of)
				const insertBase = `INSERT INTO venue_rates (key, base_apr, as_of) VALUES ${merged.map((_,i)=>`($${i*3+1},$${i*3+2},$${i*3+3})`).join(',')}`;
				const baseVals: any[] = [];
				for (const r of merged) baseVals.push(`${r.venue}:${r.market}`, r.baseApr, r.asOf);
				try { await db.query(insertBase, baseVals); } catch (e:any) { console.error('venue_rates base insert error', e.message); }
				// Enhance rows with new columns if they exist (best-effort)
				for (const r of merged) {
					try {
						await db.query(`UPDATE venue_rates SET venue=$1, chain=$2, market=$3, base_apy=$4, reward_apr=$5, reward_apy=$6, source=$7, fetched_at=now() WHERE key=$8 AND as_of=$9`, [r.venue, r.chain, r.market, r.baseApy ?? null, (r as any).rewardApr ?? null, (r as any).rewardApy ?? null, r.source ?? null, `${r.venue}:${r.market}`, r.asOf]);
					} catch (e:any) {
						// Ignore if column missing or duplicate
					}
				}
			})();
		}

		res.json({ success:true, cached:false, data: merged, ...(Object.keys(errors).length ? { errors } : {}) });
	} catch (e:any) {
		console.error('[venues.rates] error', e?.message);
		res.status(500).json({ success:false, error:{ code:'SERVER', message: e?.message ?? 'rates failed' }});
	}
});
