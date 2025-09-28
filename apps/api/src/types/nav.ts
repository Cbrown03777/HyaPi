export interface NavPoint { d: string; pps: number }
export interface ChainMix { chain: string; weight: number }
export interface AllocationMetrics {
  pps: number;
  apy7d: number;
  lifetimeGrowth: number;
  chainMix: ChainMix[];
  ppsSeries: NavPoint[];
}
