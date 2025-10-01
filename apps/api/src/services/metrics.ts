import { db } from './db';
import type { Metrics, ChainMix, AssetMix } from '../types/metrics';
import { getPrices } from '@hyapi/prices';

async function getBufferPI(): Promise<number> {
  try {
    const q = await db.query<{ buffer_pi: string }>(`SELECT buffer_pi::text FROM treasury WHERE id = true`);
    return Number(q.rows?.[0]?.buffer_pi ?? 0);
  } catch { return 0; }
}

async function getTVLPI(): Promise<number> {
  try {
    // Effective PI value we already compute for portfolio; reuse the aggregate
    const q = await db.query<{ v: string }>(`SELECT COALESCE(SUM(effective_pi_value),0)::text AS v FROM v_user_portfolio`);
    return Number(q.rows?.[0]?.v ?? 0);
  } catch { return 0; }
}

async function getPPS(): Promise<number> {
  try {
    const q = await db.query<{ p: string }>(`SELECT (SELECT pps_1e18 FROM pps_series ORDER BY as_of_date DESC LIMIT 1)::text AS p`);
    const raw = Number(q.rows?.[0]?.p ?? 1e18);
    return raw / 1e18;
  } catch { return 1; }
}

async function getFeesToDatePI(): Promise<number> {
  try {
    const q = await db.query<{ v: string }>(`SELECT COALESCE(SUM(amount_pi),0)::text AS v FROM fees_ledger`);
    return Number(q.rows?.[0]?.v ?? 0);
  } catch { return 0; }
}

async function getNavHistory(limit = 14): Promise<Array<{ d: string; pps: number }>> {
  try {
    const q = await db.query<{ as_of_date: string; pps_1e18: string }>(
      `SELECT as_of_date::text, pps_1e18::text FROM pps_series ORDER BY as_of_date DESC LIMIT $1`, [limit]
    );
    return q.rows
      .reverse()
      .map(r => ({ d: r.as_of_date, pps: Number(r.pps_1e18) / 1e18 }))
      .filter(x => Number.isFinite(x.pps));
  } catch { return []; }
}

function computeEMA7Annualized(series: Array<{ d: string; pps: number }>): number {
  if (series.length < 2) return 0;
  // Compute daily returns r_t = pps_t / pps_{t-1} - 1
  const rets: number[] = [];
  for (let i = 1; i < series.length; i++) {
    const prev = series[i-1].pps;
    const curr = series[i].pps;
    if (prev > 0) rets.push(curr / prev - 1);
  }
  if (!rets.length) return 0;
  const k = 2 / (7 + 1);
  let ema = rets[0];
  for (let i = 1; i < rets.length; i++) {
    ema = rets[i] * k + ema * (1 - k);
  }
  // Annualize: (1 + ema)^365 - 1 (assuming daily cadence)
  const apy = Math.pow(1 + ema, 365) - 1;
  return Number.isFinite(apy) ? apy : 0;
}

type VenueRow = { venue: string; chain?: string | null; market?: string | null; deployed_pi?: string | null };

async function getVenueBalances(): Promise<VenueRow[]> {
  try {
    // Shadow table with PI units per venue; join venue_rates for chain/market labels if available
    const q = await db.query<VenueRow>(
      `SELECT vb.venue, vr.chain, vr.market, vb.deployed_pi::text AS deployed_pi
       FROM venue_balances_pi vb
       LEFT JOIN LATERAL (
         SELECT DISTINCT ON (key) chain, market FROM venue_rates
         WHERE venue = split_part(vb.venue,':',1)
       ) vr ON true`
    );
    return q.rows;
  } catch { return []; }
}

// Static address mapping (mirrors web config). In future unify via shared package if needed.
const ADDRESS_MAP: Record<string,string> = {
  COSMOS: 'cosmos1xhdm4xccpqsvcxel5amf4r32e86q9k48x7aqjx',
  ARBITRUM: '0x1660Ef3e78FA3f04289B773b6ccF3666DBB6c7B5',
  BASE: '0x1660Ef3e78FA3f04289B773b6ccF3666DBB6c7B5',
  TIA: 'celestia1xhdm4xccpqsvcxel5amf4r32e86q9k48h5vsgt',
  TERRA: 'terra15hf2ad99amu5x3edd99jnv049cwqrga6yf5hc2',
  JUNO: 'juno1xhdm4xccpqsvcxel5amf4r32e86q9k48sv7m46',
  BAND: 'band13df4yakp3d429e503gmqw7tdvfg3d9dd6uzjnr'
};

function buildChainMix(venues: VenueRow[], bufferPI: number): ChainMix[] {
  const deployed = venues.reduce((s, v) => s + (Number(v.deployed_pi ?? 0) || 0), 0);
  const denom = Math.max(1, deployed);
  const byChain = new Map<string, number>();
  for (const v of venues) {
    const chain = (v.chain || inferChainFromVenue(v.venue)).trim() || 'Other';
    const amt = Number(v.deployed_pi ?? 0) || 0;
    byChain.set(chain, (byChain.get(chain) || 0) + amt);
  }
  return Array.from(byChain.entries()).map(([chain, amt]) => ({ chain, weight: amt / denom, address: ADDRESS_MAP[chain.toUpperCase()] }));
}

function buildAssetMix(venues: VenueRow[], bufferPI: number): AssetMix[] {
  const deployed = venues.reduce((s, v) => s + (Number(v.deployed_pi ?? 0) || 0), 0);
  const denom = Math.max(1, deployed);
  const byAsset = new Map<string, { amt: number; venue?: string }>();
  for (const v of venues) {
    const market = (v.market || inferMarketFromVenue(v.venue)).trim() || 'PI';
    const amt = Number(v.deployed_pi ?? 0) || 0;
    const cur = byAsset.get(market) || { amt: 0, venue: v.venue };
    cur.amt += amt; cur.venue = cur.venue || v.venue;
    byAsset.set(market, cur);
  }
  return Array.from(byAsset.entries()).map(([asset, { amt, venue }]) => ({ asset, venue, weight: amt / denom }));
}

function inferChainFromVenue(venue: string): string {
  const key = (venue || '').toLowerCase();
  if (key.startsWith('stride')) return 'Cosmos';
  if (key.startsWith('aave')) return 'Sui';
  if (key.startsWith('justlend')) return 'Aptos';
  return 'Other';
}

function inferMarketFromVenue(venue: string): string {
  const market = venue.split(':')[1] || '';
  return market || 'PI';
}

export async function getPortfolioMetrics(): Promise<{ ok: boolean; status?: number; data?: Metrics }>{
  try {
    const [bufferPI, tvlPIraw, pps, venues, series] = await Promise.all([
      getBufferPI(),
      getTVLPI(),
      getPPS(),
      getVenueBalances(),
      getNavHistory(14),
    ]);

    // Prices
    let priceBlock: Metrics['prices'] = { PI: 0, LUNA: 0, BAND: 0, JUNO: 0, ATOM: 0, TIA: 0, DAI: 0, lastUpdatedISO: new Date().toISOString(), degraded: true };
    try {
      const wanted = ['PI','LUNA','BAND','JUNO','ATOM','TIA','DAI'] as const;
      const { prices, asOf, degraded } = await getPrices([...wanted]);
      priceBlock = { ...prices, lastUpdatedISO: asOf, degraded } as any;
    } catch {
      // keep degraded default
    }

  const deployedPI = venues.reduce((s, v) => s + (Number(v.deployed_pi ?? 0) || 0), 0);
  const tvlPI = bufferPI + deployedPI;
  const tvlUSD = tvlPI * (priceBlock.PI || 0);
  const tvlPI_deployed = deployedPI;
  const tvlUSD_deployed = deployedPI * (priceBlock.PI || 0);
    const chainMix = buildChainMix(venues, bufferPI);
    const assetMix = buildAssetMix(venues, bufferPI);
    const apy7d = computeEMA7Annualized(series);
    const feesToDatePI = await getFeesToDatePI();

    const metrics: Metrics = {
  tvlUSD, tvlPI, tvlPI_deployed, tvlUSD_deployed, pps, apy7d,
      bufferPI,
      chainMix,
      assetMix,
      prices: priceBlock,
      feesToDatePI,
      extra: { ppsSeries: series }
    };
    return { ok: true, data: metrics };
  } catch (e) {
    console.error('getPortfolioMetrics error', (e as any)?.message || e);
    return { ok: false, status: 503 };
  }
}
