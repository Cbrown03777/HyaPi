/**
 * Stride connector (fallback env-based APRs)
 */
import { Rate, VenueConnector } from './types';

// Demo fallback APRs (will be replaced by live Stride / external API integration)
// Snapshot (intended for Pi Core Team demo Sept 19) with per-call env reload so
// changing STRIDE_* env vars + a hot reload (Next dev / process restart in prod)
// updates values without needing to rebuild this package.
function currentAprMap(): Record<string, number> {
	const n = (v: string | undefined, d: string) => {
		if (v == null || v.trim() === '') return Number(d);
		const parsed = Number(v);
		return Number.isFinite(parsed) ? parsed : Number(d);
	};
	return {
		stATOM: n(process.env.STRIDE_STATOM_APR, '0.1514'),
		stTIA:  n(process.env.STRIDE_STTIA_APR,  '0.11'),
		stJUNO: n(process.env.STRIDE_STJUNO_APR, '0.2262'),
		stLUNA: n(process.env.STRIDE_STLUNA_APR, '0.1772'),
		stBAND: n(process.env.STRIDE_STBAND_APR, '0.1543'),
	};
}

export const stride: VenueConnector = {
	async getLiveRates(markets) {
		const now = new Date().toISOString();
		const aprs = currentAprMap();
		const symbols = markets?.length ? markets : Object.keys(aprs);
		return symbols.map<Rate>(s => {
			const apr = aprs[s] ?? 0.12;
			return {
				venue: 'stride',
				chain: 'cosmos',
				market: s,
				baseApr: apr,
				baseApy: (1 + apr/365)**365 - 1,
				asOf: now
			};
		});
	},
	estimateApy(rate, opts) {
		const comp = Math.max(1, opts?.compounding ?? 365);
		const fee = Math.max(0, opts?.feeBps ?? 0) / 10_000;
		const gross = (1 + rate.baseApr / comp)**comp - 1;
		return Math.max(0, gross * (1 - fee));
	},
	async deposit() { throw new Error('NOT_IMPLEMENTED: Stride deposit will require IBC/Cosmos signer workflows.'); },
	async withdraw() { throw new Error('NOT_IMPLEMENTED: Stride withdraw will require unbonding/redeem logic.'); }
};

export default stride;
