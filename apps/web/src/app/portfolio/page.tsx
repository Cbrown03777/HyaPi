'use client'
import { useEffect, useMemo, useState } from 'react'
import { GOV_API_BASE } from '@hyapi/shared'
import { piLogin, signInWithPi } from '@/lib/pi'
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

type PpsRow = { as_of_date: string; pps_1e18: string }

export default function PortfolioPage() {
  const [token, setToken] = useState('')
  const [hyapi, setHyapi] = useState<number | null>(null)
  const [piValue, setPiValue] = useState<number | null>(null)
  const [pps1e18, setPps1e18] = useState<string | null>(null)
  const [series, setSeries] = useState<PpsRow[]>([])
  const { items } = useActivity()
  const [showProof, setShowProof] = useState(false)

  useEffect(() => {
    (async () => {
      // If we have a persisted token, use it; else prompt login
      let t = ''
      try { t = (typeof localStorage !== 'undefined' ? localStorage.getItem('hyapiBearer') : '') || '' } catch {}
      if (!t) {
        try {
          const { accessToken } = await piLogin()
          t = accessToken
          try { if (typeof localStorage !== 'undefined') localStorage.setItem('hyapiBearer', t) } catch {}
        } catch {
          // No token yet; UI will show login button
        }
      }
      setToken(t)
      if (t) (globalThis as any).hyapiBearer = t
      if (!t) return
      try {
        const res = await api('/v1/portfolio')
        const j = await res.json()
        if ((res as any).ok && j?.success) {
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

  // Allocation / APY query
  const allocQ = useAllocation()
  const alloc = allocQ.data

  return (
    <Box sx={{ mx: 'auto', maxWidth: 'lg', px: { xs: 2, sm: 3 }, py: 4 }}>
      <Box sx={{ display:'flex', alignItems:'center', mb:1 }}>
        <Typography variant="h5" fontWeight={600} sx={{ flex:1 }}>Your Portfolio</Typography>
        {!token && (
          <Button size="small" variant="contained" onClick={async ()=>{
            try {
              const { accessToken } = await piLogin()
              setToken(accessToken)
              try { localStorage.setItem('hyapiBearer', accessToken) } catch {}
            } catch {}
          }}>Log in with Pi</Button>
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
        {!allocQ.isLoading && alloc && <ApyCards pps={alloc.pps} apy7d={alloc.apy7d} lifetimeGrowth={alloc.lifetimeGrowth} />}
      </Box>
      {alloc?.degraded && (
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
                {items.slice(0, 10).map(e => {
                  const color = e.status === 'success' ? 'success' : e.status === 'error' ? 'error' : 'default'
                  return (
                    <TableRow key={e.id} sx={{ '&:last-child td': { pb: 1.5 } }}>
                      <TableCell sx={{ whiteSpace: 'nowrap', color: 'rgba(255,255,255,0.65)', fontSize: 13 }}>{new Date(e.ts).toLocaleString()}</TableCell>
                      <TableCell sx={{ whiteSpace: 'nowrap', fontSize: 13 }}>{e.kind}</TableCell>
                      <TableCell sx={{ fontSize: 13 }}>{e.title}{e.detail ? ` — ${e.detail}` : ''}</TableCell>
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>
                        <Chip label={e.status} size="small" color={color as any} variant={color === 'default' ? 'outlined' : 'filled'} sx={{ fontSize: 11, height: 22 }} />
                      </TableCell>
                    </TableRow>
                  )
                })}
                {!items.length && (
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
