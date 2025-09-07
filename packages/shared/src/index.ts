// Prefer relative base so Pi Sandbox (non-localhost) can reach the API via Next proxy
export const GOV_API_BASE = process.env.NEXT_PUBLIC_GOV_API_BASE ?? "/api";
export type ChainKey = 'sui' | 'aptos' | 'cosmos';

export interface Allocation { sui: number; aptos: number; cosmos: number; }
