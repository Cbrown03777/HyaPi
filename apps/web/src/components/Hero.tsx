"use client";
import React from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/Button';

type Props = {
	token?: string;
};

export function Hero({ token }: Props) {
	return (
		<section className="mb-4">
			<Card className="px-4 py-4 sm:px-6 sm:py-6">
				<h1 className="text-2xl sm:text-3xl font-semibold leading-tight">hyaPi Governance</h1>
				<p className="mt-1 text-sm sm:text-base text-white/70">
					hyaPi aggregates staking across multiple chains to optimize yield and liquidity safety. Use your hyaPi governance
					power to vote on allocation proposals, shape risk parameters, or propose new staking platforms for the ecosystem.
				</p>
				<details className="mt-3">
					<summary className="cursor-pointer select-none text-sm text-white/70 hover:text-white/90">How it works</summary>
					<div className="mt-2 grid gap-2 text-sm text-white/70">
						<div className="rounded-md border border-white/15 bg-white/5 p-2">1) Deposit Pi → receive hyaPi 1:1</div>
						<div className="rounded-md border border-white/15 bg-white/5 p-2">2) Vote on allocation proposals and parameters</div>
						<div className="rounded-md border border-white/15 bg-white/5 p-2">3) Redemptions are instant if buffer has liquidity, otherwise queued</div>
						<div className="rounded-md border border-white/15 bg-white/5 p-2">4) Propose new platforms for inclusion via Create</div>
					</div>
				</details>
				<div className="mt-3 grid gap-2 sm:flex sm:items-center sm:justify-between">
					<div className="text-xs text-[var(--fg2)]">Signed in: <code className="text-xs">{token || '(no token — dev fallback)'}</code></div>
					<div className="flex gap-2">
						<a href="/stake"><Button className="btn-modern btn-primary" rightIcon={<span aria-hidden>➔</span>}>Stake Pi</Button></a>
						<a href="/create"><Button className="btn-modern btn-secondary">Create Proposal</Button></a>
					</div>
				</div>
			</Card>
		</section>
	);
}

export default Hero;
