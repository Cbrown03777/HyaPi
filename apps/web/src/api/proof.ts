import { GOV_API_BASE } from '@hyapi/shared'

export async function fetchProof() {
  const r = await fetch(`${GOV_API_BASE}/v1/proof/reserves`, { cache: 'no-store' })
  return r.json()
}
