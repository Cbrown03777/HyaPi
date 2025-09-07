"use client";
import React from 'react';
import ProposalCard, { type Proposal as ProposalModel } from '@/components/ProposalCard';

type Props = {
	proposals: ProposalModel[];
	onVote: (id:string, support:'for'|'against'|'abstain')=>void;
	onFinalize: (id:string)=>void;
	onExecute: (id:string)=>void;
	busy?: boolean;
};

export function GovernancePeek({ proposals, onVote, onFinalize, onExecute, busy }: Props) {
	const top = proposals.slice(0,2);
	if (top.length === 0) return null;
	return (
		<section className="mt-6">
			<h2 className="text-sm font-semibold text-white/70 mb-2">Active Proposals</h2>
			<div className="grid grid-cols-1 gap-3 md:grid-cols-2">
						{top.map(p => {
							const extra:any = {};
								if (typeof busy === 'boolean') extra.busy = busy;
							return (
								<ProposalCard key={p.proposal_id} p={p} onVote={onVote} onFinalize={onFinalize} onExecute={onExecute} {...extra} />
							);
						})}
			</div>
		</section>
	);
}

export default GovernancePeek;
