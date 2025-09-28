import { db } from './db';
import type { ChainMix } from '../types/nav';

interface RawVenueRow { chain: string; usd: string }

export async function getChainMix(): Promise<ChainMix[]> {
  try {
    const q = await db.query<RawVenueRow>(`SELECT chain, SUM(usd_notional)::text AS usd FROM venue_holdings GROUP BY chain`);
    if (!q.rowCount) return [];
    const total = q.rows.reduce((s,r)=> s + Number(r.usd||0), 0);
    if (!total) return [];
    return q.rows.map(r => ({ chain: r.chain, weight: Number(r.usd)/total })).filter(c => Number.isFinite(c.weight));
  } catch (e) {
    console.warn('getChainMix failed', (e as any)?.message);
    return [];
  }
}
