// Number and token formatting helpers for consistent display across the app

export function fmtNumber(x?: string | number | null, digits = 6): string {
  if (x == null) return '0';
  const n = typeof x === 'string' ? Number(x) : x;
  if (!Number.isFinite(n)) return String(x ?? '');
  return n.toFixed(digits).replace(/\.?0+$/, '');
}

export function fmtPercent(n?: number | null, digits = 2, opts?: { sign?: boolean }): string {
  if (!Number.isFinite(n ?? NaN)) return '0%';
  const v = (n as number).toFixed(digits);
  const s = opts?.sign ? (n as number) > 0 ? '+' : '' : '';
  return `${s}${v}%`;
}

export function fmtCompact(n?: number | null, digits = 1): string {
  if (!Number.isFinite(n ?? NaN)) return '0';
  const abs = Math.abs(n as number);
  const sign = (n as number) < 0 ? '-' : '';
  const units: [number, string][] = [
    [1e12, 'T'],
    [1e9, 'B'],
    [1e6, 'M'],
    [1e3, 'K'],
  ];
  for (const [v, s] of units) {
    if (abs >= v) return `${sign}${((abs / v)).toFixed(digits).replace(/\.?0+$/, '')}${s}`;
  }
  return `${(n as number).toFixed(Math.min(digits, 6)).replace(/\.?0+$/, '')}`;
}

// New lightweight helpers for admin allocation UI
export function formatPercent(n: number | undefined | null, digits = 2) {
  if (!Number.isFinite(n ?? NaN)) return '0.00%';
  return `${(n as number * 100).toFixed(digits)}%`;
}

export function formatUSD(n: number | undefined | null, digits = 2) {
  if (!Number.isFinite(n ?? NaN)) return '$0.00';
  return '$' + (n as number).toLocaleString(undefined, { minimumFractionDigits: digits, maximumFractionDigits: digits });
}

// Proof-of-reserves helpers
export const formatToken = (n:number, sym:string) => `${(n||0).toLocaleString(undefined,{maximumFractionDigits:6})} ${sym}`;
export const formatUSD0 = (n?:number) => n==null ? '—' : new Intl.NumberFormat(undefined,{style:'currency',currency:'USD',maximumFractionDigits:0}).format(n);

export function timeago(iso: string | undefined | null): string {
  if (!iso) return '';
  const then = new Date(iso).getTime();
  if (!then) return '';
  const diffSec = Math.max(0, (Date.now() - then) / 1000);
  if (diffSec < 60) return `${Math.floor(diffSec)}s ago`;
  if (diffSec < 3600) return `${Math.floor(diffSec/60)}m ago`;
  if (diffSec < 86400) return `${Math.floor(diffSec/3600)}h ago`;
  return `${Math.floor(diffSec/86400)}d ago`;
}

// Convert 1e18-scaled token amounts to a short human string
export function toTokenStr(e18?: string | number | null, fracDigits = 4): string {
  if (e18 == null) return '0';
  const s = typeof e18 === 'number' ? String(e18) : e18;
  try {
    const n = BigInt(s);
    const whole = n / 10n ** 18n;
    const frac = (n % 10n ** 18n).toString().padStart(18, '0').slice(0, fracDigits);
    return frac === ''.padStart(fracDigits, '0')
      ? whole.toString()
      : `${whole}.${frac}`.replace(/\.*0+$/, '');
  } catch {
    const f = Number(s);
    if (!Number.isFinite(f)) return '0';
    return (f / 1e18).toFixed(fracDigits).replace(/\.?0+$/, '');
  }
}
