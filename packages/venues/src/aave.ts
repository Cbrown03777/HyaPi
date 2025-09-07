/**
 * Aave V3 GraphQL reference:
 * https://aave.com/docs/developers/aave-v3/markets/data
 * We use the stable, widely supported "reserves" legacy-style query on each chain
 * to fetch liquidityRate (Ray, 1e27) which is the supply APR.
 * We intentionally avoid the newer fragment-heavy schema for simplicity and resilience.
 */
import { httpJSON } from './http'; // NOTE: After editing this file, run `pnpm --filter @hyapi/venues build` to refresh dist/
// On-chain (Arbitrum) support
import { createPublicClient, http as viemHttp, Address, parseAbi } from 'viem';
import { arbitrum, celo, avalanche } from 'viem/chains';
import { Rate, VenueConnector } from './types';

// Per-chain endpoints (override via env if needed)
const AAVE_ENDPOINTS: Record<string,string> = {
	ethereum: process.env.AAVE_GQL_ETHEREUM ?? process.env.AAVE_GQL_URL ?? 'https://api.thegraph.com/subgraphs/name/aave/protocol-v3',
	arbitrum: process.env.AAVE_GQL_ARBITRUM ?? 'https://api.thegraph.com/subgraphs/name/aave/protocol-v3-arbitrum',
	base: process.env.AAVE_GQL_BASE ?? 'https://api.thegraph.com/subgraphs/name/aave/protocol-v3-base',
	celo: process.env.AAVE_GQL_CELO ?? 'https://api.thegraph.com/subgraphs/name/aave/protocol-v3-celo',
	avalanche: process.env.AAVE_GQL_AVALANCHE ?? 'https://api.thegraph.com/subgraphs/name/aave/protocol-v3-avalanche'
};
const AAVE_GQL_KEY = process.env.AAVE_GQL_KEY; // optional api key header (if any endpoint supports it)

const RESERVES_QUERY = `
query Reserves($symbols: [String!]) {
	reserves(where: { symbol_in: $symbols }) {
		symbol
		liquidityRate
	}
}`;

// -------- Arbitrum Gateway (stepwise enhancement) --------
// To enable: set env AAVE_ARB_API_KEY and (optionally) AAVE_ARB_SUBGRAPH_ID (defaults to known id)
// Endpoint pattern: https://gateway-arbitrum.network.thegraph.com/api/${AAVE_ARB_API_KEY}/subgraphs/id/${SUBGRAPH_ID}
const AAVE_ARB_API_KEY = process.env.AAVE_ARB_API_KEY; // DO NOT hardcode secrets.
const AAVE_ARB_SUBGRAPH_ID = process.env.AAVE_ARB_SUBGRAPH_ID ?? '4xyasjQeREe7PxnF6wVdobZvCw5mhoHZq3T7guRpuNPf';
// Correct Arbitrum Aave V3 Pool address
const AAVE_ARB_POOL_ADDR = '0x794a61358D6845594F94dc1DB02A252b5b4814aD';
// Data Provider address (from user provided; ensure correct checksum not required as we lowercase internally)
// Provided ProtocolDataProvider address (may revert on Arbitrum); we fall back to Pool if it fails.
const AAVE_ARB_DATA_PROVIDER = '0x14496b405D62c24F91f04Cda1c69Dc526D56fDE5';
// ---------- CELO (base + incentives) ----------
// Environment provided variables (user supplied) – fall back to placeholders if not set to avoid crashes.
const CELO_POOL_ADDRESS = (process.env.CELO_POOL_ADDRESS || '').trim();
const CELO_USDT_UNDERLYING = (process.env.CELO_USDT_UNDERLYING || '').trim().toLowerCase();
const CELO_UI_INCENTIVES_PROVIDER = (process.env.CELO_UI_INCENTIVES_PROVIDER || '').trim();
// Optional addresses provider (required for incentives provider per contract source) – different from Pool address
const CELO_ADDRESSES_PROVIDER = (process.env.CELO_ADDRESSES_PROVIDER || '').trim();
const ARBITRUM_RPC_URL = process.env.ARBITRUM_RPC_URL || 'https://arb1.arbitrum.io/rpc';
// ---------- AVALANCHE (AUSD base) ----------
const AVALANCHE_POOL_ADDRESS = (process.env.AVALANCHE_POOL_ADDRESS || '0x794a61358D6845594F94dc1DB02A252b5b4814aD').trim();
const AVALANCHE_AUSD_UNDERLYING = (process.env.AVALANCHE_AUSD_UNDERLYING || '0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a').trim().toLowerCase();
const AVALANCHE_RPC_URL = process.env.AVALANCHE_RPC_URL || '';
// Underlying asset addresses (lowercase) for symbols on Arbitrum.
// Aave currently lists USDC.e (bridged) in many deployments; the canonical USDC (0xaf88...) may not have a reserve yet.
// We'll treat a request for 'USDC' as attempting canonical first then USDC.e fallback.
const ARBITRUM_ASSET_ALTS: Record<string,string[]> = {
	USDC: [
		'0xaf88d065e99c1dea569d2d0c242a65660c681985', // canonical USDC
		'0xff970a61a04b1ca14834a43f5de4533ebddb5cc8'  // USDC.e
	],
	USDT: ['0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9'],
	DAI:  ['0xda10009cbd5d07dd0cecc66161fc93d7c9000da1'],
	WETH: ['0x82af49447d8a07e3bd95bd0d56f35241523fbab1'],
	WBTC: ['0x2f2a2543b76a4166549f7aaab6cb7cddedbee1b6']
};
// Convenience single mapping picking the first candidate (used elsewhere for symbol filtering)
const ARBITRUM_ASSETS: Record<string,string> = Object.fromEntries(Object.entries(ARBITRUM_ASSET_ALTS).map(([k,v]) => [k, v[0]]));

function buildArbitrumGatewayQuery(symbols: string[]) {
	// Build a single query using field aliases per reserve id; we request only latest history entry (first:1 ordered desc)
	const parts: string[] = [];
	for (const sym of symbols) {
		const addr = ARBITRUM_ASSETS[sym];
		if (!addr) continue;
		const reserveId = `${addr}-${AAVE_ARB_POOL_ADDR}`.toLowerCase();
		parts.push(`${sym.toLowerCase()}: reserve(id: \"${reserveId}\") { symbol reserveParamsHistory(orderBy: timestamp, orderDirection: desc, first: 1) { timestamp liquidityRate variableBorrowRate } }`);
	}
	return `query ArbitrumReserves {\n${parts.join('\n')}\n}`;
}

const SECONDS_PER_YEAR = 31_536_000; // 365 * 24 * 60 * 60

function rayToAprDecimal(ray: string | number): number {
	const n = typeof ray === 'string' ? Number(ray) : ray;
	if (!Number.isFinite(n)) return 0;
	return n / 1e27;
}

export const aave: VenueConnector = {
	async getLiveRates(markets) {
		const symbols = (markets && markets.length ? markets : ['USDT','USDC','DAI','WETH','WBTC','AUSD']).map(s=>s.toUpperCase());
		const now = new Date().toISOString();
		const headers: Record<string,string> = { 'content-type':'application/json' };
		if (AAVE_GQL_KEY) headers['x-api-key'] = AAVE_GQL_KEY;
		const collected: Rate[] = [];
		const SOURCE_PRIORITY: Record<string,number> = { onchain:3, gql:2, legacy:2, llama:1 };
		function upsert(rate: Rate) {
			const key = `${rate.chain}:${rate.market}`;
			const i = collected.findIndex(r => `${r.chain}:${r.market}` === key);
			if (i === -1) { collected.push(rate); return; }
			const existing = collected[i];
			const ep = SOURCE_PRIORITY[existing.source || ''] || 0;
			const np = SOURCE_PRIORITY[rate.source || ''] || 0;
			if (np > ep || (np === ep && (rate.baseApr ?? 0) > (existing.baseApr ?? 0))) collected[i] = rate;
		}
		// We'll iterate Graph endpoints for legacy fetch later & for fallback detection
		const chainEntries = Object.entries(AAVE_ENDPOINTS);

		// -------- On-chain (Arbitrum) base rates --------
		// Attempt on-chain fetch for Arbitrum (liquidityRate) if RPC available
		try {
			const arbSymbols = symbols.filter(s => ARBITRUM_ASSETS[s]);
			if (arbSymbols.length && ARBITRUM_RPC_URL) {
				const client = createPublicClient({ chain: arbitrum, transport: viemHttp(ARBITRUM_RPC_URL) });
				// Official Pool getReserveData struct (Aave V3):
				// returns (
				//  configuration (uint256), liquidityIndex (uint128), currentLiquidityRate (uint128),
				//  variableBorrowIndex (uint128), currentVariableBorrowRate (uint128), currentStableBorrowRate (uint128),
				//  lastUpdateTimestamp (uint40), id (uint16), aTokenAddress, stableDebtTokenAddress,
				//  variableDebtTokenAddress, interestRateStrategyAddress, accruedToTreasury (uint128),
				//  unbacked (uint128), isolationModeTotalDebt (uint128)
				// )
				const poolAbi = parseAbi([
					'function getReserveData(address asset) view returns (uint256,uint128,uint128,uint128,uint128,uint128,uint40,uint16,address,address,address,address,uint128,uint128,uint128)'
				]);
				for (const sym of arbSymbols) {
					const candidates = ARBITRUM_ASSET_ALTS[sym] || [];
					let got = false;
					for (const addr of candidates) {
						try {
							const res: any = await client.readContract({ address: AAVE_ARB_POOL_ADDR as Address, abi: poolAbi, functionName: 'getReserveData', args: [addr as Address] });
							if (process.env.AAVE_DEBUG === '1') console.log('[aave][arb][onchain] raw', sym, addr.slice(0,10), res);
							const lrRaw = res?.[2]; // currentLiquidityRate
							const lr = Number(lrRaw);
							if (!Number.isFinite(lr) || lr <= 0) {
								continue; // try next candidate
							}
							let baseApr = lr / 1e27;
							if (baseApr > 2) baseApr = baseApr / 1e9; // mis-scale guard
							if (baseApr > 1) baseApr = 1;
							const baseApy = (1 + baseApr/365)**365 - 1;
							upsert({ venue:'aave', chain:'arbitrum', market: sym, baseApr, baseApy, asOf: now, source:'onchain' });
							got = true;
							break;
						} catch (poolErr:any) {
							if (process.env.AAVE_DEBUG === '1') console.warn('[aave][arb][onchain] pool revert', sym, addr.slice(0,10), poolErr?.message);
						}
					}
					if (!got && process.env.AAVE_DEBUG === '1') console.warn('[aave][arb][onchain] no candidate produced rate', sym);
				}
			}
		} catch (e:any) {
			if (process.env.AAVE_DEBUG === '1') console.warn('[aave][arb][onchain] error', e?.message);
		}
		// 1. Specialized Arbitrum gateway query (if credentials present) - higher fidelity historical param capture
		if (AAVE_ARB_API_KEY) {
			try {
				const arbSymbols = symbols.filter(s => ARBITRUM_ASSETS[s]);
				if (arbSymbols.length) {
					const gatewayUrl = `https://gateway-arbitrum.network.thegraph.com/api/${AAVE_ARB_API_KEY}/subgraphs/id/${AAVE_ARB_SUBGRAPH_ID}`;
					const query = buildArbitrumGatewayQuery(arbSymbols);
					const body = JSON.stringify({ query });
					const data = await httpJSON<any>(gatewayUrl, { method: 'POST', headers: { 'content-type':'application/json' }, body });
					if (process.env.AAVE_DEBUG === '1') {
						console.log('[aave][arb][gateway] query', query);
						if (data?.errors) console.warn('[aave][arb][gateway] errors', JSON.stringify(data.errors));
						else console.log('[aave][arb][gateway] keys', Object.keys(data?.data || {}));
					}
					for (const sym of arbSymbols) {
						const node = data?.data?.[sym.toLowerCase()];
						if (!node) { if (process.env.AAVE_DEBUG === '1') console.warn('[aave][arb] missing node for', sym); continue; }
						const hist = node.reserveParamsHistory?.[0];
						if (!hist) { if (process.env.AAVE_DEBUG === '1') console.warn('[aave][arb] no history for', sym); continue; }
						const lrRaw = Number(hist.liquidityRate);
						if (!Number.isFinite(lrRaw)) { if (process.env.AAVE_DEBUG === '1') console.warn('[aave][arb] invalid liquidityRate for', sym, hist.liquidityRate); continue; }
						const simpleRate = lrRaw / 1e27; // nominal APR
						const baseApy = Math.pow(1 + simpleRate / SECONDS_PER_YEAR, SECONDS_PER_YEAR) - 1;
						const baseApr = simpleRate;
						upsert({ venue:'aave', chain:'arbitrum', market: sym, baseApr, baseApy, asOf: now, source:'gql' });
					}
					if (process.env.AAVE_DEBUG === '1') console.log('[aave][arb][gateway] parsed rows', collected.filter(r=>r.chain==='arbitrum').length);
				}
			} catch (err) {
				if (process.env.AAVE_DEBUG === '1') console.warn('[aave][arb][gateway] error', (err as any)?.message);
			}
		}

		// 2. Generic Graph (legacy reserves) for all chains (ethereum, arbitrum, base, celo)
		for (const [chain, endpoint] of chainEntries) {
			try {
				const gqlBody = JSON.stringify({ query: RESERVES_QUERY, variables: { symbols } });
				const data = await httpJSON<any>(endpoint, { method: 'POST', headers, body: gqlBody });
				const reserves = data?.data?.reserves;
				if (Array.isArray(reserves)) {
					for (const r of reserves) {
						const sym = String(r.symbol || '').toUpperCase();
						if (!symbols.includes(sym)) continue;
						const lr = Number(r.liquidityRate);
						if (!Number.isFinite(lr) || lr <= 0) continue;
						let baseApr = lr / 1e27;
						if (baseApr > 2) baseApr = baseApr / 1e9;
						if (baseApr > 1) baseApr = 1;
						const baseApy = (1 + baseApr/365)**365 - 1;
						upsert({ venue:'aave', chain, market: sym, baseApr, baseApy, asOf: now, source:'legacy' });
					}
				}
			} catch (gErr:any) {
				if (process.env.AAVE_DEBUG === '1') console.warn('[aave][gql] chain error', chain, gErr?.message);
			}
		}

		// 3. Celo on-chain base + incentives (clean retry with candidate ABI)
		// 3a. Avalanche on-chain base (AUSD)
		try {
			if (AVALANCHE_POOL_ADDRESS && AVALANCHE_AUSD_UNDERLYING && symbols.includes('AUSD') && AVALANCHE_RPC_URL) {
				const client = createPublicClient({ chain: avalanche, transport: viemHttp(AVALANCHE_RPC_URL) });
				const poolAbi = parseAbi(['function getReserveData(address asset) view returns (uint256,uint128,uint128,uint128,uint128,uint128,uint40,uint16,address,address,address,address,uint128,uint128,uint128)']);
				try {
					const res: any = await client.readContract({ address: AVALANCHE_POOL_ADDRESS as Address, abi: poolAbi, functionName: 'getReserveData', args: [AVALANCHE_AUSD_UNDERLYING as Address] });
					const lr = Number(res?.[2]);
					if (Number.isFinite(lr) && lr>0) {
						let baseApr = lr / 1e27;
						if (baseApr > 2) baseApr = baseApr / 1e9; // mis-scale guard
						if (baseApr > 1) baseApr = 1; // cap
						const baseApy = (1 + baseApr/365)**365 - 1;
						upsert({ venue:'aave', chain:'avalanche', market:'AUSD', baseApr, baseApy, asOf: now, source:'onchain' });
					}
				} catch (avErr:any) { if (process.env.AAVE_DEBUG==='1') console.warn('[aave][avax][onchain] getReserveData error', avErr?.message); }
			}
		} catch(avOuter:any) { if (process.env.AAVE_DEBUG==='1') console.warn('[aave][avax] outer', avOuter?.message); }

		try {
			if (CELO_POOL_ADDRESS && CELO_USDT_UNDERLYING && symbols.includes('USDT') && process.env.CELO_RPC_URL) {
				const client = createPublicClient({ chain: celo, transport: viemHttp(process.env.CELO_RPC_URL) });
				const poolAbi = parseAbi(['function getReserveData(address asset) view returns (uint256,uint128,uint128,uint128,uint128,uint128,uint40,uint16,address,address,address,address,uint128,uint128,uint128)']);
				let baseApr: number | undefined; let baseApy: number | undefined; let supplyUsd: number | undefined;
				try {
					const res: any = await client.readContract({ address: CELO_POOL_ADDRESS as Address, abi: poolAbi, functionName: 'getReserveData', args: [CELO_USDT_UNDERLYING as Address] });
					const lr = Number(res?.[2]);
					if (Number.isFinite(lr) && lr>0) {
						baseApr = lr / 1e27;
						if (baseApr > 2) baseApr = baseApr / 1e9;
						if (baseApr > 1) baseApr = 1;
						baseApy = (1 + baseApr/365)**365 - 1;
					}
					const aToken = res?.[8];
					if (aToken) {
						try {
							const erc20Abi = parseAbi(['function totalSupply() view returns (uint256)','function decimals() view returns (uint8)']);
							const [ts, dec] = await Promise.all([
								client.readContract({ address: aToken as Address, abi: erc20Abi, functionName: 'totalSupply' }) as Promise<any>,
								client.readContract({ address: aToken as Address, abi: erc20Abi, functionName: 'decimals' }) as Promise<any>
							]);
							supplyUsd = Number(ts) / 10 ** Number(dec || 6);
						} catch(sErr:any) { if (process.env.AAVE_DEBUG==='1') console.warn('[aave][celo][supply] error', sErr?.message); }
					}
				} catch (ceErr:any) { if (process.env.AAVE_DEBUG === '1') console.warn('[aave][celo][onchain] getReserveData error', ceErr?.message); }
				let rewardApr: number | undefined; let rewardApy: number | undefined; let notes: string | undefined; const rewardNotes:string[]=[];
				if (baseApr !== undefined && supplyUsd && supplyUsd>0 && CELO_ADDRESSES_PROVIDER) {
					try {
						const candAbi = parseAbi(['function getReservesIncentivesData(address provider) view returns (tuple(address underlyingAsset, tuple(address tokenAddress, address incentiveController, tuple(address rewardTokenAddress,uint256 tokenIncentivesIndex,uint256 emissionPerSecond,uint256 incentivesLastUpdateTimestamp,uint256 emissionEndTimestamp,uint256 precision,uint256 rewardTokenDecimals,string rewardTokenSymbol,address rewardOracleAddress,uint256 priceFeedDecimals,int256 rewardPriceFeed)[] rewards) aIncentiveData, tuple(address tokenAddress, address incentiveController, tuple(address rewardTokenAddress,uint256 tokenIncentivesIndex,uint256 emissionPerSecond,uint256 incentivesLastUpdateTimestamp,uint256 emissionEndTimestamp,uint256 precision,uint256 rewardTokenDecimals,string rewardTokenSymbol,address rewardOracleAddress,uint256 priceFeedDecimals,int256 rewardPriceFeed)[] rewards) vIncentiveData)[])']);
						const raw: any = await client.readContract({ address: CELO_UI_INCENTIVES_PROVIDER as Address, abi: candAbi, functionName: 'getReservesIncentivesData', args: [CELO_ADDRESSES_PROVIDER as Address] });
						if (Array.isArray(raw)) {
							const match = raw.find((r:any)=> r?.underlyingAsset?.toLowerCase?.() === CELO_USDT_UNDERLYING);
							const rewards = match?.aIncentiveData?.rewards || [];
							if (Array.isArray(rewards) && rewards.length) {
								let totalRewardsUsdPerYear = 0;
								for (const rw of rewards) {
									const emissionPerSecond = Number(rw.emissionPerSecond);
									if (!emissionPerSecond || emissionPerSecond<=0) continue;
									const priceFeed = Number(rw.rewardPriceFeed);
									const priceFeedDecimals = Number(rw.priceFeedDecimals)||8;
									const rewardTokenDecimals = Number(rw.rewardTokenDecimals)||18;
									const price = Math.abs(priceFeed) / 10 ** priceFeedDecimals;
									const yearlyTokens = emissionPerSecond * SECONDS_PER_YEAR / 10 ** rewardTokenDecimals;
									const yearlyUsd = yearlyTokens * price;
									if (yearlyUsd>0) { totalRewardsUsdPerYear += yearlyUsd; rewardNotes.push(`CAND:${rw.rewardTokenSymbol||'RWD'}:${emissionPerSecond}`); }
								}
								if (totalRewardsUsdPerYear>0) {
									rewardApr = totalRewardsUsdPerYear / supplyUsd;
									if (rewardApr>5) rewardApr = rewardApr/1e9;
									rewardApy = (1 + (rewardApr||0)/365)**365 -1;
									notes = 'celo_incentives_candidate';
								}
							}
						}
					} catch(cErr:any) { if (process.env.AAVE_DEBUG==='1') console.warn('[aave][celo][incentives][candidate] fail', cErr?.message); }
				}
				if (rewardApr!==undefined) notes = (notes? notes+';':'') + rewardNotes.join(',');
				if (baseApr!==undefined) {
					upsert({ venue:'aave', chain:'celo', market:'USDT', baseApr, baseApy: baseApy ?? (1+baseApr/365)**365 -1, rewardApr, rewardApy, asOf: now, source:'onchain', notes: notes || (rewardApr === undefined ? 'incentives_probe_no_decode' : undefined) });
				}
			}
		} catch(e:any) { if (process.env.AAVE_DEBUG==='1') console.warn('[aave][celo][incentives] outer', e?.message); }

		// Determine missing (by chain+symbol) for fallback
		const presentKey = new Set(collected.map(r => `${r.chain}:${r.market}`));
		const needFallback: { chain:string; market:string }[] = [];
		for (const [chain] of chainEntries) {
			for (const sym of symbols) {
				if (!presentKey.has(`${chain}:${sym}`)) needFallback.push({ chain, market: sym });
			}
		}
		if (needFallback.length === 0) return collected;
		// DeFiLlama fallback (single fetch) then filter per need
		try {
			const llama = await httpJSON<any>('https://yields.llama.fi/pools');
			const pools = Array.isArray(llama?.data) ? llama.data : (llama?.pools || []);
			const byNeed = new Set(needFallback.map(n => `${n.chain}:${n.market}`));
			for (const p of pools) {
				if (!p || typeof p !== 'object') continue;
				if (!/aave/i.test(p.project || '')) continue;
				const sym = String(p.symbol || '').toUpperCase();
				const chainRaw = String(p.chain || '').toLowerCase();
				let chain: string = chainRaw;
				if (chain === 'eth' || chain === 'ethereum') chain = 'ethereum';
				if (chain === 'arbitrum') chain = 'arbitrum';
				if (chain === 'base') chain = 'base';
				if (!symbols.includes(sym)) continue;
				if (!byNeed.has(`${chain}:${sym}`)) continue;
				const apy = Number(p.apy);
				if (!Number.isFinite(apy)) continue;
				const baseApy = apy/100;
				const baseApr = Math.log(1 + baseApy);
				upsert({ venue:'aave', chain, market: sym, baseApr, baseApy, asOf: now, source:'llama' });
			}
		} catch {/* ignore */}
		return collected;
	},
	estimateApy(rate, opts) {
		const comp = Math.max(1, opts?.compounding ?? 365);
		const fee = Math.max(0, opts?.feeBps ?? 0)/10_000;
		const gross = (1 + rate.baseApr/comp)**comp - 1;
		return Math.max(0, gross * (1 - fee));
	},
	async deposit() { throw new Error('NOT_IMPLEMENTED: Aave deposit will be wired to treasury signer later.'); },
	async withdraw() { throw new Error('NOT_IMPLEMENTED: Aave withdraw will be wired to treasury signer later.'); }
};

export default aave;
