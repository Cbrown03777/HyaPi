// Temporary shim for @hyapi/alloc until workspace path mapping resolves built types
declare module '@hyapi/alloc' {
	export interface Guardrails {
		lambda: number;
		softmaxK: number;
		bufferBps: number;
		minTradeUSD: number;
		maxVenueBps: Record<string, number>;
		maxDriftBps: number;
		cooldownSec: number;
		allowVenue: Record<string, boolean>;
		staleRateMaxSec: number;
	}
	export interface Rate { venue:string; chain:string; market:string; baseApr:number; baseApy?:number; rewardApr?:number; rewardApy?:number; asOf:string; }
	export type GovWeights = Record<string, number>;
	export type TargetWeights = Record<string, number>;
	export type Holdings = Record<string, number>;
	export function computeTargets(gov: GovWeights, rates: Rate[], guards: Guardrails): TargetWeights;
	export function planRebalance(args: { tvlUSD: number; bufferBps:number; current:Holdings; targetWeights:TargetWeights; minTradeUSD:number; maxDriftBps:number }): { bufferUSD:number; actions:{ kind:"increase"|"decrease"|"buffer"; key?:string; deltaUSD:number }[]; totalDeltaUSD:number; driftBps:number };
}
