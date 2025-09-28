import type { NavPoint } from '../types/nav';

export interface ApyStats {
  apy7d: number; // annualized
  lifetimeGrowth: number; // (last/first - 1)
}

export function computeDailyReturns(series: NavPoint[]): number[] {
  const returns: number[] = [];
  for (let i=1;i<series.length;i++) {
    const prev = series[i-1].pps;
    const cur = series[i].pps;
    if (prev>0 && cur>0) returns.push(cur/prev - 1);
  }
  return returns;
}

export function ema(values: number[], span: number): number | null {
  if (!values.length) return null;
  const k = 2/(span+1);
  let emaVal = values[0];
  for (let i=1;i<values.length;i++) {
    emaVal = values[i]*k + emaVal*(1-k);
  }
  return emaVal;
}

export function annualizeDailyReturn(r: number): number {
  // Assuming ~365 compounding periods
  return Math.pow(1+r,365)-1;
}

export function calcApy(series: NavPoint[]): ApyStats {
  if (series.length < 2) return { apy7d: 0, lifetimeGrowth: 0 };
  const rets = computeDailyReturns(series.slice(-8)); // last 7 intervals
  const er = ema(rets, 7) ?? 0;
  const apy7d = annualizeDailyReturn(er);
  const first = series[0].pps;
  const last = series[series.length-1].pps;
  const lifetimeGrowth = first>0 ? (last/first - 1) : 0;
  return { apy7d, lifetimeGrowth };
}
