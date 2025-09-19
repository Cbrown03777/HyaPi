import axios from 'axios';

export type SupportedSymbol = 'PI' | 'LUNA' | 'BAND' | 'JUNO' | 'ATOM' | 'TIA' | 'DAI';
export interface PriceResult { prices: Record<SupportedSymbol, number>; asOf: string; degraded: boolean; source: 'cmc' | 'fallback'; }

const SUPPORTED: SupportedSymbol[] = ['PI','LUNA','BAND','JUNO','ATOM','TIA','DAI'];
const SUPPORTED_SET = new Set<SupportedSymbol>(SUPPORTED);

function asSupported(sym: string): SupportedSymbol | null {
  const u = sym?.toUpperCase?.();
  if (!u) return null;
  return SUPPORTED_SET.has(u as SupportedSymbol) ? (u as SupportedSymbol) : null;
}

// Simple per-symbol cache with 60s TTL
const cache = new Map<SupportedSymbol, { price: number; asOf: number }>();
const TTL_MS = 60_000;

function getCached(symbol: SupportedSymbol): number | null {
  const v = cache.get(symbol);
  if (!v) return null;
  if (Date.now() - v.asOf < TTL_MS) return v.price;
  return null;
}

function setCached(symbol: SupportedSymbol, price: number) {
  cache.set(symbol, { price, asOf: Date.now() });
}

async function cmcClient(symbols: SupportedSymbol[]): Promise<Record<SupportedSymbol, number>> {
  const apiKey = process.env.CMC_API_KEY;
  if (!apiKey) throw new Error('CMC_API_KEY missing');
  const url = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest';
  const params = new URLSearchParams({ symbol: symbols.join(',') });
  const { data } = await axios.get(url + '?' + params.toString(), {
    headers: { 'X-CMC_PRO_API_KEY': apiKey },
    timeout: 8000,
    // note: avoid throwing for non-2xx; we'll catch anyway
    validateStatus: () => true,
  });
  const out: Record<SupportedSymbol, number> = {
    PI: 0, LUNA: 0, BAND: 0, JUNO: 0, ATOM: 0, TIA: 0, DAI: 1,
  };
  // CMC returns data keyed by symbol uppercase
  if (data && data.data) {
    for (const sym of symbols) {
      const row = data.data[sym];
      const price = row?.quote?.USD?.price;
      if (typeof price === 'number' && Number.isFinite(price)) out[sym] = price;
    }
  }
  return out;
}

// Fallback: mock/static mapping; optionally could call CoinGecko simple price
// Map symbols to CoinGecko ids if needed:
// LUNA -> terra-luna-2; BAND -> band-protocol; ATOM -> cosmos; TIA -> celestia; JUNO -> juno-network; DAI -> dai; PI -> not generally available
async function fallbackClient(symbols: SupportedSymbol[]): Promise<Record<SupportedSymbol, number>> {
  const out: Record<SupportedSymbol, number> = { PI: 0, LUNA: 0, BAND: 0, JUNO: 0, ATOM: 0, TIA: 0, DAI: 1 };
  try {
    // For demo safety or offline, we can keep a small static. If internet is allowed, you could integrate CoinGecko here.
    // Keeping static nominal values; PI stays 0 as it's typically unavailable via public fallbacks.
    const staticVals: Partial<Record<SupportedSymbol, number>> = {
      LUNA: 0.5,
      BAND: 1.5,
      JUNO: 0.3,
      ATOM: 6,
      TIA: 3,
      DAI: 1,
      PI: 0,
    };
    for (const s of symbols) {
      const val = staticVals[s];
      if (typeof val === 'number') out[s] = val;
    }
  } catch {
    // swallow
  }
  return out;
}

export async function getPrices(symbols: SupportedSymbol[], opts?: { force?: boolean }): Promise<PriceResult> {
  const wanted = Array.from(new Set(symbols.map(s => asSupported(String(s))).filter(Boolean))) as SupportedSymbol[];
  const result: Record<SupportedSymbol, number> = { PI: 0, LUNA: 0, BAND: 0, JUNO: 0, ATOM: 0, TIA: 0, DAI: 0 };

  const useCache = !opts?.force;
  const toFetch: SupportedSymbol[] = [];
  if (useCache) {
    for (const s of wanted) {
      const v = getCached(s);
      if (v != null) result[s] = v; else toFetch.push(s);
    }
  } else {
    toFetch.push(...wanted);
  }

  let degraded = false as boolean;
  let source: 'cmc' | 'fallback' = 'cmc';

  if (toFetch.length > 0) {
    try {
      let prices: Record<SupportedSymbol, number> | null = null;
      if (process.env.CMC_API_KEY) {
        prices = await cmcClient(toFetch);
      } else {
        degraded = true; source = 'fallback';
        prices = await fallbackClient(toFetch);
      }
      if (!prices) throw new Error('no prices');
      for (const s of toFetch) {
        const v = prices[s];
        if (typeof v === 'number' && Number.isFinite(v)) {
          result[s] = v;
          setCached(s, v);
        } else {
          // missing -> 0
          result[s] = 0;
        }
      }
    } catch {
      degraded = true; source = 'fallback';
      const prices = await fallbackClient(toFetch).catch(() => null);
      for (const s of toFetch) {
        const v = prices?.[s] ?? 0;
        result[s] = v;
        setCached(s, v);
      }
    }
  }

  // Ensure all requested supported symbols are present in the result
  for (const s of wanted) {
    if (typeof result[s] !== 'number') result[s] = 0;
  }

  return { prices: result, asOf: new Date().toISOString(), degraded, source };
}
