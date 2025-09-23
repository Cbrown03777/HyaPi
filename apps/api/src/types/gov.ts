// apps/api/src/types/gov.ts
export type ProposalStatus = 'Open' | 'Closed' | 'Passed' | 'Rejected' | 'Failed' | 'Canceled';

export interface Proposal {
  id: string;                 // uuid or numeric string
  title: string;
  summary: string;            // short one-liner
  status: ProposalStatus;
  startTimeISO: string;
  endTimeISO: string;         // used to compute open/closed
  yes: number;                // raw votes (normalized to human units if needed)
  no: number;                 // raw votes
  abstain: number;            // raw votes
  turnout?: number | null;    // optional % of eligible
  createdAtISO: string;
  updatedAtISO: string;
}

export interface ProposalList {
  items: Proposal[];
  nextCursor?: string | null;
}
