import { API_BASE } from './config';

export type ManualStatus = 'Planned'|'Confirmed'|'All';

export type PlannedAction = {
  id: string;
  venue: string;
  amountPI: number;
  status: 'Planned'|'Confirmed';
  createdAt: string;
  note?: string;
};

export type ConfirmFillInput = {
  avgPriceUSD: number;
  feeUSD: number;
  txUrl: string;
  filledAt?: string;
  idempotencyKey?: string;
};

export async function listActions(token: string, status: ManualStatus = 'Planned'): Promise<PlannedAction[]> {
  const url = `${API_BASE}/v1/admin/actions?status=${encodeURIComponent(status)}`;
  const r = await fetch(url, { headers: { Authorization: `Bearer ${token}` }, cache: 'no-store' });
  const j = await r.json();
  if (!j?.success) throw new Error(j?.error?.message || 'list failed');
  return j.data as PlannedAction[];
}

export async function createAction(token: string, venue: string, amountPI: number, note?: string): Promise<PlannedAction> {
  const r = await fetch(`${API_BASE}/v1/admin/actions`, {
    method: 'POST',
    headers: { 'Content-Type':'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ venue, amountPI, note })
  });
  const j = await r.json();
  if (!j?.success) throw new Error(j?.error?.message || 'create failed');
  return j.data as PlannedAction;
}

export async function confirmAction(token: string, id: string, body: ConfirmFillInput) {
  const r = await fetch(`${API_BASE}/v1/admin/actions/${encodeURIComponent(id)}/confirm`, {
    method: 'POST',
    headers: { 'Content-Type':'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body)
  });
  const j = await r.json();
  if (!j?.success) throw new Error(j?.error?.message || 'confirm failed');
  return j.data as { ok:boolean };
}
