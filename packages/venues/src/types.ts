import { z } from 'zod';

export const RateSchema = z.object({
	venue: z.enum(['aave','justlend','stride']),
	chain: z.string(),
	market: z.string(),
	baseApr: z.number(),
	baseApy: z.number().optional(),
	rewardApr: z.number().optional(),
	rewardApy: z.number().optional(),
	rewardMeritApr: z.number().optional(),
	rewardMeritApy: z.number().optional(),
	rewardSelfApr: z.number().optional(),
	rewardSelfApy: z.number().optional(),
	source: z.enum(['gql','llama','legacy','onchain']).optional(),
	notes: z.string().optional(),
	asOf: z.string()
});
export type Rate = z.infer<typeof RateSchema>;

export interface VenueConnector {
	getLiveRates(markets?: string[]): Promise<Rate[]>;
	estimateApy(rate: Rate, opts?: { compounding?: number; feeBps?: number }): number;
	deposit(_args: { amount: number; asset: string; addr?: string }): Promise<string>;
	withdraw(_args: { amount: number; asset: string; addr?: string }): Promise<string>;
}

export const NOT_IMPLEMENTED = 'NOT_IMPLEMENTED';
