'use client'
import { useEffect, useMemo, useState } from 'react'
import { GOV_API_BASE } from '@hyapi/shared'
import { signInWithPi } from '@/lib/pi'
import { StatCard } from '@/components/StatCard'
import { Card as UiCard } from '@/components/ui/Card'
import { useActivity } from '@/components/ActivityProvider'
import { fmtNumber, fmtPercent, fmtCompact } from '@/lib/format'

type PpsRow = { as_of_date: string; pps_1e18: string }

export default function PortfolioPage() {
  const [token, setToken] = useState('')
  const [hyapi, setHyapi] = useState<number | null>(null)
  const [piValue, setPiValue] = useState<number | null>(null)
  const [pps1e18, setPps1e18] = useState<string | null>(null)
  const [series, setSeries] = useState<PpsRow[]>([])
  const { items } = useActivity()

  useEffect(() => {
    (async () => {
      const maybe = await signInWithPi()
      const t = typeof maybe === 'string' ? maybe : (maybe as any)?.accessToken ?? ''
      setToken(t)
      if (t) (globalThis as any).hyapiBearer = t
      try {
        const res = await fetch(`${GOV_API_BASE}/v1/portfolio`, { headers: { Authorization: `Bearer ${t}` } })
        const j = await res.json()
        if (res.ok && j?.success) {
          const data = j.data
          setHyapi(Number(data?.hyapi_amount ?? '0'))
          setPiValue(Number(data?.effective_pi_value ?? '0'))
          setPps1e18(String(data?.pps_1e18 ?? '1000000000000000000'))
          setSeries((data?.pps_series ?? []) as PpsRow[])
        }
      } catch {}
    })()
  }, [])

  const pps = useMemo(() => {
    const n = Number(pps1e18 ?? '1000000000000000000') / 1e18
    return Number.isFinite(n) ? n : 1
  }, [pps1e18])

  const dailyDeltaPct = useMemo(() => {
    if (!series || series.length < 2) return null
  const lastRow = series[series.length - 1]
  const prevRow = series[series.length - 2]
  if (!lastRow || !prevRow) return null
  const last = Number(lastRow.pps_1e18) / 1e18
  const prev = Number(prevRow.pps_1e18) / 1e18
    if (!Number.isFinite(last) || !Number.isFinite(prev) || prev === 0) return null
    return ((last / prev) - 1) * 100
  }, [series])

  return (
    <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-6">
  <h2 className="text-xl sm:text-2xl font-semibold leading-tight">Your Portfolio</h2>

      {/* Stats row */}
      <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-3">
  <StatCard label="hyaPi balance" value={`${(hyapi ?? 0) >= 10000 ? fmtCompact(hyapi ?? 0) : fmtNumber(hyapi)} hyaPi`} tone="primary" />
  <StatCard label="Estimated Pi value" value={`${(piValue ?? 0) >= 10000 ? fmtCompact(piValue ?? 0) : fmtNumber(piValue)} Pi`} tone="accent" />
        <StatCard
          label="Growth vs Pi"
          value={fmtPercent((pps - 1) * 100, 2, { sign: true })}
          hint="Computed as (PPS ÷ 1.0 − 1) × 100. PPS represents Pi per 1 hyaPi."
          {...(dailyDeltaPct == null
            ? {}
            : { sub: `${dailyDeltaPct >= 0 ? '▲' : '▼'} ${fmtPercent(Math.abs(dailyDeltaPct))} since last` })}
        />
      </div>

      {/* Allocation placeholder */}
      <div className="mt-4 grid grid-cols-1 gap-3 lg:grid-cols-2">
        <UiCard className="p-0">
          <div className="bg-gradient-to-r from-white/10 to-transparent px-4 py-2 text-xs text-white/70">Allocation</div>
          <div className="p-4 text-sm text-white/80">
            Allocation data isn’t available yet. Governance proposals will define target weights across chains.
          </div>
        </UiCard>

        {/* Activity table */}
        <UiCard className="p-0 overflow-hidden">
          <div className="bg-gradient-to-r from-[color:var(--pri)]/20 to-transparent px-4 py-2 text-xs text-white/70">Recent activity</div>
          <div className="p-2 overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-left text-white/70">
                  <th scope="col" className="px-3 py-2">When</th>
                  <th scope="col" className="px-3 py-2">Type</th>
                  <th scope="col" className="px-3 py-2">Detail</th>
                  <th scope="col" className="px-3 py-2">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/10">
                {items.slice(0, 10).map((e) => (
                  <tr key={e.id} className="text-white/90">
                    <td className="px-3 py-2 whitespace-nowrap text-white/70">{new Date(e.ts).toLocaleString()}</td>
                    <td className="px-3 py-2 whitespace-nowrap">{e.kind}</td>
                    <td className="px-3 py-2">{e.title}{e.detail ? ` — ${e.detail}` : ''}</td>
                    <td className="px-3 py-2 whitespace-nowrap">
                      <span className={
                        'inline-flex rounded-md px-2 py-0.5 text-xs ' +
                        (e.status === 'success'
                          ? 'bg-[color:var(--success)]/20 text-[color:var(--success)]'
                          : e.status === 'error'
                          ? 'bg-[color:var(--danger)]/20 text-[color:var(--danger)]'
                          : 'bg-white/20 text-white/90')
                      }>{e.status}</span>
                    </td>
                  </tr>
                ))}
                {!items.length && (
                  <tr>
                    <td className="px-3 py-3 text-white/60" colSpan={4}>No recent activity.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </UiCard>
      </div>
    </div>
  )
}
