import { z } from "zod";

export const VenueId = z.enum(["aave","justlend","stride"]);
export type VenueId = z.infer<typeof VenueId>;

export const Asset = z.string();

export const Rate = z.object({
	venue: VenueId,
	chain: z.string(),
	market: Asset,
	baseApr: z.number(),
	baseApy: z.number().optional(),
	rewardApr: z.number().optional(),
	rewardApy: z.number().optional(),
	asOf: z.string()
});
export type Rate = z.infer<typeof Rate>;

export const GovWeights = z.record(z.string(), z.number());
export type GovWeights = z.infer<typeof GovWeights>;

export const Holdings = z.record(z.string(), z.number());
export type Holdings = z.infer<typeof Holdings>;

export const TargetWeights = z.record(z.string(), z.number());
export type TargetWeights = z.infer<typeof TargetWeights>;

export type PlanAction =
	| { kind:"increase"; key:string; deltaUSD:number }
	| { kind:"decrease"; key:string; deltaUSD:number }
	| { kind:"buffer";   deltaUSD:number };

export interface Guardrails {
	lambda: number;
	softmaxK: number;
	bufferBps: number;
	minTradeUSD: number;
	maxVenueBps: Record<VenueId, number>;
	maxDriftBps: number;
	cooldownSec: number;
	allowVenue: Record<VenueId, boolean>;
	staleRateMaxSec: number;
}
