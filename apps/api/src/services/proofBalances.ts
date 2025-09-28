import { PROOF_ADDRESSES } from '../config/proof';
import type { ChainBalance, ProofOfReserves } from '../types/proof';
import { getPrices } from '@hyapi/prices';

interface CacheEntry { value: ChainBalance; ts: number }
const CACHE = new Map<string, CacheEntry>();
const TTL_MS = 60_000; // 60s cache

function cacheKey(chain: string, asset: string, address: string) {
  return `${chain}:${asset}:${address}`;
}

async function cosmosBalance(lcd: string, address: string, baseDenom: string, exponent: number): Promise<number> {
  const url = `${lcd.replace(/\/$/, '')}/cosmos/bank/v1beta1/balances/${address}`;
  const r = await fetch(url, { method: 'GET', headers: { Accept: 'application/json' } }).catch(() => null);
  if (!r || !r.ok) return 0;
  const j: any = await r.json().catch(()=>null);
  const arr = j?.balances || [];
  const coin = arr.find((c: any) => c?.denom === baseDenom);
  if (!coin) return 0;
  const raw = Number(coin.amount || '0');
  if (!Number.isFinite(raw) || raw <= 0) return 0;
  return raw / 10**exponent;
}

async function evmEthBalance(rpcUrl: string, address: string): Promise<number> {
  const body = { jsonrpc: '2.0', id: 1, method: 'eth_getBalance', params: [address, 'latest'] };
  const r = await fetch(rpcUrl, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }).catch(()=>null);
  if (!r || !r.ok) return 0;
  const j: any = await r.json().catch(()=>null);
  const hex = j?.result;
  if (typeof hex !== 'string') return 0;
  const wei = Number(BigInt(hex));
  return wei / 1e18;
}

interface ChainMeta { lcd?: string; denom?: string; exp?: number }
function chainMeta(chain: string): ChainMeta {
  switch(chain) {
    case 'COSMOS': return { lcd: process.env.COSMOS_LCD || 'https://cosmos-rest.publicnode.com', denom: 'uatom', exp: 6 };
    case 'TIA': return { lcd: process.env.CELESTIA_LCD || 'https://celestia-rest.publicnode.com', denom: 'utia', exp: 6 };
    case 'TERRA': return { lcd: process.env.TERRA_LCD || 'https://phoenix-lcd.terra.dev', denom: 'uluna', exp: 6 };
    case 'JUNO': return { lcd: process.env.JUNO_LCD || 'https://juno-rest.publicnode.com', denom: 'ujuno', exp: 6 };
    case 'BAND': return { lcd: process.env.BAND_LCD || 'https://laozi1.bandchain.org/api', denom: 'uband', exp: 6 };
    default: return {};
  }
}

async function fetchOne(chain: string, asset: string, address: string, explorer: string): Promise<ChainBalance> {
  const key = cacheKey(chain, asset, address);
  const now = Date.now();
  const cached = CACHE.get(key);
  if (cached && now - cached.ts < TTL_MS) return cached.value;
  let balance = 0; let degraded = false;
  try {
    if (['COSMOS','TIA','TERRA','JUNO','BAND'].includes(chain)) {
      const meta = chainMeta(chain);
      if (meta.lcd && meta.denom && meta.exp != null) {
        balance = await cosmosBalance(meta.lcd, address, meta.denom, meta.exp);
      } else degraded = true;
    } else if (['ARBITRUM','BASE'].includes(chain)) {
      const rpc = chain === 'ARBITRUM' ? process.env.ARBITRUM_RPC_URL : process.env.BASE_RPC_URL;
      if (rpc) balance = await evmEthBalance(rpc, address); else degraded = true;
    } else {
      degraded = true;
    }
  } catch {
    degraded = true;
  }
  const value: ChainBalance = { chain: chain as any, asset: asset as any, address, balance, explorer, asOf: new Date().toISOString(), degraded: degraded || balance===0 };
  CACHE.set(key, { value, ts: now });
  return value;
}

export async function getProofOfReserves(): Promise<ProofOfReserves> {
  try {
    const items = await Promise.all(PROOF_ADDRESSES.map(async a => {
      return fetchOne(a.chain, a.asset, a.address, a.explorerUrl(a.address));
    }));
    // Prices (exclude ETH if not supported in price service). We'll request only non-ETH for now.
    let degradedAny = items.some(i => i.degraded);
    try {
      const syms = ['ATOM','TIA','LUNA','JUNO','BAND'] as const;
      const { prices, degraded } = await getPrices(syms as any);
      degradedAny = degradedAny || degraded;
      // map USD for those assets
      for (const it of items) {
        if (prices[it.asset as keyof typeof prices]) {
          it.usd = it.balance * (prices as any)[it.asset];
        }
      }
    } catch {
      degradedAny = true;
    }
    const totalUsd = items.reduce((s,i)=> s + (i.usd || 0), 0) || undefined;
    return { items, totals: totalUsd != null ? { usd: totalUsd } : undefined, degraded: degradedAny };
  } catch (e:any) {
    console.warn('getProofOfReserves failed', e.message);
    return { items: [], degraded: true };
  }
}
