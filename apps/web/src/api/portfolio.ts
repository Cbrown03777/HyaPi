import { API_BASE } from './config';

export type ChainMix = Array<{ chain: string; weight: number; usd: number; address?: string }>;
export type AssetMix = Array<{ market: string; chain: string; weight: number; usd: number; address?: string }>;

export interface PortfolioMetrics {
  tvlUSD: number;
  tvlPI: number;
  tvlPI_deployed?: number;
  tvlUSD_deployed?: number;
  pps: number;
  apy7d: number;
  bufferPI: number;
  feesToDatePI: number;
  prices: { PI: number; LUNA: number; BAND: number; JUNO: number; ATOM: number; TIA: number; DAI: number; lastUpdatedISO: string; degraded: boolean };
  chainMix: ChainMix;
  assetMix: AssetMix;
  extra?: { ppsSeries?: Array<{ as_of_date: string; pps_1e18: string }> };
}

export async function fetchPortfolioMetrics(signal?: AbortSignal): Promise<PortfolioMetrics> {
  const r = await fetch(`${API_BASE}/v1/portfolio/metrics`, { cache: 'no-store', signal: signal ?? null });
  if (!r.ok) throw new Error(`metrics ${r.status}`);
  const body = await r.json();
  if (body?.success && body?.data) return body.data as PortfolioMetrics;
  throw new Error('metrics unavailable');
}
