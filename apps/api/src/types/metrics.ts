export type ChainMix = { chain: string; weight: number };
export type AssetMix = { asset: string; weight: number; venue?: string };

export interface Metrics {
  tvlUSD: number;            // total = deployed + buffer (PI * price)
  tvlPI: number;             // total = deployed + buffer (PI)
  tvlPI_deployed?: number;   // deployed-only PI (optional)
  tvlUSD_deployed?: number;  // deployed-only USD (optional)
  pps: number;
  apy7d: number;
  bufferPI: number;
  chainMix: ChainMix[];
  assetMix: AssetMix[];
  prices: {
    PI: number; LUNA: number; BAND: number; JUNO: number; ATOM: number; TIA: number; DAI: number;
    lastUpdatedISO: string; degraded?: boolean;
  };
  feesToDatePI: number;
  extra?: { ppsSeries?: Array<{ d: string; pps: number }> };
}
