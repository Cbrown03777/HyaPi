export interface ChainBalance {
  chain: 'COSMOS'|'TIA'|'TERRA'|'JUNO'|'BAND'|'ARBITRUM'|'BASE';
  asset: 'ATOM'|'TIA'|'LUNA'|'JUNO'|'BAND'|'ETH';
  address: string;
  balance: number; // native token units
  usd?: number;
  asOf: string;
  explorer: string;
  degraded?: boolean;
}

export interface ProofOfReserves {
  items: ChainBalance[];
  totals?: { usd?: number };
  degraded?: boolean;
}
