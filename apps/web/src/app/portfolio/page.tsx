'use client'
import { useEffect, useMemo, useState, useCallback } from 'react'
import { piLogin } from '@/lib/pi'
import { api } from '@/lib/http'
import { StatCard } from '@/components/StatCard'
import { Card } from '@/components/Card'
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Chip, Skeleton, Alert, Button } from '@mui/material'
import { useActivity } from '@/components/ActivityProvider'
import { fmtNumber, fmtPercent, fmtCompact } from '@/lib/format'
import { useAllocation } from '@/hooks/useAllocation'
import { AllocationBar } from '@/components/portfolio/AllocationBar'
import { ApyCards } from '@/components/portfolio/ApyCards'
import { PublicAddresses } from '@/components/portfolio/PublicAddresses'
import { ProofDialog } from '@/components/proof/ProofDialog'
import { PiInit } from '@/components/PiInit'
import PiLoginButton from '@/components/PiLoginButton'

type PpsRow = { as_of_date: string; pps_1e18: string }
type Metrics = { apy7d?: number; lifetimeGrowth?: number; pps?: number; degraded?: boolean }
type ActivityItem = { id: string; ts: number; kind: string; title: string; detail?: string; status: string }

export default function PortfolioPage() {
  const [token, setToken] = useState('')
  const [hyapi, setHyapi] = useState<number | null>(null)
  const [piValue, setPiValue] = useState<number | null>(null)
  const [pps1e18, setPps1e18] = useState<string | null>(null)
  const [series, setSeries] = useState<PpsRow[]>([])
  const [metrics, setMetrics] = useState<Metrics | null>(null)
  const [activity, setActivity] = useState<ActivityItem[]>([])
  const { items } = useActivity()
  const [showProof, setShowProof] = useState(false)

  const refetch = useCallback(async (): Promise<void> => {
    const dev = process.env.NODE_ENV !== 'production'
    if (dev) {
      console.debug('[portfolio] token?', !!token)
      console.debug('[portfolio] api', process.env.NEXT_PUBLIC_API_BASE)
    }
    if (!token) return
    try {
      const res = await api('/v1/portfolio')
      if (res.status === 401) {
        try { localStorage.removeItem('hyapiBearer') } catch {}
        ;(globalThis as any).hyapiBearer = ''
        setToken('')
        return
      }
      const j = await res.json()
      if (res.ok && j?.success) {
        const data = j.data
        setHyapi(Number(data?.hyapi_amount ?? '0'))
        setPiValue(Number(data?.effective_pi_value ?? '0'))
        setPps1e18(String(data?.pps_1e18 ?? '1000000000000000000'))
        setSeries((data?.pps_series ?? []) as PpsRow[])
        // Fetch metrics (public)
        try {
          const mr = await fetch(`${process.env.NEXT_PUBLIC_API_BASE}/v1/portfolio/metrics`, { cache: 'no-store' })
          const mj = await mr.json().catch(()=>null)
          const md = mj?.data ?? mj ?? null
          setMetrics(md ? { apy7d: md.apy7d, lifetimeGrowth: md.lifetimeGrowth, pps: md.pps, degraded: md?.prices?.degraded || false } : null)
        } catch {}
        // Fetch recent activity (auth)
        try {
          const ar = await api('/v1/activity/recent')
          const aj = await ar.json().catch(()=>null)
          const items = Array.isArray(aj?.data?.items) ? aj.data.items.slice(0,10) : []
          const mapped = items.map((it: any) => {
            const kind = String(it.kind || '').toUpperCase()
            const typeLabel = kind === 'DEPOSIT' ? 'Deposit' : kind === 'REDEEM' ? 'Redemption' : (kind || 'Activity')
            const lock = Number(it.lockupWeeks ?? it.lockup_weeks ?? 0) || 0
            const parts: string[] = []
            parts.push(lock > 0 ? `Lockup: ${lock} weeks` : 'No lockup')
            const tx: string | undefined = it.txid || it?.meta?.txid
            if (tx) parts.push(`Tx: ${String(tx).slice(0,8)}…`)
            const detail = parts.join(' • ')
            const ts = it.createdAt ? Date.parse(it.createdAt) : (typeof it.ts === 'string' ? Date.parse(it.ts) : (it.ts ?? Date.now()))
            const id = String(it.paymentId || it.identifier || it.payment_id || `${kind}:${ts}`)
            const amount = Number(it.amount ?? 0)
            const title = kind === 'DEPOSIT' ? `+${amount} Pi` : kind === 'REDEEM' ? `-${amount} Pi` : typeLabel
            return { id, ts, kind: typeLabel, title, detail, status: 'success' } as ActivityItem
          })
          if (dev) console.debug('[portfolio][activity]', mapped)
          setActivity(mapped)
        } catch {}
        if (dev) console.debug('[portfolio] rows', (data?.stakes?.length ?? 0))
      }
    } catch {}
  }, [token])

  useEffect(() => {
    // Initial token load from storage
    try {
      const t = (globalThis as any).hyapiBearer || (typeof localStorage !== 'undefined' ? localStorage.getItem('hyapiBearer') : '') || ''
      if (typeof t === 'string' && t.trim()) setToken(t)
    } catch {}
  }, [])

  useEffect(() => {
    // Auth event listener to refetch
    function onAuth() {
      try {
        const t = (globalThis as any).hyapiBearer || (typeof localStorage !== 'undefined' ? localStorage.getItem('hyapiBearer') : '') || ''
        if (typeof t === 'string') setToken(t)
      } catch {}
      void refetch()
    }
    window.addEventListener('hyapi-auth', onAuth as EventListener)
    return () => window.removeEventListener('hyapi-auth', onAuth as EventListener)
  }, [refetch])

  

  useEffect(() => {
    if (token) {
      (globalThis as any).hyapiBearer = token;
      void refetch();
    }
  }, [token, refetch])

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

  // Allocation / APY query
  const allocQ = useAllocation()
  const alloc = allocQ.data

  return (
    <Box sx={{ mx: 'auto', maxWidth: 'lg', px: { xs: 2, sm: 3 }, py: 4 }}>
      <PiInit />
      <Box sx={{ display:'flex', alignItems:'center', mb:1 }}>
        <Typography variant="h5" fontWeight={600} sx={{ flex:1 }}>Your Portfolio</Typography>
        {!token && (
          <PiLoginButton onLoggedIn={({ accessToken }) => { setToken(accessToken) }} />
        )}
        {token && <Button size="small" variant="outlined" onClick={()=>setShowProof(true)}>View on‑chain addresses</Button>}
      </Box>

      <Box sx={{ display: 'grid', gap: 1.5, gridTemplateColumns: { xs: '1fr', sm: 'repeat(3, 1fr)' }, mt: 0.5 }}>
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
      </Box>

      <Box sx={{ mt: 2 }}>
        {allocQ.isLoading && <Skeleton variant="rounded" height={60} />}
        {!allocQ.isLoading && alloc && <ApyCards pps={alloc.pps} apy7d={metrics?.apy7d ?? alloc.apy7d} lifetimeGrowth={metrics?.lifetimeGrowth ?? alloc.lifetimeGrowth} />}
      </Box>
      {(alloc?.degraded || metrics?.degraded) && (
        <Alert severity="warning" sx={{ mt: 1 }}>
          Allocation / APY data is degraded or incomplete.
        </Alert>
      )}

      <Box sx={{ display: 'grid', gap: 1.5, gridTemplateColumns: { xs: '1fr', lg: '1fr 1fr' }, mt: 1 }}>
        <Card>
          <Box sx={{ px: 2.5, py: 1.25, background: 'linear-gradient(90deg, rgba(255,255,255,0.08), transparent)' }}>
            <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.7)', fontWeight: 500 }}>Allocation</Typography>
          </Box>
          <Box sx={{ p: 2.5, pt: 1.5 }}>
            {allocQ.isLoading && <Skeleton variant="rounded" height={18} />}
            {!allocQ.isLoading && <AllocationBar mix={alloc?.chainMix || []} />}
            <Box sx={{ mt: 2 }}>
              <PublicAddresses />
            </Box>
          </Box>
        </Card>
        <Card>
          <Box sx={{ px: 2.5, py: 1.25, background: 'linear-gradient(90deg, rgba(123,140,255,0.25), transparent)' }}>
            <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.7)', fontWeight: 500 }}>Recent activity</Typography>
          </Box>
          <Box sx={{ p: 1.25, pt: 0.5 }}>
            <Table size="small" sx={{ '& th, & td': { border: 0 } }}>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ color: 'rgba(255,255,255,0.65)', fontSize: 12 }}>When</TableCell>
                  <TableCell sx={{ color: 'rgba(255,255,255,0.65)', fontSize: 12 }}>Type</TableCell>
                  <TableCell sx={{ color: 'rgba(255,255,255,0.65)', fontSize: 12 }}>Detail</TableCell>
                  <TableCell sx={{ color: 'rgba(255,255,255,0.65)', fontSize: 12 }}>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {(activity.length ? activity : items.slice(0, 10)).map(e => {
                  const color = e.status === 'success' ? 'success' : e.status === 'error' ? 'error' : 'default'
                  return (
                    <TableRow key={e.id} sx={{ '&:last-child td': { pb: 1.5 } }}>
                      <TableCell sx={{ whiteSpace: 'nowrap', color: 'rgba(255,255,255,0.65)', fontSize: 13 }}>{new Date(e.ts).toLocaleString?.() || e.ts}</TableCell>
                      <TableCell sx={{ whiteSpace: 'nowrap', fontSize: 13 }}>{e.kind}</TableCell>
                      <TableCell sx={{ fontSize: 13 }}>{e.title}{e.detail ? ` — ${e.detail}` : ''}</TableCell>
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>
                        <Chip label={e.status} size="small" color={color as any} variant={color === 'default' ? 'outlined' : 'filled'} sx={{ fontSize: 11, height: 22 }} />
                      </TableCell>
                    </TableRow>
                  )
                })}
                {!activity.length && !items.length && (
                  <TableRow>
                    <TableCell colSpan={4} sx={{ color: 'rgba(255,255,255,0.55)', fontSize: 13 }}>No recent activity.</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </Box>
        </Card>
      </Box>
      <ProofDialog open={showProof} onClose={()=>setShowProof(false)} />
    </Box>
  )
}
