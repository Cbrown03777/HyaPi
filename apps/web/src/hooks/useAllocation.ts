import { useQuery } from '@tanstack/react-query'
import { GOV_API_BASE } from '@hyapi/shared'

export interface AllocationResponse {
  pps: number
  apy7d: number
  lifetimeGrowth: number
  chainMix: { chain: string; weight: number }[]
  ppsSeries: { d: string; pps: number }[]
  degraded?: boolean
}

async function fetchAllocation(): Promise<AllocationResponse> {
  const r = await fetch(`${GOV_API_BASE}/v1/portfolio/allocation`)
  const j = await r.json().catch(()=>({}))
  if (r.ok && j?.success) return j.data as AllocationResponse
  return { pps:1, apy7d:0, lifetimeGrowth:0, chainMix:[], ppsSeries:[], degraded:true }
}

export function useAllocation() {
  return useQuery({
    queryKey: ['allocation'],
    queryFn: fetchAllocation,
    refetchInterval: 30000
  })
}
