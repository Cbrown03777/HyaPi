"use client";
import { useQuery } from '@tanstack/react-query';
import { fetchPortfolioMetrics, type PortfolioMetrics } from '@/api/portfolio';

export function usePortfolioMetrics() {
  return useQuery<PortfolioMetrics, Error>({
    queryKey: ['portfolio-metrics'],
    queryFn: ({ signal }) => fetchPortfolioMetrics(signal as AbortSignal | undefined),
    staleTime: 30_000,
    refetchInterval: 30_000,
    refetchOnWindowFocus: false,
  });
}
