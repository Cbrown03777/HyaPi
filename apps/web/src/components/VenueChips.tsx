"use client";
import React from 'react';
import clsx from 'clsx';
import { fmtNumber as fmtDec } from '@/lib/format';

interface Basket { key:string; usd:number; grossApy?:number; netApy?:number; }

type Props = { baskets: Basket[]; showGross?: boolean };

export function VenueChips({ baskets, showGross }: Props) {
	if (!baskets || baskets.length === 0) return null;
	return (
		<div className="flex flex-wrap gap-2 mt-3" aria-label="Current allocation venues">
			{baskets.map(b => {
				const apy = showGross ? b.grossApy : b.netApy;
				return (
					<div key={b.key} className={clsx('group relative rounded-full px-3 py-1.5 text-[11px] border backdrop-blur-sm', 'border-white/15 bg-white/5 hover:bg-white/10 transition-colors')}>
						<span className="font-medium">{b.key}</span>
						<span className="ml-1 text-white/60">${fmtDec(b.usd)}</span>
						{apy!=null && <span className="ml-1 text-white/50">{(apy*100).toFixed(2)}%</span>}
					</div>
				);
			})}
		</div>
	);
}

export default VenueChips;
