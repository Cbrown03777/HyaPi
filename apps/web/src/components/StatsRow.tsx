"use client";
import React from 'react';
import { StatCard } from '@/components/StatCard';
import { fmtNumber as fmtDec, fmtCompact, fmtPercent } from '@/lib/format';

interface PortfolioLike {
	hyapi_amount: string;
	effective_pi_value: string;
	pps_1e18: string;
}

interface AllocSummaryLike {
	totalUsd?: number;
	totalGrossApy?: number;
	totalNetApy?: number;
}
interface AllocEmaLike { ema7: number|null; }

type Props = {
	pf: PortfolioLike | null;
	allocSummary: AllocSummaryLike | null;
	allocEma: AllocEmaLike | null;
	showGross: boolean;
};

export function StatsRow({ pf, allocSummary, allocEma, showGross }: Props) {
	return (
		<section>
			<div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
				<StatCard label="TVL" value={`${pf && Number(pf.effective_pi_value) >= 10000 ? fmtCompact(Number(pf.effective_pi_value)) : fmtDec(pf?.effective_pi_value ?? 0)} Pi`} tone="primary" />
				{(() => {
					const tvlUsd = allocSummary?.totalUsd;
					const gross = allocSummary?.totalGrossApy;
					const net = allocSummary?.totalNetApy;
					const v = showGross ? gross : (allocEma?.ema7 ?? net);
					const dailyUsd = (tvlUsd && v) ? (tvlUsd * v / 365) : 0;
					const label = showGross ? 'Gross APY' : 'Net APY (EMA7)';
					const sub = dailyUsd? `~${fmtDec(dailyUsd)} USD/day ${showGross? 'gross':'net'}` : 'across platforms';
					return <StatCard label={label} value={v? fmtPercent(v*100,2):'—'} sub={sub} tone="base" />;
				})()}
				<StatCard label="Your hyaPi" value={`${pf && Number(pf.hyapi_amount) >= 10000 ? fmtCompact(Number(pf.hyapi_amount)) : fmtDec(pf?.hyapi_amount ?? 0)} hyaPi`} tone="accent" />
				{(() => {
					const pps = pf ? Number(pf.pps_1e18) / 1e18 : NaN;
					const growthPct = Number.isFinite(pps) ? (pps - 1) * 100 : null;
					const statsProps = growthPct == null
						? { label: 'Growth vs Pi', value: '—', tone: 'base' as const }
						: { label: 'Growth vs Pi', value: fmtPercent(growthPct, 2, { sign: true }), tone: 'base' as const, sub: 'based on current PPS', hint: 'Computed as (PPS ÷ 1.0 − 1) × 100. PPS represents Pi per 1 hyaPi.' };
					return <StatCard {...statsProps} />;
				})()}
			</div>
		</section>
	);
}

export default StatsRow;
