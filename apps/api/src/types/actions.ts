export type VenueKey = 'COSMOS_STRIDE_LUNA' | 'COSMOS_STRIDE_BAND' | 'COSMOS_STRIDE_JUNO' | string;

export interface PlannedAction {
  id: string;
  venue: VenueKey;
  amountPI: number;
  status: 'Planned' | 'Confirmed';
  createdAt: string; // ISO
  note?: string;
}

export interface ConfirmFillInput {
  avgPriceUSD: number;    // required, > 0
  feeUSD: number;         // >= 0
  txUrl: string;          // https://...
  filledAt?: string;      // ISO, default now
  idempotencyKey?: string; // optional; if present, do not double-apply
}

export interface ConfirmFillResult {
  ok: boolean;
  actionId: string;
  newStatus: 'Confirmed';
  updated: { bufferPI: number; venuePI: number };
  auditId: string;
}
