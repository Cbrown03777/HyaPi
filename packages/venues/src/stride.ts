/**
 * Stride connector (fallback env-based APRs)
 */
import { Rate, VenueConnector } from './types';

const STRIDE_FALLBACK: Record<string, number> = {
	stATOM: Number(process.env.STRIDE_STATOM_APR ?? '0.12'),
	stTIA: Number(process.env.STRIDE_STTIA_APR ?? '0.14')
};

export const stride: VenueConnector = {
	async getLiveRates(markets) {
		const now = new Date().toISOString();
		const symbols = markets?.length ? markets : Object.keys(STRIDE_FALLBACK);
		return symbols.map<Rate>(s => ({
			venue: 'stride',
			chain: 'cosmos',
			market: s,
			baseApr: STRIDE_FALLBACK[s] ?? 0.12,
			baseApy: (1 + (STRIDE_FALLBACK[s] ?? 0.12)/365)**365 - 1,
			asOf: now
		}));
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
