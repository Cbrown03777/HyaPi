import { GOV_API_BASE as API_BASE } from '@hyapi/shared';

type FetchParams = { limit?: number; cursor?: string | undefined; status?: string | undefined };

export async function fetchProposals(params?: FetchParams) {
  const qs = new URLSearchParams();
  if (params?.limit) qs.set('limit', String(params.limit));
  if (params?.cursor) qs.set('cursor', params.cursor);
  if (params?.status && params.status !== 'All') qs.set('status', params.status);
  const url = `${API_BASE}/v1/gov/proposals${qs.size ? `?${qs.toString()}` : ''}`;
  const r = await fetch(url, { cache: 'no-store' });
  return r.json();
}
