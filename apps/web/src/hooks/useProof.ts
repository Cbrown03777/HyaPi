'use client'
import { useQuery } from '@tanstack/react-query'
import { fetchProof } from '../api/proof'

export function useProof() {
  return useQuery({
    queryKey: ['proofOfReserves'],
    queryFn: async () => {
      const j = await fetchProof()
      if (!j?.success) throw new Error('proof fetch failed')
      return j.data
    },
    refetchInterval: 60_000
  })
}
