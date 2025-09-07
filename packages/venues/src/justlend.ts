/**
 * JustLend REST connector (new schema)
 */
import { httpJSON } from './http';
import { Rate, VenueConnector } from './types';

const JL = process.env.JUSTLEND_BASE ?? 'https://openapi.just.network';

type JTokenResponse = {
	code: number;
	message: string;
	data: { tokenList: Array<{ symbol: string; supplyApy?: string; miningSupplyApy?: string; supplyRatePerBlock?: string; }> };
};

function pctStrToDec(v?: string): number {
	if (!v) return 0; const n = Number(v); return Number.isFinite(n)? n/100 : 0;
}

export const justlend: VenueConnector = {
	async getLiveRates(markets) {
		const res = await httpJSON<JTokenResponse>(`${JL}/lend/jtoken`);
		const now = new Date().toISOString();
		const list = res?.data?.tokenList ?? [];
		return list
			.filter(m => {
				// Determine underlying market key
				const underlying = (m as any).underlyingSymbol || m.symbol.replace(/^j/,'');
				if (markets?.length) return markets.includes(underlying) || markets.includes(m.symbol);
				return true;
			})
			.filter(m => {
				const underlying = (m as any).underlyingSymbol || m.symbol.replace(/^j/,'');
				return ['USDT','USDC','USDD','TRX'].includes(underlying);
			})
			.map<Rate>(m => {
				const underlying = (m as any).underlyingSymbol || m.symbol.replace(/^j/,'');
				let baseApy = pctStrToDec((m as any).supplyApy);
				const rewardApy = pctStrToDec((m as any).miningSupplyApy);
				// If baseApy missing but supplyRate present treat supplyRate as APR approximation
				let baseApr: number;
				if (!baseApy && (m as any).supplyRate) {
					const sr = Number((m as any).supplyRate);
					if (Number.isFinite(sr)) {
						baseApr = sr; // assume already decimal APR
						baseApy = (1 + baseApr/365)**365 - 1;
					} else baseApr = 0;
				} else {
					baseApr = baseApy ? Math.log(1 + baseApy) : 0;
				}
				return {
					venue: 'justlend',
					chain: 'tron',
					market: underlying,
					baseApr,
					baseApy,
					rewardApr: rewardApy ? Math.log(1 + rewardApy) : undefined,
					rewardApy,
					asOf: now
				};
			});
	},
	estimateApy(rate, opts) {
		const comp = Math.max(1, opts?.compounding ?? 365);
		const fee = Math.max(0, opts?.feeBps ?? 0) / 10_000;
		const grossCore = (1 + (rate.baseApr || 0)/comp)**comp - 1;
		const grossReward = rate.rewardApr ? ( (1 + rate.rewardApr/comp)**comp - 1 ) : 0;
		const gross = grossCore + grossReward;
		return Math.max(0, gross * (1 - fee));
	},
	async deposit() { throw new Error('NOT_IMPLEMENTED: JustLend deposit will require TRON signer integration.'); },
	async withdraw() { throw new Error('NOT_IMPLEMENTED: JustLend withdraw will require TRON signer integration.'); }
};

export default justlend;
