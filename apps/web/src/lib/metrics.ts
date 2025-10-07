export type PortfolioMetrics = {
  apy7d: number;
  pps: number;
  tvlUSD: number;
  tvlPI: number;
  prices?: { PI?: number; lastUpdatedISO?: string; degraded?: boolean };
};

export async function fetchPortfolioMetrics(): Promise<PortfolioMetrics> {
  const base = process.env.NEXT_PUBLIC_API_BASE!;
  const r = await fetch(`${base}/v1/portfolio/metrics`, { cache: 'no-store' });
  if (!r.ok) throw new Error(`metrics ${r.status}`);
  const json = await r.json();
  return (json.data ?? json) as PortfolioMetrics;
}
